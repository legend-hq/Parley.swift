# Solana Support in Mercator — Overview

## What are we doing?

Adding Solana as a second chain family alongside EVM. Charter (the transaction planner) needs to produce Solana transaction instructions in addition to EVM Quark operations.

**Design principle:** Unified refactor. The Chart data model uses a single `[OperationAction]` array for both EVM and Solana, with a discriminated `Operation` enum separating chain-specific execution details from chain-agnostic action metadata.

---

## Architecture

```
                        ┌─────────────────────────────────────────────────────┐
  QuarkIntent           │               Charter Pipeline                      │
  (chain-agnostic)      │                                                     │
  ───────────────────►  │  Tradewinds ──► Flows                               │
                        │  (routing)       │                                   │
                        │                  │  for each flow:                   │
                        │                  ▼                                   │
                        │         constructOperationsAndActionsExtended        │
                        │                  │                                   │
                        │                  ├── flow.source.isEVM?              │
                        │                  │   └► QuarkOperationBuilder        │
                        │                  │      (scriptAddress, calldata,    │
                        │                  │       nonce, EIP-712)             │
                        │                  │                                   │
                        │                  └── flow.source.isSolana?           │
                        │                      └► SolanaOperationBuilder (TODO)│
                        │                         (programId, accounts,        │
                        │                          base64 data)                │
                        │                  │                                   │
                        │                  ▼                                   │
                        │  Chart { operationActions[], signingData }           │
                        └─────────────────────────────────────────────────────┘
                                           │
                           ┌───────────────┴───────────────┐
                           ▼                               ▼
                     Legend Backend                    iOS App
                     (submit + monitor)               (sign + display)
```

**Key insight:** Everything above the flow loop is already chain-agnostic. The single function `constructOperationsAndActionsExtended` processes all flows and delegates each one to the right builder based on the source network. Today it only has the EVM path; the Solana path is the main TODO.

---

## Data Model Summary

### Address Types

```
EthAddress ─────── EVM-specific (hex, 20 bytes)
SolanaAddress ──── Solana-specific (base58, 32 bytes)
ChainAddress ───── Enum: one case per supported chain, typed address per VM family
```

| Type | Format | Validation | Use case |
|------|--------|-----------|----------|
| `EthAddress` | `0x` + 40 hex chars | 20-byte check | EVM contracts, wallets |
| `SolanaAddress` | Base58 string | 32-byte ed25519 pubkey | Solana programs, wallets |
| `ChainAddress` | Enum with one case per supported Network | Compile-time: can't pair wrong address type with wrong chain | Intent entry points — sender, recipient, borrower, etc. |

```swift
public enum ChainAddress {
    // Atlas-supported EVM networks
    case arbitrum(EthAddress)
    case base(EthAddress)
    case ethereum(EthAddress)
    case hyperEVM(EthAddress)
    case optimism(EthAddress)
    case polygon(EthAddress)
    case unichain(EthAddress)
    case worldChain(EthAddress)
    // Testnets
    case sepolia(EthAddress)
    case baseSepolia(EthAddress)
    // Solana
    case solana(SolanaAddress)

    /// Non-failable init — traps on unsupported network.
    public init(_ address: EthAddress, chain: Network)

    /// Check before constructing if the network might be unsupported.
    public static func supports(_ chain: Network) -> Bool
}
```

**Why a flat enum:** You can't put a `SolanaAddress` on `.base` or an `EthAddress` on `.solana` — the compiler rejects it. The init traps on unsupported networks (e.g. `.sonic`) rather than returning nil, matching how the codebase treats unsupported chains as programmer errors. Use `ChainAddress.supports(_:)` to check first if needed.

**Helpers on ChainAddress:**
- `.chain: Network` — the network this address is on
- `.ethAddress: EthAddress?` — extract EVM address (nil for Solana)
- `.solanaAddress: SolanaAddress?` — extract Solana address (nil for EVM)
- `.displayString: String` — hex or base58 as appropriate
- `.shortened: String` — truncated display (e.g. `0xd8dA...6045`)
- `.onChain: String` — formatted string like `"on Base"`

**Tradeoff:** Only Atlas-supported networks get cases (not all 33+ `Network` variants). Adding a new supported chain means adding a case + updating switches. Switches are mechanical and groupable via comma-separated patterns in Swift.

