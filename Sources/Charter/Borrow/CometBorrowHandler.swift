import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

// MARK: - CometBorrowHandler

struct CometBorrowHandler: BorrowIntentHandler {
    typealias BorrowIntent = Charter.CometBorrowIntent

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
        .cometCollateralBalance(
            network: network,
            comet: intent.comet,
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
        .cometBorrow(asset: borrowAsset, amount: borrowAmount)
    }

    func createSupplyCollateralRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode
    ) -> LegendRouteType {
        .cometSupplyCollateral(isCappedMax: false)
    }

    func createSupplyAndBorrowRoute(
        from: TradewindsLegendNode,
        to: TradewindsLegendNode,
        borrowAmount: Number,
        borrowAsset: EthAddress,
        isCappedMaxSupply: Bool
    ) -> LegendRouteType {
        .cometSupplyCollateralAndBorrow(
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
        let network = Network.fromChainId(intent.chainId)

        // Verify the comet exists in Atlas
        guard Atlas.getCometMarket(network: network, comet: intent.comet) != nil else {
            return []
        }

        return
            folio.getCometCollateralBalances(
                network: network,
                comet: intent.comet,
                wallet: borrower
            )
            .compactMap { tokenSymbol, balance in
                // Get the collateral asset to get its address
                guard
                    let collateralAsset = Atlas.getEvmAssetBySymbol(
                        network: network,
                        symbol: tokenSymbol
                    )
                else {
                    return nil
                }
                return Tradewinds.Resource(
                    amount: .exact(balance.underlying),
                    node: TradewindsLegendNode.cometCollateralBalance(
                        network: network,
                        comet: intent.comet,
                        collateralAsset: collateralAsset.assetAddress,
                        wallet: borrower
                    )
                )
            }
    }

    /// Calculates the user's available borrow capacity based on their collateral positions.
    ///
    /// For each collateral asset in the Comet market:
    /// ```
    /// collateralValue = collateralBalance × collateralUsdPrice
    /// borrowCapacityValue += collateralValue × liquidateCollateralFactor
    /// ```
    /// Then apply safety cap, convert to borrow asset terms, and subtract existing borrows:
    /// ```
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

        let nonZeroCollateralBalances =
            folio.getCometCollateralBalances(
                network: network,
                comet: intent.comet,
                wallet: borrower
            )
            .filter { !$0.balance.isZero }

        guard !nonZeroCollateralBalances.isEmpty else {
            return .failure(.noCollateralInBorrowMarket(network: network))
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

        let borrowMarketKey = Folio.BorrowMarketType.comet(
            network: network,
            comet: intent.comet,
            underlyingSymbol: borrowAssetInfo.symbol
        )

        guard let borrowMarket = folio.borrowMarkets[borrowMarketKey] else {
            return .failure(.cometMarketNotFound(comet: intent.comet, network: network))
        }

        let borrowCapacityValue = nonZeroCollateralBalances.reduce(Value.zero) { total, item in
            guard let collateral = borrowMarket.collaterals[item.tokenSymbol] else {
                return total
            }
            let collateralValue = item.balance * collateral.usdPrice
            return total + collateralValue * collateral.liquidateCollateralFactor
        }

        guard !borrowCapacityValue.isZero else {
            return .failure(.noCollateralInBorrowMarket(network: network))
        }

        let safeBorrowCapacityValue = borrowCapacityValue * borrowCapacitySafetyCap
        let safeBorrowCapacity = safeBorrowCapacityValue.toTokenAmount(
            price: borrowAssetPrice,
            decimals: Int(borrowAssetInfo.decimals)
        )

        let existingBorrowAmount =
            folio.getCometBorrowBalance(
                network: network,
                comet: intent.comet,
                underlyingSymbol: borrowAssetInfo.symbol,
                wallet: borrower
            )?
            .underlying ?? Number.zero
        let availableBorrowCapacity =
            safeBorrowCapacity.underlying > existingBorrowAmount
            ? safeBorrowCapacity.underlying - existingBorrowAmount
            : Number.zero

        return .success(Tradewinds.Resource(
                amount: .exact(availableBorrowCapacity),
            node: .cometBorrowCapacity(
                network: network,
                comet: intent.comet,
                borrowAsset: borrowAsset,
                wallet: borrower
            )
        ))
    }

    // MARK: - Additional Validation

    func validateIntent(_ intent: BorrowIntent, folio: Folio) -> Bool {
        let network = Network.fromChainId(intent.chainId)

        // Validate the borrow asset exists
        guard Atlas.getEvmAssetBySymbol(network: network, symbol: intent.assetSymbol) != nil else {
            return false
        }

        // Validate collateral asset if specified
        if !intent.collateralAssetSymbol.isEmpty {
            guard Atlas.getEvmAssetBySymbol(network: network, symbol: intent.collateralAssetSymbol) != nil else {
                return false
            }
        }

        // Verify the comet market exists
        guard Atlas.getCometMarket(network: network, comet: intent.comet) != nil else {
            return false
        }

        return true
    }
}
