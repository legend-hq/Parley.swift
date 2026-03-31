import Atlas
import Eth
import Foundation
import SwiftNumber

public struct Folio: Codable, Equatable, Hashable, Sendable {
    @PathDict public var balances: [BalanceType: Amount]
    @PathDict public var prices: [PriceType: Value]
    @PathDict public var yieldMarkets: [YieldMarketType: YieldMarket]
    @PathDict public var borrowMarkets: [BorrowMarketType: BorrowMarket]
    @PathDict public var rewards: [RewardType: Reward]
    @PathDict public var swapHints: [SwapHintType: SwapHint]
    @PathDict public var bridgeHints: [BridgeHintType: BridgeHint]
    @PathDict public var hexData: [HexDataType: Hex]
    @PathDict public var solanaTransactionContext: [SolanaTransactionContextType: SolanaTransactionContext]
    @PathDict public var completionStatuses: [CompletionStatusType: Bool]
    @PathDict public var patches: [CompletionStatusType: [Patch]]

    public init(
        balances: [BalanceType: Amount] = [:],
        prices: [PriceType: Value] = [:],
        yieldMarkets: [YieldMarketType: YieldMarket] = [:],
        borrowMarkets: [BorrowMarketType: BorrowMarket] = [:],
        rewards: [RewardType: Reward] = [:],
        swapHints: [SwapHintType: SwapHint] = [:],
        bridgeHints: [BridgeHintType: BridgeHint] = [:],
        hexData: [HexDataType: Hex] = [:],
        solanaTransactionContext: [SolanaTransactionContextType: SolanaTransactionContext] = [:],
        completionStatuses: [CompletionStatusType: Bool] = [:],
        patches: [CompletionStatusType: [Patch]] = [:]
    ) {
        self.balances = balances
        self.prices = prices
        self.yieldMarkets = yieldMarkets
        self.borrowMarkets = borrowMarkets
        self.rewards = rewards
        self.swapHints = swapHints
        self.bridgeHints = bridgeHints
        self.hexData = hexData
        self.solanaTransactionContext = solanaTransactionContext
        self.completionStatuses = completionStatuses
        self.patches = patches
    }

    public enum BalanceType: Codable, Equatable, Hashable, Sendable {
        case token(network: Network, symbol: String, wallet: ChainAddress)
        case yieldMarket(yieldMarket: YieldMarketType, wallet: EthAddress)
        case borrowMarket(borrowMarket: BorrowMarketType, wallet: EthAddress)
        case borrowMarketCollateral(
            borrowMarket: BorrowMarketType,
            tokenSymbol: String,
            wallet: EthAddress
        )
        case reward(rewardType: RewardType)
        case lockedReward(rewardType: RewardType)
    }

    public enum PriceType: Codable, Equatable, Hashable, Sendable {
        case token(symbol: String)
        case assetQuote(quoteId: Hex, tokenSymbol: String)
        case networkOperationQuote(quoteId: Hex, network: Network, operationType: String)
    }

    public enum YieldMarketType: Codable, Equatable, Hashable, Sendable {
        case aave(network: Network, pool: EthAddress, underlyingSymbol: String)
        case comet(network: Network, comet: EthAddress, underlyingSymbol: String)
        case morphoVault(network: Network, vault: EthAddress, underlyingSymbol: String)
        case stakingToken(network: Network, symbol: String)
    }

    public struct YieldMarket: Codable, Equatable, Hashable, Sendable {
        @Scientific public var supplyApr: Percentage
        @Scientific public var supplyRewardsApr: Percentage
        @ScientificNil public var supplyCap: Amount?
        @Scientific public var totalSupply: Amount

        public init(
            supplyApr: Percentage,
            supplyRewardsApr: Percentage,
            supplyCap: Amount?,
            totalSupply: Amount
        ) {
            self.supplyApr = supplyApr
            self.supplyRewardsApr = supplyRewardsApr
            self.supplyCap = supplyCap
            self.totalSupply = totalSupply
        }
    }

