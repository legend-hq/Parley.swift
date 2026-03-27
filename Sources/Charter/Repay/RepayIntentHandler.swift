import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

// MARK: - RepayIntentHandler Protocol

protocol RepayIntentHandler {
    associatedtype RepayIntent

    // MARK: - Core Intent Accessors

    func getRepayer(from intent: RepayIntent) -> EthAddress
    func getRepayAmount(from intent: RepayIntent) -> Number
    func getRepayAssetSymbol(from intent: RepayIntent) -> String
    func getChainId(from intent: RepayIntent) -> Number
    func getIsMaxIntent(from intent: RepayIntent) -> Bool

    // MARK: - Collateral Withdrawal Accessors

    func getCollateralAmounts(from intent: RepayIntent) -> [Number]
    func getCollateralAssetSymbols(from intent: RepayIntent) -> [String]

    // MARK: - Node Creation

    func createBorrowPositionNode(
        network: Network,
        borrowAsset: EthAddress,
        wallet: EthAddress,
        intent: RepayIntent
    ) -> TradewindsLegendNode

    func createCollateralNode(
        network: Network,
        collateralAsset: EthAddress,
        wallet: EthAddress,
        intent: RepayIntent
    ) -> TradewindsLegendNode

    // MARK: - Route Creation

    func createRepayRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        isMax: Bool
    ) -> LegendRouteType

    func createWithdrawCollateralRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        isMax: Bool
    ) -> LegendRouteType

    // MARK: - Position Queries

    func queryExistingDebt(
        intent: RepayIntent,
        repayer: EthAddress,
        folio: Folio
    ) -> Number

    func queryExistingCollateral(
        intent: RepayIntent,
        repayer: EthAddress,
        folio: Folio
    ) -> [Tradewinds.Resource<TradewindsLegendNode>]

    // MARK: - Validation

    func validateIntent(_ intent: RepayIntent, folio: Folio) -> Result<Void, Charter.CharterError>
}

// MARK: - Repay Scenario

enum RepayScenario {
    case repayOnly
    case withdrawCollateralOnly
    case repayAndWithdrawCollateral
}

// MARK: - Common Implementation

extension RepayIntentHandler {

    func determineScenario(intent: RepayIntent) -> RepayScenario {
        let hasRepayAmount = getRepayAmount(from: intent) > Number(0)
        let collateralAmounts = getCollateralAmounts(from: intent)
        let hasCollateral =
            !collateralAmounts.isEmpty && collateralAmounts.contains { $0 > Number(0) }

        if hasRepayAmount && !hasCollateral {
            return .repayOnly
        } else if !hasRepayAmount && hasCollateral {
            return .withdrawCollateralOnly
        } else if hasRepayAmount && hasCollateral {
            return .repayAndWithdrawCollateral
        } else {
            // Edge case: no repay and no collateral - treat as repay only with 0 amount
            return .repayOnly
        }
    }

    func handle(
        _ intent: RepayIntent,
        folio: Folio,
        allowUsingEarningBalances: Bool,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        switch validateIntent(intent, folio: folio) {
            case .failure(let error):
                return .failure(error)
            case .success:
                break  // Continue with the handler logic
        }

        let network = Network.fromChainId(getChainId(from: intent))
        let scenario = determineScenario(intent: intent)

        switch scenario {
            case .repayOnly:
                return handleRepayOnly(
                    intent: intent,
                    network: network,
                    folio: folio,
                    allowUsingEarningBalances: allowUsingEarningBalances,
                    logger: logger
                )

            case .withdrawCollateralOnly:
                return handleWithdrawCollateralOnly(
                    intent: intent,
                    network: network,
                    folio: folio
                )

            case .repayAndWithdrawCollateral:
                return handleRepayAndWithdrawCollateral(
                    intent: intent,
                    network: network,
                    folio: folio,
                    allowUsingEarningBalances: allowUsingEarningBalances,
                    logger: logger
                )
        }
    }

    // MARK: - Scenario Handlers

