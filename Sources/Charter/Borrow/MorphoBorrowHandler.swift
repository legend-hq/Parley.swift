import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

// MARK: - MorphoBorrowHandler

struct MorphoBorrowHandler: BorrowIntentHandler {
    typealias BorrowIntent = Charter.MorphoBorrowIntent

    func getBorrower(from intent: BorrowIntent) -> EthAddress {
        intent.borrower.ethAddress
    }

    func getBorrowAmount(from intent: BorrowIntent) -> Number {
        intent.amount
    }

    func getBorrowAssetSymbol(from intent: BorrowIntent) -> String {
        intent.assetSymbol
    }

    func getCollateralAmount(from intent: BorrowIntent) -> Number? {
        intent.collateralAmount
    }

    func getCollateralAssetSymbol(from intent: BorrowIntent) -> String? {
        intent.collateralAssetSymbol
    }

    func getChainId(from intent: BorrowIntent) -> Number {
        intent.chainId
    }

    func getIsCappedMaxSupply(from intent: BorrowIntent) -> Bool {
        intent.isMaxIntent
    }

    func getIsMaxBorrow(from intent: BorrowIntent) -> Bool {
        intent.amount.isMaxUint256
    }

    func createCollateralNode(
        network: Network,
        collateralAsset: EthAddress,
        wallet: EthAddress,
        intent: BorrowIntent
    ) -> TradewindsLegendNode {
        .morphoCollateralBalance(
            network: network,
            marketId: intent.marketId,
            collateralAsset: collateralAsset,
            wallet: wallet
        )
    }