    public enum BorrowMarketType: Codable, Equatable, Hashable, Sendable {
        case aave(network: Network, pool: EthAddress, underlyingSymbol: String)
        case comet(network: Network, comet: EthAddress, underlyingSymbol: String)
        case morpho(network: Network, collateralTokenSymbol: String, borrowTokenSymbol: String)
    }

    public struct BorrowMarket: Codable, Equatable, Hashable, Sendable {
        @ScientificNil public var baseBorrowMin: Amount?
        @Scientific public var borrowApr: Percentage
        @Scientific public var borrowRewardsApr: Percentage
        @ScientificNil public var borrowCap: Amount?
        @Scientific public var totalBorrow: Amount
        public var collaterals: [String: Collateral]

        public struct Collateral: Codable, Equatable, Hashable, Sendable {
            @Scientific public var borrowCollateralFactor: Percentage
            @Scientific public var liquidateCollateralFactor: Percentage
            @ScientificNil public var liquidationFactor: Percentage?
            @ScientificNil public var supplyCap: Amount?
            @ScientificNil public var totalSupply: Amount?
            @Scientific public var usdPrice: Value

            public init(
                borrowCollateralFactor: Percentage,
                liquidateCollateralFactor: Percentage,
                liquidationFactor: Percentage?,
                supplyCap: Amount?,
                totalSupply: Amount?,
                usdPrice: Value
            ) {
                self.borrowCollateralFactor = borrowCollateralFactor
                self.liquidateCollateralFactor = liquidateCollateralFactor
                self.liquidationFactor = liquidationFactor
                self.supplyCap = supplyCap
                self.totalSupply = totalSupply
                self.usdPrice = usdPrice
            }
        }

        public init(
            baseBorrowMin: Amount? = nil,
            borrowApr: Percentage,
            borrowRewardsApr: Percentage,
            borrowCap: Amount?,
            totalBorrow: Amount,
            collaterals: [String: Collateral]
        ) {
            self.baseBorrowMin = baseBorrowMin
            self.borrowApr = borrowApr
            self.borrowRewardsApr = borrowRewardsApr
            self.borrowCap = borrowCap
            self.totalBorrow = totalBorrow
            self.collaterals = collaterals
        }
    }

    public enum RewardType: Codable, Equatable, Hashable, Sendable {
        case cometReward(
            network: Network,
            comet: EthAddress,
            underlyingSymbol: String,
            cometRewards: EthAddress,
            wallet: EthAddress
        )
        case morphoReward(
            network: Network,
            underlyingSymbol: String,
            distributor: EthAddress,
            wallet: EthAddress
        )
    }

    public struct Reward: Codable, Equatable, Hashable, Sendable {
        public var proof: Proof

        public enum Proof: Equatable, Hashable, Sendable {
            case none
            case morphoReward(proof: [Hex], proofAmount: Amount)
        }

        public init(proof: Proof) {
            self.proof = proof
        }
    }

    public enum SwapHintType: Codable, Equatable, Hashable, Sendable {
        case wrapper(
            underlyingNetwork: Network,
            underlyingSymbol: String,
            wrappedNetwork: Network,
            wrappedSymbol: String
        )
        /// DEX/aggregator swap hint tier.
        /// tierAmount is the cumulative sell amount at which this tier ends (used as unique key).
        /// The SwapHint value contains: maxAmount=incremental capacity, exchangeRate=tier rate.
        case swap(
            network: Network,
            sellSymbol: String,
            buySymbol: String,
            venue: String,
            tierAmount: Number
        )
    }

    public struct SwapHint: Codable, Equatable, Hashable, Sendable {
        @ScientificNil public var minAmount: Amount?
        @ScientificNil public var maxAmount: Amount?
        @Scientific public var exchangeRate: Percentage

        public init(minAmount: Amount?, maxAmount: Amount?, exchangeRate: Percentage) {
            self.minAmount = minAmount
            self.maxAmount = maxAmount
            self.exchangeRate = exchangeRate
        }
    }

