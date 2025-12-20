import Charter
import Eth
import Foundation
import Prelude

extension Charter.ActionContext {
    public func toAction(portfolios: [Portfolio]) -> Action? {
        switch self {
            case .transfer(let context):
                return context.toAction(portfolios: portfolios)
            case .bridge(let context):
                return context.toAction(portfolios: portfolios)
            case .bridgeMint(let context):
                return context.toAction(portfolios: portfolios)
            case .aaveSupply(let context):
                return context.toAction(portfolios: portfolios)
            case .aaveWithdraw(let context):
                return context.toAction(portfolios: portfolios)
            case .cometSupply(let context):
                return context.toAction(portfolios: portfolios)
            case .morphoVaultSupply(let context):
                return context.toAction(portfolios: portfolios)
            case .cometBorrow(let context):
                return context.toAction(portfolios: portfolios)
            case .morphoBorrow(let context):
                return context.toAction(portfolios: portfolios)
            case .cometRepay(let context):
                return context.toAction(portfolios: portfolios)
            case .morphoRepay(let context):
                return context.toAction(portfolios: portfolios)
            case .swap(let context):
                return context.toAction(portfolios: portfolios)
            case .cometClaimRewards(let context):
                return context.toAction(portfolios: portfolios)
            case .morphoClaimRewards(let context):
                return context.toAction(portfolios: portfolios)
            case .cometWithdraw(let context):
                return context.toAction(portfolios: portfolios)
            case .morphoVaultWithdraw(let context):
                return context.toAction(portfolios: portfolios)
            case .withdrawAndBorrow(let context):
                return context.toAction(portfolios: portfolios)
            case .recurringSwap(let context):
                return context.toAction(portfolios: portfolios)
            case .quotePay(let context):
                return context.toAction(portfolios: portfolios)
            case .loopLong(let context):
                return context.toAction(portfolios: portfolios)
            case .unloopLong(let context):
                return context.toAction(portfolios: portfolios)
            case .addBackingToken(let context):
                return context.toAction(portfolios: portfolios)
            case .withdrawBackingToken(let context):
                return context.toAction(portfolios: portfolios)
            case .loopShort, .unloopShort:
                // TODO: Unimplemented for now
                return nil
            case .wrap, .unwrap:
                return nil
            case .multiAction(let contexts):
                return .multiAction(
                    contexts.compactMap { $0.toAction(portfolios: portfolios) }
                )
        }
    }
}

/// Helper functions to convert from ``Charter.Chart.Action`` to ``Action``s.
extension Charter.Chart.Action {
    public func toAction(portfolios: [Portfolio]) -> Action? {
        return actionContext.toAction(portfolios: portfolios)
    }

    public var isRecurring: Bool {
        actionContext.isRecurring
    }

    public var isBridge: Bool {
        actionContext.isBridge
    }
}

// MARK: Transfer

extension Charter.ActionContext.TransferActionContext: ActionConvertible {
    public func toTransferAction(portfolios: [Portfolio]) -> TransferAction? {
        let network = Network.fromChainId(chainId)
        let assetSymbol = self.assetSymbol == "ETH" ? "WETH" : self.assetSymbol

        guard let asset = portfolios.getAsset(symbol: assetSymbol, chain: network) else {
            return nil
        }

        let transferAmount = PricedAmount(amount, forAsset: asset, withPrice: price)
        let recipient = ChainAddress(address: recipient, chain: asset.chain)

        return TransferAction(transferAmount: transferAmount, recipient: recipient)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toTransferAction(portfolios: portfolios).map { .transfer($0) }
    }
}

// MARK: Bridge Mint

extension Charter.ActionContext.BridgeMintActionContext: ActionConvertible {
    public var bridgeDapp: DApp? {
        switch bridgeType {
            case .cctpV1, .cctpV2:
                return .CircleBridge
            case .across:
                return .Across
            default:
                return nil
        }
    }

