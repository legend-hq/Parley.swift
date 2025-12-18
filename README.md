# Mercator

## Swift

Note: please download the most recent version of Swift and the Swift WASM SDK at https://www.swift.org/install/macos/. See "release/6.2" and the "Swift SDK for WebAssembly".

## Charter

Charter is the main program to take in user intents and decide which scripts need to be run to get the intended result. It is based on top of `Tradewinds`, which is the graph program to decide how best to get from one state to another via on-chain route transitions.

### Legend Scripts

Charter requires that Legend scripts are made available to it (e.g. to construct the on-chain actions). These can be built via `scripts/get-legend-script-release.sh <VERSION>` which will be downloaded to `legend-scripts-release/<VERSION>` and the contract directory (`Sources/Prelude/Contracts/`) will be updated with the `Geno` of these files.

## Parley

Parley exposes Mercator via a WASM interface. This WASM blob can be e.g. embedded into the Legend backend or signed and downloaded by the App for an OTA upgrade.

### Building

Parley can be built via `scripts/build-parley.sh` or `scripts/build-parley.sh release`. The resultant wasm file will be at `.build/{debug,release}/Parley.wasm`. This can be copied to the Legend folder via `scripts/build-parley.sh --release --optimize --copy ../legend`

Note: we try to make these slim, but we can make them slimmer by following the directions in https://github.com/GoodNotes/swift-icudata-slim?tab=readme-ov-file#i-want-even-smaller-icu-data-what-can-i-do

### Interface

Parley provides a WASM interface with the following functions:

- `name()` - Returns the module name ("Parley")
- `version()` - Returns the current version string
- `chart()` - The main function that processes intents and generates transaction charts

The `chart` function accepts a JSON request containing the user's intent, current portfolios, quotes for various operations, and other necessary data. It returns either a successfully generated chart with all required transactions or an error describing what went wrong. This allows external systems to convert high-level user intents into concrete blockchain operations.
