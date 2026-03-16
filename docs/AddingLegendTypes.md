# Adding Legend Types to Charter

This guide explains how to add new `LegendNode` or `LegendRouteType` cases to the Charter system.

## Adding a New LegendNode

To add a new node type, update these files:

1. **`Sources/Mercator/Charter/LegendNode.swift`**
   - Add the new case to the `LegendNode` enum
   - Update the `label` computed property
   ```swift
   case swapPool(network: Network, tokenA: String, tokenB: String)
   
   // In label:
   case .swapPool(let network, let tokenA, let tokenB): 
       return "\(tokenA)/\(tokenB) Pool(\(network))"
   ```

2. **`Sources/Mercator/Charter/Charter+Tradewinds.swift`**
   - Update `buildRoutesToTarget()` if the new node can be a route source/sink
   - Update `getNodes()` if needed for resource extraction

## Adding a New LegendRouteType

To add a new route type, update these files:

1. **`Sources/Mercator/Charter/LegendRouteType.swift`**
   - Add the new case to the `LegendRouteType` enum
   - Update `description`, `label()`, and `order` properties
   ```swift
   case swap
   
   // In description:
   case .swap: return "Token Swap"
   
   // In order:
   case .swap: 2
   ```

2. **`Sources/Mercator/Charter/Charter+QuarkIntent+TradewindsTarget.swift`**
   - Update the intent handling to use the new route type
   - Modify `buildRoutesToTarget()` to create routes with the new type

3. **`Sources/Mercator/Charter/LegendRouteType.swift`**
   - Update `getQuarkOperations()` to handle the new route type
   - Map the route type to appropriate QuarkOperations

## Example: Adding a Swap Route

```swift
// In LegendRouteType.swift
case swap

// In getQuarkOperations()
case .swap:
    return [SwapOperation(...)]

// In Charter+Tradewinds.swift
if canSwap(source, target) {
    routes.append(Route(
        id: .swap,
        source: source,
        sink: target,
        rate: getSwapRate(source, target),
        ...
    ))
}
```

## Testing

After adding new types:
1. Update tests in `Tests/CharterTests/` to cover the new cases
2. Run `swift test` to ensure everything compiles
3. Add test cases that exercise the new nodes/routes