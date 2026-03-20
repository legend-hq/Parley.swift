import Eth
import Foundation
import Prelude
import SwiftNumber

public struct SemanticEventContext: Codable, Equatable, Sendable {
    public let type: Type_
    public let logIndices: [Int?]

    public enum Type_: Equatable, Sendable {
        case aaveSupply(AaveSupply)
        case aaveWithdraw(AaveWithdraw)
        case cometSupplyBase(CometSupplyBase)
        case cometSupplyCollateral(CometSupplyCollateral)
        case cometRepay(CometRepay)
        case cometWithdrawBase(CometWithdrawBase)
        case cometWithdrawCollateral(CometWithdrawCollateral)
        case cometBorrow(CometBorrow)
        case cometLiquidationCollateralAbsorbed(CometLiquidationCollateralAbsorbed)
        case cometLiquidationBasePaidOut(CometLiquidationBasePaidOut)
        case cometClaimReward(CometClaimReward)
        case morphoClaimReward(MorphoClaimReward)
        case morphoSupplyCollateral(MorphoSupplyCollateral)
        case morphoWithdrawCollateral(MorphoWithdrawCollateral)
        case morphoBorrow(MorphoBorrow)
        case morphoRepay(MorphoRepay)
        case morphoVaultSupply(MorphoVaultSupply)
        case morphoVaultWithdraw(MorphoVaultWithdraw)
        case morphoLiquidation(MorphoLiquidation)
        case paycall(Paycall)
        case swap(Swap)
        case bridgeSend(BridgeSend)
        case bridgeReceive(BridgeReceive)
        case outboundTransfer(OutboundTransfer)
        case inboundTransfer(InboundTransfer)
        case loopLong(LoopLong)
        case unloopLong(UnloopLong)
        case recurringSwap(Swap)
        case addBackingToLoop(AddBackingToken)
        case withdrawBackingFromLoop(WithdrawBackingToken)
        case quotePay(QuotePay)
    }

