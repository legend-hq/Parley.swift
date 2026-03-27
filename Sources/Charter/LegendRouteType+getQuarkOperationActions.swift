import Atlas
import Eth
import Prelude
import SwiftNumber
import Tradewinds

enum TokenSource {
    case source
    case sink
    case none
}

extension Tradewinds.Flow<TradewindsLegendNode, LegendRouteType> {
    // Amount after deducting IN-fees from the flow amount.
    // Use for operations pulling from wallet balances (transfers, bridges, supplies, repays).
    // For withdrawals from earning markets, use `amount` instead (fees paid separately).
    // See LegendRouteType.swift for detailed fee handling explanation.
    var amountLessInFee: Number {
        let totalInFees = self.route.totalInFees
        return self.amount - totalInFees
    }

    var quotePayInFees: Number {
        self.route.fees
            .filter { fee in fee.type == .quotePay && fee.isInFee }
            .reduce(Number(0)) { $0 + $1.amount }
    }

    var quotePayFees: Number {
        self.route.fees
            .filter { fee in fee.type == .quotePay }
            .reduce(Number(0)) { $0 + $1.amount }
    }

    var tokenSource: TokenSource {
        if case .tokenBalance(_, _, _, _) = self.route.source {
            return .source
        } else if case .tokenBalance(_, _, _, _) = self.route.sink {
            return .sink
        } else {
            return .none
        }
    }

    var feeAsset: Result<Atlas.EvmAsset, Charter.CharterError> {
        switch self.tokenSource {
            case .source:
                return self.route.source.asAtlasAsset
            case .sink:
                return self.route.sink.asAtlasAsset
            default:
                return .failure(.error("No token source"))
        }
    }

