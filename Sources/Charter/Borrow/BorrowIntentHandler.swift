import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

// MARK: - BorrowIntentHandler Protocol

protocol BorrowIntentHandler {
    associatedtype BorrowIntent

    func getBorrower(from intent: BorrowIntent) -> EthAddress
    func getBorrowAmount(from intent: BorrowIntent) -> Number
    func getBorrowAssetSymbol(from intent: BorrowIntent) -> String
    func getCollateralAmount(from intent: BorrowIntent) -> Number?
    func getCollateralAssetSymbol(from intent: BorrowIntent) -> String?
    func getChainId(from intent: BorrowIntent) -> Number
    func getIsCappedMaxSupply(from intent: BorrowIntent) -> Bool
    func getIsMaxBorrow(from intent: BorrowIntent) -> Bool

    func createCollateralNode(
        network: Network,
        collateralAsset: EthAddress,
        wallet: EthAddress,
        intent: BorrowIntent
    ) -> TradewindsLegendNode

    func createBorrowRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        borrowAmount: Number,
        borrowAsset: EthAddress
    ) -> LegendRouteType

    func createSupplyCollateralRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode
    ) -> LegendRouteType

    func createSupplyAndBorrowRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        borrowAmount: Number,
        borrowAsset: EthAddress,
        isCappedMaxSupply: Bool
    ) -> LegendRouteType

    func queryExistingCollateral(
        intent: BorrowIntent,
        borrower: EthAddress,
        folio: Folio
    ) -> [Tradewinds.Resource<TradewindsLegendNode>]

    func queryBorrowCapacity(
        intent: BorrowIntent,
        borrower: EthAddress,
        borrowAsset: EthAddress,
        folio: Folio
    ) -> Result<Tradewinds.Resource<TradewindsLegendNode>, Charter.CharterError>

    func validateIntent(_ intent: BorrowIntent, folio: Folio) -> Bool

    func handle(
        _ intent: BorrowIntent,
        folio: Folio,
        earnMarketPolicy: EarnMarketPolicy,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    >
}

// MARK: - Shared Constants

/// A multiplier applied to the calculated borrow capacity to prevent users from borrowing
/// at the exact liquidation limit, which would risk instant liquidation due to price fluctuations
/// or accrued interest.
///
/// Example: If collateral allows borrowing up to 100 USDC at the liquidation threshold,
/// applying the 98% safety cap limits the actual borrowable amount to 98 USDC.
let borrowCapacitySafetyCap = Percentage("980000000000000000")

private enum BorrowScenario {
    case justBorrow
    case supplyCollateralOnly
    case supplyCollateralAndBorrow
}

private struct CollateralInfo {
    let symbol: String
    let address: EthAddress
    let amount: Number
}

// MARK: - BorrowIntentHandler Extension

extension BorrowIntentHandler {

    // MARK: - Public Methods

    // Default validation - can be overridden by concrete implementations
    func validateIntent(_ intent: BorrowIntent, folio: Folio) -> Bool {
        let network = Network.fromChainId(getChainId(from: intent))
        guard
            Atlas.getAssetBySymbol(network: network, symbol: getBorrowAssetSymbol(from: intent))
                != nil
        else {
            return false
        }
        return true
    }

    func handle(
        _ intent: BorrowIntent,
        folio: Folio,
        earnMarketPolicy: EarnMarketPolicy,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        // Validation
        guard validateIntent(intent, folio: folio) else {
            return .failure(.error("Borrow intent validation failed"))
        }

        let network = Network.fromChainId(getChainId(from: intent))
        let scenario = determineBorrowScenario(intent)

        // Max borrow is only supported for standalone borrows (existing collateral).
        // For supply+borrow, Tradewinds targets collateral so we can't calculate exact borrow amount.
        if scenario == .supplyCollateralAndBorrow && getBorrowAmount(from: intent).isMaxUint256 {
            return .failure(
                .error(
                    "Max borrow is not supported in supply+borrow flow. Please specify an exact borrow amount."
                )
            )
        }

        switch scenario {
            case .justBorrow:
                return handleJustBorrow(
                    intent: intent,
                    network: network,
                    folio: folio,
                    logger: logger
                )

            case .supplyCollateralOnly:
                return handleSupplyCollateralOnly(
                    intent: intent,
                    network: network,
                    folio: folio,
                    earnMarketPolicy: earnMarketPolicy,
                    logger: logger
                )

            case .supplyCollateralAndBorrow:
                return handleSupplyCollateralAndBorrow(
                    intent: intent,
                    network: network,
                    folio: folio,
                    earnMarketPolicy: earnMarketPolicy,
                    logger: logger
                )
        }
    }

    // MARK: - Private Helpers