    private enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case eventMetadata = "event_metadata"
        case logIndices = "log_indices"
    }

    public enum EventType: String, Codable, Equatable {
        case aaveSupply = "aave_supply"
        case aaveWithdraw = "aave_withdraw"
        case cometSupplyBase = "comet_supply_base"
        case cometSupplyCollateral = "comet_supply_collateral"
        case cometRepay = "comet_repay"
        case cometWithdrawBase = "comet_withdraw_base"
        case cometWithdrawCollateral = "comet_withdraw_collateral"
        case cometBorrow = "comet_borrow"
        case cometLiquidationCollateralAbsorbed = "comet_liquidation_collateral_absorbed"
        case cometLiquidationBasePaidOut = "comet_liquidation_base_paid_out"
        case cometClaimReward = "comet_claim_reward"
        case morphoClaimReward = "morpho_claim_reward"
        case morphoSupplyCollateral = "morpho_supply_collateral"
        case morphoWithdrawCollateral = "morpho_withdraw_collateral"
        case morphoBorrow = "morpho_borrow"
        case morphoRepay = "morpho_repay"
        case morphoVaultSupply = "morpho_vault_supply"
        case morphoVaultWithdraw = "morpho_vault_withdraw"
        case morphoLiquidation = "morpho_liquidation"
        case paycall
        case swap
        case bridgeSend = "bridge_send"
        case bridgeReceive = "bridge_receive"
        case outboundTransfer = "outbound_transfer"
        case inboundTransfer = "inbound_transfer"
        case recurringSwap = "recurring_swap"
        case loopLong = "loop_long"
        case unloopLong = "unloop_long"
        case addBackingToLoop = "add_backing_to_loop"
        case withdrawBackingFromLoop = "withdraw_backing_from_loop"
        case quotePay = "quote_pay"
    }

    public var eventType: EventType {
        switch type {
            case .aaveSupply:
                .aaveSupply
            case .aaveWithdraw:
                .aaveWithdraw
            case .cometSupplyBase:
                .cometSupplyBase
            case .cometSupplyCollateral:
                .cometSupplyCollateral
            case .cometRepay:
                .cometRepay
            case .cometWithdrawBase:
                .cometWithdrawBase
            case .cometWithdrawCollateral:
                .cometWithdrawCollateral
            case .cometBorrow:
                .cometBorrow
            case .cometLiquidationCollateralAbsorbed:
                .cometLiquidationCollateralAbsorbed
            case .cometLiquidationBasePaidOut:
                .cometLiquidationBasePaidOut
            case .cometClaimReward:
                .cometClaimReward
            case .morphoClaimReward:
                .morphoClaimReward
            case .morphoSupplyCollateral:
                .morphoSupplyCollateral
            case .morphoWithdrawCollateral:
                .morphoWithdrawCollateral
            case .morphoBorrow:
                .morphoBorrow
            case .morphoRepay:
                .morphoRepay
            case .morphoVaultSupply:
                .morphoVaultSupply
            case .morphoVaultWithdraw:
                .morphoVaultWithdraw
            case .morphoLiquidation:
                .morphoLiquidation
            case .paycall:
                .paycall
            case .swap:
                .swap
            case .recurringSwap:
                .recurringSwap
            case .bridgeSend:
                .bridgeSend
            case .bridgeReceive:
                .bridgeReceive
            case .outboundTransfer:
                .outboundTransfer
            case .inboundTransfer:
                .inboundTransfer
            case .loopLong:
                .loopLong
            case .unloopLong:
                .unloopLong
            case .addBackingToLoop:
                .addBackingToLoop
            case .withdrawBackingFromLoop:
                .withdrawBackingFromLoop
            case .quotePay:
                .quotePay
        }
    }

    public init(type: Type_) {
        self.type = type
        self.logIndices = []
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(EventType.self, forKey: .eventType)
        let logIndices = try container.decode([Int?].self, forKey: .logIndices)

        self.logIndices = logIndices

        switch eventType {
            case .aaveSupply:
                let context = try container.decode(AaveSupply.self, forKey: .eventMetadata)
                self.type = .aaveSupply(context)
            case .aaveWithdraw:
                let context = try container.decode(AaveWithdraw.self, forKey: .eventMetadata)
                self.type = .aaveWithdraw(context)
            case .cometSupplyBase:
                let context = try container.decode(CometSupplyBase.self, forKey: .eventMetadata)
                self.type = .cometSupplyBase(context)
            case .cometSupplyCollateral:
                let context = try container.decode(
                    CometSupplyCollateral.self,
                    forKey: .eventMetadata
                )
                self.type = .cometSupplyCollateral(context)
            case .cometRepay:
                let context = try container.decode(CometRepay.self, forKey: .eventMetadata)
                self.type = .cometRepay(context)
            case .cometWithdrawBase:
                let context = try container.decode(CometWithdrawBase.self, forKey: .eventMetadata)
                self.type = .cometWithdrawBase(context)
            case .cometWithdrawCollateral:
                let context = try container.decode(
                    CometWithdrawCollateral.self,
                    forKey: .eventMetadata
                )
                self.type = .cometWithdrawCollateral(context)
            case .cometBorrow:
                let context = try container.decode(CometBorrow.self, forKey: .eventMetadata)
                self.type = .cometBorrow(context)
            case .cometLiquidationCollateralAbsorbed:
                let context = try container.decode(
                    CometLiquidationCollateralAbsorbed.self,
                    forKey: .eventMetadata
                )
                self.type = .cometLiquidationCollateralAbsorbed(context)
            case .cometLiquidationBasePaidOut:
                let context = try container.decode(
                    CometLiquidationBasePaidOut.self,
                    forKey: .eventMetadata
                )
                self.type = .cometLiquidationBasePaidOut(context)
            case .cometClaimReward:
                let context = try container.decode(CometClaimReward.self, forKey: .eventMetadata)
                self.type = .cometClaimReward(context)
            case .morphoClaimReward:
                let context = try container.decode(MorphoClaimReward.self, forKey: .eventMetadata)
                self.type = .morphoClaimReward(context)
            case .morphoSupplyCollateral:
                let context = try container.decode(
                    MorphoSupplyCollateral.self,
                    forKey: .eventMetadata
                )
                self.type = .morphoSupplyCollateral(context)
            case .morphoWithdrawCollateral:
                let context = try container.decode(
                    MorphoWithdrawCollateral.self,
                    forKey: .eventMetadata
                )
                self.type = .morphoWithdrawCollateral(context)
            case .morphoBorrow:
                let context = try container.decode(MorphoBorrow.self, forKey: .eventMetadata)
                self.type = .morphoBorrow(context)
            case .morphoLiquidation:
                let context = try container.decode(MorphoLiquidation.self, forKey: .eventMetadata)
                self.type = .morphoLiquidation(context)
            case .morphoRepay:
                let context = try container.decode(MorphoRepay.self, forKey: .eventMetadata)
                self.type = .morphoRepay(context)
            case .morphoVaultSupply:
                let context = try container.decode(MorphoVaultSupply.self, forKey: .eventMetadata)
                self.type = .morphoVaultSupply(context)
            case .morphoVaultWithdraw:
                let context = try container.decode(MorphoVaultWithdraw.self, forKey: .eventMetadata)
                self.type = .morphoVaultWithdraw(context)
            case .paycall:
                let context = try container.decode(Paycall.self, forKey: .eventMetadata)
                self.type = .paycall(context)
            case .swap:
                let context = try container.decode(Swap.self, forKey: .eventMetadata)
                self.type = .swap(context)
            case .recurringSwap:
                let context = try container.decode(Swap.self, forKey: .eventMetadata)
                self.type = .recurringSwap(context)
            case .bridgeSend:
                let context = try container.decode(BridgeSend.self, forKey: .eventMetadata)
                self.type = .bridgeSend(context)
            case .bridgeReceive:
                let context = try container.decode(BridgeReceive.self, forKey: .eventMetadata)
                self.type = .bridgeReceive(context)
            case .outboundTransfer:
                let context = try container.decode(OutboundTransfer.self, forKey: .eventMetadata)
                self.type = .outboundTransfer(context)
            case .inboundTransfer:
                let context = try container.decode(InboundTransfer.self, forKey: .eventMetadata)
                self.type = .inboundTransfer(context)
            case .loopLong:
                let context = try container.decode(LoopLong.self, forKey: .eventMetadata)
                self.type = .loopLong(context)
            case .unloopLong:
                let context = try container.decode(UnloopLong.self, forKey: .eventMetadata)
                self.type = .unloopLong(context)
            case .addBackingToLoop:
                let context = try container.decode(AddBackingToken.self, forKey: .eventMetadata)
                self.type = .addBackingToLoop(context)
            case .withdrawBackingFromLoop:
                let context = try container.decode(
                    WithdrawBackingToken.self,
                    forKey: .eventMetadata
                )
                self.type = .withdrawBackingFromLoop(context)
            case .quotePay:
                let context = try container.decode(QuotePay.self, forKey: .eventMetadata)
                self.type = .quotePay(context)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(logIndices, forKey: .logIndices)

        switch type {
            case .aaveSupply(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .aaveWithdraw(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometSupplyBase(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometSupplyCollateral(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometRepay(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometWithdrawBase(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometWithdrawCollateral(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometBorrow(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometLiquidationCollateralAbsorbed(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometLiquidationBasePaidOut(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .cometClaimReward(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoClaimReward(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoSupplyCollateral(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoWithdrawCollateral(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoLiquidation(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoBorrow(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoRepay(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoVaultSupply(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .morphoVaultWithdraw(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .paycall(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .swap(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .recurringSwap(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .bridgeSend(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .bridgeReceive(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .outboundTransfer(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .inboundTransfer(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .loopLong(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .unloopLong(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .addBackingToLoop(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .withdrawBackingFromLoop(let context):
                try container.encode(context, forKey: .eventMetadata)
            case .quotePay(let context):
                try container.encode(context, forKey: .eventMetadata)
        }

    }

    public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
        switch type {
            case .aaveSupply(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .aaveWithdraw(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometSupplyBase(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometSupplyCollateral(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometRepay(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometWithdrawBase(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometWithdrawCollateral(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometBorrow(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometLiquidationCollateralAbsorbed(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometLiquidationBasePaidOut(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .cometClaimReward(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoClaimReward(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoSupplyCollateral(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoWithdrawCollateral(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoLiquidation(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoBorrow(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoRepay(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoVaultSupply(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .morphoVaultWithdraw(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .paycall(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .swap(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .recurringSwap(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .bridgeSend(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .bridgeReceive(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .outboundTransfer(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .inboundTransfer(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .loopLong(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .unloopLong(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .addBackingToLoop(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .withdrawBackingFromLoop(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
            case .quotePay(let context):
                context.toSemanticEvent(network: network, portfolios: portfolios)
        }
    }

    // MARK: Supply

    public struct AaveSupply: Codable, Equatable, Sendable {
        public let aavePool: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public enum CodingKeys: String, CodingKey {
            case aavePool = "aave_pool"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public init(aavePool: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.aavePool = aavePool
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getEarnMarketEvent(
                id: .aaveMarket(network, market: aavePool, baseAsset: token),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .aaveSupply($0) }
        }
    }

    public struct CometSupplyBase: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getEarnMarketEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometSupplyBaseAsset($0) }
        }
    }

    public struct MorphoVaultSupply: Codable, Equatable, Sendable {
        public let morphoVault: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(morphoVault: EthAddress, token: EthAddress, amount: Number, dollarValue: Number)
        {
            self.morphoVault = morphoVault
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case morphoVault = "morpho_vault"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getEarnMarketEvent(
                id: .morphoVault(network, morphoVault),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .morphoVaultSupply($0) }
        }
    }

    // MARK: Supply Collateral

    public struct CometSupplyCollateral: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketCollateralEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometSupplyCollateral($0) }
        }
    }

    public struct MorphoClaimReward: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number
        public let rewardsContract: EthAddress

        public init(
            token: EthAddress,
            amount: Number,
            dollarValue: Number,
            rewardsContract: EthAddress
        ) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
            self.rewardsContract = rewardsContract
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
            case rewardsContract = "rewards_contract"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }
            let amount = PricedAmount(amount, forAsset: asset, dollarValue: dollarValue)

            return .claimReward(.init(dApp: .Morpho, claimAmount: amount))
        }
    }

    public struct CometClaimReward: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number
        public let rewardsContract: EthAddress

        public init(
            token: EthAddress,
            amount: Number,
            dollarValue: Number,
            rewardsContract: EthAddress
        ) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
            self.rewardsContract = rewardsContract
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
            case rewardsContract = "rewards_contract"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }
            let amount = PricedAmount(amount, forAsset: asset, dollarValue: dollarValue)

            return .claimReward(.init(dApp: .Compound, claimAmount: amount))
        }
    }

    public struct MorphoSupplyCollateral: Codable, Equatable, Sendable {
        public let morpho: EthAddress
        public let morphoMarketId: Hex
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(
            morpho: EthAddress,
            morphoMarketId: Hex,
            token: EthAddress,
            amount: Number,
            dollarValue: Number
        ) {
            self.morpho = morpho
            self.morphoMarketId = morphoMarketId
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case morpho
            case morphoMarketId = "morpho_market_id"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketCollateralEvent(
                id: .morphoMarket(network, morphoMarketId),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .morphoSupplyCollateral($0) }
        }
    }

    // MARK: Repay

    public struct CometRepay: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketBaseAssetEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometRepay($0) }
        }
    }

    public struct MorphoRepay: Codable, Equatable, Sendable {
        public let morpho: EthAddress
        public let morphoMarketId: Hex
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(
            morpho: EthAddress,
            morphoMarketId: Hex,
            token: EthAddress,
            amount: Number,
            dollarValue: Number
        ) {
            self.morpho = morpho
            self.morphoMarketId = morphoMarketId
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case morpho
            case morphoMarketId = "morpho_market_id"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketBaseAssetEvent(
                id: .morphoMarket(network, morphoMarketId),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .morphoRepay($0) }
        }
    }

    // MARK: Withdraw

    public struct AaveWithdraw: Codable, Equatable, Sendable {
        public let aavePool: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(aavePool: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.aavePool = aavePool
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case aavePool = "aave_pool"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getEarnMarketEvent(
                id: .aaveMarket(network, market: aavePool, baseAsset: token),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .aaveWithdraw($0) }
        }
    }

    public struct CometWithdrawBase: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getEarnMarketEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometWithdrawBaseAsset($0) }
        }
    }

    public struct MorphoVaultWithdraw: Codable, Equatable, Sendable {
        public let morphoVault: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(morphoVault: EthAddress, token: EthAddress, amount: Number, dollarValue: Number)
        {
            self.morphoVault = morphoVault
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case morphoVault = "morpho_vault"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getEarnMarketEvent(
                id: .morphoVault(network, morphoVault),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .morphoVaultWithdraw($0) }
        }
    }

    // MARK: Withdraw Collateral

    public struct CometWithdrawCollateral: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketCollateralEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometWithdrawCollateral($0) }
        }
    }

    public struct MorphoWithdrawCollateral: Codable, Equatable, Sendable {
        public let morpho: EthAddress
        public let morphoMarketId: Hex
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(
            morpho: EthAddress,
            morphoMarketId: Hex,
            token: EthAddress,
            amount: Number,
            dollarValue: Number
        ) {
            self.morpho = morpho
            self.morphoMarketId = morphoMarketId
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case morpho
            case morphoMarketId = "morpho_market_id"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketCollateralEvent(
                id: .morphoMarket(network, morphoMarketId),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .morphoWithdrawCollateral($0) }
        }
    }

    // MARK: Borrow

    public struct CometBorrow: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketBaseAssetEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometBorrow($0) }
        }
    }

    public struct MorphoBorrow: Codable, Equatable, Sendable {
        public let morpho: EthAddress
        public let morphoMarketId: Hex
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(
            morpho: EthAddress,
            morphoMarketId: Hex,
            token: EthAddress,
            amount: Number,
            dollarValue: Number
        ) {
            self.morpho = morpho
            self.morphoMarketId = morphoMarketId
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case morpho
            case morphoMarketId = "morpho_market_id"
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketBaseAssetEvent(
                id: .morphoMarket(network, morphoMarketId),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .morphoBorrow($0) }
        }
    }

    // MARK: Liquidation

    public struct MorphoLiquidation: Codable, Equatable, Sendable {
        let morpho: EthAddress
        let morphoMarketId: Hex
        let repaidToken: EthAddress
        let repaidAmount: Number
        let repaidUsdValue: Number
        let seizedToken: EthAddress
        let seizedAmount: Number
        let seizedUsdValue: Number

        public init(
            morpho: EthAddress,
            morphoMarketId: Hex,
            repaidToken: EthAddress,
            repaidAmount: Number,
            repaidUsdValue: Number,
            seizedToken: EthAddress,
            seizedAmount: Number,
            seizedUsdValue: Number
        ) {
            self.morpho = morpho
            self.morphoMarketId = morphoMarketId
            self.repaidToken = repaidToken
            self.repaidAmount = repaidAmount
            self.repaidUsdValue = repaidUsdValue
            self.seizedToken = seizedToken
            self.seizedAmount = seizedAmount
            self.seizedUsdValue = seizedUsdValue
        }

        public enum CodingKeys: String, CodingKey {
            case morpho
            case morphoMarketId = "morpho_market_id"
            case repaidToken = "repaid_token"
            case repaidAmount = "repaid_amount"
            case repaidUsdValue = "repaid_usd_value"
            case seizedToken = "seized_token"
            case seizedAmount = "seized_amount"
            case seizedUsdValue = "seized_usd_value"
        }

        func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            guard
                let borrowMarket = portfolios.getBorrowMarket(
                    id: .morphoMarket(network, morphoMarketId)
                )
            else {
                return nil
            }

            guard let collateralAsset = borrowMarket.collateralAssets.first else {
                return nil
            }

            return .morphoLiquidation(
                MorphoLiquidationEvent(
                    borrowMarket: borrowMarket,
                    collateralSeized: .init(
                        seizedAmount,
                        forAsset: collateralAsset,
                        dollarValue: seizedUsdValue
                    ),
                    debtRepaid: .init(
                        repaidAmount,
                        forAsset: borrowMarket.baseAsset,
                        dollarValue: repaidUsdValue
                    )
                )
            )
        }
    }

    public struct CometLiquidationCollateralAbsorbed: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketCollateralEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometLiquidationCollateralAbsorbed($0) }
        }
    }

    public struct CometLiquidationBasePaidOut: Codable, Equatable, Sendable {
        public let comet: EthAddress
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(comet: EthAddress, token: EthAddress, amount: Number, dollarValue: Number) {
            self.comet = comet
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case comet
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            getBorrowMarketBaseAssetEvent(
                id: .cometMarket(network, comet),
                token: token,
                amount: amount,
                dollarValue: dollarValue,
                portfolios: portfolios
            )
            .map { .cometLiquidationBaseAssetPaidOut($0) }
        }
    }

    // MARK: Swap

    public struct Swap: Codable, Equatable, Sendable {
        public let inputToken: EthAddress
        public let inputAmount: Number
        public let inputDollarValue: Number
        public let outputToken: EthAddress
        public let outputAmount: Number
        public let outputDollarValue: Number
        public let swapVenue: String

        public init(
            inputToken: EthAddress,
            inputAmount: Number,
            inputDollarValue: Number,
            outputToken: EthAddress,
            outputAmount: Number,
            outputDollarValue: Number,
            swapVenue: String
        ) {
            self.inputToken = inputToken
            self.inputAmount = inputAmount
            self.inputDollarValue = inputDollarValue
            self.outputToken = outputToken
            self.outputAmount = outputAmount
            self.outputDollarValue = outputDollarValue
            self.swapVenue = swapVenue
        }

        public enum CodingKeys: String, CodingKey {
            case inputToken = "input_token"
            case inputAmount = "input_amount"
            case inputDollarValue = "input_dollar_value"
            case outputToken = "output_token"
            case outputAmount = "output_amount"
            case outputDollarValue = "output_dollar_value"
            case swapVenue = "swap_venue"
        }

        public func toSwapEvent(network: Network, portfolios: [Portfolio]) -> SwapEvent? {
            guard let inAsset = portfolios.getAsset(token: inputToken, chain: network),
                let outAsset = portfolios.getAsset(token: outputToken, chain: network),
                let venue = SwapVenue(rawValue: swapVenue)
            else {
                return nil
            }

            let inAmount = PricedAmount(
                inputAmount,
                forAsset: inAsset,
                dollarValue: inputDollarValue
            )

            let outAmount = PricedAmount(
                outputAmount,
                forAsset: outAsset,
                dollarValue: outputDollarValue
            )

            return SwapEvent(
                inAmount: inAmount,
                outAmount: outAmount,
                swapVenue: venue
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toSwapEvent(network: network, portfolios: portfolios).map { .swap($0) }
        }
    }

    // MARK: Bridge

    public struct BridgeSend: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number
        public let srcChain: Number
        public let dstChain: Number
        public let bridgeFees: Number
        public let bridgeFeesDollarValue: Number
        public let bridge: String
        public let depositId: Number?
        public let relayHash: Hex?
        public let sourceChainId: UInt64?
        public let nonce: Hex?

        public init(
            token: EthAddress,
            amount: Number,
            dollarValue: Number,
            srcChain: Number,
            dstChain: Number,
            bridgeFees: Number,
            bridgeFeesDollarValue: Number,
            bridge: String,
            depositId: Number?,
            relayHash: Hex?,
            sourceChainId: UInt64? = nil,
            nonce: Hex? = nil
        ) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
            self.srcChain = srcChain
            self.dstChain = dstChain
            self.bridgeFees = bridgeFees
            self.bridgeFeesDollarValue = bridgeFeesDollarValue
            self.bridge = bridge
            self.depositId = depositId
            self.relayHash = relayHash
            self.sourceChainId = sourceChainId
            self.nonce = nonce
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
            case srcChain = "src_chain"
            case dstChain = "dst_chain"
            case bridgeFees = "bridge_fees"
            case bridgeFeesDollarValue = "bridge_fees_dollar_value"
            case bridge
            case depositId = "deposit_id"
            case relayHash = "relay_hash"
            case sourceChainId = "source_chain_id"
            case nonce
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.token = try container.decode(EthAddress.self, forKey: .token)
            self.amount = try container.decode(Number.self, forKey: .amount)
            self.dollarValue = try container.decode(Number.self, forKey: .dollarValue)
            self.srcChain = try container.decode(Number.self, forKey: .srcChain)
            self.dstChain = try container.decode(Number.self, forKey: .dstChain)
            self.bridgeFees = try container.decode(Number.self, forKey: .bridgeFees)
            self.bridgeFeesDollarValue = try container.decode(
                Number.self,
                forKey: .bridgeFeesDollarValue
            )
            self.bridge = try container.decode(String.self, forKey: .bridge)

            self.relayHash = try container.decodeIfPresent(Hex.self, forKey: .relayHash)
            self.depositId = try container.decodeIfPresent(Number.self, forKey: .depositId)
            self.sourceChainId = try container.decodeIfPresent(UInt64.self, forKey: .sourceChainId)
            self.nonce = try container.decodeIfPresent(Hex.self, forKey: .nonce)
        }

        public func toBridgeSendEvent(network _: Network, portfolios: [Portfolio])
            -> BridgeSendEvent?
        {
            guard let bridge = Bridge(rawValue: bridge)
            else {
                return nil
            }

            let sourceNetwork = Network.fromChainId(srcChain)
            let destinationNetwork = Network.fromChainId(dstChain)

            guard let sourceChainAsset = portfolios.getAsset(token: token, chain: sourceNetwork)
            else {
                return nil
            }

            let bridgeAmount = PricedAmount(
                amount,
                forAsset: sourceChainAsset,
                dollarValue: dollarValue
            )

            let bridgeFee = PricedAmount(
                bridgeFees,
                forAsset: sourceChainAsset,
                dollarValue: bridgeFeesDollarValue
            )

            return BridgeSendEvent(
                bridgeAmount: bridgeAmount,
                bridgeFee: bridgeFee,
                bridge: bridge,
                destinationNetwork: destinationNetwork
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toBridgeSendEvent(network: network, portfolios: portfolios).map { .bridgeSend($0) }
        }
    }

    public struct BridgeReceive: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number
        public let dstChain: Number
        public let bridgeFees: Number
        public let bridgeFeesDollarValue: Number
        public let bridge: String

        public init(
            token: EthAddress,
            amount: Number,
            dollarValue: Number,
            dstChain: Number,
            bridgeFees: Number,
            bridgeFeesDollarValue: Number,
            bridge: String
        ) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
            self.dstChain = dstChain
            self.bridgeFees = bridgeFees
            self.bridgeFeesDollarValue = bridgeFeesDollarValue
            self.bridge = bridge
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
            case dstChain = "dst_chain"
            case bridgeFees = "bridge_fees"
            case bridgeFeesDollarValue = "bridge_fees_dollar_value"
            case bridge
        }

        public func toBridgeReceiveEvent(network _: Network, portfolios: [Portfolio])
            -> BridgeReceiveEvent?
        {
            guard let bridge = Bridge(rawValue: bridge)
            else {
                return nil
            }

            let destinationNetwork = Network.fromChainId(dstChain)

            guard
                let destinationChainAsset = portfolios.getAsset(
                    token: token,
                    chain: destinationNetwork
                )
            else {
                return nil
            }

            let bridgeAmount = PricedAmount(
                amount,
                forAsset: destinationChainAsset,
                dollarValue: dollarValue
            )

            let bridgeFee = PricedAmount(
                bridgeFees,
                forAsset: destinationChainAsset,
                dollarValue: bridgeFeesDollarValue
            )

            return BridgeReceiveEvent(
                bridgeAmount: bridgeAmount,
                bridgeFee: bridgeFee,
                bridge: bridge
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toBridgeReceiveEvent(network: network, portfolios: portfolios)
                .map {
                    .bridgeReceive($0)
                }
        }
    }

    // MARK: Transfer

    public struct OutboundTransfer: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number
        public let recipient: EthAddress

        public init(token: EthAddress, amount: Number, dollarValue: Number, recipient: EthAddress) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
            self.recipient = recipient
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
            case recipient
        }

        public func toOutboundTransferEvent(network: Network, portfolios: [Portfolio])
            -> OutboundTransferEvent?
        {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }

            let amount = PricedAmount(
                amount,
                forAsset: asset,
                dollarValue: dollarValue
            )

            return OutboundTransferEvent(
                transferAmount: amount,
                recipient: ChainAddress(recipient, chain: network)
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toOutboundTransferEvent(network: network, portfolios: portfolios)
                .map {
                    .outboundTransfer($0)
                }
        }
    }

    public struct InboundTransfer: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number
        public let sender: EthAddress

        public init(token: EthAddress, amount: Number, dollarValue: Number, sender: EthAddress) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
            self.sender = sender
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
            case sender
        }

        public func toInboundTransferEvent(network: Network, portfolios: [Portfolio])
            -> InboundTransferEvent?
        {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }

            let amount = PricedAmount(
                amount,
                forAsset: asset,
                dollarValue: dollarValue
            )

            return InboundTransferEvent(
                transferAmount: amount,
                sender: ChainAddress(sender, chain: network)
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toInboundTransferEvent(network: network, portfolios: portfolios)
                .map {
                    .inboundTransfer($0)
                }
        }
    }

    // MARK: Loop

    public struct LoopLong: Codable, Equatable, Sendable {
        public let borrowMarketId: Hex
        public let backingToken: EthAddress
        public let backingAmount: Number
        public let backingDollarValue: Number
        public let exposureToken: EthAddress
        public let exposureAmount: Number
        public let exposureDollarValue: Number
        public let swapInputToken: EthAddress
        public let swapInputAmount: Number
        public let swapInputDollarValue: Number
        public let swapOutputToken: EthAddress
        public let swapOutputAmount: Number
        public let swapOutputDollarValue: Number
        public let swapVenue: String
        public let borrowVenue: String

        public init(
            borrowMarketId: Hex,
            backingToken: EthAddress,
            backingAmount: Number,
            backingDollarValue: Number,
            exposureToken: EthAddress,
            exposureAmount: Number,
            exposureDollarValue: Number,
            swapInputToken: EthAddress,
            swapInputAmount: Number,
            swapInputDollarValue: Number,
            swapOutputToken: EthAddress,
            swapOutputAmount: Number,
            swapOutputDollarValue: Number,
            swapVenue: String,
            borrowVenue: String
        ) {
            self.borrowMarketId = borrowMarketId
            self.backingToken = backingToken
            self.backingAmount = backingAmount
            self.backingDollarValue = backingDollarValue
            self.exposureToken = exposureToken
            self.exposureAmount = exposureAmount
            self.exposureDollarValue = exposureDollarValue
            self.swapInputToken = swapInputToken
            self.swapInputAmount = swapInputAmount
            self.swapInputDollarValue = swapInputDollarValue
            self.swapOutputToken = swapOutputToken
            self.swapOutputAmount = swapOutputAmount
            self.swapOutputDollarValue = swapOutputDollarValue
            self.swapVenue = swapVenue
            self.borrowVenue = borrowVenue
        }

        public enum CodingKeys: String, CodingKey {
            case borrowMarketId = "borrow_market_id"
            case backingToken = "backing_token"
            case backingAmount = "backing_amount"
            case backingDollarValue = "backing_dollar_value"
            case exposureToken = "exposure_token"
            case exposureAmount = "exposure_amount"
            case exposureDollarValue = "exposure_dollar_value"
            case swapInputToken = "swap_input_token"
            case swapInputAmount = "swap_input_amount"
            case swapInputDollarValue = "swap_input_dollar_value"
            case swapOutputToken = "swap_output_token"
            case swapOutputAmount = "swap_output_amount"
            case swapOutputDollarValue = "swap_output_dollar_value"
            case swapVenue = "swap_venue"
            case borrowVenue = "borrow_venue"
        }

        public func toLoopLongEvent(network: Network, portfolios: [Portfolio]) -> LoopLongEvent? {
            guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
                Logger.error(
                    "Loop Long backing asset not found. Token: \(backingToken.hex), Chain: \(network.description)"
                )
                return nil
            }

            guard let exposureAsset = portfolios.getAsset(token: exposureToken, chain: network)
            else {
                Logger.error(
                    "Loop Long exposure asset not found. Token: \(exposureToken.hex), Chain: \(network.description)"
                )
                return nil
            }

            guard let swapInputAsset = portfolios.getAsset(token: swapInputToken, chain: network)
            else {
                Logger.error(
                    "Loop Long swap input asset not found. Token: \(swapInputToken), Chain: \(network.description)"
                )
                return nil
            }

            guard let swapOutputAsset = portfolios.getAsset(token: swapOutputToken, chain: network)
            else {
                Logger.error(
                    "Loop Long swap output asset not found. Token: \(swapOutputToken), Chain: \(network.description)"
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

            guard let swapVenue = SwapVenue(rawValue: swapVenue) else {
                Logger.error("Loop Long swap venue not found. Id: \(swapVenue)")
                return nil
            }

            return .init(
                morphoMarket: morphoMarket,
                swapVenue: swapVenue.dApp,
                backingAmount: PricedAmount(
                    backingAmount,
                    forAsset: backingAsset,
                    dollarValue: backingDollarValue
                ),
                exposureAmount: PricedAmount(
                    exposureAmount,
                    forAsset: exposureAsset,
                    dollarValue: exposureDollarValue
                ),
                swapInputAmount: PricedAmount(
                    swapInputAmount,
                    forAsset: swapInputAsset,
                    dollarValue: swapInputDollarValue
                ),
                swapOutputAmount: PricedAmount(
                    swapOutputAmount,
                    forAsset: swapOutputAsset,
                    dollarValue: swapOutputDollarValue
                )
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toLoopLongEvent(network: network, portfolios: portfolios).map { .loopLong($0) }
        }
    }

    public struct UnloopLong: Codable, Equatable, Sendable {
        public let borrowMarketId: Hex
        public let backingToken: EthAddress
        public let backingAmount: Number
        public let backingDollarValue: Number
        public let exposureToken: EthAddress
        public let exposureAmount: Number
        public let exposureDollarValue: Number
        public let swapInputToken: EthAddress
        public let swapInputAmount: Number
        public let swapInputDollarValue: Number
        public let swapOutputToken: EthAddress
        public let swapOutputAmount: Number
        public let swapOutputDollarValue: Number
        public let swapVenue: String
        public let borrowVenue: String

        public init(
            borrowMarketId: Hex,
            backingToken: EthAddress,
            backingAmount: Number,
            backingDollarValue: Number,
            exposureToken: EthAddress,
            exposureAmount: Number,
            exposureDollarValue: Number,
            swapInputToken: EthAddress,
            swapInputAmount: Number,
            swapInputDollarValue: Number,
            swapOutputToken: EthAddress,
            swapOutputAmount: Number,
            swapOutputDollarValue: Number,
            swapVenue: String,
            borrowVenue: String
        ) {
            self.borrowMarketId = borrowMarketId
            self.backingToken = backingToken
            self.backingAmount = backingAmount
            self.backingDollarValue = backingDollarValue
            self.exposureToken = exposureToken
            self.exposureAmount = exposureAmount
            self.exposureDollarValue = exposureDollarValue
            self.swapInputToken = swapInputToken
            self.swapInputAmount = swapInputAmount
            self.swapInputDollarValue = swapInputDollarValue
            self.swapOutputToken = swapOutputToken
            self.swapOutputAmount = swapOutputAmount
            self.swapOutputDollarValue = swapOutputDollarValue
            self.swapVenue = swapVenue
            self.borrowVenue = borrowVenue
        }

        public enum CodingKeys: String, CodingKey {
            case borrowMarketId = "borrow_market_id"
            case backingToken = "backing_token"
            case backingAmount = "backing_amount"
            case backingDollarValue = "backing_dollar_value"
            case exposureToken = "exposure_token"
            case exposureAmount = "exposure_amount"
            case exposureDollarValue = "exposure_dollar_value"
            case swapInputToken = "swap_input_token"
            case swapInputAmount = "swap_input_amount"
            case swapInputDollarValue = "swap_input_dollar_value"
            case swapOutputToken = "swap_output_token"
            case swapOutputAmount = "swap_output_amount"
            case swapOutputDollarValue = "swap_output_dollar_value"
            case swapVenue = "swap_venue"
            case borrowVenue = "borrow_venue"
        }

        public func toUnloopLongEvent(network: Network, portfolios: [Portfolio]) -> UnloopLongEvent?
        {
            guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
                Logger.error(
                    "Loop Long backing asset not found. Token: \(backingToken.hex), Chain: \(network.description)"
                )
                return nil
            }

            guard let exposureAsset = portfolios.getAsset(token: exposureToken, chain: network)
            else {
                Logger.error(
                    "Loop Long exposure asset not found. Token: \(exposureToken.hex), Chain: \(network.description)"
                )
                return nil
            }

            guard let swapInputAsset = portfolios.getAsset(token: swapInputToken, chain: network)
            else {
                Logger.error(
                    "Loop Long swap input asset not found. Token: \(swapInputToken), Chain: \(network.description)"
                )
                return nil
            }

            guard let swapOutputAsset = portfolios.getAsset(token: swapOutputToken, chain: network)
            else {
                Logger.error(
                    "Loop Long swap output asset not found. Token: \(swapOutputToken), Chain: \(network.description)"
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

            guard let swapVenue = SwapVenue(rawValue: swapVenue) else {
                Logger.error("Loop Long swap venue not found. Id: \(swapVenue)")
                return nil
            }

            return .init(
                morphoMarket: morphoMarket,
                swapVenue: swapVenue.dApp,
                backingAmount: PricedAmount(
                    backingAmount,
                    forAsset: backingAsset,
                    dollarValue: backingDollarValue
                ),
                exposureAmount: PricedAmount(
                    exposureAmount,
                    forAsset: exposureAsset,
                    dollarValue: exposureDollarValue
                ),
                swapInputAmount: PricedAmount(
                    swapInputAmount,
                    forAsset: swapInputAsset,
                    dollarValue: swapInputDollarValue
                ),
                swapOutputAmount: PricedAmount(
                    swapOutputAmount,
                    forAsset: swapOutputAsset,
                    dollarValue: swapOutputDollarValue
                )
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toUnloopLongEvent(network: network, portfolios: portfolios).map { .unloopLong($0) }
        }

    }

    public struct AddBackingToken: Codable, Equatable, Sendable {
        let borrowMarketId: Hex
        let backingToken: EthAddress
        let backingAmount: Number
        let backingDollarValue: Number
        let borrowVenue: String
        let isShort: Bool

        public init(
            borrowMarketId: Hex,
            backingToken: EthAddress,
            backingAmount: Number,
            backingDollarValue: Number,
            borrowVenue: String,
            isShort: Bool
        ) {
            self.borrowMarketId = borrowMarketId
            self.backingToken = backingToken
            self.backingAmount = backingAmount
            self.backingDollarValue = backingDollarValue
            self.borrowVenue = borrowVenue
            self.isShort = isShort
        }

        public enum CodingKeys: String, CodingKey {
            case borrowMarketId = "borrow_market_id"
            case backingToken = "backing_token"
            case backingAmount = "backing_amount"
            case backingDollarValue = "backing_dollar_value"
            case borrowVenue = "borrow_venue"
            case isShort = "is_short"
        }

        func toAddBackingTokenEvent(network: Network, portfolios: [Portfolio])
            -> AddBackingTokenEvent?
        {
            guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
                Logger.error(
                    "Add backing token backing asset not found. Token: \(backingToken.hex), Chain: \(network.description)"
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
                    "Add backing token borrow market not found. Id: \(borrowMarketId), Chain: \(network.description)"
                )
                return nil
            }

            return .init(
                morphoMarket: morphoMarket,
                backingAmount: PricedAmount(
                    backingAmount,
                    forAsset: backingAsset,
                    dollarValue: backingDollarValue
                ),
                isShort: isShort
            )
        }

        func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toAddBackingTokenEvent(network: network, portfolios: portfolios)
                .map { .addBackingToken($0) }
        }
    }

    public struct WithdrawBackingToken: Codable, Equatable, Sendable {
        let borrowMarketId: Hex
        let backingToken: EthAddress
        let backingAmount: Number
        let backingDollarValue: Number
        let borrowVenue: String
        let isShort: Bool

        enum CodingKeys: String, CodingKey {
            case borrowMarketId = "borrow_market_id"
            case backingToken = "backing_token"
            case backingAmount = "backing_amount"
            case backingDollarValue = "backing_dollar_value"
            case borrowVenue = "borrow_venue"
            case isShort = "is_short"
        }

        public init(
            borrowMarketId: Hex,
            backingToken: EthAddress,
            backingAmount: Number,
            backingDollarValue: Number,
            borrowVenue: String,
            isShort: Bool
        ) {
            self.borrowMarketId = borrowMarketId
            self.backingToken = backingToken
            self.backingAmount = backingAmount
            self.backingDollarValue = backingDollarValue
            self.borrowVenue = borrowVenue
            self.isShort = isShort
        }

        func toWithdrawBackingTokenEvent(network: Network, portfolios: [Portfolio])
            -> WithdrawBackingTokenEvent?
        {
            guard let backingAsset = portfolios.getAsset(token: backingToken, chain: network) else {
                Logger.error(
                    "Withdraw backing token backing asset not found. Token: \(backingToken.hex), Chain: \(network.description)"
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
                    "Withdraw backing token borrow market not found. Id: \(borrowMarketId), Chain: \(network.description)"
                )
                return nil
            }

            return .init(
                morphoMarket: morphoMarket,
                backingAmount: PricedAmount(
                    backingAmount,
                    forAsset: backingAsset,
                    dollarValue: backingDollarValue
                ),
                isShort: isShort
            )
        }

        func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toWithdrawBackingTokenEvent(network: network, portfolios: portfolios)
                .map { .withdrawBackingToken($0) }
        }
    }

    // MARK: Payment

    public struct Paycall: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(token: EthAddress, amount: Number, dollarValue: Number) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toPayEvent(network: Network, portfolios: [Portfolio]) -> PayEvent? {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }

            let amount = PricedAmount(
                amount,
                forAsset: asset,
                dollarValue: dollarValue
            )

            return PayEvent(
                amount: amount
            )
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toPayEvent(network: network, portfolios: portfolios).map { .paycall($0) }
        }
    }

    public struct QuotePay: Codable, Equatable, Sendable {
        public let token: EthAddress
        public let amount: Number
        public let dollarValue: Number

        public init(token: EthAddress, amount: Number, dollarValue: Number) {
            self.token = token
            self.amount = amount
            self.dollarValue = dollarValue
        }

        public enum CodingKeys: String, CodingKey {
            case token
            case amount
            case dollarValue = "dollar_value"
        }

        public func toQuotePayEvent(network: Network, portfolios: [Portfolio]) -> QuotePayEvent? {
            guard let asset = portfolios.getAsset(token: token, chain: network) else {
                return nil
            }

            let amount = PricedAmount(
                amount,
                forAsset: asset,
                withPrice: dollarValue
            )

            return QuotePayEvent(amount: amount)
        }

        public func toSemanticEvent(network: Network, portfolios: [Portfolio]) -> SemanticEvent? {
            toQuotePayEvent(network: network, portfolios: portfolios).map { .quotePay($0) }
        }
    }
}

private func getEarnMarketEvent(
    id: MarketIdentifier,
    token: EthAddress,
    amount: Number,
    dollarValue: Number,
    portfolios: [Portfolio]
) -> EarnMarketEvent? {
    guard let earnMarket = portfolios.getEarnMarket(id: id) else {
        return nil
    }

    guard earnMarket.baseAsset.address == token else {
        return nil
    }

    let amount = PricedAmount(amount, forAsset: earnMarket.baseAsset, dollarValue: dollarValue)
    return EarnMarketEvent(
        earnMarket: earnMarket,
        amount: amount
    )
}

private func getBorrowMarketBaseAssetEvent(
    id: MarketIdentifier,
    token: EthAddress,
    amount: Number,
    dollarValue: Number,
    portfolios: [Portfolio]
) -> BorrowMarketBaseAssetEvent? {
    guard let borrowMarket = portfolios.getBorrowMarket(id: id) else {
        return nil
    }

    guard borrowMarket.baseAsset.address == token else {
        return nil
    }

    let amount = PricedAmount(amount, forAsset: borrowMarket.baseAsset, dollarValue: dollarValue)
    return BorrowMarketBaseAssetEvent(
        borrowMarket: borrowMarket,
        amount: amount
    )
}

private func getBorrowMarketCollateralEvent(
    id: MarketIdentifier,
    token: EthAddress,
    amount: Number,
    dollarValue: Number,
    portfolios: [Portfolio]
) -> BorrowMarketCollateralEvent? {
    guard let borrowMarket = portfolios.getBorrowMarket(id: id) else {
        return nil
    }

    guard let collateralAsset = borrowMarket.getCollateralAsset(token: token) else {
        return nil
    }

    let amount = PricedAmount(amount, forAsset: collateralAsset, dollarValue: dollarValue)
    return BorrowMarketCollateralEvent(
        borrowMarket: borrowMarket,
        amount: amount
    )
}
