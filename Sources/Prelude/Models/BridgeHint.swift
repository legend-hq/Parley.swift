import Eth
import Foundation
import SwiftNumber

public enum LegendModel {
    public struct BridgeHintResponse: Codable, Equatable, Sendable {
        public let bridgeHints: [BridgeHint]

        enum CodingKeys: String, CodingKey {
            case bridgeHints = "bridge_hints"
        }
    }

    public struct BridgeHint: Codable, Equatable, Sendable {
        public enum BridgeType: String, Codable, Equatable, Sendable {
            case across
            case cctpV2 = "cctp_v2"
        }

        public let bridgeType: BridgeType
        @NetworkIdent public var networkIn: Network
        public let symbolIn: String
        @NetworkIdent public var networkOut: Network
        public let symbolOut: String
        @Scientific public var minAmount: Amount
        @Scientific public var maxAmount: Amount
        @Scientific public var maxAmountInstant: Amount
        public let estimatedFillTimeSec: Int
        @Scientific public var fixedCost: Amount
        @Scientific public var rate: Percentage

        public init(
            bridgeType: BridgeType,
            networkIn: Network,
            symbolIn: String,
            networkOut: Network,
            symbolOut: String,
            minAmount: Amount,
            maxAmount: Amount,
            maxAmountInstant: Amount,
            estimatedFillTimeSec: Int,
            fixedCost: Amount,
            rate: Percentage
        ) {
            self.bridgeType = bridgeType
            self.networkIn = networkIn
            self.symbolIn = symbolIn
            self.networkOut = networkOut
            self.symbolOut = symbolOut
            self.minAmount = minAmount
            self.maxAmount = maxAmount
            self.maxAmountInstant = maxAmountInstant
            self.estimatedFillTimeSec = estimatedFillTimeSec
            self.fixedCost = fixedCost
            self.rate = rate
        }

        enum CodingKeys: String, CodingKey {
            case bridgeType = "type"
            case networkIn = "network_in"
            case symbolIn = "symbol_in"
            case networkOut = "network_out"
            case symbolOut = "symbol_out"
            case minAmount = "min_amount"
            case maxAmount = "max_amount"
            case maxAmountInstant = "max_amount_instant"
            case estimatedFillTimeSec = "estimated_fill_time_sec"
            case fixedCost = "fixed_cost"
            case rate = "rate"
        }
    }
}
