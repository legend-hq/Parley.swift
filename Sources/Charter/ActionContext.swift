import Eth
import Foundation
import Prelude
import SwiftNumber

extension Charter {
    public enum ActionContext: Codable, Equatable, Hashable, Sendable {
        case cometBorrow(CometBorrowActionContext)
        case morphoBorrow(MorphoBorrowActionContext)
        case bridge(BridgeActionContext)
        case bridgeMint(BridgeMintActionContext)
        case cometRepay(CometRepayActionContext)
        case morphoRepay(MorphoRepayActionContext)
        case aaveSupply(AaveSupplyActionContext)
        case cometSupply(CometSupplyActionContext)
        case morphoVaultSupply(MorphoVaultSupplyActionContext)
        case swap(SwapActionContext)
        case transfer(TransferActionContext)
        case aaveWithdraw(AaveWithdrawActionContext)
        case cometWithdraw(CometWithdrawActionContext)
        case morphoVaultWithdraw(MorphoVaultWithdrawActionContext)
        case withdrawAndBorrow(WithdrawAndBorrowActionContext)
        case recurringSwap(RecurringSwapActionContext)
        case quotePay(QuotePayActionContext)
        case wrap(WrapActionContext)
        case unwrap(UnwrapActionContext)
        case cometClaimRewards(CometClaimRewardsActionContext)
        case morphoClaimRewards(MorphoClaimRewardsActionContext)
        case multiAction([ActionContext])
        case addBackingToken(AddBackingTokenActionContext)
        case loopLong(LoopLongActionContext)
        case unloopLong(UnloopLongActionContext)
        case loopShort(LoopShortActionContext)
        case unloopShort(UnloopShortActionContext)
        case withdrawBackingToken(WithdrawBackingTokenActionContext)

        enum CodingKeys: String, CodingKey {
            case actionType = "action_type"
            case actionContext = "action_context"
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(actionType, forKey: .actionType)
            try encodeBody(to: encoder)
        }

        /// Encodes the context body without the action_type discriminator.
        public func encodeBody(to encoder: Encoder) throws {
            switch self {
                case .cometBorrow(let ctx): try ctx.encode(to: encoder)
                case .morphoBorrow(let ctx): try ctx.encode(to: encoder)
                case .bridge(let ctx): try ctx.encode(to: encoder)
                case .bridgeMint(let ctx): try ctx.encode(to: encoder)
                case .cometRepay(let ctx): try ctx.encode(to: encoder)
                case .morphoRepay(let ctx): try ctx.encode(to: encoder)
                case .aaveSupply(let ctx): try ctx.encode(to: encoder)
                case .cometSupply(let ctx): try ctx.encode(to: encoder)
                case .morphoVaultSupply(let ctx): try ctx.encode(to: encoder)
                case .swap(let ctx): try ctx.encode(to: encoder)
                case .transfer(let ctx): try ctx.encode(to: encoder)
                case .aaveWithdraw(let ctx): try ctx.encode(to: encoder)
                case .cometWithdraw(let ctx): try ctx.encode(to: encoder)
                case .morphoVaultWithdraw(let ctx): try ctx.encode(to: encoder)
                case .withdrawAndBorrow(let ctx): try ctx.encode(to: encoder)
                case .recurringSwap(let ctx): try ctx.encode(to: encoder)
                case .quotePay(let ctx): try ctx.encode(to: encoder)
                case .wrap(let ctx): try ctx.encode(to: encoder)
                case .unwrap(let ctx): try ctx.encode(to: encoder)
                case .cometClaimRewards(let ctx): try ctx.encode(to: encoder)
                case .morphoClaimRewards(let ctx): try ctx.encode(to: encoder)
                case .addBackingToken(let ctx): try ctx.encode(to: encoder)
                case .loopLong(let ctx): try ctx.encode(to: encoder)
                case .unloopLong(let ctx): try ctx.encode(to: encoder)
                case .loopShort(let ctx): try ctx.encode(to: encoder)
                case .unloopShort(let ctx): try ctx.encode(to: encoder)
                case .withdrawBackingToken(let ctx): try ctx.encode(to: encoder)
                case .multiAction(let contexts):
                    var multiContainer = encoder.container(
                        keyedBy: MultiActionContext.CodingKeys.self
                    )
                    try multiContainer.encode(contexts.map(\.actionType), forKey: .actionTypes)
                    var actionContextsContainer = multiContainer.nestedUnkeyedContainer(
                        forKey: .actionContexts
                    )
                    try contexts.forEach { context in
                        try context.encode(to: actionContextsContainer.superEncoder())
                    }
            }
        }

        public init(from decoder: Decoder) throws {
            self = try Self.decodeActionContext(from: decoder)
        }

        /// Decodes an ActionContext body from a decoder given an externally-provided actionType.
        /// Use this when the action_type is not embedded in the encoded data.
        public static func decodeBody(from decoder: Decoder, actionType: String) throws
            -> ActionContext
        {
            switch actionType {
                case CometBorrowActionContext.actionType, "BORROW":
                    return try .cometBorrow(CometBorrowActionContext(from: decoder))
                case MorphoBorrowActionContext.actionType:
                    return try .morphoBorrow(MorphoBorrowActionContext(from: decoder))
                case BridgeActionContext.actionType, "BRIDGE_CCTP_V2_BURN":
                    return try .bridge(BridgeActionContext(from: decoder))
                case BridgeMintActionContext.actionType, "BRIDGE_CCTP_V2_MINT":
                    return try .bridgeMint(BridgeMintActionContext(from: decoder))
                case CometRepayActionContext.actionType, "REPAY":
                    return try .cometRepay(CometRepayActionContext(from: decoder))
                case MorphoRepayActionContext.actionType:
                    return try .morphoRepay(MorphoRepayActionContext(from: decoder))
                case AaveSupplyActionContext.actionType:
                    return try .aaveSupply(AaveSupplyActionContext(from: decoder))
                case CometSupplyActionContext.actionType, "SUPPLY":
                    return try .cometSupply(CometSupplyActionContext(from: decoder))
                case MorphoVaultSupplyActionContext.actionType:
                    return try .morphoVaultSupply(MorphoVaultSupplyActionContext(from: decoder))
                case SwapActionContext.actionType:
                    return try .swap(SwapActionContext(from: decoder))
                case TransferActionContext.actionType:
                    return try .transfer(TransferActionContext(from: decoder))
                case AaveWithdrawActionContext.actionType:
                    return try .aaveWithdraw(AaveWithdrawActionContext(from: decoder))
                case CometWithdrawActionContext.actionType, "WITHDRAW":
                    return try .cometWithdraw(CometWithdrawActionContext(from: decoder))
                case MorphoVaultWithdrawActionContext.actionType:
                    return try .morphoVaultWithdraw(
                        MorphoVaultWithdrawActionContext(from: decoder)
                    )
                case WithdrawAndBorrowActionContext.actionType:
                    return try .withdrawAndBorrow(WithdrawAndBorrowActionContext(from: decoder))
                case RecurringSwapActionContext.actionType:
                    return try .recurringSwap(RecurringSwapActionContext(from: decoder))
                case QuotePayActionContext.actionType:
                    return try .quotePay(QuotePayActionContext(from: decoder))
                case WrapActionContext.actionType:
                    return try .wrap(WrapActionContext(from: decoder))
                case UnwrapActionContext.actionType:
                    return try .unwrap(UnwrapActionContext(from: decoder))
                case CometClaimRewardsActionContext.actionType:
                    return try .cometClaimRewards(CometClaimRewardsActionContext(from: decoder))
                case MorphoClaimRewardsActionContext.actionType:
                    return try .morphoClaimRewards(
                        MorphoClaimRewardsActionContext(from: decoder)
                    )
                case AddBackingTokenActionContext.actionType:
                    return try .addBackingToken(AddBackingTokenActionContext(from: decoder))
                case LoopLongActionContext.actionType:
                    return try .loopLong(LoopLongActionContext(from: decoder))
                case UnloopLongActionContext.actionType:
                    return try .unloopLong(UnloopLongActionContext(from: decoder))
                case LoopShortActionContext.actionType:
                    return try .loopShort(LoopShortActionContext(from: decoder))
                case UnloopShortActionContext.actionType:
                    return try .unloopShort(UnloopShortActionContext(from: decoder))
                case WithdrawBackingTokenActionContext.actionType:
                    return try .withdrawBackingToken(
                        WithdrawBackingTokenActionContext(from: decoder)
                    )
                default:
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    throw DecodingError.dataCorruptedError(
                        forKey: .actionType,
                        in: container,
                        debugDescription: "Unknown action type: \(actionType)"
                    )
            }
        }

