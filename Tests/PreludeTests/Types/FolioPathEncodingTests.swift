import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

@Suite("Folio Path Encoding Tests")
struct FolioPathEncodingTests {

    // MARK: - StringListCodable Tests

    @Test("PriceType to/from string list")
    func priceTypeStringList() throws {
        let token = Folio.PriceType.token(symbol: "USDC")
        let tokenList = token.toStringList()
        #expect(tokenList == ["token", "USDC"])

        let (decoded, remaining) = try Folio.PriceType.fromStringList(tokenList)
        #expect(decoded == token)
        #expect(remaining.isEmpty)

        let assetQuote = Folio.PriceType.assetQuote(
            quoteId: "0xabcdef1234567890",
            tokenSymbol: "ETH"
        )
        let assetList = assetQuote.toStringList()
        #expect(assetList == ["asset_quote", "0xabcdef1234567890", "ETH"])
    }

    @Test("YieldMarketType to/from string list")
    func yieldMarketTypeStringList() throws {
        let pool: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"
        let aave = Folio.YieldMarketType.aave(network: .base, pool: pool, underlyingSymbol: "USDC")
        let list = aave.toStringList()
        #expect(list == ["aave", "base", pool.hex, "USDC"])

        let (decoded, remaining) = try Folio.YieldMarketType.fromStringList(list)
        #expect(decoded == aave)
        #expect(remaining.isEmpty)
    }

    @Test("BalanceType with nested YieldMarketType")
    func balanceTypeNested() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let pool: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"

        let balance = Folio.BalanceType.yieldMarket(
            yieldMarket: .aave(network: .base, pool: pool, underlyingSymbol: "USDC"),
            wallet: wallet
        )

        let list = balance.toStringList()
        #expect(list == ["yield_market", "aave", "base", pool.hex, "USDC", wallet.hex])

        let (decoded, remaining) = try Folio.BalanceType.fromStringList(list)
        #expect(decoded == balance)
        #expect(remaining.isEmpty)
    }

    @Test("String escaping with slashes")
    func stringEscaping() {
        let original = "USD/EUR"
        let escaped = original.escapingSlashes()
        #expect(escaped == "USD\\/EUR")

        let unescaped = escaped.unescapingSlashes()
        #expect(unescaped == original)
    }

    // MARK: - PathDict Tests

    struct TestFolio: Codable {
        @PathDict var balances: [Folio.BalanceType: Amount]
        @PathDict var prices: [Folio.PriceType: Value]
    }

    @Test("PathDict encoding simple dictionary")
    func pathDictSimpleEncoding() throws {
        let wallet: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"
        let testFolio = TestFolio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    "3500000",
                    decimals: 6
                )
            ],
            prices: [
                .token(symbol: "USDC"): Value("1000000")
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(testFolio)
        let json = String(data: data, encoding: .utf8)!

        print(json)

        #expect(
            json.contains("\"token\\/base\\/USDC\\/0x1234567890abcdef1234567890abcdef12345678\"")
        )
        #expect(json.contains("\"token\\/USDC\""))

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestFolio.self, from: data)
        #expect(decoded.balances == testFolio.balances)
        #expect(decoded.prices == testFolio.prices)
    }

    @Test("PathDict with nested types")
    func pathDictNestedEncoding() throws {
        let wallet: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"
        let pool: EthAddress = "0xabcdef1234567890abcdef1234567890abcdef12"

        let testFolio = TestFolio(
            balances: [
                .yieldMarket(
                    yieldMarket: .aave(network: .base, pool: pool, underlyingSymbol: "USDC"),
                    wallet: wallet
                ): Amount("1000000000", decimals: 6)
            ],
            prices: [:]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(testFolio)
        let json = String(data: data, encoding: .utf8)!

        #expect(
            json.contains(
                "\"yield_market\\/aave\\/base\\/0xabcdef1234567890abcdef1234567890abcdef12\\/USDC\\/0x1234567890abcdef1234567890abcdef12345678\""
            )
        )

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestFolio.self, from: data)
        #expect(decoded.balances == testFolio.balances)
    }

    // MARK: - Scientific Encoding Tests

    @Test("Amount scientific encoding")
    func amountScientific() throws {
        let amount = Amount("3500000", decimals: 6)
        #expect(amount.scientific == "3.5e6")

        let decoded = try Amount(scientificString: "3.5e6")
        #expect(decoded == amount)

        let wholeAmount = Amount("1000000", decimals: 6)
        #expect(wholeAmount.scientific == "1e6")

        let zeroDecimalAmount = Amount("42", decimals: 0)
        #expect(zeroDecimalAmount.scientific == "42")
    }

    @Test("Scientific encoding in JSON")
    func scientificInJSON() throws {
        struct TestStruct: Codable {
            @Scientific var amount: Amount
        }

        let test = TestStruct(amount: Amount("3500000", decimals: 6))

        let encoder = JSONEncoder()
        let data = try encoder.encode(test)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"3.5e6\""))

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestStruct.self, from: data)
        #expect(decoded.amount == test.amount)
    }
}
