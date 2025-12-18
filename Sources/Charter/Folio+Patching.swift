import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber

typealias BalanceType = Folio.BalanceType

// MARK: - Helper Functions

func getTokenSymbolByAddress(network: Network, token: EthAddress) throws -> String {
    if let atlasNetwork = Atlas.getNetwork(network: network),
        let asset = atlasNetwork.getAssetByAddress(token)
    {
        return asset.symbol
    }

    throw PatchError.tokenSymbolNotFound(token: token)
}

func getActualAmount(amount: Number, balances: [BalanceType: Amount], balanceType: BalanceType)
    throws -> Number
{
    if amount.isMaxUint256 {
        guard let balance = balances[balanceType] else {
            throw PatchError.balanceNotFound(balanceType: balanceType)
        }

        return balance.underlying
    }

    return amount
}

func repayToBorrowMarket(
    balances: inout [BalanceType: Amount],
    underlyingTokenBalanceType: BalanceType,
    borrowMarketBalanceType: BalanceType,
    collateralAmounts: [(BalanceType, BalanceType, Number)],
    repayAmount: Number
) throws {
    let actualRepayAmount = try getActualAmount(
        amount: repayAmount,
        balances: balances,
        balanceType: borrowMarketBalanceType
    )

    // Send away underlying token to borrow market
    try reduceBalance(
        balances: &balances,
        balanceType: underlyingTokenBalanceType,
        amount: actualRepayAmount
    )

    // Remove debt from borrow market
    try reduceBalance(
        balances: &balances,
        balanceType: borrowMarketBalanceType,
        amount: actualRepayAmount
    )

    for (marketCollateralBalanceType, collateralTokenBalanceType, collateralAmount)
        in collateralAmounts
    {
        // Remove collateral position from market
        try reduceBalance(
            balances: &balances,
            balanceType: marketCollateralBalanceType,
            amount: collateralAmount
        )

        // Receive back collateral token
        try augmentBalance(
            balances: &balances,
            balanceType: collateralTokenBalanceType,
            amount: collateralAmount
        )
    }
}

func borrowFromBorrowMarket(
    balances: inout [BalanceType: Amount],
    borrowTokenBalanceType: BalanceType,
    borrowMarketBalanceType: BalanceType,
    collateralAmounts: [(BalanceType, BalanceType, Number)],
    borrowAmount: Number
) throws {
    // Receive borrowed token
    try augmentBalance(
        balances: &balances,
        balanceType: borrowTokenBalanceType,
        amount: borrowAmount
    )

    // Add debt to borrow market
    try augmentBalance(
        balances: &balances,
        balanceType: borrowMarketBalanceType,
        amount: borrowAmount
    )

    // Take away collateral from wallet
    for (marketCollateralBalanceType, collateralTokenBalanceType, collateralAmount)
        in collateralAmounts
    {
        // Send away collateral token from wallet
        try reduceBalance(
            balances: &balances,
            balanceType: collateralTokenBalanceType,
            amount: collateralAmount
        )

        // Add collateral to borrow market
        try augmentBalance(
            balances: &balances,
            balanceType: marketCollateralBalanceType,
            amount: collateralAmount
        )
    }
}

func withdrawFromYieldMarket(
    balances: inout [BalanceType: Amount],
    underlyingTokenBalanceType: BalanceType,
    yieldMarketBalanceType: BalanceType,
    withdrawAmount: Number
) throws {
    let actualWithdrawAmount = try getActualAmount(
        amount: withdrawAmount,
        balances: balances,
        balanceType: yieldMarketBalanceType
    )

    // Gain underlying token
    try augmentBalance(
        balances: &balances,
        balanceType: underlyingTokenBalanceType,
        amount: actualWithdrawAmount
    )

    // Take away from yield market balance
    try reduceBalance(
        balances: &balances,
        balanceType: yieldMarketBalanceType,
        amount: actualWithdrawAmount
    )
}

func supplyToYieldMarket(
    balances: inout [BalanceType: Amount],
    underlyingTokenBalanceType: BalanceType,
    yieldMarketBalanceType: BalanceType,
    supplyAmount: Number
) throws {
    let actualSupplyAmount = try getActualAmount(
        amount: supplyAmount,
        balances: balances,
        balanceType: underlyingTokenBalanceType
    )

    // Send away underlying token from wallet
    try reduceBalance(
        balances: &balances,
        balanceType: underlyingTokenBalanceType,
        amount: actualSupplyAmount
    )

    // Receive yield market balance
    try augmentBalance(
        balances: &balances,
        balanceType: yieldMarketBalanceType,
        amount: actualSupplyAmount
    )
}