**JSON encoding:** `{ "address": "0x..." or "base58...", "chain": <chainId> }`. Decoding uses `0x` prefix to distinguish EVM from Solana.

### Chart Output (what Charter produces)

> **⚠️ DATA MODEL CHANGE (v2)** — The previous spec used a dual-array approach with separate `QuarkOperationAction` and `SolanaOperationAction` types. After reviewing the full end-to-end lifecycle (`plans.details` in Prime API, backend decomposition at `quark_intent.ex:212-277`, and Charter output at `LegendRouteType+getQuarkOperationActions.swift:1934`), we determined the old model conflated operation mechanics with action semantics. The new model cleanly separates them:
>
> - **Operation** = _how_ to execute (chain-specific: EVM script calldata vs Solana instructions)
> - **Action** = _what_ the user wants (chain-agnostic: transfer, swap, bridge)

```
Chart
├── version: String
├── operationActions: [OperationAction]     ← unified array (EVM + Solana)
└── signingData: SigningData                ← compound signing envelope
```

### OperationAction (unified — replaces QuarkOperationAction + SolanaOperationAction)

```
OperationAction
├── operation: Operation (enum)             ← chain-specific execution details
│   ├── case evm(EVMOperation)
│   └── case solana(SolanaOperation)
└── action: Action                          ← chain-agnostic action description
```

**Key insight:** This maps directly to the `plans.details` concept in the Prime API — each plan entry has an operation (how) and an action (what). The old model had two different struct shapes for the same concept.

### EVM vs Solana Operation — Side by Side

| | EVM (`EVMOperation`) | Solana (`SolanaOperation`) |
|---|---|---|
| **Execution data** | scriptAddress, scriptCalldata, scriptSources | instructions: [SolanaInstruction] |
| **Replay protection** | nonce, nonceSecret, totalPlays, expiry, isReplayable | (none — backend manages recent_blockhash) |
| **Signing** | EIP-712 typed data hash (secp256k1) via `signingData.evm` | Transaction message bytes (ed25519) via `signingData.solana` |
| **Multi-op merging** | Multicall script (ABI-encoded) | Multiple instructions in one tx (native) |
| **Address format** | `0x...` (hex) | Base58 |
| **Instruction data** | `0x...` calldata (hex) | Base64 |

### EVMOperation (formerly QuarkOperation + parts of Chart.Action)

```
EVMOperation
├── scriptAddress: EthAddress      // contract address
├── scriptCalldata: Hex            // ABI-encoded calldata
├── scriptSources: [Hex]           // bytecode sources
├── nonce: Hex                     // 32-byte nonce
├── expiry: Number                 // block timestamp
├── isReplayable: Bool
├── nonceSecret: Hex               // MOVED here from Action — cryptographic replay protection
└── totalPlays: Number             // MOVED here from Action — per-operation execution count
```

**Why `nonceSecret` and `totalPlays` moved from Action to Operation:**
- `nonceSecret` is generated per-operation and directly assigned as the operation's `nonce` (`Chart.swift:51`: `nonce: nonceSecret`). It's cryptographic replay protection — pure operation mechanics.
- `totalPlays` controls how many times an operation can execute. The backend uses it for `is_replayable: total_plays > 1`, tracking `remaining_plays`, and computing `play_number`.
- Neither field has anything to do with action context (what the user wants to do). They describe _operation execution mechanics_, not _user intent_.

### SolanaOperation

```
SolanaOperation
└── instructions: [SolanaInstruction]      // What to execute
    ├── programId: SolanaAddress           // e.g. Token Program
    ├── accounts: [SolanaAccountMeta]      // pubkey + signer/writable flags
    └── data: String                       // base64-encoded instruction data
```

No nonce/expiry/totalPlays — Solana uses `recent_blockhash` (~90s TTL), managed by the backend at submission time.

### Action (chain-agnostic — replaces both Chart.Action and SolanaAction)

```
Action
├── chainId: Number                // 1 for ETH mainnet, 501424 for Solana, etc.
├── account: ChainAddress          // user's wallet
├── actionType: String             // "TRANSFER", "SWAP", "BRIDGE", etc.
├── actionContext: ActionContext    // chain-agnostic action description
└── executionType: ExecutionType   // "IMMEDIATE" | "DELAYED" | "RECURRENT" | "CONTINGENT"
```

