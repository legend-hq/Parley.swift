# Tradewinds Migration Guide

## Overview

Tradewinds has been refactored to be generic over node types and support user-defined cost functions. This provides much more flexibility for different use cases.

## Key Changes

### 1. Generic Node Type

Instead of using `Int` for nodes, you now define your own enum that conforms to `TradewindsNode`:

```swift
enum MyNode: TradewindsNode {
    case usdcBase
    case usdcArbitrum
    case ethBase
    case sendUsdcTo(address: String)  // Can have associated values!
}
```

### 2. User-Defined Cost Functions

Instead of hardcoded `-log(rate)` cost calculation, you provide your own cost function:

```swift
let costFunction: Tradewinds.CostFunction<MyNode> = { route in
    switch route.type {
    case "PreferredRoute":
        return 0.1  // Low cost
    case "ExpensiveRoute":
        return 10.0  // High cost
    case "BlockedRoute":
        return nil  // Infinite cost - route disabled
    default:
        return -log(route.rate.asDouble)  // Default rate-based cost
    }
}
```

### 3. Updated Route Structure

Routes no longer have `time` or a separate `routeType` field. Instead, they have a generic `type` and now support dual fees: `inFee` (deducted before rate) and `outFee` (deducted after rate). The `id` is now a computed property.

```swift
let route = Tradewinds.Route(
    type: "CCTP_Mainnet_Base",
    source: .usdcMainnet,
    sink: .usdcBase,
    rate: 0.9999,
    inFee: Number("500000000000000"), // e.g., gas fee paid upfront
    outFee: Number("1000000000000000"), // e.g., bridge relayer fee
    minFlow: Number(0),
    maxFlow: Number(10_000) * Number(10).power(6)
)
```

### 4. Updated API

The API for `flow` and `maxFlow` remains the same, but you'll pass in your new routes and cost function.

```swift
// Find optimal flows
let result = Tradewinds.flow(
    routes: routes,
    resources: resources,
    target: target,
    costFunction: myCustomCostFunction
)

// Calculate max flow
let maxResult = Tradewinds.maxFlow(
    routes: routes,
    resources: resources,
    targetNode: targetNode,
    costFunction: myCustomCostFunction
)
```

### 5. Dual Fee Structure

Routes now support two types of fees:
- `inFee`: Deducted from the source amount BEFORE the exchange rate is applied (e.g., gas fees)
- `outFee`: Deducted from the result AFTER the exchange rate is applied (e.g., bridge relayer fees)

The formula is: `sinkAmount = max(0, (sourceAmount - inFee) * rate - outFee)`

A new cost function, `dualFeeCostFunction`, is provided to help optimize for routes with these fees. It accounts for both fee types when calculating route costs.

```swift
let costFn = Tradewinds.dualFeeCostFunction(targetAmount: targetAmount)

let result = Tradewinds.flow(
    //...
    costFunction: costFn
)
```

## Migration Steps

1.  **Define your node enum**: Create an enum conforming to `TradewindsNode`.
2.  **Update route definitions**: Update your `Tradewinds.Route` initializations. You will now provide a `type` (of any `Hashable` & `Comparable` type you choose) instead of an `id`. You can now add `inFee` and/or `outFee` where applicable to model different fee structures.
3.  **Create cost function**: Define how different routes should be prioritized. Consider using `dualFeeCostFunction` if you have routes with fees.
4.  **Update API calls**: Pass your new routes and cost function to the `flow`/`maxFlow` methods.

## Example

```swift
// Define nodes
enum TokenNode: TradewindsNode {
    case usdc(chain: String)
    case eth(chain: String)
    case exit(recipient: String)
}

// Create routes
let routes = [
    Tradewinds.Route(
        type: "bridge",
        source: .usdc(chain: "mainnet"),
        sink: .usdc(chain: "base"),
        rate: 0.999,
        inFee: Number("50000000000000"), // Gas fee paid upfront
        outFee: Number("100000000000000"), // Bridge fee from output
        minFlow: Number(0),
        maxFlow: Number(10_000) * Number(10).power(6)
    )
]

// Define cost function
let targetAmount = Number(500) * Number(10).power(6)
let costFn = Tradewinds.dualFeeCostFunction(targetAmount: targetAmount)

// Use the API
let result = Tradewinds.flow(
    routes: routes,
    resources: [.init(amount: .exact(Number(1000) * Number(10).power(6)), node: .usdc(chain: "mainnet"))],
    target: .init(amount: .exact(targetAmount), node: .usdc(chain: "base")),
    costFunction: costFn
)
```

## Benefits

- **Type Safety**: Nodes are now strongly typed with your domain model
- **Flexibility**: Any routing preference can be expressed via cost functions
- **Simplicity**: Core algorithm focuses only on graph optimization
- **Extensibility**: Nodes can carry data (e.g., addresses, metadata)
