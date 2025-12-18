import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

// MARK: - MorphoRepayHandler

struct MorphoRepayHandler: RepayIntentHandler {
    typealias RepayIntent = Charter.MorphoRepayIntent

    // MARK: - Core Intent Accessors

    func getRepayer(from intent: RepayIntent) -> EthAddress {
        intent.repayer
    }

    func getRepayAmount(from intent: RepayIntent) -> Number {
        intent.amount
    }

    func getRepayAssetSymbol(from intent: RepayIntent) -> String {
        intent.assetSymbol
    }

    func getChainId(from intent: RepayIntent) -> Number {
        intent.chainId
    }

    func getIsMaxIntent(from intent: RepayIntent) -> Bool {
        intent.isMaxIntent
    }

    // MARK: - Collateral Withdrawal Accessors

    func getCollateralAmounts(from intent: RepayIntent) -> [Number] {
        // MorphoRepayIntent has singular collateral, return as array for protocol compatibility
        intent.collateralAmount > Number(0) ? [intent.collateralAmount] : []
    }

    func getCollateralAssetSymbols(from intent: RepayIntent) -> [String] {
        // MorphoRepayIntent has singular collateral, return as array for protocol compatibility
        !intent.collateralAssetSymbol.isEmpty ? [intent.collateralAssetSymbol] : []
    }

    // MARK: - Node Creation

    func createBorrowPositionNode(
        network: Network,
        borrowAsset: EthAddress,
        wallet: EthAddress,
        intent: RepayIntent
    ) -> TradewindsLegendNode {
        .morphoBorrowPosition(
            network: network,
            marketId: intent.marketId,
            borrowAsset: borrowAsset,
            wallet: wallet
        )
    }

    func createCollateralNode(
        network: Network,
        collateralAsset: EthAddress,
        wallet: EthAddress,
        intent: RepayIntent
    ) -> TradewindsLegendNode {
        .morphoCollateralBalance(
            network: network,
            marketId: intent.marketId,
            collateralAsset: collateralAsset,
            wallet: wallet
        )
    }

    // MARK: - Route Creation

    func createRepayRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        isMax: Bool
    ) -> LegendRouteType {
        return .morphoRepay(isMax: isMax)
    }

    func createWithdrawCollateralRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        isMax: Bool
    ) -> LegendRouteType {
        .morphoWithdrawCollateral(isMax: isMax)
    }

    // MARK: - Position Queries

    func queryExistingDebt(
        intent: RepayIntent,
        repayer: EthAddress,
        folio: Folio
    ) -> Number {
        let network = Network.fromChainId(intent.chainId)
        let borrowKey = Folio.BalanceType.borrowMarket(
            borrowMarket: .morpho(
                network: network,
                collateralTokenSymbol: intent.collateralAssetSymbol,
                borrowTokenSymbol: intent.assetSymbol
            ),
            wallet: repayer
        )
        return folio.balances[borrowKey]?.underlying ?? Number(0)
    }

    func queryExistingCollateral(
        intent: RepayIntent,
        repayer: EthAddress,
        folio: Folio
    ) -> [Tradewinds.Resource<TradewindsLegendNode>] {
        var resources: [Tradewinds.Resource<TradewindsLegendNode>] = []
        let network = Network.fromChainId(intent.chainId)
        let requestedCollateralSymbol = intent.collateralAssetSymbol

        // Verify the market exists in Atlas
        guard let networkType = Atlas.getNetwork(network: network),
            let _ = networkType.getMorphoMarketByMarketId(intent.marketId)
        else {
            return resources
        }

        // Iterate through all balances to find collateral positions
        for (balanceType, balance) in folio.balances {
            guard
                case .borrowMarketCollateral(let borrowMarket, let tokenSymbol, let wallet) =
                    balanceType,
                case .morpho(let balanceNetwork, let collateralSymbol, let borrowSymbol) =
                    borrowMarket,
                balanceNetwork == network,
                collateralSymbol == intent.collateralAssetSymbol,
                borrowSymbol == intent.assetSymbol,
                wallet == repayer
            else {
                continue
            }

            // If specific collateral is requested, filter by it
            if !requestedCollateralSymbol.isEmpty && tokenSymbol != requestedCollateralSymbol {
                continue
            }

            // Get the collateral asset to get its address
            guard
                let collateralAsset = Atlas.getAssetBySymbol(network: network, symbol: tokenSymbol)
            else {
                continue
            }

            let resource = Tradewinds.Resource(
                amount: .exact(balance.underlying),
                node: createCollateralNode(
                    network: network,
                    collateralAsset: collateralAsset.assetAddress,
                    wallet: repayer,
                    intent: intent
                )
            )
            resources.append(resource)
        }

        return resources
    }

    // MARK: - Validation

    func validateIntent(_ intent: RepayIntent, folio: Folio) -> Result<Void, Charter.CharterError> {
        let network = Network.fromChainId(intent.chainId)

        // Validate the borrow asset exists
        guard Atlas.getAssetBySymbol(network: network, symbol: intent.assetSymbol) != nil else {
            return .failure(
                .unknownAsset(symbol: intent.assetSymbol, network: network, address: nil))
        }

        // Validate collateral asset if specified
        if !intent.collateralAssetSymbol.isEmpty {
            guard
                Atlas.getAssetBySymbol(network: network, symbol: intent.collateralAssetSymbol)
                    != nil
            else {
                return .failure(
                    .unknownAsset(
                        symbol: intent.collateralAssetSymbol,
                        network: network,
                        address: nil
                    ))
            }
        }

        // Verify the Morpho market exists
        guard let networkType = Atlas.getNetwork(network: network),
            let _ = networkType.getMorphoMarketByMarketId(intent.marketId)
        else {
            return .failure(.morphoMarketNotFound(marketId: intent.marketId, network: network))
        }

        // Check for repay amount exceeding debt (only for non-max intents)
        if !getIsMaxIntent(from: intent) {
            let existingDebt = queryExistingDebt(
                intent: intent,
                repayer: intent.repayer,
                folio: folio
            )
            if existingDebt > Number(0) && intent.amount > existingDebt {
                return .failure(
                    .repayAmountExceedsDebt(
                        network: network,
                        repayAsset: intent.assetSymbol,
                        repayAmount: Amount(intent.amount, decimals: 0),
                        existingDebt: Amount(existingDebt, decimals: 0)
                    )
                )
            }
        }

        return .success(())
    }

    // No override needed - the default implementation in RepayIntentHandler follows
    // the BorrowHandler pattern: generate routes, then transform them to combined operations.
    // This maintains single commodity flow while avoiding crashes.
}
