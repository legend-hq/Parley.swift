import Atlas
import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

@Suite("Folio Codable Tests")
struct FolioCodableTests {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    // MARK: - Empty Folio Tests

    @Test("Empty Folio encoding")
    func emptyFolioEncoding() throws {
        let folio = Folio()

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        let expectedJson = """
            {
              "balances" : {

              },
              "borrow_markets" : {

              },
              "bridge_hints" : {

              },
              "completion_statuses" : {

              },
              "hex_data" : {

              },
              "patches" : {

              },
              "prices" : {

              },
              "rewards" : {

              },
              "solana_transaction_context" : {

              },
              "swap_hints" : {

              },
              "yield_markets" : {

              }
            }
            """

        #expect(json == expectedJson)

        // Also verify round-trip
        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Simple Token Balance Tests

    @Test("Simple token balance encoding")
    func simpleTokenBalance() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    "52000000",
                    decimals: 6
                )
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        let expectedJson = """
            {
              "balances" : {
                "token/base/USDC/0xaabbccddee1234567890abcdef1234567890abcd" : "52e6"
              },
              "borrow_markets" : {

              },
              "bridge_hints" : {

              },
              "completion_statuses" : {

              },
              "hex_data" : {

              },
              "patches" : {

              },
              "prices" : {

              },
              "rewards" : {

              },
              "solana_transaction_context" : {

              },
              "swap_hints" : {

              },
              "yield_markets" : {

              }
            }
            """

        #expect(json == expectedJson)

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Prices with Scientific Notation

