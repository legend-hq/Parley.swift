import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

public enum Charter {
    public static let version = "1.6.0"

    // MARK: - Action Type Constants
    static let ACTION_TYPE_AAVE_SUPPLY = "AAVE_SUPPLY"
    static let ACTION_TYPE_AAVE_WITHDRAW = "AAVE_WITHDRAW"
    static let ACTION_TYPE_COMET_BORROW = "COMET_BORROW"
    static let ACTION_TYPE_MORPHO_BORROW = "MORPHO_BORROW"
    static let ACTION_TYPE_BRIDGE = "BRIDGE"
    static let ACTION_TYPE_BRIDGE_MINT = "BRIDGE_MINT"
    static let ACTION_TYPE_COMET_CLAIM_REWARDS = "COMET_CLAIM_REWARDS"
    static let ACTION_TYPE_MORPHO_CLAIM_REWARDS = "MORPHO_CLAIM_REWARDS"
    static let ACTION_TYPE_RECURRING_SWAP = "RECURRING_SWAP"
    static let ACTION_TYPE_COMET_REPAY = "COMET_REPAY"
    static let ACTION_TYPE_MORPHO_REPAY = "MORPHO_REPAY"
    static let ACTION_TYPE_COMET_SUPPLY = "COMET_SUPPLY"
    static let ACTION_TYPE_MORPHO_VAULT_SUPPLY = "MORPHO_VAULT_SUPPLY"
    static let ACTION_TYPE_SWAP = "SWAP"
    static let ACTION_TYPE_TRANSFER = "TRANSFER"
    static let ACTION_TYPE_COMET_WITHDRAW = "COMET_WITHDRAW"
    static let ACTION_TYPE_MORPHO_VAULT_WITHDRAW = "MORPHO_VAULT_WITHDRAW"
    static let ACTION_TYPE_WRAP = "WRAP"
    static let ACTION_TYPE_UNWRAP = "UNWRAP"
    static let ACTION_TYPE_QUOTE_PAY = "QUOTE_PAY"
    static let ACTION_TYPE_MULTI_ACTION = "MULTI_ACTION"
    static let ACTION_TYPE_WITHDRAW_AND_BORROW = "WITHDRAW_AND_BORROW"
    static let ACTION_TYPE_LOOP_LONG = "LOOP_LONG"
    static let ACTION_TYPE_UNLOOP_LONG = "UNLOOP_LONG"
    static let ACTION_TYPE_LOOP_SHORT = "LOOP_SHORT"
    static let ACTION_TYPE_UNLOOP_SHORT = "UNLOOP_SHORT"
    static let ACTION_TYPE_ADD_BACKING_TOKEN = "ADD_BACKING_TOKEN"
    static let ACTION_TYPE_WITHDRAW_BACKING_TOKEN = "WITHDRAW_BACKING_TOKEN"

    // MARK: - Venue Constants
    static let SWAP_VENUE_UNISWAP_V3 = "UNISWAP_V3"
    static let BORROW_VENUE_MORPHO_BLUE = "MORPHO_BLUE"

    // MARK: - Bridge Type Constants
    static let BRIDGE_TYPE_ACROSS = "ACROSS"

    // MARK: - Fee Description Constants
    static let FEE_DESCRIPTION_LEGEND = "LEGEND"
    static let FEE_DESCRIPTION_ZERO_EX = "ZERO_EX"

    // MARK: - Expiry Buffer Constants
    static let STANDARD_EXPIRY_BUFFER: Number = 900  // 15 minutes
    static let BRIDGE_EXPIRY_BUFFER: Number = 900  // 15 minutes
    static let SWAP_EXPIRY_BUFFER: Number = 900  // 15 minutes
    static let TRANSFER_EXPIRY_BUFFER: Number = 900  // 15 minutes

    // MARK: - Fee Constants
    static let SWAP_FEE_PERCENT: Number = Number("15e14")  // 0.15% = 0.0015e18
    static let LOOP_FEE_PERCENT: Number = Number("4e14")  // 0.04% = 0.0004e18
    static let FEE_PERCENT_SCALE: Number = Number("1e18")

    // MARK: - Fee Recipients
    static let SWAP_FEE_RECIPIENT = EthAddress("0x7ea8d6119596016935543d90Ee8f5126285060A1")
    static let LOOP_FEE_RECIPIENT = EthAddress("0x7ea8d6119596016935543d90Ee8f5126285060A1")

    // MARK: - Buffer Constants

