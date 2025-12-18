import Foundation
import SwiftNumber
import Testing
import Tradewinds

@testable import Charter

/// Tests for fee underflow issues where flows are allowed even when fees exceed amounts
struct TradewindsFeeUnderflowTests {

    @Test("Flow should fail when inFee exceeds available amount")
    func testInFeeExceedsAmount() {
        // Create a route with a 100 unit inFee
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "largeFee", isInFee: true, amount: "100e6")  // 100 units inFee
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        // Try to send 50 units through a route that requires 100 units in fees
        // Currently this INCORRECTLY succeeds with partial fee payment
        let result = Tradewinds.flow(
            routes: [route],
            resources: [.init(amount: .exact("50e6"), node: .A)],
            target: .init(amount: .exact("10e6"), node: .B),
            costFunction: Tradewinds.rateCostFunction()
        )

        print("Test result: \(result)")

        // CURRENTLY: The algorithm incorrectly allows this flow
        // It should fail but instead saturates the fee payment to available amount
        switch result {
            case .success(let flows):
                print("BUG: Flow succeeded when it should have failed!")
                print("Flows: \(flows)")
                for flow in flows {
                    print("  Flow amount: \(flow.amount), sinkAmount: \(flow.sinkAmount)")
                }
                Issue.record("Flow should have failed due to insufficient funds for fees")
            case .failure(let error):
                print("Correctly failed with: \(error)")
        }
    }

    @Test("Flow should fail when outFee exceeds post-rate amount")
    func testOutFeeExceedsAmount() {
        // Create a route with a 100 unit outFee and 50% rate
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.5,  // 50% rate
            fees: [
                Tradewinds.Fee(type: "largeFee", isInFee: false, amount: "100e6")  // 100 units outFee
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        // With 150 units, after 50% rate we get 75 units, which is less than the 100 unit outFee
        // This should fail
        runFlowTest(
            .init(
                name: "OutFee Exceeds Post-Rate Amount",
                routes: [route],
                resources: [.init(amount: .exact("150e6"), node: .A)],
                target: .init(amount: .exact("10e6"), node: .B),
                costFunction: Tradewinds.rateCostFunction(),
                // Should fail since 150 * 0.5 = 75, which is less than 100 outFee
                expect: .failure(
                    .insufficientResources(target: .exact("10e6"), max: "0"),
                    maxFlow: "0"
                )
            )
        )
    }

    @Test("Flow should succeed when fees are exactly covered")
    func testFeesExactlyCovered() {
        // Create a route with a 50 unit inFee
        let route: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "exactFee", isInFee: true, amount: "50e6")  // 50 units inFee
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        // With exactly 50 units, we can pay the fee but deliver 0
        // With zero-rejection logic, .max targets that deliver zero should fail
        runFlowTest(
            .init(
                name: "Fees Exactly Covered",
                routes: [route],
                resources: [.init(amount: .exact("50e6"), node: .A)],
                target: .init(amount: .max, node: .B),  // Max flow request
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(.insufficientResources(target: .max, max: "0"), maxFlow: "0")
            )
        )
    }

    @Test("Multi-hop with fees exceeding intermediate amounts")
    func testMultiHopFeeUnderflow() {
        // Create a two-hop path where the second hop's fees exceed what's available
        let route1: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "A->B",
            source: .A,
            sink: .B,
            rate: 0.5,  // 50% rate
            fees: [],  // No fees on first hop
            minFlow: "0",
            maxFlow: "1000e6"
        )

        let route2: Tradewinds.Route<TradewindsTestNode, String> = .init(
            type: "B->C",
            source: .B,
            sink: .C,
            rate: 1.0,
            fees: [
                Tradewinds.Fee(type: "largeFee", isInFee: true, amount: "100e6")  // 100 units inFee
            ],
            minFlow: "0",
            maxFlow: "1000e6"
        )

        // Start with 100 at A, after first hop we have 50 at B
        // Second hop needs 100 in fees, so this should fail
        runFlowTest(
            .init(
                name: "Multi-Hop Fee Underflow",
                routes: [route1, route2],
                resources: [.init(amount: .exact("100e6"), node: .A)],
                target: .init(amount: .exact("10e6"), node: .C),
                costFunction: Tradewinds.rateCostFunction(),
                expect: .failure(
                    .insufficientResources(target: .exact("10e6"), max: "0"),
                    maxFlow: "0"
                )
            )
        )
    }
}
