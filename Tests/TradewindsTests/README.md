# Tradewinds Tests

This directory contains tests for the new generic Tradewinds implementation.

## Test Structure

### Core Files

- **TradewindsTestBase.swift**: Shared test infrastructure including:
  - `TradewindsTestNode` enum for common node types
  - `FlowTestCase` struct for test definition
  - `runFlowTest()` function used by all tests
  - Helper types and extensions

### Test Suites

- **TradewindsQuickTests.swift**: Essential tests that verify core functionality
- **TradewindsGenericTests.swift**: Basic generic implementation tests
- **TradewindsGenericBridgeTests.swift**: Bridge-specific scenarios
- **TradewindsSwapTests.swift**: Swap route tests
- **TradewindsExitTests.swift**: Exit node tests

## Usage Pattern

All tests follow this pattern:

```swift
@Test("Test description")
func testSomething() {
    runFlowTest(.init(
        name: "Test name",
        routes: [/* route definitions */],
        resources: [/* initial resources */],
        target: (/* amount */, /* target node */),
        costFunction: /* cost function */,
        expect: .exactFlows([/* expected flows */], maxFlow: /* expected max */)
    ))
}
```

## Key Features Tested

1. **Generic Node Types**: Using enum-based nodes with associated values
2. **User-Defined Cost Functions**: Custom routing preferences
3. **Route Filtering**: Disabling routes via `nil` cost
4. **Bridge Routes**: Cross-chain transfers with fees
5. **Swap Routes**: Token exchanges with different rates
6. **Exit Routes**: Terminal actions with associated data
7. **Multi-hop Routing**: Complex paths through multiple routes
8. **Max Flow Calculation**: Optimal resource utilization

## Number Precision

Tests use the `Number(value, decimals: n)` initializer for proper decimal handling:
- USDC: `Number(1000, decimals: 6)` = 1000 * 10^6
- ETH: `Number(2, decimals: 18)` = 2 * 10^18

## Rate System

All rates are scaled by 1e18 for precision. Use the helper extensions:
- `1.0.asRate` = 1e18 (1:1 exchange)
- `9999.bpsRate` = 0.9999 * 1e18 (1 basis point fee)
- `swapRate(fromDecimals: 18, toDecimals: 6, ratio: 2000)` for cross-decimal swaps

## Running Tests

```bash
# Run all Tradewinds tests
swift test --filter "Tradewinds"

# Run specific test suite
swift test --filter "TradewindsQuickTests"
```