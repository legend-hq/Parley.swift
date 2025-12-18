import Foundation
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Shared Test Infrastructure

/// Common node type for Tradewinds tests
enum TradewindsTestNode: TradewindsNode {
    typealias FeeType = String  // Use String as the fee type for tests

    case A, B, C, D, E, F
    case sendTo(address: String)

    var label: String {
        switch self {
            case .sendTo(let address): return "sendTo(\(address))"
            default: return "\(self)"
        }
    }

    public var decimals: Int? {
        return nil
    }
}

// MARK: - Test Helper Types

struct FlowTestCase {
    let name: String
    let routes: [Tradewinds.Route<TradewindsTestNode, String>]
    let resources: [Tradewinds.Resource<TradewindsTestNode>]
    let target: Tradewinds.Target<TradewindsTestNode>
    let costFunction: Tradewinds.CostFunction<TradewindsTestNode, String>
    let expect: FlowExpectation
}

enum FlowExpectation {
    case exactFlows([Tradewinds.Flow<TradewindsTestNode, String>], maxFlow: Number)
    case failure(Tradewinds.Error, maxFlow: Number)
    case maxFlow(sinkAmount: Number, flows: [Tradewinds.Flow<TradewindsTestNode, String>])
}

// MARK: - Number Extension

extension Number {
    /// Creates a Number with the given value and decimal places
    /// Example: Number(5, decimals: 18) = 5 * 10^18
    init(_ value: Int, decimals: Int) {
        let multiplier = Number(10).power(decimals)
        self = Number(value) * multiplier
    }

    /// Creates a Number with the given double value and decimal places
    /// Example: Number(1.5, decimals: 18) = 1.5 * 10^18
    init(_ value: Double, decimals: Int) {
        // Convert double to string to preserve decimals
        let stringValue = String(format: "%.18f", value)
        let parts = stringValue.split(separator: ".")

        if parts.count == 2 {
            // Has decimal part
            let integerPart = String(parts[0])
            let decimalPart = String(parts[1]).trimmingCharacters(in: .init(charactersIn: "0"))

            let integerValue = Number(integerPart) ?? Number(0)
            let decimalValue = Number(decimalPart) ?? Number(0)
            let decimalDivisor = Number(10).power(decimalPart.count)

            let multiplier = Number(10).power(decimals)
            self = (integerValue * multiplier) + (decimalValue * multiplier / decimalDivisor)
        } else {
            // No decimal part
            let multiplier = Number(10).power(decimals)
            self = Number(Int(value)) * multiplier
        }
    }
}

// MARK: - Rate Helpers

extension Double {
    /// Convert a simple ratio to a rate value for use in routes
    /// Examples:
    /// - 1.0.asRate = 1e18 (1:1)
    /// - 2.0.asRate = 2e18 (2:1)
    /// - 0.5.asRate = 5e17 (1:2)
    var asRate: Double {
        return self * 1e18
    }

    /// Convert basis points to a rate value
    /// Example: 9999.bpsRate = 0.9999 * 1e18
    var bpsRate: Double {
        return self * 1e18 / 10000
    }
}

// Helper to create swap rates accounting for decimal differences
func swapRate(fromDecimals: Int, toDecimals: Int, ratio: Double) -> Double {
    // If swapping 1 unit of 'from' gives 'ratio' units of 'to'
    // We need to adjust for decimal differences
    let decimalAdjustment = pow(10.0, Double(toDecimals - fromDecimals))
    return ratio * decimalAdjustment * 1e18
}

// MARK: - Test Runner

func runFlowTest(_ test: FlowTestCase) {
    if shouldGenerateGraphviz() {
        // 1. Visualize the setup
        generateAndSaveDot(
            testName: test.name,
            routes: test.routes,
            resources: test.resources,
            flows: nil,
            target: test.target,
            suffix: "1_setup"
        )

        // 2. Visualize the expected solution
        if case .exactFlows(let expected, _) = test.expect {
            generateAndSaveDot(
                testName: test.name,
                routes: test.routes,
                resources: test.resources,
                flows: expected,
                target: test.target,
                suffix: "2_solution_expected"
            )
        }
    }

    // Calculate max flow
    let maxFlowResult = Tradewinds.maxFlow(
        routes: test.routes,
        resources: test.resources,
        targetNode: test.target.node,
        costFunction: test.costFunction
    )

    guard case .success(let actualMaxFlow) = maxFlowResult else {
        Issue.record("Max flow calculation failed: \(maxFlowResult)")
        return
    }

    // Run the flow algorithm
    let result = Tradewinds.flowWithResult(
        routes: test.routes,
        resources: test.resources,
        target: test.target,
        costFunction: test.costFunction
    )

    switch (result, test.expect) {
        case (.success(let flowResult), .exactFlows(let expectedFlows, let expectedMaxFlow)):
            // Check max flow
            #expect(
                actualMaxFlow.sinkAmount == expectedMaxFlow,
                "Max flow mismatch: expected \(expectedMaxFlow) but got \(actualMaxFlow.sinkAmount)"
            )

            #expect(
                flowResult.flows == expectedFlows,
                "The actual flows did not match the expected flows."
            )

        case (.failure(let error), .failure(let expectedError, let expectedMaxFlow)):
            #expect(error == expectedError)
            #expect(actualMaxFlow.sinkAmount == expectedMaxFlow)

        case (.success(let flowResult), .maxFlow(let expectedSinkAmount, let expectedFlows)):
            #expect(flowResult.totalSinkAmount == expectedSinkAmount)
            #expect(flowResult.flows == expectedFlows)

        default:
            if case .failure(let error) = result {
                Issue.record(
                    "Test failed with error: \(error). Expected: \(test.expect). Max flow: \(actualMaxFlow.sinkAmount)"
                )
            } else {
                Issue.record("Test result mismatch: expected \(test.expect) but got \(result)")
            }
    }

    if shouldGenerateGraphviz(), case .success(let flowResult) = result,
        case .exactFlows(let expected, _) = test.expect
    {
        // 3. Visualize the actual solution
        generateAndSaveDot(
            testName: test.name,
            routes: test.routes,
            resources: test.resources,
            flows: flowResult.flows,
            target: test.target,
            suffix: "3_solution_actual"
        )

        // 4. Visualize the combined view
        generateAndSaveCombinedDot(
            testName: test.name,
            routes: test.routes,
            resources: test.resources,
            expectedFlows: expected,
            actualFlows: flowResult.flows,
            target: test.target
        )
    }
}
