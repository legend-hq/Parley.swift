import Foundation
import Prelude
import SwiftNumber

/// Protocol for nodes in the Tradewinds network
public protocol TradewindsNode: Hashable, Sendable {
    associatedtype FeeType: Hashable & Sendable = String
    var decimals: Int? { get }
}
/// Protocol for route types that provide custom identifiers
public protocol RouteIdentifiable {
    var identifier: String { get }
}
private let MAX_UINT_256: Number =
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
/// Network flow solver for multi-commodity trade route optimization
public enum Tradewinds {
    public static let ALLOWED_OVERSHOOT = Percentage(fromBps: Number(1))
    // MARK: - Public Types
    /// Errors that can occur during flow calculation
    public enum Error: Swift.Error, Equatable, CustomStringConvertible {
        case insufficientResources(target: FlowAmount, max: Number)
        case noPathFound
        case targetAboveMaxFlow
        case invalidInput(String)
        public var description: String {
            switch self {
                case .insufficientResources(let target, let max):
                    let targetStr: String
                    switch target {
                        case .exact(let number):
                            targetStr = ".exact(\(number))"
                        case .max:
                            targetStr = ".max"
                    }
                    return "insufficientResources(target: \(targetStr), max: \(max))"
                case .noPathFound:
                    return "noPathFound"
                case .targetAboveMaxFlow:
                    return "targetAboveMaxFlow"
                case .invalidInput(let message):
                    return "invalidInput(\(message))"
            }
        }
    }
    /// Fee with type annotation
    public struct Fee<FeeType: Hashable & Sendable>: Hashable, Sendable {
        public let type: FeeType
        public let isInFee: Bool
        public let amount: Number
        public init(type: FeeType, isInFee: Bool, amount: Number) {
            self.type = type
            self.isInFee = isInFee
            self.amount = amount
        }
    }
    /// A directed trade route between two nodes
    public struct Route<Node: TradewindsNode, ID: Hashable & Comparable>: Equatable, Hashable {
        public let type: ID  // Route type
        public let source: Node
        public let sink: Node
        public let rate: Percentage  // Exchange rate
        public let fees: [Fee<Node.FeeType>]  // Annotated fees
        public let minFlow: Number  // Minimum flow constraint
        public let maxFlow: Number  // Maximum capacity
        // Computed property based on type, source, sink, and rate
        public var id: String {
            let typeStr: String
            if let identifiable = type as? RouteIdentifiable {
                typeStr = identifiable.identifier
            } else {
                typeStr = "\(type)"
            }
            return "\(typeStr)_\(source)_\(sink)_\(rate)"
        }
        public init(
            type: ID,
            source: Node,
            sink: Node,
            rate: Percentage,
            fees: [Fee<Node.FeeType>] = [],
            minFlow: Number,
            maxFlow: Number
        ) {
            self.type = type
            self.source = source
            self.sink = sink
            self.rate = rate
            self.fees = fees
            self.minFlow = minFlow
            self.maxFlow = maxFlow
        }
        // Helper computed properties for fee calculations
        public var totalInFees: Number {
            fees.filter { $0.isInFee }.reduce(Number(0)) { $0 + $1.amount }
        }
        public var totalOutFees: Number {
            fees.filter { !$0.isInFee }.reduce(Number(0)) { $0 + $1.amount }
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(source)
            hasher.combine(sink)
            hasher.combine(rate)
            hasher.combine(fees)
            hasher.combine(minFlow)
            hasher.combine(maxFlow)
        }
    }
    public enum FlowAmount: Sendable, Equatable, Hashable {
        case exact(Number)
        case max
    }
    /// The target for a flow calculation
    public struct Target<Node: TradewindsNode>: Sendable {
        public let amount: FlowAmount
        public let node: Node
        public init(amount: FlowAmount, node: Node) {
            self.amount = amount
            self.node = node
        }
    }
    /// Initial resources at a node
    public struct Resource<Node: TradewindsNode>: Sendable {
        public let amount: FlowAmount
        public let node: Node
        public init(amount: FlowAmount, node: Node) {
            self.amount = amount
            self.node = node
        }
    }
    /// A flow along a specific route
    public struct Flow<Node: TradewindsNode, ID: Hashable & Comparable>: Hashable,
        CustomStringConvertible,
        Equatable
    {
        public let route: Route<Node, ID>
        public let amount: Number  // Amount at source
        public init(route: Route<Node, ID>, amount: Number) {
            self.route = route
            self.amount = amount
        }
        /// The amount delivered to the sink after applying fees and rate
        /// Uses floor to ensure we never request more than achievable (critical for bridges)
        public var sinkAmount: Number {
            let hp = HPAmount(from: amount)
            // Apply inFees first
            let afterInFees = hp > route.totalInFees ? hp - route.totalInFees : HPAmount.zero
            // Apply rate
            let afterRate = afterInFees * route.rate
            // Apply outFees
            let afterOutFees =
                afterRate > route.totalOutFees ? afterRate - route.totalOutFees : HPAmount.zero
            return afterOutFees.floor().toNumber()
        }
        public var description: String {
            "Flow(route: \"\(route.id)\", amount: \(amount))"
        }
        public static func == (lhs: Flow<Node, ID>, rhs: Flow<Node, ID>) -> Bool {
            lhs.route.id == rhs.route.id && lhs.amount == rhs.amount
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(route.id)
            hasher.combine(amount)
        }
    }
    /// Result of a flow calculation
    public struct FlowResult<Node: TradewindsNode, ID: Hashable & Comparable> {
        public let flows: [Flow<Node, ID>]
        public let totalSourceAmount: Number  // Total amount consumed from sources
        public let totalSinkAmount: Number  // Total amount delivered to sink
        public var pathDescriptions: [String] {
            var paths: [[Flow<Node, ID>]] = []
            var processedFlows = Set<Flow<Node, ID>>()
            let flowMap = flows.reduce(into: [Node: [Flow<Node, ID>]]()) {
                $0[$1.route.source, default: []].append($1)
            }
            let sourceFlows = flows.filter { flow in
                !flows.contains(where: { $0.route.sink == flow.route.source })
            }
            for flow in sourceFlows {
                if processedFlows.contains(flow) { continue }
                var path = [flow]
                processedFlows.insert(flow)
                var currentSink = flow.route.sink
                while let nextFlow = flowMap[currentSink]?
                    .first(where: {
                        !processedFlows.contains($0)
                    })
                {
                    path.append(nextFlow)
                    processedFlows.insert(nextFlow)
                    currentSink = nextFlow.route.sink
                }
                paths.append(path)
            }
            return paths.map { path in
                let routeStr = path.map { "\($0.route.id)" }.joined(separator: " → ")
                let amountStr = path.first.map { "\($0.amount)" } ?? "0"
                return "Path (\(amountStr)): \(routeStr)"
            }
        }
    }
    /// Type alias for cost functions
    public typealias CostFunction<Node: TradewindsNode, ID: Hashable & Comparable> = (
        Route<Node, ID>
    ) -> Double?
    // MARK: - Public API
    /// Find maximum amount of target resource achievable
    public static func maxFlow<Node: TradewindsNode, ID: Hashable & Comparable>(
        routes: [Route<Node, ID>],
        resources: [Resource<Node>],
        targetNode: Node,
        costFunction: CostFunction<Node, ID>
    ) -> Result<(flows: [Flow<Node, ID>], sinkAmount: Number), Error> {
        let target = Target(amount: .max, node: targetNode)
        switch flowWithResult(
            routes: routes,
            resources: resources,
            target: target,
            costFunction: costFunction
        ) {
            case .success(let result):
                return .success((flows: result.flows, sinkAmount: result.totalSinkAmount))
            case .failure(.insufficientResources), .failure(.noPathFound):
                // maxFlow should return 0, not error, when no flow is possible
                return .success((flows: [], sinkAmount: Number(0)))
            case .failure(let error):
                // Other errors (like invalid inputs) should still propagate
                return .failure(error)
        }
    }
    /// Find minimum-cost flow to achieve target amount
    public static func flow<Node: TradewindsNode, ID: Hashable & Comparable>(
        routes: [Route<Node, ID>],
        resources: [Resource<Node>],
        target: Target<Node>,
        costFunction: CostFunction<Node, ID>
    ) -> Result<[Flow<Node, ID>], Error> {
        switch flowWithResult(
            routes: routes,
            resources: resources,
            target: target,
            costFunction: costFunction
        ) {
            case .success(let result):
                return .success(result.flows)
            case .failure(let error):
                return .failure(error)
        }
    }
    /// Find minimum-cost flow with detailed result
    public static func flowWithResult<Node: TradewindsNode, ID: Hashable & Comparable>(
        routes: [Route<Node, ID>],
        resources: [Resource<Node>],
        target: Target<Node>,
        costFunction: CostFunction<Node, ID>
    ) -> Result<FlowResult<Node, ID>, Error> {
        // Validate routes - reject any with zero rate
        if let zeroRateRoute = routes.first(where: { $0.rate.isZero }) {
            return .failure(.invalidInput("Route has zero rate: \(zeroRateRoute.id)"))
        }
        let targetAmount: Number
        switch target.amount {
            case .exact(let number):
                targetAmount = number
            case .max:
                targetAmount = MAX_UINT_256
        }
        // Check if we already have enough at target
        let existingAtTarget: Number
        if let resourceAtTarget = resources.first(where: { $0.node == target.node }) {
            switch resourceAtTarget.amount {
                case .exact(let number):
                    existingAtTarget = number
                case .max:
                    // This case is ambiguous, but let's treat it as having enough for now
                    // if the target is not .max. A resource of .max should probably
                    // only be used when we are calculating a max flow.
                    existingAtTarget = MAX_UINT_256
            }
        } else {
            existingAtTarget = Number(0)
        }
        if existingAtTarget >= targetAmount {
            return .success(
                FlowResult<Node, ID>(
                    flows: [],
                    totalSourceAmount: Number(0),
                    totalSinkAmount: targetAmount
                )
            )
        }
        let result = findOptimalFlows(
            routes: routes,
            resources: resources,
            targetAmount: targetAmount - existingAtTarget,
            target: target.node,
            costFunction: costFunction,
            isMaxTarget: {
                switch target.amount {
                    case .max: return true
                    case .exact: return false
                }
            }()
        )
        // Success case
        let totalAchieved = result.totalSinkAmount + existingAtTarget
        // For .max targets, fail if we achieved zero (no valid path)
        if case .max = target.amount, totalAchieved == Number(0) {
            return .failure(.insufficientResources(target: target.amount, max: .zero))
        }
        // For exact amounts, fail if we didn't reach the target
        if target.amount != .max && totalAchieved < targetAmount {
            return .failure(.insufficientResources(target: target.amount, max: totalAchieved))
        }
        let finalResult = FlowResult<Node, ID>(
            flows: result.flows,
            totalSourceAmount: result.totalSourceAmount,
            totalSinkAmount: totalAchieved
        )
        return .success(finalResult)
    }
    // MARK: - Default Cost Functions
    /// Default cost function based on exchange rate
    public static func rateCostFunction<Node: TradewindsNode, ID: Hashable & Comparable>()
        -> CostFunction<Node, ID>
    {
        return { route in
            guard !route.rate.isZero else { return nil }
            return -log(route.rate.asDouble)
        }
    }
    // TODO: Multi-path fixed cost estimation
    // When flow splits across multiple paths, this cost function evaluates each using the full
    // targetAmount rather than the actual partial flow, causing mis-estimation of fixed cost impact.
    /// A cost function that incorporates dual fees (inFee and outFee) and accounts for fixed costs.
    /// Divides fee amounts by targetAmount to compare total cost across routes.
    public static func dualFeeCostFunction<Node: TradewindsNode, ID: Hashable & Comparable>(
        targetAmount: Number
    ) -> CostFunction<Node, ID> {
        return { route in
            let rateCost = rateCostFunction()(route) ?? Double.infinity
            // Avoid division by zero if target amount is 0
            guard targetAmount > Number(0) else {
                return rateCost
            }
            // inFee is subtracted before rate application
            // Its impact is proportional to how much it reduces the effective transfer amount
            let inFeeImpact = Double(route.totalInFees) / Double(targetAmount)
            // outFee is subtracted after rate application
            // To deliver targetAmount, we need (targetAmount + outFee) / rate from source
            let outFeeImpact =
                Double(route.totalOutFees) / (route.rate.asDouble * Double(targetAmount))
            return rateCost + inFeeImpact + outFeeImpact
        }
    }
    /// Alias for backwards compatibility - maps to dualFeeCostFunction
    public static func fixedPlusRateCostFunction<Node: TradewindsNode, ID: Hashable & Comparable>(
        targetAmount: Number
    ) -> CostFunction<Node, ID> {
        return dualFeeCostFunction(targetAmount: targetAmount)
    }
    /// Cost function that accounts for minimum flow requirements
    public static func minFlowAwareCostFunction<Node: TradewindsNode, ID: Hashable & Comparable>(
        targetAmount: Number
    ) -> CostFunction<Node, ID> {
        return { route in
            // Calculate effective rate considering minFlow
            let effectiveRate: Double
            if route.minFlow > targetAmount && targetAmount > Number(0) {
                // If we must send more than needed due to minFlow,
                // the effective rate is reduced proportionally
                effectiveRate = route.rate.asDouble * (Double(targetAmount) / Double(route.minFlow))
            } else {
                effectiveRate = route.rate.asDouble
            }
            // Use effective rate in cost calculation
            let rateCost = -log(effectiveRate)
            // Account for both fees (normalized by actual amount that will be sent)
            let amountToSend = max(route.minFlow, targetAmount)
            let inFeeComponent =
                amountToSend > Number(0) ? Double(route.totalInFees) / Double(amountToSend) : 0.0
            let outFeeComponent =
                amountToSend > Number(0) ? Double(route.totalOutFees) / Double(amountToSend) : 0.0
            return rateCost + inFeeComponent + outFeeComponent
        }
    }
    // MARK: - Implementation
    // MARK: - Fee helpers (clarify once-per-route fee handling)
    // Track routes already charged fixed fees (both in and out) in this execution.
    private typealias PaidRoutes = Set<String>
    /// Deduct in-fees that have not yet been paid for the given route.
    private static func deductUnpaidInFees<Node: TradewindsNode, ID: Hashable & Comparable>(
        _ amount: HPAmount,
        route: Route<Node, ID>,
        paidRoutes: PaidRoutes
    ) -> HPAmount {
        guard !paidRoutes.contains(route.id) else { return amount }
        var v = amount
        for fee in route.fees where fee.isInFee {
            v = v > fee.amount ? v - fee.amount : HPAmount.zero
        }
        return v
    }
    /// Deduct out-fees that have not yet been paid for the given route.
    private static func deductUnpaidOutFees<Node: TradewindsNode, ID: Hashable & Comparable>(
        _ amount: HPAmount,
        route: Route<Node, ID>,
        paidRoutes: PaidRoutes
    ) -> HPAmount {
        guard !paidRoutes.contains(route.id) else { return amount }
        var v = amount
        for fee in route.fees where !fee.isInFee {
            v = v > fee.amount ? v - fee.amount : HPAmount.zero
        }
        return v
    }
    /// Add in-fees that have not yet been paid to the needed amount for the given route.
    private static func addUnpaidInFees<Node: TradewindsNode, ID: Hashable & Comparable>(
        _ amount: HPAmount,
        route: Route<Node, ID>,
        paidRoutes: PaidRoutes
    ) -> HPAmount {
        guard !paidRoutes.contains(route.id) else { return amount }
        var v = amount
        for fee in route.fees where fee.isInFee {
            v = v + fee.amount
        }
        return v
    }
    /// Add out-fees that have not yet been paid to the needed amount for the given route.
    private static func addUnpaidOutFees<Node: TradewindsNode, ID: Hashable & Comparable>(
        _ amount: HPAmount,
        route: Route<Node, ID>,
        paidRoutes: PaidRoutes
    ) -> HPAmount {
        guard !paidRoutes.contains(route.id) else { return amount }
        var v = amount
        for fee in route.fees where !fee.isInFee {
            v = v + fee.amount
        }
        return v
    }
    /// Sum of unpaid in-fees for quick checks.
    private static func unpaidInFeesTotal<Node: TradewindsNode, ID: Hashable & Comparable>(
        route: Route<Node, ID>,
        paidRoutes: PaidRoutes
    ) -> Number {
        guard !paidRoutes.contains(route.id) else { return Number(0) }
        var total = Number(0)
        for fee in route.fees where fee.isInFee {
            total = total + fee.amount
        }
        return total
    }
    /// Sum of unpaid out-fees for quick checks.
    private static func unpaidOutFeesTotal<Node: TradewindsNode, ID: Hashable & Comparable>(
        route: Route<Node, ID>,
        paidRoutes: PaidRoutes
    ) -> Number {
        guard !paidRoutes.contains(route.id) else { return Number(0) }
        var total = Number(0)
        for fee in route.fees where !fee.isInFee {
            total = total + fee.amount
        }
        return total
    }
    // MARK: - Single-hop transforms
    /// Forward deliver across a single route (apply unpaid in-fees, rate, then unpaid out-fees).
    private static func forwardDeliver<Node: TradewindsNode, ID: Hashable & Comparable>(
        route: Route<Node, ID>,
        source: Number,
        paid: PaidRoutes
    ) -> Number {
        var v = HPAmount(from: source)
        v = deductUnpaidInFees(v, route: route, paidRoutes: paid)
        v = v * route.rate
        v = deductUnpaidOutFees(v, route: route, paidRoutes: paid)
        return v.floor().toNumber()
    }
    /// Backward source needed for a single route to deliver target at sink.
    private static func backwardSourceNeeded<Node: TradewindsNode, ID: Hashable & Comparable>(
        route: Route<Node, ID>,
        target: Number,
        paid: PaidRoutes
    ) -> Number {
        var need = HPAmount(from: target)
        need = addUnpaidOutFees(need, route: route, paidRoutes: paid)
        need = need / route.rate
        need = addUnpaidInFees(need, route: route, paidRoutes: paid)
        return need.ceil().toNumber()
    }
    /// Forward deliver across a prefix of routes assuming fees unpaid on those routes.
    private static func forwardDeliverPrefix<Node: TradewindsNode, ID: Hashable & Comparable>(
        path: [Route<Node, ID>],
        prefixCount: Int,
        source: Number
    ) -> Number {
        var v = HPAmount(from: source)
        let unpaid: PaidRoutes = []
        for i in 0..<prefixCount {
            let r = path[i]
            v = deductUnpaidInFees(v, route: r, paidRoutes: unpaid)
            v = v * r.rate
            v = deductUnpaidOutFees(v, route: r, paidRoutes: unpaid)
        }
        return v.floor().toNumber()
    }
    private struct SearchNode<Node: TradewindsNode>: Hashable {
        let node: Node
        let isRoot: Bool
    }