        public static func decodeActionContext(from decoder: Decoder) throws -> ActionContext {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let actionType = try container.decode(String.self, forKey: .actionType)

            switch actionType {
                case "MULTI_ACTION":
                    // Try to decode from nested container first (when called from ActivityMetadata)
                    let multiContainer: KeyedDecodingContainer<MultiActionContext.CodingKeys>
                    if let nestedContainer = try? container.nestedContainer(
                        keyedBy: MultiActionContext.CodingKeys.self,
                        forKey: .actionContext
                    ) {
                        multiContainer = nestedContainer
                    } else {
                        // Fall back to root level (when decoding standalone ActionContext)
                        multiContainer = try decoder.container(
                            keyedBy: MultiActionContext.CodingKeys.self
                        )
                    }

                    let actionTypes = try multiContainer.decode(
                        [String].self,
                        forKey: .actionTypes
                    )
                    var contextsUnkeyed = try multiContainer.nestedUnkeyedContainer(
                        forKey: .actionContexts
                    )
                    var multiActions: [ActionContext] = []

                    for type in actionTypes {
                        // Gets a decoder for the next element in contextsUnkeyed
                        let singleDecoder = try contextsUnkeyed.superDecoder()
                        let action = try decodeBody(
                            from: singleDecoder,
                            actionType: type
                        )
                        multiActions.append(action)
                    }

                    return .multiAction(multiActions)
                default:
                    let actionDecoder: Decoder
                    if container.contains(.actionContext) {
                        actionDecoder = try container.superDecoder(forKey: .actionContext)
                    } else {
                        actionDecoder = decoder
                    }
                    return try decodeBody(
                        from: actionDecoder,
                        actionType: actionType
                    )
            }
        }

        public var actionType: String {
            switch self {
                case .transfer:
                    TransferActionContext.actionType
                case .bridge:
                    BridgeActionContext.actionType
                case .bridgeMint:
                    BridgeMintActionContext.actionType
                case .aaveSupply:
                    AaveSupplyActionContext.actionType
                case .aaveWithdraw:
                    AaveWithdrawActionContext.actionType
                case .cometSupply:
                    CometSupplyActionContext.actionType
                case .morphoVaultSupply:
                    MorphoVaultSupplyActionContext.actionType
                case .cometBorrow:
                    CometBorrowActionContext.actionType
                case .morphoBorrow:
                    MorphoBorrowActionContext.actionType
                case .cometRepay:
                    CometRepayActionContext.actionType
                case .morphoRepay:
                    MorphoRepayActionContext.actionType
                case .swap:
                    SwapActionContext.actionType
                case .cometClaimRewards:
                    CometClaimRewardsActionContext.actionType
                case .morphoClaimRewards:
                    MorphoClaimRewardsActionContext.actionType
                case .cometWithdraw:
                    CometWithdrawActionContext.actionType
                case .morphoVaultWithdraw:
                    MorphoVaultWithdrawActionContext.actionType
                case .withdrawAndBorrow:
                    WithdrawAndBorrowActionContext.actionType
                case .recurringSwap:
                    RecurringSwapActionContext.actionType
                case .quotePay:
                    QuotePayActionContext.actionType
                case .wrap:
                    WrapActionContext.actionType
                case .unwrap:
                    UnwrapActionContext.actionType
                case .loopLong:
                    LoopLongActionContext.actionType
                case .loopShort:
                    LoopShortActionContext.actionType
                case .unloopLong:
                    UnloopLongActionContext.actionType
                case .unloopShort:
                    UnloopShortActionContext.actionType
                case .addBackingToken:
                    AddBackingTokenActionContext.actionType
                case .withdrawBackingToken:
                    WithdrawBackingTokenActionContext.actionType
                case .multiAction:
                    MultiActionContext.actionType
            }
        }

        public struct CometBorrowActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_COMET_BORROW

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let collateralAmounts: [Number]
            public let collateralAssetSymbols: [String]
            public let collateralTokenPrices: [Number]
            public let collateralTokens: [EthAddress]
            public let comet: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case collateralAmounts = "collateral_amounts"
                case collateralAssetSymbols = "collateral_asset_symbols"
                case collateralTokenPrices = "collateral_token_prices"
                case collateralTokens = "collateral_tokens"
                case comet
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                collateralAmounts: [Number],
                collateralAssetSymbols: [String],
                collateralTokenPrices: [Number],
                collateralTokens: [EthAddress],
                comet: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.collateralAmounts = collateralAmounts
                self.collateralAssetSymbols = collateralAssetSymbols
                self.collateralTokenPrices = collateralTokenPrices
                self.collateralTokens = collateralTokens
                self.comet = comet
                self.price = price
                self.token = token
            }

