import Foundation
import SwiftNumber
import Testing
import Tradewinds

@testable import Charter

/// Tests for Tradewinds scenarios involving multi-hop and complex graph topologies.
struct TradewindsMultiHopTests {

    @Test("Two-Hop Flow Numberized")
    func testTwoHopFlowNumberized() {
        // Graph: A -> B -> C
        // Tests a simple chain of routes.
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "1000000000"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 0.98,
            minFlow: "0",
            maxFlow: "1000000000"
        )
        runFlowTest(
            .init(
                name: "Two-Hop Flow",
                routes: [routeAB, routeBC],
                resources: [.init(amount: .exact("100000000"), node: .A)],
                target: .init(amount: .exact("50000000"), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "51535767"),  // Exact amount needed at A
                        .init(route: routeBC, amount: "51020409"),  // 51535767 * 0.99 = 51020409.33 (truncated)
                    ],
                    maxFlow: "97020000"
                )  // 100 * 0.99 * 0.98
            )
        )
    }

    @Test("Two-Hop Flow Decimalized")
    func testTwoHopFlowDecimalized() {
        // Graph: A -> B -> C
        // Tests a simple chain of routes.
        let routeAB: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "100.0e6"
        )
        let routeBC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 0.98,
            minFlow: "0",
            maxFlow: "100.0e6"
        )
        runFlowTest(
            .init(
                name: "Two-Hop Flow",
                routes: [routeAB, routeBC],
                resources: [.init(amount: .exact("100.0e6"), node: .A)],
                target: .init(amount: .exact("50.0e6"), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "51.535767e6"),  // Exact amount needed at A
                        .init(route: routeBC, amount: "51.020409e6"),  // 51.535767e6 * 0.99 (truncated)
                    ],
                    maxFlow: "97.02000e6"
                )  // 100.0e6 * 0.99 * 0.98
            )
        )
    }

    @Test("Three-Hop Flow")
    func testThreeHopFlow() {
        // Graph: A -> B -> C -> D
        // Tests a longer chain of routes.
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
        let routeCD: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "C->D",
            source: .C,
            sink: .D,
            rate: 0.97,
            minFlow: "0",
            maxFlow: "1000e6"
        )
        runFlowTest(
            .init(
                name: "Three-Hop Flow",
                routes: [routeAB, routeBC, routeCD],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("50e6"), node: .D),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAB, amount: "53.129657e6"),  // Exact amount needed at A
                        .init(route: routeBC, amount: "52.598360e6"),  // 53.129657e6 * 0.99 (truncated)
                        .init(route: routeCD, amount: "51.546392e6"),  // 52.598360e6 * 0.98 (truncated)
                    ],
                    maxFlow: "94.1094e6"
                )  // 100 * 0.99 * 0.98 * 0.97
            )
        )
    }

    @Test("Converging Flows from Two Sources")
    func testConvergingFlows() {
        // Graph: A->C, B->C
        // Tests a scenario where two different sources flow to the same sink.
        let routeAC: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->C",
            source: .A,
            sink: .C,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "100e6"
        )  // Better rate
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
                name: "Converging Flows from Two Sources",
                routes: [routeAC, routeBC],
                resources: [
                    .init(amount: .exact("30e6"), node: .A),
                    .init(amount: .exact("50e6"), node: .B),
                ],
                target: .init(amount: .exact("60e6"), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAC, amount: "30e6"),  // Uses all of A first (29.7 delivered)
                        .init(route: routeBC, amount: "30.918368e6"),  // Then takes from B to meet the rest of the target
                    ],
                    maxFlow: "78.7e6"
                )  // 30*0.99 + 50*0.98 = 29.7 + 49 = 78.7
            )
        )
    }

    @Test("Converging Through an Intermediate Node")
    func testConvergingThroughIntermediateNode() {
        // Graph: A->D, B->D, D->E
        // Tests a scenario where multiple sources flow through an intermediate node.
        // To get 100e6 at E (rate 0.95), we need ~105.263e6 at D.
        // D has 10e6, so we need ~95.263e6 more.
        // Source A is cheaper (rate 0.99), so we take all 50e6 from A, which delivers 49.5e6 to D.
        // We still need ~45.763e6 at D, so we take ~46.697e6 from B (rate 0.98).
        // The total flow through D->E is the sum of these amounts.
        let routeAD: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->D",
            source: .A,
            sink: .D,
            rate: 0.99,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeBD: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->D",
            source: .B,
            sink: .D,
            rate: 0.98,
            minFlow: "0",
            maxFlow: "100e6"
        )
        let routeDE: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "D->E",
            source: .D,
            sink: .E,
            rate: 0.95,
            minFlow: "0",
            maxFlow: "200e6"
        )
        runFlowTest(
            .init(
                name: "Converging Through an Intermediate Node",
                routes: [routeAD, routeBD, routeDE],
                resources: [
                    .init(amount: .exact("50e6"), node: .A),
                    .init(amount: .exact("50e6"), node: .B),
                    .init(amount: .exact("10e6"), node: .D),
                ],  // Resources at sources and intermediate node
                target: .init(amount: .exact("100e6"), node: .E),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .exactFlows(
                    [
                        .init(route: routeAD, amount: "50e6"),
                        .init(route: routeBD, amount: "46.697100e6"),
                        .init(route: routeDE, amount: "105.263158e6"),
                    ],
                    maxFlow: "103.075e6"
                )  // (50*0.99 + 50*0.98 + 10) * 0.95 = (49.5 + 49 + 10) * 0.95 = 108.5 * 0.95 = 103.075
            )
        )
    }

    @Test("Max Flow in Multi-Hop Scenario")
    func testMaxFlowInMultiHopScenario() {
        // Graph: A -> B -> C
        // Tests max flow calculation in a multi-hop scenario.
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
            rate: 0.8,
            minFlow: "0",
            maxFlow: "100e6"
        )
        runFlowTest(
            .init(
                name: "Max Flow in Multi-Hop Scenario",
                routes: [routeAB, routeBC],
                resources: [.init(amount: .exact("50e6"), node: .A)],
                target: .init(amount: .max, node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .maxFlow(
                    sinkAmount: "36e6",
                    flows: [
                        .init(route: routeAB, amount: "50e6"),
                        .init(route: routeBC, amount: "45e6"),
                    ]
                )
            )
        )
    }
}