    private func determineBorrowScenario(_ intent: BorrowIntent) -> BorrowScenario {
        let hasBorrowAmount = getBorrowAmount(from: intent) > Number(0)
        let hasCollateral = (getCollateralAmount(from: intent) ?? Number(0)) > Number(0)

        if hasBorrowAmount && !hasCollateral {
            return .justBorrow
        } else if !hasBorrowAmount && hasCollateral {
            return .supplyCollateralOnly
        } else if hasBorrowAmount && hasCollateral {
            return .supplyCollateralAndBorrow
        } else {
            return .supplyCollateralOnly
        }
    }

    private func extractCollateralInfo(
        _ intent: BorrowIntent,
        network: Network,
        folio: Folio
    ) -> CollateralInfo? {
        guard let collateralAmount = getCollateralAmount(from: intent), collateralAmount > Number(0)
        else {
            return nil
        }

        guard let symbol = getCollateralAssetSymbol(from: intent),
            let collateralAmount = getCollateralAmount(from: intent)
        else {
            return nil
        }
        let actualSymbol = getWrappedAssetSymbol(symbol, folio: folio, network: network)

        guard let asset = Atlas.getAssetBySymbol(network: network, symbol: actualSymbol) else {
            return nil
        }

        return CollateralInfo(
            symbol: symbol,
            address: asset.assetAddress,
            amount: collateralAmount
        )
    }

    private func getWrappedAssetSymbol(_ symbol: String, folio: Folio, network: Network)
        -> String
    {
        for (type, _) in folio.swapHints {
            if case .wrapper(
                let underlyingNetwork,
                let underlyingSymbol,
                let wrappedNetwork,
                let wrappedSymbol
            ) = type,
                underlyingNetwork == network && underlyingSymbol.equalIgnoringCase(symbol)
                    && wrappedNetwork == network
            {
                return wrappedSymbol
            }
        }
        return symbol
    }

    private func createCollateralResources(
        symbol: String,
        folio: Folio,
        actorWallet: ChainAddress,
        earnMarketPolicy: EarnMarketPolicy
    ) -> Result<[Tradewinds.Resource<TradewindsLegendNode>], Charter.CharterError> {
        let factory = TradewindsResourceFactory(
            folio: folio,
            primarySymbol: symbol,
            earnMarketPolicy: earnMarketPolicy,
            actorWallet: actorWallet,
            network: nil
        )

        return factory.createAllResources()
    }

    // MARK: - Scenario Handlers

    private func handleJustBorrow(
        intent: BorrowIntent,
        network: Network,
        folio: Folio,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        let borrowSymbol = getBorrowAssetSymbol(from: intent)
        guard let borrowAsset = Atlas.getAssetBySymbol(network: network, symbol: borrowSymbol)
        else {
            return .failure(.unknownAsset(symbol: borrowSymbol, network: network, address: nil))
        }

        let borrower = getBorrower(from: intent)
        let borrowAmount = getBorrowAmount(from: intent)

        let borrowCapacityResource: Tradewinds.Resource<TradewindsLegendNode>
        switch queryBorrowCapacity(
            intent: intent,
            borrower: borrower,
            borrowAsset: borrowAsset.assetAddress,
            folio: folio
        ) {
        case .success(let resource):
            borrowCapacityResource = resource
        case .failure(let error):
            return .failure(error)
        }

        let targetNode = TradewindsLegendNode.tokenBalance(
            network: network,
            address: borrowAsset.assetAddress.on(network),
            symbol: borrowAsset.symbol,
            wallet: borrower.on(network)
        )

        let isMaxBorrow = getIsMaxBorrow(from: intent)
        let borrowRoute = makeLegendRoute(
            type: createBorrowRoute(
                from: borrowCapacityResource.node,
                to: targetNode,
                borrowAmount: borrowAmount,
                borrowAsset: borrowAsset.assetAddress
            ),
            source: borrowCapacityResource.node,
            sink: targetNode,
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256,
            folio: folio
        )

        return .success(
            (
                [borrowRoute],
                [borrowCapacityResource],
                Tradewinds.Target(
                    amount: isMaxBorrow ? .max : .exact(borrowAmount),
                    node: targetNode
                )
            )
        )
    }

    private func handleSupplyCollateralOnly(
        intent: BorrowIntent,
        network: Network,
        folio: Folio,
        earnMarketPolicy: EarnMarketPolicy,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        guard
            let collateralInfo = extractCollateralInfo(
                intent,
                network: network,
                folio: folio
            )
        else {
            return .failure(.error("Failed to extract collateral info for borrow intent"))
        }

        let borrower = getBorrower(from: intent)
        let resources: [Tradewinds.Resource<TradewindsLegendNode>]
        switch createCollateralResources(
            symbol: collateralInfo.symbol,
            folio: folio,
            actorWallet: borrower.on(network),
            earnMarketPolicy: earnMarketPolicy
        ) {
            case .success(let res):
                resources = res
            case .failure(let error):
                return .failure(error)
        }

        let targetNode = createCollateralNode(
            network: network,
            collateralAsset: collateralInfo.address,
            wallet: borrower,
            intent: intent
        )

        let routes = generateStandardRoutes(
            intent: intent,
            resources: resources,
            targetNode: targetNode,
            folio: folio,
            actorWallet: borrower.on(network),
            logger: logger
        )

        return .success(
            (
                routes,
                resources,
                Tradewinds.Target(
                    amount: collateralInfo.amount.isMaxUint256
                        ? .max : .exact(collateralInfo.amount),
                    node: targetNode
                )
            )
        )
    }

