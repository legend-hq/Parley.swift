import Foundation
import SwiftNumber
import Testing
import Tradewinds

@testable import Charter

/// Tests for advanced Tradewinds features, such as custom cost functions and special node types.
struct TradewindsAdvancedTests {

    @Test("Parallel Routes with Custom Cost")
    func testParallelRoutesWithCustomCost() {
        // Graph: A => B
        // Tests that a custom cost function can override the default rate-based selection,
        // forcing the algorithm to choose a path with a worse exchange rate.
        let goodRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_good_rate",
            source: .A,
            sink: .B,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let badRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_bad_rate",
            source: .A,
            sink: .B,
            rate: 0.95,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let customCost: Tradewinds.CostFunction<TradewindsTestNode, String> = { route in
            // Prefer the route with the "bad" rate by giving it a lower cost.
            route.id == "A->B_bad_rate" ? 1.0 : 10.0
        }

        runFlowTest(
            .init(
                name: "Parallel Routes with Custom Cost",
                routes: [goodRoute, badRoute],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),
                costFunction: customCost,
                expect: .exactFlows(
                    [
                        .init(route: badRoute, amount: "52.631579e6")  // 50.0 / 0.95
                    ],
                    maxFlow: "95e6"
                )
            )
        )
    }

    @Test("Cost Function Filtering")
    func testCostFunctionFiltering() {
        // Graph: A => B
        // Tests that returning `nil` from a cost function effectively disables a route.
        let blockedRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_blocked",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let allowedRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_allowed",
            source: .A,
            sink: .B,
            rate: 0.98,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let customCost: Tradewinds.CostFunction<TradewindsTestNode, String> = { route in
            if route.type == "A->B_blocked" { return nil }  // Block this route
            return -log(route.rate.asDouble)
        }

        runFlowTest(
            .init(
                name: "Cost Function Filtering",
                routes: [blockedRoute, allowedRoute],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),
                costFunction: customCost,
                expect: .exactFlows(
                    [
                        .init(route: allowedRoute, amount: "51.020409e6")
                    ],
                    maxFlow: "98e6"
                )
            )
        )
    }

    @Test("Complex Multi-Hop with Custom Cost")
    func testComplexMultiHopWithCustomCost() {
        // Graph: A -> B -> C
        // Tests a multi-hop scenario where the cost function includes non-rate-based penalties (e.g., time).
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 0.98,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let timeBasedCost: Tradewinds.CostFunction<TradewindsTestNode, String> = { route in
            let baseCost = -log(route.rate.asDouble)
            switch route.id {
                case "A->B": return baseCost + 0.5  // Slower route
                case "B->C": return baseCost  // Faster route
                default: return baseCost
            }
        }

        runFlowTest(
            .init(
                name: "Complex Multi-Hop with Custom Cost",
                routes: [routeAB, routeBC],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .C),
                costFunction: timeBasedCost,
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "51.535767e6"),  // Exact amount needed at A
                        .init(route: routeBC, amount: "51.020409e6"),  // 51.535767e6 * 0.99 (truncated)
                    ],
                    maxFlow: "97.02e6"
                )
            )
        )
    }

    @Test("Exit Node with Associated Data")
    func testExitNodeWithData() {
        // Graph: A -> ExitNode
        // Tests that the algorithm can handle nodes with associated data (e.g., a specific address).
        let bobAddress = "0x0000000000000000000000000000000000000B0B"
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "exit_to_bob",
            source: .A,
            sink: .sendTo(address: bobAddress),
            rate: 1.0,
            minFlow: "0",
            maxFlow: "1000e6"
        )

        runFlowTest(
            .init(
                name: "Exit Node with Associated Data",
                routes: [route],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .sendTo(address: bobAddress)),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: route, amount: "50e6")
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Max Flow with Custom Cost")
    func testMaxFlowWithCustomCost() {
        // Graph: A => B
        // Tests that max flow is correctly calculated with a custom cost function.
        let goodRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_good_rate",
            source: .A,
            sink: .B,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let badRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_bad_rate",
            source: .A,
            sink: .B,
            rate: 0.95,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let customCost: Tradewinds.CostFunction<TradewindsTestNode, String> = { route in
            // Prefer the route with the "bad" rate by giving it a lower cost.
            route.id == "A->B_bad_rate" ? 1.0 : 10.0
        }

        runFlowTest(
            .init(
                name: "Max Flow with Custom Cost",
                routes: [goodRoute, badRoute],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .max, node: .B),
                costFunction: customCost,
                expect: .maxFlow(
                    sinkAmount: "95e6",
                    flows: [
                        .init(route: badRoute, amount: "100e6")
                    ]
                )
            )
        )
    }

    @Test("Simple Graph Cycle")
    func testSimpleGraphCycle() {
        // Graph: A -> B -> A (cycle)
        // Tests that the algorithm finds the direct path to a target within a cycle
        // without getting stuck.
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeBA: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->A",
            source: .B,
            sink: .A,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "100e6"
        )

        runFlowTest(
            .init(
                name: "Simple Graph Cycle",
                routes: [routeAB, routeBA],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),  // Target is in the cycle
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "50e6")
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Graph Cycle with Exit Path")
    func testGraphCycleWithExitPath() {
        // Graph: A -> B, B -> C -> B (cycle), B -> D (exit)
        // Tests that the algorithm can navigate around a cycle to find a valid path to the target.
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeCB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "C->B",
            source: .C,
            sink: .B,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeBD: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->D",
            source: .B,
            sink: .D,
            rate: 0.95,
            minFlow: "0",
            maxFlow: "100e6"
        )

        runFlowTest(
            .init(
                name: "Graph Cycle with Exit Path",
                routes: [routeAB, routeBC, routeCB, routeBD],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .D),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "52.631579e6"),  // 50 / 0.95
                        .init(route: routeBD, amount: "52.631579e6"),
                    ],
                    maxFlow: "95e6"
                )
            )
        )
    }

    @Test("Arbitrage Cycle with Exit Path")
    func testArbitrageCycleWithExitPath() {
        // Graph: A -> B, B -> C -> B (arbitrage cycle, rate > 1), B -> D (exit)
        // Tests that the algorithm can find a path to a target even when it must
        // traverse a node that is part of a negative-cost (arbitrage) cycle.
        // The current implementation should not get stuck due to its Dijkstra variant.
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.9,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 1.2,
            minFlow: "0",
            maxFlow: "100e6"
        )  // Profitable
        let routeCB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "C->B",
            source: .C,
            sink: .B,
            rate: 1.2,
            minFlow: "0",
            maxFlow: "100e6"
        )  // Profitable
        let routeBD: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->D",
            source: .B,
            sink: .D,
            rate: 0.9,
            minFlow: "0",
            maxFlow: "100e6"
        )

        runFlowTest(
            .init(
                name: "Arbitrage Cycle with Exit Path",
                routes: [routeAB, routeBC, routeCB, routeBD],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .D),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "61.728396e6"),  // 50 / (0.9 * 0.9)
                        .init(route: routeBD, amount: "55.555556e6"),  // 50 / 0.9
                    ],
                    maxFlow: "81e6"
                )  // 100 * 0.9 * 0.9
            )
        )
    }
}
