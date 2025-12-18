import Charter
import Eth
import Foundation
import Prelude
import SwiftKeccak
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

struct HarnessTest: Codable, CustomStringConvertible {
    let name: String
    let mercatorVersion: String
    let intent: Charter.QuarkIntent
    let chart: Charter.Chart?
    let chartUser: Charter.Chart?
    let folio: Prelude.Folio

    enum CodingKeys: String, CodingKey {
        case name
        case mercatorVersion = "mercator_version"
        case intent
        case chart
        case chartUser = "chart_user"
        case folio
    }

    var description: String {
        "\(name): \(intent.description)"
    }
}

@Suite("Harness Tests")
struct HarnessTests {
    let decoder = JSONDecoder()

    static let testCases: [HarnessTest] = {
        guard let url = Bundle.module.url(forResource: "HarnessTests", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let tests = try? JSONDecoder().decode([HarnessTest].self, from: data)
        else {
            return []
        }

        let currentVersion = Charter.version
        return tests.compactMap { test in
            if test.mercatorVersion != currentVersion {
                // Yellow color for filtered tests
                let yellow = "\u{001B}[33m"
                let reset = "\u{001B}[0m"
                print(
                    "\(yellow)Filtered test '\(test.name)' - version mismatch (expected: \(currentVersion), found: \(test.mercatorVersion))\(reset)"
                )
                return nil
            }
            return test
        }
    }()

    @Test("Harness", arguments: testCases)
    func runHarnessTest(_ test: HarnessTest) throws {
        let result = Charter.chartExtended(
            intent: test.intent,
            folio: test.folio,
            logger: Charter.Logger(print: true)
        )

        // Generate visualization if enabled
        let shouldVisualize = shouldGenerateGraphviz()
        if shouldVisualize {
            if let routes = result.routes,
                let resources = result.resources,
                let target = result.target
            {

                // 1. Setup visualization (no flows)
                generateAcceptanceTestVisualization(
                    testName: test.name,
                    routes: routes,
                    resources: resources,
                    flows: nil,
                    target: target,
                    suffix: "1_setup"
                )

                // 2. Solution visualization (with flows if successful)
                switch result.result {
                    case .success:
                        if let flows = result.flowResult?.flows {
                            generateAcceptanceTestVisualization(
                                testName: test.name,
                                routes: routes,
                                resources: resources,
                                flows: flows,
                                target: target,
                                suffix: "2_solution"
                            )
                        }
                    case .failure:
                        // For failures, still show the setup only
                        break
                }
            }
        }

        switch result.result {
            case .success(let chart):
                // Compare with expected chart if provided
                if let expectedChart = test.chart {
                    #expect(chart == expectedChart)
                }

            // TODO: Asset equivalence check with chartUser if needed

            case .failure(let error):
                Issue.record("Test '\(test.name)' failed: \(error)")
        }
    }
}
