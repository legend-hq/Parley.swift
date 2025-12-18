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
    @PathDict public var completionStatuses: [CompletionStatusType: Bool]

    public init(
        balances: [BalanceType: Amount] = [:],
        prices: [PriceType: Value] = [:],
        yieldMarkets: [YieldMarketType: YieldMarket] = [:],
        borrowMarkets: [BorrowMarketType: BorrowMarket] = [:],
        rewards: [RewardType: Reward] = [:],
        swapHints: [SwapHintType: SwapHint] = [:],
        bridgeHints: [BridgeHintType: BridgeHint] = [:],
        hexData: [HexDataType: Hex] = [:],
        completionStatuses: [CompletionStatusType: Bool] = [:]
    ) {
        self.balances = balances
        self.prices = prices
        self.yieldMarkets = yieldMarkets
        self.borrowMarkets = borrowMarkets
        self.rewards = rewards
        self.swapHints = swapHints
        self.bridgeHints = bridgeHints
        self.hexData = hexData
        self.completionStatuses = completionStatuses
    }

    public enum BalanceType: Codable, Equatable, Hashable, Sendable {
        case token(network: Network, symbol: String, wallet: EthAddress)
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
        @ScientificNil public var supplyCap: Percentage?
        @Scientific public var totalSupply: Amount

        public init(
            supplyApr: Percentage,
            supplyRewardsApr: Percentage,
            supplyCap: Percentage?,
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
            borrowApr: Percentage,
            borrowRewardsApr: Percentage,
            borrowCap: Amount?,
            totalBorrow: Amount,
            collaterals: [String: Collateral]
        ) {
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

    public enum CompletionStatusType: Codable, Equatable, Hashable, Sendable {
        case quarkNonce(wallet: EthAddress, nonce: Hex)
        case acrossFill(wallet: EthAddress, relayHash: Hex)
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
        case completionStatuses = "completion_statuses"
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
