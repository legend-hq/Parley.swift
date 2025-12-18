import Foundation
import SwiftNumber

// MARK: - Graphviz Visualization

enum ScientificLabel {
    static func trimTrailingZeros<S: StringProtocol>(_ s: S) -> String {
        var str = String(s)
        while str.last == "0" { str.removeLast() }
        return str
    }

    static func signed(signed value: SNumber, decimals: Int? = nil, showDecimals: Int? = nil)
        -> String
    {
        // Zero is special
        if value == 0 { return "0" }

        let isNegative = value < 0
        let digits = String(value.magnitude)
        let sign = isNegative ? "-" : ""

        // Fixed “decimals” mode (fixed-point style, like token decimals)
        if let d = decimals {
            let len = digits.count
            if len > d {
                let cut = digits.index(digits.endIndex, offsetBy: -d)
                let intPart = digits[..<cut]
                let fracPart = digits[cut...]
                let frac = trimTrailingZeros(fracPart)
                if frac.isEmpty {
                    return "\(sign)\(intPart)e\(showDecimals ?? d)"
                } else {
                    return "\(sign)\(intPart).\(frac)e\(showDecimals ?? d)"
                }
            } else {
                // Need to pad zeros on the left so we can split
                let pad = String(repeating: "0", count: d - len)
                let fracPart = pad + digits
                let frac = trimTrailingZeros(fracPart)
                if frac.isEmpty {
                    return "\(sign)0e\(showDecimals ?? d)"
                } else {
                    return "\(sign)0.\(frac)e\(showDecimals ?? d)"
                }
            }
        } else {
            // Normal mode: plain decimal if < 1e3, else scientific with exact digits
            if digits.count <= 3 {
                return sign + digits
            }

            let first = digits.first!
            let rest = digits.dropFirst()
            let frac = trimTrailingZeros(rest)
            let mantissa = frac.isEmpty ? String(first) : "\(first).\(frac)"
            let exponent = digits.count - 1
            return "\(sign)\(mantissa)e\(exponent)"
        }
    }

    static func unsigned(_ value: Number, decimals: Int? = nil) -> String {
        return signed(signed: SNumber(value), decimals: decimals)
    }
}
@available(macOS 13.0, *)
extension Tradewinds {

    /// Generates a Graphviz DOT language representation of a Tradewinds graph.
    public static func generateDot<Node: TradewindsNode, ID: Hashable & CustomStringConvertible>(
        version: String,
        routes: [Route<Node, ID>],
        resources: [Resource<Node>]? = nil,
        flows: [Flow<Node, ID>]? = nil,
        target: Target<Node>? = nil
    ) -> String {
        var dot = "digraph TradewindsFlow {\n"
        dot += "    rankdir=LR;\n"
        dot += "    node [shape=box, style=rounded, fontname=\"Helvetica\"];\n"
        dot += "    edge [fontname=\"Helvetica\", fontsize=10];\n"
        dot += "    label=\"Tradewinds Graph \(version)\";\n"
        dot += "    labelloc=t;\n"

        dot += subgraph(
            title: "Graph",
            routes: routes,
            resources: resources,
            flows: flows,
            target: target,
            prefix: "g"
        )

        dot += "}\n"
        return dot
    }

    /// Generates a combined Graphviz DOT language representation of the setup, expected, and actual flows.
    public static func generateCombinedDot<
        Node: TradewindsNode,
        ID: Hashable & CustomStringConvertible
    >(
        routes: [Route<Node, ID>],
        resources: [Resource<Node>],
        expectedFlows: [Flow<Node, ID>],
        actualFlows: [Flow<Node, ID>],
        target: Target<Node>
    ) -> String {
        var dot = "digraph TradewindsCombined {\n"
        dot += "    rankdir=TB;\n"
        dot += "    label=\"Tradewinds Flow Comparison\";\n"
        dot += "    labelloc=t;\n"

        // Setup Subgraph
        dot += subgraph(
            title: "Setup",
            routes: routes,
            resources: resources,
            flows: nil,
            target: target,
            prefix: "s"
        )

        // Expected Subgraph
        dot += subgraph(
            title: "Expected Solution",
            routes: routes,
            resources: resources,
            flows: expectedFlows,
            target: target,
            prefix: "e"
        )

        // Actual Subgraph
        dot += subgraph(
            title: "Actual Solution",
            routes: routes,
            resources: resources,
            flows: actualFlows,
            target: target,
            prefix: "a"
        )

        dot += "}\n"
        return dot
    }