func augmentBalance(
    balances: inout [BalanceType: Amount],
    balanceType: BalanceType,
    amount: Number
) throws {
    if let balance = balances[balanceType] {
        balances[balanceType] = balance + amount
    } else {
        guard let atlasAsset = balanceType.atlasAsset else {
            throw PatchError.balanceNotFound(balanceType: balanceType)
        }
        balances[balanceType] = Amount(amount, decimals: Int(atlasAsset.decimals))
    }
}

func reduceBalance(
    balances: inout [BalanceType: Amount],
    balanceType: BalanceType,
    amount: Number
) throws {
    guard let balance = balances[balanceType] else {
        throw PatchError.balanceNotFound(balanceType: balanceType)
    }

    let newBalance =
        balance.underlying < amount ? Amount(0, decimals: balance.decimals) : balance - amount
    balances[balanceType] = newBalance
}

enum PatchError: Error, CustomStringConvertible, Equatable {
    case swapHintNotFound(
        underlyingNetwork: Network,
        underlyingSymbol: String,
        wrappedNetwork: Network,
        wrappedSymbol: String
    )
    case balanceNotFound(balanceType: BalanceType)
    case insufficientBalance(balanceType: BalanceType)
    case tokenSymbolNotFound(token: EthAddress)
    case invalidExchangeRate(exchangeRate: Percentage)

    var description: String {
        switch self {
            case .swapHintNotFound(
                let underlyingNetwork,
                let underlyingSymbol,
                let wrappedNetwork,
                let wrappedSymbol
            ):
                return
                    "Swap hint not found for underlying network: \(underlyingNetwork), underlying symbol: \(underlyingSymbol), wrapped network: \(wrappedNetwork), wrapped symbol: \(wrappedSymbol)"
            case .balanceNotFound(let balanceType):
                return "Balance not found for balance type: \(balanceType)"
            case .insufficientBalance(let balanceType):
                return "Insufficient balance for balance type: \(balanceType)"
            case .tokenSymbolNotFound(let token):
                return "Token symbol not found for token: \(token)"
            case .invalidExchangeRate(let exchangeRate):
                return "Invalid exchange rate: \(exchangeRate)"
        }
    }
}

extension Folio {
    public func patch(
        withActionContext actionContext: Charter.ActionContext,
        andQuarkWalletAddress quarkWalletAddress: EthAddress,
        logger: Charter.Logger? = nil
    ) -> Folio {
        var newBalances = self.balances
        do {
            try Folio.patchBalances(
                balances: &newBalances,
                swapHints: self.swapHints,
                withActionContext: actionContext,
                andQuarkWalletAddress: quarkWalletAddress
            )
        } catch {
            logger?.log("[Folio+Patching] Error patching balances: \(error)")
            return self
        }

        return Folio(
            balances: newBalances,
            prices: self.prices,
            yieldMarkets: self.yieldMarkets,
            borrowMarkets: self.borrowMarkets,
            rewards: self.rewards,
            swapHints: self.swapHints,
            bridgeHints: self.bridgeHints,
            hexData: self.hexData,
            completionStatuses: self.completionStatuses
        )
    }