    private struct SearchState<Node: TradewindsNode>: Hashable {
        let current: SearchNode<Node>
        let pathNodes: Set<Node>  // Track nodes in path to prevent physical cycles
    }

    /// Find shortest path from available start nodes to target using Dijkstra's algorithm
    private static func findShortestPath<Node: TradewindsNode, ID: Hashable & Comparable>(
        graph: [Node: [(route: Route<Node, ID>, cost: Double)]],
        available: [Node: Number],
        target: Node,
        usedCapacity: [String: Number],
        failedRoutes: Set<String>,
        nodesWithFailedPaths: Set<Node>
    ) -> (prev: [SearchNode<Node>: SearchNode<Node>], routes: [SearchNode<Node>: Route<Node, ID>])?
    {
        // State-based Dijkstra: we track distance to each SearchNode.
        var dist: [SearchNode<Node>: Double] = [:]
        var prev: [SearchNode<Node>: SearchNode<Node>] = [:]
        var routeMap: [SearchNode<Node>: Route<Node, ID>] = [:]
        var visited = Set<SearchNode<Node>>()

        // Priority queue stores (cost, SearchNode, pathNodes)
        // pathNodes is used to prevent cycles during exploration
        var pq: [(cost: Double, current: SearchNode<Node>, pathNodes: Set<Node>)] = []

        // Start from all nodes with available resources (except the target)
        // Filter out nodes whose paths to target have failed
        let startNodes =
            available
            .filter { $0.value > Number(0) && $0.key != target && !nodesWithFailedPaths.contains($0.key) }
            .keys
            .sorted { String(describing: $0) < String(describing: $1) }

        for node in startNodes {
            let sn = SearchNode(node: node, isRoot: true)
            dist[sn] = 0.0
            pq.append((0.0, sn, [node]))
        }

        if pq.isEmpty { return nil }

        while !pq.isEmpty {
            // Find minimum with deterministic tie-breaking
            var minIndex = 0
            for i in 1..<pq.count {
                if pq[i].cost < pq[minIndex].cost {
                    minIndex = i
                } else if pq[i].cost == pq[minIndex].cost {
                    if pq[i].current.isRoot != pq[minIndex].current.isRoot {
                        if pq[i].current.isRoot { minIndex = i }
                    } else if String(describing: pq[i].current.node)
                        < String(describing: pq[minIndex].current.node)
                    {
                        minIndex = i
                    }
                }
            }
            let (currentDist, current, pathNodes) = pq.remove(at: minIndex)

            if visited.contains(current) { continue }
            visited.insert(current)

            if !current.isRoot && current.node == target {
                break
            }

            // Check neighbors
            for (route, cost) in graph[current.node] ?? [] {
                // Prevent physical cycles (don't return to a node already in this path)
                if pathNodes.contains(route.sink) { continue }

                // Skip failed routes only when exploring from a root state.
                if current.isRoot && failedRoutes.contains(route.id) {
                    continue
                }

                let usedOnRoute = usedCapacity[route.id] ?? Number(0)
                let remainingCapacity = route.maxFlow - usedOnRoute
                if remainingCapacity <= Number(0) { continue }
                if remainingCapacity < route.minFlow { continue }

                let newDist = currentDist + cost
                let nextSearchNode = SearchNode(node: route.sink, isRoot: false)

                // Standard Dijkstra update logic
                let shouldUpdate =
                    if let existingDist = dist[nextSearchNode] {
                        if newDist < existingDist {
                            true
                        } else if newDist == existingDist {
                            if let existingRoute = routeMap[nextSearchNode] {
                                route.id < existingRoute.id
                            } else {
                                true
                            }
                        } else {
                            false
                        }
                    } else {
                        true
                    }

                if shouldUpdate {
                    dist[nextSearchNode] = newDist
                    prev[nextSearchNode] = current
                    routeMap[nextSearchNode] = route
                    var nextPathNodes = pathNodes
                    nextPathNodes.insert(route.sink)
                    pq.append((newDist, nextSearchNode, nextPathNodes))
                }
            }
        }

        let targetState = SearchNode(node: target, isRoot: false)
        return prev[targetState] != nil ? (prev, routeMap) : nil
    }

