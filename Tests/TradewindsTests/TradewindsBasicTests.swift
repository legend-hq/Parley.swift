import Foundation
import Prelude
import SwiftNumber
import Testing
import Tradewinds

@testable import Charter

/// Tests for fundamental Tradewinds scenarios, focusing on single and parallel paths.
struct TradewindsBasicTests {

    @Test("Single Route Flow")
    func testSingleRouteFlow() {
        // Graph: A -> B
        // Tests a simple, single-edge flow.
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        runFlowTest(
            .init(
                name: "Single Route Flow",
                routes: [route],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: route, amount: "50.505051e6")  // 50.0e6 / 0.99
                    ],
                    maxFlow: "99e6"
                )
            )
        )
    }

    @Test("Parallel Route Selection by Rate")
    func testParallelRouteSelection() {
        // Graph: A => B (two parallel routes)
        // Tests that the algorithm correctly chooses the path with the best exchange rate.
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
        runFlowTest(
            .init(
                name: "Parallel Route Selection by Rate",
                routes: [goodRoute, badRoute],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: goodRoute, amount: "50.505051e6")
                    ],
                    maxFlow: "99e6"
                )
            )
        )
    }

    @Test("Insufficient Resources to Meet Target")
    func testInsufficientResources() {
        // Graph: A -> B
        // Tests the failure case where available resources are less than the required target.
        runFlowTest(
            .init(
                name: "Insufficient Resources",
                routes: [
                    .init(
                        type: "A->B",
                        source: .A,
                        sink: .B,
                        rate: 1.0,
                        minFlow: "0",
                        maxFlow: "1000e6"
                    )
                ],
                resources: [.init(amount: .exact("10e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(
                    .insufficientResources(target: .exact("50e6"), max: "10e6"),
                    maxFlow: "10e6"
                )
            )
        )
    }

    @Test("Route Capacity Is the Bottleneck")
    func testRouteCapacityLimit() {
        // Graph: A -> B
        // Tests that the route's maxFlow is respected and becomes the bottleneck.
        runFlowTest(
            .init(
                name: "Route Capacity Is the Bottleneck",
                routes: [
                    .init(
                        type: "A->B_limited",
                        source: .A,
                        sink: .B,
                        rate: 1.0,
                        minFlow: "0",
                        maxFlow: "20e6"
                    )
                ],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(
                    .insufficientResources(target: .exact("50e6"), max: "20e6"),
                    maxFlow: "20e6"
                )
            )
        )
    }

    @Test("Max Flow Calculation from Multiple Sources")
    func testMaxFlowCalculation() {
        // Graph: A->C, B->C
        // Tests the calculation of the maximum achievable flow at a sink from multiple sources.
        let routeAC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->C",
            source: .A,
            sink: .C,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 0.98,
            minFlow: "0",
            maxFlow: "100e6"
        )
        runFlowTest(
            .init(
                name: "Max Flow Calculation",
                routes: [routeAC, routeBC],
                resources: [
                    .init(amount: .exact("70e6"), node: .A),
                    .init(amount: .exact("50e6"), node: .B),
                ],
                target: .init(amount: .max, node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                // Max flow is the sum of all possible inputs adjusted by their rates.
                // 70 * 0.99 + 50 * 0.98 = 69.3 + 49 = 118.3
                expect: .maxFlow(
                    sinkAmount: "118.3e6",
                    flows: [
                        .init(route: routeAC, amount: "70e6"),
                        .init(route: routeBC, amount: "50e6"),
                    ]
                )
            )
        )
    }

    @Test("Max Flow with Single Route")
    func testMaxFlowWithSingleRoute() {
        // Graph: A -> B
        // Tests that max flow is correctly calculated for a single route.
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.9,
            minFlow: "0",
            maxFlow: "100e6"
        )
        runFlowTest(
            .init(
                name: "Max Flow with Single Route",
                routes: [route],
                resources: [.init(amount: .exact("50e6"), node: .A)],
                target: .init(amount: .max, node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .maxFlow(
                    sinkAmount: "45e6",
                    flows: [
                        .init(route: route, amount: "50e6")
                    ]
                )
            )
        )
    }

    @Test("Multi-Route Flow Fails When MinFlow Not Met")
    func testMultiRouteFlowFailsWhenMinFlowNotMet() {
        // Graph: A->C (good rate, no min, max 50), B->C (bad rate, min 100, max 1000)
        // Target is 70. A->C provides 49.5. Remainder is 20.5.
        // To get 20.5 from B->C, need to send ~20.9, which is < minFlow of 100.
        // So B->C is not usable. The flow should fail.
        let routeAC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->C",
            source: .A,
            sink: .C,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "50e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 0.98,
            minFlow: "100e6",
            maxFlow: "1000e6"
        )
        runFlowTest(
            .init(
                name: "Multi-Route Flow Fails When MinFlow Not Met",
                routes: [routeAC, routeBC],
                resources: [
                    .init(amount: .exact("100e6"), node: .A),
                    .init(amount: .exact("1000e6"), node: .B),
                ],
                target: .init(amount: .exact("70e6"), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                // Max flow is 50*0.99 + 1000*0.98 = 49.5 + 980 = 1029.5
                expect: .failure(
                    .insufficientResources(target: .exact("70e6"), max: "49.5e6"),
                    maxFlow: "1029.5e6"
                )
            )
        )
    }

    @Test("Multi-Route Flow Succeeds When MinFlow Is Met")
    func testMultiRouteFlowSucceedsWhenMinFlowIsMet() {
        // Graph: A->C (good rate, no min, max 50), B->C (bad rate, min 100, max 1000)
        // Target is 150e6. A->C provides round(50e6 * 0.99) = 49500000.
        // Remainder is 100500000.
        // To get 100500000 from B->C (rate 0.98), need 100500000/0.98 = 102551020.408...
        // HP precision requires ceiling: 102551021 (ensures delivery of at least target)
        // which is > minFlow of 100e6. So B->C is usable. The flow should succeed.
        let routeAC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->C",
            source: .A,
            sink: .C,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "50e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 0.98,
            minFlow: "100e6",
            maxFlow: "1000e6"
        )
        runFlowTest(
            .init(
                name: "Multi-Route Flow Succeeds When MinFlow Is Met",
                routes: [routeAC, routeBC],
                resources: [
                    .init(amount: .exact("100e6"), node: .A),
                    .init(amount: .exact("1000e6"), node: .B),
                ],
                target: .init(amount: .exact("150e6"), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAC, amount: "50e6"),
                        .init(route: routeBC, amount: "102.551021e6"),  // (150 - 49.5) / 0.98
                    ],
                    maxFlow: "1029.5e6"
                )
            )
        )
    }

    @Test("Single Route Fails When Target Below MinFlow")
    func testSingleRouteFailsWhenTargetBelowMinFlow() {
        // User wants 20 but route requires minimum 50
        // Should FAIL - we never overshoot the user's intended target
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "50e6",
            maxFlow: "150e6"
        )
        runFlowTest(
            .init(
                name: "Single Route Fails When Target Below MinFlow",
                routes: [routeAB],
                resources: [
                    .init(amount: .exact("100e6"), node: .A)
                ],
                target: .init(amount: .exact("20e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(
                    .insufficientResources(target: .exact("20e6"), max: .zero),
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Exact Constraint with Bridge - Partial Flow")
    func testExactConstraintWithBridgeFlowConservation() {
        // This test verifies that partial flows are allowed even with exact constraints
        // Graph: A -> B -> C
        // A -> B has exact constraint (minFlow = maxFlow = 3000e6)
        // B -> C is a bridge with rate 0.999 and fixed cost 5e6
        // The bridge should only receive what's needed for the target, not the full withdrawal amount

        let exactWithdraw: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_exact",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "3000e6",  // Exact constraint
            maxFlow: "3000e6"  // Exact constraint
        )

        let bridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C_bridge",
            source: .B,
            sink: .C,
            rate: 0.999,  // 0.1% fee
            fees: [Tradewinds.Fee(type: "bridge", isInFee: false, amount: "5e6")],  // Fixed bridge cost as outFee
            minFlow: "1e6",
            maxFlow: "10000e6"
        )

        runFlowTest(
            .init(
                name: "Exact Constraint with Bridge",
                routes: [exactWithdraw, bridge],
                resources: [.init(amount: .exact("3000e6"), node: .A)],
                target: .init(amount: .exact("2990e6"), node: .C),  // Target less than withdrawal to account for fees
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: exactWithdraw, amount: "3000e6"),  // Should withdraw exactly 3000
                        .init(route: bridge, amount: "2997997998"),  // Algorithm calculates: 2997997998 * 0.999 - 5e6 = 2990e6 delivered
                    ],
                    maxFlow: "2992e6"  // 3000e6 * .999 - 5e6 = 2992e6 max flow
                )
            )
        )
    }

    // MARK: - Target Overshoot Bug Tests

    @Test("Single-Hop Path Does Not Overshoot")
    func testSingleHopPathDoesNotOvershoot() {
        // Graph: A -> B with minFlow = 80, target = 60
        // Should FAIL because we cannot send 60 when route requires minimum 80
        // We never overshoot the user's intended target amount
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "80e6",
            maxFlow: "200e6"
        )
        runFlowTest(
            .init(
                name: "Single Route Fails When Target Below MinFlow",
                routes: [route],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("60e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(
                    .insufficientResources(target: .exact("60e6"), max: .zero),
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Multi-Hop Path Does Not Overshoot")
    func testMultiHopPathDoesNotOvershoot() {
        // Graph: A -> B -> C
        // A -> B has minFlow = 80, B -> C has no minFlow
        // Target at C is 60
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "80e6",
            maxFlow: "200e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "200e6"
        )
        runFlowTest(
            .init(
                name: "MinFlow Forces Target Overshoot - Multi-Hop Path",
                routes: [routeAB, routeBC],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("60e6"), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "80e6"),
                        .init(route: routeBC, amount: "60e6"),
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Complex Multi-Hop with Multiple MinFlow Constraints")
    func testComplexMultiHopWithMultipleMinFlowConstraints() {
        // Graph: A -> B -> C -> D
        // A -> B has minFlow = 60
        // B -> C has minFlow = 80
        // C -> D has no minFlow
        // Target at D is 40
        // This tests that B->C minFlow=80 is satisfied while C->D only flows 40
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "60e6",
            maxFlow: "200e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 1.0,
            minFlow: "80e6",
            maxFlow: "200e6"
        )
        let routeCD: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "C->D",
            source: .C,
            sink: .D,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "200e6"
        )
        runFlowTest(
            .init(
                name: "Complex Multi-Hop with Multiple MinFlow Constraints",
                routes: [routeAB, routeBC, routeCD],
                resources: [.init(amount: .exact("150e6"), node: .A)],
                target: .init(amount: .exact("40e6"), node: .D),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // A->B must flow at least 60 (its minFlow), but needs to flow 80 to satisfy B->C
                        .init(route: routeAB, amount: "80e6"),
                        // B->C must flow 80 (its minFlow)
                        .init(route: routeBC, amount: "80e6"),
                        // C->D only needs to flow 40 (the target amount)
                        .init(route: routeCD, amount: "40e6"),
                    ],
                    maxFlow: "150e6"
                )
            )
        )
    }

    @Test("Complex Multi-Hop with local minimums")
    func testComplexMultiHopWithLocalMins() {
        // Scenario: Avoid getting stuck on "local" minFlow paths.
        //
        // Graph topology
        //   A ──> B ──> F   (B→F has minFlow = 40)
        //   C ─────────> F (C→F has minFlow = 20)
        //   D ──> E ──> F   (E→F has minFlow = 10; D→E has a fixed cost)
        //
        // Resources
        //   A: 45, C: 20, D: 20
        // Target
        //   Deliver exactly 50 to F
        //
        // Why this can get tricky
        // - If the solver greedily consumes the C→F path first (minFlow = 20),
        //   the remaining target becomes 30. The B→F path requires a minFlow = 40,
        //   which is > 30 and therefore infeasible for the last hop (we never overshoot).
        //   That would leave the problem unsatisfied even though a feasible combination exists.
        //
        // Correct strategy (what we expect)
        // - Use A→B with 45, then B→F with its minFlow 40 to contribute 40 to F.
        // - Use D→E with 20 (pays a 10 fixed cost), then E→F with its minFlow 10 to contribute the
        //   remaining 10 to F.
        // - Do NOT use C→F, because forcing 20 there makes the residual < 40 and blocks B→F.
        //
        // This test verifies the solver avoids local minima and finds the globally feasible
        // combination that respects all minFlow constraints without overshooting the target.
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [Tradewinds.Fee(type: "fixed", isInFee: false, amount: "5e6")],
            minFlow: "0e6",
            maxFlow: "200e6"
        )
        let routeBF: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->F",
            source: .B,
            sink: .F,
            rate: 1.0,
            minFlow: "40e6",
            maxFlow: "200e6"
        )
        let routeCF: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "C->F",
            source: .C,
            sink: .F,
            rate: 1.0,
            minFlow: "20e6",
            maxFlow: "200e6"
        )
        let routeDE: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "D->E",
            source: .D,
            sink: .E,
            rate: 1.0,
            fees: [Tradewinds.Fee(type: "fixed", isInFee: false, amount: "10e6")],
            minFlow: "0e6",
            maxFlow: "200e6"
        )
        let routeEF: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "E->F",
            source: .E,
            sink: .F,
            rate: 1.0,
            minFlow: "10e6",
            maxFlow: "200e6"
        )
        runFlowTest(
            .init(
                name: "Complex Multi-Hop with local minimums",
                routes: [routeAB, routeBF, routeCF, routeDE, routeEF],
                resources: [
                    .init(amount: .exact("45e6"), node: .A),
                    .init(amount: .exact("20e6"), node: .C),
                    .init(amount: .exact("20e6"), node: .D),
                ],
                target: .init(amount: .exact("50e6"), node: .F),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "45e6"),
                        .init(route: routeCF, amount: "20e6"),
                        .init(route: routeDE, amount: "20e6"),
                        .init(route: routeBF, amount: "40e6"),
                        .init(route: routeEF, amount: "10e6"),
                    ],
                    maxFlow: "70e6"
                )
            )
        )
    }

    @Test("Exact MinFlow=MaxFlow Constraint Should Not Be Violated By Alternative Resource")
    func testExactWithdrawalConstraintNotViolatedByAlternativeResource() {
        // This test reproduces the MigrateSupplies/WithdrawBackingToken bug:
        // When we have:
        // - Resource A with 500 available + route A->C with minFlow=500, maxFlow=500 (exact constraint)
        // - Resource B with 100 available + route B->C with no constraints
        // - Target C needs 500
        //
        // Expected: A->C flows exactly 500 (respecting minFlow=maxFlow)
        // Actual Bug: A->C flows ~499.98, B->C flows ~0.02 (violates minFlow constraint!)
        //
        // The minFlow=maxFlow constraint should FORCE exactly 500 through A->C if that route is used.
        // Tradewinds should not be able to reduce flow on A->C below minFlow to use resource B.

        let exactWithdrawal: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->C_exact",
            source: .A,
            sink: .C,
            rate: 1.0,
            minFlow: "500e6",  // Must flow exactly 500 if used
            maxFlow: "500e6"
        )

        let alternativeResource: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "100e6"
        )

        runFlowTest(
            .init(
                name: "Exact Withdrawal Constraint With Alternative Resource",
                routes: [exactWithdrawal, alternativeResource],
                resources: [
                    .init(amount: .exact("500e6"), node: .A),  // Comet supply
                    .init(amount: .exact("100e6"), node: .B),  // Existing token balance
                ],
                target: .init(amount: .exact("500e6"), node: .C),  // Need exactly 500
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // Should use exactly 500 from A (respecting minFlow=maxFlow constraint)
                        // Should NOT use B at all
                        .init(route: exactWithdrawal, amount: "500e6")
                    ],
                    maxFlow: "600e6"  // Total available: 500 + 100
                )
            )
        )
    }

    @Test("Exact MinFlow=MaxFlow with Fees and Multi-Hop Path")
    func testExactWithdrawalWithFeesAndMultiHop() {
        // More realistic scenario matching MigrateSupplies:
        // A (Comet) -> B (Token) -> D (Aave)
        // C (existing token balance) -> B -> D
        //
        // A->B: exact withdrawal (minFlow=500, maxFlow=500)
        // B->D: supply route with fee
        // C->B: use existing balance for fees
        //
        // Target: 500 at D
        // The exact constraint on A->B should force exactly 500 through that path

        let exactWithdrawal: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_exact",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "500e6",
            maxFlow: "500e6"
        )

        let supply: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->D_supply",
            source: .B,
            sink: .D,
            rate: 1.0,
            fees: [Tradewinds.Fee(type: "quotepay", isInFee: true, amount: "0.02e6")],  // Fee deducted from input
            minFlow: "0",
            maxFlow: "1000e6"
        )

        let existingBalance: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "C->B_token",
            source: .C,
            sink: .B,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "100e6"
        )

        runFlowTest(
            .init(
                name: "Exact Withdrawal With Fees Multi-Hop",
                routes: [exactWithdrawal, supply, existingBalance],
                resources: [
                    .init(amount: .exact("500e6"), node: .A),  // Comet supply
                    .init(amount: .exact("100e6"), node: .C),  // Existing token balance
                ],
                target: .init(amount: .exact("500e6"), node: .D),  // Need 500 at Aave
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // Withdraws exactly 500 from A (respects minFlow=maxFlow constraint)
                        .init(route: exactWithdrawal, amount: "500e6"),
                        // Uses 0.02 from C to cover fee
                        .init(route: existingBalance, amount: "0.02e6"),
                        // Supplies 500.02 to D (500 from A + 0.02 from C, minus 0.02 fee = 500 delivered)
                        .init(route: supply, amount: "500.02e6"),
                    ],
                    maxFlow: "599.98e6"
                )
            )
        )
    }

    @Test("MinFlow Satisfied Via Upstream Liquidity")
    func testMinFlowSatisfiedViaUpstreamLiquidity() {
        // Tests that routes with minFlow can be satisfied by upstream routing when local
        // resources are insufficient. The solver must explore multi-hop paths where upstream
        // liquidity flows through intermediate nodes to meet downstream minFlow requirements.
        let bridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_bridge",
            source: .A,
            sink: .B,
            rate: 0.99,  // 1% bridge fee
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let swap: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C_swap",
            source: .B,
            sink: .C,
            rate: 1.0,  // 1:1 swap for simplicity
            minFlow: "50e6",  // Swap requires minimum 50e6
            maxFlow: "10000e6"
        )

        runFlowTest(
            .init(
                name: "MinFlow Satisfied Via Upstream Liquidity",
                routes: [bridge, swap],
                resources: [
                    .init(amount: .exact("1000e6"), node: .A)  // Only Chain A has USDC
                ],
                target: .init(amount: .exact("50e6"), node: .C),  // Want exactly minFlow amount
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // Bridge needs to send enough to meet swap's minFlow after fees
                        // Need 50e6 at B, bridge rate is 0.99, so need ~50.505e6
                        .init(route: bridge, amount: "50.505051e6"),
                        // Swap exactly at minFlow
                        .init(route: swap, amount: "50e6"),
                    ],
                    maxFlow: "990e6"  // 1000*0.99*1.0 = 990
                )
            )
        )
    }

    @Test("Rounding Fixes Precision Loss with Non-Representable Rate")
    func testRoundingFixesPrecisionLoss() {
        // Test that rounding eliminates precision loss for non-representable rates
        // This rate mimics the actual swap test: 0.05e18 / 150.02e6
        // In base-10, this cannot be represented exactly (denominator has factors 13 × 577)
        // With floor division: would lose 1 wei in forward-backward calculation
        // With rounding: should preserve exact amount

        let inputAmount = Number("150.02e6")  // 150.02e6 (6 decimals)
        let targetOutput = Number("0.05e18")  // 0.05e18 (18 decimals)

        // Create rate from this exact ratio
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "USDC->WETH",
            source: .A,
            sink: .B,
            rate: Percentage(fromRatio: targetOutput.asSNumber, over: inputAmount.asSNumber),
            minFlow: "0",
            maxFlow: inputAmount
        )

        runFlowTest(
            .init(
                name: "Rounding Precision Fix",
                routes: [route],
                resources: [.init(amount: .exact(inputAmount), node: .A)],
                target: .init(amount: .exact(targetOutput), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: route, amount: inputAmount)
                    ],
                    maxFlow: targetOutput  // Should be EXACT, not targetOutput - 1
                )
            )
        )
    }

    @Test("Multi-Hop Exact-Out with Rounding")
    func testMultiHopExactOutWithRounding() {
        // Test multi-hop exact-out flow with rounding
        // This tests the ceiling division logic when working backward from target
        // The backward calculation should correctly determine required input amounts

        let targetAmount = Number("1000e6")  // Want exactly 1000 at C

        // Two hops: A -> B -> C
        // Each has a rate slightly less than 1.0 (non-representable)
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: Percentage(fromRatio: Number("997").asSNumber, over: Number("1000").asSNumber),
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: Percentage(fromRatio: Number("998").asSNumber, over: Number("1000").asSNumber),
            minFlow: "0",
            maxFlow: "10000e6"
        )

        // Rounding logic:
        // - Backward pass calculates required flows in HP, constrained flows use ceiling
        // - Backward pass now verifies floored delivery and adjusts flow amounts if needed
        // - Forward pass preserves ceiling via ceil().toNumber() on actualFlows
        // - Flow.sinkAmount uses floor() to ensure bridges never request more than achievable
        // BC: 1000 / 0.998 = 1002.004008016... (HP) → ceil: 1002.004009e6
        // AB: 1002.004008016... / 0.997 = 1005.019065... (HP) → ceil: 1005.019066e6
        // But floor(1005.019066 * 0.997) = 1002.004008, which is 1 wei short!
        // So backward pass adds 1: AB flows 1005.019067 → floor(1005.019067 * 0.997) = 1002.004009 ✓
        // Sink at C: floor(1002.004009 * 0.998) = floor(1000.000000982) = 1000e6 ✓
        //
        // Max possible flow: 5000 * 0.997 * 0.998 = 4975.03

        runFlowTest(
            .init(
                name: "Multi-Hop Exact-Out",
                routes: [routeAB, routeBC],
                resources: [.init(amount: .exact("5000e6"), node: .A)],
                target: .init(amount: .exact(targetAmount), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "1005.019067e6"),
                        .init(route: routeBC, amount: "1002.004009e6"),
                    ],
                    maxFlow: "4975.03e6"
                )
            )
        )
    }

    @Test("Explores Multi-Hop When Direct Path Infeasible")
    func testExploresMultiHopWhenDirectPathInfeasible() {
        // ORIGINAL BUG (not reproduced here):
        // In CharterTradewindsSwapTests, Dijkstra gets stuck repeatedly attempting an infeasible
        // 1-hop path (USDC[base]→WETH[base]) 100 times instead of exploring the viable 2-hop
        // path (USDC[arbitrum]→USDC[base]→WETH[base]). That bug may require more complex
        // conditions to trigger (e.g., specific cost functions, route ordering, or graph structure).
        //
        // Scenario:
        // - Node B has only 100 USDC available (insufficient for the swap)
        // - Node A has 5000 USDC that can bridge to Node B
        // - There's a swap route B->C that requires EXACTLY 3000 USDC (minFlow=maxFlow=3000e6)
        //   This represents an exact-in swap where we must sell exactly 3000 USDC
        // - Target: Get WETH at Node C (doesn't matter how much, just maximize)
        //
        // Graph topology:
        //   A (5000 USDC) --> B (100 USDC) --> C (target: WETH)
        //                     bridge          swap
        //
        // Why this is a bug:
        // 1. Dijkstra finds the lowest-cost path to target: B->C (direct swap)
        // 2. This path is INFEASIBLE because B only has 100 USDC but swap needs 3000 USDC
        // 3. When attempting to use this path fails, nothing changes in the graph state
        // 4. Dijkstra retries the SAME infeasible path until maxIterations (100)
        // 5. It NEVER explores the viable 2-hop path: A->B->C (bridge then swap)
        //
        // Expected behavior (what SHOULD happen):
        // The algorithm should recognize that:
        // 1. Direct path from B has insufficient resources (100 < 3000)
        // 2. Multi-hop path A->B->C is viable
        // 3. Bridge from A provides the needed liquidity at B
        //
        // Current behavior (after fixing resource accounting):
        // - Finds the multi-hop path A->B->C
        // - Bridges 2900 from A (not 3000) because 100 already exists at B
        // - Total at B: 100 (existing) + 2900 (bridged) = 3000 for swap
        // - This is optimal: uses existing resources before moving new ones
        //
        // Previous buggy behavior (before the fix):
        // - Would bridge 3000 from A, ignoring the 100 at B
        // - Left 100 USDC unused at B after the swap
        // - Wasted bridge capacity and fees
        //
        // This differs from testComplexMultiHopWithLocalMins because in that test,
        // all paths are FEASIBLE from their starting resources. Here, we specifically
        // test that the algorithm explores multi-hop paths when direct paths are infeasible.

        let bridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_bridge",
            source: .A,
            sink: .B,
            rate: 1.0,  // No fee for simplicity
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let exactInSwap: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C_swap_exactIn",
            source: .B,
            sink: .C,
            rate: 1.0,  // 1 USDC = 1 unit of target token (simplified)
            minFlow: "3000e6",  // Must swap exactly 3000 USDC
            maxFlow: "3000e6"  // Must swap exactly 3000 USDC
        )

        runFlowTest(
            .init(
                name: "Explores Multi-Hop When Direct Path Infeasible",
                routes: [bridge, exactInSwap],
                resources: [
                    .init(amount: .exact("5000e6"), node: .A),  // Arbitrum has plenty
                    .init(amount: .exact("100e6"), node: .B),  // Base has insufficient for swap
                ],
                target: .init(amount: .max, node: .C),  // Get as much WETH as possible
                costFunction: Tradewinds.rateCostFunction(),
                expect: .maxFlow(
                    sinkAmount: "3000e6",  // Should deliver 3000 (after bridging and swapping)
                    flows: [
                        // Bridges 2900 from A (100 already exists at B, so total = 3000)
                        .init(route: bridge, amount: "2900e6"),
                        // Swaps exactly 3000 from B (100 existing + 2900 bridged)
                        .init(route: exactInSwap, amount: "3000e6"),
                    ]
                )
            )
        )
    }

    @Test("Multi-Start Dijkstra Avoids Cheaper Infeasible Path")
    func testMultiStartDijkstraAvoidsCheaperInfeasiblePath() {
        // This test replicates the exact bug from CharterTradewindsSwapTests.testSwapWithCrossChainBridge
        //
        // BUG SCENARIO:
        // - Two start nodes both initialize Dijkstra with cost=0
        // - From LocalNode: 1-hop path to target (cheaper, but insufficient resources)
        // - From RemoteNode: 2-hop path to target via LocalNode (more expensive, but viable)
        // - Dijkstra prefers the cheaper 1-hop path
        // - Path validation fails (LocalNode has 100, needs 3000)
        // - Algorithm loops, finding same infeasible path 100 times
        //
        // EXPECTED FIX:
        // When exploring from a start node, if a direct route to target cannot satisfy
        // minFlow with available resources, skip it in Dijkstra to force exploration
        // of alternative paths.

        let bridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "bridge_remote_to_local",
            source: .A,  // Remote chain (Arbitrum)
            sink: .B,  // Local chain (Base)
            rate: 1.0,  // No fee for simplicity
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let swap: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "swap_local_to_target",
            source: .B,  // Local chain (Base)
            sink: .C,  // Target (WETH)
            rate: Percentage(fromRatio: Number("1e18").asSNumber, over: Number("3000e6").asSNumber),  // 1 ETH per 3000 USDC
            minFlow: "3000e6",  // Exact-in swap requires exactly 3000 USDC
            maxFlow: "3000e6"
        )

        // Cost analysis:
        // Bridge: -log(1.0) + 0.0001 = 0 + 0.0001 = 0.0001
        // Swap: -log(rate) + 0.0001 ≈ -log(0.000000000000333333) + 0.0001 ≈ 26.723
        //
        // Path costs:
        // 1-hop (B→C): 26.723 ← CHEAPER but infeasible (only 100 USDC at B)
        // 2-hop (A→B→C): 0.0001 + 26.723 = 26.723 ← Same cost but viable
        //
        // Without the fix, Dijkstra chooses the 1-hop path first (due to tie-breaking)
        // and gets stuck repeatedly trying it.

        runFlowTest(
            .init(
                name: "Multi-Start Dijkstra Avoids Cheaper Infeasible Path",
                routes: [bridge, swap],
                resources: [
                    .init(amount: .exact("5000e6"), node: .A),  // Remote has plenty
                    .init(amount: .exact("100e6"), node: .B),  // Local has insufficient
                ],
                target: .init(amount: .max, node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .maxFlow(
                    sinkAmount: "1e18",  // 1 WETH from swapping 3000 USDC
                    flows: [
                        // Bridge 2900 USDC from A to B (100 already exists at B, so total = 3000)
                        .init(route: bridge, amount: "2900e6"),
                        // Swap exactly 3000 USDC (100 existing + 2900 bridged) to get 1 WETH
                        .init(route: swap, amount: "3000e6"),
                    ]
                )
            )
        )
    }

    // MARK: - Max Target Zero-Rejection Tests

    @Test("Max Target Rejects Zero Flow")
    func testMaxTargetRejectsZeroFlow() {
        // Test that .max target fails when only zero can be delivered
        // Uses zero resources to create a zero-flow scenario
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        runFlowTest(
            .init(
                name: "Max Target Rejects Zero Flow",
                routes: [route],
                resources: [.init(amount: .exact("0"), node: .A)],  // Zero resources
                target: .init(amount: .max, node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(.insufficientResources(target: .max, max: "0"), maxFlow: "0")
            )
        )
    }

    @Test("Max Target With Fees Consuming All Flow")
    func testMaxTargetWithFeesConsumingAllFlow() {
        // Test that .max target fails when fees consume all output
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "outFee", isInFee: false, amount: "100e6")  // Fee equals output
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )
        runFlowTest(
            .init(
                name: "Max Target With Fees Consuming All Flow",
                routes: [route],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .max, node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(.insufficientResources(target: .max, max: "0"), maxFlow: "0")  // 100e6 - 100e6 fee = 0
            )
        )
    }

    @Test("Exact Flow Uses Existing Balance At Intermediate Node")
    func testExactFlowUsesExistingBalanceAtIntermediateNode() {
        // BUG REPRODUCTION: This test demonstrates a fixed bug in TradeWinds where it does
        // not properly utilize existing resources at intermediate nodes when an exact-flow constraint
        // is present.
        //
        // Scenario (mimics swap with cross-chain bridge):
        // - Node A (Arbitrum USDC): 5000 available
        // - Node B (Base USDC): 100 already available
        // - Node C (Base WETH): target
        // - Route A->B: bridge with 1% fee + 1 USDC fixed cost
        // - Route B->C: swap with EXACT constraint (minFlow = maxFlow = 3000)
        //
        // EXPECTED BEHAVIOR:
        // - Swap needs exactly 3000 at B
        // - Already have 100 at B
        // - Should bridge only ~2930 from A to deliver ~2900 to B (after fees)
        // - Total at B: 100 + 2900 = 3000 for swap
        //
        // BUGGY BEHAVIOR (what used to happen before the fix):
        // - Bridges ~3031 from A to deliver 3000 to B
        // - Total at B: 100 + 3000 = 3100
        // - Swap uses 3000, leaving 100 unused
        // - Over-bridges by ~100 USDC

        let bridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_bridge",
            source: .A,
            sink: .B,
            rate: 0.99,  // 1% fee
            fees: [Tradewinds.Fee(type: "bridge", isInFee: false, amount: "1e6")],  // 1 USDC fixed cost
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let exactSwap: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C_swap",
            source: .B,
            sink: .C,
            rate: 0.5,  // Example swap rate (irrelevant to bug)
            fees: [],
            minFlow: "3000e6",  // EXACT constraint
            maxFlow: "3000e6"  // EXACT constraint
        )

        runFlowTest(
            .init(
                name: "Exact Flow With Existing Balance At Intermediate Node",
                routes: [bridge, exactSwap],
                resources: [
                    .init(amount: .exact("5000e6"), node: .A),  // Arbitrum USDC
                    .init(amount: .exact("100e6"), node: .B),  // Base USDC (existing!)
                ],
                target: .init(amount: .max, node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // CORRECT: Bridges ~2930 to deliver ~2900 after fees
                        // Formula: (2900 + 1 out_fee) / 0.99 rate = 2930.303030... ≈ 2930.303031
                        // The extra ~1.01 tokens (vs 2929.29 if ignoring out_fee) covers the 1 USDC out_fee
                        // Result: 100 (existing) + 2900 (bridged after fees) = 3000 total at B for swap
                        .init(route: bridge, amount: "2930.303031e6"),
                        .init(route: exactSwap, amount: "3000e6"),
                    ],
                    maxFlow: "1500e6"  // 3000 * 0.5
                )
            )
        )
    }

    @Test("Max Target With Bridge Minimum Larger Than Shortfall")
    func testMaxTargetWithBridgeMinimumLargerThanShortfall() {
        // Scenario (mimics Morpho max repay with insufficient local funds):
        // - Node A (Base): 100 USDC available
        // - Node B (worldChain): 2.006 USDC available (after quotePay deduction)
        // - Node C (MorphoDebt): target with .max
        // - Route A->B: bridge with minFlow=0.5 (Across minimum)
        // - Route B->C: repay with maxFlow=2.01 (debt + buffer)
        //
        // Expected behavior:
        // - Use local funds first (2.006 on B)
        // - Then stage the bridge minFlow (0.5 from A) even though shortfall is 0.004
        // - Repay up to B->C maxFlow (2.01), leaving residual on B
        // - Final sink amount at C is 2.01

        let bridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_bridge",
            source: .A,
            sink: .B,
            rate: 0.999,  // 0.1% bridge fee
            fees: [],
            minFlow: "0.5e6",  // Bridge minimum: 0.5 USDC (like Across)
            maxFlow: "100e6"
        )

        let repay: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C_repay",
            source: .B,
            sink: .C,
            rate: 1.0,  // No loss on repay
            fees: [],
            minFlow: "0",
            maxFlow: "2.01e6"  // Can't repay more than debt (2.01 USDC)
        )

        runFlowTest(
            .init(
                name: "Max Target With Bridge Minimum Larger Than Shortfall",
                routes: [bridge, repay],
                resources: [
                    .init(amount: .exact("100e6"), node: .A),  // Base: 100 USDC
                    .init(amount: .exact("2.006e6"), node: .B),  // worldChain: 2.006 USDC (after fees)
                ],
                target: .init(amount: .max, node: .C),  // Maximize at target (THIS IS THE BUG)
                costFunction: Tradewinds.rateCostFunction(),
                expect: .maxFlow(
                    sinkAmount: "2.01e6",
                    flows: [
                        .init(route: bridge, amount: "0.5e6"),  // Stage minimum bridge
                        .init(route: repay, amount: "2.01e6"),  // Repay up to maxFlow
                    ]
                )
            )
        )
    }

    @Test("Bridge MinFlow With QuotePay In-Fee")
    func testBridgeMinFlowWithQuotePayInFee() {
        // Scenario: a single-hop bridge with a positive minFlow and a non-operation
        // in-fee (QuotePay) paid at the source. The solver must enforce minFlow against the
        // post-QuotePay input, i.e. require source ≥ (minFlow + QuotePay).
        //
        // Setup (USDC, 6 decimals):
        // - A → B bridge, rate = 1.0
        // - QuotePay in-fee at source = 2 USDC
        // - minFlow = 5 USDC (e.g., a bridge min-deposit)
        // - A has 10 USDC
        // Expectation:
        // - To deliver exactly 5 at B, send 7 at A (5 + 2)
        // - Max flow from 10 at A is 8 at B (10 - 2 once)

        let bridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_bridge",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [Tradewinds.Fee(type: "quotePay", isInFee: true, amount: "2e6")],
            minFlow: "5e6",
            maxFlow: "1000e6"
        )

        runFlowTest(
            .init(
                name: "Bridge MinFlow With QuotePay In-Fee",
                routes: [bridge],
                resources: [
                    .init(amount: .exact("10e6"), node: .A)
                ],
                target: .init(amount: .exact("5e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // Enforced: source = minFlow + QuotePay = 5 + 2 = 7
                        .init(route: bridge, amount: "7e6")
                    ],
                    // Max flow = 10 − 2 (QuotePay charged once) = 8
                    maxFlow: "8e6"
                )
            )
        )
    }

    // MARK: - Fixed Cost Tests

    @Test("Fixed Cost Causes Suboptimal Routing - Small Amount")
    func testFixedCostCausesSuboptimalRouting_SmallAmount() {
        // This test documents rateCostFunction behavior when fixed costs are significant.
        // Mercator now uses dualFeeCostFunction which correctly accounts for fixed costs.
        //
        // Scenario: Two parallel bridge routes from different chains to Base
        // - Route A (Mainnet): Better rate (0.999 = 0.1% fee), High gas ($20)
        // - Route B (Arbitrum): Worse rate (0.98 = 2% fee), Low gas ($2)
        // - Target: $50 to Base
        //
        // Optimal choice for $50 (considering total cost):
        // - Route A: $50/0.999 + $20 = $70.07 total cost
        // - Route B: $50/0.98 + $2 = $53.04 total cost
        // - Route B is better by $17.03!
        //
        // rateCostFunction behavior (rate-only):
        // - Only sees rates: -log(0.999) = 0.001 vs -log(0.98) = 0.0202
        // - Chooses Route A (better rate, ignores fixed cost)
        // - Results in paying $70.07 instead of $53.04
        //
        // For exact-amount targets in Mercator, we now use dualFeeCostFunction which correctly
        // accounts for fixed costs. See CharterTradewindsRoutingTests for correct behavior.

        let mainnetBridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "mainnet_bridge",
            source: .A,  // Mainnet USDC
            sink: .C,  // Base USDC
            rate: 0.999,  // 0.1% bridge fee
            fees: [
                Tradewinds.Fee(type: "gas", isInFee: true, amount: "20e6")  // $20 gas cost
            ],
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let arbitrumBridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "arbitrum_bridge",
            source: .B,  // Arbitrum USDC
            sink: .C,  // Base USDC
            rate: 0.98,  // 2% bridge fee
            fees: [
                Tradewinds.Fee(type: "gas", isInFee: true, amount: "2e6")  // $2 gas cost
            ],
            minFlow: "0",
            maxFlow: "10000e6"
        )

        runFlowTest(
            .init(
                name: "Fixed Cost Suboptimal - Small Amount",
                routes: [mainnetBridge, arbitrumBridge],
                resources: [
                    .init(amount: .exact("100e6"), node: .A),  // Mainnet has $100
                    .init(amount: .exact("100e6"), node: .B),  // Arbitrum has $100
                ],
                target: .init(amount: .exact("50e6"), node: .C),  // Want $50 on Base
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // BUG: Current algorithm chooses Mainnet (better rate, worse total cost)
                        // Optimal would be Arbitrum (worse rate, better total cost)
                        .init(route: mainnetBridge, amount: "70050051")
                    ],
                    maxFlow: "175960000"  // Total max: (100-20)*0.999 + (100-2)*0.98 = 79.92 + 96.04
                )
            )
        )
    }

    @Test("Fixed Cost Becomes Optimal - Large Amount")
    func testFixedCostBecomesOptimal_LargeAmount() {
        // This test demonstrates that rateCostFunction works correctly when the amount is large
        // enough that the better rate dominates fixed cost differences.
        //
        // Scenario: Same two routes as above
        // - Route A (Mainnet): Better rate (0.999 = 0.1% fee), High gas ($20)
        // - Route B (Arbitrum): Worse rate (0.98 = 2% fee), Low gas ($2)
        // - Target: $5000 to Base
        //
        // Optimal choice for $5000 (considering total cost):
        // - Route A: $5000/0.999 + $20 = $5025.03 total cost
        // - Route B: $5000/0.98 + $2 = $5104.08 total cost
        // - Route A is better by $79.05!
        //
        // rateCostFunction behavior (rate-only):
        // - Sees rates: -log(0.999) = 0.001 vs -log(0.98) = 0.0202
        // - Chooses Route A (better rate)
        // - Happens to be correct for large amounts where rate dominates
        //
        // This demonstrates that for large amounts, rate-based decisions happen to align
        // with total-cost-optimal decisions since the better rate dominates fixed costs.

        let mainnetBridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "mainnet_bridge",
            source: .A,  // Mainnet USDC
            sink: .C,  // Base USDC
            rate: 0.999,  // 0.1% bridge fee
            fees: [
                Tradewinds.Fee(type: "gas", isInFee: true, amount: "20e6")  // $20 gas cost
            ],
            minFlow: "0",
            maxFlow: "10000e6"
        )

        let arbitrumBridge: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "arbitrum_bridge",
            source: .B,  // Arbitrum USDC
            sink: .C,  // Base USDC
            rate: 0.98,  // 2% bridge fee
            fees: [
                Tradewinds.Fee(type: "gas", isInFee: true, amount: "2e6")  // $2 gas cost
            ],
            minFlow: "0",
            maxFlow: "10000e6"
        )

        runFlowTest(
            .init(
                name: "Fixed Cost Optimal - Large Amount",
                routes: [mainnetBridge, arbitrumBridge],
                resources: [
                    .init(amount: .exact("6000e6"), node: .A),  // Mainnet has $6000
                    .init(amount: .exact("6000e6"), node: .B),  // Arbitrum has $6000
                ],
                target: .init(amount: .exact("5000e6"), node: .C),  // Want $5000 on Base
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // For large amounts, Mainnet is actually optimal
                        // (better rate dominates the fixed cost)
                        .init(route: mainnetBridge, amount: "5025005006")
                    ],
                    maxFlow: "11852060000"  // Total max: (6000-20)*0.999 + (6000-2)*0.98 = 5974.02 + 5878.04
                )
            )
        )
    }

    @Test("Target Below Outgoing Fee")
    func testWithdrawTargetBelowOutFee() {
        // Tests correct flow calculation when target < outgoing fixed fee
        // Example: target net is 0.1 units, outgoing fee is 0.5 units
        // The solver should send 0.6 units total (target + fee)
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "withdraw",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "quotePay", isInFee: false, amount: "0.5e6")
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        runFlowTest(
            .init(
                name: "Target Below Outgoing Fee",
                routes: [route],
                resources: [.init(amount: .exact("10e6"), node: .A)],
                target: .init(amount: .exact("0.1e6"), node: .B),
                costFunction: Tradewinds.dualFeeCostFunction(targetAmount: "0.1e6"),
                expect: .exactFlows(
                    [
                        .init(route: route, amount: "0.6e6")
                    ],
                    maxFlow: "9.5e6"
                )
            )
        )
    }

    @Test("Multi-Source Dijkstra Does Not Route Through Start Nodes")
    func testMultiSourceDijkstraDoesNotRouteThroughStartNodes() {
        // This test reproduces a critical bug in multi-source Dijkstra pathfinding.
        //
        // BUG SCENARIO:
        // - Two start nodes (A and B) both have available resources
        // - There's a route from A→B with cost=0 (e.g., ETH wrapping to WETH)
        // - There's a route from B→C to the target
        // - Target needs resources at C
        //
        // BUGGY BEHAVIOR (before fix):
        // - Dijkstra initializes both A and B with dist=0 (both are start nodes)
        // - When exploring A's edges, it finds A→B with cost=0
        // - It sets dist[B] = 0 + 0 = 0 and prev[B] = A→B route
        // - This CORRUPTS B's status as an independent start node!
        // - Path reconstruction yields: A→B→C instead of just B→C
        // - When calculating flows, the first hop (A→B) returns 0 because B already has resources
        // - The algorithm interprets flow=0 as "insufficient resources" and FAILS
        //
        // CORRECT BEHAVIOR (after fix):
        // - Start nodes (resource holders) should NEVER have predecessors set WHILE they have resources
        // - B remains an independent start node in iteration 1
        // - Path reconstruction yields: B→C (direct path using existing resources)
        // - Flow calculation succeeds
        //
        // IMPORTANT CLARIFICATION:
        // Start nodes can ONLY be reached via edges AFTER their resources are exhausted.
        // Once available[B] = 0, B is no longer a start node and CAN be part of a path.

        let wrapRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B_wrap",
            source: .A,  // Node A (e.g., ETH)
            sink: .B,    // Node B (e.g., WETH) - also a start node!
            rate: 1.0,   // 1:1 conversion
            minFlow: "0",
            maxFlow: "1000e6"
        )

        let supplyRoute: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C_supply",
            source: .B,  // Node B (WETH)
            sink: .C,    // Node C (target, e.g., Comet)
            rate: 1.0,
            minFlow: "0",
            maxFlow: "1000e6"
        )

        runFlowTest(
            .init(
                name: "Multi-Source Dijkstra Does Not Route Through Start Nodes",
                routes: [wrapRoute, supplyRoute],
                resources: [
                    .init(amount: .exact("5e6"), node: .A),    // Small amount at A
                    .init(amount: .exact("100e6"), node: .B),  // Large amount at B (sufficient!)
                ],
                target: .init(amount: .exact("10e6"), node: .C),  // Need 10 at C
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        // Should use B→C directly (B is a start node with sufficient resources)
                        // Should NOT route through A→B→C
                        .init(route: supplyRoute, amount: "10e6")
                    ],
                    maxFlow: "105e6"  // 5 (from A via wrap) + 100 (direct from B)
                )
            )
        )
    }
}
