# Parley WASM Weight Reduction Strategy

**Goal:** Reduce Parley.wasm from ~27MB to ~5MB (or less).

**Date:** 2025-02-23 (updated 2025-02-24)

> **WARNING:** Parley uses the **official Swift 6.2+ WebAssembly SDK** (`wasm32-unknown-wasip1`).
> This is **NOT SwiftWasm** (the deprecated community fork). Do not reference SwiftWasm
> documentation, patterns, or tooling — they are likely incorrect for our use-case.

---

## Results So Far

| Phase | Binary Size | Savings |
|-------|------------|---------|
| Baseline (before) | ~27 MB | — |
| Phase 1: FoundationEssentials + drop ICU + wasm-opt | **13 MB** | **14 MB (52%)** |

---

## What Was Done (Phase 1)

### 1. Switched all imports to FoundationEssentials

Every `import Foundation` across all source files (96 in Parley.swift, 435 in Atlas.swift) was replaced with:

```swift
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
```

This prevents `FoundationInternationalization` (and its ICU data payload) from being linked on WASM, while preserving full Foundation on macOS/iOS where tests run.

### 2. Eliminated all Foundation-only APIs

FoundationEssentials on WASM is a much smaller API surface than Foundation. These APIs needed replacement:

| API | Replacement | Files |
|-----|-------------|-------|
| `NumberFormatter` | Pure `formatNumber()` function | `Decimal+Format.swift` (full rewrite) |
| `NSDecimalNumber.doubleValue` | `Double(decimal.description) ?? 0.0` | Amount, Value, Percentage |
| `NSDecimalNumber.description(withLocale:)` | `decimal.description` | 3 `*+Scientific.swift` files |
| `NSDecimalRound` | `Decimal.pow10()` helper | (removed with NumberFormatter) |
| `NSRegularExpression` | Swift Regex (`/pattern/`) | `Decimal+Scientific.swift` |
| `NSNull` | `Optional<[String: Any]>?` | `PortfolioGenerator.swift` |
| `pow(Decimal, Int)` | `Decimal.pow10(n)` using `Decimal(sign:exponent:significand:)` | 8 files |
| `pow(Double, Double)`, `floor()`, `log()` | `cPow()`, `cFloor()`, `cLog()` wrappers (re-export C math) | `PlatformCompat.swift` |
| `String.replacingOccurrences(of:with:)` | `String.replacingAll(_:with:)` (pure Swift) | 5 files |
| `String.range(of:)` | `String._findRange(of:)` (pure Swift) | 3 files |
| `String.trimmingCharacters(in:)` | `String.trimmingWhitespace()` (pure Swift) | 2 files |
| `ISO8601DateFormatter` | `Date.ISO8601FormatStyle` / `.formatted(.iso8601)` | `ISODate.swift` |
| `error.localizedDescription` | `String(describing: error)` | 4 files |
| `CGFloat` | `Double` | `Percentage.swift` |
| `String(format:)` | Manual formatting / string interpolation | Tradewinds, Eth.swift |
| `NSLocalizedString` | Plain string literals | Eth.swift (Schema, EVM) |
| `JSONSerialization` | `#if` gated (test-only code) | `PortfolioGenerator.swift` |

All replacements live in `Sources/Prelude/Utilities/PlatformCompat.swift` or inline.

### 3. Removed ICUDataSlim dependency

Deleted `swift-icudata-slim` from `Package.swift`. It existed solely to feed ICU data to FoundationInternationalization. With FoundationEssentials, there's nothing to feed.

### 4. Updated dependencies (in .build/checkouts — need upstreaming)

- **SwiftKeccak**: `NSData` → `Data.withUnsafeBytes`, conditional import
- **SwiftNumber**: `NSDecimalRound` → string-based truncation, `CharacterSet` → pure Swift, `pow` → `Decimal(sign:exponent:significand:)`, conditional imports
- **Eth.swift**: `NSNull` → `#if canImport(ObjectiveC)`, `NSLocalizedString` → plain strings, `String(format:)` → hex byte helpers, `ceil` → integer math, `replacingOccurrences` → pure Swift, conditional imports