    private static func subgraph<Node: TradewindsNode, ID: Hashable & CustomStringConvertible>(
        title: String,
        routes: [Route<Node, ID>],
        resources: [Resource<Node>]?,
        flows: [Flow<Node, ID>]?,
        target: Target<Node>?,
        prefix: String
    ) -> String {
        var dot = "    subgraph cluster_\(prefix) {\n"
        dot += "        label = \"\(title)\";\n"
        dot += "        style = rounded;\n"

        var allNodes = Set<Node>()
        routes.forEach {
            allNodes.insert($0.source)
            allNodes.insert($0.sink)
        }
        resources?.forEach { allNodes.insert($0.node) }
        if let target = target { allNodes.insert(target.node) }

        // Use Dictionary(grouping:by:) and take the first value for duplicates
        let resourceMap = Dictionary(
            (resources ?? []).map { ($0.node, $0.amount) },
            uniquingKeysWith: { first, _ in first }
        )
        let flowMap = (flows ?? [])
            .reduce(into: [String: Number]()) {
                $0[$1.route.id, default: 0] += $1.amount
            }

        for node in allNodes.sorted(by: { String(describing: $0) < String(describing: $1) }) {
            let nodeID = "\(prefix)_\(String(describing: node).toGraphvizID())"
            var nodeLabel = String(describing: node).escapeForGraphvizLabel()
            var style = ""
            let shape = ""

            if let resource = resourceMap[node] {
                let amountStr: String
                switch resource {
                    case .exact(let n):
                        amountStr = ScientificLabel.unsigned(n, decimals: node.decimals)
                    case .max: amountStr = "Max"
                }
                nodeLabel = "\(nodeLabel)\\n\(amountStr)"
                style = ", style=\"rounded,filled\", fillcolor=lightgreen"
            }

            if let target = target, node == target.node {
                // For target node, show the target amount
                let targetAmountStr: String
                switch target.amount {
                    case .exact(let n):
                        targetAmountStr = ScientificLabel.unsigned(
                            n,
                            decimals: target.node.decimals
                        )
                    case .max:
                        targetAmountStr = "Max"
                }
                nodeLabel = "\(nodeLabel)\\nTarget: \(targetAmountStr)"
                style = ", style=\"rounded,filled,bold\", fillcolor=lightblue, penwidth=2"
            }

            let attributes = "[label=\"\(nodeLabel)\"\(style)\(shape)]"
            dot += "        \"\(nodeID)\" \(attributes);\n"
        }

        for route in routes {
            let sourceID = "\(prefix)_\(String(describing: route.source).toGraphvizID())"
            let sinkID = "\(prefix)_\(String(describing: route.sink).toGraphvizID())"
            let flowAmount = flowMap[route.id]
            let isActive = flowAmount != nil && flowAmount! > 0

            var attributes = "color=gray, style=dashed"

            // Get a short label for the route type
            let routeTypeLabel = String(describing: route.type)
            let rateStr: String

            if let sourceDecimals = route.source.decimals,
                let sinkDecimals = route.sink.decimals
            {
                // Let's show the rate as a rate ratio
                let sourceRate = ScientificLabel.signed(
                    signed: route.rate.underlying,
                    decimals: 18 + sourceDecimals - sinkDecimals,
                    showDecimals: sinkDecimals
                )
                rateStr = "\(sourceRate) per 1e\(sinkDecimals)"
            } else {
                // Simple label with type and rate as well as fees
                let rateValue = route.rate.asDouble
                rateStr = String(format: " (%.2f)", rateValue)
            }

            var feeLabel = " "
            if route.totalInFees > .zero {
                feeLabel =
                    "[IN: \(ScientificLabel.unsigned(route.totalInFees, decimals: route.source.decimals))]"
            }
            if route.totalOutFees > .zero {
                feeLabel =
                    "[OUT: \(ScientificLabel.unsigned(route.totalOutFees, decimals: route.sink.decimals))]"
            }

            // Add flow constraints if present
            var flowConstraints = ""
            var constraints: [String] = []

            // Show minFlow if non-zero
            if route.minFlow > .zero {
                let minFlowStr = ScientificLabel.unsigned(
                    route.minFlow,
                    decimals: route.source.decimals
                )
                constraints.append("min: \(minFlowStr)")
            }

            // Show maxFlow if not MAX_UINT_256
            if route.maxFlow < Number.MAX_UINT_256 {
                let maxFlowStr = ScientificLabel.unsigned(
                    route.maxFlow,
                    decimals: route.source.decimals
                )
                constraints.append("max: \(maxFlowStr)")
            }

            if !constraints.isEmpty {
                flowConstraints = "\\n[\(constraints.joined(separator: ", "))]"
            }

            var label = "\"\(routeTypeLabel)\(rateStr)\(feeLabel)\(flowConstraints)\""

            if isActive, let amount = flowAmount {
                attributes = "color=blue, style=bold, penwidth=2"
                // Add flow amount for active routes
                let flowStr: String = ScientificLabel.unsigned(
                    amount,
                    decimals: route.source.decimals
                )

                // Calculate flow transformation breakdown
                var transformationStr = ""
                let sourceAmount = SNumber(amount)

                // Step 1: Apply in-fees
                let afterInFees =
                    sourceAmount > route.totalInFees
                    ? sourceAmount - SNumber(route.totalInFees)
                    : SNumber.zero
                let afterInFeesStr = ScientificLabel.unsigned(
                    Number(afterInFees.magnitude),
                    decimals: route.source.decimals
                )

                // Step 2: Apply rate
                let afterRate = afterInFees * route.rate.underlying / SNumber("1000000000000000000")
                let afterRateStr = ScientificLabel.unsigned(
                    Number(afterRate.magnitude),
                    decimals: route.sink.decimals
                )

                // Step 3: Apply out-fees
                let delivered =
                    afterRate > route.totalOutFees
                    ? afterRate - SNumber(route.totalOutFees)
                    : SNumber.zero
                let deliveredStr = ScientificLabel.unsigned(
                    Number(delivered.magnitude),
                    decimals: route.sink.decimals
                )

                // Build transformation string showing the flow at each stage
                if route.totalInFees > 0 || route.totalOutFees > 0 {
                    var stages: [String] = []
                    if route.totalInFees > 0 {
                        stages.append("-inFee→\(afterInFeesStr)")
                    }
                    stages.append("×rate→\(afterRateStr)")
                    if route.totalOutFees > 0 {
                        stages.append("-outFee→\(deliveredStr)")
                    }
                    transformationStr = "\\n[\(stages.joined(separator: ", "))]"
                }

                label =
                    "\"\(routeTypeLabel)\(rateStr)\(feeLabel)\(flowConstraints)\\nFlow: \(flowStr)\(transformationStr)\""
            }

            dot += "        \"\(sourceID)\" -> \"\(sinkID)\" [label=\(label), \(attributes)];\n"
        }

        dot += "    }\n"
        return dot
    }

}

extension String {
    fileprivate func toGraphvizID() -> String {
        return
            self
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: "(", with: "_")
            .replacingOccurrences(of: ")", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ",", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ".", with: "_")
    }

    fileprivate func escapeForGraphvizLabel() -> String {
        return
            self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// Helper to sort nodes deterministically
extension TradewindsNode {
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: self))
    }
}