    func handleRepayOnly(
        intent: RepayIntent,
        network: Network,
        folio: Folio,
        allowUsingEarningBalances: Bool,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        let repayer = getRepayer(from: intent)
        let repayAmount = getRepayAmount(from: intent)
        let assetSymbol = getRepayAssetSymbol(from: intent)

        guard let borrowAsset = Atlas.getEvmAssetBySymbol(network: network, symbol: assetSymbol) else {
            return .failure(.unknownAsset(symbol: assetSymbol, network: network, address: nil))
        }

        // Create resources from available balances (can be from any network for bridging)
        let resourceFactory = TradewindsResourceFactory(
            folio: folio,
            primarySymbol: assetSymbol,
            earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
            actorWallet: repayer,
            network: nil  // Allow resources from any network for bridging
        )
        let resources: [Tradewinds.Resource<TradewindsLegendNode>]
        switch resourceFactory.createAllResources() {
            case .success(let res):
                resources = res
            case .failure(let error):
                logger?.log("Failed to create resources: \(error)")
                return .failure(error)
        }
        // Create the borrow position node as sink
        let borrowPositionNode = createBorrowPositionNode(
            network: network,
            borrowAsset: borrowAsset.assetAddress,
            wallet: repayer,
            intent: intent
        )

        // Create token balance node on target network
        let tokenNode = TradewindsLegendNode.tokenBalance(
            network: network,
            address: borrowAsset.assetAddress,
            symbol: assetSymbol,
            wallet: repayer
        )

        // Get all unique nodes (don't include borrowPositionNode in generateRoutes)
        let allNodes = Array(Set([tokenNode] + resources.map { $0.node }))

        // Generate routes including bridges and other conversions
        let isMax = getIsMaxIntent(from: intent)
        var routes = generateRoutes(
            nodes: allNodes,
            folio: folio,
            userWallets: folio.getRelevantWallets(),
            actorWallet: repayer,
            cappedMaxNodes: isMax ? Set(allNodes) : Set(),
            logger: logger
        )

        // Determine if we should use "true max" (uint256.max) or calculated amount
        // We can only use uint256.max if the user has enough funds to cover the full debt
        let effectiveIsMax: Bool
        let routeMaxFlow: Number
        
        if isMax {
            let existingDebt = queryExistingDebt(
                intent: intent,
                repayer: repayer,
                folio: folio
            )
            
            // Calculate max available balance that can reach destination chain
            // This accounts for bridge costs and source chain fees
            let maxAvailable = Charter.totalAvailableBalance(
                assetSymbol: assetSymbol,
                destinationChain: network,
                folio: folio,
                actorWallet: repayer,
                allowUsingEarningBalances: allowUsingEarningBalances
            )
            
            // Get quote fee for the repay operation
            let quoteFee = folio.quoteCost(
                routeType: createRepayRoute(from: tokenNode, to: borrowPositionNode, isMax: true),
                symbol: assetSymbol,
                network: network
            ) ?? Number(0)
            
            // Apply buffer to account for interest accrual between construction and execution
            let bufferedDebt = existingDebt * Charter.MAX_REPAY_BUFFER
            let totalRequired = Number(bufferedDebt) + quoteFee
            
            // Only use "true max" (uint256.max) if user can afford the full debt
            // Otherwise, use calculated partial amount to avoid revert
            effectiveIsMax = maxAvailable >= totalRequired
            
            // Cap route maxFlow to prevent over-repaying
            routeMaxFlow = totalRequired
        } else {
            effectiveIsMax = false
            routeMaxFlow = Number.MAX_UINT_256
        }
        
        // Create the repay route with the determined isMax flag
        let repayRouteType = createRepayRoute(
            from: tokenNode,
            to: borrowPositionNode,
            isMax: effectiveIsMax
        )
        
        // Add the repay route from token to borrow position
        routes.append(
            makeLegendRoute(
                type: repayRouteType,
                source: tokenNode,
                sink: borrowPositionNode,
                rate: .oneHundred,
                minFlow: Number(0),
                maxFlow: routeMaxFlow,
                folio: folio
            )
        )

        // Set up target
        // For max repay: use .max target to repay as much as possible
        // The route's maxFlow constraint ensures we don't repay more than the debt
        let target: Tradewinds.Target<TradewindsLegendNode>
        if isMax {
            target = Tradewinds.Target(
                amount: .max,
                node: borrowPositionNode
            )
        } else {
            target = Tradewinds.Target(
                amount: .exact(repayAmount),
                node: borrowPositionNode
            )
        }

        return .success((routes, resources, target))
    }

