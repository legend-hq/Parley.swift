import Foundation
import SwiftNumber
import Testing
import Tradewinds

@testable import Charter

// MARK: - Visualization Support

/// Check if visualization is enabled via VIZ=1 environment variable
public func shouldGenerateGraphviz() -> Bool {
    return ProcessInfo.processInfo.environment["VIZ"] == "1"
}

// MARK: - Generic Visualization for any Node and RouteType

/// Generate and save a DOT file for generic Tradewinds types
public func generateAndSaveDot<Node: TradewindsNode, RouteType: Hashable & CustomStringConvertible>(
    testName: String,
    routes: [Tradewinds.Route<Node, RouteType>],
    resources: [Tradewinds.Resource<Node>],
    flows: [Tradewinds.Flow<Node, RouteType>]?,
    target: Tradewinds.Target<Node>,
    suffix: String
) {
    let dotString = Tradewinds.generateDot(
        version: Charter.version,
        routes: routes,
        resources: resources,
        flows: flows,
        target: target
    )

    let fileName = "\(testName.replacingOccurrences(of: " ", with: "_"))_\(suffix).dot"
    // Get the project root directory (Mercator) and append Visualizations
    let currentDir = FileManager.default.currentDirectoryPath
    let directory = URL(fileURLWithPath: currentDir).appendingPathComponent("Visualizations")

    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(fileName)
        try dotString.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        print("\n[GRAPHVIZ] Generated DOT file: \(fileURL.path)")
    } catch {
        print("\n[GRAPHVIZ] Error saving DOT file: \(error)")
    }
}

/// Generate and save a combined DOT file comparing expected vs actual flows
public func generateAndSaveCombinedDot<
    Node: TradewindsNode,
    RouteType: Hashable & CustomStringConvertible
>(
    testName: String,
    routes: [Tradewinds.Route<Node, RouteType>],
    resources: [Tradewinds.Resource<Node>],
    expectedFlows: [Tradewinds.Flow<Node, RouteType>],
    actualFlows: [Tradewinds.Flow<Node, RouteType>],
    target: Tradewinds.Target<Node>
) {
    let dotString = Tradewinds.generateCombinedDot(
        routes: routes,
        resources: resources,
        expectedFlows: expectedFlows,
        actualFlows: actualFlows,
        target: target
    )

    let fileName = "\(testName.replacingOccurrences(of: " ", with: "_"))_4_combined.dot"
    // Get the project root directory (Mercator) and append Visualizations
    let currentDir = FileManager.default.currentDirectoryPath
    let directory = URL(fileURLWithPath: currentDir).appendingPathComponent("Visualizations")

    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(fileName)
        try dotString.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        print("\n[GRAPHVIZ] Generated Combined DOT file: \(fileURL.path)")
    } catch {
        print("\n[GRAPHVIZ] Error saving Combined DOT file: \(error)")
    }
}

// MARK: - Acceptance Test Specific Visualization

/// Generate visualization for acceptance tests
public func generateAcceptanceTestVisualization(
    testName: String? = nil,
    routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
    resources: [Tradewinds.Resource<TradewindsLegendNode>],
    flows: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>]?,
    target: Tradewinds.Target<TradewindsLegendNode>,
    suffix: String
) {
    let finalTestName = testName ?? getCurrentTestName()

    generateAndSaveDot(
        testName: finalTestName,
        routes: routes,
        resources: resources,
        flows: flows,
        target: target,
        suffix: suffix
    )
}

/// Generate combined visualization for acceptance tests
public func generateAcceptanceTestCombinedVisualization(
    testName: String? = nil,
    routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
    resources: [Tradewinds.Resource<TradewindsLegendNode>],
    expectedFlows: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>],
    actualFlows: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>],
    target: Tradewinds.Target<TradewindsLegendNode>
) {
    let finalTestName = testName ?? getCurrentTestName()

    generateAndSaveCombinedDot(
        testName: finalTestName,
        routes: routes,
        resources: resources,
        expectedFlows: expectedFlows,
        actualFlows: actualFlows,
        target: target
    )
}

// MARK: - Test Name Utilities

/// Get the current test name from the Testing framework
private func getCurrentTestName() -> String {
    if let currentTest = Test.current {
        let displayName = currentTest.displayName ?? "unknown_test"
        return
            displayName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "\"", with: "")
    } else {
        return "test"
    }
}
