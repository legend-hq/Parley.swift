import Eth
import Prelude
import SwiftNumber

extension Charter {
    public enum QuarkIntentError: Error {
        case notImplemented
    }

    public struct QuarkIntent: Equatable, Codable, Sendable, Hashable {
        public let type: Type_
        public let blockTimestamp: Number

        public enum Type_: Equatable, Codable, Sendable, Hashable {
            case aaveSupply(AaveSupplyIntent)
            case aaveWithdraw(AaveWithdrawIntent)
            case addBackingToken(AddBackingTokenIntent)
            case claimRewards(ClaimRewardsIntent)
            case cometBorrow(CometBorrowIntent)
            case cometRepay(CometRepayIntent)
            case cometSupply(CometSupplyIntent)
            case cometWithdraw(CometWithdrawIntent)
            case compounder(CompounderIntent)
            case loopLong(LoopLongIntent)
            case loopShort(LoopShortIntent)
            case migrateSupplies(MigrateSuppliesIntent)
            case morphoBorrow(MorphoBorrowIntent)
            case morphoRepay(MorphoRepayIntent)
            case morphoVaultSupply(MorphoVaultSupplyIntent)
            case morphoVaultWithdraw(MorphoVaultWithdrawIntent)
            case recurringSwap(RecurringSwapIntent)
            case supply(SupplyIntent)
            case swapAndSupply(SwapAndSupplyIntent)
            case swap(SwapIntent)
            case transfer(TransferIntent)
            case unloopLong(UnloopLongIntent)
            case unloopShort(UnloopShortIntent)
            case withdrawBackingToken(WithdrawBackingTokenIntent)
            case withdraw(WithdrawIntent)

            public var intentType: String {
                switch self {
                    case .aaveSupply: return "aave_supply"
                    case .aaveWithdraw: return "aave_withdraw"
                    case .addBackingToken: return "add_backing_token"
                    case .claimRewards: return "claim_rewards"
                    case .cometBorrow: return "comet_borrow"
                    case .cometRepay: return "comet_repay"
                    case .cometSupply: return "comet_supply"
                    case .cometWithdraw: return "comet_withdraw"
                    case .compounder: return "compounder"
                    case .loopLong: return "loop_long"
                    case .loopShort: return "loop_short"
                    case .migrateSupplies: return "migrate_supplies"
                    case .morphoBorrow: return "morpho_borrow"
                    case .morphoRepay: return "morpho_repay"
                    case .morphoVaultSupply: return "morpho_vault_supply"
                    case .morphoVaultWithdraw: return "morpho_vault_withdraw"
                    case .recurringSwap: return "recurring_swap"
                    case .supply: return "supply"
                    case .swapAndSupply: return "swap_and_supply"
                    case .swap: return "swap"
                    case .transfer: return "transfer"
                    case .unloopLong: return "unloop_long"
                    case .unloopShort: return "unloop_short"
                    case .withdraw: return "withdraw"
                    case .withdrawBackingToken: return "withdraw_backing_token"
                }
            }

            var assetAmounts: [(assetSymbol: String, amount: Number)] {
                switch self {
                    case .transfer(let transferIntent):
                        return [
                            (
                                assetSymbol: transferIntent.assetSymbol,
                                amount: transferIntent.amount
                            )
                        ]
                    default:
                        return []
                }
            }

            var network: Network {
                switch self {
                    case .transfer(let transferIntent):
                        return Network.fromChainId(transferIntent.chainId)
                    case .migrateSupplies(let migrateSuppliesIntent):
                        return Network.fromChainId(migrateSuppliesIntent.supplyIntent.chainId)
                    default:
                        return .unknown(Number(0))
                }
            }

            var isRecurringSwap: Bool {
                switch self {
                    case .recurringSwap:
                        return true
                    default:
                        return false
                }
            }

            var isMaxIntent: Bool {
                switch self {
                    case .transfer(let transferIntent):
                        return transferIntent.amount.isMaxUint256
                    case .aaveSupply(let aaveSupplyIntent):
                        return aaveSupplyIntent.amount.isMaxUint256
                    case .aaveWithdraw(let aaveWithdrawIntent):
                        return aaveWithdrawIntent.amount.isMaxUint256
                    case .addBackingToken(let addBackingTokenIntent):
                        return addBackingTokenIntent.amount.isMaxUint256
                    case .claimRewards:
                        return false
                    case .cometBorrow(let cometBorrowIntent):
                        return cometBorrowIntent.isMaxIntent
                    case .cometRepay(let cometRepayIntent):
                        return cometRepayIntent.isMaxIntent
                    case .cometSupply(let cometSupplyIntent):
                        return cometSupplyIntent.amount.isMaxUint256
                    case .cometWithdraw(let cometWithdrawIntent):
                        return cometWithdrawIntent.amount.isMaxUint256
                    case .compounder(let compounderIntent):
                        return compounderIntent.supplyIntent.amount.isMaxUint256
                    case .loopLong(let loopLongIntent):
                        return loopLongIntent.maxProvidedBackingAmount.isMaxUint256
                    case .loopShort(let loopShortIntent):
                        return loopShortIntent.providedBackingAmount.isMaxUint256
                    case .migrateSupplies(let migrateSuppliesIntent):
                        return migrateSuppliesIntent.supplyIntent.amount.isMaxUint256
                    case .morphoBorrow(let morphoBorrowIntent):
                        return morphoBorrowIntent.isMaxIntent
                    case .morphoRepay(let morphoRepayIntent):
                        return morphoRepayIntent.isMaxIntent
                    case .morphoVaultSupply(let morphoVaultSupplyIntent):
                        return morphoVaultSupplyIntent.amount.isMaxUint256
                    case .morphoVaultWithdraw(let morphoVaultWithdrawIntent):
                        return morphoVaultWithdrawIntent.amount.isMaxUint256
                    case .recurringSwap:
                        return false
                    case .supply(let supplyIntent):
                        return supplyIntent.amount.isMaxUint256
                    case .swapAndSupply(let swapAndSupplyIntent):
                        return swapAndSupplyIntent.supplyIntent.amount.isMaxUint256
                    case .swap(let swapIntent):
                        return swapIntent.sellAmount.isMaxUint256
                    case .unloopLong(let unloopLongIntent):
                        return unloopLongIntent.exposureAmount.isMaxUint256
                    case .unloopShort(let unloopShortIntent):
                        return unloopShortIntent.exposureAmount.isMaxUint256
                    case .withdraw(let withdrawIntent):
                        return withdrawIntent.amount.isMaxUint256
                    case .withdrawBackingToken(let withdrawBackingTokenIntent):
                        return withdrawBackingTokenIntent.amount.isMaxUint256
                }
            }

