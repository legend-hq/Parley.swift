import Foundation
import SwiftNumber
import Testing
import Tradewinds

@testable import Charter

/// Tests for dual-fee routing scenarios in Tradewinds.
struct TradewindsFixedCostTests {

    @Test("Single Route with OutFee")
    func testSingleRouteWithOutFee() {
        // Graph: A -> B
        // A simple test to ensure the outFee is correctly subtracted from the sink amount.
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "10e6")  // 10 units
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        runFlowTest(
            .init(
                name: "Single Route with OutFee",
                routes: [route],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "50e6"),
                // To get 50 at sink, we need to send 60 (50 + 10 outFee).
                // Max flow is 100 (source) - 10 (outFee) = 90.
                expect: .exactFlows(
                    [
                        .init(route: route, amount: "60e6")
                    ],
                    maxFlow: "90e6"
                )
            )
        )
    }

    @Test("Multi-Hop with Mixed Fees")
    func testMultiHopWithMixedFees() {
        // Graph: A -> B -> C
        // Tests that inFee and outFee from multiple routes in a path are correctly applied.
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "inFee", isInFee: true, amount: "2e6"),
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "3e6"),
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "inFee", isInFee: true, amount: "4e6"),
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "4e6"),
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        runFlowTest(
            .init(
                name: "Multi-Hop with Mixed Fees",
                routes: [routeAB, routeBC],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .C),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "50e6"),
                // Working backwards: 50 at C + 4 outFee = 54, / 1.0 = 54, + 4 inFee = 58 at B
                // 58 at B + 3 outFee = 61, / 1.0 = 61, + 2 inFee = 63 at A
                // Max flow: 100 - 2 = 98, * 1.0 = 98, - 3 = 95 at B
                // 95 - 4 = 91, * 1.0 = 91, - 4 = 87 at C
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "63e6"),
                        .init(route: routeBC, amount: "58e6"),
                    ],
                    maxFlow: "87e6"
                )
            )
        )
    }

    @Test("Max Flow Calculation with Dual Fees")
    func testMaxFlowWithDualFees() {
        // Graph: A -> B
        // Tests that max flow correctly accounts for both inFee and outFee.
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.9,
            fees: [
                Tradewinds.Fee(type: "inFee", isInFee: true, amount: "2e6"),
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "3e6"),
            ],
            minFlow: "0",
            maxFlow: "100e6"
        )

        runFlowTest(
            .init(
                name: "Max Flow with Dual Fees",
                routes: [route],
                resources: [.init(amount: .exact("50e6"), node: .A)],
                target: .init(amount: .max, node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                // Max from source is 50. After inFee: 50 - 2 = 48. Rate adjusted: 48 * 0.9 = 43.2. After outFee: 43.2 - 3 = 40.2.
                expect: .maxFlow(
                    sinkAmount: "40.2e6",
                    flows: [
                        .init(route: route, amount: "50e6")
                    ]
                )
            )
        )
    }

    @Test("High Fees Make Route Unusable")
    func testHighFeesMakeRouteUnusable() {
        // Graph: A -> B
        // Tests a scenario where the fees are greater than the amount that can be delivered,
        // making the route impossible to use for a given target.
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.5,
            fees: [
                Tradewinds.Fee(type: "inFee", isInFee: true, amount: "5e6"),
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "15e6"),
            ],
            minFlow: "0",
            maxFlow: "100e6"
        )

        runFlowTest(
            .init(
                name: "High Fees Make Route Unusable",
                routes: [route],
                resources: [.init(amount: .exact("30e6"), node: .A)],
                target: .init(amount: .exact("10e6"), node: .B),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "10e6"),
                // To get 10, work backwards: 10 + 15 (outFee) = 25, / 0.5 = 50, + 5 (inFee) = 55. We only have 30.
                // Max flow is (30 - 5) * 0.5 - 15 = 12.5 - 15 = 0.
                expect: .failure(
                    .insufficientResources(target: .exact("10e6"), max: "0"),
                    maxFlow: "0"
                )
            )
        )
    }

    @Test("Parallel Routes with Mixed Fees")
    func testParallelRoutesWithMixedFees() {
        // Graph: A => B
        // One route has a better rate but fees, the other has a worse rate and no fees.
        // The cost function should guide the choice based on the target amount.
        let highRateRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_high_rate",
            source: .A,
            sink: .B,
            rate: 0.99,
            fees: [
                Tradewinds.Fee(type: "inFee", isInFee: true, amount: "5e6"),
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "5e6"),
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let lowRateRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_low_rate",
            source: .A,
            sink: .B,
            rate: 0.95,
            fees: [],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        // Scenario 1: Small transfer. The low-rate, no-fee route should be cheaper.
        runFlowTest(
            .init(
                name: "Parallel Mixed Fees - Small Transfer",
                routes: [highRateRoute, lowRateRoute],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("20e6"), node: .B),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "20e6"),
                // Low rate: 20 / 0.95 = 21.05. Cost ~ -log(0.95) = 0.051
                // High rate: (20+5)/0.99 + 5 = 30.25. Cost ~ -log(0.99) + 10/20 = 0.01 + 0.5 = 0.51
                // Low rate route is chosen.
                // Max flow is 100 * 0.95 = 95, vs (100-5)*0.99-5 = 89.05.
                expect: .exactFlows(
                    [
                        .init(route: lowRateRoute, amount: "21.052632e6")
                    ],
                    maxFlow: "95e6"
                )
            )
        )

        // Scenario 2: Large transfer. The high-rate route becomes more efficient.
        runFlowTest(
            .init(
                name: "Parallel Mixed Fees - Large Transfer",
                routes: [highRateRoute, lowRateRoute],
                resources: [.init(amount: .exact("1000e6"), node: .A)],
                target: .init(amount: .exact("500e6"), node: .B),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "500e6"),
                // Low rate: 500 / 0.95 = 526.3. Cost ~ 0.051
                // High rate: backwards calc: 500 + 5 (outFee) = 505, / 0.99 = 510.101, + 5 (inFee) = 515.101
                // High rate route is chosen. Cost ~ -log(0.99) + 10/500 = 0.01 + 0.02 = 0.03
                // Max flow is (1000-5)*0.99-5 = 980.05, which is better than 1000 * 0.95 = 950.
                expect: .exactFlows(
                    [
                        .init(route: highRateRoute, amount: "515.101011e6")
                    ],
                    maxFlow: "980.05e6"
                )
            )
        )
    }

    @Test("Fixed Cost Route Selection - Dual Fee Optimal")
    func testFixedCostRouteSelection_DualFeeOptimal() {
        // This test demonstrates that dualFeeCostFunction correctly handles
        // the mainnet vs L2 bridge scenario where fixed costs dominate.
        //
        // Scenario: Bridge $50 from either Mainnet or Arbitrum to Base
        // - Mainnet: Better rate (0.999), High gas ($20)
        // - Arbitrum: Worse rate (0.98), Low gas ($2)
        //
        // With dualFeeCostFunction, the algorithm correctly chooses Arbitrum
        // because the total cost is lower despite the worse rate.
        //
        // Mainnet total: $50/0.999 + $20 = $70.07
        // Arbitrum total: $50/0.98 + $2 = $53.04 ✓ (saves $17.03)

        let mainnetBridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "mainnet_bridge",
            source: .A,
            sink: .C,
            rate: 0.999,
            fees: [
                Tradewinds.Fee(type: "gas", isInFee: true, amount: "20e6")
            ],
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let arbitrumBridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "arbitrum_bridge",
            source: .B,
            sink: .C,
            rate: 0.98,
            fees: [
                Tradewinds.Fee(type: "gas", isInFee: true, amount: "2e6")
            ],
            minFlow: "0",
            maxFlow: "10000e6"
        )

        runFlowTest(
            .init(
                name: "Dual Fee Chooses Optimal Route",
                routes: [mainnetBridge, arbitrumBridge],
                resources: [
                    .init(amount: .exact("100e6"), node: .A),
                    .init(amount: .exact("100e6"), node: .B),
                ],
                target: .init(amount: .exact("50e6"), node: .C),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "50e6"),
                // dualFeeCostFunction correctly chooses Arbitrum:
                // - Mainnet cost: -log(0.999) + 20/50 = 0.001 + 0.4 = 0.401
                // - Arbitrum cost: -log(0.98) + 2/50 = 0.020 + 0.04 = 0.060 ✓
                // To get 50: work backwards: 50 / 0.98 = 51.020408, + 2 (inFee) = 53.020408
                // Max flow: Mainnet (100-20)*0.999 + Arb (100-2)*0.98 = 79.92 + 96.04 = 175.96
                expect: .exactFlows(
                    [
                        .init(route: arbitrumBridge, amount: "53.020409e6")
                    ],
                    maxFlow: "175.96e6"
                )
            )
        )
    }

    @Test("InFee vs OutFee Behavior")
    func testInFeeVsOutFeeBehavior() {
        // Graph: A -> B
        // Test to demonstrate the difference between inFee and outFee
        let inFeeRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_inFee",
            source: .A,
            sink: .B,
            rate: 0.5,
            fees: [
                Tradewinds.Fee(type: "inFee", isInFee: true, amount: "10e6")
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )
        let outFeeRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_outFee",
            source: .A,
            sink: .B,
            rate: 0.5,
            fees: [
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "10e6")
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        // Test with inFee route
        runFlowTest(
            .init(
                name: "InFee Route",
                routes: [inFeeRoute],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("40e6"), node: .B),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "40e6"),
                // To get 40: work backwards: 40 / 0.5 = 80, + 10 (inFee) = 90
                // Verification: 90 - 10 = 80, * 0.5 = 40 ✓
                expect: .exactFlows(
                    [
                        .init(route: inFeeRoute, amount: "90e6")
                    ],
                    maxFlow: "45e6"
                )  // Max: (100 - 10) * 0.5 = 45
            )
        )

        // Test with outFee route
        runFlowTest(
            .init(
                name: "OutFee Route",
                routes: [outFeeRoute],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("40e6"), node: .B),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "40e6"),
                // To get 40: work backwards: 40 + 10 (outFee) = 50, / 0.5 = 100
                // Verification: 100 * 0.5 = 50, - 10 = 40 ✓
                expect: .exactFlows(
                    [
                        .init(route: outFeeRoute, amount: "100e6")
                    ],
                    maxFlow: "40e6"
                )  // Max: 100 * 0.5 - 10 = 40
            )
        )
    }
}