    private func handleSupplyCollateralAndBorrow(
        intent: BorrowIntent,
        network: Network,
        folio: Folio,
        earnMarketPolicy: EarnMarketPolicy,
        logger: Charter.Logger?
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        guard
            let collateralInfo = extractCollateralInfo(
                intent,
                network: network,
                folio: folio
            ),
            let borrowAsset = Atlas.getAssetBySymbol(
                network: network,
                symbol: getBorrowAssetSymbol(from: intent)
            )
        else {
            return .failure(
                .unknownAsset(
                    symbol: getBorrowAssetSymbol(from: intent),
                    network: network,
                    address: nil
                )
            )
        }

        let borrower = getBorrower(from: intent)
        let resources: [Tradewinds.Resource<TradewindsLegendNode>]
        switch createCollateralResources(
            symbol: collateralInfo.symbol,
            folio: folio,
            actorWallet: borrower.on(network),
            earnMarketPolicy: earnMarketPolicy
        ) {
            case .success(let res):
                resources = res
            case .failure(let error):
                return .failure(error)
        }

        let targetNode = createCollateralNode(
            network: network,
            collateralAsset: collateralInfo.address,
            wallet: borrower,
            intent: intent
        )

        let routes = generateStandardRoutes(
            intent: intent,
            resources: resources,
            targetNode: targetNode,
            folio: folio,
            actorWallet: borrower.on(network),
            logger: logger
        )

        let transformedRoutes = transformSupplyRoutesToSupplyAndBorrow(
            routes: routes,
            targetNode: targetNode,
            borrowAsset: borrowAsset.assetAddress,
            borrowAmount: getBorrowAmount(from: intent),
            folio: folio
        )

        return .success(
            (
                transformedRoutes,
                resources,
                Tradewinds.Target(
                    amount: collateralInfo.amount.isMaxUint256
                        ? .max : .exact(collateralInfo.amount),
                    node: targetNode
                )
            )
        )
    }

    // MARK: - Route Generation Helpers

    private func generateStandardRoutes(
        intent: BorrowIntent,
        resources: [Tradewinds.Resource<TradewindsLegendNode>],
        targetNode: TradewindsLegendNode,
        folio: Folio,
        actorWallet: ChainAddress,
        logger: Charter.Logger?
    ) -> [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] {
        let allNodes = Array(Set([targetNode] + resources.map { $0.node }))
        let userWallets = extractUserWallets(from: resources)
        let isCappedMaxSupply = getIsCappedMaxSupply(from: intent)

        return generateRoutes(
            nodes: allNodes,
            folio: folio,
            userWallets: userWallets,
            actorWallet: actorWallet,
            cappedMaxNodes: isCappedMaxSupply ? Set(allNodes) : Set(),
            logger: logger
        )
    }

    private func transformSupplyRoutesToSupplyAndBorrow(
        routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
        targetNode: TradewindsLegendNode,
        borrowAsset: EthAddress,
        borrowAmount: Number,
        folio: Folio
    ) -> [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] {
        routes.map { route in
            if route.sink == targetNode {
                // Check if this is a supply collateral route and preserve isCappedMax
                switch route.type {
                    case .cometSupplyCollateral(let isCappedMaxSupply),
                        .morphoSupplyCollateral(let isCappedMaxSupply):
                        let routeType = createSupplyAndBorrowRoute(
                            from: route.source,
                            to: route.sink,
                            borrowAmount: borrowAmount,
                            borrowAsset: borrowAsset,
                            isCappedMaxSupply: isCappedMaxSupply
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

    private func extractUserWallets(from resources: [Tradewinds.Resource<TradewindsLegendNode>])
        -> Set<ChainAddress>
    {
        Set(
            resources.compactMap { resource -> ChainAddress? in
                switch resource.node {
                    case .tokenBalance(_, _, _, let wallet):
                        return wallet
                    case .cometSupplyBalance(let network, _, _, let wallet),
                        .cometCollateralBalance(let network, _, _, let wallet),
                        .morphoCollateralBalance(let network, _, _, let wallet),
                        .morphoVaultSupplyBalance(let network, _, _, let wallet),
                        .aaveSupplyBalance(let network, _, _, let wallet):
                        return wallet.on(network)
                    default:
                        return nil
                }
            }
        )
    }
}