    /// Reconstruct path from target back to source using state-aware predecessor map
    private static func reconstructPath<Node: TradewindsNode, ID: Hashable & Comparable>(
        from target: Node,
        using result: (
            prev: [SearchNode<Node>: SearchNode<Node>], routes: [SearchNode<Node>: Route<Node, ID>]
        )
    ) -> [Route<Node, ID>] {
        var path: [Route<Node, ID>] = []
        var currentState = SearchNode(node: target, isRoot: false)
        let maxPathSteps = 100

        var pathSteps = 0
        while let route = result.routes[currentState],
            let prevState = result.prev[currentState],
            pathSteps < maxPathSteps
        {
            path.append(route)
            currentState = prevState
            pathSteps += 1
            if currentState.isRoot { break }
        }

        path.reverse()
        return path
    }

    /// Topologically sort flows to respect execution dependencies
    private static func topologicalSort<Node: TradewindsNode, ID: Hashable & Comparable>(
        _ flows: [Flow<Node, ID>]
    ) -> [Flow<Node, ID>] {
        var sorted: [Flow<Node, ID>] = []
        var remaining = flows
        while !remaining.isEmpty {
            // Find flows that can be executed now (their source doesn't depend on any remaining flow's sink)
            let executable =
                remaining.filter { flow in
                    !remaining.contains { other in
                        other.route.sink == flow.route.source
                    }
                }
                .sorted { a, b in
                    // Deterministic ordering within executable flows
                    // First compare by type using its natural ordering
                    if a.route.type != b.route.type {
                        return a.route.type < b.route.type
                    }
                    // Then by amount
                    if a.amount != b.amount {
                        return a.amount < b.amount
                    }
                    // Then by route ID for additional determinism
                    if a.route.id != b.route.id {
                        return a.route.id < b.route.id
                    }
                    return String(describing: a.route.source) < String(describing: b.route.source)
                }
            if executable.isEmpty {
                // Cycle detected or remaining flows can't be ordered - add them sorted
                sorted.append(
                    contentsOf: remaining.sorted { a, b in
                        // First compare by type using its natural ordering
                        if a.route.type != b.route.type {
                            return a.route.type < b.route.type
                        }
                        // Then by amount
                        if a.amount != b.amount {
                            return a.amount < b.amount
                        }
                        // Then by route ID for additional determinism
                        if a.route.id != b.route.id {
                            return a.route.id < b.route.id
                        }
                        return String(describing: a.route.source)
                            < String(describing: b.route.source)
                    }
                )
                break
            }
            // Add executable flows and remove them from remaining
            sorted.append(contentsOf: executable)
            remaining.removeAll { flow in
                executable.contains { $0.route.id == flow.route.id && $0.amount == flow.amount }
            }
        }
        return sorted
    }
    /// Calculate flow amounts for a path considering all constraints
    private static func calculateFlowsForPath<Node: TradewindsNode, ID: Hashable & Comparable>(
        path: [Route<Node, ID>],
        remainingTarget: Number,
        bottleneck: Number,
        chargedRoutes: PaidRoutes,
        available: [Node: Number]
    ) -> (flows: [Number], failureIndex: Int?, deliveredToFailureSource: Number?) {
        guard !path.isEmpty else { return ([], nil, nil) }
        // Step 1: Backward pass to compute required source at each hop
        // For each hop, calculate: "how much needs to flow through this route to satisfy downstream?"
        // This respects route capacity constraints (maxFlow) and minimum requirements (minFlow)
        var requiredFlows: [HPAmount] = Array(repeating: HPAmount.zero, count: path.count)
        var needed = HPAmount(from: remainingTarget)
        for i in stride(from: path.count - 1, through: 0, by: -1) {
            let route = path[i]
            let paid = chargedRoutes
            needed = addUnpaidOutFees(needed, route: route, paidRoutes: paid)
            needed = needed / route.rate
            needed = addUnpaidInFees(needed, route: route, paidRoutes: paid)
            // Enforce minimum flow constraint
            // minFlow applies to the amount AFTER subtracting NON-OPERATION inFees (like QuotePay)
            // but BEFORE operation-specific inFees (like bridge fixed cost which is part of the operation)
            // So for bridges: needed >= (minFlow + QuotePay_fee) but NOT + bridge_fee
            // We identify non-operation fees as those with type .quotePay
            // Always enforce minFlow against the post-QuotePay input.
            // QuotePay is a non-operation in-fee and must be additive to minFlow.
            let totalNonOperationInFees: Number = route.fees
                .filter { fee in fee.isInFee && "\(fee.type)".lowercased() == "quotepay" }
                .reduce(Number(0)) { $0 + $1.amount }
            let minFlowIncludingInFees =
                HPAmount(from: route.minFlow) + HPAmount(from: totalNonOperationInFees)
            if needed.toNumber() < minFlowIncludingInFees.toNumber() {
                needed = minFlowIncludingInFees
            }
            // Clamp input to maxFlow capacity if needed
            // This happens AFTER minFlow enforcement to ensure minFlow takes priority
            if needed > route.maxFlow {
                needed = HPAmount(from: route.maxFlow)
            }
            // After all transformations and constraints, this is the target OUTPUT for validation
            // Forward-simulate from needed (INPUT) to verify delivery
            let targetForThisRoute: HPAmount = {
                var output = needed
                output = deductUnpaidInFees(output, route: route, paidRoutes: paid)
                output = output * route.rate
                output = deductUnpaidOutFees(output, route: route, paidRoutes: paid)
                return output.floor()
            }()
            // Account for floor in forward pass: verify that ceil(needed) will deliver enough after flooring
            var testAmount = needed.ceil()
            var testDelivery = HPAmount(from: testAmount.toNumber())
            testDelivery = deductUnpaidInFees(testDelivery, route: route, paidRoutes: paid)
            testDelivery = testDelivery * route.rate
            testDelivery = deductUnpaidOutFees(testDelivery, route: route, paidRoutes: paid)
            testDelivery = testDelivery.floor()
            // If floored delivery falls short, increment until we meet the target
            // Add safety limit to prevent infinite loops (max 1000 iterations)
            var iterations = 0
            let maxIterations = 1000
            while testDelivery.toNumber() < targetForThisRoute.toNumber()
                && iterations < maxIterations
            {
                testAmount = testAmount + HPAmount(from: Number("1"))
                testDelivery = HPAmount(from: testAmount.toNumber())
                testDelivery = deductUnpaidInFees(testDelivery, route: route, paidRoutes: paid)
                testDelivery = testDelivery * route.rate
                testDelivery = deductUnpaidOutFees(testDelivery, route: route, paidRoutes: paid)
                testDelivery = testDelivery.floor()
                iterations += 1
            }
            needed = testAmount
            requiredFlows[i] = needed
            // For intermediate nodes, subtract existing resources before propagating upstream
            // Principle: upstream hops only need to deliver the shortfall, not the total
            // This is generic: if node B needs 3000 and has 100, upstream only delivers 2900
            if i > 0 {
                let sourceNode = route.source
                let existingAtSource = available[sourceNode, default: Number(0)]
                needed = needed > existingAtSource ? needed - existingAtSource : HPAmount.zero
            }
        }
        // Step 2: Apply constraints and propagate downstream requirements
        var constrainedFlows: [Number] = []
        for (index, route) in path.enumerated() {
            var flowAmount = requiredFlows[index].ceil().toNumber()
            // Apply route's maxFlow constraint only (minFlow already enforced via backward pass)
            flowAmount = min(flowAmount, route.maxFlow)
            constrainedFlows.append(flowAmount)
        }
        // Step 3: Calculate actual flows considering available resources
        var actualFlows: [Number] = []
        for (index, route) in path.enumerated() {
            let constrainedFlow = constrainedFlows[index]
            var flowAmount: HPAmount
            if index == 0 {
                // First hop: limited by available resources
                flowAmount = HPAmount.min(HPAmount(from: constrainedFlow), bottleneck)
                // Can't meet minimum requirements (considering non-operation inFees only)
                let totalNonOperationInFees: Number = route.fees
                    .filter { fee in fee.isInFee && "\(fee.type)".lowercased() == "quotepay" }
                    .reduce(Number(0)) { $0 + $1.amount }
                let minFlowIncludingInFees =
                    HPAmount(from: route.minFlow) + HPAmount(from: totalNonOperationInFees)
                if flowAmount.toNumber() < minFlowIncludingInFees.toNumber() {
                    return ([], 0, nil)
                }
            } else {
                // For intermediate hops, total available = upstream delivery + existing resources
                // Principle: any node can use both what arrives AND what's already there
                let upstreamRoute = path[index - 1]
                let upstreamFlow = actualFlows[index - 1]
                var availableFromUpstream = HPAmount(from: upstreamFlow)
                let paid = chargedRoutes
                availableFromUpstream = deductUnpaidInFees(
                    availableFromUpstream,
                    route: upstreamRoute,
                    paidRoutes: paid
                )
                availableFromUpstream = availableFromUpstream * upstreamRoute.rate
                availableFromUpstream = deductUnpaidOutFees(
                    availableFromUpstream,
                    route: upstreamRoute,
                    paidRoutes: paid
                )
                availableFromUpstream = availableFromUpstream.floor()
                let existingAtSource = HPAmount(from: available[route.source, default: Number(0)])
                let totalAvailable = availableFromUpstream + existingAtSource
                // Flow the minimum of total available and what's constrained by route/target
                flowAmount = HPAmount.min(totalAvailable, constrainedFlow)
                // Ensure we meet route constraints (considering non-operation inFees only)
                let totalNonOperationInFees: Number = route.fees
                    .filter { fee in fee.isInFee && "\(fee.type)".lowercased() == "quotepay" }
                    .reduce(Number(0)) { $0 + $1.amount }
                let minFlowIncludingInFees =
                    HPAmount(from: route.minFlow) + HPAmount(from: totalNonOperationInFees)
                if flowAmount.toNumber() < minFlowIncludingInFees.toNumber() {
                    // Try to use exactly minFlow if available (use integer comparison to avoid tiny fractional underflow)
                    if totalAvailable.toNumber() >= minFlowIncludingInFees.toNumber() {
                        flowAmount = minFlowIncludingInFees
                    } else {
                        // We can stage liquidity to this hop's source by executing the prefix
                        // The amount deliverable to this source is totalAvailable
                        return (actualFlows, index, totalAvailable.toNumber())
                    }
                }
                flowAmount = HPAmount.min(flowAmount, route.maxFlow)
            }
            let finalAmount = flowAmount.ceil().toNumber()
            actualFlows.append(finalAmount)
        }
        return (actualFlows, nil, nil)
    }
    private static func findOptimalFlows<Node: TradewindsNode, ID: Hashable & Comparable>(
        routes: [Route<Node, ID>],
        resources: [Resource<Node>],
        targetAmount: Number,
        target: Node,
        costFunction: CostFunction<Node, ID>,
        isMaxTarget: Bool
    ) -> FlowResult<Node, ID> {
        /*
         Staged exact-in accumulation (high level):
         - The solver selects one best path (linear chain) to the target per iteration via Dijkstra.
         - If a downstream hop on that path has a positive minFlow (e.g., an exact-in swap) and
           the upstream availability into that hop is insufficient, we "stage" liquidity by
           executing only the prefix of the path up to the hop’s source, crediting the amount
           delivered to that intermediate node (not to the final target), and then retry.
         - This allows multiple start nodes (e.g., different chains) to supply an intermediate
           node across iterations until the exact-in hop’s minFlow can be satisfied in one shot.
        
         Invariants and safety:
         - Staging is only applied when a downstream hop (index > 0) fails a minFlow check.
         - Prefix execution respects fees and maxFlow on each prefix hop and deducts only from
           the first-hop source’s available resources; it credits the hop’s source node at the
           failure index with the delivered amount (after fees and rate), not the final target.
         - We do not mutate paidFees for staging (fees are paid once when the actual hop executes).
         - If the first hop fails, the start node is excluded for this iteration (as before).
         - The loop terminates when either: (1) the final hop executes successfully; or (2) no
           start nodes can contribute further (insufficient resources/capacity).
        */
        // Create adjacency list with deterministic ordering
        var graph: [Node: [(route: Route<Node, ID>, cost: Double)]] = [:]
        for route in routes {
            // Skip routes with nil cost (infinite cost)
            guard let cost = costFunction(route) else { continue }
            graph[route.source, default: []].append((route, cost))
        }
        // Sort adjacency lists for determinism: by cost, then by route ID
        for (node, _) in graph {
            graph[node]?
                .sort { (a, b) in
                    if a.cost != b.cost {
                        return a.cost < b.cost  // Better cost first
                    }
                    return a.route.id < b.route.id  // Tie-breaker: alphabetical by ID
                }
        }
        // Available resources
        var available: [Node: Number] = [:]
        for resource in resources {
            let amount: Number
            switch resource.amount {
                case .exact(let number):
                    amount = number
                case .max:
                    amount = MAX_UINT_256
            }
            available[resource.node, default: Number(0)] += amount
        }
        var flowAmounts: [String: Number] = [:]
        var totalSourceAmount = Number(0)
        var totalSinkAmount = Number(0)
        var remainingTarget = targetAmount
        var usedCapacity: [String: Number] = [:]
        var chargedRoutes: PaidRoutes = []
        var failedRoutes = Set<String>()  // Track routes that failed validation (e.g., minFlow not met)
        var nodesWithFailedPaths = Set<Node>()  // Track nodes whose paths to target have failed
        // Helper to mark a route as failed.
        // We track failed routes but DON'T immediately mark the node as having failed paths.
        // This allows other routes from the same start node to be tried.
        // The node is only marked as having failed paths when ALL routes from it have failed.
        func markRouteFailed(route: Route<Node, ID>) {
            failedRoutes.insert(route.id)
            // Check if ALL routes from this source have now failed
            let routesFromSource = graph[route.source] ?? []
            let allFailed = routesFromSource.allSatisfy { failedRoutes.contains($0.route.id) }
            if allFailed {
                nodesWithFailedPaths.insert(route.source)
            }
        }
        // Track which start nodes have at least one failed route (need incoming resources)
        func startNodeNeedsIncomingRoutes(_ node: Node) -> Bool {
            guard let routes = graph[node] else { return false }
            return routes.contains { failedRoutes.contains($0.route.id) }
        }
        // Repeatedly find best path until target is met
        var iterations = 0
        let maxIterations = 100  // Prevent infinite loops
        while remainingTarget > Number(0) && iterations < maxIterations {
            iterations += 1
            let previousRemaining = remainingTarget
            // Find best path to target using Dijkstra
            guard
                let shortestPathResult = findShortestPath(
                    graph: graph,
                    available: available,
                    target: target,
                    usedCapacity: usedCapacity,
                    failedRoutes: failedRoutes,
                    nodesWithFailedPaths: nodesWithFailedPaths
                )
            else {
                break  // No path found or no resources available
            }
            // Reconstruct path
            let path = reconstructPath(from: target, using: shortestPathResult)
            // Calculate how much to send
            var bottleneck: Number
            if let firstRoute = path.first, let sourceAmount = available[firstRoute.source] {
                bottleneck = sourceAmount
            } else {
                bottleneck = Number(0)
            }
            // Check capacity constraints along the path (fee-aware backpropagation)
            // Convert each hop's remaining capacity into source terms using backward single-hop transforms.
            for (i, route) in path.enumerated() {
                let remainingCapacity = route.maxFlow - (usedCapacity[route.id] ?? Number(0))
                let capacityAtSourceTerms: Number = {
                    if i == 0 { return max(remainingCapacity, Number(0)) }
                    var cap = max(remainingCapacity, Number(0))
                    let unpaid: PaidRoutes = []
                    for backIndex in stride(from: i - 1, through: 0, by: -1) {
                        cap = backwardSourceNeeded(
                            route: path[backIndex],
                            target: cap,
                            paid: unpaid
                        )
                    }
                    return cap
                }()
                bottleneck = min(bottleneck, capacityAtSourceTerms)
            }
            // Helper function to calculate flows for a path
            let pathCalc = calculateFlowsForPath(
                path: path,
                remainingTarget: remainingTarget,
                bottleneck: bottleneck,
                chargedRoutes: chargedRoutes,
                available: available
            )
            // Handle failure cases
            if let failureIndex = pathCalc.failureIndex {
                // First hop failed: for .max targets we can stage minimum at first hop to unlock downstream capacity
                if failureIndex == 0 {
                    if isMaxTarget, path.count >= 2, let firstHop = path.first {
                        // Stage exactly the first hop's minFlow when feasible
                        let startAvail = available[firstHop.source, default: Number(0)]
                        let remainingCap =
                            firstHop.maxFlow - (usedCapacity[firstHop.id] ?? Number(0))
                        let capBound = min(startAvail, remainingCap)
                        let stageAmount = firstHop.minFlow
                        if capBound >= stageAmount, stageAmount > Number(0) {
                            let delivered = forwardDeliver(
                                route: firstHop,
                                source: stageAmount,
                                paid: []
                            )
                            if delivered > Number(0) {
                                // Apply stage
                                flowAmounts[firstHop.id, default: Number(0)] += stageAmount
                                usedCapacity[firstHop.id, default: Number(0)] += stageAmount
                                let currentAvailable = available[
                                    firstHop.source,
                                    default: Number(0)
                                ]
                                available[firstHop.source] =
                                    currentAvailable > stageAmount
                                    ? currentAvailable - stageAmount : Number(0)
                                totalSourceAmount += stageAmount
                                available[firstHop.sink, default: Number(0)] += delivered
                                continue
                            }
                        }
                    }
                    if let firstRoute = path.first {
                        markRouteFailed(route: firstRoute)
                    }
                    continue
                }
                // Downstream hop failed: execute prefix to stage liquidity
                var prefixFlows = pathCalc.flows  // amounts at source terms for hops 0..failureIndex-1
                if prefixFlows.isEmpty && failureIndex > 0 {
                    // nothing to stage
                    if let firstRoute = path.first {
                        markRouteFailed(route: firstRoute)
                    }
                    continue
                }
                // Apply prefix flows (0..failureIndex-1)
                // Special case: single-hop prefix – limit flow to shortfall pre-image to avoid over-staging
                if failureIndex == 1 {
                    let failingRoute = path[failureIndex]
                    let currentAtFailure = available[failingRoute.source, default: Number(0)]
                    let shortfall =
                        failingRoute.minFlow > currentAtFailure
                        ? (failingRoute.minFlow - currentAtFailure) : Number(0)
                    if shortfall == Number(0) { continue }
                    let r = path[0]
                    // Capacity bound at first hop
                    let startAvail = available[r.source, default: Number(0)]
                    let remainingCap = (r.maxFlow - (usedCapacity[r.id] ?? Number(0)))
                    let capBound = min(startAvail, remainingCap)
                    if capBound == Number(0) {
                        if let firstRoute = path.first {
                            markRouteFailed(route: firstRoute)
                        }
                        continue
                    }
                    // Deliverable cap through first hop
                    let capDeliver = forwardDeliver(route: r, source: capBound, paid: [])
                    if capDeliver == Number(0) {
                        if let firstRoute = path.first {
                            markRouteFailed(route: firstRoute)
                        }
                        continue
                    }
                    let targetDeliver = min(shortfall, capDeliver)
                    // Backward single-hop source needed (ceil to satisfy)
                    let needed = backwardSourceNeeded(route: r, target: targetDeliver, paid: [])
                    var stageSource = min(max(needed, Number(1)), capBound)
                    // Single correction step to guard rounding
                    if forwardDeliver(route: r, source: stageSource, paid: []) < targetDeliver
                        && stageSource < capBound
                    {
                        stageSource = stageSource + Number(1)
                    }
                    if forwardDeliver(route: r, source: stageSource, paid: []) < targetDeliver {
                        if let firstRoute = path.first {
                            markRouteFailed(route: firstRoute)
                        }
                        continue
                    }
                    prefixFlows = [stageSource]
                }
                // Apply the (possibly adjusted) prefix flows
                for (i, amountForCurrentHop) in prefixFlows.enumerated() {
                    let route = path[i]
                    flowAmounts[route.id, default: Number(0)] += amountForCurrentHop
                    usedCapacity[route.id, default: Number(0)] += amountForCurrentHop
                    if i == 0 {
                        // First hop: deduct from source wallet
                        let currentAvailable = available[route.source, default: Number(0)]
                        let actualDeduction = min(amountForCurrentHop, currentAvailable)
                        available[route.source] = currentAvailable - actualDeduction
                        totalSourceAmount += actualDeduction
                    } else {
                        // Intermediate hop in staging: track consumption of existing resources
                        let upstreamRoute = path[i - 1]
                        let upstreamFlow = prefixFlows[i - 1]
                        // Calculate delivery using forwardDeliver with empty paid set
                        // (fees apply fresh during staging)
                        let upstreamDelivered = forwardDeliver(
                            route: upstreamRoute,
                            source: upstreamFlow,
                            paid: []
                        )
                        // Amount consumed from existing resources
                        let consumedFromExisting =
                            amountForCurrentHop > upstreamDelivered
                            ? amountForCurrentHop - upstreamDelivered
                            : Number(0)
                        // Decrement consumed existing resources
                        if consumedFromExisting > Number(0) {
                            let currentAvailable = available[route.source, default: Number(0)]
                            available[route.source] =
                                currentAvailable > consumedFromExisting
                                ? currentAvailable - consumedFromExisting
                                : Number(0)
                        }
                    }
                    // For staging, we do not mutate chargedRoutes (fees are per execution),
                    // we only update availability at the failure hop source at the end
                }
                // Credit the delivered amount to the failing hop's source node
                let failureSourceNode = path[failureIndex].source
                // Compute delivered amount from applied prefix flows using forward fee application
                let deliveredStage = forwardDeliverPrefix(
                    path: path,
                    prefixCount: failureIndex,
                    source: prefixFlows.first ?? Number(0)
                )
                available[failureSourceNode, default: Number(0)] += deliveredStage
                // Note: With failedRoutes tracking, the node itself was never excluded,
                // only specific routes were. So no need to re-enable the node.
                // Try again with updated availability (do not change remainingTarget)
                continue
            }
            let hopFlowAmounts = pathCalc.flows
            bottleneck = hopFlowAmounts.first ?? Number(0)
            if bottleneck == Number(0) { break }
            // Pre-validate that we can actually pay all fees along this path
            // This prevents us from creating flows that would saturate to 0
            var validationAmount = HPAmount(from: bottleneck)
            for route in path {
                let inDue = unpaidInFeesTotal(route: route, paidRoutes: chargedRoutes)
                if validationAmount < inDue {
                    bottleneck = Number(0)
                    break
                }
                validationAmount = validationAmount - inDue
                validationAmount = validationAmount * route.rate
                let outDue = unpaidOutFeesTotal(route: route, paidRoutes: chargedRoutes)
                if validationAmount < outDue {
                    bottleneck = Number(0)
                    break
                }
                validationAmount = validationAmount - outDue
            }
            if bottleneck == Number(0) {
                // Path validation failed - try next path
                // Mark the route as failed so we try alternative routes from the same source
                if let firstRoute = path.first {
                    markRouteFailed(route: firstRoute)
                }
                continue
            }
            // Apply flows
            var deliveredAfterFees = Number(0)
            for (i, route) in path.enumerated() {
                let amountForCurrentHop = hopFlowAmounts[i]
                // Use the amount for the current hop to create the Flow object
                flowAmounts[route.id, default: Number(0)] += amountForCurrentHop
                // Update used capacity with the amount that entered this hop
                usedCapacity[route.id, default: Number(0)] += amountForCurrentHop
                // Handle resource deduction based on hop position
                if i == 0 {
                    // First hop: deduct from source wallet
                    let currentAvailable = available[route.source, default: Number(0)]
                    let actualDeduction = min(amountForCurrentHop, currentAvailable)
                    if currentAvailable < actualDeduction {
                        available[route.source] = Number(0)
                    } else {
                        available[route.source] = currentAvailable - actualDeduction
                    }
                    totalSourceAmount += actualDeduction
                } else {
                    // Intermediate or final hop: track consumption of existing resources
                    let upstreamRoute = path[i - 1]
                    let upstreamFlow = hopFlowAmounts[i - 1]
                    // Calculate how much the upstream hop delivered to this hop's source
                    // This accounts for fees (if not already paid) and rate
                    let upstreamDelivered: Number
                    if chargedRoutes.contains(upstreamRoute.id) {
                        // Fees already paid in previous iteration - just apply rate
                        var v = HPAmount(from: upstreamFlow)
                        v = v * upstreamRoute.rate
                        upstreamDelivered = v.floor().toNumber()
                    } else {
                        // First use of this route - apply fees and mark as paid
                        upstreamDelivered = forwardDeliver(
                            route: upstreamRoute,
                            source: upstreamFlow,
                            paid: chargedRoutes
                        )
                        chargedRoutes.insert(upstreamRoute.id)
                    }
                    // Amount consumed from existing resources at this hop's source node
                    // If this hop flows more than what arrived from upstream, the difference
                    // must have come from existing resources at this node
                    let consumedFromExisting =
                        amountForCurrentHop > upstreamDelivered
                        ? amountForCurrentHop - upstreamDelivered
                        : Number(0)
                    // Decrement the consumed existing resources to prevent double-counting
                    if consumedFromExisting > Number(0) {
                        let currentAvailable = available[route.source, default: Number(0)]
                        available[route.source] =
                            currentAvailable > consumedFromExisting
                            ? currentAvailable - consumedFromExisting
                            : Number(0)
                    }
                }
                // Calculate delivery for the last hop
                if i == path.count - 1 {
                    var afterInFees = HPAmount(from: amountForCurrentHop)
                    let alreadyCharged = chargedRoutes.contains(route.id)
                    if !alreadyCharged {
                        for fee in route.fees where fee.isInFee {
                            afterInFees =
                                afterInFees > fee.amount ? afterInFees - fee.amount : HPAmount.zero
                        }
                    }
                    let sinkAmount = afterInFees * route.rate
                    var afterOutFees = sinkAmount
                    if !alreadyCharged {
                        for fee in route.fees where !fee.isInFee {
                            afterOutFees =
                                afterOutFees > fee.amount
                                ? afterOutFees - fee.amount : HPAmount.zero
                        }
                        chargedRoutes.insert(route.id)
                    }
                    deliveredAfterFees = afterOutFees.floor().toNumber()
                }
                // Note: Removed the else block that marked intermediate hops as paid
                // They are now marked when calculating upstream delivery for the next hop
            }
            // Check if this delivery would overshoot the target
            // Never allow overshooting the target
            if deliveredAfterFees > remainingTarget {
                // This path would overshoot - skip it and try another
                continue
            }
            totalSinkAmount += deliveredAfterFees
            remainingTarget = remainingTarget - deliveredAfterFees
            // Check if we made progress
            if remainingTarget == previousRemaining {
                // No progress made - stop trying
                break
            }
        }
        let routeMap = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })
        let flows = flowAmounts.keys.sorted()
            .compactMap { id -> Flow<Node, ID>? in
                guard let route = routeMap[id], let amount = flowAmounts[id] else { return nil }
                return Flow(route: route, amount: amount)
            }
        // Topological sort respects execution dependencies while preserving deterministic order
        let finalFlows = topologicalSort(flows)
        return FlowResult<Node, ID>(
            flows: finalFlows,
            totalSourceAmount: totalSourceAmount,
            totalSinkAmount: totalSinkAmount
        )
    }
}