    /// Buffer for max withdrawals to account for interest accrual between calculation and execution.
    /// Applied as rate multiplier in Tradewinds (covers ~52 min @ 10% APY, ~10 min @ 50% APY).
    static let MAX_WITHDRAW_BUFFER: Percentage = Percentage(fromNumber: Number("1.00001e18"))

    /// Buffer for max repay to account for interest accrual on debt between calculation and execution.
    /// Applied to maxFlow constraint on repay route (covers ~52 min @ 10% APY, ~10 min @ 50% APY).
    static let MAX_REPAY_BUFFER: Percentage = Percentage(fromNumber: Number("1.00001e18"))

    /// Buffer for max swap outputs to model capacity for favorable slippage in Tradewinds.
    /// Only affects flow planning, not on-chain buyAmount.
    /// TODO: Consider reducing to 1.01 since this could be a bit too high.
    static let SWAP_OUTPUT_BUFFER: Percentage = Percentage(fromNumber: Number("1.015e18"))

    // MARK: - Slippage Constants

    /// Default max slippage tolerance for swap v2 operations, expressed as a percentage in 1e18 scale.
    /// Applied internally as a factor: rate * (1 - tolerance), e.g. rate * 0.99 for 1% tolerance.
    public static let SWAP_MAX_SLIPPAGE: Percentage = Percentage(fromNumber: Number("0.01e18"))

    /// @notice The unique ID given to Legend by the Across team to track the origination source of deposits
    static let ACROSS_UNIQUE_IDENTIFIER: Hex = Hex("0x0067")

    /// @notice The buffer to subtract from the quote timestamp to ensure it isn't some time in
    ///         the future, which would cause the Across SpokePool contract to revert
    static let ACROSS_QUOTE_TIMESTAMP_BUFFER: UInt = 30  // 30 seconds

    /// @notice The amount of time that the bridge action has to be filled before timing out
    static let ACROSS_FILL_DEADLINE_BUFFER: UInt = 600  // 10 minutes

    // @TODO: Change to reference from Atlas once available
    static let CCTP_V2_TOKEN_MESSENGER: EthAddress = EthAddress(
        "0x28b5a0e9C621a5BadaA536219b3a228C8168cf5d"
    )

    // @TODO: Change to reference from Atlas once available
    static let CCTP_V2_MESSAGE_TRANSMITTER: EthAddress = EthAddress(
        "0x81D40F21F12A8F0E3252Bccb954D722d4c464B64"
    )

    static let QUOTE_PAY_RECIPIENT: EthAddress = EthAddress(
        "0x7ea8d6119596016935543d90Ee8f5126285060A1"
    )

    public static func chart(
        intent: QuarkIntent,
        folio: Folio
    ) -> Result<Chart, CharterError> {
        let (result, _, _, _, _) = chartExtended(
            intent: intent,
            folio: folio,
            logger: nil
        )

        return result
    }