**These changes live in `.build/checkouts/` and will be lost on `swift package resolve`.** New versions of SwiftKeccak, SwiftNumber, and Eth.swift must be published.

### 5. Build safeguards

Added to `build-parley.sh`:
- **Pre-build lint**: Rejects bare `import Foundation` not inside `#else` blocks
- **Post-build symbol check**: `wasm-objdump -x` verifies no ICU/FoundationInternationalization symbols
- **Binary size reporting**: Prints size and warns if above 15MB threshold
- **Aggressive wasm-opt**: Added `--converge`, `--duplicate-function-elimination`, `--strip-producers`, `--vacuum`, `--dce`, etc.

### 6. New test coverage

Added `Tests/PreludeTests/Extensions/DecimalFormatTests.swift` with 17 tests for the pure `formatNumber()` implementation.

---

## Key Learnings

### FoundationEssentials on WASM is much more limited than expected

The initial plan assumed FoundationEssentials would be a near-drop-in replacement for Foundation. In practice, the WASM SDK's FoundationEssentials is missing many APIs that are available on macOS/Linux:

- **All NSString-bridged String methods** (`replacingOccurrences`, `range(of:)`, `trimmingCharacters`, `data(using:)`)
- **C math functions** (`pow`, `floor`, `ceil`, `log`) — Foundation re-exports these from Darwin/Glibc, FoundationEssentials does not
- **`String(format:)`** — Foundation-only
- **`ISO8601DateFormatter`** (class) — use `Date.ISO8601FormatStyle` instead
- **`CGFloat`** — CoreGraphics, doesn't exist on WASM
- **`error.localizedDescription`** — Foundation extension on Error
- **`JSONSerialization`** — Foundation-only (JSONEncoder/Decoder ARE in FoundationEssentials)
- **`NSNull`**, **`NSNumber`**, **`NSData`** — ObjC bridge types

This required creating `PlatformCompat.swift` with pure Swift replacements for string operations and C math wrappers.

### Dependency changes are fragile

Changes to `.build/checkouts/` are lost whenever SPM resolves packages. The dependency updates (SwiftKeccak, SwiftNumber, Eth.swift) must be upstreamed and version-bumped before this work can be merged cleanly.

### `pow(Decimal, Int)` is not in FoundationEssentials

The `pow` function for Decimal that's commonly used (`pow(10, n)` to get 10^n as a Decimal) is not available. Replaced with `Decimal(sign: .plus, exponent: n, significand: 1)` wrapped as `Decimal.pow10(n)`.

---

## What's Left: Remaining 13MB

The current 13MB is composed of:

| Component | Est. Size | Reducible? |
|-----------|-----------|------------|
| Swift Runtime + stdlib | ~5 MB | Only with Embedded Swift (major rewrite) |
| Application code | ~4-5 MB | Partially — Atlas.swift has 435 generated files |
| Dead code (protocol conformances) | ~2-3 MB | Blocked by Swift compiler limitations |
| wasm-opt overhead | ~1 MB | Minor further tuning possible |

### Potential next steps (not yet implemented)

1. **Test with nightly/dev Swift toolchains** — Forum reports suggest nightlies produce much smaller WASM. Could reveal upstream improvements.

2. **Audit Atlas.swift** — 435 generated chain/asset definition files. If Parley's WASM path only uses a subset of chains, splitting Atlas into per-chain targets could reduce dead code.

3. **Embedded Swift** (nuclear option, → sub-1MB) — Eliminates the entire Swift runtime. Requires:
   - Replacing all Codable (depends on existentials)
   - Eliminating `any Protocol` existentials (21 occurrences)
   - No Foundation at all — manual JSON serialization
   - Restricted String operations

### Immediate TODOs

- [ ] Upstream SwiftKeccak changes → tag new version
- [ ] Upstream SwiftNumber changes → tag new version
- [ ] Upstream Eth.swift changes → tag new version
- [ ] Update Atlas.swift code generator template to emit conditional imports
- [ ] Update Package.swift to reference new dep versions
- [ ] Run Parley WASM integration tests once test harness is updated
- [ ] Verify Mercator (backend) still builds and passes tests with these changes