**Changes from old `Chart.Action`:** `quarkAccount: EthAddress` → `account: ChainAddress`, `nonceSecret` and `totalPlays` moved to `EVMOperation` (their correct home — they're operation execution mechanics, not action semantics).

**Changes from old `SolanaAction`:** `account: SolanaAddress` → `account: ChainAddress`. Otherwise identical.

**Backwards compatibility:** The new `operationActions` / `signingData` fields are additive — they're new fields on `Chart`, added alongside the existing `quarkOperationActions` / `solanaOperationActions` / `eip712Data`. The old fields stay in place and the backend continues reading from them. Migration to the new unified fields happens separately.

### Shared Types (work for both chains)

| Type | Where used | What changed |
|------|-----------|-------------|
| `ActionContext` | Describes what an operation does (transfer, swap, bridge...) | Transfer + Bridge variants use `ChainAddress` for `token` and `recipient` |
| `QuarkIntent` | User's intent (what they want to do) | All intent types use `ChainAddress` for sender/recipient/borrower/etc. |
| `Folio` | Portfolio state passed to Charter | `BalanceType.token` wallet now `ChainAddress` |
| `LegendNode` | Tradewinds routing graph nodes | `tokenBalance` uses `ChainAddress` for address + wallet |
| `Network` | Chain identifier | Added `.solana`, `.isSolana`, `.isEVM` |
| `ExecutionType` | `IMMEDIATE`, `CONTINGENT`, etc. | Unchanged — shared by both |

### SigningData (compound envelope — replaces EIP712Data)

```
SigningData
├── evm: EVMSigningData?           // present when chart contains EVM operations
│   ├── digest: Hex                // EIP-712 typed data hash
│   ├── domainSeparator: Hex
│   └── hashStruct: Hex
└── solana: SolanaSigningData?     // present when chart contains Solana operations
    └── serializedMessage: String  // base64 — transaction message bytes to sign
```

**Why compound structure:** EVM uses a single EIP-712 signature that covers all EVM operations in the chart — it's inherently chart-level, not per-operation. The compound structure makes it explicit: a chart can require EVM signing, Solana signing, both, or neither.

| Chart type | `signingData.evm` | `signingData.solana` |
|------------|-------------------|---------------------|
| EVM-only | present | nil |
| Solana-only | nil | present |
| Mixed (EVM + Solana) | present | present |
| Version-only (no ops) | nil | nil |

### Solana Asset Resolution (stopgap)

Since Atlas doesn't cover Solana yet, we use `SolanaAssetRegistry` — a hardcoded lookup:

| Symbol | Mint Address |
|--------|-------------|
| USDC | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` |
| SOL/WSOL | `So11111111111111111111111111111111111111112` |
| USDT | `Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB` |

`LegendNode.decimals` also has a hardcoded fallback for Solana tokens (6 for USDC/USDT, 9 for SOL/WSOL). Both are temporary until Atlas gains Solana data.

---

## Implementation Status

### Done (this branch)

| Component | Files | What |
|-----------|-------|------|
| `SolanaAddress` | `Prelude/Types/SolanaAddress.swift` | Base58 validated, 32-byte, Codable |
| `ChainAddress` | `Prelude/Types/ChainAddress.swift` | Flat enum with one case per supported chain — non-failable init, `.chain` property, `.ethAddress`/`.solanaAddress` accessors |
| `Network+Solana` | `Prelude/Types/Network+Solana.swift` | `.solana`, `isSolana`, `SolanaAssetRegistry` |
| `Chart` dual arrays | `Charter/Chart.swift` | `solanaOperationActions` field, `eip712Data` optional (to be replaced by unified model) |
| `SolanaOperationAction` | `Charter/SolanaOperationAction.swift` | Full struct: instructions + action + account metas (to be replaced by unified `OperationAction`) |
| `ActionContext` updates | `Charter/ActionContext.swift` | Transfer + Bridge use `ChainAddress` for `token` and `recipient` |
| `QuarkIntent` updates | `Charter/QuarkIntent.swift` | `TransferIntent` sender/recipient → `ChainAddress` |
| `Folio` updates | `Prelude/Types/Folio.swift` + extensions | Token balance wallet → `ChainAddress`, path parsing |
| `LegendNode` updates | `Charter/LegendNode.swift` | `tokenBalance` → `ChainAddress`, decimal fallback |
| Elixir chart module | `mercator.ex/charter/chart.ex` | Full Solana de/serialization with doctests |

### Pending (unified data model refactor)

| Component | What |
|-----------|------|
| Unified `OperationAction` type | Replaces `QuarkOperationAction` + `SolanaOperationAction` |
| `Operation` enum (evm/solana) | Discriminated union with `type` key in JSON |
| Chain-agnostic `Action` | `account: ChainAddress`, no `nonceSecret`/`totalPlays` |
| `nonceSecret`/`totalPlays` → `EVMOperation` | Move from Action to Operation |
| `SigningData` compound structure | Replaces `EIP712Data` with `{ evm, solana }` |
| `Chart.swift` — unified model | Single `operationActions` array + `signingData` |
| `chart.ex` (Elixir) — unified model | Update de/serialization for new structure |

### Not Done (future work)

See next section.

---

## Future Work — What's Needed for Full Solana Support

The data model is in place. What's missing is the **operation construction pipeline** — the code that turns a Tradewinds flow into actual Solana instructions.

### Phase 1: Charter Pipeline (make Charter produce Solana charts)

```
Current pipeline (EVM-only):
  Flows ──► getQuarkOperationDetails() ──► QuarkOperationBuilder ──► QuarkOperationAction[]
                                              │
                                    (builds EVM calldata, ABI encoding,
                                     script addresses, nonces)

Needed pipeline (dual-chain):
  Flows ──► is Solana? ──yes──► getSolanaOperationDetails() ──► OperationAction(.solana)[]
               │
               no
               │
               ▼
            getQuarkOperationDetails() ──► OperationAction(.evm)[]  (unchanged)
```

| Task | Where | What needs to happen |
|------|-------|---------------------|
| **Fork at flow level** | `Charter.swift:392-434` | Detect Solana flows (`wallet?.solanaAddress != nil`) and route to Solana builder instead of calling `getQuarkOperationActions` |
| **`SolanaOperationBuilder`** | New file | Build `SolanaInstruction[]` for each operation type. Start with transfer (SystemProgram + SPL Token), then swap (Jupiter CPI), then bridge (Across SVM spoke pool) |
| **Unified OperationAction output** | `Charter.swift` | Both builders produce `OperationAction` with chain-agnostic `Action`. EVM builder wraps in `.evm(EVMOperation)`, Solana builder wraps in `.solana(SolanaOperation)` |
| **Skip Multicall merge for Solana** | `Charter.swift:437` | `mergeSameChainOperations` is EVM-only. Solana ops just concatenate instructions into one tx — no merging script needed |
| **Build `signingData`** | `Charter.swift` | Construct compound `SigningData` — EVM sub-field when EVM ops present, Solana sub-field when Solana ops present |
| **Nonce handling** | `Charter.swift:396` | Solana flows don't need `nonceSecret` from Folio. The nonce guard must be chain-conditional. `nonceSecret`/`totalPlays` only populated on `EVMOperation` |

### Phase 2: Backend (Legend) — Store + Execute Solana Operations

| Task | What |
|------|------|
| `chain_id` range check | Solana chain_id = `501424` (fits in standard integer — no bigint migration needed). |
| `solana_wallets` table | Store user Solana wallets (address, chain_id, account FK, signing_wallet FK) |
| `solana_operations` table | Store Solana ops (instructions as JSONB, signature, recent_blockhash, status, action_context) |
| Chart decomposition | Iterate `operation_actions[]`, check `operation.type` → route to `quark_operations` (EVM) or `solana_operations` (Solana) |
| Ed25519 signing support | `signing_wallets.wallet_curve` field. Backend signature verification for ed25519 (currently hardcoded to secp256k1) |
| Solana tx builder | Assemble instructions + recent_blockhash + compute budget → serialized transaction |
| `SolanaTrxCannon` | Submit Solana transactions via `sendTransaction` RPC |
| `SolanaReceiptScanner` | Poll `getSignatureStatuses`. Handle processed → confirmed → finalized |
| Blockhash expiry handling | Solana txs expire ~90s. Need rebuild + re-sign flow |
| ExogenousExecution for Solana | Gate Solana operations on cross-chain events (e.g., bridge fill) |

### Phase 3: iOS — Sign + Display Solana Operations

| Task | What |
|------|------|
| Ed25519 signing | Sign Solana transaction message bytes (vs EIP-712 digest for EVM) |
| Two-round-trip signing for mixed charts | EVM sign → submit → backend builds Solana tx → return to iOS → Solana sign → submit |
| Activity display | `ActivityMetadata.quarkWalletAddress` → `ChainAddress` enum. Show Solana signatures (base58) instead of tx hashes |
| Solana portfolio | Fetch balances via `getBalance` + `getTokenAccountsByOwner` RPC. Build Folio entries |

### Phase 4: Atlas + Asset Infrastructure

| Task | What |
|------|------|
| Atlas Solana assets | Token registry with mint addresses, decimals, symbols. Replaces `SolanaAssetRegistry` stopgap |
| Remove hardcoded fallbacks | Delete `SolanaAssetRegistry` and `LegendNode.knownDecimals` once Atlas covers Solana |
| KnownNetwork for Solana | Add Solana program addresses (Token Program, ATA Program, Jupiter, Across SVM spoke pool) |

---

## Encoding Conventions

| Data kind | EVM | Solana |
|-----------|-----|--------|
| Addresses | `0x` + hex (`EthAddress`) | Base58 (`SolanaAddress`) |
| Raw byte data | `0x` + hex (`Hex`) | Base64 (instruction data) |
| Big integers | Decimal string (`Number`) | Decimal string (`Number`) |
| Signatures | `0x` + hex (65 bytes) | Base58 (64 bytes) |
| Chain ID | Small int (e.g. `8453`) | Integer (`501424`) |

---

## Example: Solana Transfer Chart

What Charter would produce for "send 1 USDC on Solana":

```json
{
  "version": "1.5.8",
  "operation_actions": [
    {
      "operation": {
        "type": "solana",
        "instructions": [
          {
            "program_id": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            "accounts": [
              { "pubkey": "<sender-ata>", "is_signer": false, "is_writable": true },
              { "pubkey": "<recipient-ata>", "is_signer": false, "is_writable": true },
              { "pubkey": "<sender-wallet>", "is_signer": true, "is_writable": false }
            ],
            "data": "<base64-transfer-instruction>"
          }
        ]
      },
      "action": {
        "chain_id": "501424",
        "account": "<sender-wallet-base58>",
        "action_type": "TRANSFER",
        "action_context": {
          "amount": "1000000",
          "asset_symbol": "USDC",
          "chain_id": "501424",
          "price": "100000000",
          "recipient": "<recipient-base58>",
          "token": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        },
        "execution_type": "IMMEDIATE"
      }
    }
  ],
  "signing_data": {
    "solana": {
      "serialized_message": "AQAB..."
    }
  }
}
```

## Example: Bridge Solana USDC → Supply on Base (Mixed Chart)

```json
{
  "version": "1.5.8",
  "operation_actions": [
    {
      "operation": {
        "type": "solana",
        "instructions": [
          { "program_id": "<spl-approve>", "accounts": [...], "data": "..." },
          { "program_id": "<across-svm-spoke>", "accounts": [...], "data": "..." }
        ]
      },
      "action": {
        "chain_id": "501424",
        "account": "<sender-wallet-base58>",
        "action_type": "BRIDGE",
        "action_context": {
          "asset_symbol": "USDC",
          "bridge_type": "ACROSS",
          "chain_id": "501424",
          "destination_chain_id": "8453",
          "destination_asset_symbol": "USDC",
          "input_amount": "1000000",
          "output_amount": "990000",
          "price": "1.00",
          "recipient": "0xQuarkWalletOnBase...",
          "token": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        },
        "execution_type": "IMMEDIATE"
      }
    },
    {
      "operation": {
        "type": "evm",
        "script_address": "0xAaveSupplyScript...",
        "script_calldata": "0x...",
        "script_sources": [],
        "nonce": "0x...",
        "expiry": "9999999999",
        "is_replayable": false,
        "nonce_secret": "0x...",
        "total_plays": "1"
      },
      "action": {
        "chain_id": "8453",
        "account": "0xQuarkWalletOnBase...",
        "action_type": "SUPPLY",
        "action_context": { "...": "..." },
        "execution_type": "CONTINGENT"
      }
    }
  ],
  "signing_data": {
    "evm": {
      "digest": "0x...",
      "domain_separator": "0x...",
      "hash_struct": "0x..."
    },
    "solana": {
      "serialized_message": "AQAB..."
    }
  }
}
```

Backend creates: 1 `SolanaOperation` (IMMEDIATE) + 1 `QuarkOperation` (CONTINGENT) + 1 `ExogenousExecution` gating the QuarkOperation on bridge fill.
