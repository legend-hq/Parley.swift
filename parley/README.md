# Parley - WASM Interface for Mercator

Parley provides a WebAssembly interface to Charter and other Mercator systems.

## Structure

- `client.js` - JavaScript client for interacting with the WASM module
- `tests/` - Test suite using Bun
  - `smoke.test.js` - Basic functionality tests
  - `charter.test.js` - Charter integration tests

## Building

```bash
# Build the WASM module
../scripts/build-parley.sh
```

## Testing

```bash
# Run all tests
bun test

# Run specific test suites
bun test:smoke     # Basic smoke tests
bun test:charter   # Charter integration tests
```

## Usage

```javascript
import { ParleyClient } from './client.js';

const client = new ParleyClient('../.build/debug/Parley.wasm');
await client.initialize();

// Call the chart function
const result = await client.chart({
    version: "1.0",
    intent: { /* ... */ },
    portfolios: [],
    quote: { /* ... */ },
    across_quotes: [],
    nonce_secrets: []
});
```