    @Test("Prices encoding with Values")
    func pricesEncoding() throws {
        let folio = Folio(
            prices: [
                .token(symbol: "USDC"): Value("1000000"),
                .token(symbol: "ETH"): Value("3500000000"),
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        // Values should encode as decimal numbers
        #expect(json.contains("\"token/USDC\" : \"0.01\""))
        #expect(json.contains("\"token/ETH\" : \"35\""))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Yield Markets with Scientific Properties

    @Test("YieldMarket with Scientific encoding")
    func yieldMarketScientific() throws {
        let pool: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"

        let folio = Folio(
            yieldMarkets: [
                .aave(network: .base, pool: pool, underlyingSymbol: "USDC"): Folio.YieldMarket(
                    supplyApr: Percentage(fromBps: Number("250")),  // 2.5%
                    supplyRewardsApr: Percentage(fromBps: Number("100")),  // 1%
                    supplyCap: Amount("9500000000", decimals: 6),
                    totalSupply: Amount("1000000000", decimals: 6)
                )
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        // Check the yield market key format
        #expect(json.contains("\"aave/base/0x1234567890abcdef1234567890abcdef12345678/USDC\""))

        // Check scientific encoding of values
        #expect(json.contains("\"supply_apr\" : \"0.025\""))
        #expect(json.contains("\"supply_rewards_apr\" : \"0.01\""))
        #expect(json.contains("\"supply_cap\" : \"9500e6\""))
        #expect(json.contains("\"total_supply\" : \"1000e6\""))  // Should use scientific notation

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Complex Nested Types

    @Test("Complex nested balance types")
    func complexNestedTypes() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let pool: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"

        let folio = Folio(
            balances: [
                .yieldMarket(
                    yieldMarket: .aave(network: .base, pool: pool, underlyingSymbol: "USDC"),
                    wallet: wallet
                ): Amount("100000000", decimals: 6),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "ETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: wallet
                ): Amount("2000000000000000000", decimals: 18),
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        // Check nested type encoding
        #expect(
            json.contains(
                "\"yield_market/aave/base/0x1234567890abcdef1234567890abcdef12345678/USDC/0xaabbccddee1234567890abcdef1234567890abcd\""
            )
        )
        #expect(
            json.contains(
                "\"borrow_market_collateral/morpho/base/ETH/USDC/WETH/0xaabbccddee1234567890abcdef1234567890abcd\""
            )
        )

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Network Identifier Tests

    @Test("Network identifier encoding")
    func networkIdentEncoding() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"

        let folio = Folio(
            balances: [
                .token(network: .ethereum, symbol: "ETH", wallet: wallet.on(.ethereum)): Amount(
                    "1000000000000000000",
                    decimals: 18
                ),
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    "1000000",
                    decimals: 6
                ),
                .token(network: .arbitrum, symbol: "ARB", wallet: wallet.on(.arbitrum)): Amount(
                    "5000000000000000000",
                    decimals: 18
                ),
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        // Check network identifiers are readable
        #expect(json.contains("token/ethereum/ETH"))
        #expect(json.contains("token/base/USDC"))
        #expect(json.contains("token/arbitrum/ARB"))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Optional Fields with ScientificNil

    @Test("Optional fields with null values")
    func optionalFieldsNull() throws {
        let pool: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"

        let folio = Folio(
            yieldMarkets: [
                .aave(network: .base, pool: pool, underlyingSymbol: "USDC"): Folio.YieldMarket(
                    supplyApr: Percentage(fromBps: Number("250")),  // 2.5%
                    supplyRewardsApr: Percentage(fromBps: Number("100")),  // 1%
                    supplyCap: nil,  // This should encode as null
                    totalSupply: Amount("1000000000", decimals: 6)
                )
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"supply_cap\" : null"))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Complete Folio Example

    @Test("Complete Folio with all field types")
    func completeFolio() throws {
        let wallet: EthAddress = "0x00000000000000000000000000000000000a11ce"  // alice
        let pool: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"
        let comet: EthAddress = "0x5678901234567890abcdef1234567890abcdef12"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    "52000000",
                    decimals: 6
                ),
                .reward(
                    rewardType: .cometReward(
                        network: .base,
                        comet: comet,
                        underlyingSymbol: "USDC",
                        cometRewards: EthAddress("0x0000000000000000000000000000000000000022"),
                        wallet: wallet
                    )
                ):
                    Amount("1000000", decimals: 6),
                .lockedReward(
                    rewardType: .cometReward(
                        network: .base,
                        comet: comet,
                        underlyingSymbol: "USDC",
                        cometRewards: EthAddress("0x0000000000000000000000000000000000000022"),
                        wallet: wallet
                    )
                ):
                    Amount("2000000", decimals: 6),
            ],
            prices: [
                .token(symbol: "USDC"): Value("100000000")  // $1.00
            ],
            yieldMarkets: [
                .aave(network: .base, pool: pool, underlyingSymbol: "USDC"): Folio.YieldMarket(
                    supplyApr: Percentage(fromBps: Number("250")),  // 2.5%
                    supplyRewardsApr: Percentage(fromBps: Number("100")),  // 1%
                    supplyCap: nil,
                    totalSupply: Amount("1000000000", decimals: 6)
                )
            ],
            borrowMarkets: [
                .comet(network: .base, comet: comet, underlyingSymbol: "USDC"): Folio.BorrowMarket(
                    borrowApr: Percentage(fromBps: Number("500")),  // 5%
                    borrowRewardsApr: Percentage(fromBps: Number("0")),  // 0%
                    borrowCap: Amount("1000000000", decimals: 6),  // 1000 USDC
                    totalBorrow: Amount("500000000", decimals: 6),
                    collaterals: [
                        "WETH": Folio.BorrowMarket.Collateral(
                            borrowCollateralFactor: Percentage(fromBps: Number("8000")),  // 80%
                            liquidateCollateralFactor: Percentage(fromBps: Number("8500")),  // 85%
                            liquidationFactor: Percentage(fromBps: Number("500")),  // 5%
                            supplyCap: Amount("10000000000000000000000", decimals: 18),  // 10,000 ETH
                            totalSupply: Amount("5000000000000000000000", decimals: 18),  // 5,000 ETH
                            usdPrice: Value("350000000000")  // $3,500
                        )
                    ]
                )
            ],
            rewards: [
                .cometReward(
                    network: .base,
                    comet: comet,
                    underlyingSymbol: "USDC",
                    cometRewards: "0x0000000000000000000000000000000000000022",
                    wallet: wallet
                ):
                    Folio.Reward(
                        proof: .none
                    ),
                .morphoReward(
                    network: .base,
                    underlyingSymbol: "USDC",
                    distributor: "0x0000000000000000000000000000000000000022",
                    wallet: wallet
                ):
                    Folio.Reward(
                        proof: .morphoReward(
                            proof: [
                                "0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff",
                                "0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff",
                            ],
                            proofAmount: "3.0e8"
                        )
                    ),
            ],
            swapHints: [
                .wrapper(
                    underlyingNetwork: .base,
                    underlyingSymbol: "USDC",
                    wrappedNetwork: .base,
                    wrappedSymbol: "USDC+"
                ): Folio.SwapHint(
                    minAmount: Amount("100000000", decimals: 6),  // 100 USDC minimum
                    maxAmount: Amount("1000000000", decimals: 6),  // 1000 USDC maximum
                    exchangeRate: Percentage(fromBps: Number("10000"))  // 100%
                ),
                .swap(
                    network: .base,
                    sellSymbol: "USDC",
                    buySymbol: "WETH",
                    venue: "0x",
                    tierAmount: Number("100000000")  // 100 USDC tier
                ): Folio.SwapHint(
                    minAmount: Amount("0", decimals: 6),
                    maxAmount: Amount("100000000", decimals: 6),  // 100 USDC capacity
                    exchangeRate: Percentage(fromBps: Number("4"))  // 0.04% (0.0004 ETH/USDC)
                )
            ],
            bridgeHints: [
                .across(
                    networkIn: .base,
                    symbolIn: "USDC",
                    networkOut: .arbitrum,
                    symbolOut: "USDC"
                ): Folio.BridgeHint(
                    minAmount: Amount("1000000", decimals: 6),
                    maxAmount: Amount("2000000000", decimals: 6),
                    maxAmountInstant: Amount("1500000000", decimals: 6),
                    estimatedFillTimeSec: 5,
                    fixedCost: Amount("500000", decimals: 6),
                    rate: Percentage(fromBps: Number("9950"))  // 99.5%
                )
            ],
            hexData: [
                .nonceSecret(network: .base, wallet: wallet): Hex(
                    stringLiteral:
                        "0xcafecafecafecafecafecafecafecafecafecafecafecafecafecafecafecafe"
                )
            ],
            solanaTransactionContext: [
                .wallet(SolanaAddress("7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV")):
                    Folio.SolanaTransactionContext(
                        durableNonceAccount: SolanaAddress("9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"),
                        durableNonceValue: Base58Data(fromBase58: "F7vmkY3DTaxfagttWjQweib42b6ZHADSx94Tw8gHx3W7")!,
                        feePayer: SolanaAddress("FVen3X669xLzsi6N2V91DoiyzHzg1uAgqiT8jZ9nS96Z")
                    )
            ],
            completionStatuses: [
                .quarkNonce(
                    wallet: wallet,
                    nonce: Hex(
                        stringLiteral:
                            "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
                    )
                ):
                    true
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        let expectedJson = """
            {
              "balances" : {
                "locked_reward/comet_reward/base/0x5678901234567890abcdef1234567890abcdef12/USDC/0x0000000000000000000000000000000000000022/0x00000000000000000000000000000000000a11ce" : "2e6",
                "reward/comet_reward/base/0x5678901234567890abcdef1234567890abcdef12/USDC/0x0000000000000000000000000000000000000022/0x00000000000000000000000000000000000a11ce" : "1e6",
                "token/base/USDC/0x00000000000000000000000000000000000a11ce" : "52e6"
              },
              "borrow_markets" : {
                "comet/base/0x5678901234567890abcdef1234567890abcdef12/USDC" : {
                  "base_borrow_min" : null,
                  "borrow_apr" : "0.05",
                  "borrow_cap" : "1000e6",
                  "borrow_rewards_apr" : "0",
                  "collaterals" : {
                    "WETH" : {
                      "borrow_collateral_factor" : "0.8",
                      "liquidate_collateral_factor" : "0.85",
                      "liquidation_factor" : "0.05",
                      "supply_cap" : "10000e18",
                      "total_supply" : "5000e18",
                      "usd_price" : "3500"
                    }
                  },
                  "total_borrow" : "500e6"
                }
              },
              "bridge_hints" : {
                "across/base/USDC/arbitrum/USDC" : {
                  "estimated_fill_time_sec" : 5,
                  "fixed_cost" : "0.5e6",
                  "max_amount" : "2000e6",
                  "max_amount_instant" : "1500e6",
                  "min_amount" : "1e6",
                  "rate" : "0.995"
                }
              },
              "completion_statuses" : {
                "quark_nonce/0x00000000000000000000000000000000000a11ce/0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" : true
              },
              "hex_data" : {
                "nonce_secret/base/0x00000000000000000000000000000000000a11ce" : "0xcafecafecafecafecafecafecafecafecafecafecafecafecafecafecafecafe"
              },
              "patches" : {

              },
              "prices" : {
                "token/USDC" : "1"
              },
              "rewards" : {
                "comet_reward/base/0x5678901234567890abcdef1234567890abcdef12/USDC/0x0000000000000000000000000000000000000022/0x00000000000000000000000000000000000a11ce" : {
                  "proof" : {
                    "proof_type" : "none"
                  }
                },
                "morpho_reward/base/USDC/0x0000000000000000000000000000000000000022/0x00000000000000000000000000000000000a11ce" : {
                  "proof" : {
                    "proof" : [
                      "0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff",
                      "0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
                    ],
                    "proof_amount" : "3e8",
                    "proof_type" : "morpho_reward"
                  }
                }
              },
              "solana_transaction_context" : {
                "7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV" : {
                  "durable_nonce_account" : "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
                  "durable_nonce_value" : "F7vmkY3DTaxfagttWjQweib42b6ZHADSx94Tw8gHx3W7",
                  "fee_payer" : "FVen3X669xLzsi6N2V91DoiyzHzg1uAgqiT8jZ9nS96Z"
                }
              },
              "swap_hints" : {
                "swap/base/USDC/WETH/0x/100000000" : {
                  "exchange_rate" : "0.0004",
                  "max_amount" : "100e6",
                  "min_amount" : "0e6"
                },
                "wrapper/base/USDC/base/USDC+" : {
                  "exchange_rate" : "1",
                  "max_amount" : "1000e6",
                  "min_amount" : "100e6"
                }
              },
              "yield_markets" : {
                "aave/base/0x1234567890abcdef1234567890abcdef12345678/USDC" : {
                  "supply_apr" : "0.025",
                  "supply_cap" : null,
                  "supply_rewards_apr" : "0.01",
                  "total_supply" : "1000e6"
                }
              }
            }
            """

        #expect(json == expectedJson)

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Special Characters and Edge Cases

    @Test("Tokens with special characters")
    func tokensWithSpecialChars() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"

        let folio = Folio(
            balances: [
                // Test escaping of forward slashes in token symbols
                .token(network: .base, symbol: "USD/EUR", wallet: wallet.on(.base)): Amount(
                    "1000000",
                    decimals: 6
                )
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        // The token symbol with / should be escaped in the path (with double backslash in JSON)
        #expect(json.contains("token/base/USD\\\\/EUR/0xaabbccddee1234567890abcdef1234567890abcd"))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    @Test("Decoding full Folio")
    func decodingFullFolio() throws {
        let data = try Data(
            contentsOf: URL(fileURLWithPath: "Tests/PreludeTests/example-folio.json")
        )
        let _ = try decoder.decode(Folio.self, from: data)
    }

    @Test("Unknown network encoding")
    func unknownNetwork() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let unknownNetwork = Network.unknown(Number("999999"))

        let folio = Folio(
            balances: [
                .token(network: unknownNetwork, symbol: "TEST", wallet: wallet.on(unknownNetwork)): Amount(
                    "1000000",
                    decimals: 18
                )
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        // Should encode unknown networks with their chain ID
        #expect(json.contains("token/unknown_999999/TEST"))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }
}
