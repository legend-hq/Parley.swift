import Eth
import Foundation
import SwiftNumber

public struct PricesResponse: Codable, Equatable, Sendable {
    public let prices: [String: Value]

    private enum CodingKeys: String, CodingKey {
        case prices
    }

    public init(prices: [String: Value]) {
        self.prices = prices
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pricesDict = try container.decode([String: String].self, forKey: .prices)

        var decodedPrices: [String: Value] = [:]
        for (key, stringValue) in pricesDict {
            decodedPrices[key] = try Value(scientificString: stringValue)
        }
        self.prices = decodedPrices
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var encodedPrices: [String: String] = [:]
        for (key, value) in prices {
            encodedPrices[key] = value.scientific
        }
        try container.encode(encodedPrices, forKey: .prices)
    }
}