            var maxIntent: Type_ {
                switch self {
                    case .transfer(let transferIntent):
                        return .transfer(
                            TransferIntent(
                                chainId: transferIntent.chainId,
                                assetSymbol: transferIntent.assetSymbol,
                                amount: Number.MAX_UINT_256,
                                sender: transferIntent.sender,
                                recipient: transferIntent.recipient
                            )
                        )
                    case .aaveSupply(let aaveSupplyIntent):
                        return .aaveSupply(
                            AaveSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: aaveSupplyIntent.assetSymbol,
                                chainId: aaveSupplyIntent.chainId,
                                aavePool: aaveSupplyIntent.aavePool,
                                sender: aaveSupplyIntent.sender
                            )
                        )
                    case .aaveWithdraw(let aaveWithdrawIntent):
                        return .aaveWithdraw(
                            AaveWithdrawIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: aaveWithdrawIntent.assetSymbol,
                                chainId: aaveWithdrawIntent.chainId,
                                aavePool: aaveWithdrawIntent.aavePool,
                                withdrawer: aaveWithdrawIntent.withdrawer
                            )
                        )
                    case .addBackingToken(let addBackingTokenIntent):
                        return .addBackingToken(
                            AddBackingTokenIntent(
                                exposureAssetSymbol: addBackingTokenIntent.exposureAssetSymbol,
                                backingAssetSymbol: addBackingTokenIntent.backingAssetSymbol,
                                marketId: addBackingTokenIntent.marketId,
                                amount: Number.MAX_UINT_256,
                                isShort: addBackingTokenIntent.isShort,
                                sender: addBackingTokenIntent.sender,
                                chainId: addBackingTokenIntent.chainId
                            )
                        )
                    case .claimRewards:
                        return self
                    case .cometBorrow(let cometBorrowIntent):
                        return .cometBorrow(
                            CometBorrowIntent(
                                amount: cometBorrowIntent.amount,
                                assetSymbol: cometBorrowIntent.assetSymbol,
                                borrower: cometBorrowIntent.borrower,
                                chainId: cometBorrowIntent.chainId,
                                collateralAmount: Number.MAX_UINT_256,
                                collateralAssetSymbol: cometBorrowIntent.collateralAssetSymbol,
                                comet: cometBorrowIntent.comet
                            )
                        )
                    case .cometRepay(let cometRepayIntent):
                        return .cometRepay(
                            CometRepayIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: cometRepayIntent.assetSymbol,
                                chainId: cometRepayIntent.chainId,
                                collateralAmount: cometRepayIntent.collateralAmount,
                                collateralAssetSymbol: cometRepayIntent.collateralAssetSymbol,
                                comet: cometRepayIntent.comet,
                                repayer: cometRepayIntent.repayer
                            )
                        )
                    case .cometSupply(let cometSupplyIntent):
                        return .cometSupply(
                            CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: cometSupplyIntent.assetSymbol,
                                chainId: cometSupplyIntent.chainId,
                                comet: cometSupplyIntent.comet,
                                sender: cometSupplyIntent.sender
                            )
                        )
                    case .cometWithdraw(let cometWithdrawIntent):
                        return .cometWithdraw(
                            CometWithdrawIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: cometWithdrawIntent.assetSymbol,
                                chainId: cometWithdrawIntent.chainId,
                                comet: cometWithdrawIntent.comet,
                                withdrawer: cometWithdrawIntent.withdrawer
                            )
                        )
                    case .compounder(let compounderIntent):
                        let maxSupplyIntent: SupplyIntent
                        switch compounderIntent.supplyIntent {
                            case .aave(let aaveIntent):
                                maxSupplyIntent = .aave(
                                    AaveSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: aaveIntent.assetSymbol,
                                        chainId: aaveIntent.chainId,
                                        aavePool: aaveIntent.aavePool,
                                        sender: aaveIntent.sender
                                    )
                                )
                            case .comet(let cometIntent):
                                maxSupplyIntent = .comet(
                                    CometSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: cometIntent.assetSymbol,
                                        chainId: cometIntent.chainId,
                                        comet: cometIntent.comet,
                                        sender: cometIntent.sender
                                    )
                                )
                            case .morpho(let morphoIntent):
                                maxSupplyIntent = .morpho(
                                    MorphoVaultSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: morphoIntent.assetSymbol,
                                        morphoVault: morphoIntent.morphoVault,
                                        sender: morphoIntent.sender,
                                        chainId: morphoIntent.chainId
                                    )
                                )
                        }
                        return .compounder(
                            CompounderIntent(
                                claimRewardsIntent: compounderIntent.claimRewardsIntent,
                                swapIntent: compounderIntent.swapIntent,
                                supplyIntent: maxSupplyIntent
                            )
                        )
                    case .loopLong(let loopLongIntent):
                        return .loopLong(
                            LoopLongIntent(
                                exposureAssetSymbol: loopLongIntent.exposureAssetSymbol,
                                backingAssetSymbol: loopLongIntent.backingAssetSymbol,
                                marketId: loopLongIntent.marketId,
                                isIncrease: loopLongIntent.isIncrease,
                                exposureAmount: loopLongIntent.exposureAmount,
                                maxSwapBackingAmount: loopLongIntent.maxSwapBackingAmount,
                                maxProvidedBackingAmount: Number.MAX_UINT_256,
                                poolFee: loopLongIntent.poolFee,
                                sender: loopLongIntent.sender,
                                chainId: loopLongIntent.chainId
                            )
                        )
                    case .loopShort(let loopShortIntent):
                        return .loopShort(
                            LoopShortIntent(
                                exposureAssetSymbol: loopShortIntent.exposureAssetSymbol,
                                backingAssetSymbol: loopShortIntent.backingAssetSymbol,
                                marketId: loopShortIntent.marketId,
                                isIncrease: loopShortIntent.isIncrease,
                                exposureAmount: loopShortIntent.exposureAmount,
                                minSwapBackingAmount: loopShortIntent.minSwapBackingAmount,
                                providedBackingAmount: Number.MAX_UINT_256,
                                poolFee: loopShortIntent.poolFee,
                                sender: loopShortIntent.sender,
                                chainId: loopShortIntent.chainId
                            )
                        )
                    case .migrateSupplies(let migrateSuppliesIntent):
                        let maxSupplyIntent: SupplyIntent
                        switch migrateSuppliesIntent.supplyIntent {
                            case .aave(let aaveIntent):
                                maxSupplyIntent = .aave(
                                    AaveSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: aaveIntent.assetSymbol,
                                        chainId: aaveIntent.chainId,
                                        aavePool: aaveIntent.aavePool,
                                        sender: aaveIntent.sender
                                    )
                                )
                            case .comet(let cometIntent):
                                maxSupplyIntent = .comet(
                                    CometSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: cometIntent.assetSymbol,
                                        chainId: cometIntent.chainId,
                                        comet: cometIntent.comet,
                                        sender: cometIntent.sender
                                    )
                                )
                            case .morpho(let morphoIntent):
                                maxSupplyIntent = .morpho(
                                    MorphoVaultSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: morphoIntent.assetSymbol,
                                        morphoVault: morphoIntent.morphoVault,
                                        sender: morphoIntent.sender,
                                        chainId: morphoIntent.chainId
                                    )
                                )
                        }
                        return .migrateSupplies(
                            MigrateSuppliesIntent(
                                withdrawIntents: migrateSuppliesIntent.withdrawIntents,
                                supplyIntent: maxSupplyIntent,
                                migrateOnlySupplyBalances: migrateSuppliesIntent.migrateOnlySupplyBalances
                            )
                        )
                    case .morphoBorrow(let morphoBorrowIntent):
                        return .morphoBorrow(
                            MorphoBorrowIntent(
                                amount: morphoBorrowIntent.amount,
                                assetSymbol: morphoBorrowIntent.assetSymbol,
                                marketId: morphoBorrowIntent.marketId,
                                borrower: morphoBorrowIntent.borrower,
                                chainId: morphoBorrowIntent.chainId,
                                collateralAmount: Number.MAX_UINT_256,
                                collateralAssetSymbol: morphoBorrowIntent.collateralAssetSymbol
                            )
                        )
                    case .morphoRepay(let morphoRepayIntent):
                        return .morphoRepay(
                            MorphoRepayIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: morphoRepayIntent.assetSymbol,
                                marketId: morphoRepayIntent.marketId,
                                repayer: morphoRepayIntent.repayer,
                                chainId: morphoRepayIntent.chainId,
                                collateralAmount: morphoRepayIntent.collateralAmount,
                                collateralAssetSymbol: morphoRepayIntent.collateralAssetSymbol
                            )
                        )
                    case .morphoVaultSupply(let morphoVaultSupplyIntent):
                        return .morphoVaultSupply(
                            MorphoVaultSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: morphoVaultSupplyIntent.assetSymbol,
                                morphoVault: morphoVaultSupplyIntent.morphoVault,
                                sender: morphoVaultSupplyIntent.sender,
                                chainId: morphoVaultSupplyIntent.chainId
                            )
                        )
                    case .morphoVaultWithdraw(let morphoVaultWithdrawIntent):
                        return .morphoVaultWithdraw(
                            MorphoVaultWithdrawIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: morphoVaultWithdrawIntent.assetSymbol,
                                morphoVault: morphoVaultWithdrawIntent.morphoVault,
                                chainId: morphoVaultWithdrawIntent.chainId,
                                withdrawer: morphoVaultWithdrawIntent.withdrawer
                            )
                        )
                    case .recurringSwap:
                        return self
                    case .supply(let supplyIntent):
                        let maxSupplyIntent: SupplyIntent
                        switch supplyIntent {
                            case .aave(let aaveIntent):
                                maxSupplyIntent = .aave(
                                    AaveSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: aaveIntent.assetSymbol,
                                        chainId: aaveIntent.chainId,
                                        aavePool: aaveIntent.aavePool,
                                        sender: aaveIntent.sender
                                    )
                                )
                            case .comet(let cometIntent):
                                maxSupplyIntent = .comet(
                                    CometSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: cometIntent.assetSymbol,
                                        chainId: cometIntent.chainId,
                                        comet: cometIntent.comet,
                                        sender: cometIntent.sender
                                    )
                                )
                            case .morpho(let morphoIntent):
                                maxSupplyIntent = .morpho(
                                    MorphoVaultSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: morphoIntent.assetSymbol,
                                        morphoVault: morphoIntent.morphoVault,
                                        sender: morphoIntent.sender,
                                        chainId: morphoIntent.chainId
                                    )
                                )
                        }
                        return .supply(maxSupplyIntent)
                    case .swapAndSupply(let swapAndSupplyIntent):
                        let maxSupplyIntent: SupplyIntent
                        switch swapAndSupplyIntent.supplyIntent {
                            case .aave(let aaveIntent):
                                maxSupplyIntent = .aave(
                                    AaveSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: aaveIntent.assetSymbol,
                                        chainId: aaveIntent.chainId,
                                        aavePool: aaveIntent.aavePool,
                                        sender: aaveIntent.sender
                                    )
                                )
                            case .comet(let cometIntent):
                                maxSupplyIntent = .comet(
                                    CometSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: cometIntent.assetSymbol,
                                        chainId: cometIntent.chainId,
                                        comet: cometIntent.comet,
                                        sender: cometIntent.sender
                                    )
                                )
                            case .morpho(let morphoIntent):
                                maxSupplyIntent = .morpho(
                                    MorphoVaultSupplyIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: morphoIntent.assetSymbol,
                                        morphoVault: morphoIntent.morphoVault,
                                        sender: morphoIntent.sender,
                                        chainId: morphoIntent.chainId
                                    )
                                )
                        }
                        return .swapAndSupply(
                            SwapAndSupplyIntent(
                                swapIntent: swapAndSupplyIntent.swapIntent,
                                supplyIntent: maxSupplyIntent
                            )
                        )
                    case .swap(let swapIntent):
                        return .swap(
                            SwapIntent(
                                chainId: swapIntent.chainId,
                                sellToken: swapIntent.sellToken,
                                sellAmount: Number.MAX_UINT_256,
                                buyToken: swapIntent.buyToken,
                                buyAmount: swapIntent.buyAmount,
                                swapQuoteSellAmount: swapIntent.swapQuoteSellAmount,
                                swapQuoteBuyAmount: swapIntent.swapQuoteBuyAmount,
                                feeToken: swapIntent.feeToken,
                                feeAmount: swapIntent.feeAmount,
                                sender: swapIntent.sender,
                                isExactOut: swapIntent.isExactOut,
                                isBuy: swapIntent.isBuy
                            )
                        )
                    case .unloopLong(let unloopLongIntent):
                        return .unloopLong(
                            UnloopLongIntent(
                                exposureAssetSymbol: unloopLongIntent.exposureAssetSymbol,
                                backingAssetSymbol: unloopLongIntent.backingAssetSymbol,
                                marketId: unloopLongIntent.marketId,
                                exposureAmount: Number.MAX_UINT_256,
                                backingAmountToExit: unloopLongIntent.backingAmountToExit,
                                minSwapBackingAmount: unloopLongIntent.minSwapBackingAmount,
                                poolFee: unloopLongIntent.poolFee,
                                sender: unloopLongIntent.sender,
                                chainId: unloopLongIntent.chainId
                            )
                        )
                    case .unloopShort(let unloopShortIntent):
                        return .unloopShort(
                            UnloopShortIntent(
                                exposureAssetSymbol: unloopShortIntent.exposureAssetSymbol,
                                backingAssetSymbol: unloopShortIntent.backingAssetSymbol,
                                marketId: unloopShortIntent.marketId,
                                exposureAmount: Number.MAX_UINT_256,
                                backingAmountToExit: unloopShortIntent.backingAmountToExit,
                                maxSwapBackingAmount: unloopShortIntent.maxSwapBackingAmount,
                                poolFee: unloopShortIntent.poolFee,
                                sender: unloopShortIntent.sender,
                                chainId: unloopShortIntent.chainId
                            )
                        )
                    case .withdraw(let withdrawIntent):
                        let maxWithdrawIntent: WithdrawIntent
                        switch withdrawIntent {
                            case .aave(let aaveIntent):
                                maxWithdrawIntent = .aave(
                                    AaveWithdrawIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: aaveIntent.assetSymbol,
                                        chainId: aaveIntent.chainId,
                                        aavePool: aaveIntent.aavePool,
                                        withdrawer: aaveIntent.withdrawer
                                    )
                                )
                            case .comet(let cometIntent):
                                maxWithdrawIntent = .comet(
                                    CometWithdrawIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: cometIntent.assetSymbol,
                                        chainId: cometIntent.chainId,
                                        comet: cometIntent.comet,
                                        withdrawer: cometIntent.withdrawer
                                    )
                                )
                            case .morpho(let morphoIntent):
                                maxWithdrawIntent = .morpho(
                                    MorphoVaultWithdrawIntent(
                                        amount: Number.MAX_UINT_256,
                                        assetSymbol: morphoIntent.assetSymbol,
                                        morphoVault: morphoIntent.morphoVault,
                                        chainId: morphoIntent.chainId,
                                        withdrawer: morphoIntent.withdrawer
                                    )
                                )
                        }
                        return .withdraw(maxWithdrawIntent)
                    case .withdrawBackingToken(let withdrawBackingTokenIntent):
                        return .withdrawBackingToken(
                            WithdrawBackingTokenIntent(
                                exposureAssetSymbol: withdrawBackingTokenIntent.exposureAssetSymbol,
                                backingAssetSymbol: withdrawBackingTokenIntent.backingAssetSymbol,
                                marketId: withdrawBackingTokenIntent.marketId,
                                amount: Number.MAX_UINT_256,
                                isShort: withdrawBackingTokenIntent.isShort,
                                sender: withdrawBackingTokenIntent.sender,
                                chainId: withdrawBackingTokenIntent.chainId
                            )
                        )
                }
            }
        }

        enum CodingKeys: String, CodingKey {
            case intentType = "intent_type"
            case blockTimestamp = "block_timestamp"
        }

        public init(type: Type_, blockTimestamp: Number) {
            self.type = type
            self.blockTimestamp = blockTimestamp
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(blockTimestamp, forKey: .blockTimestamp)
            try container.encode(self.type.intentType, forKey: .intentType)

            switch self.type {
                case .aaveSupply(let aaveSupplyIntent):
                    try aaveSupplyIntent.encode(to: encoder)
                case .aaveWithdraw(let aaveWithdrawIntent):
                    try aaveWithdrawIntent.encode(to: encoder)
                case .addBackingToken(let addBackingTokenIntent):
                    try addBackingTokenIntent.encode(to: encoder)
                case .claimRewards(let claimRewardsIntent):
                    try claimRewardsIntent.encode(to: encoder)
                case .cometBorrow(let cometBorrowIntent):
                    try cometBorrowIntent.encode(to: encoder)
                case .cometRepay(let cometRepayIntent):
                    try cometRepayIntent.encode(to: encoder)
                case .cometSupply(let cometSupplyIntent):
                    try cometSupplyIntent.encode(to: encoder)
                case .cometWithdraw(let cometWithdrawIntent):
                    try cometWithdrawIntent.encode(to: encoder)
                case .compounder(let compounderIntent):
                    try compounderIntent.encode(to: encoder)
                case .loopLong(let loopLongIntent):
                    try loopLongIntent.encode(to: encoder)
                case .loopShort(let loopShortIntent):
                    try loopShortIntent.encode(to: encoder)
                case .migrateSupplies(let migrateSuppliesIntent):
                    try migrateSuppliesIntent.encode(to: encoder)
                case .morphoBorrow(let morphoBorrowIntent):
                    try morphoBorrowIntent.encode(to: encoder)
                case .morphoRepay(let morphoRepayIntent):
                    try morphoRepayIntent.encode(to: encoder)
                case .morphoVaultSupply(let morphoVaultSupplyIntent):
                    try morphoVaultSupplyIntent.encode(to: encoder)
                case .morphoVaultWithdraw(let morphoVaultWithdrawIntent):
                    try morphoVaultWithdrawIntent.encode(to: encoder)
                case .recurringSwap(let recurringSwapIntent):
                    try recurringSwapIntent.encode(to: encoder)
                case .swap(let swapIntent):
                    try swapIntent.encode(to: encoder)
                case .swapAndSupply(let swapAndSupplyIntent):
                    try swapAndSupplyIntent.encode(to: encoder)
                case .supply(let supplyIntent):
                    try supplyIntent.encode(to: encoder)
                case .transfer(let transferIntent):
                    try transferIntent.encode(to: encoder)
                case .unloopLong(let unloopLongIntent):
                    try unloopLongIntent.encode(to: encoder)
                case .unloopShort(let unloopShortIntent):
                    try unloopShortIntent.encode(to: encoder)
                case .withdraw(let withdrawIntent):
                    try withdrawIntent.encode(to: encoder)
                case .withdrawBackingToken(let withdrawBackingTokenIntent):
                    try withdrawBackingTokenIntent.encode(to: encoder)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.blockTimestamp = try container.decode(Number.self, forKey: .blockTimestamp)

            let intentType = try container.decode(String.self, forKey: .intentType)
            switch intentType {
                case "aave_supply":
                    self.type = try .aaveSupply(AaveSupplyIntent(from: decoder))
                case "aave_withdraw":
                    self.type = try .aaveWithdraw(AaveWithdrawIntent(from: decoder))
                case "add_backing_token":
                    self.type = try .addBackingToken(AddBackingTokenIntent(from: decoder))
                case "claim_rewards":
                    self.type = try .claimRewards(ClaimRewardsIntent(from: decoder))
                case "comet_borrow":
                    self.type = try .cometBorrow(CometBorrowIntent(from: decoder))
                case "comet_repay":
                    self.type = try .cometRepay(CometRepayIntent(from: decoder))
                case "comet_supply":
                    self.type = try .cometSupply(CometSupplyIntent(from: decoder))
                case "comet_withdraw":
                    self.type = try .cometWithdraw(CometWithdrawIntent(from: decoder))
                case "compounder":
                    self.type = try .compounder(CompounderIntent(from: decoder))
                case "loop_long":
                    self.type = try .loopLong(LoopLongIntent(from: decoder))
                case "loop_short":
                    self.type = try .loopShort(LoopShortIntent(from: decoder))
                case "migrate_supplies":
                    self.type = try .migrateSupplies(MigrateSuppliesIntent(from: decoder))
                case "morpho_borrow":
                    self.type = try .morphoBorrow(MorphoBorrowIntent(from: decoder))
                case "morpho_repay":
                    self.type = try .morphoRepay(MorphoRepayIntent(from: decoder))
                case "morpho_vault_supply":
                    self.type = try .morphoVaultSupply(MorphoVaultSupplyIntent(from: decoder))
                case "morpho_vault_withdraw":
                    self.type = try .morphoVaultWithdraw(MorphoVaultWithdrawIntent(from: decoder))
                case "recurring_swap":
                    self.type = try .recurringSwap(RecurringSwapIntent(from: decoder))
                case "supply":
                    self.type = try .supply(SupplyIntent(from: decoder))
                case "swap_and_supply":
                    self.type = try .swapAndSupply(SwapAndSupplyIntent(from: decoder))
                case "swap":
                    self.type = try .swap(SwapIntent(from: decoder))
                case "transfer":
                    self.type = try .transfer(TransferIntent(from: decoder))
                case "unloop_long":
                    self.type = try .unloopLong(UnloopLongIntent(from: decoder))
                case "unloop_short":
                    self.type = try .unloopShort(UnloopShortIntent(from: decoder))
                case "withdraw":
                    self.type = try .withdraw(WithdrawIntent(from: decoder))
                case "withdraw_backing_token":
                    self.type = try .withdrawBackingToken(WithdrawBackingTokenIntent(from: decoder))
                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .intentType,
                        in: container,
                        debugDescription: "Unknown intent type: \(intentType)"
                    )
            }
        }

        public var description: String {
            switch self.type {
                case .aaveSupply(let intent):
                    return "Aave Supply Intent: \(intent)"
                case .aaveWithdraw(let intent):
                    return "Aave Withdraw Intent: \(intent)"
                case .addBackingToken(let intent):
                    return "Add Backing Token Intent: \(intent)"
                case .claimRewards(let intent):
                    return "Claim Rewards Intent: \(intent)"
                case .cometBorrow(let intent):
                    return "Comet Borrow Intent: \(intent)"
                case .cometRepay(let intent):
                    return "Comet Repay Intent: \(intent)"
                case .cometSupply(let intent):
                    return "Comet Supply Intent: \(intent)"
                case .cometWithdraw(let intent):
                    return "Comet Withdraw Intent: \(intent)"
                case .compounder(let intent):
                    return "Compounder Intent: \(intent)"
                case .loopLong(let intent):
                    return "Loop Long Intent: \(intent)"
                case .loopShort(let intent):
                    return "Loop Short Intent: \(intent)"
                case .migrateSupplies(let intent):
                    return "Migrate Supplies Intent: \(intent)"
                case .morphoBorrow(let intent):
                    return "Morpho Borrow Intent: \(intent)"
                case .morphoRepay(let intent):
                    return "Morpho Repay Intent: \(intent)"
                case .morphoVaultSupply(let intent):
                    return "Morpho Vault Supply Intent: \(intent)"
                case .morphoVaultWithdraw(let intent):
                    return "Morpho Vault Withdraw Intent: \(intent)"
                case .recurringSwap(let intent):
                    return "Recurring Swap Intent: \(intent)"
                case .supply(let intent):
                    return "Supply Intent: \(intent)"
                case .swapAndSupply(let intent):
                    return "Swap and Supply Intent: \(intent)"
                case .swap(let intent):
                    return "Swap Intent: \(intent)"
                case .transfer(let intent):
                    return "Transfer Intent: \(intent)"
                case .unloopLong(let intent):
                    return "Unloop Long Intent: \(intent)"
                case .unloopShort(let intent):
                    return "Unloop Short Intent: \(intent)"
                case .withdraw(let intent):
                    return "Withdraw Intent: \(intent)"
                case .withdrawBackingToken(let intent):
                    return "Withdraw Backing Token Intent: \(intent)"
            }
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }

    public struct TransferIntent: Equatable, Codable, Hashable, Sendable {
        public let chainId: Number
        public let assetSymbol: String
        public let amount: Number
        public let sender: EthAddress
        public let recipient: EthAddress

        public enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case assetSymbol = "asset_symbol"
            case amount
            case sender
            case recipient
        }

        public init(
            chainId: Number,
            assetSymbol: String,
            amount: Number,
            sender: EthAddress,
            recipient: EthAddress
        ) {
            self.chainId = chainId
            self.assetSymbol = assetSymbol
            self.amount = amount
            self.sender = sender
            self.recipient = recipient
        }
    }

    public struct CometSupplyIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let comet: EthAddress
        public let sender: EthAddress

        enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case chainId = "chain_id"
            case comet
            case sender
        }

        public init(
            amount: Number,
            assetSymbol: String,
            chainId: Number,
            comet: EthAddress,
            sender: EthAddress
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.chainId = chainId
            self.comet = comet
            self.sender = sender
        }
    }

    public struct AaveSupplyIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let aavePool: EthAddress
        public let sender: EthAddress

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case chainId = "chain_id"
            case aavePool = "aave_pool"
            case sender
        }

        public init(
            amount: Number,
            assetSymbol: String,
            chainId: Number,
            aavePool: EthAddress,
            sender: EthAddress
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.chainId = chainId
            self.aavePool = aavePool
            self.sender = sender
        }
    }

    public struct AaveWithdrawIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let aavePool: EthAddress
        public let withdrawer: EthAddress

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case chainId = "chain_id"
            case aavePool = "aave_pool"
            case withdrawer
        }

        public init(
            amount: Number,
            assetSymbol: String,
            chainId: Number,
            aavePool: EthAddress,
            withdrawer: EthAddress
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.chainId = chainId
            self.aavePool = aavePool
            self.withdrawer = withdrawer
        }
    }

    public struct AddBackingTokenIntent: Equatable, Codable, Hashable, Sendable {
        public let exposureAssetSymbol: String
        public let backingAssetSymbol: String
        public let marketId: Hex
        public let amount: Number
        public let isShort: Bool
        public let sender: EthAddress
        public let chainId: Number

        public enum CodingKeys: String, CodingKey {
            case exposureAssetSymbol = "exposure_asset_symbol"
            case backingAssetSymbol = "backing_asset_symbol"
            case marketId = "market_id"
            case amount
            case isShort = "is_short"
            case sender
            case chainId = "chain_id"
        }

        public init(
            exposureAssetSymbol: String,
            backingAssetSymbol: String,
            marketId: Hex,
            amount: Number,
            isShort: Bool,
            sender: EthAddress,
            chainId: Number
        ) {
            self.exposureAssetSymbol = exposureAssetSymbol
            self.backingAssetSymbol = backingAssetSymbol
            self.marketId = marketId
            self.amount = amount
            self.isShort = isShort
            self.sender = sender
            self.chainId = chainId
        }
    }

    public struct CometBorrowIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let borrower: EthAddress
        public let chainId: Number
        public let collateralAmount: Number
        public let collateralAssetSymbol: String
        public let comet: EthAddress

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case borrower
            case chainId = "chain_id"
            case collateralAmount = "collateral_amount"
            case collateralAssetSymbol = "collateral_asset_symbol"
            case comet
        }

        public init(
            amount: Number,
            assetSymbol: String,
            borrower: EthAddress,
            chainId: Number,
            collateralAmount: Number,
            collateralAssetSymbol: String,
            comet: EthAddress
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.borrower = borrower
            self.chainId = chainId
            self.collateralAmount = collateralAmount
            self.collateralAssetSymbol = collateralAssetSymbol
            self.comet = comet
        }

        var isMaxIntent: Bool {
            collateralAmount.isMaxUint256
        }
    }

    public struct CometRepayIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let collateralAmount: Number
        public let collateralAssetSymbol: String
        public let comet: EthAddress
        public let repayer: EthAddress

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case chainId = "chain_id"
            case collateralAmount = "collateral_amount"
            case collateralAssetSymbol = "collateral_asset_symbol"
            case comet
            case repayer
        }

        public init(
            amount: Number,
            assetSymbol: String,
            chainId: Number,
            collateralAmount: Number,
            collateralAssetSymbol: String,
            comet: EthAddress,
            repayer: EthAddress
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.chainId = chainId
            self.collateralAmount = collateralAmount
            self.collateralAssetSymbol = collateralAssetSymbol
            self.comet = comet
            self.repayer = repayer
        }

        var isMaxIntent: Bool {
            amount == Number.MAX_UINT_256
        }
    }

    public struct CometWithdrawIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let comet: EthAddress
        public let withdrawer: EthAddress

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case chainId = "chain_id"
            case comet
            case withdrawer
        }

        public init(
            amount: Number,
            assetSymbol: String,
            chainId: Number,
            comet: EthAddress,
            withdrawer: EthAddress
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.chainId = chainId
            self.comet = comet
            self.withdrawer = withdrawer
        }
    }

    public struct LoopLongIntent: Equatable, Codable, Hashable, Sendable {
        public let exposureAssetSymbol: String
        public let backingAssetSymbol: String
        public let marketId: Hex
        public let isIncrease: Bool
        public let exposureAmount: Number
        public let maxSwapBackingAmount: Number
        public let maxProvidedBackingAmount: Number
        public let poolFee: UInt
        public let sender: EthAddress
        public let chainId: Number

        public enum CodingKeys: String, CodingKey {
            case exposureAssetSymbol = "exposure_asset_symbol"
            case backingAssetSymbol = "backing_asset_symbol"
            case marketId = "market_id"
            case isIncrease = "is_increase"
            case exposureAmount = "exposure_amount"
            case maxSwapBackingAmount = "max_swap_backing_amount"
            case maxProvidedBackingAmount = "max_provided_backing_amount"
            case poolFee = "pool_fee"
            case sender
            case chainId = "chain_id"
        }

        public init(
            exposureAssetSymbol: String,
            backingAssetSymbol: String,
            marketId: Hex,
            isIncrease: Bool,
            exposureAmount: Number,
            maxSwapBackingAmount: Number,
            maxProvidedBackingAmount: Number,
            poolFee: UInt,
            sender: EthAddress,
            chainId: Number
        ) {
            self.exposureAssetSymbol = exposureAssetSymbol
            self.backingAssetSymbol = backingAssetSymbol
            self.marketId = marketId
            self.isIncrease = isIncrease
            self.exposureAmount = exposureAmount
            self.maxSwapBackingAmount = maxSwapBackingAmount
            self.maxProvidedBackingAmount = maxProvidedBackingAmount
            self.poolFee = poolFee
            self.sender = sender
            self.chainId = chainId
        }
    }

    public struct LoopShortIntent: Equatable, Codable, Hashable, Sendable {
        public let exposureAssetSymbol: String
        public let backingAssetSymbol: String
        public let marketId: Hex
        public let isIncrease: Bool
        public let exposureAmount: Number
        public let minSwapBackingAmount: Number
        public let providedBackingAmount: Number
        public let poolFee: UInt
        public let sender: EthAddress
        public let chainId: Number

        public enum CodingKeys: String, CodingKey {
            case exposureAssetSymbol = "exposure_asset_symbol"
            case backingAssetSymbol = "backing_asset_symbol"
            case marketId = "market_id"
            case isIncrease = "is_increase"
            case exposureAmount = "exposure_amount"
            case minSwapBackingAmount = "min_swap_backing_amount"
            case providedBackingAmount = "provided_backing_amount"
            case poolFee = "pool_fee"
            case sender
            case chainId = "chain_id"
        }

        public init(
            exposureAssetSymbol: String,
            backingAssetSymbol: String,
            marketId: Hex,
            isIncrease: Bool,
            exposureAmount: Number,
            minSwapBackingAmount: Number,
            providedBackingAmount: Number,
            poolFee: UInt,
            sender: EthAddress,
            chainId: Number
        ) {
            self.exposureAssetSymbol = exposureAssetSymbol
            self.backingAssetSymbol = backingAssetSymbol
            self.marketId = marketId
            self.isIncrease = isIncrease
            self.exposureAmount = exposureAmount
            self.minSwapBackingAmount = minSwapBackingAmount
            self.providedBackingAmount = providedBackingAmount
            self.poolFee = poolFee
            self.sender = sender
            self.chainId = chainId
        }
    }

    public struct MigrateSuppliesIntent: Equatable, Codable, Hashable, Sendable {
        public let withdrawIntents: [WithdrawIntent]
        public let supplyIntent: SupplyIntent
        public let migrateOnlySupplyBalances: Bool

        public enum CodingKeys: String, CodingKey {
            case withdrawIntents = "withdraw_intents"
            case supplyIntent = "supply_intent"
            case migrateOnlySupplyBalances = "migrate_only_supply_balances"
        }

        public init(
            withdrawIntents: [WithdrawIntent],
            supplyIntent: SupplyIntent,
            migrateOnlySupplyBalances: Bool
        ) {
            self.withdrawIntents = withdrawIntents
            self.supplyIntent = supplyIntent
            self.migrateOnlySupplyBalances = migrateOnlySupplyBalances
        }
    }

    public struct MorphoBorrowIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let marketId: Hex
        public let borrower: EthAddress
        public let chainId: Number
        public let collateralAmount: Number
        public let collateralAssetSymbol: String

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case marketId = "market_id"
            case borrower
            case chainId = "chain_id"
            case collateralAmount = "collateral_amount"
            case collateralAssetSymbol = "collateral_asset_symbol"
        }

        public init(
            amount: Number,
            assetSymbol: String,
            marketId: Hex,
            borrower: EthAddress,
            chainId: Number,
            collateralAmount: Number,
            collateralAssetSymbol: String
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.marketId = marketId
            self.borrower = borrower
            self.chainId = chainId
            self.collateralAmount = collateralAmount
            self.collateralAssetSymbol = collateralAssetSymbol
        }

        var isMaxIntent: Bool {
            collateralAmount.isMaxUint256
        }
    }

    public struct MorphoRepayIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let marketId: Hex
        public let repayer: EthAddress
        public let chainId: Number
        public let collateralAmount: Number
        public let collateralAssetSymbol: String

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case marketId = "market_id"
            case repayer
            case chainId = "chain_id"
            case collateralAmount = "collateral_amount"
            case collateralAssetSymbol = "collateral_asset_symbol"
        }

        public init(
            amount: Number,
            assetSymbol: String,
            marketId: Hex,
            repayer: EthAddress,
            chainId: Number,
            collateralAmount: Number,
            collateralAssetSymbol: String
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.marketId = marketId
            self.repayer = repayer
            self.chainId = chainId
            self.collateralAmount = collateralAmount
            self.collateralAssetSymbol = collateralAssetSymbol
        }

        var isMaxIntent: Bool {
            amount == Number.MAX_UINT_256
        }
    }

    public struct ClaimRewardsIntent: Equatable, Codable, Hashable, Sendable {
        public let claimer: EthAddress
        public let assetSymbol: String

        public enum CodingKeys: String, CodingKey {
            case claimer
            case assetSymbol = "asset_symbol"
        }

        public init(claimer: EthAddress, assetSymbol: String) {
            self.claimer = claimer
            self.assetSymbol = assetSymbol
        }
    }

    public struct MorphoVaultSupplyIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let morphoVault: EthAddress
        public let sender: EthAddress
        public let chainId: Number

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case morphoVault = "morpho_vault"
            case sender
            case chainId = "chain_id"
        }

        public init(
            amount: Number,
            assetSymbol: String,
            morphoVault: EthAddress,
            sender: EthAddress,
            chainId: Number
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.morphoVault = morphoVault
            self.sender = sender
            self.chainId = chainId
        }
    }

    public struct MorphoVaultWithdrawIntent: Equatable, Codable, Hashable, Sendable {
        public let amount: Number
        public let assetSymbol: String
        public let morphoVault: EthAddress
        public let chainId: Number
        public let withdrawer: EthAddress

        public enum CodingKeys: String, CodingKey {
            case amount
            case assetSymbol = "asset_symbol"
            case morphoVault = "morpho_vault"
            case chainId = "chain_id"
            case withdrawer
        }

        public init(
            amount: Number,
            assetSymbol: String,
            morphoVault: EthAddress,
            chainId: Number,
            withdrawer: EthAddress
        ) {
            self.amount = amount
            self.assetSymbol = assetSymbol
            self.morphoVault = morphoVault
            self.chainId = chainId
            self.withdrawer = withdrawer
        }
    }

    public struct RecurringSwapIntent: Equatable, Codable, Hashable, Sendable {
        public let chainId: Number
        public let sellToken: EthAddress
        public let sellAmount: Number
        public let buyToken: EthAddress
        public let buyAmount: Number
        public let interval: Number
        public let sender: EthAddress

        public enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case sellToken = "sell_token"
            case sellAmount = "sell_amount"
            case buyToken = "buy_token"
            case buyAmount = "buy_amount"
            case interval
            case sender
        }

        public init(
            chainId: Number,
            sellToken: EthAddress,
            sellAmount: Number,
            buyToken: EthAddress,
            buyAmount: Number,
            interval: Number,
            sender: EthAddress
        ) {
            self.chainId = chainId
            self.sellToken = sellToken
            self.sellAmount = sellAmount
            self.buyToken = buyToken
            self.buyAmount = buyAmount
            self.interval = interval
            self.sender = sender
        }
    }

    public enum SupplyIntent: Equatable, Codable, Hashable, Sendable {
        case aave(AaveSupplyIntent)
        case comet(CometSupplyIntent)
        case morpho(MorphoVaultSupplyIntent)

        enum CodingKeys: String, CodingKey {
            case intentType = "intent_type"
            case marketType = "market_type"
            case market
            case amount
            case assetSymbol = "asset_symbol"
            case chainId = "chain_id"
            case sender
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("supply", forKey: .intentType)

            switch self {
                case .comet(let intent):
                    try container.encode("COMET", forKey: .marketType)
                    try container.encode(intent.comet, forKey: .market)
                    try container.encode(intent.amount, forKey: .amount)
                    try container.encode(intent.assetSymbol, forKey: .assetSymbol)
                    try container.encode(intent.chainId, forKey: .chainId)
                    try container.encode(intent.sender, forKey: .sender)

                case .aave(let intent):
                    try container.encode("AAVE", forKey: .marketType)
                    try container.encode(intent.aavePool, forKey: .market)
                    try container.encode(intent.amount, forKey: .amount)
                    try container.encode(intent.assetSymbol, forKey: .assetSymbol)
                    try container.encode(intent.chainId, forKey: .chainId)
                    try container.encode(intent.sender, forKey: .sender)

                case .morpho(let intent):
                    try container.encode("MORPHO", forKey: .marketType)
                    try container.encode(intent.morphoVault, forKey: .market)
                    try container.encode(intent.amount, forKey: .amount)
                    try container.encode(intent.assetSymbol, forKey: .assetSymbol)
                    try container.encode(intent.chainId, forKey: .chainId)
                    try container.encode(intent.sender, forKey: .sender)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let marketType = try container.decode(String.self, forKey: .marketType)

            switch marketType {
                case "COMET":
                    let amount = try container.decode(Number.self, forKey: .amount)
                    let assetSymbol = try container.decode(String.self, forKey: .assetSymbol)
                    let chainId = try container.decode(Number.self, forKey: .chainId)
                    let comet = try container.decode(EthAddress.self, forKey: .market)
                    let sender = try container.decode(EthAddress.self, forKey: .sender)

                    self = .comet(
                        CometSupplyIntent(
                            amount: amount,
                            assetSymbol: assetSymbol,
                            chainId: chainId,
                            comet: comet,
                            sender: sender
                        )
                    )

                case "AAVE":
                    let amount = try container.decode(Number.self, forKey: .amount)
                    let assetSymbol = try container.decode(String.self, forKey: .assetSymbol)
                    let chainId = try container.decode(Number.self, forKey: .chainId)
                    let aavePool = try container.decode(EthAddress.self, forKey: .market)
                    let sender = try container.decode(EthAddress.self, forKey: .sender)

                    self = .aave(
                        AaveSupplyIntent(
                            amount: amount,
                            assetSymbol: assetSymbol,
                            chainId: chainId,
                            aavePool: aavePool,
                            sender: sender
                        )
                    )

                case "MORPHO":
                    let amount = try container.decode(Number.self, forKey: .amount)
                    let assetSymbol = try container.decode(String.self, forKey: .assetSymbol)
                    let chainId = try container.decode(Number.self, forKey: .chainId)
                    let morphoVault = try container.decode(EthAddress.self, forKey: .market)
                    let sender = try container.decode(EthAddress.self, forKey: .sender)

                    self = .morpho(
                        MorphoVaultSupplyIntent(
                            amount: amount,
                            assetSymbol: assetSymbol,
                            morphoVault: morphoVault,
                            sender: sender,
                            chainId: chainId
                        )
                    )

                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .marketType,
                        in: container,
                        debugDescription: "Unknown market type: \(marketType)"
                    )
            }
        }

        // Helper computed properties for common fields
        public var amount: Number {
            switch self {
                case .aave(let intent):
                    return intent.amount
                case .comet(let intent):
                    return intent.amount
                case .morpho(let intent):
                    return intent.amount
            }
        }

        public var assetSymbol: String {
            switch self {
                case .aave(let intent):
                    return intent.assetSymbol
                case .comet(let intent):
                    return intent.assetSymbol
                case .morpho(let intent):
                    return intent.assetSymbol
            }
        }

        public var chainId: Number {
            switch self {
                case .aave(let intent):
                    return intent.chainId
                case .comet(let intent):
                    return intent.chainId
                case .morpho(let intent):
                    return intent.chainId
            }
        }

        public var sender: EthAddress {
            switch self {
                case .aave(let intent):
                    return intent.sender
                case .comet(let intent):
                    return intent.sender
                case .morpho(let intent):
                    return intent.sender
            }
        }

        public var market: EthAddress {
            switch self {
                case .aave(let intent):
                    return intent.aavePool
                case .comet(let intent):
                    return intent.comet
                case .morpho(let intent):
                    return intent.morphoVault
            }
        }
    }

    public struct SwapAndSupplyIntent: Equatable, Codable, Hashable, Sendable {
        public let swapIntent: SwapIntent
        public let supplyIntent: SupplyIntent

        public enum CodingKeys: String, CodingKey {
            case swapIntent = "swap_intent"
            case supplyIntent = "supply_intent"
        }

        public init(
            swapIntent: SwapIntent,
            supplyIntent: SupplyIntent
        ) {
            self.swapIntent = swapIntent
            self.supplyIntent = supplyIntent
        }
    }

    public struct CompounderIntent: Equatable, Codable, Hashable, Sendable {
        public let claimRewardsIntent: ClaimRewardsIntent
        public let swapIntent: SwapIntent
        public let supplyIntent: SupplyIntent

        public enum CodingKeys: String, CodingKey {
            case claimRewardsIntent = "claim_rewards_intent"
            case swapIntent = "swap_intent"
            case supplyIntent = "supply_intent"
        }

        public init(
            claimRewardsIntent: ClaimRewardsIntent,
            swapIntent: SwapIntent,
            supplyIntent: SupplyIntent
        ) {
            self.claimRewardsIntent = claimRewardsIntent
            self.swapIntent = swapIntent
            self.supplyIntent = supplyIntent
        }
    }

    public struct SwapIntent: Equatable, Codable, Hashable, Sendable {
        public let chainId: Number
        public let sellToken: EthAddress
        public let sellAmount: Number
        public let buyToken: EthAddress
        public let buyAmount: Number
        public let swapQuoteSellAmount: Number
        public let swapQuoteBuyAmount: Number
        public let feeToken: EthAddress
        public let feeAmount: Number
        public let sender: EthAddress
        public let isExactOut: Bool
        public let isBuy: Bool

        public enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case sellToken = "sell_token"
            case sellAmount = "sell_amount"
            case buyToken = "buy_token"
            case buyAmount = "buy_amount"
            case swapQuoteSellAmount = "swap_quote_sell_amount"
            case swapQuoteBuyAmount = "swap_quote_buy_amount"
            case feeToken = "fee_token"
            case feeAmount = "fee_amount"
            case sender
            case isExactOut = "is_exact_out"
            case isBuy = "is_buy"
        }

        public init(
            chainId: Number,
            sellToken: EthAddress,
            sellAmount: Number,
            buyToken: EthAddress,
            buyAmount: Number,
            swapQuoteSellAmount: Number,
            swapQuoteBuyAmount: Number,
            feeToken: EthAddress,
            feeAmount: Number,
            sender: EthAddress,
            isExactOut: Bool,
            isBuy: Bool
        ) {
            self.chainId = chainId
            self.sellToken = sellToken
            self.sellAmount = sellAmount
            self.buyToken = buyToken
            self.buyAmount = buyAmount
            self.swapQuoteSellAmount = swapQuoteSellAmount
            self.swapQuoteBuyAmount = swapQuoteBuyAmount
            self.feeToken = feeToken
            self.feeAmount = feeAmount
            self.sender = sender
            self.isExactOut = isExactOut
            self.isBuy = isBuy
        }
    }

    public struct UnloopLongIntent: Equatable, Codable, Hashable, Sendable {
        public let exposureAssetSymbol: String
        public let backingAssetSymbol: String
        public let marketId: Hex
        public let exposureAmount: Number
        public let backingAmountToExit: Number
        public let minSwapBackingAmount: Number
        public let poolFee: UInt
        public let sender: EthAddress
        public let chainId: Number

        public enum CodingKeys: String, CodingKey {
            case exposureAssetSymbol = "exposure_asset_symbol"
            case backingAssetSymbol = "backing_asset_symbol"
            case marketId = "market_id"
            case exposureAmount = "exposure_amount"
            case backingAmountToExit = "backing_amount_to_exit"
            case minSwapBackingAmount = "min_swap_backing_amount"
            case poolFee = "pool_fee"
            case sender
            case chainId = "chain_id"
        }

        public init(
            exposureAssetSymbol: String,
            backingAssetSymbol: String,
            marketId: Hex,
            exposureAmount: Number,
            backingAmountToExit: Number,
            minSwapBackingAmount: Number,
            poolFee: UInt,
            sender: EthAddress,
            chainId: Number
        ) {
            self.exposureAssetSymbol = exposureAssetSymbol
            self.backingAssetSymbol = backingAssetSymbol
            self.marketId = marketId
            self.exposureAmount = exposureAmount
            self.backingAmountToExit = backingAmountToExit
            self.minSwapBackingAmount = minSwapBackingAmount
            self.poolFee = poolFee
            self.sender = sender
            self.chainId = chainId
        }
    }

    public struct UnloopShortIntent: Equatable, Codable, Hashable, Sendable {
        public let exposureAssetSymbol: String
        public let backingAssetSymbol: String
        public let marketId: Hex
        public let exposureAmount: Number
        public let backingAmountToExit: Number
        public let maxSwapBackingAmount: Number
        public let poolFee: UInt
        public let sender: EthAddress
        public let chainId: Number

        public enum CodingKeys: String, CodingKey {
            case exposureAssetSymbol = "exposure_asset_symbol"
            case backingAssetSymbol = "backing_asset_symbol"
            case marketId = "market_id"
            case exposureAmount = "exposure_amount"
            case backingAmountToExit = "backing_amount_to_exit"
            case maxSwapBackingAmount = "max_swap_backing_amount"
            case poolFee = "pool_fee"
            case sender
            case chainId = "chain_id"
        }

        public init(
            exposureAssetSymbol: String,
            backingAssetSymbol: String,
            marketId: Hex,
            exposureAmount: Number,
            backingAmountToExit: Number,
            maxSwapBackingAmount: Number,
            poolFee: UInt,
            sender: EthAddress,
            chainId: Number
        ) {
            self.exposureAssetSymbol = exposureAssetSymbol
            self.backingAssetSymbol = backingAssetSymbol
            self.marketId = marketId
            self.exposureAmount = exposureAmount
            self.backingAmountToExit = backingAmountToExit
            self.maxSwapBackingAmount = maxSwapBackingAmount
            self.poolFee = poolFee
            self.sender = sender
            self.chainId = chainId
        }
    }

    public struct WithdrawBackingTokenIntent: Equatable, Codable, Hashable, Sendable {
        public let exposureAssetSymbol: String
        public let backingAssetSymbol: String
        public let marketId: Hex
        public let amount: Number
        public let isShort: Bool
        public let sender: EthAddress
        public let chainId: Number

        public enum CodingKeys: String, CodingKey {
            case exposureAssetSymbol = "exposure_asset_symbol"
            case backingAssetSymbol = "backing_asset_symbol"
            case marketId = "market_id"
            case amount
            case isShort = "is_short"
            case sender
            case chainId = "chain_id"
        }

        public init(
            exposureAssetSymbol: String,
            backingAssetSymbol: String,
            marketId: Hex,
            amount: Number,
            isShort: Bool,
            sender: EthAddress,
            chainId: Number
        ) {
            self.exposureAssetSymbol = exposureAssetSymbol
            self.backingAssetSymbol = backingAssetSymbol
            self.marketId = marketId
            self.amount = amount
            self.isShort = isShort
            self.sender = sender
            self.chainId = chainId
        }
    }

    public enum WithdrawIntent: Equatable, Codable, Hashable, Sendable {
        case aave(AaveWithdrawIntent)
        case comet(CometWithdrawIntent)
        case morpho(MorphoVaultWithdrawIntent)

        enum CodingKeys: String, CodingKey {
            case intentType = "intent_type"
            case marketType = "market_type"
            case market
            case amount
            case assetSymbol = "asset_symbol"
            case chainId = "chain_id"
            case withdrawer
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("withdraw", forKey: .intentType)

            switch self {
                case .comet(let intent):
                    try container.encode("COMET", forKey: .marketType)
                    try container.encode(intent.comet, forKey: .market)
                    try container.encode(intent.amount, forKey: .amount)
                    try container.encode(intent.assetSymbol, forKey: .assetSymbol)
                    try container.encode(intent.chainId, forKey: .chainId)
                    try container.encode(intent.withdrawer, forKey: .withdrawer)

                case .aave(let intent):
                    try container.encode("AAVE", forKey: .marketType)
                    try container.encode(intent.aavePool, forKey: .market)
                    try container.encode(intent.amount, forKey: .amount)
                    try container.encode(intent.assetSymbol, forKey: .assetSymbol)
                    try container.encode(intent.chainId, forKey: .chainId)
                    try container.encode(intent.withdrawer, forKey: .withdrawer)

                case .morpho(let intent):
                    try container.encode("MORPHO", forKey: .marketType)
                    try container.encode(intent.morphoVault, forKey: .market)
                    try container.encode(intent.amount, forKey: .amount)
                    try container.encode(intent.assetSymbol, forKey: .assetSymbol)
                    try container.encode(intent.chainId, forKey: .chainId)
                    try container.encode(intent.withdrawer, forKey: .withdrawer)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let marketType = try container.decode(String.self, forKey: .marketType)

            switch marketType {
                case "COMET":
                    let amount = try container.decode(Number.self, forKey: .amount)
                    let assetSymbol = try container.decode(String.self, forKey: .assetSymbol)
                    let chainId = try container.decode(Number.self, forKey: .chainId)
                    let comet = try container.decode(EthAddress.self, forKey: .market)
                    let withdrawer = try container.decode(EthAddress.self, forKey: .withdrawer)

                    self = .comet(
                        CometWithdrawIntent(
                            amount: amount,
                            assetSymbol: assetSymbol,
                            chainId: chainId,
                            comet: comet,
                            withdrawer: withdrawer
                        )
                    )

                case "AAVE":
                    let amount = try container.decode(Number.self, forKey: .amount)
                    let assetSymbol = try container.decode(String.self, forKey: .assetSymbol)
                    let chainId = try container.decode(Number.self, forKey: .chainId)
                    let aavePool = try container.decode(EthAddress.self, forKey: .market)
                    let withdrawer = try container.decode(EthAddress.self, forKey: .withdrawer)

                    self = .aave(
                        AaveWithdrawIntent(
                            amount: amount,
                            assetSymbol: assetSymbol,
                            chainId: chainId,
                            aavePool: aavePool,
                            withdrawer: withdrawer
                        )
                    )

                case "MORPHO":
                    let amount = try container.decode(Number.self, forKey: .amount)
                    let assetSymbol = try container.decode(String.self, forKey: .assetSymbol)
                    let chainId = try container.decode(Number.self, forKey: .chainId)
                    let morphoVault = try container.decode(EthAddress.self, forKey: .market)
                    let withdrawer = try container.decode(EthAddress.self, forKey: .withdrawer)

                    self = .morpho(
                        MorphoVaultWithdrawIntent(
                            amount: amount,
                            assetSymbol: assetSymbol,
                            morphoVault: morphoVault,
                            chainId: chainId,
                            withdrawer: withdrawer
                        )
                    )

                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .marketType,
                        in: container,
                        debugDescription: "Unknown market type: \(marketType)"
                    )
            }
        }

        // Helper computed properties for common fields
        public var amount: Number {
            switch self {
                case .aave(let intent):
                    return intent.amount
                case .comet(let intent):
                    return intent.amount
                case .morpho(let intent):
                    return intent.amount
            }
        }

        public var assetSymbol: String {
            switch self {
                case .aave(let intent):
                    return intent.assetSymbol
                case .comet(let intent):
                    return intent.assetSymbol
                case .morpho(let intent):
                    return intent.assetSymbol
            }
        }

        public var chainId: Number {
            switch self {
                case .aave(let intent):
                    return intent.chainId
                case .comet(let intent):
                    return intent.chainId
                case .morpho(let intent):
                    return intent.chainId
            }
        }

        public var withdrawer: EthAddress {
            switch self {
                case .aave(let intent):
                    return intent.withdrawer
                case .comet(let intent):
                    return intent.withdrawer
                case .morpho(let intent):
                    return intent.withdrawer
            }
        }

        public var market: EthAddress {
            switch self {
                case .aave(let intent):
                    return intent.aavePool
                case .comet(let intent):
                    return intent.comet
                case .morpho(let intent):
                    return intent.morphoVault
            }
        }
    }
}