            public static func fromBorrowActionContext(_ context: Actions.BorrowActionContext)
                -> CometBorrowActionContext
            {
                return CometBorrowActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    collateralAmounts: context.collateralAmounts,
                    collateralAssetSymbols: context.collateralAssetSymbols,
                    collateralTokenPrices: context.collateralTokenPrices,
                    collateralTokens: context.collateralTokens,
                    comet: context.comet,
                    price: context.price,
                    token: context.token
                )
            }
        }

        public struct MorphoBorrowActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_MORPHO_BORROW

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let collateralAmount: Number
            public let collateralAssetSymbol: String
            public let collateralTokenPrice: Number
            public let collateralToken: EthAddress
            public let morpho: EthAddress
            public let morphoMarketId: Hex
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case collateralAmount = "collateral_amount"
                case collateralAssetSymbol = "collateral_asset_symbol"
                case collateralTokenPrice = "collateral_token_price"
                case collateralToken = "collateral_token"
                case morpho
                case morphoMarketId = "morpho_market_id"
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                collateralAmount: Number,
                collateralAssetSymbol: String,
                collateralTokenPrice: Number,
                collateralToken: EthAddress,
                morpho: EthAddress,
                morphoMarketId: Hex,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.collateralAmount = collateralAmount
                self.collateralAssetSymbol = collateralAssetSymbol
                self.collateralTokenPrice = collateralTokenPrice
                self.collateralToken = collateralToken
                self.morpho = morpho
                self.morphoMarketId = morphoMarketId
                self.price = price
                self.token = token
            }

            public static func fromMorphoBorrowActionContext(
                _ context: Actions.MorphoBorrowActionContext
            )
                -> MorphoBorrowActionContext
            {
                return MorphoBorrowActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    collateralAmount: context.collateralAmount,
                    collateralAssetSymbol: context.collateralAssetSymbol,
                    collateralTokenPrice: context.collateralTokenPrice,
                    collateralToken: context.collateralToken,
                    morpho: context.morpho,
                    morphoMarketId: context.morphoMarketId,
                    price: context.price,
                    token: context.token
                )
            }
        }

        public struct BridgeActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_BRIDGE

            public enum BridgeType: Codable, Equatable, Hashable, Sendable {
                case across
                case cctpV1
                case cctpV2
                case unknown(String)

                var rawValue: String {
                    switch self {
                        case .across: return BridgeType.ACROSS
                        case .cctpV1: return BridgeType.CCTP_V1
                        case .cctpV2: return BridgeType.CCTP_V2
                        case .unknown(let value): return value
                    }
                }

                public init(rawValue: String) {
                    switch rawValue {
                        case BridgeType.ACROSS:
                            self = .across
                        case BridgeType.CCTP_V1:
                            self = .cctpV1
                        case BridgeType.CCTP_V2:
                            self = .cctpV2
                        default:
                            self = .unknown(rawValue)
                    }
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = BridgeType(rawValue: rawValue)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(rawValue)
                }

                static let ACROSS = "ACROSS"
                static let CCTP_V1 = "CCTP_V1"
                static let CCTP_V2 = "CCTP_V2"
            }

            public let assetSymbol: String
            public let bridgeType: BridgeType
            public let chainId: Number
            public let destinationChainId: Number
            public let destinationAssetSymbol: String
            public let inputAmount: Number
            public let outputAmount: Number
            public let price: Number
            public let recipient: EthAddress
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case assetSymbol = "asset_symbol"
                case bridgeType = "bridge_type"
                case chainId = "chain_id"
                case destinationChainId = "destination_chain_id"
                case destinationAssetSymbol = "destination_asset_symbol"
                case inputAmount = "input_amount"
                case outputAmount = "output_amount"
                case price
                case recipient
                case token
            }

            public init(
                assetSymbol: String,
                bridgeType: BridgeType,
                chainId: Number,
                destinationChainId: Number,
                destinationAssetSymbol: String,
                inputAmount: Number,
                outputAmount: Number,
                price: Number,
                recipient: EthAddress,
                token: EthAddress
            ) {
                self.assetSymbol = assetSymbol
                self.bridgeType = bridgeType
                self.chainId = chainId
                self.destinationChainId = destinationChainId
                self.destinationAssetSymbol = destinationAssetSymbol
                self.inputAmount = inputAmount
                self.outputAmount = outputAmount
                self.price = price
                self.recipient = recipient
                self.token = token
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.assetSymbol = try container.decode(String.self, forKey: .assetSymbol)
                self.bridgeType = try container.decode(BridgeType.self, forKey: .bridgeType)
                self.chainId = try container.decode(Number.self, forKey: .chainId)
                self.destinationChainId = try container.decode(
                    Number.self,
                    forKey: .destinationChainId
                )
                self.destinationAssetSymbol =
                    try container.decodeIfPresent(String.self, forKey: .destinationAssetSymbol)
                    ?? (self.assetSymbol == "WETH" ? "ETH" : self.assetSymbol)
                self.inputAmount = try container.decode(Number.self, forKey: .inputAmount)
                self.outputAmount = try container.decode(Number.self, forKey: .outputAmount)
                self.price = try container.decode(Number.self, forKey: .price)
                self.recipient = try container.decode(EthAddress.self, forKey: .recipient)
                self.token = try container.decode(EthAddress.self, forKey: .token)
            }

            public static func fromBridgeActionContext(_ context: Actions.BridgeActionContext)
                -> BridgeActionContext
            {
                return BridgeActionContext(
                    assetSymbol: context.assetSymbol,
                    bridgeType: BridgeType(rawValue: context.bridgeType),
                    chainId: context.chainId,
                    destinationChainId: context.destinationChainId,
                    destinationAssetSymbol: context.assetSymbol == "WETH"
                        ? "ETH" : context.assetSymbol,
                    inputAmount: context.inputAmount,
                    outputAmount: context.outputAmount,
                    price: context.price,
                    recipient: context.recipient,
                    token: context.token
                )
            }
        }

        public struct BridgeMintActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_BRIDGE_MINT

            public let assetSymbol: String
            public let bridgeType: BridgeActionContext.BridgeType
            public let chainId: Number  // destination chain ID
            public let sourceChainId: Number
            public let inputAmount: Number
            // outputAmount: Useful to be attached for Portfolio Patching calculation
            public let outputAmount: Number  // inputAmount - maxFee
            public let maxFee: Number
            public let recipient: EthAddress
            public let token: EthAddress  // The token address on destination chain

            public enum CodingKeys: String, CodingKey {
                case assetSymbol = "asset_symbol"
                case bridgeType = "bridge_type"
                case chainId = "chain_id"
                case sourceChainId = "source_chain_id"
                case inputAmount = "input_amount"
                case outputAmount = "output_amount"
                case maxFee = "max_fee"
                case recipient
                case token
            }

            public init(
                assetSymbol: String,
                bridgeType: BridgeActionContext.BridgeType,
                chainId: Number,
                sourceChainId: Number,
                inputAmount: Number,
                outputAmount: Number,
                maxFee: Number,
                recipient: EthAddress,
                token: EthAddress
            ) {
                self.assetSymbol = assetSymbol
                self.bridgeType = bridgeType
                self.chainId = chainId
                self.sourceChainId = sourceChainId
                self.inputAmount = inputAmount
                self.outputAmount = outputAmount
                self.maxFee = maxFee
                self.recipient = recipient
                self.token = token
            }
        }

        // ---

        public struct CometRepayActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_COMET_REPAY

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let collateralAmounts: [Number]
            public let collateralAssetSymbols: [String]
            public let collateralTokenPrices: [Number]
            public let collateralTokens: [EthAddress]
            public let comet: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case collateralAmounts = "collateral_amounts"
                case collateralAssetSymbols = "collateral_asset_symbols"
                case collateralTokenPrices = "collateral_token_prices"
                case collateralTokens = "collateral_tokens"
                case comet
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                collateralAmounts: [Number],
                collateralAssetSymbols: [String],
                collateralTokenPrices: [Number],
                collateralTokens: [EthAddress],
                comet: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.collateralAmounts = collateralAmounts
                self.collateralAssetSymbols = collateralAssetSymbols
                self.collateralTokenPrices = collateralTokenPrices
                self.collateralTokens = collateralTokens
                self.comet = comet
                self.price = price
                self.token = token
            }

            public static func fromRepayActionContext(_ context: Actions.RepayActionContext)
                -> CometRepayActionContext
            {
                return CometRepayActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    collateralAmounts: context.collateralAmounts,
                    collateralAssetSymbols: context.collateralAssetSymbols,
                    collateralTokenPrices: context.collateralTokenPrices,
                    collateralTokens: context.collateralTokens,
                    comet: context.comet,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct MorphoRepayActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_MORPHO_REPAY

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let collateralAmount: Number
            public let collateralAssetSymbol: String
            public let collateralTokenPrice: Number
            public let collateralToken: EthAddress
            public let morpho: EthAddress
            public let morphoMarketId: Hex
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case collateralAmount = "collateral_amount"
                case collateralAssetSymbol = "collateral_asset_symbol"
                case collateralTokenPrice = "collateral_token_price"
                case collateralToken = "collateral_token"
                case morpho
                case morphoMarketId = "morpho_market_id"
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                collateralAmount: Number,
                collateralAssetSymbol: String,
                collateralTokenPrice: Number,
                collateralToken: EthAddress,
                morpho: EthAddress,
                morphoMarketId: Hex,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.collateralAmount = collateralAmount
                self.collateralAssetSymbol = collateralAssetSymbol
                self.collateralTokenPrice = collateralTokenPrice
                self.collateralToken = collateralToken
                self.morpho = morpho
                self.morphoMarketId = morphoMarketId
                self.price = price
                self.token = token
            }

            public static func fromMorphoRepayActionContext(
                _ context: Actions.MorphoRepayActionContext
            )
                -> MorphoRepayActionContext
            {
                return MorphoRepayActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    collateralAmount: context.collateralAmount,
                    collateralAssetSymbol: context.collateralAssetSymbol,
                    collateralTokenPrice: context.collateralTokenPrice,
                    collateralToken: context.collateralToken,
                    morpho: context.morpho,
                    morphoMarketId: context.morphoMarketId,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct AaveSupplyActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_AAVE_SUPPLY

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let aavePool: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case aavePool = "aave_pool"
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                aavePool: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.aavePool = aavePool
                self.price = price
                self.token = token
            }

            public static func fromAaveSupplyActionContext(
                _ context: Actions.AaveSupplyActionContext
            )
                -> AaveSupplyActionContext
            {
                return AaveSupplyActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    aavePool: context.aavePool,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct CometSupplyActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_COMET_SUPPLY

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let comet: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case comet
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                comet: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.comet = comet
                self.price = price
                self.token = token
            }

            public static func fromCometSupplyActionContext(
                _ context: Actions.CometSupplyActionContext
            )
                -> CometSupplyActionContext
            {
                return CometSupplyActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    comet: context.comet,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct MorphoVaultSupplyActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_MORPHO_VAULT_SUPPLY

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let morphoVault: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case morphoVault = "morpho_vault"
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                morphoVault: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.morphoVault = morphoVault
                self.price = price
                self.token = token
            }

            public static func fromMorphoVaultSupplyActionContext(
                _ context: Actions.MorphoVaultSupplyActionContext
            ) -> MorphoVaultSupplyActionContext {
                return MorphoVaultSupplyActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    morphoVault: context.morphoVault,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct SwapActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_SWAP

            public let chainId: Number
            public let feeAmounts: [Number]
            public let feeAssetSymbols: [String]
            public let feeTokens: [EthAddress]
            public let feeTokenPrices: [Number]
            public let feeDescriptions: [String]
            public let inputAmount: Number
            public let inputAssetSymbol: String
            public let inputToken: EthAddress
            public let inputTokenPrice: Number
            public let outputAmount: Number
            public let outputAssetSymbol: String
            public let outputToken: EthAddress
            public let outputTokenPrice: Number
            public let isExactOut: Bool
            public let isBuy: Bool
            public let isCappedMax: Bool
            public let useFiller: Bool

            public enum CodingKeys: String, CodingKey {
                case chainId = "chain_id"
                case feeAmounts = "fee_amounts"
                case feeAssetSymbols = "fee_asset_symbols"
                case feeTokens = "fee_tokens"
                case feeTokenPrices = "fee_token_prices"
                case feeDescriptions = "fee_descriptions"
                case inputAmount = "input_amount"
                case inputAssetSymbol = "input_asset_symbol"
                case inputToken = "input_token"
                case inputTokenPrice = "input_token_price"
                case outputAmount = "output_amount"
                case outputAssetSymbol = "output_asset_symbol"
                case outputToken = "output_token"
                case outputTokenPrice = "output_token_price"
                case isExactOut = "is_exact_out"
                case isBuy = "is_buy"
                case isCappedMax = "is_capped_max"
                case useFiller = "use_filler"
            }

            // Separate enum for old keys used only in decoding
            private enum LegacyCodingKeys: String, CodingKey {
                case feeAmount = "fee_amount"
                case feeAssetSymbol = "fee_asset_symbol"
                case feeToken = "fee_token"
                case feeTokenPrice = "fee_token_price"
            }

            public init(
                chainId: Number,
                feeAmounts: [Number],
                feeAssetSymbols: [String],
                feeTokens: [EthAddress],
                feeTokenPrices: [Number],
                feeDescriptions: [String],
                inputAmount: Number,
                inputAssetSymbol: String,
                inputToken: EthAddress,
                inputTokenPrice: Number,
                outputAmount: Number,
                outputAssetSymbol: String,
                outputToken: EthAddress,
                outputTokenPrice: Number,
                isExactOut: Bool,
                isBuy: Bool,
                isCappedMax: Bool,
                useFiller: Bool
            ) {
                self.chainId = chainId
                self.feeAmounts = feeAmounts
                self.feeAssetSymbols = feeAssetSymbols
                self.feeTokens = feeTokens
                self.feeTokenPrices = feeTokenPrices
                self.feeDescriptions = feeDescriptions
                self.inputAmount = inputAmount
                self.inputAssetSymbol = inputAssetSymbol
                self.inputToken = inputToken
                self.inputTokenPrice = inputTokenPrice
                self.outputAmount = outputAmount
                self.outputAssetSymbol = outputAssetSymbol
                self.outputToken = outputToken
                self.outputTokenPrice = outputTokenPrice
                self.isExactOut = isExactOut
                self.isBuy = isBuy
                self.isCappedMax = isCappedMax
                self.useFiller = useFiller
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                // Decode fields that haven't changed
                chainId = try container.decode(Number.self, forKey: .chainId)
                inputAmount = try container.decode(Number.self, forKey: .inputAmount)
                inputAssetSymbol = try container.decode(String.self, forKey: .inputAssetSymbol)
                inputToken = try container.decode(EthAddress.self, forKey: .inputToken)
                inputTokenPrice = try container.decode(Number.self, forKey: .inputTokenPrice)
                outputAmount = try container.decode(Number.self, forKey: .outputAmount)
                outputAssetSymbol = try container.decode(String.self, forKey: .outputAssetSymbol)
                outputToken = try container.decode(EthAddress.self, forKey: .outputToken)
                outputTokenPrice = try container.decode(Number.self, forKey: .outputTokenPrice)
                isExactOut = try container.decode(Bool.self, forKey: .isExactOut)
                // Handle is_buy as optional - if not present, determine from input_asset_symbol
                isBuy =
                    try container.decodeIfPresent(Bool.self, forKey: .isBuy)
                    ?? (inputAssetSymbol == "USDC")
                isCappedMax =
                    try container.decodeIfPresent(Bool.self, forKey: .isCappedMax) ?? false
                useFiller = try container.decodeIfPresent(Bool.self, forKey: .useFiller) ?? false

                // Handle backward compatibility for fee fields
                // Try to decode as arrays first (new format)
                if let amounts = try? container.decode([Number].self, forKey: .feeAmounts) {
                    feeAmounts = amounts
                    feeAssetSymbols = try container.decode([String].self, forKey: .feeAssetSymbols)
                    feeTokens = try container.decode([EthAddress].self, forKey: .feeTokens)
                    feeTokenPrices = try container.decode([Number].self, forKey: .feeTokenPrices)
                    feeDescriptions =
                        try container.decodeIfPresent([String].self, forKey: .feeDescriptions) ?? []
                } else {
                    // Fall back to singular fields (old format)
                    let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)

                    // Fee fields are optional - if not present, default to empty arrays
                    if let singleAmount = try legacyContainer.decodeIfPresent(
                        Number.self,
                        forKey: .feeAmount
                    ) {
                        let singleSymbol = try legacyContainer.decode(
                            String.self,
                            forKey: .feeAssetSymbol
                        )
                        let singleToken = try legacyContainer.decode(
                            EthAddress.self,
                            forKey: .feeToken
                        )
                        let singlePrice = try legacyContainer.decode(
                            Number.self,
                            forKey: .feeTokenPrice
                        )

                        // Convert to arrays
                        feeAmounts = [singleAmount]
                        feeAssetSymbols = [singleSymbol]
                        feeTokens = [singleToken]
                        feeTokenPrices = [singlePrice]
                        feeDescriptions = ["ZERO_EX"]
                    } else {
                        // No fee fields present - default to empty arrays
                        feeAmounts = []
                        feeAssetSymbols = []
                        feeTokens = []
                        feeTokenPrices = []
                        feeDescriptions = []
                    }
                }
            }

            public static func fromSwapActionContext(_ context: Actions.SwapActionContext)
                -> SwapActionContext
            {
                return SwapActionContext(
                    chainId: context.chainId,
                    feeAmounts: context.feeAmounts,
                    feeAssetSymbols: context.feeAssetSymbols,
                    feeTokens: context.feeTokens,
                    feeTokenPrices: context.feeTokenPrices,
                    feeDescriptions: context.feeDescriptions,
                    inputAmount: context.inputAmount,
                    inputAssetSymbol: context.inputAssetSymbol,
                    inputToken: context.inputToken,
                    inputTokenPrice: context.inputTokenPrice,
                    outputAmount: context.outputAmount,
                    outputAssetSymbol: context.outputAssetSymbol,
                    outputToken: context.outputToken,
                    outputTokenPrice: context.outputTokenPrice,
                    isExactOut: context.isExactOut,
                    isBuy: context.isBuy,
                    isCappedMax: context.isCappedMax,
                    useFiller: context.useFiller
                )
            }
        }

        // ---

        public struct TransferActionContext: Codable, Equatable, Hashable, Sendable {
            static let actionType: String = Charter.ACTION_TYPE_TRANSFER

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let price: Number
            public let recipient: EthAddress
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case price
                case recipient
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                price: Number,
                recipient: EthAddress,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.price = price
                self.recipient = recipient
                self.token = token
            }

            public static func fromTransferActionContext(_ context: Actions.TransferActionContext)
                -> TransferActionContext
            {
                return TransferActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    price: context.price,
                    recipient: context.recipient,
                    token: context.token
                )
            }
        }

        // ---

        public struct AaveWithdrawActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_AAVE_WITHDRAW

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let aavePool: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case aavePool = "aave_pool"
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                aavePool: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.aavePool = aavePool
                self.price = price
                self.token = token
            }

            public static func fromAaveWithdrawActionContext(
                _ context: Actions.AaveWithdrawActionContext
            )
                -> AaveWithdrawActionContext
            {
                return AaveWithdrawActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    aavePool: context.aavePool,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct CometWithdrawActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_COMET_WITHDRAW

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let comet: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case comet
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                comet: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.comet = comet
                self.price = price
                self.token = token
            }

            public static func fromCometWithdrawActionContext(
                _ context: Actions.CometWithdrawActionContext
            )
                -> CometWithdrawActionContext
            {
                return CometWithdrawActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    comet: context.comet,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct MorphoVaultWithdrawActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_MORPHO_VAULT_WITHDRAW

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let morphoVault: EthAddress
            public let price: Number
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case morphoVault = "morpho_vault"
                case price
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                morphoVault: EthAddress,
                price: Number,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.morphoVault = morphoVault
                self.price = price
                self.token = token
            }

            public static func fromMorphoVaultWithdrawActionContext(
                _ context: Actions.MorphoVaultWithdrawActionContext
            ) -> MorphoVaultWithdrawActionContext {
                return MorphoVaultWithdrawActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    morphoVault: context.morphoVault,
                    price: context.price,
                    token: context.token
                )
            }
        }

        // ---

        public struct WithdrawAndBorrowActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_WITHDRAW_AND_BORROW

            public let borrowAmount: Number
            public let chainId: Number
            public let collateralAmounts: [Number]
            public let collateralTokenPrices: [Number]
            public let collateralTokens: [EthAddress]
            public let comet: EthAddress
            public let price: Number
            public let token: EthAddress
            public let withdrawAmount: Number

            public enum CodingKeys: String, CodingKey {
                case borrowAmount = "borrow_amount"
                case chainId = "chain_id"
                case collateralAmounts = "collateral_amounts"
                case collateralTokenPrices = "collateral_token_prices"
                case collateralTokens = "collateral_tokens"
                case comet
                case price
                case token
                case withdrawAmount = "withdraw_amount"
            }

            public init(
                borrowAmount: Number,
                chainId: Number,
                collateralAmounts: [Number],
                collateralTokenPrices: [Number],
                collateralTokens: [EthAddress],
                comet: EthAddress,
                price: Number,
                token: EthAddress,
                withdrawAmount: Number
            ) {
                self.borrowAmount = borrowAmount
                self.chainId = chainId
                self.collateralAmounts = collateralAmounts
                self.collateralTokenPrices = collateralTokenPrices
                self.collateralTokens = collateralTokens
                self.comet = comet
                self.price = price
                self.token = token
                self.withdrawAmount = withdrawAmount
            }

            public static func fromWithdrawAndBorrowActionContext(
                _ context: Actions.WithdrawAndBorrowActionContext
            ) -> WithdrawAndBorrowActionContext {
                return WithdrawAndBorrowActionContext(
                    borrowAmount: context.borrowAmount,
                    chainId: context.chainId,
                    collateralAmounts: context.collateralAmounts,
                    collateralTokenPrices: context.collateralTokenPrices,
                    collateralTokens: context.collateralTokens,
                    comet: context.comet,
                    price: context.price,
                    token: context.token,
                    withdrawAmount: context.withdrawAmount
                )
            }
        }

        // ---

        public struct RecurringSwapActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_RECURRING_SWAP

            public let chainId: Number
            public let inputAmount: Number
            public let inputAssetSymbol: String
            public let inputToken: EthAddress
            public let inputTokenPrice: Number
            public let outputAmount: Number
            public let outputAssetSymbol: String
            public let outputToken: EthAddress
            public let outputTokenPrice: Number
            public let isExactOut: Bool
            public let interval: Number

            public enum CodingKeys: String, CodingKey {
                case chainId = "chain_id"
                case inputAmount = "input_amount"
                case inputAssetSymbol = "input_asset_symbol"
                case inputToken = "input_token"
                case inputTokenPrice = "input_token_price"
                case outputAmount = "output_amount"
                case outputAssetSymbol = "output_asset_symbol"
                case outputToken = "output_token"
                case outputTokenPrice = "output_token_price"
                case isExactOut = "is_exact_out"
                case interval
            }

            public init(
                chainId: Number,
                inputAmount: Number,
                inputAssetSymbol: String,
                inputToken: EthAddress,
                inputTokenPrice: Number,
                outputAmount: Number,
                outputAssetSymbol: String,
                outputToken: EthAddress,
                outputTokenPrice: Number,
                isExactOut: Bool,
                interval: Number
            ) {
                self.chainId = chainId
                self.inputAmount = inputAmount
                self.inputAssetSymbol = inputAssetSymbol
                self.inputToken = inputToken
                self.inputTokenPrice = inputTokenPrice
                self.outputAmount = outputAmount
                self.outputAssetSymbol = outputAssetSymbol
                self.outputToken = outputToken
                self.outputTokenPrice = outputTokenPrice
                self.isExactOut = isExactOut
                self.interval = interval
            }

            public static func fromRecurringSwapActionContext(
                _ context: Actions.RecurringSwapActionContext
            )
                -> RecurringSwapActionContext
            {
                return RecurringSwapActionContext(
                    chainId: context.chainId,
                    inputAmount: context.inputAmount,
                    inputAssetSymbol: context.inputAssetSymbol,
                    inputToken: context.inputToken,
                    inputTokenPrice: context.inputTokenPrice,
                    // TODO: THIS IS STILL BEING WORKED ON
                    outputAmount: .zero,
                    outputAssetSymbol: context.outputAssetSymbol,
                    outputToken: context.outputToken,
                    outputTokenPrice: context.outputTokenPrice,
                    // TODO: THIS IS STILL BEING WORKED ON
                    isExactOut: false,
                    interval: context.interval
                )
            }
        }

        // ---

        public struct QuotePayActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_QUOTE_PAY

            public let amount: Number
            public let assetSymbol: String
            public let chainId: Number
            public let price: Number
            public let payee: EthAddress
            public let quoteId: Hex
            public let token: EthAddress

            public enum CodingKeys: String, CodingKey {
                case amount
                case assetSymbol = "asset_symbol"
                case chainId = "chain_id"
                case price
                case payee
                case quoteId = "quote_id"
                case token
            }

            public init(
                amount: Number,
                assetSymbol: String,
                chainId: Number,
                price: Number,
                payee: EthAddress,
                quoteId: Hex,
                token: EthAddress
            ) {
                self.amount = amount
                self.assetSymbol = assetSymbol
                self.chainId = chainId
                self.price = price
                self.payee = payee
                self.quoteId = quoteId
                self.token = token
            }

            public static func fromQuotePayActionContext(_ context: Actions.QuotePayActionContext)
                -> QuotePayActionContext
            {
                return QuotePayActionContext(
                    amount: context.amount,
                    assetSymbol: context.assetSymbol,
                    chainId: context.chainId,
                    price: context.price,
                    payee: context.payee,
                    quoteId: context.quoteId,
                    token: context.token
                )
            }
        }

        // ---

        public struct WrapActionContext: Codable, Equatable, Hashable, Sendable {
            static let actionType = Charter.ACTION_TYPE_WRAP

            public let chainId: Number
            public let amount: Number
            public let token: EthAddress
            public let fromAssetSymbol: String
            public let toAssetSymbol: String

            public enum CodingKeys: String, CodingKey {
                case chainId = "chain_id"
                case amount
                case token
                case fromAssetSymbol = "from_asset_symbol"
                case toAssetSymbol = "to_asset_symbol"
            }

            public init(
                chainId: Number,
                amount: Number,
                token: EthAddress,
                fromAssetSymbol: String,
                toAssetSymbol: String
            ) {
                self.chainId = chainId
                self.amount = amount
                self.token = token
                self.fromAssetSymbol = fromAssetSymbol
                self.toAssetSymbol = toAssetSymbol
            }

            public static func fromWrapOrUnwrapActionContext(
                _ context: Actions.WrapOrUnwrapActionContext
            )
                -> WrapActionContext
            {
                return WrapActionContext(
                    chainId: context.chainId,
                    amount: context.amount,
                    token: context.token,
                    fromAssetSymbol: context.fromAssetSymbol,
                    toAssetSymbol: context.toAssetSymbol
                )
            }
        }

        public struct UnwrapActionContext: Codable, Equatable, Hashable, Sendable {
            static let actionType = Charter.ACTION_TYPE_UNWRAP

            public let chainId: Number
            public let amount: Number
            public let token: EthAddress
            public let fromAssetSymbol: String
            public let toAssetSymbol: String

            public enum CodingKeys: String, CodingKey {
                case chainId = "chain_id"
                case amount
                case token
                case fromAssetSymbol = "from_asset_symbol"
                case toAssetSymbol = "to_asset_symbol"
            }

            public init(
                chainId: Number,
                amount: Number,
                token: EthAddress,
                fromAssetSymbol: String,
                toAssetSymbol: String
            ) {
                self.chainId = chainId
                self.amount = amount
                self.token = token
                self.fromAssetSymbol = fromAssetSymbol
                self.toAssetSymbol = toAssetSymbol
            }

            public static func fromWrapOrUnwrapActionContext(
                _ context: Actions.WrapOrUnwrapActionContext
            )
                -> UnwrapActionContext
            {
                return UnwrapActionContext(
                    chainId: context.chainId,
                    amount: context.amount,
                    token: context.token,
                    fromAssetSymbol: context.fromAssetSymbol,
                    toAssetSymbol: context.toAssetSymbol
                )
            }
        }

        // ---

        public struct CometClaimRewardsActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_COMET_CLAIM_REWARDS

            public let amounts: [Number]
            public let assetSymbols: [String]
            public let chainId: Number
            public let prices: [Number]
            public let tokens: [EthAddress]

            public enum CodingKeys: String, CodingKey {
                case amounts
                case assetSymbols = "asset_symbols"
                case chainId = "chain_id"
                case prices
                case tokens
            }

            public init(
                amounts: [Number],
                assetSymbols: [String],
                chainId: Number,
                prices: [Number],
                tokens: [EthAddress]
            ) {
                self.amounts = amounts
                self.assetSymbols = assetSymbols
                self.chainId = chainId
                self.prices = prices
                self.tokens = tokens
            }

            public static func fromCometClaimRewardsActionContext(
                _ context: Actions.CometClaimRewardsActionContext
            ) -> CometClaimRewardsActionContext {
                return CometClaimRewardsActionContext(
                    amounts: context.amounts,
                    assetSymbols: context.assetSymbols,
                    chainId: context.chainId,
                    prices: context.prices,
                    tokens: context.tokens
                )
            }
        }

        public struct MultiActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_MULTI_ACTION

            public let actionTypes: [String]
            public let actionContexts: [ActionContext]

            public enum CodingKeys: String, CodingKey {
                case actionTypes = "action_types"
                case actionContexts = "action_contexts"
            }

            public init(actionTypes: [String], actionContexts: [ActionContext]) {
                self.actionTypes = actionTypes
                self.actionContexts = actionContexts
            }
        }

        // ---

        public struct MorphoClaimRewardsActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_MORPHO_CLAIM_REWARDS

            public let amounts: [Number]
            public let assetSymbols: [String]
            public let chainId: Number
            public let prices: [Number]
            public let tokens: [EthAddress]

            public enum CodingKeys: String, CodingKey {
                case amounts
                case assetSymbols = "asset_symbols"
                case chainId = "chain_id"
                case prices
                case tokens
            }

            public init(
                amounts: [Number],
                assetSymbols: [String],
                chainId: Number,
                prices: [Number],
                tokens: [EthAddress]
            ) {
                self.amounts = amounts
                self.assetSymbols = assetSymbols
                self.chainId = chainId
                self.prices = prices
                self.tokens = tokens
            }

            public static func fromMorphoClaimRewardsActionContext(
                _ context: Actions.MorphoClaimRewardsActionContext
            ) -> MorphoClaimRewardsActionContext {
                return MorphoClaimRewardsActionContext(
                    amounts: context.amounts,
                    assetSymbols: context.assetSymbols,
                    chainId: context.chainId,
                    prices: context.prices,
                    tokens: context.tokens
                )
            }
        }

        // ---

        public struct AddBackingTokenActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_ADD_BACKING_TOKEN

            public let amount: Number
            public let backingAssetSymbol: String
            public let backingToken: EthAddress
            public let backingTokenPrice: Number
            public let chainId: Number
            public let exposureAssetSymbol: String
            public let exposureToken: EthAddress
            public let exposureTokenPrice: Number
            public let borrowVenue: String
            public let borrowMarketId: Hex
            public let isShort: Bool

            public enum CodingKeys: String, CodingKey {
                case amount
                case backingAssetSymbol = "backing_asset_symbol"
                case backingToken = "backing_token"
                case backingTokenPrice = "backing_token_price"
                case chainId = "chain_id"
                case exposureAssetSymbol = "exposure_asset_symbol"
                case exposureToken = "exposure_token"
                case exposureTokenPrice = "exposure_token_price"
                case borrowVenue = "borrow_venue"
                case borrowMarketId = "borrow_market_id"
                case isShort = "is_short"
            }

            public init(
                amount: Number,
                backingAssetSymbol: String,
                backingToken: EthAddress,
                backingTokenPrice: Number,
                chainId: Number,
                exposureAssetSymbol: String,
                exposureToken: EthAddress,
                exposureTokenPrice: Number,
                borrowVenue: String,
                borrowMarketId: Hex,
                isShort: Bool
            ) {
                self.amount = amount
                self.backingAssetSymbol = backingAssetSymbol
                self.backingToken = backingToken
                self.backingTokenPrice = backingTokenPrice
                self.chainId = chainId
                self.exposureAssetSymbol = exposureAssetSymbol
                self.exposureToken = exposureToken
                self.exposureTokenPrice = exposureTokenPrice
                self.borrowVenue = borrowVenue
                self.borrowMarketId = borrowMarketId
                self.isShort = isShort
            }

            public static func fromAddBackingTokenActionContext(
                _ context: Actions.AddBackingTokenActionContext
            )
                -> AddBackingTokenActionContext
            {
                return AddBackingTokenActionContext(
                    amount: context.amount,
                    backingAssetSymbol: context.backingAssetSymbol,
                    backingToken: context.backingToken,
                    backingTokenPrice: context.backingTokenPrice,
                    chainId: context.chainId,
                    exposureAssetSymbol: context.exposureAssetSymbol,
                    exposureToken: context.exposureToken,
                    exposureTokenPrice: context.exposureTokenPrice,
                    borrowVenue: context.borrowVenue,
                    borrowMarketId: context.borrowMarketId,
                    isShort: context.isShort,
                )
            }
        }

        // ---

        public struct LoopLongActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_LOOP_LONG

            public let backingAssetSymbol: String
            public let backingToken: EthAddress
            public let backingTokenPrice: Number
            public let maxSwapBackingAmount: Number
            public let maxProvidedBackingAmount: Number
            public let chainId: Number
            public let isIncrease: Bool
            public let exposureAmount: Number
            public let exposureAssetSymbol: String
            public let exposureToken: EthAddress
            public let exposureTokenPrice: Number
            public let swapVenue: String
            public let borrowVenue: String
            public let borrowMarketId: Hex
            public let feeAmount: Number
            public let feeAssetSymbol: String
            public let feeToken: EthAddress
            public let feeTokenPrice: Number

            public enum CodingKeys: String, CodingKey {
                case backingAssetSymbol = "backing_asset_symbol"
                case backingToken = "backing_token"
                case backingTokenPrice = "backing_token_price"
                case maxSwapBackingAmount = "max_swap_backing_amount"
                case maxProvidedBackingAmount = "max_provided_backing_amount"
                case chainId = "chain_id"
                case isIncrease = "is_increase"
                case exposureAmount = "exposure_amount"
                case exposureAssetSymbol = "exposure_asset_symbol"
                case exposureToken = "exposure_token"
                case exposureTokenPrice = "exposure_token_price"
                case swapVenue = "swap_venue"
                case borrowVenue = "borrow_venue"
                case borrowMarketId = "borrow_market_id"
                case feeAmount = "fee_amount"
                case feeAssetSymbol = "fee_asset_symbol"
                case feeToken = "fee_token"
                case feeTokenPrice = "fee_token_price"
            }

            public init(
                backingAssetSymbol: String,
                backingToken: EthAddress,
                backingTokenPrice: Number,
                maxSwapBackingAmount: Number,
                maxProvidedBackingAmount: Number,
                chainId: Number,
                isIncrease: Bool,
                exposureAmount: Number,
                exposureAssetSymbol: String,
                exposureToken: EthAddress,
                exposureTokenPrice: Number,
                swapVenue: String,
                borrowVenue: String,
                borrowMarketId: Hex,
                feeAmount: Number,
                feeAssetSymbol: String,
                feeToken: EthAddress,
                feeTokenPrice: Number
            ) {
                self.backingAssetSymbol = backingAssetSymbol
                self.backingToken = backingToken
                self.backingTokenPrice = backingTokenPrice
                self.maxSwapBackingAmount = maxSwapBackingAmount
                self.maxProvidedBackingAmount = maxProvidedBackingAmount
                self.chainId = chainId
                self.isIncrease = isIncrease
                self.exposureAmount = exposureAmount
                self.exposureAssetSymbol = exposureAssetSymbol
                self.exposureToken = exposureToken
                self.exposureTokenPrice = exposureTokenPrice
                self.swapVenue = swapVenue
                self.borrowVenue = borrowVenue
                self.borrowMarketId = borrowMarketId
                self.feeAmount = feeAmount
                self.feeAssetSymbol = feeAssetSymbol
                self.feeToken = feeToken
                self.feeTokenPrice = feeTokenPrice
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(backingAssetSymbol, forKey: .backingAssetSymbol)
                try container.encode(backingToken.description, forKey: .backingToken)
                try container.encode(backingTokenPrice.description, forKey: .backingTokenPrice)
                try container.encode(
                    maxSwapBackingAmount.description,
                    forKey: .maxSwapBackingAmount
                )
                try container.encode(
                    maxProvidedBackingAmount.description,
                    forKey: .maxProvidedBackingAmount
                )
                try container.encode(chainId.description, forKey: .chainId)
                try container.encode(isIncrease, forKey: .isIncrease)
                try container.encode(exposureAmount.description, forKey: .exposureAmount)
                try container.encode(exposureAssetSymbol, forKey: .exposureAssetSymbol)
                try container.encode(exposureToken.description, forKey: .exposureToken)
                try container.encode(exposureTokenPrice.description, forKey: .exposureTokenPrice)
                try container.encode(swapVenue, forKey: .swapVenue)
                try container.encode(borrowVenue, forKey: .borrowVenue)
                try container.encode(borrowMarketId.hex, forKey: .borrowMarketId)
                try container.encode(feeAmount.description, forKey: .feeAmount)
                try container.encode(feeAssetSymbol, forKey: .feeAssetSymbol)
                try container.encode(feeToken.description, forKey: .feeToken)
                try container.encode(feeTokenPrice.description, forKey: .feeTokenPrice)
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                backingAssetSymbol = try container.decode(String.self, forKey: .backingAssetSymbol)
                backingToken = try container.decode(EthAddress.self, forKey: .backingToken)
                backingTokenPrice = try container.decode(Number.self, forKey: .backingTokenPrice)
                maxSwapBackingAmount = try container.decode(
                    Number.self,
                    forKey: .maxSwapBackingAmount
                )
                maxProvidedBackingAmount = try container.decode(
                    Number.self,
                    forKey: .maxProvidedBackingAmount
                )
                chainId = try container.decode(Number.self, forKey: .chainId)
                // Preserve backwards compatibility
                isIncrease = try container.decodeIfPresent(Bool.self, forKey: .isIncrease) ?? false
                exposureAmount = try container.decode(Number.self, forKey: .exposureAmount)
                exposureAssetSymbol = try container.decode(
                    String.self,
                    forKey: .exposureAssetSymbol
                )
                exposureToken = try container.decode(EthAddress.self, forKey: .exposureToken)
                exposureTokenPrice = try container.decode(Number.self, forKey: .exposureTokenPrice)
                swapVenue = try container.decode(String.self, forKey: .swapVenue)
                borrowVenue = try container.decode(String.self, forKey: .borrowVenue)
                borrowMarketId = try container.decode(Hex.self, forKey: .borrowMarketId)
                if let decodedFeeAmount = try container.decodeIfPresent(Number.self, forKey: .feeAmount) {
                    feeAmount = decodedFeeAmount
                    feeAssetSymbol = try container.decode(String.self, forKey: .feeAssetSymbol)
                    feeToken = try container.decode(EthAddress.self, forKey: .feeToken)
                    feeTokenPrice = try container.decode(Number.self, forKey: .feeTokenPrice)
                } else {
                    feeAmount = .zero
                    feeAssetSymbol = backingAssetSymbol
                    feeToken = backingToken
                    feeTokenPrice = backingTokenPrice
                }
            }

            public static func fromLoopLongActionContext(_ context: Actions.LoopLongActionContext)
                -> LoopLongActionContext
            {
                return LoopLongActionContext(
                    backingAssetSymbol: context.backingAssetSymbol,
                    backingToken: context.backingToken,
                    backingTokenPrice: context.backingTokenPrice,
                    maxSwapBackingAmount: context.maxSwapBackingAmount,
                    maxProvidedBackingAmount: context.maxProvidedBackingAmount,
                    chainId: context.chainId,
                    isIncrease: context.isIncrease,
                    exposureAmount: context.exposureAmount,
                    exposureAssetSymbol: context.exposureAssetSymbol,
                    exposureToken: context.exposureToken,
                    exposureTokenPrice: context.exposureTokenPrice,
                    swapVenue: context.swapVenue,
                    borrowVenue: context.borrowVenue,
                    borrowMarketId: context.borrowMarketId,
                    feeAmount: context.feeAmount,
                    feeAssetSymbol: context.feeAssetSymbol,
                    feeToken: context.feeToken,
                    feeTokenPrice: context.feeTokenPrice
                )
            }
        }

        // ---

        public struct LoopShortActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_LOOP_SHORT

            public let backingAssetSymbol: String
            public let backingToken: EthAddress
            public let backingTokenPrice: Number
            public let minSwapBackingAmount: Number
            public let providedBackingAmount: Number
            public let chainId: Number
            public let isIncrease: Bool
            public let exposureAmount: Number
            public let exposureAssetSymbol: String
            public let exposureToken: EthAddress
            public let exposureTokenPrice: Number
            public let swapVenue: String
            public let borrowVenue: String
            public let borrowMarketId: Hex
            public let feeAmount: Number
            public let feeAssetSymbol: String
            public let feeToken: EthAddress
            public let feeTokenPrice: Number

            public enum CodingKeys: String, CodingKey {
                case backingAssetSymbol = "backing_asset_symbol"
                case backingToken = "backing_token"
                case backingTokenPrice = "backing_token_price"
                case minSwapBackingAmount = "min_swap_backing_amount"
                case providedBackingAmount = "provided_backing_amount"
                case chainId = "chain_id"
                case isIncrease = "is_increase"
                case exposureAmount = "exposure_amount"
                case exposureAssetSymbol = "exposure_asset_symbol"
                case exposureToken = "exposure_token"
                case exposureTokenPrice = "exposure_token_price"
                case swapVenue = "swap_venue"
                case borrowVenue = "borrow_venue"
                case borrowMarketId = "borrow_market_id"
                case feeAmount = "fee_amount"
                case feeAssetSymbol = "fee_asset_symbol"
                case feeToken = "fee_token"
                case feeTokenPrice = "fee_token_price"
            }

            public init(
                backingAssetSymbol: String,
                backingToken: EthAddress,
                backingTokenPrice: Number,
                minSwapBackingAmount: Number,
                providedBackingAmount: Number,
                chainId: Number,
                isIncrease: Bool,
                exposureAmount: Number,
                exposureAssetSymbol: String,
                exposureToken: EthAddress,
                exposureTokenPrice: Number,
                swapVenue: String,
                borrowVenue: String,
                borrowMarketId: Hex,
                feeAmount: Number,
                feeAssetSymbol: String,
                feeToken: EthAddress,
                feeTokenPrice: Number
            ) {
                self.backingAssetSymbol = backingAssetSymbol
                self.backingToken = backingToken
                self.backingTokenPrice = backingTokenPrice
                self.minSwapBackingAmount = minSwapBackingAmount
                self.providedBackingAmount = providedBackingAmount
                self.chainId = chainId
                self.isIncrease = isIncrease
                self.exposureAmount = exposureAmount
                self.exposureAssetSymbol = exposureAssetSymbol
                self.exposureToken = exposureToken
                self.exposureTokenPrice = exposureTokenPrice
                self.swapVenue = swapVenue
                self.borrowVenue = borrowVenue
                self.borrowMarketId = borrowMarketId
                self.feeAmount = feeAmount
                self.feeAssetSymbol = feeAssetSymbol
                self.feeToken = feeToken
                self.feeTokenPrice = feeTokenPrice
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                backingAssetSymbol = try container.decode(String.self, forKey: .backingAssetSymbol)
                backingToken = try container.decode(EthAddress.self, forKey: .backingToken)
                backingTokenPrice = try container.decode(Number.self, forKey: .backingTokenPrice)
                minSwapBackingAmount = try container.decode(Number.self, forKey: .minSwapBackingAmount)
                providedBackingAmount = try container.decode(Number.self, forKey: .providedBackingAmount)
                chainId = try container.decode(Number.self, forKey: .chainId)
                isIncrease = try container.decodeIfPresent(Bool.self, forKey: .isIncrease) ?? false
                exposureAmount = try container.decode(Number.self, forKey: .exposureAmount)
                exposureAssetSymbol = try container.decode(String.self, forKey: .exposureAssetSymbol)
                exposureToken = try container.decode(EthAddress.self, forKey: .exposureToken)
                exposureTokenPrice = try container.decode(Number.self, forKey: .exposureTokenPrice)
                swapVenue = try container.decode(String.self, forKey: .swapVenue)
                borrowVenue = try container.decode(String.self, forKey: .borrowVenue)
                borrowMarketId = try container.decode(Hex.self, forKey: .borrowMarketId)
                // Fee fields are optional - if feeAmount is present, decode all; otherwise default to backing asset with zero fee
                if let decodedFeeAmount = try container.decodeIfPresent(Number.self, forKey: .feeAmount) {
                    feeAmount = decodedFeeAmount
                    feeAssetSymbol = try container.decode(String.self, forKey: .feeAssetSymbol)
                    feeToken = try container.decode(EthAddress.self, forKey: .feeToken)
                    feeTokenPrice = try container.decode(Number.self, forKey: .feeTokenPrice)
                } else {
                    feeAmount = .zero
                    feeAssetSymbol = backingAssetSymbol
                    feeToken = backingToken
                    feeTokenPrice = backingTokenPrice
                }
            }

            public static func fromLoopShortActionContext(_ context: Actions.LoopShortActionContext)
                -> LoopShortActionContext
            {
                return LoopShortActionContext(
                    backingAssetSymbol: context.backingAssetSymbol,
                    backingToken: context.backingToken,
                    backingTokenPrice: context.backingTokenPrice,
                    minSwapBackingAmount: context.minSwapBackingAmount,
                    providedBackingAmount: context.providedBackingAmount,
                    chainId: context.chainId,
                    isIncrease: context.isIncrease,
                    exposureAmount: context.exposureAmount,
                    exposureAssetSymbol: context.exposureAssetSymbol,
                    exposureToken: context.exposureToken,
                    exposureTokenPrice: context.exposureTokenPrice,
                    swapVenue: context.swapVenue,
                    borrowVenue: context.borrowVenue,
                    borrowMarketId: context.borrowMarketId,
                    feeAmount: context.feeAmount,
                    feeAssetSymbol: context.feeAssetSymbol,
                    feeToken: context.feeToken,
                    feeTokenPrice: context.feeTokenPrice
                )
            }
        }

        // ---

        public struct UnloopLongActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_UNLOOP_LONG

            public let backingAssetSymbol: String
            public let backingToken: EthAddress
            public let backingTokenPrice: Number
            public let minSwapBackingAmount: Number
            public let backingAmountToExit: Number
            public let chainId: Number
            public let exposureAmount: Number
            public let exposureAssetSymbol: String
            public let exposureToken: EthAddress
            public let exposureTokenPrice: Number
            public let swapVenue: String
            public let borrowVenue: String
            public let borrowMarketId: Hex
            public let feeAmount: Number
            public let feeAssetSymbol: String
            public let feeToken: EthAddress
            public let feeTokenPrice: Number

            public enum CodingKeys: String, CodingKey {
                case backingAssetSymbol = "backing_asset_symbol"
                case backingToken = "backing_token"
                case backingTokenPrice = "backing_token_price"
                case minSwapBackingAmount = "min_swap_backing_amount"
                case backingAmountToExit = "backing_amount_to_exit"
                case chainId = "chain_id"
                case exposureAmount = "exposure_amount"
                case exposureAssetSymbol = "exposure_asset_symbol"
                case exposureToken = "exposure_token"
                case exposureTokenPrice = "exposure_token_price"
                case swapVenue = "swap_venue"
                case borrowVenue = "borrow_venue"
                case borrowMarketId = "borrow_market_id"
                case feeAmount = "fee_amount"
                case feeAssetSymbol = "fee_asset_symbol"
                case feeToken = "fee_token"
                case feeTokenPrice = "fee_token_price"
            }

            public init(
                backingAssetSymbol: String,
                backingToken: EthAddress,
                backingTokenPrice: Number,
                minSwapBackingAmount: Number,
                backingAmountToExit: Number,
                chainId: Number,
                exposureAmount: Number,
                exposureAssetSymbol: String,
                exposureToken: EthAddress,
                exposureTokenPrice: Number,
                swapVenue: String,
                borrowVenue: String,
                borrowMarketId: Hex,
                feeAmount: Number,
                feeAssetSymbol: String,
                feeToken: EthAddress,
                feeTokenPrice: Number
            ) {
                self.backingAssetSymbol = backingAssetSymbol
                self.backingToken = backingToken
                self.backingTokenPrice = backingTokenPrice
                self.minSwapBackingAmount = minSwapBackingAmount
                self.backingAmountToExit = backingAmountToExit
                self.chainId = chainId
                self.exposureAmount = exposureAmount
                self.exposureAssetSymbol = exposureAssetSymbol
                self.exposureToken = exposureToken
                self.exposureTokenPrice = exposureTokenPrice
                self.swapVenue = swapVenue
                self.borrowVenue = borrowVenue
                self.borrowMarketId = borrowMarketId
                self.feeAmount = feeAmount
                self.feeAssetSymbol = feeAssetSymbol
                self.feeToken = feeToken
                self.feeTokenPrice = feeTokenPrice
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                backingAssetSymbol = try container.decode(String.self, forKey: .backingAssetSymbol)
                backingToken = try container.decode(EthAddress.self, forKey: .backingToken)
                backingTokenPrice = try container.decode(Number.self, forKey: .backingTokenPrice)
                minSwapBackingAmount = try container.decode(Number.self, forKey: .minSwapBackingAmount)
                backingAmountToExit = try container.decode(Number.self, forKey: .backingAmountToExit)
                chainId = try container.decode(Number.self, forKey: .chainId)
                exposureAmount = try container.decode(Number.self, forKey: .exposureAmount)
                exposureAssetSymbol = try container.decode(String.self, forKey: .exposureAssetSymbol)
                exposureToken = try container.decode(EthAddress.self, forKey: .exposureToken)
                exposureTokenPrice = try container.decode(Number.self, forKey: .exposureTokenPrice)
                swapVenue = try container.decode(String.self, forKey: .swapVenue)
                borrowVenue = try container.decode(String.self, forKey: .borrowVenue)
                borrowMarketId = try container.decode(Hex.self, forKey: .borrowMarketId)
                // Fee fields are optional - if feeAmount is present, decode all; otherwise default to backing asset with zero fee
                if let decodedFeeAmount = try container.decodeIfPresent(Number.self, forKey: .feeAmount) {
                    feeAmount = decodedFeeAmount
                    feeAssetSymbol = try container.decode(String.self, forKey: .feeAssetSymbol)
                    feeToken = try container.decode(EthAddress.self, forKey: .feeToken)
                    feeTokenPrice = try container.decode(Number.self, forKey: .feeTokenPrice)
                } else {
                    feeAmount = .zero
                    feeAssetSymbol = backingAssetSymbol
                    feeToken = backingToken
                    feeTokenPrice = backingTokenPrice
                }
            }

            public static func fromUnloopLongActionContext(
                _ context: Actions.UnloopLongActionContext
            ) -> UnloopLongActionContext {
                return UnloopLongActionContext(
                    backingAssetSymbol: context.backingAssetSymbol,
                    backingToken: context.backingToken,
                    backingTokenPrice: context.backingTokenPrice,
                    minSwapBackingAmount: context.minSwapBackingAmount,
                    backingAmountToExit: context.backingAmountToExit,
                    chainId: context.chainId,
                    exposureAmount: context.exposureAmount,
                    exposureAssetSymbol: context.exposureAssetSymbol,
                    exposureToken: context.exposureToken,
                    exposureTokenPrice: context.exposureTokenPrice,
                    swapVenue: context.swapVenue,
                    borrowVenue: context.borrowVenue,
                    borrowMarketId: context.borrowMarketId,
                    feeAmount: context.feeAmount,
                    feeAssetSymbol: context.feeAssetSymbol,
                    feeToken: context.feeToken,
                    feeTokenPrice: context.feeTokenPrice
                )
            }
        }

        // ---

        public struct UnloopShortActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_UNLOOP_SHORT

            public let backingAssetSymbol: String
            public let backingToken: EthAddress
            public let backingTokenPrice: Number
            public let maxSwapBackingAmount: Number
            public let chainId: Number
            public let exposureAmount: Number
            public let exposureAssetSymbol: String
            public let exposureToken: EthAddress
            public let exposureTokenPrice: Number
            public let swapVenue: String
            public let borrowVenue: String
            public let borrowMarketId: Hex
            public let feeAmount: Number
            public let feeAssetSymbol: String
            public let feeToken: EthAddress
            public let feeTokenPrice: Number

            public enum CodingKeys: String, CodingKey {
                case backingAssetSymbol = "backing_asset_symbol"
                case backingToken = "backing_token"
                case backingTokenPrice = "backing_token_price"
                case maxSwapBackingAmount = "max_swap_backing_amount"
                case chainId = "chain_id"
                case exposureAmount = "exposure_amount"
                case exposureAssetSymbol = "exposure_asset_symbol"
                case exposureToken = "exposure_token"
                case exposureTokenPrice = "exposure_token_price"
                case swapVenue = "swap_venue"
                case borrowVenue = "borrow_venue"
                case borrowMarketId = "borrow_market_id"
                case feeAmount = "fee_amount"
                case feeAssetSymbol = "fee_asset_symbol"
                case feeToken = "fee_token"
                case feeTokenPrice = "fee_token_price"
            }

            public init(
                backingAssetSymbol: String,
                backingToken: EthAddress,
                backingTokenPrice: Number,
                maxSwapBackingAmount: Number,
                chainId: Number,
                exposureAmount: Number,
                exposureAssetSymbol: String,
                exposureToken: EthAddress,
                exposureTokenPrice: Number,
                swapVenue: String,
                borrowVenue: String,
                borrowMarketId: Hex,
                feeAmount: Number,
                feeAssetSymbol: String,
                feeToken: EthAddress,
                feeTokenPrice: Number
            ) {
                self.backingAssetSymbol = backingAssetSymbol
                self.backingToken = backingToken
                self.backingTokenPrice = backingTokenPrice
                self.maxSwapBackingAmount = maxSwapBackingAmount
                self.chainId = chainId
                self.exposureAmount = exposureAmount
                self.exposureAssetSymbol = exposureAssetSymbol
                self.exposureToken = exposureToken
                self.exposureTokenPrice = exposureTokenPrice
                self.swapVenue = swapVenue
                self.borrowVenue = borrowVenue
                self.borrowMarketId = borrowMarketId
                self.feeAmount = feeAmount
                self.feeAssetSymbol = feeAssetSymbol
                self.feeToken = feeToken
                self.feeTokenPrice = feeTokenPrice
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                backingAssetSymbol = try container.decode(String.self, forKey: .backingAssetSymbol)
                backingToken = try container.decode(EthAddress.self, forKey: .backingToken)
                backingTokenPrice = try container.decode(Number.self, forKey: .backingTokenPrice)
                maxSwapBackingAmount = try container.decode(Number.self, forKey: .maxSwapBackingAmount)
                chainId = try container.decode(Number.self, forKey: .chainId)
                exposureAmount = try container.decode(Number.self, forKey: .exposureAmount)
                exposureAssetSymbol = try container.decode(String.self, forKey: .exposureAssetSymbol)
                exposureToken = try container.decode(EthAddress.self, forKey: .exposureToken)
                exposureTokenPrice = try container.decode(Number.self, forKey: .exposureTokenPrice)
                swapVenue = try container.decode(String.self, forKey: .swapVenue)
                borrowVenue = try container.decode(String.self, forKey: .borrowVenue)
                borrowMarketId = try container.decode(Hex.self, forKey: .borrowMarketId)
                // Fee fields are optional - if feeAmount is present, decode all; otherwise default to backing asset with zero fee
                if let decodedFeeAmount = try container.decodeIfPresent(Number.self, forKey: .feeAmount) {
                    feeAmount = decodedFeeAmount
                    feeAssetSymbol = try container.decode(String.self, forKey: .feeAssetSymbol)
                    feeToken = try container.decode(EthAddress.self, forKey: .feeToken)
                    feeTokenPrice = try container.decode(Number.self, forKey: .feeTokenPrice)
                } else {
                    feeAmount = .zero
                    feeAssetSymbol = backingAssetSymbol
                    feeToken = backingToken
                    feeTokenPrice = backingTokenPrice
                }
            }

            public static func fromUnloopShortActionContext(
                _ context: Actions.UnloopShortActionContext
            ) -> UnloopShortActionContext {
                return UnloopShortActionContext(
                    backingAssetSymbol: context.backingAssetSymbol,
                    backingToken: context.backingToken,
                    backingTokenPrice: context.backingTokenPrice,
                    maxSwapBackingAmount: context.maxSwapBackingAmount,
                    chainId: context.chainId,
                    exposureAmount: context.exposureAmount,
                    exposureAssetSymbol: context.exposureAssetSymbol,
                    exposureToken: context.exposureToken,
                    exposureTokenPrice: context.exposureTokenPrice,
                    swapVenue: context.swapVenue,
                    borrowVenue: context.borrowVenue,
                    borrowMarketId: context.borrowMarketId,
                    feeAmount: context.feeAmount,
                    feeAssetSymbol: context.feeAssetSymbol,
                    feeToken: context.feeToken,
                    feeTokenPrice: context.feeTokenPrice
                )
            }
        }

        // ---

        public struct WithdrawBackingTokenActionContext: Codable, Equatable, Hashable, Sendable {
            public static let actionType: String = Charter.ACTION_TYPE_WITHDRAW_BACKING_TOKEN

            public let amount: Number
            public let backingAssetSymbol: String
            public let backingToken: EthAddress
            public let backingTokenPrice: Number
            public let chainId: Number
            public let exposureAssetSymbol: String
            public let exposureToken: EthAddress
            public let exposureTokenPrice: Number
            public let borrowVenue: String
            public let borrowMarketId: Hex
            public let isShort: Bool

            public enum CodingKeys: String, CodingKey {
                case amount
                case backingAssetSymbol = "backing_asset_symbol"
                case backingToken = "backing_token"
                case backingTokenPrice = "backing_token_price"
                case chainId = "chain_id"
                case exposureAssetSymbol = "exposure_asset_symbol"
                case exposureToken = "exposure_token"
                case exposureTokenPrice = "exposure_token_price"
                case borrowVenue = "borrow_venue"
                case borrowMarketId = "borrow_market_id"
                case isShort = "is_short"
            }

            public init(
                amount: Number,
                backingAssetSymbol: String,
                backingToken: EthAddress,
                backingTokenPrice: Number,
                chainId: Number,
                exposureAssetSymbol: String,
                exposureToken: EthAddress,
                exposureTokenPrice: Number,
                borrowVenue: String,
                borrowMarketId: Hex,
                isShort: Bool
            ) {
                self.amount = amount
                self.backingAssetSymbol = backingAssetSymbol
                self.backingToken = backingToken
                self.backingTokenPrice = backingTokenPrice
                self.chainId = chainId
                self.exposureAssetSymbol = exposureAssetSymbol
                self.exposureToken = exposureToken
                self.exposureTokenPrice = exposureTokenPrice
                self.borrowVenue = borrowVenue
                self.borrowMarketId = borrowMarketId
                self.isShort = isShort
            }

            public static func fromWithdrawBackingTokenActionContext(
                _ context: Actions.WithdrawBackingTokenActionContext
            ) -> WithdrawBackingTokenActionContext {
                return WithdrawBackingTokenActionContext(
                    amount: context.amount,
                    backingAssetSymbol: context.backingAssetSymbol,
                    backingToken: context.backingToken,
                    backingTokenPrice: context.backingTokenPrice,
                    chainId: context.chainId,
                    exposureAssetSymbol: context.exposureAssetSymbol,
                    exposureToken: context.exposureToken,
                    exposureTokenPrice: context.exposureTokenPrice,
                    borrowVenue: context.borrowVenue,
                    borrowMarketId: context.borrowMarketId,
                    isShort: context.isShort,
                )
            }
        }

        enum ActionContextDecoderError: Error {
            case invalidActionType(String)
        }
    }
}
