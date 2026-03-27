import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

internal func generateRoute(
    sourceNode: TradewindsLegendNode,
    sinkNode: TradewindsLegendNode,
    folio: Folio,
    userWallets: Set<EthAddress>,
    actorWallet: EthAddress,
    cappedMaxNodes: Set<TradewindsLegendNode>,
    exactWithdrawalAmounts: [EthAddress: Number] = [:],  // Maps market address to exact withdrawal amount
    logger: Charter.Logger?
) -> [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] {
    let maxFlow = Number.MAX_UINT_256

    // Handle routes between different node types
    switch (sourceNode, sinkNode) {
        case (
            .tokenBalance(let sourceNetwork, let sourceAddress, let sourceSymbol, let sourceWallet),
            .tokenBalance(let sinkNetwork, let sinkAddress, let sinkSymbol, let sinkWallet)
        )
        where sourceNetwork == sinkNetwork && sourceAddress != sinkAddress
            && sourceWallet == sinkWallet:
            // Case 1: Same-chain, different assets (potential wrap/unwrap)

            if let wrapQuoteRate = folio.getWrapQuote(
                underlyingNetwork: sourceNetwork,
                underlyingSymbol: sourceSymbol,
                wrappedNetwork: sinkNetwork,
                wrappedSymbol: sinkSymbol
            ),
                !wrapQuoteRate.isZero
            {
                return [makeLegendRoute(
                    type: .wrap,
                    source: sourceNode,
                    sink: sinkNode,
                    rate: Percentage(fromDouble: 1.0 / wrapQuoteRate.asDouble),
                    minFlow: Number(0),
                    maxFlow: maxFlow,
                    folio: folio
                )]
            } else if let unwrapQuoteRate = folio.getUnwrapQuote(
                underlyingNetwork: sourceNetwork,
                underlyingSymbol: sourceSymbol,
                wrappedNetwork: sinkNetwork,
                wrappedSymbol: sinkSymbol
            ) {
                return [makeLegendRoute(
                    type: .unwrap,
                    source: sourceNode,
                    sink: sinkNode,
                    rate: Percentage(fromDouble: unwrapQuoteRate.asDouble),
                    minFlow: Number(0),
                    maxFlow: maxFlow,
                    folio: folio
                )]
            }

        case (
            .tokenBalance(let sourceNetwork, let sourceAddress, _, let sourceWallet),
            .tokenBalance(let sinkNetwork, let sinkAddress, _, let sinkWallet)
        )
        where sourceNetwork == sinkNetwork && sourceAddress == sinkAddress
            && sourceWallet != sinkWallet:

            // Case 2: Same-chain transfer

            // Directional routing rules:
            // 1. Actor can transfer OUT to anyone (transferOut)
            // 2. Other userWallets can transfer TO actor (tokenTransfer)
            // 3. Actor cannot transfer to other userWallets

            if sourceWallet == actorWallet {
                // Actor is sending - only allow if sink is NOT in userWallets (no transfers to other user wallets)
                guard !userWallets.contains(sinkWallet) || sinkWallet == actorWallet else {
                    return []
                }
                return [makeLegendRoute(
                    type: .transferOut,
                    source: sourceNode,
                    sink: sinkNode,
                    rate: 1.0,
                    minFlow: Number(0),
                    maxFlow: maxFlow,
                    folio: folio
                )]
            } else if userWallets.contains(sourceWallet) && sinkWallet == actorWallet {
                // Other user wallets can send TO actor
                return [makeLegendRoute(
                    type: .tokenTransfer,
                    source: sourceNode,
                    sink: sinkNode,
                    rate: 1.0,
                    minFlow: Number(0),
                    maxFlow: maxFlow,
                    folio: folio
                )]
            }

            // No other transfers allowed
            return []

        case (
            .tokenBalance(let sourceNetwork, _, let sourceSymbol, let sourceWallet),
            .tokenBalance(let sinkNetwork, _, let sinkSymbol, let sinkWallet)
        ):

            // Case 3: Cross-chain bridge (tokenBalance -> tokenBalance)
            // Supports both Across and CCTP v2 bridges
            // For bridges: only allow actor to bridge their own funds
            if sourceWallet != actorWallet || sinkWallet != actorWallet {
                return []
            }

            var bridgeRoutes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] = []
            let isCappedMax = cappedMaxNodes.contains(sourceNode)

            // Across bridge
            if let bridgeHint = folio.getAcrossQuote(
                sourceNetwork: sourceNetwork,
                sinkNetwork: sinkNetwork,
                sourceSymbol: sourceSymbol,
                sinkSymbol: sinkSymbol
            ) {
                bridgeRoutes.append(makeLegendRoute(
                    type: .bridge(bridgeType: .across, isCappedMax: isCappedMax),
                    source: sourceNode,
                    sink: sinkNode,
                    rate: Percentage(fromNumber: Number(bridgeHint.rate.underlying)),
                    fees: [
                        Tradewinds.Fee(
                            type: .bridgeAcross,
                            isInFee: false,
                            amount: bridgeHint.fixedCost.underlying
                        )
                    ],
                    minFlow: bridgeHint.minAmount.underlying,
                    maxFlow: bridgeHint.maxAmountInstant.underlying,
                    folio: folio
                ))
            }

            // CCTP v2 bridge
            if let cctpHint = folio.getCCTPv2Quote(
                sourceNetwork: sourceNetwork,
                sinkNetwork: sinkNetwork,
                sourceSymbol: sourceSymbol,
                sinkSymbol: sinkSymbol
            ) {
                bridgeRoutes.append(makeLegendRoute(
                    type: .bridge(bridgeType: .cctpV2, isCappedMax: isCappedMax),
                    source: sourceNode,
                    sink: sinkNode,
                    rate: Percentage(fromNumber: Number(cctpHint.rate.underlying)),
                    fees: [
                        Tradewinds.Fee(
                            type: .bridgeCCTPv2,
                            isInFee: false,
                            amount: cctpHint.fixedCost.underlying
                        )
                    ],
                    minFlow: cctpHint.minAmount.underlying,
                    maxFlow: cctpHint.maxAmount.underlying,
                    folio: folio
                ))
            }

            return bridgeRoutes

        case (
            .tokenBalance(let network, let address, _, let wallet),
            .cometSupplyBalance(let cometNetwork, _, let baseAsset, let cometWallet)
        )
        where network == cometNetwork && wallet == cometWallet && wallet == actorWallet
            && address == baseAsset:
            // Token to Comet supply (must be same network, same wallet, same asset, only actor)
            // Use sink node maxness for supply operations (the supply venue determines maxness)
            let isCappedMax = cappedMaxNodes.contains(sinkNode)
            return [makeLegendRoute(
                type: .cometSupply(isCappedMax: isCappedMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,  // TODO: Use actual supply cap from folio
                folio: folio
            )]

        case (
            .cometSupplyBalance(let network, let comet, let baseAsset, let wallet),
            .tokenBalance(let tokenNetwork, let address, _, let tokenWallet)
        )
        where network == tokenNetwork && wallet == tokenWallet && wallet == actorWallet
            && address == baseAsset:
            // Comet withdraw to token (must be same network, same wallet, same asset, only actor)

            // Check if this is a max withdrawal based on cappedMaxNodes
            let isMax = cappedMaxNodes.contains(sourceNode)

            // Check if this withdrawal has an exact amount requirement
            let minFlow: Number
            let flowMax: Number
            if let exactAmount = exactWithdrawalAmounts[comet] {
                // Enforce exact withdrawal amount
                // Both minFlow and maxFlow set to exactAmount to force exact withdrawal
                minFlow = exactAmount
                flowMax = exactAmount
            } else {
                // No exact amount specified - allow any amount up to max
                minFlow = Number(0)
                flowMax = maxFlow
            }

            return [makeLegendRoute(
                type: .cometWithdraw(isMax: isMax),
                source: sourceNode,
                sink: sinkNode,
                rate: isMax ? Charter.MAX_WITHDRAW_BUFFER : 1.0,
                minFlow: minFlow,
                maxFlow: flowMax,
                folio: folio
            )]

        case (
            .tokenBalance(let network, let address, _, let wallet),
            .morphoVaultSupplyBalance(let vaultNetwork, _, let baseAsset, let vaultWallet)
        )
        where network == vaultNetwork && wallet == vaultWallet && wallet == actorWallet
            && address == baseAsset:
            // Token to Morpho vault supply (must be same network, same wallet, same asset, only actor)
            // Use sink node maxness for supply operations (the supply venue determines maxness)
            let isCappedMax = cappedMaxNodes.contains(sinkNode)
            return [makeLegendRoute(
                type: .morphoVaultSupply(isCappedMax: isCappedMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,  // TODO: Use actual supply cap from folio
                folio: folio
            )]

        case (
            .morphoVaultSupplyBalance(let network, let vault, let baseAsset, let wallet),
            .tokenBalance(let tokenNetwork, let address, _, let tokenWallet)
        )
        where network == tokenNetwork && wallet == tokenWallet && wallet == actorWallet
            && address == baseAsset:
            // Morpho vault withdraw to token (must be same network, same wallet, same asset, only actor)

            // Check if this is a max withdrawal based on cappedMaxNodes
            let isMax = cappedMaxNodes.contains(sourceNode)

            // Check if this withdrawal has an exact amount requirement
            let minFlow: Number
            let flowMax: Number
            if let exactAmount = exactWithdrawalAmounts[vault] {
                // Enforce exact withdrawal amount
                // Both minFlow and maxFlow set to exactAmount to force exact withdrawal
                minFlow = exactAmount
                flowMax = exactAmount
            } else {
                // No exact amount specified - allow any amount up to max
                minFlow = Number(0)
                flowMax = maxFlow
            }

            return [makeLegendRoute(
                type: .morphoVaultWithdraw(isMax: isMax),
                source: sourceNode,
                sink: sinkNode,
                rate: isMax ? Charter.MAX_WITHDRAW_BUFFER : Percentage(fromNumber: Number("1e18")),
                minFlow: minFlow,
                maxFlow: flowMax,
                folio: folio
            )]

        case (
            .tokenBalance(let network, let address, _, let wallet),
            .aaveSupplyBalance(let aaveNetwork, _, let baseAsset, let aaveWallet)
        )
        where network == aaveNetwork && wallet == aaveWallet && wallet == actorWallet
            && address == baseAsset:
            // Token to Aave supply (must be same network, same wallet, same asset, only actor)
            // Use sink node maxness for supply operations (the supply venue determines maxness)
            let isCappedMax = cappedMaxNodes.contains(sinkNode)
            return [makeLegendRoute(
                type: .aaveSupply(isCappedMax: isCappedMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,  // TODO: Use actual supply cap from folio
                folio: folio
            )]

        case (
            .aaveSupplyBalance(let network, let pool, let baseAsset, let wallet),
            .tokenBalance(let tokenNetwork, let address, _, let tokenWallet)
        )
        where network == tokenNetwork && wallet == tokenWallet && wallet == actorWallet
            && address == baseAsset:
            // Aave withdraw to token (must be same network, same wallet, same asset, only actor)

            // Check if this is a max withdrawal based on cappedMaxNodes
            let isMax = cappedMaxNodes.contains(sourceNode)

            // Check if this withdrawal has an exact amount requirement
            let minFlow: Number
            let flowMax: Number
            if let exactAmount = exactWithdrawalAmounts[pool] {
                // Enforce exact withdrawal amount
                // Both minFlow and maxFlow set to exactAmount to force exact withdrawal
                minFlow = exactAmount
                flowMax = exactAmount
            } else {
                // No exact amount specified - allow any amount up to max
                minFlow = Number(0)
                flowMax = maxFlow
            }

            return [makeLegendRoute(
                type: .aaveWithdraw(isMax: isMax),
                source: sourceNode,
                sink: sinkNode,
                rate: isMax ? Charter.MAX_WITHDRAW_BUFFER : 1.0,
                minFlow: minFlow,
                maxFlow: flowMax,
                folio: folio
            )]

        case (
            .tokenBalance(let network, let address, _, let wallet),
            .cometCollateralBalance(let cometNetwork, _, let collateralAsset, let cometWallet)
        )
        where network == cometNetwork && wallet == cometWallet && wallet == actorWallet
            && address == collateralAsset:
            // Token to Comet collateral (must be same network, same wallet, same asset, only actor)
            let isCappedMax = cappedMaxNodes.contains(sinkNode)
            return [makeLegendRoute(
                type: .cometSupplyCollateral(isCappedMax: isCappedMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,
                folio: folio
            )]

        case (
            .tokenBalance(let network, let address, _, let wallet),
            .cometBorrowPosition(let borrowNetwork, _, let borrowAsset, let borrowWallet)
        )
        where network == borrowNetwork && wallet == borrowWallet && wallet == actorWallet
            && address == borrowAsset:
            // Token to Comet borrow position (repay) - must be same network, same wallet, same asset, only actor
            let isMax = cappedMaxNodes.contains(sourceNode)
            return [makeLegendRoute(
                type: .cometRepay(isMax: isMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,
                folio: folio
            )]

        case (
            .tokenBalance(let network, let address, _, let wallet),
            .morphoBorrowPosition(let borrowNetwork, _, let borrowAsset, let borrowWallet)
        )
        where network == borrowNetwork && wallet == borrowWallet && wallet == actorWallet
            && address == borrowAsset:
            // Token to Morpho borrow position (repay) - must be same network, same wallet, same asset, only actor
            let isMax = cappedMaxNodes.contains(sourceNode)
            return [makeLegendRoute(
                type: .morphoRepay(isMax: isMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,
                folio: folio
            )]

        case (
            .tokenBalance(let network, let address, _, let wallet),
            .morphoCollateralBalance(let morphoNetwork, _, let collateralAsset, let morphoWallet)
        )
        where network == morphoNetwork && wallet == morphoWallet && wallet == actorWallet
            && address == collateralAsset:
            // Token to Morpho collateral (must be same network, same wallet, same asset, only actor)
            let isCappedMax = cappedMaxNodes.contains(sinkNode)
            return [makeLegendRoute(
                type: .morphoSupplyCollateral(isCappedMax: isCappedMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,
                folio: folio
            )]

        case (
            .cometCollateralBalance(let collateralNetwork, _, let collateralAsset, let wallet),
            .tokenBalance(let tokenNetwork, let tokenAddress, _, let tokenWallet)
        )
        where collateralNetwork == tokenNetwork && collateralAsset == tokenAddress
            && wallet == tokenWallet && wallet == actorWallet:
            // Comet collateral to token balance (withdrawal)
            // Use source node maxness for withdrawal operations
            let isMax = cappedMaxNodes.contains(sourceNode)
            return [makeLegendRoute(
                type: .cometWithdrawCollateral(isMax: isMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,
                folio: folio
            )]

        case (
            .morphoCollateralBalance(let collateralNetwork, _, let collateralAsset, let wallet),
            .tokenBalance(let tokenNetwork, let tokenAddress, _, let tokenWallet)
        )
        where collateralNetwork == tokenNetwork && collateralAsset == tokenAddress
            && wallet == tokenWallet && wallet == actorWallet:
            // Morpho collateral to token balance (withdrawal)
            // Use source node maxness for withdrawal operations
            let isMax = cappedMaxNodes.contains(sourceNode)
            return [makeLegendRoute(
                type: .morphoWithdrawCollateral(isMax: isMax),
                source: sourceNode,
                sink: sinkNode,
                rate: 1.0,  // 1:1 conversion
                minFlow: Number(0),
                maxFlow: maxFlow,
                folio: folio
            )]

        default:
            return []
    }

    return []
}

/// Creates token balance nodes and routes for swap hint assets in a single pass.
/// Nodes enable cross-chain routing to/from swap targets.
/// Routes represent swap hint tiers (one per tier per hint).
internal func createSwapHintNodesAndRoutes(
    folio: Folio,
    actorWallet: EthAddress,
    isMaxIntent: Bool
) -> (nodes: [TradewindsLegendNode], routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]) {
    var nodes: Set<TradewindsLegendNode> = []
    var routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] = []
    let slippageFactor = Percentage.one - Charter.SWAP_MAX_SLIPPAGE

    for (swapHintType, swapHint) in folio.swapHints {
        guard case .swap(let network, let sellSymbol, let buySymbol, let venue, _) = swapHintType else {
            continue
        }
        let capacity = swapHint.maxAmount?.underlying ?? Number(0)
        guard sellSymbol != buySymbol && capacity > 0 else { continue }

        guard let atlasNetwork = Atlas.getEvmNetwork(network: network),
              let sellAsset = atlasNetwork.getAssetBySymbol(sellSymbol),
              let buyAsset = atlasNetwork.getAssetBySymbol(buySymbol) else {
            continue
        }

        let sellNode = TradewindsLegendNode.tokenBalance(
            network: network, address: sellAsset.assetAddress,
            symbol: sellSymbol, wallet: actorWallet
        )
        let buyNode = TradewindsLegendNode.tokenBalance(
            network: network, address: buyAsset.assetAddress,
            symbol: buySymbol, wallet: actorWallet
        )
        nodes.insert(sellNode)
        nodes.insert(buyNode)

        let tierBuyAmount = capacity * swapHint.exchangeRate.underlying.asNumber / Number.pow10(swapHint.exchangeRate.factorScale)
        let minTierBuyAmount = Number(tierBuyAmount * slippageFactor)
        let adjustedRate = isMaxIntent
            ? swapHint.exchangeRate * Charter.SWAP_OUTPUT_BUFFER * slippageFactor
            : swapHint.exchangeRate * slippageFactor

        routes.append(makeLegendRoute(
            type: .swap(
                buyToken: buyAsset.assetAddress,
                buyAmount: minTierBuyAmount,
                swapQuoteSellAmount: capacity,
                swapQuoteBuyAmount: minTierBuyAmount,
                feeToken: sellAsset.assetAddress,
                feeAmount: Number(0),
                isExactOut: false,
                isCappedMax: isMaxIntent,
                venue: venue
            ),
            source: sellNode,
            sink: buyNode,
            rate: adjustedRate,
            minFlow: Number(0),
            maxFlow: capacity,
            folio: folio
        ))
    }

    return (Array(nodes), routes)
}

internal func generateRoutes(
    nodes: [TradewindsLegendNode],
    folio: Folio,
    userWallets: Set<EthAddress>,
    actorWallet: EthAddress,
    cappedMaxNodes: Set<TradewindsLegendNode>,
    exactWithdrawalAmounts: [EthAddress: Number] = [:],  // Maps market address to exact withdrawal amount
    includeSwapHints: Bool = false,  // When true, also generate swap hint routes
    logger: Charter.Logger?
) -> [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] {
    var routes: Set<Tradewinds.Route<TradewindsLegendNode, LegendRouteType>> = []

    // Pre-create swap hint nodes and routes in one pass
    let (swapHintNodes, swapHintRoutes) = includeSwapHints
        ? createSwapHintNodesAndRoutes(folio: folio, actorWallet: actorWallet, isMaxIntent: !cappedMaxNodes.isEmpty)
        : ([], [])

    // Use Set to deduplicate nodes
    let allNodes: Set<TradewindsLegendNode> = Set(nodes)
        .union(swapHintNodes)

    // Generate routes between all pairs of nodes (including swap nodes)
    for sourceNode in allNodes {
        for sinkNode in allNodes where sourceNode != sinkNode {
            for route in generateRoute(
                sourceNode: sourceNode,
                sinkNode: sinkNode,
                folio: folio,
                userWallets: userWallets,
                actorWallet: actorWallet,
                cappedMaxNodes: cappedMaxNodes,
                exactWithdrawalAmounts: exactWithdrawalAmounts,
                logger: logger
            ) {
                routes.insert(route)
            }
        }
    }

    // Add swap hint routes
    for route in swapHintRoutes {
        routes.insert(route)
    }

    return Array(routes)
}

/// Builds Tradewinds graph components (routes, resources, sink nodes) for claiming rewards
internal func buildRewardClaimGraph(
    rewardBalances: [(rewardType: Folio.RewardType, amount: Amount)],
    folio: Folio,
    claimer: EthAddress
) -> Result<
    (
        routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
        resources: [Tradewinds.Resource<TradewindsLegendNode>],
        sinkNodes: Set<TradewindsLegendNode>
    ),
    Charter.CharterError
> {
    var routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] = []
    var resources: [Tradewinds.Resource<TradewindsLegendNode>] = []
    var sinkNodes: Set<TradewindsLegendNode> = []

    for (rewardType, amount) in rewardBalances {
        let (underlyingSymbol, network) = rewardType.underlyingSymbolAndNetwork

        guard let asset = Atlas.getEvmAssetBySymbol(network: network, symbol: underlyingSymbol)
        else {
            return .failure(.unknownAsset(symbol: underlyingSymbol, network: network, address: nil))
        }

        guard let price = folio.getAssetPrice(symbol: underlyingSymbol)?.underlying else {
            return .failure(.unpricedAsset(symbol: underlyingSymbol))
        }

        let rewardTokenNode = TradewindsLegendNode.tokenBalance(
            network: network,
            address: asset.assetAddress,
            symbol: underlyingSymbol,
            wallet: claimer
        )
        sinkNodes.insert(rewardTokenNode)

        switch rewardType {
            case .cometReward(_, let comet, _, let cometRewards, _):
                let rewardMarketNode = TradewindsLegendNode.cometReward(
                    network: network,
                    comet: comet,
                    token: asset.assetAddress,
                    wallet: claimer
                )
                routes.append(
                    makeLegendRoute(
                        type: .cometClaimRewards(
                            cometRewards: [cometRewards],
                            comets: [comet],
                            amounts: [amount.underlying],
                            symbols: [underlyingSymbol],
                            prices: [price],
                            tokens: [asset.assetAddress]
                        ),
                        source: rewardMarketNode,
                        sink: rewardTokenNode,
                        rate: 1.0,
                        minFlow: Number(0),
                        maxFlow: Number.MAX_UINT_256,
                        folio: folio
                    )
                )
                resources.append(Tradewinds.Resource(amount: .exact(amount.underlying), node: rewardMarketNode))

            case .morphoReward(_, _, let distributor, _):
                guard let rewardInfo = folio.rewards[rewardType],
                    case .morphoReward(proof: let proof, proofAmount: let proofAmount) = rewardInfo.proof
                else { continue }

                let rewardMarketNode = TradewindsLegendNode.morphoReward(
                    network: network,
                    distributor: distributor,
                    token: asset.assetAddress,
                    wallet: claimer
                )
                routes.append(
                    makeLegendRoute(
                        type: .morphoClaimRewards(
                            distributors: [distributor],
                            rewards: [asset.assetAddress],
                            claimables: [proofAmount.underlying],
                            claimableNows: [amount.underlying],
                            proofs: [proof],
                            symbols: [underlyingSymbol],
                            prices: [price]
                        ),
                        source: rewardMarketNode,
                        sink: rewardTokenNode,
                        rate: 1.0,
                        minFlow: Number(0),
                        maxFlow: Number.MAX_UINT_256,
                        folio: folio
                    )
                )
                resources.append(Tradewinds.Resource(amount: .exact(amount.underlying), node: rewardMarketNode))
        }
    }

    return .success((routes: routes, resources: resources, sinkNodes: sinkNodes))
}

/// Creates a virtual balance node with passthrough routes to actual token balances.
///
/// Virtual balances allow constraining total input across multiple chains.
/// For example, "swap 500 USDC" should use exactly 500 USDC total, regardless of
/// whether it comes from one chain or is split across several. The virtual node
/// aggregates all chain balances and applies the constraint at the source.
internal func createVirtualBalance(
    symbol: String,
    wallet: EthAddress,
    amount: Tradewinds.FlowAmount,
    tokenBalanceResources: [Tradewinds.Resource<TradewindsLegendNode>]
) -> (
    resource: Tradewinds.Resource<TradewindsLegendNode>,
    routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]
) {
    let virtualNode = TradewindsLegendNode.virtualBalance(symbol: symbol, wallet: wallet)
    let resource = Tradewinds.Resource<TradewindsLegendNode>(amount: amount, node: virtualNode)

    let routes = tokenBalanceResources.compactMap { resourceInfo -> Tradewinds.Route<TradewindsLegendNode, LegendRouteType>? in
        guard case .tokenBalance(_, _, let tokenSymbol, _) = resourceInfo.node,
              tokenSymbol == symbol else {
            return nil
        }
        let chainBalance: Number
        switch resourceInfo.amount {
        case .exact(let amount):
            chainBalance = amount
        case .max:
            chainBalance = Number.MAX_UINT_256
        }
        return Tradewinds.Route(
            type: .balancePassthrough,
            source: virtualNode,
            sink: resourceInfo.node,
            rate: Percentage.one,
            minFlow: Number(0),
            maxFlow: chainBalance
        )
    }

    return (resource, routes)
}

/// Creates the supply venue node for a supply intent
internal func makeSupplyVenueNode(
    supplyIntent: Charter.SupplyIntent,
    baseAsset: EthAddress
) -> TradewindsLegendNode {
    let network = Network.fromChainId(supplyIntent.chainId)
    switch supplyIntent {
        case .aave(let intent):
            return .aaveSupplyBalance(
                network: network, pool: intent.aavePool,
                baseAsset: baseAsset, wallet: intent.sender.ethAddress
            )
        case .comet(let intent):
            return .cometSupplyBalance(
                network: network, comet: intent.comet,
                baseAsset: baseAsset, wallet: intent.sender.ethAddress
            )
        case .morpho(let intent):
            return .morphoVaultSupplyBalance(
                network: network, vault: intent.morphoVault,
                baseAsset: baseAsset, wallet: intent.sender.ethAddress
            )
    }
}

extension Charter.QuarkIntent.Type_ {

    func tradewindsInfo(
        folio: Folio,
        allowUsingEarningBalances: Bool = false,
        logger: Charter.Logger? = nil
    ) -> Result<
        (
            [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>],
            [Tradewinds.Resource<TradewindsLegendNode>],
            Tradewinds.Target<TradewindsLegendNode>
        ), Charter.CharterError
    > {
        switch self {
            case .transfer(let transferIntent):
                let targetNetwork = Network.fromChainId(transferIntent.chainId)
                guard
                    let destAsset = Atlas.getEvmAssetBySymbol(
                        network: targetNetwork,
                        symbol: transferIntent.assetSymbol
                    )
                else {
                    logger?
                        .log(
                            "Failed to get destination asset: \(targetNetwork), transferIntent=\(String(describing: transferIntent))"
                        )
                    return .failure(
                        .unknownAsset(
                            symbol: transferIntent.assetSymbol,
                            network: targetNetwork,
                            address: nil
                        )
                    )
                }

                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: transferIntent.assetSymbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: transferIntent.sender.ethAddress,
                    network: nil  // Transfer can use resources from any network
                )

                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources for transfer: \(error)")
                        return .failure(error)
                }
                let targetNode = TradewindsLegendNode.tokenBalance(
                    network: targetNetwork,
                    address: destAsset.assetAddress,
                    symbol: transferIntent.assetSymbol,
                    wallet: transferIntent.recipient.ethAddress
                )

                let nodes = Array(Set([targetNode] + resources.map { $0.node }))
                let routes = generateRoutes(
                    nodes: nodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: transferIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodes) : Set(),
                    logger: logger
                )

                return .success(
                    (
                        routes,
                        resources,
                        .init(
                            amount: transferIntent.amount.isMaxUint256
                                ? .max : .exact(transferIntent.amount),
                            node: targetNode
                        )
                    )
                )

            case .cometWithdraw(let withdrawIntent):
                let network = Network.fromChainId(withdrawIntent.chainId)
                guard Atlas.getCometMarket(network: network, comet: withdrawIntent.comet) != nil
                else {
                    return .failure(
                        .cometMarketNotFound(comet: withdrawIntent.comet, network: network)
                    )
                }

                guard
                    let destAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: withdrawIntent.assetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: withdrawIntent.assetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // For withdraw, we need the comet supply balance as a resource
                let resources: [Tradewinds.Resource<TradewindsLegendNode>] = folio.balances
                    .compactMap {
                        type,
                        balance -> Tradewinds.Resource<TradewindsLegendNode>? in
                        if case .yieldMarket(let yieldMarket, let wallet) = type,
                            case .comet(let cometNetwork, let comet, let underlyingSymbol) =
                                yieldMarket,
                            cometNetwork == network
                                && underlyingSymbol.equalIgnoringCase(destAsset.symbol)
                        {
                            return Tradewinds.Resource(
                                amount: .exact(balance.underlying),
                                node: .cometSupplyBalance(
                                    network: network,
                                    comet: comet,
                                    baseAsset: destAsset.assetAddress,
                                    wallet: wallet
                                )
                            )
                        }
                        return nil
                    }

                // Target is the token balance
                let targetNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: destAsset.assetAddress,
                    symbol: withdrawIntent.assetSymbol,
                    wallet: withdrawIntent.withdrawer.ethAddress
                )

                // Don't constrain exact withdrawal amounts - let Tradewinds optimize
                // to account for fees (especially when target amount < fees)
                let exactWithdrawalAmounts: [EthAddress: Number] = [:]

                let nodes = Array(Set([targetNode] + resources.map { $0.node }))
                let routes = generateRoutes(
                    nodes: nodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: withdrawIntent.withdrawer.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodes) : Set(),
                    exactWithdrawalAmounts: exactWithdrawalAmounts,
                    logger: logger
                )

                // Verify withdrawal route exists
                guard routes.contains(where: { route in
                    if case .cometWithdraw = route.type { return true } else { return false }
                }) else {
                    return .failure(
                        .routeNotFound(
                            symbol: destAsset.symbol,
                            routeType: LegendRouteType.cometWithdraw(isMax: self.isMaxIntent).identifier
                        )
                    )
                }

                // Set target to user's desired amount (net of fees).
                // Tradewinds will work backwards to calculate required withdrawal amount (gross).
                let targetAmount: Tradewinds.FlowAmount

                if withdrawIntent.amount.isMaxUint256 {
                    targetAmount = .max
                } else {
                    targetAmount = .exact(withdrawIntent.amount)
                }

                return .success(
                    (
                        routes,
                        resources,
                        .init(
                            amount: targetAmount,
                            node: targetNode
                        )
                    )
                )

            case .cometSupply(let supplyIntent):
                let network = Network.fromChainId(supplyIntent.chainId)
                guard Atlas.getCometMarket(network: network, comet: supplyIntent.comet) != nil
                else {
                    return .failure(
                        .cometMarketNotFound(comet: supplyIntent.comet, network: network)
                    )
                }

                guard
                    let asset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: supplyIntent.assetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: supplyIntent.assetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: supplyIntent.assetSymbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: supplyIntent.sender.ethAddress,
                    network: nil  // Can use resources from any network for bridging
                )

                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources for comet supply: \(error)")
                        return .failure(error)
                }
                let baseAssetAddress = asset.assetAddress

                // Target is the comet supply balance
                let targetNode = TradewindsLegendNode.cometSupplyBalance(
                    network: network,
                    comet: supplyIntent.comet,
                    baseAsset: baseAssetAddress,
                    wallet: supplyIntent.sender.ethAddress
                )

                let nodes = Array(Set([targetNode] + resources.map { $0.node }))
                let routes = generateRoutes(
                    nodes: nodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: supplyIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodes) : Set(),
                    logger: logger
                )

                return .success(
                    (
                        routes,
                        resources,
                        .init(
                            amount: supplyIntent.amount.isMaxUint256
                                ? .max : .exact(supplyIntent.amount),
                            node: targetNode
                        )
                    )
                )

            case .morphoVaultSupply(let supplyIntent):
                let network = Network.fromChainId(supplyIntent.chainId)
                guard
                    let asset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: supplyIntent.assetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: supplyIntent.assetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: supplyIntent.assetSymbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: supplyIntent.sender.ethAddress,
                    network: nil  // Can use resources from any network for bridging
                )

                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources for morpho vault supply: \(error)")
                        return .failure(error)
                }
                // Target is the morpho vault supply balance
                let targetNode = TradewindsLegendNode.morphoVaultSupplyBalance(
                    network: network,
                    vault: supplyIntent.morphoVault,
                    baseAsset: asset.assetAddress,
                    wallet: supplyIntent.sender.ethAddress
                )

                let nodes = Array(Set([targetNode] + resources.map { $0.node }))
                let routes = generateRoutes(
                    nodes: nodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: supplyIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodes) : Set(),
                    logger: logger
                )

                return .success(
                    (
                        routes,
                        resources,
                        .init(
                            amount: supplyIntent.amount.isMaxUint256
                                ? .max : .exact(supplyIntent.amount),
                            node: targetNode
                        )
                    )
                )

            case .morphoVaultWithdraw(let withdrawIntent):
                let network = Network.fromChainId(withdrawIntent.chainId)
                guard
                    let asset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: withdrawIntent.assetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: withdrawIntent.assetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Get morpho vault positions as resources
                let resources: [Tradewinds.Resource<TradewindsLegendNode>] = folio.balances
                    .compactMap {
                        type,
                        balance -> Tradewinds.Resource<TradewindsLegendNode>? in
                        if case .yieldMarket(let yieldMarket, let wallet) = type,
                            case .morphoVault(let morphoNetwork, let vault, let underlyingSymbol) =
                                yieldMarket,
                            morphoNetwork == network && vault == withdrawIntent.morphoVault
                                && underlyingSymbol.equalIgnoringCase(asset.symbol)
                        {
                            return Tradewinds.Resource(
                                amount: .exact(balance.underlying),
                                node: .morphoVaultSupplyBalance(
                                    network: morphoNetwork,
                                    vault: vault,
                                    baseAsset: asset.assetAddress,
                                    wallet: wallet
                                )
                            )
                        }
                        return nil
                    }

                // Target is the token balance
                let targetNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: asset.assetAddress,
                    symbol: withdrawIntent.assetSymbol,
                    wallet: withdrawIntent.withdrawer.ethAddress
                )

                // Don't constrain exact withdrawal amounts - let Tradewinds optimize
                // to account for fees (especially when target amount < fees)
                let exactWithdrawalAmounts: [EthAddress: Number] = [:]

                let nodes = Array(Set([targetNode] + resources.map { $0.node }))
                let routes = generateRoutes(
                    nodes: nodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: withdrawIntent.withdrawer.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodes) : Set(),
                    exactWithdrawalAmounts: exactWithdrawalAmounts,
                    logger: logger
                )

                // Verify withdrawal route exists
                guard routes.contains(where: { route in
                    if case .morphoVaultWithdraw = route.type { return true } else { return false }
                })
                else {
                    return .failure(
                        .routeNotFound(
                            symbol: asset.symbol,
                            routeType: LegendRouteType.morphoVaultWithdraw(isMax: self.isMaxIntent).identifier
                        )
                    )
                }

                // Set target to user's desired amount (net of fees).
                // Tradewinds will work backwards to calculate required withdrawal amount (gross).
                let targetAmount: Tradewinds.FlowAmount

                if withdrawIntent.amount.isMaxUint256 {
                    targetAmount = .max
                } else {
                    targetAmount = .exact(withdrawIntent.amount)
                }

                return .success(
                    (
                        routes,
                        resources,
                        .init(
                            amount: targetAmount,
                            node: targetNode
                        )
                    )
                )

            case .aaveSupply(let supplyIntent):
                let network = Network.fromChainId(supplyIntent.chainId)
                guard let networkType = Atlas.getEvmNetwork(network: network),
                    networkType.aaveMarkets.contains(where: { $0.pool == supplyIntent.aavePool })
                else {
                    return .failure(
                        .aaveMarketNotFound(pool: supplyIntent.aavePool, network: network)
                    )
                }

                guard
                    let asset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: supplyIntent.assetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: supplyIntent.assetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: supplyIntent.assetSymbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: supplyIntent.sender.ethAddress,
                    network: nil  // Can use resources from any network for bridging
                )

                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources for aave supply: \(error)")
                        return .failure(error)
                }
                // Target is the aave supply balance
                let targetNode = TradewindsLegendNode.aaveSupplyBalance(
                    network: network,
                    pool: supplyIntent.aavePool,
                    baseAsset: asset.assetAddress,
                    wallet: supplyIntent.sender.ethAddress
                )

                let nodes = Array(Set([targetNode] + resources.map { $0.node }))
                let routes = generateRoutes(
                    nodes: nodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: supplyIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodes) : Set(),
                    logger: logger
                )

                return .success(
                    (
                        routes,
                        resources,
                        .init(
                            amount: supplyIntent.amount.isMaxUint256
                                ? .max : .exact(supplyIntent.amount),
                            node: targetNode
                        )
                    )
                )

            case .aaveWithdraw(let withdrawIntent):
                let network = Network.fromChainId(withdrawIntent.chainId)
                guard let networkType = Atlas.getEvmNetwork(network: network),
                    networkType.aaveMarkets.contains(where: { $0.pool == withdrawIntent.aavePool })
                else {
                    return .failure(
                        .aaveMarketNotFound(pool: withdrawIntent.aavePool, network: network)
                    )
                }

                guard
                    let asset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: withdrawIntent.assetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: withdrawIntent.assetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Get aave positions as resources
                let resources: [Tradewinds.Resource<TradewindsLegendNode>] = folio.balances
                    .compactMap {
                        type,
                        balance -> Tradewinds.Resource<TradewindsLegendNode>? in
                        if case .yieldMarket(let yieldMarket, let wallet) = type,
                            case .aave(let aaveNetwork, let pool, let underlyingSymbol) =
                                yieldMarket,
                            aaveNetwork == network && pool == withdrawIntent.aavePool
                                && underlyingSymbol.equalIgnoringCase(asset.symbol)
                        {
                            return Tradewinds.Resource(
                                amount: .exact(balance.underlying),
                                node: .aaveSupplyBalance(
                                    network: aaveNetwork,
                                    pool: pool,
                                    baseAsset: asset.assetAddress,
                                    wallet: wallet
                                )
                            )
                        }
                        return nil
                    }

                // Target is the token balance
                let targetNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: asset.assetAddress,
                    symbol: withdrawIntent.assetSymbol,
                    wallet: withdrawIntent.withdrawer.ethAddress
                )

                // Don't constrain exact withdrawal amounts - let Tradewinds optimize
                // to account for fees (especially when target amount < fees)
                let exactWithdrawalAmounts: [EthAddress: Number] = [:]

                let nodes = Array(Set([targetNode] + resources.map { $0.node }))
                let routes = generateRoutes(
                    nodes: nodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: withdrawIntent.withdrawer.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodes) : Set(),
                    exactWithdrawalAmounts: exactWithdrawalAmounts,
                    logger: logger
                )

                // Verify withdrawal route exists
                guard routes.contains(where: { route in
                    if case .aaveWithdraw = route.type { return true } else { return false }
                }) else {
                    return .failure(
                        .routeNotFound(
                            symbol: asset.symbol,
                            routeType: LegendRouteType.aaveWithdraw(isMax: self.isMaxIntent).identifier
                        )
                    )
                }

                // Set target to user's desired amount (net of fees).
                // Tradewinds will work backwards to calculate required withdrawal amount (gross).
                let targetAmount: Tradewinds.FlowAmount

                if withdrawIntent.amount.isMaxUint256 {
                    targetAmount = .max
                } else {
                    targetAmount = .exact(withdrawIntent.amount)
                }

                return .success(
                    (
                        routes,
                        resources,
                        .init(
                            amount: targetAmount,
                            node: targetNode
                        )
                    )
                )

            case .cometBorrow(let borrowIntent):
                let network = Network.fromChainId(borrowIntent.chainId)
                guard Atlas.getCometMarket(network: network, comet: borrowIntent.comet) != nil
                else {
                    return .failure(
                        .cometMarketNotFound(comet: borrowIntent.comet, network: network)
                    )
                }

                return CometBorrowHandler()
                    .handle(
                        borrowIntent,
                        folio: folio,
                        allowUsingEarningBalances: allowUsingEarningBalances,
                        logger: logger
                    )

            case .morphoBorrow(let borrowIntent):
                let network = Network.fromChainId(borrowIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: borrowIntent.marketId)
                        != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: borrowIntent.marketId,
                            network: network
                        )
                    )
                }

                return MorphoBorrowHandler()
                    .handle(
                        borrowIntent,
                        folio: folio,
                        allowUsingEarningBalances: allowUsingEarningBalances,
                        logger: logger
                    )
            case .swap(let swapIntent):
                // Quote-based swap: single chain, single token pair
                let network = Network.fromChainId(swapIntent.chainId)

                // Look up sell asset by address to get its symbol
                guard let atlasNetwork = Atlas.getEvmNetwork(network: network),
                    let sellAsset = atlasNetwork.getAssetByAddress(swapIntent.sellToken)
                else {
                    return .failure(
                        .unknownAsset(symbol: nil, network: network, address: swapIntent.sellToken)
                    )
                }

                // Look up buy asset
                guard let buyAsset = atlasNetwork.getAssetByAddress(swapIntent.buyToken) else {
                    return .failure(
                        .unknownAsset(symbol: nil, network: network, address: swapIntent.buyToken)
                    )
                }

                guard swapIntent.swapQuoteSellAmount > 0 else {
                    return .failure(.invalidSwapQuoteSellAmountIsZero)
                }

                // Create factory with the symbol - this ensures we get wrapped variants
                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: sellAsset.symbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: swapIntent.sender.ethAddress,
                    network: nil
                )

                // Get all resources from factory
                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources for swap: \(error)")
                        return .failure(error)
                }

                // Create sell token node
                let sellTokenNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: swapIntent.sellToken,
                    symbol: sellAsset.symbol,
                    wallet: swapIntent.sender.ethAddress
                )

                // Create buy token node (this is the output, not a resource)
                let buyTokenNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: swapIntent.buyToken,
                    symbol: buyAsset.symbol,
                    wallet: swapIntent.sender.ethAddress
                )

                // Build node set - includes buy token node but NOT in resources
                let nodes = Set([buyTokenNode, sellTokenNode] + resources.map { $0.node })
                let nodesArray = Array(nodes)

                // Generate standard routes (wrapping, bridging, etc. for sell token)
                var routes = generateRoutes(
                    nodes: nodesArray,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: swapIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodesArray) : Set(),
                    logger: logger
                )

                let rate = calculateSwapRate(swapIntent: swapIntent, isMaxSell: self.isMaxIntent)
                let (swapMinFlow, swapMaxFlow) = calculateSwapFlowConstraints(
                    swapIntent: swapIntent,
                    isMaxSell: self.isMaxIntent
                )

                let swapRoute = makeLegendRoute(
                    type: .swap(
                        buyToken: swapIntent.buyToken,
                        buyAmount: swapIntent.buyAmount,
                        swapQuoteSellAmount: swapIntent.swapQuoteSellAmount,
                        swapQuoteBuyAmount: swapIntent.swapQuoteBuyAmount,
                        feeToken: swapIntent.feeToken,
                        feeAmount: swapIntent.feeAmount,
                        isExactOut: swapIntent.isExactOut,
                        isCappedMax: self.isMaxIntent
                    ),
                    source: sellTokenNode,
                    sink: buyTokenNode,
                    rate: rate,
                    minFlow: swapMinFlow,
                    maxFlow: swapMaxFlow,
                    folio: folio
                )
                routes.append(swapRoute)

                // Target differs based on exact-out vs other swap types
                // - Exact-out: target the specific buyAmount
                // - Exact-in or max swap: maximize output at the given rate
                let target: Tradewinds.Target<TradewindsLegendNode>
                if swapIntent.isExactOut {
                    target = Tradewinds.Target(
                        amount: .exact(swapIntent.buyAmount),
                        node: buyTokenNode
                    )
                } else {
                    target = Tradewinds.Target(
                        amount: .max,
                        node: buyTokenNode
                    )
                }

                return .success((routes, resources, target))

            case .swapV2(let swapIntentV2):
                // Uses Folio swap hints for routing through optimal swap paths.

                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: swapIntentV2.sellAssetSymbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: swapIntentV2.sender,
                    network: nil  // All networks
                )
                let allResources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                case .success(let resources):
                    allResources = resources
                case .failure(let error):
                    logger?.log("Failed to create resources for swap: \(error)")
                    return .failure(error)
                }

                // Verify sufficient balance for exact-in intents
                if !self.isMaxIntent {
                    let totalAvailableBalance = allResources.reduce(Number(0)) { sum, resource in
                        if case .tokenBalance(_, _, let symbol, _) = resource.node,
                           symbol == swapIntentV2.sellAssetSymbol,
                           case .exact(let amount) = resource.amount {
                            return sum + amount
                        }
                        return sum
                    }

                    if totalAvailableBalance < swapIntentV2.sellAmount {
                        return .failure(.insufficientBalance(
                            symbol: swapIntentV2.sellAssetSymbol,
                            required: swapIntentV2.sellAmount,
                            available: totalAvailableBalance
                        ))
                    }
                }

                let virtualBalance = createVirtualBalance(
                    symbol: swapIntentV2.sellAssetSymbol,
                    wallet: swapIntentV2.sender,
                    amount: self.isMaxIntent ? .max : .exact(swapIntentV2.sellAmount),
                    tokenBalanceResources: allResources
                )

                let allNodes = Set(allResources.map { $0.node })

                var routes = generateRoutes(
                    nodes: Array(allNodes),
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: swapIntentV2.sender,
                    cappedMaxNodes: self.isMaxIntent ? allNodes : Set(),
                    includeSwapHints: true,
                    logger: logger
                )
                routes.append(contentsOf: virtualBalance.routes)

                // Collect all swap output nodes for the buy asset
                let targetBuyNodes = Set(routes.compactMap { route -> TradewindsLegendNode? in
                    if case .swap = route.type, route.sink.symbol == swapIntentV2.buyAssetSymbol {
                        return route.sink
                    }
                    return nil
                })

                // Route all buy outputs to a single settlement node
                let settlementNode = TradewindsLegendNode.swapSettlement(wallet: swapIntentV2.sender)
                for buyNode in targetBuyNodes {
                    routes.append(Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                        type: .swapSettlement,
                        source: buyNode,
                        sink: settlementNode,
                        rate: Percentage.one,
                        minFlow: Number(0),
                        maxFlow: Number.MAX_UINT_256
                    ))
                }

                let target = Tradewinds.Target<TradewindsLegendNode>(
                    amount: .max,
                    node: settlementNode
                )

                return .success((routes, [virtualBalance.resource], target))

            case .cometRepay(let repayIntent):
                let network = Network.fromChainId(repayIntent.chainId)
                guard Atlas.getCometMarket(network: network, comet: repayIntent.comet) != nil
                else {
                    return .failure(
                        .cometMarketNotFound(comet: repayIntent.comet, network: network)
                    )
                }

                return CometRepayHandler()
                    .handle(
                        repayIntent,
                        folio: folio,
                        allowUsingEarningBalances: allowUsingEarningBalances,
                        logger: logger
                    )

            case .morphoRepay(let repayIntent):
                let network = Network.fromChainId(repayIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: repayIntent.marketId) != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: repayIntent.marketId,
                            network: network
                        )
                    )
                }

                return MorphoRepayHandler()
                    .handle(
                        repayIntent,
                        folio: folio,
                        allowUsingEarningBalances: allowUsingEarningBalances,
                        logger: logger
                    )

            case .loopLong(let loopIntent):
                let network = Network.fromChainId(loopIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: loopIntent.marketId) != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: loopIntent.marketId,
                            network: network
                        )
                    )
                }

                // Resolve assets
                guard
                    let backingAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: loopIntent.backingAssetSymbol
                    ),
                    let exposureAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: loopIntent.exposureAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: loopIntent.backingAssetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Create loop venue node
                let loopVenueNode = TradewindsLegendNode.loopVenue(
                    network: network,
                    marketId: loopIntent.marketId,
                    backingAsset: backingAsset.assetAddress,
                    exposureAsset: exposureAsset.assetAddress,
                    wallet: loopIntent.sender.ethAddress
                )

                // Conditional source and resources based on backing amount
                let sourceNode: TradewindsLegendNode
                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                let target: Tradewinds.Target<TradewindsLegendNode>

                if loopIntent.maxProvidedBackingAmount == 0 {
                    // Zero backing - use virtual source to force route selection
                    let virtualNode = TradewindsLegendNode.virtualNode(
                        network: network,
                        routeType: .loopLong(
                            marketId: loopIntent.marketId,
                            exposureAsset: exposureAsset.assetAddress,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureAmount: loopIntent.exposureAmount,
                            maxSwapBackingAmount: loopIntent.maxSwapBackingAmount,
                            maxProvidedBackingAmount: loopIntent.maxProvidedBackingAmount,
                            poolFee: loopIntent.poolFee,
                            isIncrease: loopIntent.isIncrease
                        ),
                        wallet: loopIntent.sender.ethAddress
                    )
                    sourceNode = virtualNode

                    // Virtual resource to force Tradewinds to select this route
                    resources = [
                        Tradewinds.Resource(
                            amount: .exact(Number(1)),
                            node: virtualNode
                        )
                    ]

                    // Target the loop venue with virtual flow amount
                    target = Tradewinds.Target(
                        amount: .exact(Number(1)),
                        node: loopVenueNode
                    )

                } else {
                    // Non-zero backing - use backing token as source
                    let backingAssetNode = TradewindsLegendNode.tokenBalance(
                        network: network,
                        address: backingAsset.assetAddress,
                        symbol: loopIntent.backingAssetSymbol,
                        wallet: loopIntent.sender.ethAddress
                    )
                    sourceNode = backingAssetNode

                    // Create resource factory for backing assets
                    let factory = TradewindsResourceFactory(
                        folio: folio,
                        primarySymbol: loopIntent.backingAssetSymbol,
                        earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                        actorWallet: loopIntent.sender.ethAddress,
                        network: nil  // Can bridge from other networks
                    )

                    switch factory.createAllResources() {
                        case .success(let res):
                            resources = res
                        case .failure(let error):
                            logger?.log("Failed to create resources for loop: \(error)")
                            return .failure(error)
                    }

                    // Target based on intent type
                    target = Tradewinds.Target(
                        amount: loopIntent.maxProvidedBackingAmount.isMaxUint256
                            ? .max : .exact(loopIntent.maxProvidedBackingAmount),
                        node: loopVenueNode
                    )
                }

                // Standard routes not strictly needed when backing is 0, but shared for simplicity
                let nodes = Set([sourceNode, loopVenueNode] + resources.map { $0.node })
                var routes = generateRoutes(
                    nodes: Array(nodes),
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: loopIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? nodes : Set(),
                    exactWithdrawalAmounts: [:],
                    logger: logger
                )

                // Add the loop long route
                let loopLongRoute = makeLegendRoute(
                    type: .loopLong(
                        marketId: loopIntent.marketId,
                        exposureAsset: exposureAsset.assetAddress,
                        exposureAssetSymbol: exposureAsset.symbol,
                        exposureAmount: loopIntent.exposureAmount,
                        maxSwapBackingAmount: loopIntent.maxSwapBackingAmount,
                        maxProvidedBackingAmount: loopIntent.maxProvidedBackingAmount,
                        poolFee: loopIntent.poolFee,
                        isIncrease: loopIntent.isIncrease
                    ),
                    source: sourceNode,
                    sink: loopVenueNode,
                    rate: 1.0,
                    minFlow: Number(0),
                    maxFlow: Number.MAX_UINT_256,
                    folio: folio
                )

                routes.append(loopLongRoute)

                return .success((routes, resources, target))

            case .loopShort(let loopIntent):
                let network = Network.fromChainId(loopIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: loopIntent.marketId) != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: loopIntent.marketId,
                            network: network
                        )
                    )
                }

                // Resolve assets
                guard
                    let backingAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: loopIntent.backingAssetSymbol
                    ),
                    let exposureAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: loopIntent.exposureAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: loopIntent.backingAssetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Create loop venue node
                let loopVenueNode = TradewindsLegendNode.loopVenue(
                    network: network,
                    marketId: loopIntent.marketId,
                    backingAsset: backingAsset.assetAddress,
                    exposureAsset: exposureAsset.assetAddress,
                    wallet: loopIntent.sender.ethAddress
                )

                // Conditional source and resources based on backing amount
                let sourceNode: TradewindsLegendNode
                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                let target: Tradewinds.Target<TradewindsLegendNode>

                if loopIntent.providedBackingAmount == 0 {
                    // Zero backing - use virtual source to force route selection
                    let virtualNode = TradewindsLegendNode.virtualNode(
                        network: network,
                        routeType: .loopShort(
                            marketId: loopIntent.marketId,
                            exposureAsset: exposureAsset.assetAddress,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureAmount: loopIntent.exposureAmount,
                            minSwapBackingAmount: loopIntent.minSwapBackingAmount,
                            providedBackingAmount: loopIntent.providedBackingAmount,
                            poolFee: loopIntent.poolFee,
                            isIncrease: loopIntent.isIncrease
                        ),
                        wallet: loopIntent.sender.ethAddress
                    )
                    sourceNode = virtualNode

                    // Virtual resource to force Tradewinds to select this route
                    resources = [
                        Tradewinds.Resource(
                            amount: .exact(Number(1)),
                            node: virtualNode
                        )
                    ]

                    // Target the loop venue with virtual flow amount
                    target = Tradewinds.Target(
                        amount: .exact(Number(1)),
                        node: loopVenueNode
                    )

                } else {
                    // Non-zero backing - use backing token as source
                    let backingAssetNode = TradewindsLegendNode.tokenBalance(
                        network: network,
                        address: backingAsset.assetAddress,
                        symbol: loopIntent.backingAssetSymbol,
                        wallet: loopIntent.sender.ethAddress
                    )
                    sourceNode = backingAssetNode

                    // Create resource factory for backing assets (collateral for short)
                    let factory = TradewindsResourceFactory(
                        folio: folio,
                        primarySymbol: loopIntent.backingAssetSymbol,
                        earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                        actorWallet: loopIntent.sender.ethAddress,
                        network: nil  // Can bridge from other networks
                    )

                    switch factory.createAllResources() {
                        case .success(let res):
                            resources = res
                        case .failure(let error):
                            logger?.log("Failed to create resources for loop short: \(error)")
                            return .failure(error)
                    }

                    // Target based on intent type
                    target = Tradewinds.Target(
                        amount: loopIntent.providedBackingAmount.isMaxUint256
                            ? .max : .exact(loopIntent.providedBackingAmount),
                        node: loopVenueNode
                    )
                }

                // Standard routes not strictly needed when backing is 0, but shared for simplicity
                let nodes = Set([sourceNode, loopVenueNode] + resources.map { $0.node })
                var routes = generateRoutes(
                    nodes: Array(nodes),
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: loopIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? nodes : Set(),
                    exactWithdrawalAmounts: [:],
                    logger: logger
                )

                // Add the loop short route
                let loopShortRoute = makeLegendRoute(
                    type: .loopShort(
                        marketId: loopIntent.marketId,
                        exposureAsset: exposureAsset.assetAddress,
                        exposureAssetSymbol: exposureAsset.symbol,
                        exposureAmount: loopIntent.exposureAmount,
                        minSwapBackingAmount: loopIntent.minSwapBackingAmount,
                        providedBackingAmount: loopIntent.providedBackingAmount,
                        poolFee: loopIntent.poolFee,
                        isIncrease: loopIntent.isIncrease
                    ),
                    source: sourceNode,
                    sink: loopVenueNode,
                    rate: 1.0,
                    minFlow: Number(0),
                    maxFlow: Number.MAX_UINT_256,
                    folio: folio
                )

                routes.append(loopShortRoute)

                return .success((routes, resources, target))

            case .unloopLong(let unloopIntent):
                let network = Network.fromChainId(unloopIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: unloopIntent.marketId)
                        != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: unloopIntent.marketId,
                            network: network
                        )
                    )
                }

                // Resolve assets
                guard
                    let backingAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: unloopIntent.backingAssetSymbol
                    ),
                    let exposureAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: unloopIntent.exposureAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: unloopIntent.backingAssetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Create loop venue node (unloop goes from venue to token)
                let loopVenueNode = TradewindsLegendNode.loopVenue(
                    network: network,
                    marketId: unloopIntent.marketId,
                    backingAsset: backingAsset.assetAddress,
                    exposureAsset: exposureAsset.assetAddress,
                    wallet: unloopIntent.sender.ethAddress
                )

                // TODO: Unloop long resource should be based on borrow capacity.
                // For now, use .max to let Tradewinds optimize.
                let resources: [Tradewinds.Resource<TradewindsLegendNode>] = [
                    Tradewinds.Resource(
                        amount: .max,
                        node: loopVenueNode
                    )
                ]

                // Build node set - for unloop, we just need the venue and backing asset nodes
                let backingAssetNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: backingAsset.assetAddress,
                    symbol: unloopIntent.backingAssetSymbol,
                    wallet: unloopIntent.sender.ethAddress
                )

                // When exposureAmount is max (full unloop), backingAmountToExit must be 0
                let isFullUnloop = unloopIntent.exposureAmount.isMaxUint256
                if isFullUnloop && unloopIntent.backingAmountToExit != 0 {
                    return .failure(
                        .error(
                            "Invalid unloop long: when exposureAmount is max (full unloop), backingAmountToExit must be 0"
                        )
                    )
                }

                // Conditional sink and target based on backing amount to exit
                let sinkNode: TradewindsLegendNode
                let targetNode: TradewindsLegendNode
                let targetAmount: Tradewinds.FlowAmount

                if unloopIntent.backingAmountToExit == 0 && !isFullUnloop {
                    // Zero backing exit - use virtual sink to force route selection
                    let virtualNode = TradewindsLegendNode.virtualNode(
                        network: network,
                        routeType: .unloopLong(
                            marketId: unloopIntent.marketId,
                            exposureAsset: exposureAsset.assetAddress,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureAmount: unloopIntent.exposureAmount,
                            backingAmountToExit: unloopIntent.backingAmountToExit,
                            minSwapBackingAmount: unloopIntent.minSwapBackingAmount,
                            poolFee: unloopIntent.poolFee
                        ),
                        wallet: unloopIntent.sender.ethAddress
                    )
                    sinkNode = virtualNode
                    targetNode = virtualNode
                    targetAmount = .exact(Number(1))
                } else {
                    // Normal case - backing asset is the sink node
                    sinkNode = backingAssetNode
                    targetNode = backingAssetNode
                    let isMaxBackingExit = unloopIntent.backingAmountToExit.isMaxUint256
                    targetAmount =
                        isFullUnloop || isMaxBackingExit
                        ? .max
                        : .exact(unloopIntent.backingAmountToExit)
                }

                let nodes = Set([loopVenueNode, backingAssetNode, sinkNode])

                // Generate standard routes that might be needed for the output tokens
                let nodesArray = Array(nodes)
                var routes = generateRoutes(
                    nodes: nodesArray,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: unloopIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodesArray) : Set(),
                    exactWithdrawalAmounts: [:],
                    logger: logger
                )

                // Manually add the unloop long route (from venue to sink)
                let unloopLongRoute = makeLegendRoute(
                    type: .unloopLong(
                        marketId: unloopIntent.marketId,
                        exposureAsset: exposureAsset.assetAddress,
                        exposureAssetSymbol: exposureAsset.symbol,
                        exposureAmount: unloopIntent.exposureAmount,
                        backingAmountToExit: unloopIntent.backingAmountToExit,
                        minSwapBackingAmount: unloopIntent.minSwapBackingAmount,
                        poolFee: unloopIntent.poolFee
                    ),
                    source: loopVenueNode,
                    sink: sinkNode,
                    rate: 1.0,
                    minFlow: Number(0),
                    maxFlow: Number.MAX_UINT_256,
                    folio: folio
                )

                routes.append(unloopLongRoute)

                let target = Tradewinds.Target<TradewindsLegendNode>(
                    amount: targetAmount,
                    node: targetNode
                )

                return .success((routes, resources, target))

            case .unloopShort(let unloopIntent):
                let network = Network.fromChainId(unloopIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: unloopIntent.marketId)
                        != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: unloopIntent.marketId,
                            network: network
                        )
                    )
                }

                // Resolve assets
                guard
                    let backingAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: unloopIntent.backingAssetSymbol
                    ),
                    let exposureAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: unloopIntent.exposureAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: unloopIntent.backingAssetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Create loop venue node (unloop goes from venue to token)
                let loopVenueNode = TradewindsLegendNode.loopVenue(
                    network: network,
                    marketId: unloopIntent.marketId,
                    backingAsset: backingAsset.assetAddress,
                    exposureAsset: exposureAsset.assetAddress,
                    wallet: unloopIntent.sender.ethAddress
                )

                // Query folio for loop short position collateral balance
                // For unloop short, backing asset is the collateral
                let balanceKey = Folio.BalanceType.borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: network,
                        collateralTokenSymbol: backingAsset.symbol,
                        borrowTokenSymbol: exposureAsset.symbol
                    ),
                    tokenSymbol: backingAsset.symbol,
                    wallet: unloopIntent.sender.ethAddress
                )

                guard let collateralBalance = folio.balances[balanceKey]?.underlying else {
                    return .failure(
                        .error("Missing collateral balance in folio for unloop short: collateral=\(backingAsset.symbol), borrow=\(exposureAsset.symbol)")
                    )
                }

                let resources: [Tradewinds.Resource<TradewindsLegendNode>] = [
                    Tradewinds.Resource(
                        amount: .exact(collateralBalance),
                        node: loopVenueNode
                    )
                ]

                // Build node set - for unloop, we just need the venue and backing asset nodes
                let backingAssetNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: backingAsset.assetAddress,
                    symbol: unloopIntent.backingAssetSymbol,
                    wallet: unloopIntent.sender.ethAddress
                )

                // When exposureAmount is max (full unloop), backingAmountToExit must be 0
                let isFullUnloop = unloopIntent.exposureAmount.isMaxUint256
                if isFullUnloop && unloopIntent.backingAmountToExit != 0 {
                    return .failure(
                        .error(
                            "Invalid unloop short: when exposureAmount is max (full unloop), backingAmountToExit must be 0"
                        )
                    )
                }

                // Conditional sink and target based on backing amount to exit
                let sinkNode: TradewindsLegendNode
                let targetNode: TradewindsLegendNode
                let targetAmount: Tradewinds.FlowAmount

                if unloopIntent.backingAmountToExit == 0 && !isFullUnloop {
                    // Zero backing exit - use virtual sink to force route selection
                    let virtualNode = TradewindsLegendNode.virtualNode(
                        network: network,
                        routeType: .unloopShort(
                            marketId: unloopIntent.marketId,
                            exposureAsset: exposureAsset.assetAddress,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureAmount: unloopIntent.exposureAmount,
                            backingAmountToExit: unloopIntent.backingAmountToExit,
                            maxSwapBackingAmount: unloopIntent.maxSwapBackingAmount,
                            poolFee: unloopIntent.poolFee
                        ),
                        wallet: unloopIntent.sender.ethAddress
                    )
                    sinkNode = virtualNode
                    targetNode = virtualNode
                    targetAmount = .exact(Number(1))
                } else {
                    // Normal case - backing asset is the sink node
                    sinkNode = backingAssetNode
                    targetNode = backingAssetNode
                    let isMaxBackingExit = unloopIntent.backingAmountToExit.isMaxUint256
                    targetAmount =
                        isFullUnloop || isMaxBackingExit
                        ? .max
                        : .exact(unloopIntent.backingAmountToExit)
                }

                let nodes = Set([loopVenueNode, backingAssetNode, sinkNode])

                // Generate standard routes that might be needed for the output tokens
                let nodesArray = Array(nodes)
                var routes = generateRoutes(
                    nodes: nodesArray,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: unloopIntent.sender.ethAddress,
                    cappedMaxNodes: self.isMaxIntent ? Set(nodesArray) : Set(),
                    exactWithdrawalAmounts: [:],
                    logger: logger
                )

                // Manually add the unloop short route (from venue to sink)
                let unloopShortRoute = makeLegendRoute(
                    type: .unloopShort(
                        marketId: unloopIntent.marketId,
                        exposureAsset: exposureAsset.assetAddress,
                        exposureAssetSymbol: exposureAsset.symbol,
                        exposureAmount: unloopIntent.exposureAmount,
                        backingAmountToExit: unloopIntent.backingAmountToExit,
                        maxSwapBackingAmount: unloopIntent.maxSwapBackingAmount,
                        poolFee: unloopIntent.poolFee
                    ),
                    source: loopVenueNode,
                    sink: sinkNode,
                    rate: 1.0,
                    minFlow: Number(0),
                    maxFlow: Number.MAX_UINT_256,
                    folio: folio
                )

                routes.append(unloopShortRoute)

                let target = Tradewinds.Target<TradewindsLegendNode>(
                    amount: targetAmount,
                    node: targetNode
                )

                return .success((routes, resources, target))

            case .addBackingToken(let addBackingIntent):
                let network = Network.fromChainId(addBackingIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: addBackingIntent.marketId)
                        != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: addBackingIntent.marketId,
                            network: network
                        )
                    )
                }

                // Resolve assets
                guard
                    let backingAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: addBackingIntent.backingAssetSymbol
                    ),
                    let exposureAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: addBackingIntent.exposureAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: addBackingIntent.backingAssetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Create resource factory for backing assets
                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: addBackingIntent.backingAssetSymbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: addBackingIntent.sender.ethAddress,
                    network: nil  // Can bridge from other networks
                )

                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources for addBackingToken: \(error)")
                        return .failure(error)
                }

                // Create loop venue node (addBackingToken goes to venue)
                let loopVenueNode = TradewindsLegendNode.loopVenue(
                    network: network,
                    marketId: addBackingIntent.marketId,
                    backingAsset: backingAsset.assetAddress,
                    exposureAsset: exposureAsset.assetAddress,
                    wallet: addBackingIntent.sender.ethAddress
                )

                // Build node set
                var nodes = Set([loopVenueNode] + resources.map { $0.node })

                // Ensure the backing asset node exists for the route
                let backingAssetNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: backingAsset.assetAddress,
                    symbol: addBackingIntent.backingAssetSymbol,
                    wallet: addBackingIntent.sender.ethAddress
                )
                nodes.insert(backingAssetNode)

                // Generate standard routes
                let nodesArray = Array(nodes)
                var routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] =
                    generateRoutes(
                        nodes: nodesArray,
                        folio: folio,
                        userWallets: folio.getRelevantWallets(),
                        actorWallet: addBackingIntent.sender.ethAddress,
                        cappedMaxNodes: self.isMaxIntent ? Set(nodesArray) : Set(),
                        exactWithdrawalAmounts: [:],
                        logger: logger
                    )

                // Manually add the add backing token route
                let addBackingRoute = makeLegendRoute(
                    type: .addBackingToken(
                        marketId: addBackingIntent.marketId,
                        exposureAsset: exposureAsset.assetAddress,
                        exposureAssetSymbol: exposureAsset.symbol,
                        amount: addBackingIntent.amount,
                        isShort: addBackingIntent.isShort
                    ),
                    source: backingAssetNode,
                    sink: loopVenueNode,
                    rate: 1.0,
                    minFlow: Number(0),
                    maxFlow: Number.MAX_UINT_256,
                    folio: folio
                )

                routes.append(addBackingRoute)

                // Target is the loop venue with the backing amount
                let target = Tradewinds.Target<TradewindsLegendNode>(
                    amount: addBackingIntent.amount.isMaxUint256
                        ? .max : .exact(addBackingIntent.amount),
                    node: loopVenueNode
                )

                return .success((routes, resources, target))

            case .withdrawBackingToken(let withdrawIntent):
                let network = Network.fromChainId(withdrawIntent.chainId)
                guard
                    Atlas.getMorphoMarket(network: network, marketId: withdrawIntent.marketId)
                        != nil
                else {
                    return .failure(
                        .morphoMarketNotFound(
                            marketId: withdrawIntent.marketId,
                            network: network
                        )
                    )
                }

                // Resolve assets
                guard
                    let backingAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: withdrawIntent.backingAssetSymbol
                    ),
                    let exposureAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: withdrawIntent.exposureAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: withdrawIntent.backingAssetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                // Create loop venue node (withdraw goes from venue to token)
                let loopVenueNode = TradewindsLegendNode.loopVenue(
                    network: network,
                    marketId: withdrawIntent.marketId,
                    backingAsset: backingAsset.assetAddress,
                    exposureAsset: exposureAsset.assetAddress,
                    wallet: withdrawIntent.sender.ethAddress
                )

                let backingAssetNode = TradewindsLegendNode.tokenBalance(
                    network: network,
                    address: backingAsset.assetAddress,
                    symbol: withdrawIntent.backingAssetSymbol,
                    wallet: withdrawIntent.sender.ethAddress
                )

                // Query folio for position balance
                // withdrawBackingToken behavior differs by position type (see legend-scripts):
                // - LONG: Borrows more backing token (increases debt) → need borrow capacity
                // - SHORT: Withdraws backing collateral → need collateral balance
                let resourceAmount: Tradewinds.FlowAmount
                if withdrawIntent.isShort {
                    // SHORT: collateral = backing asset, can withdraw directly
                    let balanceKey = Folio.BalanceType.borrowMarketCollateral(
                        borrowMarket: .morpho(
                            network: network,
                            collateralTokenSymbol: backingAsset.symbol,
                            borrowTokenSymbol: exposureAsset.symbol
                        ),
                        tokenSymbol: backingAsset.symbol,
                        wallet: withdrawIntent.sender.ethAddress
                    )

                    guard let collateralBalance = folio.balances[balanceKey]?.underlying else {
                        return .failure(
                            .error("Missing collateral balance in folio for short position: collateral=\(backingAsset.symbol), borrow=\(exposureAsset.symbol)")
                        )
                    }
                    resourceAmount = .exact(collateralBalance)
                } else {
                    // TODO: LONG positions withdraw backing by borrowing more (increases debt).
                    // Should calculate borrow capacity based on:
                    // - Collateral value (exposure asset balance × price)
                    // - LTV ratio
                    // - Current debt
                    // For now, use .max to let Tradewinds optimize.
                    resourceAmount = .max
                }

                let resources: [Tradewinds.Resource<TradewindsLegendNode>] = [
                    Tradewinds.Resource(
                        amount: resourceAmount,
                        node: loopVenueNode
                    )
                ]

                let nodes = Set([loopVenueNode, backingAssetNode])
                let nodesArray = Array(nodes)

                var routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>] =
                    generateRoutes(
                        nodes: nodesArray,
                        folio: folio,
                        userWallets: folio.getRelevantWallets(),
                        actorWallet: withdrawIntent.sender.ethAddress,
                        cappedMaxNodes: self.isMaxIntent ? Set(nodesArray) : Set(),
                        exactWithdrawalAmounts: [:],
                        logger: logger
                    )

                // Don't constrain exact withdrawal amounts - let Tradewinds optimize
                // to account for fees (especially when target amount < fees)
                let minFlow = Number(0)
                let maxFlow = Number.MAX_UINT_256

                let withdrawRoute = makeLegendRoute(
                    type: .withdrawBackingToken(
                        marketId: withdrawIntent.marketId,
                        exposureAsset: exposureAsset.assetAddress,
                        exposureAssetSymbol: exposureAsset.symbol,
                        amount: withdrawIntent.amount,
                        isShort: withdrawIntent.isShort
                    ),
                    source: loopVenueNode,  // Source is the position
                    sink: backingAssetNode,  // Sink is the wallet
                    rate: 1.0,
                    minFlow: minFlow,
                    maxFlow: maxFlow,
                    folio: folio
                )

                routes.append(withdrawRoute)

                // Set target to user's desired amount (net of fees).
                // Tradewinds will work backwards to calculate required withdrawal amount (gross).
                let target = Tradewinds.Target<TradewindsLegendNode>(
                    amount: withdrawIntent.amount.isMaxUint256
                        ? .max
                        : .exact(withdrawIntent.amount),
                    node: backingAssetNode
                )

                return .success((routes, resources, target))

            case .migrateSupplies(let migrateIntent):
                // Extract network and primary asset from supply intent (enum-based)
                let supplyIntent = migrateIntent.supplyIntent
                let network = Network.fromChainId(supplyIntent.chainId)
                let supplyAssetSymbol = supplyIntent.assetSymbol

                // Validate all intents use the same asset (can be on different chains)
                for withdrawIntent in migrateIntent.withdrawIntents {
                    if withdrawIntent.assetSymbol != supplyAssetSymbol {
                        logger?
                            .log(
                                "Asset mismatch: withdrawing \(withdrawIntent.assetSymbol) but supplying \(supplyAssetSymbol)"
                            )
                        return .failure(
                            .error(
                                "Asset mismatch: withdrawing \(withdrawIntent.assetSymbol) but supplying \(supplyAssetSymbol)"
                            )
                        )
                    }

                }

                // Build set of withdrawal markets with their amounts
                let earnMarketPolicyAmounts = Set(
                    migrateIntent.withdrawIntents.map { withdrawIntent in
                        TradewindsResourceFactory.EarnMarketPolicyAmount(
                            marketAddress: withdrawIntent.market,
                            network: Network.fromChainId(withdrawIntent.chainId),
                            amount: withdrawIntent.amount.isMaxUint256
                                ? .max : .exact(withdrawIntent.amount)
                        )
                    }
                )

                // Create resource factory targeting specific withdrawal markets
                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: supplyAssetSymbol,
                    earnMarketPolicy: .specific(earnMarketPolicyAmounts),
                    actorWallet: supplyIntent.sender.ethAddress,
                    network: nil  // Allow cross-chain bridging if needed
                )

                // Create resources normally using the factory
                // When migrateOnlySupplyBalances=true, we only create earn market RESOURCES (starting points)
                // but we still need token balance NODES as intermediate routing points
                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                let resourceFunction =
                    migrateIntent.migrateOnlySupplyBalances
                    ? factory.createEarnMarketResources : factory.createAllResources
                switch resourceFunction() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources: \(error)")
                        return .failure(error)
                }

                // Always include token balance nodes as intermediate routing points
                // These are needed to connect withdrawals to supplies even when migrateOnlySupplyBalances=true
                let supplyAssetNodes: [TradewindsLegendNode] = factory.createTokenResources().map { $0.node }

                // Get supply asset
                guard
                    let supplyAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: supplyAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(symbol: supplyAssetSymbol, network: network, address: nil)
                    )
                }

                // Create supply venue node based on intent enum case
                let supplyVenueNode: TradewindsLegendNode
                switch supplyIntent {
                    case .comet(let cometIntent):
                        supplyVenueNode = .cometSupplyBalance(
                            network: network,
                            comet: cometIntent.comet,
                            baseAsset: supplyAsset.assetAddress,
                            wallet: cometIntent.sender.ethAddress
                        )
                    case .morpho(let morphoIntent):
                        supplyVenueNode = .morphoVaultSupplyBalance(
                            network: network,
                            vault: morphoIntent.morphoVault,
                            baseAsset: supplyAsset.assetAddress,
                            wallet: morphoIntent.sender.ethAddress
                        )
                    case .aave(let aaveIntent):
                        supplyVenueNode = .aaveSupplyBalance(
                            network: network,
                            pool: aaveIntent.aavePool,
                            baseAsset: supplyAsset.assetAddress,
                            wallet: aaveIntent.sender.ethAddress
                        )
                }

                // Build combined node set: market balances + token balances + supply venue
                // Use single-phase route generation to let Tradewinds optimize the full graph
                let allNodes = Set(resources.map { $0.node } + supplyAssetNodes + [supplyVenueNode])

                // Build exact withdrawal amounts map
                var exactWithdrawalAmounts: [EthAddress: Number] = [:]
                for withdrawIntent in migrateIntent.withdrawIntents {
                    if !withdrawIntent.amount.isMaxUint256 {
                        exactWithdrawalAmounts[withdrawIntent.market] = withdrawIntent.amount
                    }
                }

                // Build set of nodes that should use MAX amounts
                let hasAnyMaxWithdrawal = migrateIntent.withdrawIntents.contains {
                    $0.amount.isMaxUint256
                }

                let cappedMaxNodes: Set<TradewindsLegendNode> = Set(
                    allNodes.filter { node in
                        // Supply venue: always max for migrate supplies
                        if node == supplyVenueNode {
                            return true
                        }

                        switch node {
                            // Withdraw markets: max if that market has a MAX withdrawal
                            case .cometSupplyBalance(let network, let market, _, let wallet),
                                .morphoVaultSupplyBalance(let network, let market, _, let wallet),
                                .aaveSupplyBalance(let network, let market, _, let wallet):
                                return wallet == supplyIntent.sender.ethAddress
                                    && migrateIntent.withdrawIntents.contains {
                                        Network.fromChainId($0.chainId) == network
                                            && $0.market == market
                                            && $0.amount.isMaxUint256
                                    }

                            // Token balance: max if any withdrawal is MAX (enables multi-hop routing)
                            case .tokenBalance:
                                return hasAnyMaxWithdrawal

                            default:
                                return false
                        }
                    }
                )

                // Generate all routes in single phase
                let routes = generateRoutes(
                    nodes: Array(allNodes),
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: supplyIntent.sender.ethAddress,
                    cappedMaxNodes: cappedMaxNodes,
                    exactWithdrawalAmounts: exactWithdrawalAmounts,
                    logger: logger
                )

                // Calculate total withdrawal amount or use supply amount
                // If supply amount is MaxUint256, we should target max available from withdrawals
                guard supplyIntent.amount.isMaxUint256 else {
                    return .failure(
                        .error(
                            "MigrateSupplies requires supply amount to be .max (supply all specified assets)"
                        )
                    )
                }
                let targetAmount: Tradewinds.FlowAmount = .max

                // Target is the supply venue with the desired amount
                let target = Tradewinds.Target<TradewindsLegendNode>(
                    amount: targetAmount,
                    node: supplyVenueNode
                )

                return .success((routes, resources, target))

            case .swapAndSupply(let intent):
                let swapIntent = intent.swapIntent
                let supplyIntent = intent.supplyIntent

                let swapNetwork = Network.fromChainId(swapIntent.chainId)

                let supplyNetwork: Network
                let supplyAssetSymbol: String
                let supplySender: EthAddress

                switch supplyIntent {
                    case .comet(let cometIntent):
                        supplyNetwork = Network.fromChainId(cometIntent.chainId)
                        supplyAssetSymbol = cometIntent.assetSymbol
                        supplySender = cometIntent.sender.ethAddress
                    case .morpho(let morphoIntent):
                        supplyNetwork = Network.fromChainId(morphoIntent.chainId)
                        supplyAssetSymbol = morphoIntent.assetSymbol
                        supplySender = morphoIntent.sender.ethAddress
                    case .aave(let aaveIntent):
                        supplyNetwork = Network.fromChainId(aaveIntent.chainId)
                        supplyAssetSymbol = aaveIntent.assetSymbol
                        supplySender = aaveIntent.sender.ethAddress
                }

                // Debug logging
                logger?
                    .log(
                        "SwapAndSupply - Swap details: sellAmount=\(swapIntent.sellAmount), buyAmount=\(swapIntent.buyAmount)"
                    )
                logger?
                    .log(
                        "SwapAndSupply - Supply details: amount=\(supplyIntent.amount), network=\(supplyNetwork)"
                    )
                logger?.log("SwapAndSupply - Is cross-chain: \(swapNetwork != supplyNetwork)")

                guard swapIntent.sender.ethAddress == supplySender else {
                    return .failure(.swapAndSupplyMustHaveSameSender)
                }

                guard
                    let sellAsset = Atlas.getEvmAssetByAddress(
                        network: swapNetwork,
                        token: swapIntent.sellToken
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: nil,
                            network: swapNetwork,
                            address: swapIntent.sellToken
                        )
                    )
                }

                guard
                    let buyAsset = Atlas.getEvmAssetByAddress(
                        network: swapNetwork,
                        token: swapIntent.buyToken
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: nil,
                            network: swapNetwork,
                            address: swapIntent.buyToken
                        )
                    )
                }

                guard buyAsset.symbol == supplyAssetSymbol else {
                    return .failure(
                        .swapBuyTokenMustMatchSupplyAsset(
                            swapBuyToken: buyAsset.symbol,
                            supplyAsset: supplyAssetSymbol
                        )
                    )
                }

                let supplyAmount: Number
                switch supplyIntent {
                    case .comet(let intent): supplyAmount = intent.amount
                    case .morpho(let intent): supplyAmount = intent.amount
                    case .aave(let intent): supplyAmount = intent.amount
                }

                // We disallow non-max supply amounts because the point of this intent is to supply all the swapped assets
                guard supplyAmount.isMaxUint256 else {
                    return .failure(
                        .error(
                            "SwapAndSupply requires supply amount to be .max (supply all swap output)"
                        )
                    )
                }

                let factory = TradewindsResourceFactory(
                    folio: folio,
                    primarySymbol: sellAsset.symbol,
                    earnMarketPolicy: allowUsingEarningBalances ? .all : .none,
                    actorWallet: swapIntent.sender.ethAddress,
                    network: nil  // Allow cross-chain bridging
                )

                let resources: [Tradewinds.Resource<TradewindsLegendNode>]
                switch factory.createAllResources() {
                    case .success(let res):
                        resources = res
                    case .failure(let error):
                        logger?.log("Failed to create resources for swap and supply: \(error)")
                        return .failure(error)
                }

                let sellTokenNode = TradewindsLegendNode.tokenBalance(
                    network: swapNetwork,
                    address: swapIntent.sellToken,
                    symbol: sellAsset.symbol,
                    wallet: swapIntent.sender.ethAddress
                )

                // Create buy token nodes on MULTIPLE networks to allow cross-chain optimization
                var buyTokenNodes: Set<TradewindsLegendNode> = []

                buyTokenNodes.insert(
                    TradewindsLegendNode.tokenBalance(
                        network: swapNetwork,
                        address: swapIntent.buyToken,
                        symbol: buyAsset.symbol,
                        wallet: swapIntent.sender.ethAddress
                    )
                )

                // Add buy token nodes on supply network (if different)
                if swapNetwork != supplyNetwork {
                    let relevantSymbols = folio.getRelevantSymbols(
                        network: supplyNetwork,
                        assetSymbol: buyAsset.symbol
                    )

                    for symbol in relevantSymbols {
                        if let assetOnSupplyNetwork = Atlas.getEvmAssetBySymbol(
                            network: supplyNetwork,
                            symbol: symbol
                        ) {
                            let node = TradewindsLegendNode.tokenBalance(
                                network: supplyNetwork,
                                address: assetOnSupplyNetwork.assetAddress,
                                symbol: symbol,
                                wallet: swapIntent.sender.ethAddress
                            )
                            buyTokenNodes.insert(node)
                        }
                    }
                }

                guard
                    let supplyAsset = Atlas.getEvmAssetBySymbol(
                        network: supplyNetwork,
                        symbol: supplyAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: supplyAssetSymbol,
                            network: supplyNetwork,
                            address: nil
                        )
                    )
                }

                let supplyVenueNode = makeSupplyVenueNode(supplyIntent: supplyIntent, baseAsset: supplyAsset.assetAddress)

                // Build node sets for two-phase route generation
                // Phase A: Swap resources (sellToken ecosystem)
                // Phase B: Supply resources (buyToken ecosystem)

                // Get buyTokenNodeOnSwapNetwork from the buyTokenNodes set
                let buyTokenNodeOnSwapNetwork = TradewindsLegendNode.tokenBalance(
                    network: swapNetwork,
                    address: swapIntent.buyToken,
                    symbol: buyAsset.symbol,
                    wallet: swapIntent.sender.ethAddress
                )

                // Phase A: Generate routes for swap sub-intent (sellToken ecosystem)
                // This includes bridges to gather sellToken from various chains/venues
                let swapPhaseNodes = Set(
                    [sellTokenNode, buyTokenNodeOnSwapNetwork]
                        + resources.map { $0.node }
                )
                let swapPhaseNodesArray = Array(swapPhaseNodes)

                var routes = generateRoutes(
                    nodes: swapPhaseNodesArray,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: swapIntent.sender.ethAddress,
                    cappedMaxNodes: swapIntent.sellAmount.isMaxUint256 ? Set(swapPhaseNodesArray) : Set(),
                    logger: logger
                )

                logger?.log("SwapAndSupply - Generated \(routes.count) routes for swap phase")

                // Phase B: Generate routes for supply sub-intent (buyToken ecosystem)
                // This includes bridges to move buyToken cross-chain if needed
                let supplyPhaseNodes = Set(
                    Array(buyTokenNodes) + [supplyVenueNode]
                )
                let supplyPhaseNodesArray = Array(supplyPhaseNodes)

                let supplyPhaseRoutes = generateRoutes(
                    nodes: supplyPhaseNodesArray,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: swapIntent.sender.ethAddress,
                    cappedMaxNodes: supplyAmount.isMaxUint256 ? Set(supplyPhaseNodesArray) : Set(),
                    logger: logger
                )

                logger?
                    .log(
                        "SwapAndSupply - Generated \(supplyPhaseRoutes.count) routes for supply phase"
                    )

                // Combine routes from both phases
                routes.append(contentsOf: supplyPhaseRoutes)

                // Validate swap quote
                guard swapIntent.swapQuoteSellAmount > 0 else {
                    return .failure(.invalidSwapQuoteSellAmountIsZero)
                }

                let swapRate = calculateSwapRate(
                    swapIntent: swapIntent,
                    isMaxSell: swapIntent.sellAmount.isMaxUint256
                )
                let (swapMinFlow, swapMaxFlow) = calculateSwapFlowConstraints(
                    swapIntent: swapIntent,
                    isMaxSell: swapIntent.sellAmount.isMaxUint256
                )
                logger?
                    .log(
                        "SwapAndSupply - sellAmount: \(swapIntent.sellAmount), buyAmount: \(swapIntent.buyAmount), swapMinFlow: \(swapMinFlow), swapMaxFlow: \(swapMaxFlow)"
                    )

                let swapRoute = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                    type: .swap(
                        buyToken: swapIntent.buyToken,
                        buyAmount: swapIntent.buyAmount,
                        swapQuoteSellAmount: swapIntent.swapQuoteSellAmount,
                        swapQuoteBuyAmount: swapIntent.swapQuoteBuyAmount,
                        feeToken: swapIntent.feeToken,
                        feeAmount: swapIntent.feeAmount,
                        isExactOut: swapIntent.isExactOut,
                        isCappedMax: swapIntent.sellAmount.isMaxUint256
                    ),
                    source: sellTokenNode,
                    sink: buyTokenNodeOnSwapNetwork,
                    rate: swapRate,
                    minFlow: swapMinFlow,
                    maxFlow: swapMaxFlow
                )
                routes.append(swapRoute)

                // Route generation split into two phases:
                // Phase A (swap): Routes for sellToken ecosystem with swap's maxness
                // Phase B (supply): Routes for buyToken ecosystem with supply's maxness
                // This ensures bridges use the correct maxness for their supporting sub-intent

                // Target is the supply venue
                let target = Tradewinds.Target<TradewindsLegendNode>(
                    amount: .max,
                    node: supplyVenueNode
                )

                return .success((routes, resources, target))

            case .claimRewards(let claimRewardsIntent):
                let claimer = claimRewardsIntent.claimer
                let targetAssetSymbol = claimRewardsIntent.assetSymbol

                let rewardBalances = folio.getRewardBalances(
                    symbol: targetAssetSymbol,
                    wallet: claimer
                )

                if rewardBalances.isEmpty {
                    return .failure(.noClaimableRewardsFound(symbol: targetAssetSymbol))
                }

                let graphResult = buildRewardClaimGraph(
                    rewardBalances: rewardBalances, folio: folio, claimer: claimer
                )
                guard case .success(let (routes: claimRoutes, resources: resources, sinkNodes: sinkNodes)) = graphResult
                else {
                    return .failure(graphResult.asFailure)
                }

                var routes = claimRoutes
                let rewardSettlementNode = TradewindsLegendNode.rewardSettlement(wallet: claimer)
                for sinkNode in sinkNodes {
                    routes.append(
                        Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                            type: .rewardSettlement,
                            source: sinkNode,
                            sink: rewardSettlementNode,
                            rate: 1.0,
                            minFlow: Number(0),
                            maxFlow: Number.MAX_UINT_256
                        )
                    )
                }

                return .success(
                    (routes, resources, Tradewinds.Target(amount: .max, node: rewardSettlementNode))
                )

            case .compounder(let compounderIntent):
                // Compounder intent: Claims rewards, swaps them to a target token, and supplies to a market.
                // Supports multiple claim intents and multiple swap intents for flexible reward compounding.
                //
                // Constraints:
                // - Each swap's sell token must match a claimed reward's asset symbol
                // - All swap buy tokens must match the supply intent's asset symbol
                // - All rewards must be on the same chain as their corresponding swap
                // - Cross-chain supply requires bridgeable assets (USDC, ETH, WETH)
                //
                // Graph phases:
                // - Phase A: Claim rewards (from reward markets to token balances)
                // - Phase B: Swap claimed tokens (each swap converts rewards to supply asset)
                // - Phase C: Supply swapped tokens (bridges if cross-chain, then supply)
                let claimIntents = compounderIntent.claimRewardsIntents
                let swapIntents = compounderIntent.swapIntents
                let supplyIntent = compounderIntent.supplyIntent

                guard !claimIntents.isEmpty else {
                    return .failure(.error("Compounder requires at least one claim intent"))
                }
                guard !swapIntents.isEmpty else {
                    return .failure(.error("Compounder requires at least one swap intent"))
                }

                let supplyNetwork = Network.fromChainId(supplyIntent.chainId)
                let sender = claimIntents[0].claimer

                // Validate all senders match across claims, swaps, and supply
                let allSendersMatch = claimIntents.allSatisfy { $0.claimer == sender }
                    && swapIntents.allSatisfy { $0.sender.ethAddress == sender }
                    && supplyIntent.sender.ethAddress == sender
                guard allSendersMatch else {
                    return .failure(.compounderSenderMismatch)
                }

                guard supplyIntent.amount.isMaxUint256 else {
                    return .failure(.error("Compounder requires supply amount to be .max"))
                }

                guard
                    let supplyAsset = Atlas.getEvmAssetBySymbol(
                        network: supplyNetwork,
                        symbol: supplyIntent.assetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: supplyIntent.assetSymbol,
                            network: supplyNetwork,
                            address: nil
                        )
                    )
                }

                // SwapConfig captures validated swap parameters for graph construction
                struct SwapConfig {
                    let swapIntent: Charter.SwapIntent
                    let network: Network
                    let sellAsset: Atlas.EvmAsset
                    let buyAsset: Atlas.EvmAsset
                }

                // Validate each swap intent and build configs
                var swapConfigs: [SwapConfig] = []
                for swapIntent in swapIntents {
                    let swapNetwork = Network.fromChainId(swapIntent.chainId)

                    guard
                        let swapSellAsset = Atlas.getEvmAssetByAddress(
                            network: swapNetwork,
                            token: swapIntent.sellToken
                        )
                    else {
                        return .failure(
                            .unknownAsset(symbol: nil, network: swapNetwork, address: swapIntent.sellToken)
                        )
                    }

                    // Verify swap sell token matches a claimed reward asset
                    let hasMatchingClaim = claimIntents.contains { $0.assetSymbol.equalIgnoringCase(swapSellAsset.symbol) }
                    guard hasMatchingClaim else {
                        return .failure(
                            .compounderTokenMismatch(
                                expected: claimIntents.map { $0.assetSymbol }.joined(separator: ", "),
                                actual: swapSellAsset.symbol
                            )
                        )
                    }

                    guard
                        let swapBuyAsset = Atlas.getEvmAssetByAddress(
                            network: swapNetwork,
                            token: swapIntent.buyToken
                        )
                    else {
                        return .failure(
                            .unknownAsset(symbol: nil, network: swapNetwork, address: swapIntent.buyToken)
                        )
                    }

                    // Verify swap buy token matches supply asset
                    guard swapBuyAsset.symbol.equalIgnoringCase(supplyIntent.assetSymbol) else {
                        return .failure(
                            .compounderTokenMismatch(
                                expected: supplyIntent.assetSymbol,
                                actual: swapBuyAsset.symbol
                            )
                        )
                    }

                    guard swapIntent.swapQuoteSellAmount > 0 else {
                        return .failure(.invalidSwapQuoteSellAmountIsZero)
                    }

                    swapConfigs.append(SwapConfig(
                        swapIntent: swapIntent,
                        network: swapNetwork,
                        sellAsset: swapSellAsset,
                        buyAsset: swapBuyAsset
                    ))
                }

                // Cross-chain supply requires bridgeable assets
                let bridgeableSymbols: Set<String> = ["USDC", "ETH", "WETH"]
                for swapConfig in swapConfigs {
                    if swapConfig.network != supplyNetwork, !bridgeableSymbols.contains(swapConfig.buyAsset.symbol) {
                        return .failure(.error("Cross-chain compounding into \(supplyIntent.assetSymbol) is not supported. Only bridgeable assets (WETH, ETH, USDC) are supported for cross-chain supply."))
                    }
                }

                // Collect all reward balances for claimed asset symbols
                var allRewardBalances: [(rewardType: Folio.RewardType, amount: Amount)] = []
                for claimIntent in claimIntents {
                    let rewardBalances = folio.getRewardBalances(
                        symbol: claimIntent.assetSymbol,
                        wallet: sender
                    )
                    allRewardBalances.append(contentsOf: rewardBalances)
                }

                if allRewardBalances.isEmpty {
                    let symbols = claimIntents.map { $0.assetSymbol }.joined(separator: ", ")
                    return .failure(.noClaimableRewardsFound(symbol: symbols))
                }

                // Validate all rewards have a corresponding swap on the same chain
                let rewardNetworksBySymbol = Dictionary(grouping: allRewardBalances) {
                    $0.rewardType.underlyingSymbolAndNetwork.0
                }.mapValues { Set($0.map { $0.rewardType.underlyingSymbolAndNetwork.1 }) }

                let swapNetworksBySymbol = Dictionary(grouping: swapConfigs) {
                    $0.sellAsset.symbol
                }.mapValues { Set($0.map { $0.network }) }

                for (symbol, rewardNetworks) in rewardNetworksBySymbol {
                    guard let swapNetworks = swapNetworksBySymbol[symbol] else {
                        return .failure(.error("No swap intent found for claimed reward symbol: \(symbol)"))
                    }
                    for rewardNetwork in rewardNetworks {
                        if !swapNetworks.contains(rewardNetwork) {
                            return .failure(.error("All rewards must be on the same chain as their corresponding swap. Reward for \(symbol) on \(rewardNetwork.description) has no matching swap."))
                        }
                    }
                }

                // Phase A: Build claim routes from reward balances
                let graphResult = buildRewardClaimGraph(
                    rewardBalances: allRewardBalances, folio: folio, claimer: sender
                )
                guard case .success(let (routes: claimRoutes, resources: resources, sinkNodes: sinkNodes)) = graphResult
                else {
                    return .failure(graphResult.asFailure)
                }

                var routes = claimRoutes

                // Phase B: Build swap routes for each swap config
                var allSwapSellNodes: Set<TradewindsLegendNode> = []
                var allSwapBuyNodes: Set<TradewindsLegendNode> = []

                for swapConfig in swapConfigs {
                    let swapIntent = swapConfig.swapIntent
                    let swapNetwork = swapConfig.network

                    let swapSellTokenNode = TradewindsLegendNode.tokenBalance(
                        network: swapNetwork,
                        address: swapIntent.sellToken,
                        symbol: swapConfig.sellAsset.symbol,
                        wallet: sender
                    )
                    allSwapSellNodes.insert(swapSellTokenNode)

                    let swapBuyTokenNode = TradewindsLegendNode.tokenBalance(
                        network: swapNetwork,
                        address: swapIntent.buyToken,
                        symbol: swapConfig.buyAsset.symbol,
                        wallet: sender
                    )
                    allSwapBuyNodes.insert(swapBuyTokenNode)

                    let isMaxSell = swapIntent.sellAmount.isMaxUint256
                    let swapRate = calculateSwapRate(swapIntent: swapIntent, isMaxSell: isMaxSell)
                    let (swapMinFlow, swapMaxFlow) = calculateSwapFlowConstraints(
                        swapIntent: swapIntent,
                        isMaxSell: isMaxSell
                    )

                    routes.append(
                        makeLegendRoute(
                            type: .swap(
                                buyToken: swapIntent.buyToken,
                                buyAmount: swapIntent.buyAmount,
                                swapQuoteSellAmount: swapIntent.swapQuoteSellAmount,
                                swapQuoteBuyAmount: swapIntent.swapQuoteBuyAmount,
                                feeToken: swapIntent.feeToken,
                                feeAmount: swapIntent.feeAmount,
                                isExactOut: swapIntent.isExactOut,
                                isCappedMax: isMaxSell
                            ),
                            source: swapSellTokenNode,
                            sink: swapBuyTokenNode,
                            rate: swapRate,
                            minFlow: swapMinFlow,
                            maxFlow: swapMaxFlow,
                            folio: folio
                        )
                    )
                }

                // Generate routes to move claimed tokens to swap sell nodes
                var claimPhaseNodes = sinkNodes
                claimPhaseNodes.formUnion(allSwapSellNodes)

                let claimPhaseRoutes = generateRoutes(
                    nodes: Array(claimPhaseNodes),
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: sender,
                    cappedMaxNodes: [],
                    logger: logger
                )
                routes.append(contentsOf: claimPhaseRoutes)

                // Phase C: Build supply routes from swap outputs to supply venue
                // Start with swap buy nodes, then add destination nodes on supply network if bridging is needed
                var buyTokenNodes = allSwapBuyNodes
                let requiresBridgeToSupply = swapConfigs.contains { $0.network != supplyNetwork }
                if requiresBridgeToSupply {
                    for symbol in folio.getRelevantSymbols(network: supplyNetwork, assetSymbol: supplyAsset.symbol) {
                        if let asset = Atlas.getEvmAssetBySymbol(network: supplyNetwork, symbol: symbol) {
                            buyTokenNodes.insert(.tokenBalance(
                                network: supplyNetwork,
                                address: asset.assetAddress,
                                symbol: symbol,
                                wallet: sender
                            ))
                        }
                    }
                }

                let supplyVenueNode = makeSupplyVenueNode(supplyIntent: supplyIntent, baseAsset: supplyAsset.assetAddress)

                // Generate supply phase routes (buyToken → supplyVenue)
                let supplyPhaseNodes = Array(buyTokenNodes) + [supplyVenueNode]
                let supplyRoutes = generateRoutes(
                    nodes: supplyPhaseNodes,
                    folio: folio,
                    userWallets: folio.getRelevantWallets(),
                    actorWallet: sender,
                    cappedMaxNodes: supplyIntent.amount.isMaxUint256 ? Set(supplyPhaseNodes) : Set(),
                    logger: logger
                )
                routes.append(contentsOf: supplyRoutes)

                // Target is the supply venue with max amount
                return .success((
                    routes,
                    resources,
                    Tradewinds.Target(amount: .max, node: supplyVenueNode)
                ))

            default:
                return .failure(.error("Unsupported intent type"))
        }

    }

    public func tradewindsCostFn(
        resources: [Tradewinds.Resource<TradewindsLegendNode>],
        target: Tradewinds.Target<TradewindsLegendNode>
    ) -> Tradewinds.CostFunction<TradewindsLegendNode, LegendRouteType> {
        // Calculate targetAmount for cost function:
        // - For exact amounts, use that amount
        // - For .max targets, sum all available resources as an estimate
        let targetAmount: Number
        switch target.amount {
            case .exact(let amount):
                targetAmount = amount
            case .max:
                // Sum all available resources to estimate total flow
                // Note: Resources with .max should never exist - they're converted to .exact(folioBalance)
                // during resource creation. If we encounter one, skip it to avoid adding nonsensical values.
                let sum = resources.reduce(Number(0)) { accumulator, resource in
                    switch resource.amount {
                        case .exact(let amount):
                            return accumulator + amount
                        case .max:
                            // Skip resources with .max (shouldn't exist, but handle defensively)
                            return accumulator
                    }
                }
                // If all resources were .max or no resources (edge case), use 1 to avoid division by zero
                targetAmount = sum > Number(0) ? sum : Number(1)
        }

        let baseFunction: Tradewinds.CostFunction<TradewindsLegendNode, LegendRouteType> =
            Tradewinds.dualFeeCostFunction(targetAmount: targetAmount)
        return { route in
            let baseCost = baseFunction(route) ?? 0

            // Add penalty for withdrawing from earning positions
            switch route.type {
                case .cometWithdraw, .morphoVaultWithdraw, .aaveWithdraw:
                    return baseCost + 0.001
                default:
                    return baseCost
            }
        }
    }

    private func calculateSwapRate(swapIntent: Charter.SwapIntent, isMaxSell: Bool)
        -> Percentage
    {
        // For max-sell swaps, derive rate from the quoted amounts to avoid
        // zero-rate when sellAmount is MAX_UINT256. Otherwise, use the
        // user-provided amounts to preserve exact-in/out semantics.
        let baseRate: Percentage
        if isMaxSell {
            baseRate = Percentage(
                fromRatio: swapIntent.swapQuoteBuyAmount.asSNumber,
                over: swapIntent.swapQuoteSellAmount.asSNumber
            )
        } else {
            baseRate = Percentage(
                fromRatio: swapIntent.buyAmount.asSNumber,
                over: swapIntent.sellAmount.asSNumber
            )
        }

        // Apply SWAP_OUTPUT_BUFFER for max exact-in swaps to account for potential favorable slippage.
        // Swaps can see small price improvements from market conditions.
        // This ensures downstream capped-max operations can utilize the full output amount.
        // Note: Only affects Tradewinds flow propagation for downstream operations.
        // The actual on-chain swap call data (buyAmount parameter) remains unchanged.
        // Exact-out swaps are excluded because output is guaranteed at exact buyAmount.
        if isMaxSell && !swapIntent.isExactOut {
            return baseRate * Charter.SWAP_OUTPUT_BUFFER
        }

        return baseRate
    }
    private func calculateSwapFlowConstraints(
        swapIntent: Charter.SwapIntent,
        isMaxSell: Bool
    ) -> (minFlow: Number, maxFlow: Number) {
        // Set route flow constraints based on exact-in vs exact-out vs max
        if isMaxSell {
            // Max swap: allow any amount, let Tradewinds decide optimal amount from available sources
            return (minFlow: Number(0), maxFlow: Number.MAX_UINT_256)
        } else if swapIntent.isExactOut {
            // Exact-out: allow any amount up to sellAmount
            return (minFlow: Number(0), maxFlow: swapIntent.sellAmount)
        } else {
            // Exact-in: enforce exact sellAmount through route (like exact withdrawals)
            return (minFlow: swapIntent.sellAmount, maxFlow: swapIntent.sellAmount)
        }
    }

    func generateBalances(folio: Folio, network: Network, assetSymbols: Set<String>) -> [Tradewinds
        .Resource<TradewindsLegendNode>]
    {
        return folio.balances.compactMap {
            type,
            balance -> Tradewinds.Resource<TradewindsLegendNode>? in
            if case .token(let balanceNetwork, let symbol, let wallet) = type,
                balanceNetwork == network,
                assetSymbols.contains(symbol),
                let asset = Atlas.getEvmAssetBySymbol(network: balanceNetwork, symbol: symbol)
            {
                return Tradewinds.Resource(
                    amount: .exact(balance.underlying),
                    node: .tokenBalance(
                        network: balanceNetwork,
                        address: asset.assetAddress,
                        symbol: symbol,
                        wallet: wallet
                    )
                )
            }
            return nil
        }
    }

    func generateRelevantBalances(folio: Folio, network: Network, assetSymbol: String)
        -> [Tradewinds.Resource<TradewindsLegendNode>]
    {
        let relevantSymbols = folio.getRelevantSymbols(network: network, assetSymbol: assetSymbol)
        return generateBalances(folio: folio, network: network, assetSymbols: relevantSymbols)
    }
}