    /// Extended version that returns debugging information including Tradewinds graph data
    public static func chartExtended(
        intent: QuarkIntent,
        folio: Folio,
        logger: Charter.Logger?
    ) -> (
        result: Result<Chart, CharterError>,
        flowResult: Tradewinds.FlowResult<TradewindsLegendNode, LegendRouteType>?,
        routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]?,
        resources: [Tradewinds.Resource<TradewindsLegendNode>]?,
        target: Tradewinds.Target<TradewindsLegendNode>?
    ) {
        logger?.logValue("Intent", intent)
        let operationsAndActionsResult = constructOperationsAndActionsExtended(
            intent: intent.type,
            folio: folio,
            addMaxAmountBuffers: false,
            blockTimestamp: intent.blockTimestamp,
            logger: logger
        )

        switch operationsAndActionsResult.result {
            case .success(let (quarkOperationActions, steps)):
                logger?.log("Quark Operation Actions: \(String(describing: quarkOperationActions))")
                guard let eip712Data = quarkOperationActions.eip712Data else {
                    return (
                        result: .failure(.error("Failed to construct EIP-712 data")),
                        flowResult: nil,
                        routes: nil,
                        resources: nil,
                        target: nil
                    )
                }
                let chart = Chart(
                    version: version,
                    quarkOperationActions: quarkOperationActions,
                    steps: steps,
                    eip712Data: eip712Data,
                )
                return (
                    result: .success(chart),
                    flowResult: operationsAndActionsResult.flowResult,
                    routes: operationsAndActionsResult.routes,
                    resources: operationsAndActionsResult.resources,
                    target: operationsAndActionsResult.target
                )
            case .failure(let error):
                return (
                    result: .failure(error),
                    flowResult: operationsAndActionsResult.flowResult,
                    routes: operationsAndActionsResult.routes,
                    resources: operationsAndActionsResult.resources,
                    target: operationsAndActionsResult.target
                )
        }
    }

    public static func constructOperationsAndActions(
        intent: QuarkIntent.Type_,
        folio: Folio,
        addMaxAmountBuffers: Bool,
        blockTimestamp: Number,
        logger: Charter.Logger?
    ) -> Result<[Charter.QuarkOperationAction], CharterError> {
        let result = constructOperationsAndActionsExtended(
            intent: intent,
            folio: folio,
            addMaxAmountBuffers: addMaxAmountBuffers,
            blockTimestamp: blockTimestamp,
            logger: logger
        )

        switch result.result {
            case .success(let (quarkOperationActions, _)):
                return .success(quarkOperationActions)
            case .failure(let error):
                return .failure(error)
        }
    }

    public static func maxFlow(
        intent: QuarkIntent.Type_,
        folio: Folio,
        logger: Charter.Logger?
    ) -> Result<Number, Charter.CharterError> {
        maxFlowExtended(intent: intent, folio: folio, logger: logger)
            .map { (_, sinkAmount) in
                sinkAmount
            }
    }

    public static func maxFlowExtended(
        intent: QuarkIntent.Type_,
        folio: Folio,
        logger: Charter.Logger?
    ) -> Result<
        (flows: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>], maxFlow: Number),
        Charter.CharterError
    > {
        let tradewindsInfoResult = intent.maxIntent.tradewindsInfo(
            folio: folio,
            logger: logger
        )

        guard case .success(let (routes, resources, target)) = tradewindsInfoResult else {
            let error: CharterError
            if case .failure(let failureError) = tradewindsInfoResult {
                error = failureError
            } else {
                error = .error("Failed to get tradewinds info")
            }
            return .failure(error)
        }

        return
            Tradewinds.maxFlow(
                routes: routes,
                resources: resources,
                targetNode: target.node,
                costFunction: intent.tradewindsCostFn(resources: resources, target: target)
            )
            .map { (flows, sinkAmount) in (flows: flows, maxFlow: sinkAmount) }
            .mapError { error in .error(String(describing: error)) }
    }

    public static func totalAvailableBalance(
        assetSymbol: String,
        destinationChain: Network,
        folio: Folio,
        actorWallet: EthAddress,
        allowUsingEarningBalances: Bool
    ) -> Number {
        guard let asset = Atlas.getAssetBySymbol(network: destinationChain, symbol: assetSymbol)
        else {
            return Number(0)
        }

        let resourceFactory = TradewindsResourceFactory(
            folio: folio,
            primarySymbol: assetSymbol,
            // TODO: Think about how to properly handle max flows for earning market withdrawals
            // Note: When calculating available balance from earning markets, the result includes
            // MAX_WITHDRAW_BUFFER (1.00001x) applied to max withdrawals. This causes the total to be
            // slightly higher than the sum of individual balances (e.g., 100.0005 instead of 100).
            // This buffer accounts for interest accrual between calculation and execution time.
            earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
            actorWallet: actorWallet,
            network: nil
        )

        let resources: [Tradewinds.Resource<TradewindsLegendNode>]
        switch resourceFactory.createAllResources() {
            case .success(let res):
                resources = res
            case .failure:
                return Number(0)
        }

        let tokenNode = TradewindsLegendNode.tokenBalance(
            network: destinationChain,
            address: asset.assetAddress,
            symbol: assetSymbol,
            wallet: actorWallet
        )

        let allNodes = Array(Set([tokenNode] + resources.map { $0.node }))

        let routes = generateRoutes(
            nodes: allNodes,
            folio: folio,
            userWallets: folio.getRelevantWallets(),
            actorWallet: actorWallet,
            cappedMaxNodes: Set(allNodes),
            logger: nil
        )

        let tokenBalanceNode = TradewindsLegendNode.tokenBalance(
            network: destinationChain,
            address: asset.assetAddress,
            symbol: assetSymbol,
            wallet: actorWallet
        )

        let costFunction: Tradewinds.CostFunction<TradewindsLegendNode, LegendRouteType> =
            Tradewinds.dualFeeCostFunction(targetAmount: Number.MAX_UINT_256)

        let result = Tradewinds.maxFlow(
            routes: routes,
            resources: resources,
            targetNode: tokenBalanceNode,
            costFunction: costFunction
        )

        switch result {
            case .success(let (_, sinkAmount)):
                return sinkAmount
            case .failure:
                return Number(0)
        }
    }

    private static func constructOperationsAndActionsExtended(
        intent: QuarkIntent.Type_,
        folio: Folio,
        addMaxAmountBuffers: Bool,
        blockTimestamp: Number,
        logger: Charter.Logger?
    ) -> (
        result: Result<
            (quarkOperationActions: [Charter.QuarkOperationAction], steps: [Chart.Step]),
            CharterError
        >,
        flowResult: Tradewinds.FlowResult<TradewindsLegendNode, LegendRouteType>?,
        routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]?,
        resources: [Tradewinds.Resource<TradewindsLegendNode>]?,
        target: Tradewinds.Target<TradewindsLegendNode>?
    ) {
        let tradewindsInfoResult = intent.tradewindsInfo(
            folio: folio,
            logger: logger
        )

        guard case .success(let (routes, resources, target)) = tradewindsInfoResult else {
            let error: CharterError
            if case .failure(let failureError) = tradewindsInfoResult {
                error = failureError
            } else {
                error = .error("Failed to get tradewinds info")
            }
            return (
                result: .failure(error),
                flowResult: nil,
                routes: nil,
                resources: nil,
                target: nil
            )
        }

        let tradewindsResult = Tradewinds.flowWithResult(
            routes: routes,
            resources: resources,
            target: target,
            costFunction: intent.tradewindsCostFn(resources: resources, target: target)
        )

        let flowResult: Tradewinds.FlowResult<LegendNode, LegendRouteType>?
        switch tradewindsResult {
            case .success(let flowResult_):
                flowResult = flowResult_
            case .failure(let error):
                // Return failure but include the graph structure for visualization
                return (
                    result: .failure(.error(String(describing: error))),
                    flowResult: nil,
                    routes: routes,
                    resources: resources,
                    target: target
                )
        }

        var quarkOperationActions: [Charter.QuarkOperationAction] = []
        guard let flowResult = flowResult else {
            return (
                result: .failure(.error("No flow result available")),
                flowResult: nil,
                routes: routes,
                resources: resources,
                target: target
            )
        }

        logger?.log("Flow Result: \(String(describing: flowResult))")

        // Aggregate swap hint flows with the same venue into single operations
        let aggregatedFlows = SwapHints.aggregateFlows(flowResult.flows)
        let displayInfo = DisplayInfo.from(intent: intent)

        for flow in aggregatedFlows {
            guard
                let sourceNetwork = flow.route.source.network,
                let sourceWallet = flow.route.source.wallet,
                let nonceSecret = folio.getNonceSecret(
                    network: sourceNetwork,
                    wallet: sourceWallet
                )
            else {
                return (
                    result: .failure(
                        .nonceSecretNotFound(
                            network: flow.route.source.network,
                            account: flow.route.source.wallet
                        )
                    ),
                    flowResult: nil,
                    routes: routes,
                    resources: resources,
                    target: target
                )
            }

            switch flow.getQuarkOperationActions(
                folio: folio,
                nonceSecret: nonceSecret,
                blockTimestamp: blockTimestamp,
                isCappedMax: intent.isMaxIntent,
                displayInfo: displayInfo,
                logger: logger
            )
            {
                case .success(let quarkOperationActionsList):
                    quarkOperationActions.append(contentsOf: quarkOperationActionsList)
                case .failure(let err):
                    return (
                        result: .failure(err),
                        flowResult: flowResult,
                        routes: routes,
                        resources: resources,
                        target: target
                    )
            }
        }

        let mergeResult = Charter.mergeSameChainOperations(
            operationActions: quarkOperationActions
        )

        switch mergeResult {
            case .success((let operations, let actions, let steps)):
                let mergedQuarkOperationActions = zip(operations, actions)
                    .map { (op, act) in
                        QuarkOperationAction(operation: op, action: act)
                    }

                return (
                    result: .success(
                        (quarkOperationActions: mergedQuarkOperationActions, steps: steps)
                    ),
                    flowResult: flowResult,
                    routes: routes,
                    resources: resources,
                    target: target
                )
            case .failure(let error):
                return (
                    result: .failure(error),
                    flowResult: flowResult,
                    routes: routes,
                    resources: resources,
                    target: target
                )
        }
    }

    private static func mergeSameChainOperations(
        operationActions: [QuarkOperationAction]
    ) -> Result<
        (operations: [Chart.QuarkOperation], actions: [Chart.Action], steps: [Chart.Step]),
        CharterError
    > {
        var groupedOperations: [Number: [Chart.QuarkOperation]] = [:]
        var groupedActions: [Number: [Chart.Action]] = [:]
        var chainOrder: [Number] = []
        var allBridgeDestinations: Set<Number> = []

        for operationAction in operationActions {
            let operation = operationAction.operation
            let action = operationAction.action
            if groupedOperations[action.chainId] == nil {
                chainOrder.append(action.chainId)
            }
            groupedOperations[action.chainId, default: []].append(operation)
            groupedActions[action.chainId, default: []].append(action)
            if let bridgeContext = action.actionContext.bridgeActionContext {
                allBridgeDestinations.insert(bridgeContext.destinationChainId)
            }
        }

        var mergedOperations: [Chart.QuarkOperation] = []
        var mergedActions: [Chart.Action] = []

        for chainId in chainOrder {
            let operations = groupedOperations[chainId]!
            let actions = groupedActions[chainId]!

            let chainReceivesBridgeTokens = allBridgeDestinations.contains(chainId)

            let executionType = getExecutionTypeForMergedActions(
                actions: actions,
                chainReceivesBridgeTokens: chainReceivesBridgeTokens
            )

            if operations.count == 1 {
                let operation = operations.first!
                let action = actions.first!
                let updatedAction = Chart.Action(
                    chainId: action.chainId,
                    quarkAccount: action.quarkAccount,
                    actionType: action.actionType,
                    actionContext: action.actionContext,
                    nonceSecret: action.nonceSecret,
                    totalPlays: 1,
                    executionType: executionType
                )

                mergedOperations.append(operation)
                mergedActions.append(updatedAction)
            } else {
                let callContracts = operations.map { $0.scriptAddress }
                let callDatas = operations.map { $0.scriptCalldata }
                let scriptCalldata: Hex
                do {
                    scriptCalldata = try Multicall.runFn.encoded(with: [
                        .array(.address, callContracts.map { .address($0) }),
                        .array(.bytes, callDatas.map { .bytes($0) }),
                    ])
                } catch {
                    return .failure(.error(error.localizedDescription))
                }

                let quarkOperation = Chart.QuarkOperation(
                    nonce: operations.last!.nonce,
                    isReplayable: false,
                    scriptAddress: Create2.getScriptAddress(Multicall.creationCode),
                    scriptSources: [],
                    scriptCalldata: scriptCalldata,
                    expiry: operations.last!.expiry
                )

                let action = Chart.Action(
                    chainId: chainId,
                    quarkAccount: actions.last!.quarkAccount,
                    actionType: ActionContext.MultiActionContext.actionType,
                    actionContext: .multiAction(
                        actions.map { $0.actionContext }
                    ),
                    nonceSecret: actions.last!.nonceSecret,
                    totalPlays: 1,
                    executionType: executionType
                )

                mergedOperations.append(quarkOperation)
                mergedActions.append(action)
            }
        }

        // Order operations: IMMEDIATE first, then CONTINGENT
        // Within IMMEDIATE operations, sort by chainId for deterministic ordering (safe since they're independent)
        // CONTINGENT operations preserve topological order (they may have dependencies on each other)
        let zipped = Array(zip(mergedOperations, mergedActions))
        let immediateOps = zipped.filter { $0.1.executionType.isImmediate }
            .sorted { $0.1.chainId < $1.1.chainId }
        let contingentOps = zipped.filter { !$0.1.executionType.isImmediate }
        let sorted = immediateOps + contingentOps

        let sortedOperations = sorted.map { $0.0 }
        let sortedActions = sorted.map { $0.1 }

        // Generate steps from the sorted operations/actions
        let steps = generateSteps(actions: sortedActions)

        return .success(
            (
                operations: sortedOperations,
                actions: sortedActions,
                steps: steps
            )
        )
    }

    private static func getExecutionTypeForMergedActions(
        actions: [Chart.Action],
        chainReceivesBridgeTokens: Bool
    ) -> Chart.Action.ExecutionType {
        if chainReceivesBridgeTokens {
            return .contingent
        }
        return actions.last!.executionType
    }

    /// Generates steps from sorted operations/actions.
    ///
    /// For each operation (index `i`):
    /// - Creates a `quark_operation` step with `operationIndex: i`
    /// - Extracts expected actions from the action's context
    /// - For IMMEDIATE operations: `dependsOn: []`
    ///
    /// For each bridge action found in a step:
    /// - Creates an `exogenous` step for the bridge receive
    /// - `dependsOn` references the step that sends the bridge
    ///
    /// For each CONTINGENT quark_operation step:
    /// - Sets `dependsOn` to the exogenous step index(es) for its chain
    static func generateSteps(
        actions: [Chart.Action]
    ) -> [Chart.Step] {
        var steps: [Chart.Step] = []
        // Maps destination chainId -> exogenous step indices for bridge receives
        var exogenousStepIndicesByChain: [Number: [Int]] = [:]

        for (operationIndex, action) in actions.enumerated() {
            // Extract expected actions from the action context
            let expectedActions = extractExpectedActions(from: action)

            // Create quark_operation step (dependsOn filled in second pass for CONTINGENT)
            let qoStep = Chart.Step.QuarkOperationStep(
                chainId: action.chainId,
                operationIndex: operationIndex,
                expectedActions: expectedActions,
                dependsOn: []  // placeholder, filled below for CONTINGENT
            )
            let qoStepIndex = steps.count
            steps.append(.quarkOperation(qoStep))

            // For each bridge action, create an exogenous step
            let bridgeContexts = extractBridgeContexts(from: action.actionContext)
            for bridgeContext in bridgeContexts {
                let bridgeReceiveExpectedAction = Chart.ExpectedAction(
                    actionType: Charter.ActionContext.BridgeMintActionContext.actionType,
                    actionContext: .bridgeMint(
                        Charter.ActionContext.BridgeMintActionContext(
                            assetSymbol: bridgeContext.destinationAssetSymbol,
                            bridgeType: bridgeContext.bridgeType,
                            chainId: bridgeContext.destinationChainId,
                            sourceChainId: bridgeContext.chainId,
                            inputAmount: bridgeContext.inputAmount,
                            outputAmount: bridgeContext.outputAmount,
                            maxFee: bridgeContext.inputAmount - bridgeContext.outputAmount,
                            recipient: bridgeContext.recipient,
                            token: bridgeContext.token
                        )
                    )
                )

                let exoStep = Chart.Step.ExogenousStep(
                    chainId: bridgeContext.destinationChainId,
                    executionType: .bridgeReceive,
                    expectedActions: [bridgeReceiveExpectedAction],
                    dependsOn: [qoStepIndex]
                )
                let exoStepIndex = steps.count
                steps.append(.exogenous(exoStep))
                exogenousStepIndicesByChain[bridgeContext.destinationChainId, default: []]
                    .append(exoStepIndex)
            }
        }

        // Second pass: wire dependsOn for quark_operation steps that have
        // exogenous dependencies on their chain (e.g. bridge receives).
        // dependsOn is the source of truth for ordering — executionType is not
        // consulted here. An empty dependsOn means the step fires immediately.
        steps = steps.enumerated()
            .map { (index, step) in
                switch step {
                    case .quarkOperation(let qoStep):
                        if let exoIndices = exogenousStepIndicesByChain[qoStep.chainId],
                            !exoIndices.isEmpty
                        {
                            return .quarkOperation(
                                Chart.Step.QuarkOperationStep(
                                    chainId: qoStep.chainId,
                                    operationIndex: qoStep.operationIndex,
                                    expectedActions: qoStep.expectedActions,
                                    dependsOn: qoStep.dependsOn + exoIndices
                                )
                            )
                        }
                        return step
                    case .exogenous:
                        return step
                }
            }

        return steps
    }

    /// Extracts expected actions from a Chart.Action.
    /// For MULTI_ACTION, each sub-context becomes a separate expected action.
    static func extractExpectedActions(
        from action: Chart.Action
    ) -> [Chart.ExpectedAction] {
        switch action.actionContext {
            case .multiAction(let contexts):
                return contexts.map { context in
                    Chart.ExpectedAction(
                        actionType: context.actionType,
                        actionContext: context
                    )
                }
            default:
                return [
                    Chart.ExpectedAction(
                        actionType: action.actionType,
                        actionContext: action.actionContext
                    )
                ]
        }
    }

    /// Extracts all bridge action contexts from an action context (handles multiAction).
    static func extractBridgeContexts(
        from actionContext: Charter.ActionContext
    ) -> [Charter.ActionContext.BridgeActionContext] {
        switch actionContext {
            case .bridge(let bridgeContext):
                return [bridgeContext]
            case .multiAction(let contexts):
                return contexts.compactMap { context in
                    if case .bridge(let bridgeContext) = context {
                        return bridgeContext
                    }
                    return nil
                }
            default:
                return []
        }
    }
}