    public enum BridgeHintType: Codable, Equatable, Hashable, Sendable {
        case across(
            networkIn: Network,
            symbolIn: String,
            networkOut: Network,
            symbolOut: String
        )
        case cctpV2(
            networkIn: Network,
            symbolIn: String,
            networkOut: Network,
            symbolOut: String
        )
    }

    public struct BridgeHint: Codable, Equatable, Hashable, Sendable {
        @Scientific public var minAmount: Amount
        @Scientific public var maxAmount: Amount
        @Scientific public var maxAmountInstant: Amount
        public let estimatedFillTimeSec: Int
        @Scientific public var fixedCost: Amount
        @Scientific public var rate: Percentage

        public init(
            minAmount: Amount,
            maxAmount: Amount,
            maxAmountInstant: Amount,
            estimatedFillTimeSec: Int,
            fixedCost: Amount,
            rate: Percentage
        ) {
            self.minAmount = minAmount
            self.maxAmount = maxAmount
            self.maxAmountInstant = maxAmountInstant
            self.estimatedFillTimeSec = estimatedFillTimeSec
            self.fixedCost = fixedCost
            self.rate = rate
        }
    }

    public enum HexDataType: Codable, Equatable, Hashable, Sendable {
        case nonceSecret(network: Network, wallet: EthAddress)
    }

    /// Key type for Solana transaction context, keyed by the user's Solana wallet.
    public enum SolanaTransactionContextType: Codable, Equatable, Hashable, Sendable {
        case durableNonce(wallet: SolanaAddress)
    }

    /// Per-wallet Solana transaction context: everything Charter needs to build a Solana transaction.
    /// Injected by the backend before charting, similar to how EVM nonce secrets are injected.
    public struct SolanaTransactionContext: Codable, Equatable, Hashable, Sendable {
        /// The on-chain durable nonce account (a Solana Pubkey).
        public let nonceAccount: SolanaAddress
        /// The current durable nonce value (a 32-byte hash derived from a blockhash).
        /// Placed in the transaction's `recent_blockhash` field.
        public let nonceValue: Base58Data
        /// Legend's fee payer address for this transaction.
        /// Used as the ATA creation payer and the transaction fee payer.
        public let feePayer: SolanaAddress

        public init(nonceAccount: SolanaAddress, nonceValue: Base58Data, feePayer: SolanaAddress) {
            self.nonceAccount = nonceAccount
            self.nonceValue = nonceValue
            self.feePayer = feePayer
        }

        public enum CodingKeys: String, CodingKey {
            case nonceAccount = "nonce_account"
            case nonceValue = "nonce_value"
            case feePayer = "fee_payer"
        }
    }

    public enum CompletionStatusType: Codable, Equatable, Hashable, Sendable {
        case quarkNonce(wallet: EthAddress, nonce: Hex)
        case acrossFill(wallet: EthAddress, relayHash: Hex)
        case cctpV2Fill(wallet: EthAddress, nonce: Hex)
    }

    public struct Patch: Equatable, Hashable, Sendable {
        public var target: BalanceType
        public var delta: SignedAmount
        public var operationId: Hex?
        public var metadata: PatchMetadata?

        public init(
            target: BalanceType,
            delta: SignedAmount,
            operationId: Hex? = nil,
            metadata: PatchMetadata? = nil
        ) {
            self.target = target
            self.delta = delta
            self.operationId = operationId
            self.metadata = metadata
        }
    }

    public struct PatchMetadata: Codable, Equatable, Hashable, Sendable {
        public var operationType: OperationType?
        public var estimatedEta: Int?

        public init(operationType: OperationType? = nil, estimatedEta: Int? = nil) {
            self.operationType = operationType
            self.estimatedEta = estimatedEta
        }
    }

    public enum OperationType: String, Codable, Equatable, Hashable, Sendable {
        case slowRefund = "slow_refund"
    }
}

// MARK: - CodingKeys for snake_case JSON

extension Folio {
    private enum CodingKeys: String, CodingKey {
        case balances
        case prices
        case yieldMarkets = "yield_markets"
        case borrowMarkets = "borrow_markets"
        case rewards
        case swapHints = "swap_hints"
        case bridgeHints = "bridge_hints"
        case hexData = "hex_data"
        case solanaTransactionContext = "solana_transaction_context"
        case completionStatuses = "completion_statuses"
        case patches
    }
}