    func handleWithdrawCollateralOnly(
        intent: RepayIntent,
        network: Network,
        folio: Folio
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        let repayer = getRepayer(from: intent)
        let collateralSymbols = getCollateralAssetSymbols(from: intent)
        let collateralAmounts = getCollateralAmounts(from: intent)

        guard !collateralSymbols.isEmpty,
            let collateralSymbol = collateralSymbols.first,
            let collateralAmount = collateralAmounts.first,
            let collateralAsset = Atlas.getEvmAssetBySymbol(network: network, symbol: collateralSymbol)
        else {
            return .failure(.error("Missing or invalid collateral information for withdrawal"))
        }

        // Query existing collateral positions as resources
        let resources = queryExistingCollateral(intent: intent, repayer: repayer, folio: folio)

        guard !resources.isEmpty else {
            return .failure(.error("No existing collateral positions found to withdraw"))
        }

        // Create withdrawal route
        let collateralNode = createCollateralNode(
            network: network,
            collateralAsset: collateralAsset.assetAddress,
            wallet: repayer,
            intent: intent
        )

        let tokenNode = TradewindsLegendNode.tokenBalance(
            network: network,
            address: collateralAsset.assetAddress,
            symbol: collateralSymbol,
            wallet: repayer
        )

        // Determine if this is a max withdrawal based on the collateral amount
        let isMax = collateralAmount == Number.MAX_UINT_256
        let routes = [
            makeLegendRoute(
                type: createWithdrawCollateralRoute(
                    from: collateralNode,
                    to: tokenNode,
                    isMax: isMax
                ),
                source: collateralNode,
                sink: tokenNode,
                rate: .oneHundred,
                minFlow: Number(0),
                maxFlow: Number.MAX_UINT_256,
                folio: folio
            )
        ]

        guard routes.contains(where: { route in
            route.sink == tokenNode && route.source == collateralNode && {
                switch route.type {
                    case .cometWithdrawCollateral(_), .morphoWithdrawCollateral(_):
                        return true
                    default:
                        return false
                }
            }()
        }) else {
            return .failure(
                .routeNotFound(
                    symbol: collateralSymbol,
                    routeType: LegendRouteType.cometWithdrawCollateral(isMax: isMax).identifier
                )
            )
        }

        let targetAmount: Tradewinds.FlowAmount
        if collateralAmount == Number.MAX_UINT_256 {
            targetAmount = .max
        } else {
            targetAmount = .exact(collateralAmount)
        }

        // Set up target
        let target = Tradewinds.Target(
            amount: targetAmount,
            node: tokenNode
        )

        return .success((routes, resources, target))
    }

    // Helper function to create repay resources (similar to createCollateralResources in BorrowHandler)
    private func createRepayResources(
        symbol: String,
        folio: Folio,
        actorWallet: EthAddress,
        allowUsingEarningBalances: Bool
    ) -> Result<[Tradewinds.Resource<TradewindsLegendNode>], Charter.CharterError> {
        let resourceFactory = TradewindsResourceFactory(
            folio: folio,
            primarySymbol: symbol,
            earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
            actorWallet: actorWallet,
            network: nil  // Allow resources from any network for bridging
        )
        return resourceFactory.createAllResources()
    }

    // Helper function for standard route generation
    private func generateStandardRoutes(
        intent: RepayIntent,
        resources: [Tradewinds.Resource<TradewindsLegendNode>],
        targetNode: TradewindsLegendNode,
        folio: Folio,
        actorWallet: EthAddress,
        logger: Charter.Logger?
    ) -> [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] {
        let allNodes = Array(Set([targetNode] + resources.map { $0.node }))
        let userWallets = Set(resources.compactMap { $0.node.wallet })
        let isMax = getIsMaxIntent(from: intent)
        return generateRoutes(
            nodes: allNodes,
            folio: folio,
            userWallets: userWallets,
            actorWallet: actorWallet,
            cappedMaxNodes: isMax ? Set(allNodes) : Set(),
            logger: logger
        )
    }