    public func toBridgeMintAction(portfolios: [Portfolio]) -> BridgeMintAction? {
        let network = Network.fromChainId(chainId)

        // Use the token address to find the asset
        guard let asset = portfolios.getAsset(token: token, chain: network),
              let bridgeDapp = bridgeDapp else {
            return nil
        }

        // Calculate the price from the fee and amounts
        let price = outputAmount > 0 ? (inputAmount - maxFee) / outputAmount : 1

        let mintAmount = PricedAmount(outputAmount, forAsset: asset, withPrice: price)
        let feeAmount = PricedAmount(maxFee, forAsset: asset, withPrice: price)
        let senderAddress = ChainAddress(
            address: recipient,
            chain: Network.fromChainId(sourceChainId)
        )

        return BridgeMintAction(
            mintAmount: mintAmount,
            feeAmount: feeAmount,
            sender: senderAddress,
            bridgeType: bridgeDapp
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toBridgeMintAction(portfolios: portfolios).map { .bridgeMint($0) }
    }
}

// MARK: Bridge

extension Charter.ActionContext.BridgeActionContext: ActionConvertible {
    public var bridgeDapp: DApp? {
        switch bridgeType {
            case .cctpV1, .cctpV2:
                return .CircleBridge
            case .across:
                return .Across
            default:
                return nil
        }
    }

