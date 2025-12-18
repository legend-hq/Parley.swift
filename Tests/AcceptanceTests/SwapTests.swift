@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

// TODO: These have a lot of issues re: max
@Suite("Swap Tests")
struct SwapTests {
    @Test(
        "Alice bridges max and swaps with quote pay",
        .disabled("this is failing to figure out the max part?")
    )
    func testBridgeSwapMaxWithQuotePaySucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4005.1, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(4005.1, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .max(.usdc),
                    buyAmount: .amt(2.0, .weth),
                    swapQuoteSellAmount: .amt(8010, .usdc),
                    swapQuoteBuyAmount: .amt(2, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            // 4005 * 1.001 (max amt buffer) = 4009.005
                            inputTokenAmount: .amt(4009.005, .usdc),
                            outputTokenAmount: .amt(3963.95, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.12, .usdc), payee: .stax, quote: .basic),
                                .swap(
                                    filler: .filler,
                                    // Subtract 0.12 USDC to be used for the QuotePay
                                    // +0.1% to account for cappedMax buffer
                                    // = (4005 + 3963.95 - 0.12) * 1.001
                                    sellAmount: .amt(7_976.79883, .usdc),
                                    // New buy amount = total available balance / total balance * buy amount
                                    // = (4005 + 3963.95 - 0.12) / 8010 * 2
                                    buyAmount: .init(
                                        fromWei: 1_989_720_349_563_046_192,
                                        ofToken: .weth
                                    ),
                                    // Fee = buyAmount * 0.15% = 1_989_720_349_563_046_192 * 0.0015
                                    feeAmount: .init(
                                        fromWei: 2_984_580_524_344_569,
                                        ofToken: .weth
                                    ),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("1"),
                                destinationChainId: Number("8453"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("4005e6"),
                                outputAmount: Number("3963.95e6"),
                                price: Number("1e8"),
                                recipient: EthAddress("0x00000000000000000000000000000000000a11ce"),
                                token: EthAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
                            )
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.12e6"),
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
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("8453"),
                                        feeAmounts: [Number("0.019897203495630461e18")],
                                        feeAssetSymbols: ["WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            )
                                        ],
                                        feeTokenPrices: [Number("4000e8")],
                                        feeDescriptions: ["Legend Fee"],
                                        inputAmount: Number("7968.83e6"),
                                        inputAssetSymbol: "USDC",
                                        inputToken: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        ),
                                        inputTokenPrice: Number("1e8"),
                                        outputAmount: Number("1.989720349563046192e18"),
                                        outputAssetSymbol: "WETH",
                                        outputToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        outputTokenPrice: Number("4000e8"),
                                        isExactOut: false,
                                        isBuy: true,
                                        isCappedMax: true,
                                        useFiller: true
                                    )
                                ),
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice swaps an amount she does not have")
    func testSwapInsufficientFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(3000, .usdc),
                    buyAmount: .amt(1, .weth),
                    swapQuoteSellAmount: .amt(3000, .usdc),
                    swapQuoteBuyAmount: .amt(1, .weth),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 3000000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }

    @Test(
        "Alice swaps, but does not have enough to cover QuotePay cost",
        .disabled("fee asset not supported!")
    )
    func testSwapMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
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
                            fees: [.ethereum: 1000, .base: 0.1]
                        )
                    ),
                    .tokenBalance(.alice, .amt(30, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(30, .usdc), .base),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(30, .usdc),
                    buyAmount: .amt(0.01, .weth),
                    swapQuoteSellAmount: .amt(30, .usdc),
                    swapQuoteBuyAmount: .amt(0.01, .weth),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 1000.1))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    // TODO: Disabled - Mercator now validates assets exist in Atlas before checking funds.
    // Using fake chain 7777 returns .unknownAsset instead of expected .badInputInsufficientFunds.
    // @Test("Alice swaps on a chain that cannot be bridged to")
    func testSwapFundsOnUnbridgeableChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .tokenBalance(.alice, .amt(30, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(30, .usdc), .base),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(30, .usdc),
                    buyAmount: .amt(0.01, .weth),
                    swapQuoteSellAmount: .amt(30, .usdc),
                    swapQuoteBuyAmount: .amt(0.01, .weth),
                    on: .unknown(7777)
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("", 30000000, 0))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    @Test("Alice swaps with insufficient funds across multiple chains")
    func testSwapInsufficientFundsAcrossChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
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
                                .ethereum: 3,
                                .base: 0.1,
                                .unknown(7777): 0.1,
                            ]
                        )
                    ),
                    .tokenBalance(.alice, .amt(30, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(30, .usdc), .base),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(65, .usdc),
                    buyAmount: .amt(0.01, .weth),
                    swapQuoteSellAmount: .amt(65, .usdc),
                    swapQuoteBuyAmount: .amt(0.01, .weth),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 65000000, 60000000))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }

    @Test("Alice swaps on a single chain")
    func testLocalSwapSucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4000, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(3000, .usdc),
                    buyAmount: .amt(1, .weth),
                    swapQuoteSellAmount: .amt(3000, .usdc),
                    swapQuoteBuyAmount: .amt(1, .weth),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(3000, .usdc),
                            buyAmount: .amt(1, .weth),
                            feeAmount: .amt(0.0015, .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .ethereum,
                            executionType: .immediate
                        )
                    ),
                    [
                        .swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("1"),
                                feeAmounts: [
                                    Number("0.0015e18"), Number("0.01e18"),
                                ],
                                feeAssetSymbols: ["WETH", "WETH"],
                                feeTokens: [
                                    EthAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"),
                                    EthAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"),
                                ],
                                feeTokenPrices: [Number("4000e8"), Number("4000e8")],
                                feeDescriptions: ["LEGEND", "ZERO_EX"],
                                inputAmount: Number("3000e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress(
                                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                ),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("1e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress(
                                    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                ),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: false,
                                useFiller: true
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice swaps, wrapping ETH to WETH")
    func testLocalSwapWithAutoWrapperSucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .eth), .ethereum),
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(1, .weth),
                    buyAmount: .amt(3000, .usdc),
                    swapQuoteSellAmount: .amt(1, .weth),
                    swapQuoteBuyAmount: .amt(3000, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(1, .weth),
                                    buyAmount: .amt(3000, .usdc),
                                    feeAmount: .amt(4.5, .usdc),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("1"),
                                        amount: Number("1e18"),
                                        token: EthAddress(
                                            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
                                    )
                                ),
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("1"),
                                        // Fees are embedded in the swap
                                        feeAmounts: [Number("4.5e6"), Number("30e6")],
                                        feeAssetSymbols: ["USDC", "USDC"],
                                        feeTokens: [
                                            EthAddress(
                                                "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                            ),
                                            EthAddress(
                                                "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                            ),
                                        ],
                                        feeTokenPrices: [Number("1e8"), Number("1e8")],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("1e18"),
                                        inputAssetSymbol: "WETH",
                                        inputToken: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                        ),
                                        inputTokenPrice: Number("4000e8"),
                                        outputAmount: Number("3000e6"),
                                        outputAssetSymbol: "USDC",
                                        outputToken: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        ),
                                        outputTokenPrice: Number("1e8"),
                                        isExactOut: false,
                                        isBuy: true,
                                        isCappedMax: false,
                                        useFiller: true
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice swaps, paying with QuotePay")
    func testLocalSwapWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3005, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3005, .usdc), .base),
                    .quote(.basic),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(3000, .usdc),
                    buyAmount: .amt(1, .weth),
                    swapQuoteSellAmount: .amt(3000, .usdc),
                    swapQuoteBuyAmount: .amt(1, .weth),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(3000, .usdc),
                            buyAmount: .amt(1, .weth),
                            feeAmount: .amt(0.0015, .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .ethereum,
                            executionType: .immediate
                        )
                    ),
                    [
                        .swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("1"),
                                feeAmounts: [
                                    Number("0.0015e18"), Number("0.01e18"),
                                ],
                                feeAssetSymbols: ["WETH", "WETH"],
                                feeTokens: [
                                    EthAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"),
                                    EthAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"),
                                ],
                                feeTokenPrices: [Number("4000e8"), Number("4000e8")],
                                feeDescriptions: ["LEGEND", "ZERO_EX"],
                                inputAmount: Number("3000e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress(
                                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                ),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("1e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress(
                                    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                ),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: false,
                                useFiller: true
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice swaps max")
    func testSwapMaxSucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(9005, .usdc), .ethereum),
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
                            fees: [.ethereum: 5]
                        )
                    ),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .max(.usdc),
                    buyAmount: .amt(3, .weth),
                    swapQuoteSellAmount: .amt(9005, .usdc),
                    swapQuoteBuyAmount: .amt(3, .weth),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(9005, .usdc),
                            buyAmount: .amt(3, .weth),
                            feeAmount: .init(fromWei: 4_500_000_000_000_000, ofToken: .weth),
                            feeRecipient: .stax,
                            cappedMax: true,
                            network: .ethereum,
                            executionType: .immediate
                        )
                    ),
                    [
                        .swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("1"),
                                feeAmounts: [Number("0.0045e18"), Number("0.03e18")],
                                feeAssetSymbols: ["WETH", "WETH"],
                                feeTokens: [
                                    EthAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"),
                                    EthAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"),
                                ],
                                feeTokenPrices: [Number("4000e8"), Number("4000e8")],
                                feeDescriptions: ["LEGEND", "ZERO_EX"],
                                inputAmount: Number("9005e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress(
                                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                ),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("3e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress(
                                    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                ),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: true,
                                useFiller: true
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice swaps, bridging funds from Ethereum to Base")
    func testBridgeSwapSucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(3000, .usdc),
                    buyAmount: .amt(1, .weth),
                    swapQuoteSellAmount: .amt(3000, .usdc),
                    swapQuoteBuyAmount: .amt(1, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    // Adjusted for Across fees
                                    inputTokenAmount: .amt(1011.111112, .usdc),
                                    outputTokenAmount: .amt(1000, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(3000, .usdc),
                            buyAmount: .amt(1, .weth),
                            feeAmount: .amt(0.0015, .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .base,
                            executionType: .contingent
                        ),
                    ]),
                    [
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("1011.111112e6"),
                                        outputAmount: Number("1000e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("8453"),
                                feeAmounts: [
                                    Number("0.0015e18"), Number("0.01e18"),
                                ],
                                feeAssetSymbols: ["WETH", "WETH"],
                                feeTokens: [
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                ],
                                feeTokenPrices: [Number("4000e8"), Number("4000e8")],
                                feeDescriptions: ["LEGEND", "ZERO_EX"],
                                inputAmount: Number("3000e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                ),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("1e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress(
                                    "0x4200000000000000000000000000000000000006"
                                ),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: false,
                                useFiller: true
                            )
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice swaps, bridging funds from Ethereum to Base, paying with QuotePay")
    func testBridgeSwapWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
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
                                .ethereum: 5,
                                .base: 1,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(3000, .usdc),
                    buyAmount: .amt(1, .weth),
                    swapQuoteSellAmount: .amt(3000, .usdc),
                    swapQuoteBuyAmount: .amt(1, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(5, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(1011.111112, .usdc),
                                    outputTokenAmount: .amt(1000, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(3000, .usdc),
                            buyAmount: .amt(1, .weth),
                            feeAmount: .amt(0.0015, .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .base,
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("5e6"),
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("1011.111112e6"),
                                        outputAmount: Number("1000e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("8453"),
                                feeAmounts: [
                                    Number("0.0015e18"), Number("0.01e18"),
                                ],
                                feeAssetSymbols: ["WETH", "WETH"],
                                feeTokens: [
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                ],
                                feeTokenPrices: [Number("4000e8"), Number("4000e8")],
                                feeDescriptions: ["LEGEND", "ZERO_EX"],
                                inputAmount: Number("3000e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                ),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("1e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress(
                                    "0x4200000000000000000000000000000000000006"
                                ),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: false,
                                useFiller: true
                            )
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice swaps max on Base via Bridge, but some funds are unbridgeable")
    func testSwapMaxViaBridgeWithSomeUnbridgeableFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .acrossQuoteWithMin(.amt(1, .usdc), 0.01, .amt(3000, .usdc)),
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .max(.usdc),
                    buyAmount: .amt(1, .weth),
                    swapQuoteSellAmount: .amt(4000, .usdc),
                    swapQuoteBuyAmount: .amt(1, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(2000, .usdc),
                            buyAmount: .amt(0.5, .weth),
                            feeAmount: .amt(0.00075, .weth),
                            feeRecipient: .stax,
                            cappedMax: true,
                            network: .base,
                            executionType: .immediate
                        )
                    ),
                    [
                        .swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("8453"),
                                feeAmounts: [Number("0.00075e18"), Number("0.005e18")],
                                feeAssetSymbols: ["WETH", "WETH"],
                                feeTokens: [
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                ],
                                feeTokenPrices: [Number("4000e8"), Number("4000e8")],
                                feeDescriptions: ["LEGEND", "ZERO_EX"],
                                inputAmount: Number("2000e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                ),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("0.5e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress(
                                    "0x4200000000000000000000000000000000000006"
                                ),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: true,
                                useFiller: true
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice swaps on Base via Bridge, with bridge amount adjusted to be the min bridge amount")
    func testSwapsOnBaseViaBridgeAdjustingAmount() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .acrossQuoteWithMin(.amt(1, .usdc), 0.01, .amt(1000, .usdc)),
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                ],
                when: .swap(
                    from: .alice,
                    sellAmount: .amt(2000.1, .usdc),
                    buyAmount: .amt(1, .weth),
                    swapQuoteSellAmount: .amt(2000.1, .usdc),
                    swapQuoteBuyAmount: .amt(1, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    // Bridge adjusted to min input constraint (1000 USDC)
                                    // Output: (1000 * 0.99 rate) - 1 fixed cost = 989.00 USDC
                                    inputTokenAmount: .amt(1000, .usdc),
                                    outputTokenAmount: .amt(989, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(2000.1, .usdc),
                            buyAmount: .amt(1, .weth),
                            feeAmount: .amt(0.0015, .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .base,
                            executionType: .contingent
                        ),
                    ]),
                    [
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("1000e6"),
                                        outputAmount: Number("989e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("8453"),
                                feeAmounts: [
                                    Number("0.0015e18"), Number("0.01e18"),
                                ],
                                feeAssetSymbols: ["WETH", "WETH"],
                                feeTokens: [
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                    EthAddress("0x4200000000000000000000000000000000000006"),
                                ],
                                feeTokenPrices: [Number("4000e8"), Number("4000e8")],
                                feeDescriptions: ["LEGEND", "ZERO_EX"],
                                inputAmount: Number("2000.1e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                ),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("1e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress(
                                    "0x4200000000000000000000000000000000000006"
                                ),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: false,
                                useFiller: true
                            )
                        ),
                    ]
                )
            )
        )
    }
}
