import Foundation
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Test Helper Types

struct FlowTestCase {
    let name: String
    let routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]
    let resources: [Tradewinds.Resource<TradewindsLegendNode>]
    let target: Tradewinds.Target<TradewindsLegendNode>
    let costFunction: Tradewinds.CostFunction<TradewindsLegendNode, LegendRouteType>
    let expect: FlowExpectation
}

enum FlowExpectation {
    case exactFlows([Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>], maxFlow: Number)
    case unorderedFlows([Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>], maxFlow: Number)
    case failure(Tradewinds.Error, maxFlow: Number)
    case charterFailure(Charter.CharterError)
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
        } else if case .unorderedFlows(let expected, _) = test.expect {
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
        Issue.record("Max flow calculation failed")
        return
    }

    // Run the flow algorithm
    let result = Tradewinds.flowWithResult(
        routes: test.routes,
        resources: test.resources,
        target: test.target,
        costFunction: test.costFunction
    )

    func flowSortKey(_ f: Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>) -> String {
        "\(f.route.id)|\(f.amount)"
    }

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

        case (.success(let flowResult), .unorderedFlows(let expectedFlows, let expectedMaxFlow)):
            #expect(
                actualMaxFlow.sinkAmount == expectedMaxFlow,
                "Max flow mismatch: expected \(expectedMaxFlow) but got \(actualMaxFlow.sinkAmount)"
            )
            let actualSorted = flowResult.flows.sorted { flowSortKey($0) < flowSortKey($1) }
            let expectedSorted = expectedFlows.sorted { flowSortKey($0) < flowSortKey($1) }
            #expect(
                actualSorted == expectedSorted,
                "The actual flows did not match the expected flows (unordered compare)."
            )

        case (.failure(let error), .failure(let expectedError, let expectedMaxFlow)):
            #expect(error == expectedError)
            #expect(actualMaxFlow.sinkAmount == expectedMaxFlow)

        case (.failure(let error), .unorderedFlows(_, let expectedMaxFlow)):
            #expect(
                Bool(false),
                "Expected success but got failure: \(error). Expected maxFlow: \(expectedMaxFlow)"
            )

        case (.failure(let error), .exactFlows(let expectedFlows, _)):
            #expect(
                Bool(false),
                "Expected success but got failure: \(error). Expected flows: \(expectedFlows)"
            )

        case (.success(let flowResult), .failure(let expectedError, _)):
            let actualFlows = flowResult.flows.map { flow in
                ExpectedFlow(
                    type: flow.route.type,
                    amount: flow.amount,
                    source: flow.route.source,
                    sink: flow.route.sink
                )
            }
            #expect(
                Bool(false),
                "Expected failure but got success. Expected error: \(expectedError). Actual flows: \(actualFlows)"
            )

        case (_, .charterFailure):
            break  // Charter failures are handled in the Charter-specific runFlowTest
    }

    if shouldGenerateGraphviz(), case .success(let flowResult) = result,
        ({
            if case .exactFlows = test.expect { return true }
            if case .unorderedFlows = test.expect { return true }
            return false
        }())
    {
        let expected: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>]
        switch test.expect {
            case .exactFlows(let e, _): expected = e
            case .unorderedFlows(let e, _): expected = e
            default: expected = []
        }
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

// MARK: - Charter-specific test runner

struct ChartTestCase {
    let name: String
    let givens: [Given]
    let intent: Charter.QuarkIntent.Type_
    let expect: FlowExpectation
    let allowUsingEarningBalances: Bool

    init(
        name: String,
        givens: [Given],
        intent: Charter.QuarkIntent.Type_,
        expect: FlowExpectation,
        allowUsingEarningBalances: Bool = false
    ) {
        self.name = name
        self.givens = givens
        self.intent = intent
        self.expect = expect
        self.allowUsingEarningBalances = allowUsingEarningBalances
    }
}

// Helper struct that matches the test expectation format
struct ExpectedFlow {
    let type: LegendRouteType
    let amount: Number
    let source: TradewindsLegendNode
    let sink: TradewindsLegendNode
}

func runFlowTest(_ test: ChartTestCase) {
    // Build routes and target from intent
    let tradewindsResult = test.intent.tradewindsInfo(
        folio: generateFolio(from: test.givens),
        allowUsingEarningBalances: test.allowUsingEarningBalances
    )

    switch tradewindsResult {
        case .success(let (routes, resources, target)):
            // Run the flow test
            let flowTest = FlowTestCase(
                name: test.name,
                routes: routes,
                resources: resources,
                target: target,
                costFunction: test.intent.tradewindsCostFn(resources: resources, target: target),
                expect: test.expect
            )
            runFlowTest(flowTest)

        case .failure(let error):
            // Check if we expected this charter failure
            if case .charterFailure(let expectedError) = test.expect {
                #expect(
                    error == expectedError,
                    "Expected Charter error \(expectedError) but got \(error)"
                )
            } else {
                Issue.record(
                    "Failed to create tradewinds info for test: \(test.name) with error: \(error)"
                )
            }
    }
}