extension Folio.YieldMarket {
    private enum CodingKeys: String, CodingKey {
        case supplyApr = "supply_apr"
        case supplyRewardsApr = "supply_rewards_apr"
        case supplyCap = "supply_cap"
        case totalSupply = "total_supply"
    }
}

extension Folio.BorrowMarket {
    private enum CodingKeys: String, CodingKey {
        case baseBorrowMin = "base_borrow_min"
        case borrowApr = "borrow_apr"
        case borrowRewardsApr = "borrow_rewards_apr"
        case borrowCap = "borrow_cap"
        case totalBorrow = "total_borrow"
        case collaterals
    }
}

extension Folio.BorrowMarket.Collateral {
    private enum CodingKeys: String, CodingKey {
        case borrowCollateralFactor = "borrow_collateral_factor"
        case liquidateCollateralFactor = "liquidate_collateral_factor"
        case liquidationFactor = "liquidation_factor"
        case supplyCap = "supply_cap"
        case totalSupply = "total_supply"
        case usdPrice = "usd_price"
    }
}

extension Folio.SwapHint {
    private enum CodingKeys: String, CodingKey {
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case exchangeRate = "exchange_rate"
    }
}

extension Folio.BridgeHint {
    private enum CodingKeys: String, CodingKey {
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case maxAmountInstant = "max_amount_instant"
        case estimatedFillTimeSec = "estimated_fill_time_sec"
        case fixedCost = "fixed_cost"
        case rate
    }
}

// MARK: - Custom Codable for Patch

extension Folio.Patch: Codable {
    private enum CodingKeys: String, CodingKey {
        case target, delta
        case operationId = "operation_id"
        case metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let targetPath = try container.decode(String.self, forKey: .target)
        let components = targetPath.splitPath()
        let (target, _) = try Folio.BalanceType.fromStringList(components)
        self.target = target

        let deltaStr = try container.decode(String.self, forKey: .delta)
        self.delta = try SignedAmount(scientificString: deltaStr)

        self.operationId = try container.decodeIfPresent(Hex.self, forKey: .operationId)
        self.metadata = try container.decodeIfPresent(Folio.PatchMetadata.self, forKey: .metadata)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let pathComponents = target.toStringList().map { $0.escapingSlashes() }
        try container.encode(pathComponents.joined(separator: "/"), forKey: .target)
        try container.encode(delta.scientific, forKey: .delta)
        try container.encodeIfPresent(operationId, forKey: .operationId)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}

// MARK: - CodingKeys for PatchMetadata

extension Folio.PatchMetadata {
    private enum CodingKeys: String, CodingKey {
        case operationType = "operation_type"
        case estimatedEta = "estimated_eta"
    }
}

// MARK: - Custom Codable for Proof

extension Folio.Reward.Proof: Codable {
    private enum CodingKeys: String, CodingKey {
        case proofType = "proof_type"
        case proof
        case proofAmount = "proof_amount"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let proofType = try container.decode(String.self, forKey: .proofType)

        switch proofType {
            case "none":
                self = .none
            case "morpho_reward":
                let proof = try container.decode([Hex].self, forKey: .proof)
                // Decode proof_amount as a scientific notation string
                let proofAmountString = try container.decode(String.self, forKey: .proofAmount)
                let proofAmount = try Amount(scientificString: proofAmountString)
                self = .morphoReward(proof: proof, proofAmount: proofAmount)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .proofType,
                    in: container,
                    debugDescription: "Unknown proof type: \(proofType)"
                )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
            case .none:
                try container.encode("none", forKey: .proofType)
            case .morphoReward(let proof, let proofAmount):
                try container.encode("morpho_reward", forKey: .proofType)
                try container.encode(proof, forKey: .proof)
                // Encode proof_amount using scientific notation
                try container.encode(proofAmount.scientific, forKey: .proofAmount)
        }
    }
}
