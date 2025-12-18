# Mercator Build Scripts

This directory contains scripts for building and testing Mercator, designed to work both locally and in BuildKite CI.

## Scripts Overview

### prepare.sh
Compiles the test suite and creates build artifacts. This must be run before running tests.
- Creates a local cache in `/tmp/Mercator/` for faster subsequent builds
- In CI, creates and uploads build artifacts to BuildKite

```bash
./scripts/prepare.sh [environment]
```

### test.sh
Runs the test suite. Requires `prepare.sh` to be run first.
- Automatically detects which test suite is being run (acceptance, unit, or server)
- In CI, outputs test results in xUnit format for BuildKite test analytics
- Supports all standard `swift test` arguments

```bash
# Run all tests
./scripts/test.sh

# Run specific test suite
./scripts/test.sh --filter MercatorTests.

# Run specific test class
./scripts/test.sh --filter MercatorTests.YamlWriterTest

# Run specific test
./scripts/test.sh --filter MercatorTests.YamlWriterTest/testSimpleYaml
```

### compile-tests.sh
Low-level script that runs `swift build --build-tests`. Called by `prepare.sh`.

### load-prepare.sh
Loads build artifacts. In CI, downloads artifacts from BuildKite. Locally, checks that `.build` exists.

### setup-swift.sh
Placeholder for Swift installation logic (currently does nothing).

## Local Development

Run tests directly:
```bash
./scripts/test.sh
```

The script will automatically build if needed. If you want to pre-build for faster test runs:
```bash
./scripts/prepare.sh  # Optional: pre-builds the tests
./scripts/test.sh     # Will skip building if already built
```

The scripts share the same build cache as direct `swift test` commands, so you can switch between them without rebuilding.

## BuildKite CI

The BuildKite pipeline runs tests in parallel:
1. **Prepare Test Build** - Compiles tests and creates artifacts
2. **Parallel Test Execution**:
   - Acceptance Tests
   - Unit Tests (MercatorTests)
   - Server Tests
3. **Test Analytics** - Collects and reports test results

Each parallel test job downloads the build artifacts from the prepare step, avoiding redundant compilation.

## Error Handling

All scripts use `set -euo pipefail` for consistent error handling:
- `-e`: Exit on error
- `-u`: Exit on undefined variables
- `-o pipefail`: Exit on pipe failures