    // Gets the quark operations assocated with a flow, based largely on the `LegendRouteType` (including quote pays)
    public func getQuarkOperationDetails(
        folio: Folio,
        blockTimestamp: Number,
        isCappedMax: Bool,
        displayInfo: DisplayInfo?,
        logger: Charter.Logger?
    ) -> Result<
        [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
    > {
        let baseOperationDetails = self.getFlowBaseOperationDetails(
            folio: folio,
            blockTimestamp: blockTimestamp,
            isCappedMax: isCappedMax,
            displayInfo: displayInfo,
            logger: logger
        )

        let quotePayOperationDetails = self.getFlowQuotePayOperationDetails(
            folio: folio,
            blockTimestamp: blockTimestamp,
            isCappedMax: isCappedMax,
            logger: logger
        )

        switch (baseOperationDetails, quotePayOperationDetails) {
            case (.success(let baseOperationDetails), .success(let quotePayOperationDetails)):
                switch self.tokenSource {
                    case .source:
                        return .success(quotePayOperationDetails + baseOperationDetails)
                    case .sink:
                        return .success(baseOperationDetails + quotePayOperationDetails)
                    default:
                        return .success(baseOperationDetails)
                }
            case (.failure(let err), _):
                return .failure(err)
            case (_, .failure(let err)):
                return .failure(err)
        }
    }

    // Gets the quark operations assocated with a flow, based largely on the `LegendRouteType` (less quote pays)
    public func getFlowQuotePayOperationDetails(
        folio: Folio,
        blockTimestamp: Number,
        isCappedMax: Bool,
        logger: Charter.Logger?
    ) -> Result<[Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError> {
        if self.quotePayFees > .zero {
            let asset: Atlas.EvmAsset
            switch self.feeAsset {
                case .success(let asset_):
                    asset = asset_
                case .failure(let failure):
                    return .failure(failure)
            }
            guard let assetPrice = folio.getAssetPrice(symbol: asset.symbol) else {
                return .failure(.unpricedAsset(symbol: asset.symbol))
            }
            let quotePayAmount = Amount(self.quotePayFees, decimals: Int(asset.decimals))
            // TODO: Consider better approach to quotes here
            guard let quoteId = folio.getQuoteId(symbol: asset.symbol) else {
                return .failure(.error("No quote id found for asset: \(asset.symbol) in folio"))
            }

            guard let sourceNetwork = self.route.source.network else {
                return .failure(.invalidNode)
            }

            let quotePayOperationDetails = Charter.QuarkOperationBuilder.quotePay(
                network: sourceNetwork,
                asset: asset,
                assetPrice: assetPrice.underlying,
                quotePayAmount: quotePayAmount,
                quoteId: quoteId
            )
            switch quotePayOperationDetails {
                case .success(let quotePayOperationDetails):
                    return .success(quotePayOperationDetails)
                case .failure(let err):
                    return .failure(err)
            }
        } else {
            return .success([])
        }
    }

    // Gets the quark operations assocated with a flow, based largely on the `LegendRouteType` (less quote pays)
    public func getFlowBaseOperationDetails(
        folio: Folio,
        blockTimestamp: Number,
        isCappedMax: Bool,
        displayInfo: DisplayInfo?,
        logger: Charter.Logger?
    ) -> Result<
        [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
    > {
        let sourceNetworkRes: Result<Network, Charter.CharterError>
        if let sourceNetwork = self.route.source.network {
            sourceNetworkRes = .success(sourceNetwork)
        } else {
            sourceNetworkRes = .failure(.invalidNode)
        }

        let sourceWalletRes: Result<EthAddress, Charter.CharterError>
        if let sourceWallet = self.route.source.wallet {
            sourceWalletRes = .success(sourceWallet)
        } else {
            sourceWalletRes = .failure(.invalidNode)
        }

        let sinkNetworkRes: Result<Network, Charter.CharterError>
        if let sinkNetwork = self.route.sink.network {
            sinkNetworkRes = .success(sinkNetwork)
        } else {
            sinkNetworkRes = .failure(.invalidNode)
        }

        let sinkWalletRes: Result<EthAddress, Charter.CharterError>
        if let sinkWallet = self.route.sink.wallet {
            sinkWalletRes = .success(sinkWallet)
        } else {
            sinkWalletRes = .failure(.invalidNode)
        }

        switch self.route.type {
            case .tokenTransfer, .transferOut:
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                guard case .success(let sinkWallet) = sinkWalletRes else {
                    return .failure(sinkWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                return Charter.QuarkOperationBuilder.transfer(
                    network: sourceNetwork,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amountLessInFee, decimals: Int(asset.decimals)),
                    isCappedMax: isCappedMax,
                    sender: sourceWallet,
                    recipient: sinkWallet
                )
            case .bridge(let bridgeType, let bridgeIsCappedMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                guard case .success(let sinkWallet) = sinkWalletRes else {
                    return .failure(sinkWalletRes.asFailure)
                }

                let srcAsset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): srcAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                // For both Across and CCTP v2: sink is always tokenBalance
                guard let destNetwork = self.route.sink.network else {
                    return .failure(.invalidNode)
                }

                let destAsset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): destAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: srcAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: srcAsset.symbol))
                }

                // Dispatch to appropriate bridge handler based on bridge type
                switch bridgeType {
                    case .across:
                        return Charter.QuarkOperationBuilder.bridgeAcrossAsset(
                            srcNetwork: sourceNetwork,
                            srcAsset: srcAsset,
                            destNetwork: destNetwork,
                            destAsset: destAsset,
                            rate: route.rate,
                            assetPrice: price,
                            inputAmount: Amount(self.amountLessInFee, decimals: Int(srcAsset.decimals)),
                            outputAmount: Amount(self.sinkAmount, decimals: Int(srcAsset.decimals)),
                            sender: sourceWallet,
                            recipient: sinkWallet,
                            isMaxBridge: bridgeIsCappedMax,
                            blockTimestamp: blockTimestamp
                        )

                    case .cctpV2:
                        // Emit both burn and mint operations from the collapsed bridge route
                        let burnOps = Charter.QuarkOperationBuilder.bridgeCCTPv2(
                            srcNetwork: sourceNetwork,
                            srcAsset: srcAsset,
                            destNetwork: destNetwork,
                            destAsset: destAsset,
                            rate: route.rate,
                            assetPrice: price,
                            inputAmount: Amount(self.amountLessInFee, decimals: Int(srcAsset.decimals)),
                            outputAmount: Amount(self.sinkAmount, decimals: Int(destAsset.decimals)),
                            sender: sourceWallet,
                            recipient: sinkWallet,
                            isMaxBridge: bridgeIsCappedMax
                        )
                        let mintOps = Charter.QuarkOperationBuilder.bridgeMint(
                            srcNetwork: sourceNetwork,
                            destNetwork: destNetwork,
                            destAsset: destAsset,
                            inputAmount: Amount(self.amountLessInFee, decimals: Int(destAsset.decimals)),
                            outputAmount: Amount(self.sinkAmount, decimals: Int(destAsset.decimals)),
                            recipient: sinkWallet,
                            bridgeType: .cctpV2
                        )
                        // Combine burn + mint
                        return burnOps.flatMap { b in mintOps.map { m in b + m } }

                    case .cctpV1, .unknown:
                        return .failure(.error("Unsupported bridge type: \(bridgeType)"))
                }

            case .wrap, .unwrap:
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let srcAsset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): srcAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                let destAsset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): destAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: srcAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: srcAsset.symbol))
                }

                let amount = Amount(self.amountLessInFee, decimals: Int(srcAsset.decimals))

                // Call the appropriate function based on the route type
                if case .wrap = self.route.type {
                    return Charter.QuarkOperationBuilder.wrapSimple(
                        network: sourceNetwork,
                        sourceAsset: srcAsset,
                        destAsset: destAsset,
                        price: price.underlying,
                        amount: amount,
                        sender: sourceWallet
                    )
                } else {
                    return Charter.QuarkOperationBuilder.unwrapSimple(
                        network: sourceNetwork,
                        sourceAsset: srcAsset,
                        destAsset: destAsset,
                        price: price.underlying,
                        amount: amount,
                        sender: sourceWallet
                    )
                }

            case .swap(
                _,
                let buyAmount,
                let swapQuoteSellAmount,
                _,
                let feeToken,
                let feeAmount,
                let isExactOut,
                let isCappedMax,
                _  // venue
            ):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let sellAsset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): sellAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                let buyAsset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): buyAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                // Get prices
                guard let sellPrice = folio.getAssetPrice(symbol: sellAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: sellAsset.symbol))
                }

                guard let buyPrice = folio.getAssetPrice(symbol: buyAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: buyAsset.symbol))
                }

                // Determine fee asset decimals based on feeToken
                let feeAsset: Atlas.EvmAsset
                if feeToken == sellAsset.assetAddress {
                    feeAsset = sellAsset
                } else if feeToken == buyAsset.assetAddress {
                    feeAsset = buyAsset
                } else {
                    return .failure(.error("Fee asset not supported: \(feeToken)"))
                }

                // Prorate buyAmount/feeAmount based on actual sell amount vs quoted sell amount.
                // This handles swap hints where the route's buyAmount represents the full tier capacity,
                // but we may only be using a portion of the tier.
                let actualSellAmount = self.amountLessInFee
                let actualBuyAmount = Number(
                    (SNumber(buyAmount) * SNumber(actualSellAmount))
                        / SNumber(swapQuoteSellAmount)
                )
                let actualFeeAmount = Number(
                    (SNumber(feeAmount) * SNumber(actualSellAmount))
                        / SNumber(swapQuoteSellAmount)
                )

                return Charter.QuarkOperationBuilder.swap(
                    network: sourceNetwork,
                    sellAsset: sellAsset,
                    sellAmount: Amount(actualSellAmount, decimals: Int(sellAsset.decimals)),
                    buyAsset: buyAsset,
                    buyAmount: Amount(actualBuyAmount, decimals: Int(buyAsset.decimals)),
                    sellPrice: sellPrice.underlying,
                    buyPrice: buyPrice.underlying,
                    feeToken: feeToken,
                    feeAmount: Amount(actualFeeAmount, decimals: Int(feeAsset.decimals)),
                    isExactOut: isExactOut,
                    // TODO: Is `false` by default correct here?
                    isBuy: displayInfo?.isBuy ?? false,
                    isCappedMax: isCappedMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometSupply(let isCappedMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the comet market from sink node
                guard case .cometSupplyBalance(_, let comet, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for cometSupply"))
                }

                return Charter.QuarkOperationBuilder.cometSupply(
                    network: sourceNetwork,
                    comet: comet,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amountLessInFee, decimals: Int(asset.decimals)),
                    isCappedMax: isCappedMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometWithdraw(let isMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the comet market from source node
                guard case .cometSupplyBalance(_, let comet, _, _) = self.route.source else {
                    return .failure(.error("Invalid source node for cometWithdraw"))
                }

                return Charter.QuarkOperationBuilder.cometWithdraw(
                    network: sourceNetwork,
                    comet: comet,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amount, decimals: Int(asset.decimals)),
                    isMax: isMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometSupplyCollateral(let isCappedMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let collateralAsset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): collateralAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let collateralPrice = folio.getAssetPrice(symbol: collateralAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: collateralAsset.symbol))
                }

                // Get the comet market from sink node
                guard case .cometCollateralBalance(_, let comet, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for cometSupplyCollateral"))
                }

                // Get the comet market to retrieve the base asset
                guard let cometMarket = Atlas.getCometMarket(network: sourceNetwork, comet: comet) else {
                    return .failure(.error("Comet market not found for address: \(comet)"))
                }

                // Look up base asset by address
                guard let baseAsset = Atlas.getEvmAssetByAddress(network: sourceNetwork, token: cometMarket.baseAsset) else {
                    return .failure(.error("Base asset not found in Atlas for comet: \(comet)"))
                }

                guard let baseAssetPrice = folio.getAssetPrice(symbol: baseAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: baseAsset.symbol))
                }

                // For collateral supply, use cometBorrow with zero borrow amount
                return Charter.QuarkOperationBuilder.cometBorrow(
                    network: sourceNetwork,
                    comet: comet,
                    asset: baseAsset,
                    price: baseAssetPrice.underlying,
                    amount: Amount(0, decimals: Int(baseAsset.decimals)),
                    collateralAssets: [collateralAsset],
                    collateralAmounts: [Amount(self.amountLessInFee, decimals: Int(collateralAsset.decimals))],
                    collateralPrices: [collateralPrice.underlying],
                    isCappedMax: isCappedMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometBorrow(let borrowAssetAddress, _):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                // Look up borrow asset by address
                guard
                    let borrowAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: borrowAssetAddress
                    )
                else {
                    return .failure(
                        .error("Borrow asset not found in Atlas for address: \(borrowAssetAddress)")
                    )
                }

                guard let price = folio.getAssetPrice(symbol: borrowAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: borrowAsset.symbol))
                }

                // Get the comet from source node (collateral position or borrow capacity)
                let comet: EthAddress
                switch self.route.source {
                    case .cometCollateralBalance(_, let c, _, _):
                        comet = c
                    case .cometBorrowCapacity(_, let c, _, _):
                        comet = c
                    default:
                        return .failure(.error("Invalid source node for cometBorrow"))
                }

                // Simple borrow without collateral
                // Note: Always use self.amount (Tradewinds-calculated borrow capacity), not MAX_UINT_256.
                // Comet's withdraw function does not support MAX_UINT_256 for borrowing.
                return Charter.QuarkOperationBuilder.cometBorrow(
                    network: sourceNetwork,
                    comet: comet,
                    asset: borrowAsset,
                    price: price.underlying,
                    amount: Amount(self.amount, decimals: Int(borrowAsset.decimals)),
                    collateralAssets: [],
                    collateralAmounts: [],
                    collateralPrices: [],
                    isCappedMax: false,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometRepay(let isMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the comet market from sink node
                guard case .cometBorrowPosition(_, let comet, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for cometRepay"))
                }

                // Simple repay without collateral withdrawal
                return Charter.QuarkOperationBuilder.cometRepay(
                    network: sourceNetwork,
                    comet: comet,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amountLessInFee, decimals: Int(asset.decimals)),
                    collateralAsset: nil,
                    collateralAmount: nil,
                    collateralPrice: nil,
                    isMaxRepay: isMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometWithdrawCollateral(let isMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let collateralAsset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): collateralAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let collateralPrice = folio.getAssetPrice(symbol: collateralAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: collateralAsset.symbol))
                }

                // Get the comet market from source node
                guard case .cometCollateralBalance(_, let comet, _, _) = self.route.source else {
                    return .failure(.error("Invalid source node for cometWithdrawCollateral"))
                }

                guard let cometMarket = Atlas.getCometMarket(network: sourceNetwork, comet: comet)
                else {
                    return .failure(.cometMarketNotFound(comet: comet, network: sourceNetwork))
                }

                guard
                    let baseAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: cometMarket.baseAsset
                    )
                else {
                    return .failure(.error("Base asset not found for comet: \(comet)"))
                }

                guard let baseAssetPrice = folio.getAssetPrice(symbol: baseAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: baseAsset.symbol))
                }

                // Collateral withdrawal doesn't support uint256.max; fetch actual balance from folio
                let actualCollateralAmount: Number
                if isMax {
                    let collateralBalanceKey = Folio.BalanceType.borrowMarketCollateral(
                        borrowMarket: .comet(
                            network: sourceNetwork,
                            comet: comet,
                            underlyingSymbol: collateralAsset.symbol
                        ),
                        tokenSymbol: collateralAsset.symbol,
                        wallet: sourceWallet
                    )
                    actualCollateralAmount = folio.balances[collateralBalanceKey]?.underlying ?? Number(0)
                } else {
                    actualCollateralAmount = self.amount
                }

                return Charter.QuarkOperationBuilder.cometRepay(
                    network: sourceNetwork,
                    comet: comet,
                    asset: baseAsset,
                    price: baseAssetPrice.underlying,
                    amount: Amount(0, decimals: Int(baseAsset.decimals)),
                    collateralAsset: collateralAsset,
                    collateralAmount: Amount(actualCollateralAmount, decimals: Int(collateralAsset.decimals)),
                    collateralPrice: collateralPrice.underlying,
                    isMaxRepay: false,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometSupplyCollateralAndBorrow(let borrowAssetAddress, let borrowAmount, let isCappedMaxSupply):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let collateralAsset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): collateralAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                // Look up borrow asset by address
                guard
                    let borrowAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: borrowAssetAddress
                    )
                else {
                    return .failure(
                        .error("Borrow asset not found in Atlas for address: \(borrowAssetAddress)")
                    )
                }

                guard let collateralPrice = folio.getAssetPrice(symbol: collateralAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: collateralAsset.symbol))
                }

                guard let borrowPrice = folio.getAssetPrice(symbol: borrowAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: borrowAsset.symbol))
                }

                // Get the comet market from sink node
                guard case .cometCollateralBalance(_, let comet, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for cometSupplyCollateralAndBorrow"))
                }

                // Use cometBorrow with collateral arrays
                return Charter.QuarkOperationBuilder.cometBorrow(
                    network: sourceNetwork,
                    comet: comet,
                    asset: borrowAsset,
                    price: borrowPrice.underlying,
                    amount: Amount(borrowAmount, decimals: Int(borrowAsset.decimals)),
                    collateralAssets: [collateralAsset],
                    collateralAmounts: [
                        Amount(self.amountLessInFee, decimals: Int(collateralAsset.decimals))
                    ],
                    collateralPrices: [collateralPrice.underlying],
                    isCappedMax: isCappedMaxSupply,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometRepayAndWithdrawCollateral(let collateralAssetAddress, let collateralAmount, let isMaxRepay):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                // The source is the token balance (repay token), sink is the borrow position
                guard case .tokenBalance(_, let repayAssetAddress, _, _) = self.route.source else {
                    return .failure(
                        .error(
                            "Invalid source node for cometRepayAndWithdrawCollateral - expected tokenBalance"
                        )
                    )
                }

                guard case .cometBorrowPosition(_, let comet, _, _) = self.route.sink else {
                    return .failure(
                        .error(
                            "Invalid sink node for cometRepayAndWithdrawCollateral - expected cometBorrowPosition"
                        )
                    )
                }

                // Look up the repay asset
                guard
                    let repayAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: repayAssetAddress
                    )
                else {
                    return .failure(
                        .error("Repay asset not found in Atlas for address: \(repayAssetAddress)")
                    )
                }

                // Look up collateral asset by address
                guard
                    let collateralAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: collateralAssetAddress
                    )
                else {
                    return .failure(
                        .error(
                            "Collateral asset not found in Atlas for address: \(collateralAssetAddress)"
                        )
                    )
                }

                guard let repayPrice = folio.getAssetPrice(symbol: repayAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: repayAsset.symbol))
                }

                guard let collateralPrice = folio.getAssetPrice(symbol: collateralAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: collateralAsset.symbol))
                }

                // Collateral withdrawal doesn't support uint256.max; fetch actual balance from folio
                let actualCollateralAmount: Number
                if collateralAmount.isMaxUint256 {
                    let collateralBalanceKey = Folio.BalanceType.borrowMarketCollateral(
                        borrowMarket: .comet(
                            network: sourceNetwork,
                            comet: comet,
                            underlyingSymbol: collateralAsset.symbol
                        ),
                        tokenSymbol: collateralAsset.symbol,
                        wallet: sourceWallet
                    )
                    actualCollateralAmount = folio.balances[collateralBalanceKey]?.underlying ?? Number(0)
                } else {
                    actualCollateralAmount = collateralAmount
                }

                return Charter.QuarkOperationBuilder.cometRepay(
                    network: sourceNetwork,
                    comet: comet,
                    asset: repayAsset,
                    price: repayPrice.underlying,
                    amount: Amount(self.amountLessInFee, decimals: Int(repayAsset.decimals)),
                    collateralAsset: collateralAsset,
                    collateralAmount: Amount(actualCollateralAmount, decimals: Int(collateralAsset.decimals)),
                    collateralPrice: collateralPrice.underlying,
                    isMaxRepay: isMaxRepay,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoSupplyCollateral(let isCappedMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the morpho market from sink node
                guard case .morphoCollateralBalance(_, let marketId, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for morphoSupplyCollateral"))
                }

                // Need to get loan asset info from the market
                guard
                    let morphoMarket = Atlas.getMorphoMarket(
                        network: sourceNetwork,
                        marketId: marketId
                    )
                else {
                    return .failure(
                        .morphoMarketNotFound(marketId: marketId, network: sourceNetwork)
                    )
                }

                guard
                    let loanAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: morphoMarket.loanToken
                    )
                else {
                    return .failure(
                        .error(
                            "Loan asset not found in Atlas for address: \(morphoMarket.loanToken)"
                        )
                    )
                }

                // Get loan asset price for consistency
                guard let loanPrice = folio.getAssetPrice(symbol: loanAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: loanAsset.symbol))
                }

                // Use compound function with 0 borrow amount
                return Charter.QuarkOperationBuilder.morphoSupplyCollateralAndBorrow(
                    network: sourceNetwork,
                    marketId: marketId,
                    collateralAsset: asset,
                    collateralAmount: Amount(self.amountLessInFee, decimals: Int(asset.decimals)),
                    collateralPrice: price.underlying,
                    borrowAsset: loanAsset,
                    borrowAmount: Amount(0, decimals: 0),
                    borrowPrice: loanPrice.underlying,
                    isCappedMax: isCappedMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoBorrow(let borrowAssetAddress, _):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                // Look up borrow asset by address
                guard
                    let borrowAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: borrowAssetAddress
                    )
                else {
                    return .failure(
                        .error("Borrow asset not found in Atlas for address: \(borrowAssetAddress)")
                    )
                }

                guard let price = folio.getAssetPrice(symbol: borrowAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: borrowAsset.symbol))
                }

                // Get the morpho market from source node (collateral position or borrow capacity)
                let marketId: Hex
                switch self.route.source {
                    case .morphoCollateralBalance(_, let m, _, _):
                        marketId = m
                    case .morphoBorrowCapacity(_, let m, _, _):
                        marketId = m
                    default:
                        return .failure(.error("Invalid source node for morphoBorrow"))
                }

                // Use compound function with 0 collateral amount
                // Need to get collateral asset info from the market
                guard
                    let morphoMarket = Atlas.getMorphoMarket(
                        network: sourceNetwork,
                        marketId: marketId
                    )
                else {
                    return .failure(
                        .morphoMarketNotFound(marketId: marketId, network: sourceNetwork)
                    )
                }

                guard
                    let collateralAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: morphoMarket.collateralToken
                    )
                else {
                    return .failure(
                        .error(
                            "Collateral asset not found in Atlas for address: \(morphoMarket.collateralToken)"
                        )
                    )
                }

                // Note: Always use self.amount (Tradewinds-calculated borrow capacity), not MAX_UINT_256.
                // Morpho's borrow function does not support MAX_UINT_256 for borrowing.
                return Charter.QuarkOperationBuilder.morphoSupplyCollateralAndBorrow(
                    network: sourceNetwork,
                    marketId: marketId,
                    collateralAsset: collateralAsset,
                    collateralAmount: Amount(0, decimals: 0),
                    collateralPrice: Number(0),
                    borrowAsset: borrowAsset,
                    borrowAmount: Amount(self.amount, decimals: Int(borrowAsset.decimals)),
                    borrowPrice: price.underlying,
                    isCappedMax: false,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoRepay(let isMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the morpho market from sink node
                guard case .morphoBorrowPosition(_, let marketId, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for morphoRepay"))
                }

                // Use compound function with 0 withdraw amount
                // Need to get collateral asset info from the market
                guard
                    let morphoMarket = Atlas.getMorphoMarket(
                        network: sourceNetwork,
                        marketId: marketId
                    )
                else {
                    return .failure(
                        .morphoMarketNotFound(marketId: marketId, network: sourceNetwork)
                    )
                }

                guard
                    let collateralAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: morphoMarket.collateralToken
                    )
                else {
                    return .failure(
                        .error(
                            "Collateral asset not found in Atlas for address: \(morphoMarket.collateralToken)"
                        )
                    )
                }

                return Charter.QuarkOperationBuilder.morphoRepayAndWithdrawCollateral(
                    network: sourceNetwork,
                    marketId: marketId,
                    repayAsset: asset,
                    repayAmount: Amount(self.amountLessInFee, decimals: Int(asset.decimals)),
                    repayPrice: price.underlying,
                    collateralAsset: collateralAsset,
                    collateralAmount: Amount(0, decimals: 0),
                    collateralPrice: Number(0),
                    isMaxRepay: isMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoWithdrawCollateral(let isMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the morpho market from source node
                guard case .morphoCollateralBalance(_, let marketId, _, _) = self.route.source
                else {
                    return .failure(.error("Invalid source node for morphoWithdrawCollateral"))
                }

                // Use compound function with 0 repay amount
                // Need to get loan asset info from the market
                guard
                    let morphoMarket = Atlas.getMorphoMarket(
                        network: sourceNetwork,
                        marketId: marketId
                    )
                else {
                    return .failure(
                        .morphoMarketNotFound(marketId: marketId, network: sourceNetwork)
                    )
                }

                guard
                    let loanAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: morphoMarket.loanToken
                    )
                else {
                    return .failure(
                        .error(
                            "Loan asset not found in Atlas for address: \(morphoMarket.loanToken)"
                        )
                    )
                }

                guard let repayPrice = folio.getAssetPrice(symbol: loanAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: loanAsset.symbol))
                }

                // Collateral withdrawal doesn't support uint256.max; fetch actual balance from folio
                let actualCollateralAmount: Number
                if isMax {
                    let collateralBalanceKey = Folio.BalanceType.borrowMarketCollateral(
                        borrowMarket: .morpho(
                            network: sourceNetwork,
                            collateralTokenSymbol: asset.symbol,
                            borrowTokenSymbol: loanAsset.symbol
                        ),
                        tokenSymbol: asset.symbol,
                        wallet: sourceWallet
                    )
                    actualCollateralAmount = folio.balances[collateralBalanceKey]?.underlying ?? Number(0)
                } else {
                    actualCollateralAmount = self.amount
                }

                return Charter.QuarkOperationBuilder.morphoRepayAndWithdrawCollateral(
                    network: sourceNetwork,
                    marketId: marketId,
                    repayAsset: loanAsset,
                    repayAmount: Amount(0, decimals: 0),
                    repayPrice: repayPrice.underlying,
                    collateralAsset: asset,
                    collateralAmount: Amount(actualCollateralAmount, decimals: Int(asset.decimals)),
                    collateralPrice: price.underlying,
                    isMaxRepay: false,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoSupplyCollateralAndBorrow(let borrowAssetAddress, let borrowAmount, let isCappedMaxSupply):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let collateralAsset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): collateralAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                // Look up borrow asset by address
                guard
                    let borrowAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: borrowAssetAddress
                    )
                else {
                    return .failure(
                        .error("Borrow asset not found in Atlas for address: \(borrowAssetAddress)")
                    )
                }

                guard let collateralPrice = folio.getAssetPrice(symbol: collateralAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: collateralAsset.symbol))
                }

                guard let borrowPrice = folio.getAssetPrice(symbol: borrowAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: borrowAsset.symbol))
                }

                // Get the morpho market from sink node
                guard case .morphoCollateralBalance(_, let marketId, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for morphoSupplyCollateralAndBorrow"))
                }

                return Charter.QuarkOperationBuilder.morphoSupplyCollateralAndBorrow(
                    network: sourceNetwork,
                    marketId: marketId,
                    collateralAsset: collateralAsset,
                    collateralAmount: Amount(
                        self.amountLessInFee,
                        decimals: Int(collateralAsset.decimals)
                    ),
                    collateralPrice: collateralPrice.underlying,
                    borrowAsset: borrowAsset,
                    borrowAmount: Amount(borrowAmount, decimals: Int(borrowAsset.decimals)),
                    borrowPrice: borrowPrice.underlying,
                    isCappedMax: isCappedMaxSupply,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoRepayAndWithdrawCollateral(let collateralAssetAddress, let collateralAmount, let isMaxRepay):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                // The source is the token balance (repay token), sink is the borrow position
                guard case .tokenBalance(_, let repayAssetAddress, _, _) = self.route.source else {
                    return .failure(
                        .error(
                            "Invalid source node for morphoRepayAndWithdrawCollateral - expected tokenBalance"
                        )
                    )
                }

                guard case .morphoBorrowPosition(_, let marketId, _, _) = self.route.sink else {
                    return .failure(
                        .error(
                            "Invalid sink node for morphoRepayAndWithdrawCollateral - expected morphoBorrowPosition"
                        )
                    )
                }

                // Look up the repay asset
                guard
                    let repayAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: repayAssetAddress
                    )
                else {
                    return .failure(
                        .error("Repay asset not found in Atlas for address: \(repayAssetAddress)")
                    )
                }

                // Look up collateral asset by address
                guard
                    let collateralAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: collateralAssetAddress
                    )
                else {
                    return .failure(
                        .error(
                            "Collateral asset not found in Atlas for address: \(collateralAssetAddress)"
                        )
                    )
                }

                guard let repayPrice = folio.getAssetPrice(symbol: repayAsset.symbol) else {
                    return .failure(.unpricedAsset(symbol: repayAsset.symbol))
                }

                guard let collateralPrice = folio.getAssetPrice(symbol: collateralAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: collateralAsset.symbol))
                }

                // Collateral withdrawal doesn't support uint256.max; fetch actual balance from folio
                let actualCollateralAmount: Number
                if collateralAmount.isMaxUint256 {
                    let collateralBalanceKey = Folio.BalanceType.borrowMarketCollateral(
                        borrowMarket: .morpho(
                            network: sourceNetwork,
                            collateralTokenSymbol: collateralAsset.symbol,
                            borrowTokenSymbol: repayAsset.symbol
                        ),
                        tokenSymbol: collateralAsset.symbol,
                        wallet: sourceWallet
                    )
                    actualCollateralAmount = folio.balances[collateralBalanceKey]?.underlying ?? Number(0)
                } else {
                    actualCollateralAmount = collateralAmount
                }

                return Charter.QuarkOperationBuilder.morphoRepayAndWithdrawCollateral(
                    network: sourceNetwork,
                    marketId: marketId,
                    repayAsset: repayAsset,
                    repayAmount: Amount(self.amountLessInFee, decimals: Int(repayAsset.decimals)),
                    repayPrice: repayPrice.underlying,
                    collateralAsset: collateralAsset,
                    collateralAmount: Amount(
                        actualCollateralAmount,
                        decimals: Int(collateralAsset.decimals)
                    ),
                    collateralPrice: collateralPrice.underlying,
                    isMaxRepay: isMaxRepay,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoVaultSupply(let isCappedMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the vault from sink node
                guard case .morphoVaultSupplyBalance(_, let vault, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for morphoVaultSupply"))
                }

                return Charter.QuarkOperationBuilder.morphoVaultSupply(
                    network: sourceNetwork,
                    vault: vault,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amountLessInFee, decimals: Int(asset.decimals)),
                    isCappedMax: isCappedMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .morphoVaultWithdraw(let isMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the vault from source node
                guard case .morphoVaultSupplyBalance(_, let vault, _, _) = self.route.source else {
                    return .failure(.error("Invalid source node for morphoVaultWithdraw"))
                }

                return Charter.QuarkOperationBuilder.morphoVaultWithdraw(
                    network: sourceNetwork,
                    vault: vault,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amount, decimals: Int(asset.decimals)),
                    isMax: isMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .aaveSupply(let isCappedMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the Aave pool from sink node
                guard case .aaveSupplyBalance(_, let pool, _, _) = self.route.sink else {
                    return .failure(.error("Invalid sink node for aaveSupply"))
                }

                return Charter.QuarkOperationBuilder.aaveSupply(
                    network: sourceNetwork,
                    pool: pool,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amountLessInFee, decimals: Int(asset.decimals)),
                    isCappedMax: isCappedMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .aaveWithdraw(let isMax):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                let asset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): asset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard let price = folio.getAssetPrice(symbol: asset.symbol) else {
                    return .failure(.unpricedAsset(symbol: asset.symbol))
                }

                // Get the Aave pool from source node
                guard case .aaveSupplyBalance(_, let pool, _, _) = self.route.source else {
                    return .failure(.error("Invalid source node for aaveWithdraw"))
                }

                return Charter.QuarkOperationBuilder.aaveWithdraw(
                    network: sourceNetwork,
                    pool: pool,
                    asset: asset,
                    price: price.underlying,
                    amount: Amount(self.amount, decimals: Int(asset.decimals)),
                    isMax: isMax,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )
            case .morphoClaimRewards(
                let distributors,
                let rewards,
                let claimables,
                let claimableNows,
                let proofs,
                let symbols,
                let prices
            ):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                return Charter.QuarkOperationBuilder.morphoClaimRewards(
                    network: sourceNetwork,
                    distributors: distributors,
                    rewards: rewards,
                    claimables: claimables,
                    claimableNows: claimableNows,
                    proofs: proofs,
                    symbols: symbols,
                    prices: prices,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .cometClaimRewards(
                let cometRewards,
                let comets,
                let amounts,
                let symbols,
                let prices,
                let tokens
            ):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                guard case .success(let sourceWallet) = sourceWalletRes else {
                    return .failure(sourceWalletRes.asFailure)
                }

                return Charter.QuarkOperationBuilder.cometClaimRewards(
                    network: sourceNetwork,
                    cometRewards: cometRewards,
                    comets: comets,
                    amounts: amounts,
                    symbols: symbols,
                    prices: prices,
                    tokens: tokens,
                    sender: sourceWallet,
                    blockTimestamp: blockTimestamp
                )

            case .rewardSettlement:
                // Virtual route that generates no operations
                return .success([])

            case .swapSettlement:
                // Virtual route that generates no operations
                return .success([])

            case .balancePassthrough:
                // Virtual route that generates no operations
                return .success([])

            case .loopLong(
                let marketId,
                let exposureAsset,
                let exposureAssetSymbol,
                let exposureAmount,
                let maxSwapBackingAmount,
                let maxProvidedBackingAmount,
                let poolFee,
                let isIncrease
            ):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                // Get backing asset from sink (loopVenue always contains backing asset address)
                guard case .loopVenue(_, _, let backingAssetAddress, _, _) = self.route.sink,
                      let backingAsset = Atlas.getEvmAssetByAddress(network: sourceNetwork, token: backingAssetAddress)
                else {
                    return .failure(.unknownAsset(symbol: nil, network: sourceNetwork, address: nil))
                }

                guard
                    let exposureAsset: Atlas.EvmAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: exposureAsset
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: exposureAssetSymbol,
                            network: sourceNetwork,
                            address: exposureAsset
                        )
                    )
                }

                guard let backingAssetPrice = folio.getAssetPrice(symbol: backingAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: backingAsset.symbol))
                }

                guard let exposureAssetPrice = folio.getAssetPrice(symbol: exposureAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: backingAsset.symbol))
                }

                return Charter.QuarkOperationBuilder.loopLong(
                    network: sourceNetwork,
                    marketId: marketId,
                    backingAsset: backingAsset,
                    backingAssetPrice: backingAssetPrice.underlying,
                    exposureAsset: exposureAsset,
                    exposureAmount: exposureAmount,
                    exposureAssetPrice: exposureAssetPrice.underlying,
                    maxSwapBackingAmount: maxSwapBackingAmount,
                    // When backing is 0, Tradewinds uses 1 wei on the virtual route to force route selection,
                    // so we must explicitly pass 0 here instead of amountLessInFee (which would be 1 wei)
                    maxProvidedBackingAmount: maxProvidedBackingAmount == 0 ? 0 : self.amountLessInFee,
                    isCappedMax: isCappedMax,
                    poolFee: poolFee,
                    isIncrease: isIncrease
                )
            case .loopShort(
                let marketId,
                let exposureAsset,
                let exposureAssetSymbol,
                let exposureAmount,
                let minSwapBackingAmount,
                let providedBackingAmount,
                let poolFee,
                let isIncrease
            ):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                // Get backing asset from sink (loopVenue always contains backing asset address)
                guard case .loopVenue(_, _, let backingAssetAddress, _, _) = self.route.sink,
                      let backingAsset = Atlas.getEvmAssetByAddress(network: sourceNetwork, token: backingAssetAddress)
                else {
                    return .failure(.unknownAsset(symbol: nil, network: sourceNetwork, address: nil))
                }

                guard
                    let exposureAsset: Atlas.EvmAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: exposureAsset
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: exposureAssetSymbol,
                            network: sourceNetwork,
                            address: exposureAsset
                        )
                    )
                }

                guard let backingAssetPrice = folio.getAssetPrice(symbol: backingAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: backingAsset.symbol))
                }

                guard let exposureAssetPrice = folio.getAssetPrice(symbol: exposureAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: exposureAsset.symbol))
                }

                return Charter.QuarkOperationBuilder.loopShort(
                    network: sourceNetwork,
                    marketId: marketId,
                    backingAsset: backingAsset,
                    backingAssetPrice: backingAssetPrice.underlying,
                    exposureAsset: exposureAsset,
                    exposureAmount: exposureAmount,
                    exposureAssetPrice: exposureAssetPrice.underlying,
                    minSwapBackingAmount: minSwapBackingAmount,
                    // When backing is 0, Tradewinds uses 1 wei on the virtual route to force route selection,
                    // so we must explicitly pass 0 here instead of amountLessInFee (which would be 1 wei)
                    providedBackingAmount: providedBackingAmount == 0 ? 0 : self.amountLessInFee,
                    isCappedMax: isCappedMax,
                    poolFee: poolFee,
                    isIncrease: isIncrease
                )
            case .unloopLong(
                let marketId,
                let exposureAsset,
                let exposureAssetSymbol,
                let exposureAmount,
                let backingAmountToExit,
                let minSwapBackingAmount,
                let poolFee
            ):
                guard case .success(let sinkNetwork) = sinkNetworkRes else {
                    return .failure(sinkNetworkRes.asFailure)
                }

                // Get backing asset from source (loopVenue always contains backing asset address)
                guard case .loopVenue(_, _, let backingAssetAddress, _, _) = self.route.source,
                      let backingAsset = Atlas.getEvmAssetByAddress(network: sinkNetwork, token: backingAssetAddress)
                else {
                    return .failure(.unknownAsset(symbol: nil, network: sinkNetwork, address: nil))
                }

                guard
                    let exposureAsset: Atlas.EvmAsset = Atlas.getEvmAssetByAddress(
                        network: sinkNetwork,
                        token: exposureAsset
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: exposureAssetSymbol,
                            network: sinkNetwork,
                            address: exposureAsset
                        )
                    )
                }

                guard let backingAssetPrice = folio.getAssetPrice(symbol: backingAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: backingAsset.symbol))
                }

                guard let exposureAssetPrice = folio.getAssetPrice(symbol: exposureAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: exposureAsset.symbol))
                }

                // When exposureAmount is maxUint256 (full unloop), backingAmountToExit must be 0 (enforced by the smart contract)
                // When backing exit is 0, Tradewinds uses 1 wei on the virtual route to force route selection,
                // so we must explicitly pass 0 here instead of amount (which would be 1 wei)
                let actualBackingAmountToExit = (exposureAmount.isMaxUint256 || backingAmountToExit == 0) ? 0 : self.amount

                return Charter.QuarkOperationBuilder.unloopLong(
                    network: sinkNetwork,
                    marketId: marketId,
                    backingAsset: backingAsset,
                    backingAssetPrice: backingAssetPrice.underlying,
                    exposureAsset: exposureAsset,
                    exposureAmount: exposureAmount,
                    exposureAssetPrice: exposureAssetPrice.underlying,
                    backingAmountToExit: actualBackingAmountToExit,
                    minSwapBackingAmount: minSwapBackingAmount,
                    poolFee: poolFee
                )
            case .unloopShort(
                let marketId,
                let exposureAsset,
                let exposureAssetSymbol,
                let exposureAmount,
                let backingAmountToExit,
                let maxSwapBackingAmount,
                let poolFee
            ):
                guard case .success(let sinkNetwork) = sinkNetworkRes else {
                    return .failure(sinkNetworkRes.asFailure)
                }

                // Get backing asset from source (loopVenue always contains backing asset address)
                guard case .loopVenue(_, _, let backingAssetAddress, _, _) = self.route.source,
                      let backingAsset = Atlas.getEvmAssetByAddress(network: sinkNetwork, token: backingAssetAddress)
                else {
                    return .failure(.unknownAsset(symbol: nil, network: sinkNetwork, address: nil))
                }

                guard
                    let exposureAsset: Atlas.EvmAsset = Atlas.getEvmAssetByAddress(
                        network: sinkNetwork,
                        token: exposureAsset
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: exposureAssetSymbol,
                            network: sinkNetwork,
                            address: exposureAsset
                        )
                    )
                }

                guard let backingAssetPrice = folio.getAssetPrice(symbol: backingAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: backingAsset.symbol))
                }

                guard let exposureAssetPrice = folio.getAssetPrice(symbol: exposureAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: exposureAsset.symbol))
                }

                // Get wallet from source (loop venue node)
                guard let wallet = self.route.source.wallet else {
                    return .failure(.invalidNode)
                }

                // When exposureAmount is maxUint256 (full unloop), backingAmountToExit must be 0 (enforced by the smart contract)
                // When backing exit is 0, Tradewinds uses 1 wei on the virtual route to force route selection,
                // so we must explicitly pass 0 here instead of amount (which would be 1 wei)
                let actualBackingAmountToExit = (exposureAmount.isMaxUint256 || backingAmountToExit == 0) ? 0 : self.amount

                // Calculate max exposure amount for fee calculation
                let borrowKey = Folio.BalanceType.borrowMarket(
                    borrowMarket: .morpho(
                        network: sinkNetwork,
                        collateralTokenSymbol: backingAsset.symbol,
                        borrowTokenSymbol: exposureAsset.symbol
                    ),
                    wallet: wallet
                )
                let maxExposureAmount = folio.balances[borrowKey]?.underlying ?? Number(0)

                return Charter.QuarkOperationBuilder.unloopShort(
                    network: sinkNetwork,
                    marketId: marketId,
                    backingAsset: backingAsset,
                    backingAssetPrice: backingAssetPrice.underlying,
                    exposureAsset: exposureAsset,
                    exposureAmount: exposureAmount,
                    exposureAssetPrice: exposureAssetPrice.underlying,
                    backingAmountToExit: actualBackingAmountToExit,
                    maxSwapBackingAmount: maxSwapBackingAmount,
                    poolFee: poolFee,
                    maxExposureAmount: maxExposureAmount
                )
            case .addBackingToken(
                let marketId,
                let exposureAsset,
                let exposureAssetSymbol,
                let amount,
                let isShort
            ):
                guard case .success(let sourceNetwork) = sourceNetworkRes else {
                    return .failure(sourceNetworkRes.asFailure)
                }

                let backingAsset: Atlas.EvmAsset
                switch self.route.source.asAtlasAsset {
                    case .success(let asset_): backingAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard
                    let exposureAsset: Atlas.EvmAsset = Atlas.getEvmAssetByAddress(
                        network: sourceNetwork,
                        token: exposureAsset
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: exposureAssetSymbol,
                            network: sourceNetwork,
                            address: exposureAsset
                        )
                    )
                }

                guard let backingAssetPrice = folio.getAssetPrice(symbol: backingAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: backingAsset.symbol))
                }

                guard let exposureAssetPrice = folio.getAssetPrice(symbol: exposureAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: exposureAsset.symbol))
                }

                return Charter.QuarkOperationBuilder.addBackingToken(
                    network: sourceNetwork,
                    marketId: marketId,
                    backingAsset: backingAsset,
                    backingAssetPrice: backingAssetPrice.underlying,
                    exposureAsset: exposureAsset,
                    exposureAssetPrice: exposureAssetPrice.underlying,
                    amount: self.amountLessInFee,
                    isCappedMax: isCappedMax,
                    isShort: isShort
                )
            case .withdrawBackingToken(
                let marketId,
                let exposureAsset,
                let exposureAssetSymbol,
                let amount,
                let isShort
            ):
                guard case .success(let sinkNetwork) = sinkNetworkRes else {
                    return .failure(sinkNetworkRes.asFailure)
                }

                // For withdrawBackingToken, source is loopVenue, sink is tokenBalance (backing asset)
                let backingAsset: Atlas.EvmAsset
                switch self.route.sink.asAtlasAsset {
                    case .success(let asset_): backingAsset = asset_
                    case .failure(let err): return .failure(err)
                }

                guard
                    let exposureAsset: Atlas.EvmAsset = Atlas.getEvmAssetByAddress(
                        network: sinkNetwork,
                        token: exposureAsset
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: exposureAssetSymbol,
                            network: sinkNetwork,
                            address: exposureAsset
                        )
                    )
                }

                guard let backingAssetPrice = folio.getAssetPrice(symbol: backingAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: backingAsset.symbol))
                }

                guard let exposureAssetPrice = folio.getAssetPrice(symbol: exposureAsset.symbol)
                else {
                    return .failure(.unpricedAsset(symbol: exposureAsset.symbol))
                }

                return Charter.QuarkOperationBuilder.withdrawBackingToken(
                    network: sinkNetwork,
                    marketId: marketId,
                    backingAsset: backingAsset,
                    backingAssetPrice: backingAssetPrice.underlying,
                    exposureAsset: exposureAsset,
                    exposureAssetPrice: exposureAssetPrice.underlying,
                    amount: self.amount,
                    isShort: isShort
                )
        }

    }

    public func getQuarkOperationActions(
        folio: Folio,
        nonceSecret: Hex,
        blockTimestamp: Number,
        isCappedMax: Bool,
        displayInfo: DisplayInfo? = nil,
        logger: Charter.Logger?
    ) -> Result<
        [Charter.QuarkOperationAction], Charter.CharterError
    > {
        let intermediateActions = self.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: blockTimestamp,
            isCappedMax: isCappedMax,
            displayInfo: displayInfo,
            logger: logger
        )
        logger?.log("Intermediate actions: \(String(describing: intermediateActions))")

        guard let sourceWallet = self.route.source.wallet else {
            return .failure(.invalidNode)
        }

        switch intermediateActions {
            case .success(let immediateActions):
                var quarkOperationActions: [Charter.QuarkOperationAction] = []

                for immediateAction in immediateActions {
                    switch Charter.QuarkOperationBuilder.handleImmediateOperation(
                        operationDetails: immediateAction,
                        network: immediateAction.network,
                        sender: sourceWallet,
                        nonceSecret: nonceSecret,
                        blockTimestamp: blockTimestamp
                    ) {
                        case .success(let quarkOperationAction):
                            quarkOperationActions.append(quarkOperationAction)
                        case .failure(let err):
                            return .failure(err)
                    }
                }
                return .success(quarkOperationActions)
            case .failure(let err):
                return .failure(err)
        }
    }
}