    func createBorrowRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        borrowAmount: Number,
        borrowAsset: EthAddress
    ) -> LegendRouteType {
        .morphoBorrow(asset: borrowAsset, amount: borrowAmount)
    }

    func createSupplyCollateralRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode
    ) -> LegendRouteType {
        .morphoSupplyCollateral(isCappedMax: false)
    }

    func createSupplyAndBorrowRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        borrowAmount: Number,
        borrowAsset: EthAddress,
        isCappedMaxSupply: Bool
    ) -> LegendRouteType {
        .morphoSupplyCollateralAndBorrow(
            borrowAsset: borrowAsset,
            borrowAmount: borrowAmount,
            isCappedMaxSupply: isCappedMaxSupply
        )
    }

    func queryExistingCollateral(
        intent: BorrowIntent,
        borrower: EthAddress,
        folio: Folio
    ) -> [Tradewinds.Resource<TradewindsLegendNode>] {
        var resources: [Tradewinds.Resource<TradewindsLegendNode>] = []
        let network = Network.fromChainId(intent.chainId)
        let borrowSymbol = intent.assetSymbol

        // Look up the Morpho market in Atlas to find the collateral token
        guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: intent.marketId)
        else {
            return resources
        }

        // Find the collateral asset by matching the address
        guard
            let collateralAsset = Atlas.getEvmAssetByAddress(
                network: network,
                token: morphoMarket.collateralToken
            )
        else {
            return resources
        }

        // Look for the collateral balance in folio
        let balanceKey = Folio.BalanceType.borrowMarketCollateral(
            borrowMarket: .morpho(
                network: network,
                collateralTokenSymbol: collateralAsset.symbol,
                borrowTokenSymbol: borrowSymbol
            ),
            tokenSymbol: collateralAsset.symbol,
            wallet: borrower
        )

        if let balance = folio.balances[balanceKey] {
            let resource = Tradewinds.Resource(
                amount: .exact(balance.underlying),
                node: TradewindsLegendNode.morphoCollateralBalance(
                    network: network,
                    marketId: intent.marketId,
                    collateralAsset: morphoMarket.collateralToken,
                    wallet: borrower
                )
            )
            resources.append(resource)
        }

        return resources
    }

    /// Calculates the user's available borrow capacity based on their collateral position.
    ///
    /// Morpho uses LLTV (Liquidation Loan-To-Value) as the borrow limit:
    /// ```
    /// collateralValue = collateralBalance × collateralPrice
    /// borrowCapacityValue = collateralValue × lltv
    /// safeBorrowCapacityValue = borrowCapacityValue × safetyCap (98%)
    /// safeBorrowCapacity = safeBorrowCapacityValue / borrowAssetPrice
    /// availableBorrowCapacity = safeBorrowCapacity - existingBorrowAmount
    /// ```
    /// The safety cap prevents users from borrowing exactly at the liquidation limit.
    func queryBorrowCapacity(
        intent: BorrowIntent,
        borrower: EthAddress,
        borrowAsset: EthAddress,
        folio: Folio
    ) -> Result<Tradewinds.Resource<TradewindsLegendNode>, Charter.CharterError> {
        let network = Network.fromChainId(intent.chainId)

        guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: intent.marketId) else {
            return .failure(.morphoMarketNotFound(marketId: intent.marketId, network: network))
        }

        guard let borrowAssetInfo = Atlas.getEvmAssetByAddress(network: network, token: borrowAsset) else {
            return .failure(.unknownAsset(symbol: intent.assetSymbol, network: network, address: borrowAsset))
        }

        guard let borrowAssetPrice = folio.prices[.token(symbol: borrowAssetInfo.symbol)] else {
            return .failure(.unpricedAsset(symbol: borrowAssetInfo.symbol))
        }

        guard !borrowAssetPrice.isZero else {
            return .failure(.unpricedAsset(symbol: borrowAssetInfo.symbol))
        }

        guard let collateralAssetInfo = Atlas.getEvmAssetByAddress(network: network, token: morphoMarket.collateralToken) else {
            return .failure(.unknownAsset(symbol: "unknown", network: network, address: morphoMarket.collateralToken))
        }

        let balanceKey = Folio.BalanceType.borrowMarketCollateral(
            borrowMarket: .morpho(
                network: network,
                collateralTokenSymbol: collateralAssetInfo.symbol,
                borrowTokenSymbol: intent.assetSymbol
            ),
            tokenSymbol: collateralAssetInfo.symbol,
            wallet: borrower
        )

        guard let collateralBalance = folio.balances[balanceKey], !collateralBalance.isZero else {
            return .failure(.noCollateralInBorrowMarket(network: network))
        }

        guard let collateralPrice = folio.prices[.token(symbol: collateralAssetInfo.symbol)] else {
            return .failure(.unpricedAsset(symbol: collateralAssetInfo.symbol))
        }

        let lltv = Percentage(underlying: SNumber(morphoMarket.lltv))
        let collateralValue = collateralBalance * collateralPrice
        let borrowCapacityValue = collateralValue * lltv
        let safeBorrowCapacityValue = borrowCapacityValue * borrowCapacitySafetyCap
        let safeBorrowCapacity = safeBorrowCapacityValue.toTokenAmount(
            price: borrowAssetPrice,
            decimals: Int(borrowAssetInfo.decimals)
        )

        let existingBorrowAmount = folio.getMorphoBorrowBalance(
            network: network,
            collateralTokenSymbol: collateralAssetInfo.symbol,
            borrowTokenSymbol: intent.assetSymbol,
            wallet: borrower
        )?.underlying ?? Number.zero
        let availableBorrowCapacity = safeBorrowCapacity.underlying > existingBorrowAmount
            ? safeBorrowCapacity.underlying - existingBorrowAmount
            : Number.zero

        return .success(Tradewinds.Resource(
            amount: .exact(availableBorrowCapacity),
            node: .morphoBorrowCapacity(
                network: network,
                marketId: intent.marketId,
                borrowAsset: borrowAsset,
                wallet: borrower
            )
        ))
    }

    func validateIntent(_ intent: BorrowIntent, folio: Folio) -> Bool {
        let network = Network.fromChainId(intent.chainId)

        guard Atlas.getEvmAssetBySymbol(network: network, symbol: intent.assetSymbol) != nil else {
            return false
        }

        if !intent.collateralAssetSymbol.isEmpty {
            guard Atlas.getEvmAssetBySymbol(network: network, symbol: intent.collateralAssetSymbol) != nil else {
                return false
            }
        }

        guard Atlas.getMorphoMarket(network: network, marketId: intent.marketId) != nil else {
            return false
        }

        return true
    }
}
