import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

let quoteFixture = Quote(
    quoteId: Hex("0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8"),
    issuedAt: .init(timeIntervalSince1970: 1_747_983_262),
    expiresAt: .init(timeIntervalSince1970: 1_748_069_662),
    assetQuotes: [
        Quote.AssetQuote(
            tokenSymbol: "USDC",
            marketPriceUsd: Value(100_000_000),
            adjustedPriceUsd: Value(1_000_000_000)
        ),
        Quote.AssetQuote(
            tokenSymbol: "WETH",
            marketPriceUsd: Value(380_000_000_000),
            adjustedPriceUsd: Value(378_100_000_000)
        ),
    ],
    networkOperationFees: [
        Quote.NetworkOperationFee(
            chainId: 8453,
            operationType: "baseline",
            usdPrice: Value(10_000_000),
        ),
        Quote.NetworkOperationFee(
            chainId: 42161,
            operationType: "baseline",
            usdPrice: Value(100_000_000)
        ),
        Quote.NetworkOperationFee(
            chainId: 84532,
            operationType: "baseline",
            usdPrice: Value(10_000_000)
        ),
        Quote.NetworkOperationFee(
            chainId: 11_155_111,
            operationType: "baseline",
            usdPrice: Value(100_000_000)
        ),
    ]
)

@Suite("Quote Tests")
struct QuoteTests {
    @Test("Test Quotes")
    func testQuotes() async throws {
        let quoteJSON = try String(contentsOf: URL(fileURLWithPath: "./Tests/Fixtures/quote.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let quote = try decoder.decode(Quote.self, from: quoteJSON.data(using: .utf8)!)

        #expect(quote == quoteFixture)
    }
}