    public func toBridgeAction(portfolios: [Portfolio]) -> BridgeAction? {
        let network = Network.fromChainId(chainId)

        guard let asset = portfolios.getAsset(token: token, chain: network), let bridgeDapp else {
            return nil
        }

        let bridgeAmount = PricedAmount(outputAmount, forAsset: asset, withPrice: price)
        let bridgeFee = PricedAmount(inputAmount - outputAmount, forAsset: asset, withPrice: price)
        let recipient = ChainAddress(
            address: recipient,
            chain: Network.fromChainId(destinationChainId)
        )

        return BridgeAction(
            bridgeAmount: bridgeAmount,
            bridgeFee: bridgeFee,
            recipient: recipient,
            bridgeType: bridgeDapp
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        return toBridgeAction(portfolios: portfolios).map { .bridge($0) }
    }
}

// MARK: Supply

extension Charter.ActionContext.AaveSupplyActionContext: ActionConvertible {
    public func toSupplyAction(portfolios: [Portfolio]) -> SupplyAction? {
        let network = Network.fromChainId(chainId)

        guard
            let earnMarket = portfolios.getEarnMarket(
                id: .aaveMarket(network, market: aavePool, baseAsset: token)
            )
        else {
            return nil
        }

        let supplyAmount = PricedAmount(amount, forAsset: earnMarket.baseAsset, withPrice: price)

        return SupplyAction(earnMarket: earnMarket, supplyAmount: supplyAmount)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toSupplyAction(portfolios: portfolios).map { .supply($0) }
    }
}

extension Charter.ActionContext.CometSupplyActionContext: ActionConvertible {
    public func toSupplyAction(portfolios: [Portfolio]) -> SupplyAction? {
        let network = Network.fromChainId(chainId)

        guard let earnMarket = portfolios.getEarnMarket(id: .cometMarket(network, comet)) else {
            return nil
        }

        let supplyAmount = PricedAmount(amount, forAsset: earnMarket.baseAsset, withPrice: price)

        return SupplyAction(earnMarket: earnMarket, supplyAmount: supplyAmount)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toSupplyAction(portfolios: portfolios).map { .supply($0) }
    }
}

extension Charter.ActionContext.MorphoVaultSupplyActionContext: ActionConvertible {
    public func toSupplyAction(portfolios: [Portfolio]) -> SupplyAction? {
        let network = Network.fromChainId(chainId)

        guard let earnMarket = portfolios.getEarnMarket(id: .morphoVault(network, morphoVault))
        else {
            return nil
        }

        let supplyAmount = PricedAmount(amount, forAsset: earnMarket.baseAsset, withPrice: price)

        return SupplyAction(earnMarket: earnMarket, supplyAmount: supplyAmount)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toSupplyAction(portfolios: portfolios).map { .supply($0) }
    }
}

// MARK: Borrow

extension Charter.ActionContext.CometBorrowActionContext: ActionConvertible {
    public func toBorrowAction(portfolios: [Portfolio]) -> BorrowAction? {
        let network = Network.fromChainId(chainId)

        guard let borrowMarket = portfolios.getBorrowMarket(id: .cometMarket(network, comet)) else {
            return nil
        }

        guard borrowMarket.baseAsset.address == token else {
            return nil
        }

        let borrowAmount = PricedAmount(amount, forAsset: borrowMarket.baseAsset, withPrice: price)

        var collateralAmountsVal: [PricedAmount<CollateralAsset>] = []

        for (collateralAmount, collateralPrice, collateralToken) in zip3(
            collateralAmounts,
            collateralTokenPrices,
            collateralTokens
        ) {
            guard let collateralAsset = borrowMarket.getCollateralAsset(token: collateralToken), !collateralAmount.isZero
            else {
                return nil
            }

            collateralAmountsVal.append(
                PricedAmount(
                    collateralAmount,
                    forAsset: collateralAsset,
                    withPrice: collateralPrice
                )
            )
        }

        return BorrowAction(
            borrowMarket: borrowMarket,
            borrowAmount: borrowAmount,
            collateralAmounts: collateralAmountsVal
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toBorrowAction(portfolios: portfolios).map { .borrow($0) }
    }
}

extension Charter.ActionContext.MorphoBorrowActionContext: ActionConvertible {
    public func toBorrowAction(portfolios: [Portfolio]) -> BorrowAction? {
        let network = Network.fromChainId(chainId)

        guard
            let borrowMarket = portfolios.getBorrowMarket(
                id: .morphoMarket(network, morphoMarketId)
            )
        else {
            return nil
        }

        guard borrowMarket.baseAsset.address == token else {
            return nil
        }

        guard let collateralAsset = borrowMarket.collateralAssets.first else {
            return nil
        }

        let borrowAmount = PricedAmount(amount, forAsset: borrowMarket.baseAsset, withPrice: price)
        let collateralAmounts = collateralAmount.isZero ? [] : [PricedAmount(
            collateralAmount,
            forAsset: collateralAsset,
            withPrice: collateralTokenPrice
        )]

        return BorrowAction(
            borrowMarket: borrowMarket,
            borrowAmount: borrowAmount,
            collateralAmounts: collateralAmounts
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toBorrowAction(portfolios: portfolios).map { .borrow($0) }
    }
}

// MARK: Repay

extension Charter.ActionContext.CometRepayActionContext: ActionConvertible {
    public func toRepayAction(portfolios: [Portfolio]) -> RepayAction? {
        let network = Network.fromChainId(chainId)

        guard let borrowMarket = portfolios.getBorrowMarket(id: .cometMarket(network, comet)) else {
            return nil
        }

        guard borrowMarket.baseAsset.address == token else {
            return nil
        }

        let repayAmount = PricedAmount(amount, forAsset: borrowMarket.baseAsset, withPrice: price)

        var collateralAmountsVal: [PricedAmount<CollateralAsset>] = []

        for (collateralAmount, collateralPrice, collateralToken) in zip3(
            collateralAmounts,
            collateralTokenPrices,
            collateralTokens
        ) {
            guard let collateralAsset = borrowMarket.getCollateralAsset(token: collateralToken)
            else {
                return nil
            }

            collateralAmountsVal.append(
                PricedAmount(
                    collateralAmount,
                    forAsset: collateralAsset,
                    withPrice: collateralPrice
                )
            )
        }

        return RepayAction(
            borrowMarket: borrowMarket,
            repayAmount: repayAmount,
            collateralAmounts: collateralAmountsVal
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toRepayAction(portfolios: portfolios).map { .repay($0) }
    }
}

extension Charter.ActionContext.MorphoRepayActionContext: ActionConvertible {
    public func toRepayAction(portfolios: [Portfolio]) -> RepayAction? {
        let network = Network.fromChainId(chainId)

        guard
            let borrowMarket = portfolios.getBorrowMarket(
                id: .morphoMarket(network, morphoMarketId)
            )
        else {
            return nil
        }

        guard borrowMarket.baseAsset.address == token else {
            return nil
        }

        guard let collateralAsset = borrowMarket.collateralAssets.first else {
            return nil
        }

        let repayAmount = PricedAmount(amount, forAsset: borrowMarket.baseAsset, withPrice: price)
        let collateralAmount = PricedAmount(
            collateralAmount,
            forAsset: collateralAsset,
            withPrice: collateralTokenPrice
        )

        return RepayAction(
            borrowMarket: borrowMarket,
            repayAmount: repayAmount,
            collateralAmounts: collateralAmount.amount.isZero ? [] : [collateralAmount]
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toRepayAction(portfolios: portfolios).map { .repay($0) }
    }
}

// MARK: Swap

extension Charter.ActionContext.SwapActionContext: ActionConvertible {
    public func toSwapAction(portfolios: [Portfolio]) -> SwapAction? {
        let network = Network.fromChainId(chainId)

        guard let inputAsset = portfolios.getAsset(token: inputToken, chain: network),
            let outputAsset = portfolios.getAsset(token: outputToken, chain: network)
        else {
            return nil
        }

        let buyAmount = PricedAmount(
            outputAmount,
            forAsset: outputAsset,
            withPrice: outputTokenPrice
        )
        let sellAmount = PricedAmount(inputAmount, forAsset: inputAsset, withPrice: inputTokenPrice)

        // Convert all fees from the arrays
        var feeAmountsConverted: [PricedAmount<Asset>] = []
        for (feeToken, feeAmount, feePrice) in zip3(feeTokens, self.feeAmounts, feeTokenPrices) {
            if let feeAsset = portfolios.getAsset(token: feeToken, chain: network) {
                feeAmountsConverted.append(
                    PricedAmount(feeAmount, forAsset: feeAsset, withPrice: feePrice)
                )
            }
        }

        return SwapAction(
            buyAmount: buyAmount,
            sellAmount: sellAmount,
            feeAmounts: feeAmountsConverted,
            feeDescriptions: feeDescriptions,
            isBuy: isBuy
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toSwapAction(portfolios: portfolios).map { .swap($0) }
    }
}

// MARK: Claim

extension Charter.ActionContext.CometClaimRewardsActionContext: ActionConvertible {
    public func toClaimRewardsAction(portfolios: [Portfolio]) -> ClaimRewardsAction? {
        let network = Network.fromChainId(chainId)

        var amountsVal: [PricedAmount<Asset>] = []

        for (amount, price, token) in zip3(amounts, prices, tokens) {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }

            amountsVal.append(
                PricedAmount(
                    amount,
                    forAsset: asset,
                    withPrice: price
                )
            )
        }

