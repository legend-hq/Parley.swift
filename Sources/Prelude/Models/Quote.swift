import Eth
import Foundation
import SwiftNumber

public struct Quote: Codable, Equatable, Sendable {
    public let quoteId: Hex
    public let issuedAt: Date
    public let expiresAt: Date
    public let assetQuotes: [AssetQuote]
    public let networkOperationFees: [NetworkOperationFee]

    enum CodingKeys: String, CodingKey {
        case quoteId = "quote_id"
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
        case assetQuotes = "asset_quotes"
        case networkOperationFees = "network_operation_fees"
    }

    public init(
        quoteId: Hex,
        issuedAt: Date,
        expiresAt: Date,
        assetQuotes: [AssetQuote],
        networkOperationFees: [NetworkOperationFee]
    ) {
        self.quoteId = quoteId
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.assetQuotes = assetQuotes
        self.networkOperationFees = networkOperationFees
    }

    public struct AssetQuote: Codable, Equatable, Sendable {
        public let tokenSymbol: String
        public let marketPriceUsd: Value
        public let adjustedPriceUsd: Value

        enum CodingKeys: String, CodingKey {
            case tokenSymbol = "token_symbol"
            case marketPriceUsd = "market_price_usd"
            case adjustedPriceUsd = "adjusted_price_usd"
        }

        public init(
            tokenSymbol: String,
            marketPriceUsd: Value,
            adjustedPriceUsd: Value
        ) {
            self.tokenSymbol = tokenSymbol
            self.marketPriceUsd = marketPriceUsd
            self.adjustedPriceUsd = adjustedPriceUsd
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            tokenSymbol = try container.decode(String.self, forKey: .tokenSymbol)

            let marketPriceUsdString = try container.decode(String.self, forKey: .marketPriceUsd)
            marketPriceUsd = Value(Number(stringLiteral: marketPriceUsdString))

            let adjustedPriceUsdString = try container.decode(
                String.self,
                forKey: .adjustedPriceUsd
            )
            adjustedPriceUsd = Value(Number(stringLiteral: adjustedPriceUsdString))
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(tokenSymbol, forKey: .tokenSymbol)
            try container.encode(marketPriceUsd.underlying.description, forKey: .marketPriceUsd)
            try container.encode(adjustedPriceUsd.underlying.description, forKey: .adjustedPriceUsd)
        }
    }

    public struct NetworkOperationFee: Codable, Equatable, Sendable {
        public let chainId: UInt
        public let operationType: String
        public let usdPrice: Value

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case opType = "operation_type"
            case usdPrice = "usd_price"
        }

        public init(
            chainId: UInt,
            operationType: String,
            usdPrice: Value
        ) {
            self.chainId = chainId
            self.operationType = operationType
            self.usdPrice = usdPrice
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            chainId = try container.decode(UInt.self, forKey: .chainId)
            operationType = try container.decode(String.self, forKey: .opType)

            let usdPriceString = try container.decode(String.self, forKey: .usdPrice)
            usdPrice = Value(Number(stringLiteral: usdPriceString))
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(chainId, forKey: .chainId)
            try container.encode(operationType, forKey: .opType)
            try container.encode(usdPrice.underlying.description, forKey: .usdPrice)
        }
    }

    public var isValid: Bool {
        expiresAt > Date()
    }
}