    public static func patchBalances(
        balances: inout [BalanceType: Amount],
        swapHints: [SwapHintType: SwapHint],
        withActionContext actionContext: Charter.ActionContext,
        andQuarkWalletAddress quarkWalletAddress: EthAddress
    ) throws {
        switch actionContext {
            case .transfer(let context):
                // Transfer takes tokens from sender, gives to recipient

                // Transfer out from sender
                try reduceBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: Network.fromChainId(context.chainId),
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.amount
                )

                // Transfer in to recipient
                try augmentBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: Network.fromChainId(context.chainId),
                        symbol: context.assetSymbol,
                        wallet: context.recipient
                    ),
                    amount: context.amount
                )

            case .bridge(let context):
                // Bridge takes tokens from source chain, add to destination chain

                // Transfer out from sender
                try reduceBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: Network.fromChainId(context.chainId),
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.inputAmount
                )

                // Transfer in to recipient
                try augmentBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: Network.fromChainId(context.destinationChainId),
                        symbol: context.destinationAssetSymbol,
                        wallet: context.recipient
                    ),
                    amount: context.outputAmount
                )

            case .swap(let context):
                // Swap takes tokens from input asset, gives to output asset

                // Swap out input token
                try reduceBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: Network.fromChainId(context.chainId),
                        symbol: context.inputAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.inputAmount
                )

                // Swap in output token
                try augmentBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: Network.fromChainId(context.chainId),
                        symbol: context.outputAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.outputAmount
                )

            case .quotePay(let context):
                // Quote pay takes tokens from wallet

                // Transfer out from payer
                try reduceBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: Network.fromChainId(context.chainId),
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.amount
                )

            case .wrap(let context):
                // Wrap takes tokens from input asset, gives to output asset
                let network = Network.fromChainId(context.chainId)

                // TODO: Ensure we're getting from and to asset symbols correctly.
                guard
                    let swapHint = swapHints[
                        .wrapper(
                            underlyingNetwork: network,
                            underlyingSymbol: context.fromAssetSymbol,
                            wrappedNetwork: network,
                            wrappedSymbol: context.toAssetSymbol
                        )
                    ]
                else {
                    throw PatchError.swapHintNotFound(
                        underlyingNetwork: network,
                        underlyingSymbol: context.fromAssetSymbol,
                        wrappedNetwork: network,
                        wrappedSymbol: context.toAssetSymbol
                    )
                }

                guard swapHint.exchangeRate.underlying > 0 else {
                    throw PatchError.invalidExchangeRate(exchangeRate: swapHint.exchangeRate)
                }

                // Transfer out underlying token
                try reduceBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: network,
                        symbol: context.fromAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.amount
                )

                // Receive wrapped token
                try augmentBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: network,
                        symbol: context.toAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: Number(context.amount / swapHint.exchangeRate)
                )

            case .unwrap(let context):
                // Unwrap takes tokens from input asset, gives to output asset
                let network = Network.fromChainId(context.chainId)

                // TODO: Ensure we're getting from and to asset symbols correctly.
                guard
                    let swapHint = swapHints[
                        .wrapper(
                            underlyingNetwork: network,
                            underlyingSymbol: context.toAssetSymbol,
                            wrappedNetwork: network,
                            wrappedSymbol: context.fromAssetSymbol
                        )
                    ]
                else {
                    throw PatchError.swapHintNotFound(
                        underlyingNetwork: network,
                        underlyingSymbol: context.toAssetSymbol,
                        wrappedNetwork: network,
                        wrappedSymbol: context.fromAssetSymbol
                    )
                }

                guard swapHint.exchangeRate.underlying > 0 else {
                    throw PatchError.invalidExchangeRate(exchangeRate: swapHint.exchangeRate)
                }

                // Transfer out wrapped token
                try reduceBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: network,
                        symbol: context.fromAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.amount
                )

                // Receive underlying token
                try augmentBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: network,
                        symbol: context.toAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: Number(context.amount * swapHint.exchangeRate)
                )

            case .aaveSupply(let context):
                // Supply takes tokens from wallet, gives to yield market
                let network = Network.fromChainId(context.chainId)

                try supplyToYieldMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    yieldMarketBalanceType: .yieldMarket(
                        yieldMarket: .aave(
                            network: network,
                            pool: context.aavePool,
                            underlyingSymbol: context.assetSymbol
                        ),
                        wallet: quarkWalletAddress
                    ),
                    supplyAmount: context.amount
                )

            case .cometSupply(let context):
                // Supply takes tokens from wallet, gives to yield market
                let network = Network.fromChainId(context.chainId)

                try supplyToYieldMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    yieldMarketBalanceType: .yieldMarket(
                        yieldMarket: .comet(
                            network: network,
                            comet: context.comet,
                            underlyingSymbol: context.assetSymbol
                        ),
                        wallet: quarkWalletAddress
                    ),
                    supplyAmount: context.amount
                )

            case .morphoVaultSupply(let context):
                // Supply takes tokens from wallet, gives to yield market
                let network = Network.fromChainId(context.chainId)

                try supplyToYieldMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    yieldMarketBalanceType: .yieldMarket(
                        yieldMarket: .morphoVault(
                            network: network,
                            vault: context.morphoVault,
                            underlyingSymbol: context.assetSymbol
                        ),
                        wallet: quarkWalletAddress
                    ),
                    supplyAmount: context.amount
                )

            case .aaveWithdraw(let context):
                // Withdraw takes tokens from yield market, gives to wallet
                let network = Network.fromChainId(context.chainId)

                try withdrawFromYieldMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    yieldMarketBalanceType: .yieldMarket(
                        yieldMarket: .aave(
                            network: network,
                            pool: context.aavePool,
                            underlyingSymbol: context.assetSymbol
                        ),
                        wallet: quarkWalletAddress
                    ),
                    withdrawAmount: context.amount
                )

            case .cometWithdraw(let context):
                // Withdraw takes tokens from yield market, gives to wallet
                let network = Network.fromChainId(context.chainId)

                try withdrawFromYieldMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    yieldMarketBalanceType: .yieldMarket(
                        yieldMarket: .comet(
                            network: network,
                            comet: context.comet,
                            underlyingSymbol: context.assetSymbol
                        ),
                        wallet: quarkWalletAddress
                    ),
                    withdrawAmount: context.amount
                )

            case .morphoVaultWithdraw(let context):
                // Withdraw takes tokens from yield market, gives to wallet
                let network = Network.fromChainId(context.chainId)

                try withdrawFromYieldMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    yieldMarketBalanceType: .yieldMarket(
                        yieldMarket: .morphoVault(
                            network: network,
                            vault: context.morphoVault,
                            underlyingSymbol: context.assetSymbol
                        ),
                        wallet: quarkWalletAddress
                    ),
                    withdrawAmount: context.amount
                )

            case .cometBorrow(let context):
                let network = Network.fromChainId(context.chainId)
                let borrowMarket: Folio.BorrowMarketType = .comet(
                    network: network,
                    comet: context.comet,
                    underlyingSymbol: context.assetSymbol
                )

                let collateralAmounts: [(BalanceType, BalanceType, Number)] = zip(
                    context.collateralAssetSymbols,
                    context.collateralAmounts
                )
                .map {
                    (
                        .borrowMarketCollateral(
                            borrowMarket: borrowMarket,
                            tokenSymbol: $0.0,
                            wallet: quarkWalletAddress
                        ),
                        .token(
                            network: network,
                            symbol: $0.0,
                            wallet: quarkWalletAddress
                        ),
                        $0.1
                    )
                }

                try borrowFromBorrowMarket(
                    balances: &balances,
                    borrowTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    borrowMarketBalanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    collateralAmounts: collateralAmounts,
                    borrowAmount: context.amount
                )

            case .morphoBorrow(let context):
                let network = Network.fromChainId(context.chainId)

                let borrowMarket: Folio.BorrowMarketType = .morpho(
                    network: network,
                    collateralTokenSymbol: context.collateralAssetSymbol,
                    borrowTokenSymbol: context.assetSymbol
                )

                let collateralAmounts: [(BalanceType, BalanceType, Number)] = [
                    (
                        .borrowMarketCollateral(
                            borrowMarket: borrowMarket,
                            tokenSymbol: context.collateralAssetSymbol,
                            wallet: quarkWalletAddress
                        ),
                        .token(
                            network: network,
                            symbol: context.collateralAssetSymbol,
                            wallet: quarkWalletAddress
                        ),
                        context.collateralAmount
                    )
                ]

                try borrowFromBorrowMarket(
                    balances: &balances,
                    borrowTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    borrowMarketBalanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    collateralAmounts: collateralAmounts,
                    borrowAmount: context.amount
                )

            case .cometRepay(let context):
                // Repay takes borrowed token from wallet, receives collateral tokens
                let network = Network.fromChainId(context.chainId)
                let borrowMarket: Folio.BorrowMarketType = .comet(
                    network: network,
                    comet: context.comet,
                    underlyingSymbol: context.assetSymbol
                )

                let collateralAmounts: [(BalanceType, BalanceType, Number)] = zip(
                    context.collateralAssetSymbols,
                    context.collateralAmounts
                )
                .map {
                    (
                        .borrowMarketCollateral(
                            borrowMarket: borrowMarket,
                            tokenSymbol: $0.0,
                            wallet: quarkWalletAddress
                        ),
                        .token(
                            network: network,
                            symbol: $0.0,
                            wallet: quarkWalletAddress
                        ),
                        $0.1
                    )
                }

                try repayToBorrowMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    borrowMarketBalanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    collateralAmounts: collateralAmounts,
                    repayAmount: context.amount
                )

            case .morphoRepay(let context):
                // Repay takes borrowed token from wallet, receives collateral tokens
                let network = Network.fromChainId(context.chainId)
                let borrowMarket: Folio.BorrowMarketType = .morpho(
                    network: network,
                    collateralTokenSymbol: context.collateralAssetSymbol,
                    borrowTokenSymbol: context.assetSymbol
                )

                let collateralAmounts: [(BalanceType, BalanceType, Number)] = [
                    (
                        .borrowMarketCollateral(
                            borrowMarket: borrowMarket,
                            tokenSymbol: context.collateralAssetSymbol,
                            wallet: quarkWalletAddress
                        ),
                        .token(
                            network: network,
                            symbol: context.collateralAssetSymbol,
                            wallet: quarkWalletAddress
                        ),
                        context.collateralAmount
                    )
                ]

                try repayToBorrowMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.assetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    borrowMarketBalanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    collateralAmounts: collateralAmounts,
                    repayAmount: context.amount
                )

            case .cometClaimRewards(let context):
                // Add reward tokens to wallet
                for index in 0..<context.tokens.count {
                    try augmentBalance(
                        balances: &balances,
                        balanceType: .token(
                            network: Network.fromChainId(context.chainId),
                            symbol: context.assetSymbols[index],
                            wallet: quarkWalletAddress
                        ),
                        amount: context.amounts[index]
                    )
                }

            case .morphoClaimRewards(let context):
                // Add reward tokens
                for index in 0..<context.tokens.count {
                    try augmentBalance(
                        balances: &balances,
                        balanceType: .token(
                            network: Network.fromChainId(context.chainId),
                            symbol: context.assetSymbols[index],
                            wallet: quarkWalletAddress
                        ),
                        amount: context.amounts[index]
                    )
                }

            case .multiAction(let actionContexts):
                // Recursively applies each action
                for subAction in actionContexts {
                    try patchBalances(
                        balances: &balances,
                        swapHints: swapHints,
                        withActionContext: subAction,
                        andQuarkWalletAddress: quarkWalletAddress
                    )
                }

            case .withdrawAndBorrow(let context):
                // Withdraw and borrow are implemented as composite of withdraw and borrow
                let network = Network.fromChainId(context.chainId)

                let underlyingTokenSymbol = try getTokenSymbolByAddress(
                    network: network,
                    token: context.token
                )

                let borrowMarket: Folio.BorrowMarketType = .comet(
                    network: network,
                    comet: context.comet,
                    underlyingSymbol: underlyingTokenSymbol
                )

                let collateralSymbolAmounts: [(String, Number)] = try zip(
                    context.collateralTokens,
                    context.collateralAmounts
                )
                .map {
                    let (collateralTokenAddress, collateralAmount) = $0

                    return (
                        try getTokenSymbolByAddress(
                            network: network,
                            token: collateralTokenAddress
                        ),
                        collateralAmount
                    )
                }

                let collateralAmounts: [(BalanceType, BalanceType, Number)] =
                    collateralSymbolAmounts.map {
                        let (collateralTokenSymbol, collateralAmount) = $0

                        return (
                            .borrowMarketCollateral(
                                borrowMarket: borrowMarket,
                                tokenSymbol: collateralTokenSymbol,
                                wallet: quarkWalletAddress
                            ),
                            .token(
                                network: network,
                                symbol: collateralTokenSymbol,
                                wallet: quarkWalletAddress
                            ),
                            collateralAmount
                        )
                    }

                if context.withdrawAmount > Number(0) {
                    try withdrawFromYieldMarket(
                        balances: &balances,
                        underlyingTokenBalanceType: .token(
                            network: network,
                            symbol: underlyingTokenSymbol,
                            wallet: quarkWalletAddress
                        ),
                        yieldMarketBalanceType: .yieldMarket(
                            yieldMarket: .comet(
                                network: network,
                                comet: context.comet,
                                underlyingSymbol: underlyingTokenSymbol
                            ),
                            wallet: quarkWalletAddress
                        ),
                        withdrawAmount: context.withdrawAmount
                    )
                }

                if context.borrowAmount > Number(0) {
                    try borrowFromBorrowMarket(
                        balances: &balances,
                        borrowTokenBalanceType: .token(
                            network: network,
                            symbol: underlyingTokenSymbol,
                            wallet: quarkWalletAddress
                        ),
                        borrowMarketBalanceType: .borrowMarket(
                            borrowMarket: borrowMarket,
                            wallet: quarkWalletAddress
                        ),
                        collateralAmounts: collateralAmounts,
                        borrowAmount: context.borrowAmount
                    )
                }

            case .recurringSwap:
                // Recurring swaps don't affect current balances - they're scheduled for future
                break

            case .addBackingToken(let context):
                // Transfers out backing token, acts as a Morpho repay
                let network = Network.fromChainId(context.chainId)
                let borrowMarket: Folio.BorrowMarketType = .morpho(
                    network: network,
                    collateralTokenSymbol: context.exposureAssetSymbol,
                    borrowTokenSymbol: context.backingAssetSymbol
                )

                // Acts as a repay to Morpho with no collateral changes
                try repayToBorrowMarket(
                    balances: &balances,
                    underlyingTokenBalanceType: .token(
                        network: network,
                        symbol: context.backingAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    borrowMarketBalanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    collateralAmounts: [],
                    repayAmount: context.amount
                )

            case .withdrawBackingToken(let context):
                // Receives backing token, acts as Morpho borrow
                let network = Network.fromChainId(context.chainId)
                let borrowMarket: Folio.BorrowMarketType = .morpho(
                    network: network,
                    collateralTokenSymbol: context.exposureAssetSymbol,
                    borrowTokenSymbol: context.backingAssetSymbol
                )

                // Acts as a borrow from Morpho with no collateral changes
                try borrowFromBorrowMarket(
                    balances: &balances,
                    borrowTokenBalanceType: .token(
                        network: network,
                        symbol: context.backingAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    borrowMarketBalanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    collateralAmounts: [],
                    borrowAmount: context.amount
                )

            case .loopLong(let context):
                // Acts as a reduction in backing token and a Morpho borrow
                let network = Network.fromChainId(context.chainId)
                let borrowMarket: Folio.BorrowMarketType = .morpho(
                    network: network,
                    collateralTokenSymbol: context.exposureAssetSymbol,
                    borrowTokenSymbol: context.backingAssetSymbol
                )

                // Reduce backing token
                try reduceBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: network,
                        symbol: context.backingAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.maxProvidedBackingAmount
                )

                // Add debt to borrow market
                try augmentBalance(
                    balances: &balances,
                    balanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.maxSwapBackingAmount - context.maxProvidedBackingAmount
                )

                // Add collateral to borrow market
                try augmentBalance(
                    balances: &balances,
                    balanceType: .borrowMarketCollateral(
                        borrowMarket: borrowMarket,
                        tokenSymbol: context.exposureAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.exposureAmount
                )

            case .unloopLong(let context):
                // Acts as a reduction in backing token and a Morpho borrow
                let network = Network.fromChainId(context.chainId)
                let borrowMarket: Folio.BorrowMarketType = .morpho(
                    network: network,
                    collateralTokenSymbol: context.exposureAssetSymbol,
                    borrowTokenSymbol: context.backingAssetSymbol
                )

                // Add backing token
                try augmentBalance(
                    balances: &balances,
                    balanceType: .token(
                        network: network,
                        symbol: context.backingAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.backingAmountToExit
                )

                // Remove debt from borrow market
                try reduceBalance(
                    balances: &balances,
                    balanceType: .borrowMarket(
                        borrowMarket: borrowMarket,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.minSwapBackingAmount - context.backingAmountToExit
                )

                // Remove collateral to borrow market
                try reduceBalance(
                    balances: &balances,
                    balanceType: .borrowMarketCollateral(
                        borrowMarket: borrowMarket,
                        tokenSymbol: context.exposureAssetSymbol,
                        wallet: quarkWalletAddress
                    ),
                    amount: context.exposureAmount
                )

            case .loopShort(_):
                // TODO: Not implemented
                break

            case .unloopShort(_):
                // TODO: Not implemented
                break
        }
    }
}
