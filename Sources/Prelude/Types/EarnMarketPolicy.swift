import Eth
import SwiftNumber

/// Controls whether earning positions (yield markets) can be used as sources of liquidity
/// when executing an intent via Tradewinds.
///
/// - `.none`: Only token balances in wallets are used (default).
/// - `.all`: All yield market positions (Aave, Comet, Morpho Vault) may be used.
/// - `.specific`: Only the listed markets may be used, with optional exact amounts.
public enum EarnMarketPolicy: Equatable, Hashable, Sendable {
    case none
    case all
    case specific([EarnMarketSource])

    public struct EarnMarketSource: Codable, Equatable, Hashable, Sendable {
        public let marketAddress: EthAddress
        public let network: Network
        /// Amount to withdraw. `Number.MAX_UINT_256` means use up to the full position (max available).
        public let amount: Number

        public init(marketAddress: EthAddress, network: Network, amount: Number = .MAX_UINT_256) {
            self.marketAddress = marketAddress
            self.network = network
            self.amount = amount
        }

        public enum CodingKeys: String, CodingKey {
            case marketAddress = "market_address"
            case network
            case amount
        }
    }
}

// MARK: - Codable

extension EarnMarketPolicy: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case sources
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .none:
                try container.encode("none", forKey: .type)
            case .all:
                try container.encode("all", forKey: .type)
            case .specific(let sources):
                try container.encode("specific", forKey: .type)
                try container.encode(sources, forKey: .sources)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
            case "none":
                self = .none
            case "all":
                self = .all
            case "specific":
                let sources = try container.decode([EarnMarketSource].self, forKey: .sources)
                self = .specific(sources)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: container,
                    debugDescription: "Unknown earn market policy type: \(type)"
                )
        }
    }
}
