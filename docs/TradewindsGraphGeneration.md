# Tradewinds Graph Generation

## Overview

This document describes the process of converting a user's high-level financial **Intent** (e.g., "transfer 100 USDC to Bob") into a formal graph problem that can be solved by the **Tradewinds** network flow algorithm.

The primary component responsible for this is the extension on `Charter.QuarkIntent.Type_` located in `Charter+QuarkIntent+TradewindsTarget.swift`. Its main purpose is to take the user's intent and the current state of their portfolios and generate a directed graph. The Tradewinds solver then finds the most efficient (lowest cost) path through this graph to fulfill the user's goal.

The graph consists of three main components:
1.  **Nodes (`TradewindsLegendNode`):** These represent specific states in the system, such as an account's token balance on a particular network (e.g., `Alice's USDC balance on Base`).
2.  **Edges (`Tradewinds.Route`):** These represent possible actions or "routes" that can move value between nodes. Each route has a `type` (e.g., `.bridge`, `.transferOut`), a `rate` (cost/exchange rate), and capacity constraints.
3.  **Resources:** These define the initial amount of assets available at each source node.

## Key Components

### `tradewindsInfo(...)`

This is the main public entry point. It takes the user's `intent`, their `portfolios`, and a list of `acrossQuotes` and orchestrates the creation of the graph problem.

-   **Input:** `portfolios`, `acrossQuotes`
-   **Output:** A tuple containing the `routes`, `resources`, and the `target` node and amount for the solver.

### `generateRoutes(...)`

This function is responsible for building the complete set of all possible routes (edges) in the graph. It iterates through all available resource nodes and creates potential routes to all other nodes in the system.

### `generateRoute(...)`

This is the core logic for creating a single edge between a `sourceNode` and a `sinkNode`. It determines which type of action is possible between the two nodes and constructs the appropriate `Tradewinds.Route`.

The current implementation handles three primary scenarios:
1.  **Same-Chain, Different Assets:** Creates `.wrap` or `.unwrap` routes if a valid `TokenWrapperQuote` exists.
2.  **Same-Chain, Same Asset:** Creates `.tokenTransfer` (between user's own wallets) or `.transferOut` (to an external wallet) routes.
3.  **Cross-Chain, Same Asset:** Creates a `.bridge` route if a valid `AcrossQuote` exists for the given path.

---

### Suggestions for Improvement

1.  **Function Naming:** The function name `tradewindsInfo` is a bit generic. Consider renaming it to something more descriptive that reflects its purpose, such as `buildTradewindsGraph()` or `generateTradewindsProblem()`. This would make the code's intent clearer at the call site.

2.  **Route Generation Performance:** The `generateRoutes` function currently operates with `O(n^2)` complexity, where `n` is the number of nodes. It checks every possible pair of nodes for a valid route. For portfolios with a very large number of assets and accounts, this could become a performance bottleneck. If this becomes an issue, we could explore more optimized ways to generate routes, perhaps by being more selective about which node pairs to check.

3.  **Bridge Rate Calculation:** In `generateRoute`, the exchange rate for a bridge is calculated using a hardcoded `sourceAmountForRate` of `1,000,000 * 1e18`. This "magic number" could be problematic:
    *   It might not be an appropriate amount for all tokens, especially those with few decimals.
    *   It could lead to precision loss or rounding errors when calculating the rate.
    *   **Suggestion:** A more robust approach might be to normalize the rate calculation. For example, calculate the rate based on transferring **1 full unit** of the source token (e.g., `1 * 10^decimals`). This would make the rate calculation more predictable and less prone to errors.

### Open Questions

1.  **Handling Other Intents:** The `tradewindsInfo` function currently only handles the `.transfer` intent. What is the plan for supporting other intents like `.swapAndSupply`, `.loopLong`, etc.? Will they also be converted into graph problems for Tradewinds, or will they use a different mechanism?

2.  **Bridge Route ID Uniqueness:** The previous issue with duplicate keys for "bridge" routes was solved by making the `Route.id` a computed property. Is the current format (`"\(type)-\(source)-\(sink)-\(rate)"`) guaranteed to be unique enough for all planned route types?

3.  **Cost Function:** The `tradewindsCostFn` currently returns a simple negative log of the rate. Are there plans to incorporate other factors into the cost, such as gas fees, time estimates, or risk profiles?