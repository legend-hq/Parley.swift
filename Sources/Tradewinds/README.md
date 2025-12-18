# Tradewinds

A Swift package for solving multi-commodity network flow optimization problems with deterministic results.

## Overview

Tradewinds implements a network flow solver that finds optimal paths for routing resources between nodes while considering:
- Exchange rates between routes
- Capacity constraints
- Time constraints
- Multiple source and destination nodes

The algorithm uses Dijkstra's shortest path with logarithmic cost functions to optimize for the best exchange rates while ensuring deterministic results through consistent tie-breaking.

## Key Features

- **Deterministic Results**: All operations use stable sorting and tie-breaking to ensure reproducible results
- **Multi-Path Routing**: Automatically finds multiple paths when single routes have insufficient capacity
- **Time Categories**: Support for fast/medium/slow route filtering
- **Rate Optimization**: Uses logarithmic costs to find paths with the best combined exchange rates

## Usage

```swift
import Tradewinds
import SwiftNumber

// Define routes between nodes
let routes = [
    Tradewinds.Route(
        id: "ROUTE_A_B",
        source: 0,  // Node A
        sink: 1,    // Node B
        rate: 0.99, // 1% fee
        time: 10,
        minFlow: Number(0),
        maxFlow: Number(1000)
    )
]

// Define available resources
let resources = [
    Tradewinds.Resource(Number(500), of: 0)  // 500 units at Node A
]

// Find optimal flows to achieve target amount
let result = Tradewinds.flow(
    withRoutes: routes,
    withResource: resources,
    forTargetAmount: Number(400),
    ofResource: 1,  // Target Node B
    onlyTimeCategory: .any
)

// Or find maximum achievable amount
let maxResult = Tradewinds.max_target(
    withRoutes: routes,
    withResource: resources,
    forTarget: 1,
    onlyTimeCategory: .fast
)
```

## Algorithm Details

The solver uses a modified Dijkstra's algorithm with:
- Cost function: `-log(rate)` to optimize for best exchange rates
- Deterministic tie-breaking by route ID and node ID
- Iterative flow augmentation to handle capacity constraints
- Sorted output for consistent results

## Dependencies

- SwiftNumber: For arbitrary precision arithmetic
- Foundation: For basic Swift types and utilities