        return ClaimRewardsAction(dApp: .Compound, claimAmounts: amountsVal)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toClaimRewardsAction(portfolios: portfolios).map { .claimRewards($0) }
    }
}

extension Charter.ActionContext.MorphoClaimRewardsActionContext: ActionConvertible {
    public func toClaimRewardsAction(portfolios: [Portfolio]) -> ClaimRewardsAction? {
        let network = Network.fromChainId(chainId)

        var amountsVal: [PricedAmount<Asset>] = []

        for (amount, price, token) in zip3(amounts, prices, tokens) {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }

            amountsVal.append(
                PricedAmount(
                    amount,
                    forAsset: asset,
                    withPrice: price
                )
            )
        }

        return ClaimRewardsAction(dApp: .Morpho, claimAmounts: amountsVal)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toClaimRewardsAction(portfolios: portfolios).map { .claimRewards($0) }
    }
}

// MARK: Withdraw

extension Charter.ActionContext.CometWithdrawActionContext: ActionConvertible {
    public func toWithdrawAction(portfolios: [Portfolio]) -> WithdrawAction? {
        let network = Network.fromChainId(chainId)

        guard let earnMarket = portfolios.getEarnMarket(id: .cometMarket(network, comet)) else {
            return nil
        }

        let withdrawAmount = PricedAmount(amount, forAsset: earnMarket.baseAsset, withPrice: price)

        return WithdrawAction(earnMarket: earnMarket, withdrawAmount: withdrawAmount)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toWithdrawAction(portfolios: portfolios).map { .withdraw($0) }
    }
}

extension Charter.ActionContext.AaveWithdrawActionContext: ActionConvertible {
    public func toWithdrawAction(portfolios: [Portfolio]) -> WithdrawAction? {
        let network = Network.fromChainId(chainId)

        guard
            let earnMarket = portfolios.getEarnMarket(
                id: .aaveMarket(network, market: aavePool, baseAsset: token)
            )
        else {
            return nil
        }

        let withdrawAmount = PricedAmount(amount, forAsset: earnMarket.baseAsset, withPrice: price)

        return WithdrawAction(earnMarket: earnMarket, withdrawAmount: withdrawAmount)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toWithdrawAction(portfolios: portfolios).map { .withdraw($0) }
    }
}

extension Charter.ActionContext.MorphoVaultWithdrawActionContext: ActionConvertible {
    public func toWithdrawAction(portfolios: [Portfolio]) -> WithdrawAction? {
        let network = Network.fromChainId(chainId)

        guard let earnMarket = portfolios.getEarnMarket(id: .morphoVault(network, morphoVault))
        else {
            return nil
        }

        let withdrawAmount = PricedAmount(amount, forAsset: earnMarket.baseAsset, withPrice: price)

        return WithdrawAction(earnMarket: earnMarket, withdrawAmount: withdrawAmount)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toWithdrawAction(portfolios: portfolios).map { .withdraw($0) }
    }
}

// MARK: Withdraw + Borrow

extension Charter.ActionContext.WithdrawAndBorrowActionContext: ActionConvertible {
    public func toWithdrawAndBorrowAction(portfolios: [Portfolio]) -> WithdrawAndBorrowAction? {
        let network = Network.fromChainId(chainId)

        guard let earnMarket = portfolios.getEarnMarket(id: .cometMarket(network, comet)) else {
            return nil
        }

        guard let borrowMarket = portfolios.getBorrowMarket(id: .cometMarket(network, comet)) else {
            return nil
        }

        guard earnMarket.baseAsset.address == token else {
            return nil
        }

        let withdrawAmount = PricedAmount(
            withdrawAmount,
            forAsset: borrowMarket.baseAsset,
            withPrice: price
        )
        let borrowAmount = PricedAmount(
            borrowAmount,
            forAsset: borrowMarket.baseAsset,
            withPrice: price
        )

        var collateralAmountsVal: [PricedAmount<CollateralAsset>] = []

        for (collateralAmount, collateralPrice, collateralToken) in zip3(
            collateralAmounts,
            collateralTokenPrices,
            collateralTokens
        ) {
            guard let collateralAsset = borrowMarket.getCollateralAsset(token: collateralToken)
            else {
                return nil
            }

            collateralAmountsVal.append(
                PricedAmount(
                    collateralAmount,
                    forAsset: collateralAsset,
                    withPrice: collateralPrice
                )
            )
        }

        return WithdrawAndBorrowAction(
            earnMarket: earnMarket,
            borrowMarket: borrowMarket,
            withdrawAmount: withdrawAmount,
            borrowAmount: borrowAmount,
            collateralAmounts: collateralAmountsVal
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toWithdrawAndBorrowAction(portfolios: portfolios).map { .withdrawBorrow($0) }
    }
}

extension Charter.ActionContext.RecurringSwapActionContext: ActionConvertible {
    public func toSwapAction(portfolios: [Portfolio]) -> RecurringSwapAction? {
        let network = Network.fromChainId(chainId)

        guard let inputAsset = portfolios.getAsset(token: inputToken, chain: network),
            let outputAsset = portfolios.getAsset(token: outputToken, chain: network)
        else {
            return nil
        }

        let buyAmount = PricedAmount(
            outputAmount,
            forAsset: outputAsset,
            withPrice: outputTokenPrice
        )
        let sellAmount = PricedAmount(inputAmount, forAsset: inputAsset, withPrice: inputTokenPrice)
        let frequency = Frequency(interval: interval)

        return RecurringSwapAction(
            buyAmount: buyAmount,
            sellAmount: sellAmount,
            feeAmount: nil,
            frequency: frequency,
            isExactOut: isExactOut,
            // TODO: Update when isBuy is on the actionContext
            isBuy: sellAmount.asset.symbol == "USDC"
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toSwapAction(portfolios: portfolios).map { .recurringSwap($0) }
    }
}

// MARK: Quote Pay

extension Charter.ActionContext.QuotePayActionContext: ActionConvertible {
    public func toQuotePayAction(portfolios: [Portfolio]) -> QuotePayAction? {
        let network = Network.fromChainId(chainId)

        guard let asset = portfolios.getAsset(token: token, chain: network) else {
            return nil
        }

        let amount = PricedAmount(amount, forAsset: asset, withPrice: price)

        return QuotePayAction(amount: amount, quoteId: quoteId)
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toQuotePayAction(portfolios: portfolios).map { .quotePay($0) }
    }
}

// MARK: Loop
extension Charter.ActionContext.LoopLongActionContext: ActionConvertible {
    public func toLoopLongAction(portfolios: [Portfolio]) -> LoopLongAction? {
        let network = Network.fromChainId(chainId)

        guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
            Logger.error(
                "Loop Long backing asset not found when creating loop long action. Token: \(backingToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        guard let exposureAsset = portfolios.getAsset(token: exposureToken, chain: network) else {
            Logger.error(
                "Loop Long exposure asset not found. Token: \(exposureToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        guard let feeAsset = portfolios.getAsset(token: feeToken, chain: network) else {
            Logger.error(
                "Loop Long fee asset not found. Token: \(feeToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        guard
            let borrowMarket = portfolios.getBorrowMarket(
                id: .morphoMarket(network, borrowMarketId)
            ),
            case .morphoMarket(let morphoMarket) = borrowMarket
        else {
            Logger.error(
                "Loop Long borrow market not found. Id: \(borrowMarketId), Chain: \(network.description)"
            )
            return nil
        }

        guard let swapVenue = DApp(from: swapVenue) else {
            Logger.error("Loop Long swap venue not found. Id: \(swapVenue)")
            return nil
        }

        let exposurePricedAmount = PricedAmount(
            exposureAmount,
            forAsset: exposureAsset,
            withPrice: exposureTokenPrice
        )

        let maxSwapBackingPricedAmount = PricedAmount(
            maxSwapBackingAmount,
            forAsset: backingAsset,
            withPrice: backingTokenPrice
        )

        let maxProvidedBackingPricedAmount = PricedAmount(
            maxProvidedBackingAmount,
            forAsset: backingAsset,
            withPrice: backingTokenPrice
        )

        let borrowValue: Value =
            maxSwapBackingPricedAmount.amountValue - maxProvidedBackingPricedAmount.amountValue
        let borrowPricedAmount = PricedAmount(
            value: borrowValue,
            price: backingTokenPrice,
            asset: backingAsset
        )

        let feePricedAmount = PricedAmount(
            feeAmount,
            forAsset: feeAsset,
            withPrice: feeTokenPrice
        )

        return .init(
            morphoMarket: morphoMarket,
            swapVenue: swapVenue,
            maxSwapBackingAmount: maxSwapBackingPricedAmount,
            maxProvidedBackingAmount: maxProvidedBackingPricedAmount,
            exposureAmount: exposurePricedAmount,
            borrowAmount: borrowPricedAmount,
            feeAmount: feePricedAmount,
            isIncrease: isIncrease
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toLoopLongAction(portfolios: portfolios).map { .loopLong($0) }
    }
}

extension Charter.ActionContext.UnloopLongActionContext: ActionConvertible {
    public func toUnloopLongAction(portfolios: [Portfolio]) -> UnloopLongAction? {
        let network = Network.fromChainId(chainId)

        guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
            Logger.error(
                "Unloop Long backing asset not found when creating unloop long action. Token: \(backingToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        guard let exposureAsset = portfolios.getAsset(token: exposureToken, chain: network) else {
            Logger.error(
                "Unloop Long exposure asset not found. Token: \(exposureToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        guard let feeAsset = portfolios.getAsset(token: feeToken, chain: network) else {
            Logger.error(
                "Unloop Long fee asset not found. Token: \(feeToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        guard
            let borrowMarket = portfolios.getBorrowMarket(
                id: .morphoMarket(network, borrowMarketId)
            ),
            case .morphoMarket(let morphoMarket) = borrowMarket
        else {
            Logger.error(
                "Unloop Long borrow market not found. Id: \(borrowMarketId), Chain: \(network.description)"
            )
            return nil
        }

        guard let swapVenue = DApp(from: swapVenue) else {
            Logger.error("Unloop Long swap venue not found. Id: \(swapVenue)")
            return nil
        }

        let minSwapBackingPricedAmount = PricedAmount(
            minSwapBackingAmount,
            forAsset: backingAsset,
            withPrice: backingTokenPrice
        )

        let exposurePricedAmount = PricedAmount(
            exposureAmount,
            forAsset: exposureAsset,
            withPrice: exposureTokenPrice
        )

        let feePricedAmount = PricedAmount(
            feeAmount,
            forAsset: feeAsset,
            withPrice: feeTokenPrice
        )

        return .init(
            morphoMarket: morphoMarket,
            swapVenue: swapVenue,
            minSwapBackingAmount: minSwapBackingPricedAmount,
            exposureAmount: exposurePricedAmount,
            feeAmount: feePricedAmount
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toUnloopLongAction(portfolios: portfolios).map { .unloopLong($0) }
    }
}

extension Charter.ActionContext.AddBackingTokenActionContext: ActionConvertible {
    public func toAddBackingTokenAction(portfolios: [Portfolio]) -> AddBackingTokenAction? {
        let network = Network.fromChainId(chainId)

        guard
            let borrowMarket = portfolios.getBorrowMarket(
                id: .morphoMarket(network, borrowMarketId)
            ),
            case .morphoMarket(let morphoMarket) = borrowMarket
        else {
            Logger.error(
                "Add backing token borrow market not found. Id: \(borrowMarketId), Chain: \(network.description)"
            )
            return nil
        }

        guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
            Logger.error(
                "Add backing token backing asset not found. Token: \(backingToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        let backingAmount = PricedAmount(
            amount,
            forAsset: backingAsset,
            withPrice: backingTokenPrice
        )

        let side: LoopPositionSide = isShort ? .short : .long

        return .init(
            morphoMarket: morphoMarket,
            backingAmount: backingAmount,
            side: side
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toAddBackingTokenAction(portfolios: portfolios).map { .addBackingToken($0) }
    }
}

extension Charter.ActionContext.WithdrawBackingTokenActionContext: ActionConvertible {
    public func toWithdrawBackingTokenAction(portfolios: [Portfolio]) -> WithdrawBackingTokenAction?
    {
        let network = Network.fromChainId(chainId)

        guard
            let borrowMarket = portfolios.getBorrowMarket(
                id: .morphoMarket(network, borrowMarketId)
            ),
            case .morphoMarket(let morphoMarket) = borrowMarket
        else {
            Logger.error(
                "Withdraw backing token borrow market not found. Id: \(borrowMarketId), Chain: \(network.description)"
            )
            return nil
        }

        guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
            Logger.error(
                "Withdraw backing token backing asset not found. Token: \(backingToken.hex), Chain: \(network.description)"
            )
            return nil
        }

        let backingAmount = PricedAmount(
            amount,
            forAsset: backingAsset,
            withPrice: backingTokenPrice
        )

        let side: LoopPositionSide = isShort ? .short : .long

        return .init(
            morphoMarket: morphoMarket,
            backingAmount: backingAmount,
            side: side
        )
    }

    public func toAction(portfolios: [Portfolio]) -> Action? {
        toWithdrawBackingTokenAction(portfolios: portfolios).map { .withdrawBackingToken($0) }
    }
}