    // Transform function to convert repay routes to repay+withdraw (following BorrowHandler pattern)
    private func transformRepayRoutesToRepayAndWithdraw(
        routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
        targetNode: TradewindsLegendNode,
        collateralAsset: EthAddress,
        collateralAmount: Number,
        folio: Folio
    ) -> [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] {
        routes.map { route in
            if route.sink == targetNode {
                // Check if this is a repay route
                switch route.type {
                    case .cometRepay(let isMaxRepay):
                        // Transform to combined repay+withdraw for Comet
                        let routeType = LegendRouteType.cometRepayAndWithdrawCollateral(
                            collateralAsset: collateralAsset,
                            collateralAmount: collateralAmount,
                            isMaxRepay: isMaxRepay
                        )
                        return makeLegendRoute(
                            type: routeType,
                            source: route.source,
                            sink: route.sink,
                            rate: route.rate,
                            minFlow: route.minFlow,
                            maxFlow: route.maxFlow,
                            folio: folio
                        )
                    case .morphoRepay(let isMaxRepay):
                        // Transform to combined repay+withdraw for Morpho
                        let routeType = LegendRouteType.morphoRepayAndWithdrawCollateral(
                            collateralAsset: collateralAsset,
                            collateralAmount: collateralAmount,
                            isMaxRepay: isMaxRepay
                        )
                        return makeLegendRoute(
                            type: routeType,
                            source: route.source,
                            sink: route.sink,
                            rate: route.rate,
                            minFlow: route.minFlow,
                            maxFlow: route.maxFlow,
                            folio: folio
                        )
                    default:
                        return route
                }
            }
            return route
        }
    }

    func handleRepayAndWithdrawCollateral(
        intent: RepayIntent,
        network: Network,
        folio: Folio,
        allowUsingEarningBalances: Bool,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        // Following the BorrowHandler pattern exactly
        let repayer = getRepayer(from: intent)
        let repayAmount = getRepayAmount(from: intent)
        let assetSymbol = getRepayAssetSymbol(from: intent)
        let collateralSymbols = getCollateralAssetSymbols(from: intent)
        let collateralAmounts = getCollateralAmounts(from: intent)

        guard let borrowAsset = Atlas.getEvmAssetBySymbol(network: network, symbol: assetSymbol),
            !collateralSymbols.isEmpty,
            let collateralSymbol = collateralSymbols.first,
            let collateralAsset = Atlas.getEvmAssetBySymbol(network: network, symbol: collateralSymbol)
        else {
            return .failure(.error("Missing or invalid assets for repay and collateral withdrawal"))
        }

        let collateralAmount = collateralAmounts.first ?? Number.MAX_UINT_256

        // Step 1: Create resources for repay asset only (not collateral)
        let resources: [Tradewinds.Resource<TradewindsLegendNode>]
        switch createRepayResources(
            symbol: assetSymbol,
            folio: folio,
            actorWallet: repayer,
            allowUsingEarningBalances: allowUsingEarningBalances
        ) {
            case .success(let res):
                resources = res
            case .failure(let error):
                return .failure(error)
        }

        // Step 2: Create target node (borrow position)
        let targetNode = createBorrowPositionNode(
            network: network,
            borrowAsset: borrowAsset.assetAddress,
            wallet: repayer,
            intent: intent
        )

        // Step 3: Generate standard routes
        let routes = generateStandardRoutes(
            intent: intent,
            resources: resources,
            targetNode: targetNode,
            folio: folio,
            actorWallet: repayer,
            logger: logger
        )

        // Step 4: Transform repay routes to repay+withdraw
        let transformedRoutes = transformRepayRoutesToRepayAndWithdraw(
            routes: routes,
            targetNode: targetNode,
            collateralAsset: collateralAsset.assetAddress,
            collateralAmount: collateralAmount,
            folio: folio
        )

        // Step 5: Set up target
        let target = Tradewinds.Target(
            amount: repayAmount == Number.MAX_UINT_256 ? .max : .exact(repayAmount),
            node: targetNode
        )

        return .success((transformedRoutes, resources, target))
    }

}
