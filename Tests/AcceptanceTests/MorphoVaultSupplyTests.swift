@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Morpho Vault Supply Tests")
struct MorphoVaultSupplyTests {
    @Test("Alice supplies max with bridge and QuotePay")
    func testMorphoVaultSupplyMaxWithBridgeAndQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3.0, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3.0, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .max(.usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            // 3 (no quote pay on source chain)
                            inputTokenAmount: .amt(3, .usdc),
                            outputTokenAmount: .amt(1.97, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                // 3 (base balance) + 1.97 (bridged) - 0.02 (quote pay) = 4.95
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(4.95, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        Charter.ActionContext.bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("1"),
                                destinationChainId: Number("8453"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("3e6"),
                                outputAmount: Number("1.97e6"),
                                price: Number("1e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                )
                            )
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.02e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                                Charter.ActionContext.morphoVaultSupply(
                                    Charter.ActionContext.MorphoVaultSupplyActionContext(
                                        amount: Number("4.95e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        morphoVault: EthAddress(
                                            "0xc1256ae5ff1cf2719d4937adb3bbccab2e00a2ca"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice supplies max on base, bridging usdc from arbitrum, paying QuotePay with Degen")
    func testMorphoVaultSupplyMaxWithDegenQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3.0, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(3.0, .usdc), .base),
                    .tokenBalance(.alice, .amt(20.0, .degen), .base),
                    .quote(
                        .custom(
                            quoteId:
                                "0x00000000000000000000000000000000000000000000000000000000000000CC",
                            prices: [
                                .degen: 0.01
                            ],
                            fees: [
                                .base: 0.02,
                                .arbitrum: 0.04,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .payWith(
                    currency: .degen,
                    .morphoVaultSupply(from: .alice, vault: .usdc, amount: .max(.usdc), on: .base)
                ),
                // Note: Cross-currency quote pay (DEGEN for USDC) is no longer supported in the new system
                // The system will execute without quote pay since it can't pay with DEGEN for USDC operations
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .arbitrum,
                            destinationNetwork: .base,
                            // 3 (no quote pay in this flow)
                            inputTokenAmount: .amt(3.0, .usdc),  // System calculates without quote pay
                            outputTokenAmount: .amt(1.97, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        // 3 (base balance) + 1.97 (bridged) = 4.97
                        .supplyToMorphoVault(
                            tokenAmount: .amt(4.97, .usdc),
                            vault: .usdc,
                            cappedMax: true,
                            network: .base,
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice supplies to MorphoVault more than she has")
    func testMorphoSupplyInsufficientFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(2, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 2000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(2000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies to MorphoVault, but the operation cost is too high")
    func testMorphoSupplyMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: Dictionary(
                                uniqueKeysWithValues: Token.knownCases.map { token in
                                    (token, token.defaultUsdPrice)
                                }
                            ),
                            fees: [
                                .ethereum: 1000,
                                .base: 0.1,
                            ]
                        )
                    ),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(1, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 1000100000))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(1000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies to MorphoVault, but her funds are on an unreachable chain (7777)")
    func testMorphoSupplyFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(0, .usdc), .base),
                    .tokenBalance(.alice, .amt(100, .usdc), .unknown(7777)),
                    .quote(.basic),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(2, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 2000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(2000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies to MorphoVault, paying with QuotePay")
    func testSimpleMorphoVaultSupply() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(1, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(1, .usdc),
                                    vault: .usdc,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice supplies max to MorphoVault")
    func testSimpleMorphoVaultSupplyMax() async throws {
        /*
         +1.5 on Ethereum
         +1.5 on Base
         -1 for Across gasFee
         -(1.5 * .01) for Across pctFee
         -0.1 (Eth operation fee, destination)
         = 1.885 USDC supplied
         */

        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .max(.usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .ethereum,
                            // 1.5 (no quote pay on source chain)
                            inputTokenAmount: .amt(1.5, .usdc),
                            outputTokenAmount: .amt(0.485, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),  // Ethereum fee
                                // 1.5 (ethereum balance) + 0.485 (bridged) - 0.1 (quote pay) = 1.885
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(1.885, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        Charter.ActionContext.bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("8453"),
                                destinationChainId: Number("1"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("1.5e6"),
                                outputAmount: Number("485000"),
                                price: Number("1e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                )
                            )
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                                Charter.ActionContext.morphoVaultSupply(
                                    Charter.ActionContext.MorphoVaultSupplyActionContext(
                                        amount: Number("1885000"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice supplies to MorphoVault, paying with QuotePay")
    func testMorphoVaultSupplyWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(1, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(1, .usdc),
                                    vault: .usdc,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice supplies to MorphoVault, bridging funds from Ethereum to Base")
    func testMorphoVaultSupplyWithBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(5, .usdc),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            inputTokenAmount: .amt(3.050506, .usdc),
                            outputTokenAmount: .amt(2.02, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),  // Base fee
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(5, .usdc),
                                    vault: .usdc,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice supplies max to MorphoVault, bridging funds")
    func testMorphoVaultSupplyMaxWithBridge() async throws {
        /*
         +3 on Base
         +3 on Ethereum
         -1 for Across gas fee
         -(3 * 0.01) for Across pct fee
         -0.02 for Base operation fee (destination)
         = 4.95 USDC supplied to MorphoVault
         */

        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .max(.usdc),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            // 3 (no quote pay on source chain)
                            inputTokenAmount: .amt(3, .usdc),
                            outputTokenAmount: .amt(1.97, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),  // Base fee
                                // 3 (base balance) + 1.97 (bridged) - 0.02 (quote pay) = 4.95
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(4.95, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice supplies max to MorphoVault, bridging funds and paying with QuotePay")
    func testMorphoVaultSupplyMaxWithBridgeAndQuotePayAndCustomQuoteTest() async throws {
        /*
         +3 on Ethereum
         +3 on Base
         -1 for Across gas fee
         -(3 * .01) for Across pct fee
         -0.1 for Base operation fee (destination)
         = 4.87 USDC supplied
         */

        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: Dictionary(
                                uniqueKeysWithValues: Token.knownCases.map { token in
                                    (token, token.defaultUsdPrice)
                                }
                            ),
                            fees: [
                                .ethereum: 0.5,
                                .base: 0.1,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .max(.usdc),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            // 3 (no quote pay on source chain)
                            inputTokenAmount: .amt(3, .usdc),
                            outputTokenAmount: .amt(1.97, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                // 3 (base balance) + 1.97 (bridged) - 0.1 (quote pay) = 4.87
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(4.87, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice supplies to MorphoVault, bridging funds and paying with QuotePay")
    func testMorphoVaultSupplyWithBridgeAndQuotePayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: Dictionary(
                                uniqueKeysWithValues: Token.knownCases.map { token in
                                    (token, token.defaultUsdPrice)
                                }
                            ),
                            fees: [
                                .ethereum: 0.5,
                                .base: 0.1,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .morphoVaultSupply(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(5, .usdc),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            inputTokenAmount: .amt(3.131314, .usdc),
                            outputTokenAmount: .amt(2.1, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),  // Base fee
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(5, .usdc),
                                    vault: .usdc,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }
}
