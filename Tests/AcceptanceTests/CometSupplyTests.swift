@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Comet Supply Tests")
struct CometSupplyTests {
    @Test("Alice supplies 0.5 WETH to cUSDCv3 on Ethereum")
    func testCometSupplyWETHTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.0, .weth), .ethereum),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .weth,
                    .cometSupply(
                        from: .alice,
                        market: .cusdcv3,
                        amount: .amt(0.5, .weth),
                        on: .ethereum
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToComet(
                                    tokenAmount: .amt(0.5, .weth),
                                    market: .cusdcv3,
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
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000025e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        price: Number("4000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                        )
                                    )
                                ),
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("0.5e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("4000e8"),
                                        token: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice supplies 0.5 ETH to cUSDCv3 on Ethereum", .disabled())
    func testCometSupplyETHTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.0, .eth), .ethereum),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .eth,
                    .cometSupply(
                        from: .alice,
                        market: .cusdcv3,
                        amount: .amt(0.5, .eth),
                        on: .ethereum
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .supplyToComet(
                                    tokenAmount: .amt(0.5, .eth),
                                    market: .cusdcv3,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .eth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    []
                )
            )
        )
    }

    @Test("Alice supplies, but does not allow enough for quote pay")
    func testCometSupplyInsufficientFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .cometSupply(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(2, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 2000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(2000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies, but cannot cover operation cost")
    func testCometSupplyMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.0, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.0, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .ethereum: 1000,
                                .base: 0.03,
                            ]
                        )
                    ),
                ],
                when: .payWith(
                    currency: .usdc,
                    .cometSupply(
                        from: .alice,
                        market: .cusdcv3,
                        amount: .amt(1, .usdc),
                        on: .ethereum
                    )
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 1000030000))
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed
                expect: .failure(.error("insufficientResources(target: .exact(1000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies to Comet")
    func testSimpleCometSupply() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .cometSupply(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(1, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .supplyToComet(
                                    tokenAmount: .amt(1, .usdc),
                                    market: .cusdcv3,
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
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice supplies max to Comet")
    func testSimpleCometSupplyMax() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .cometSupply(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .max(.usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                // 3 (ethereum balance) - 0.1 (quote pay) = 2.9
                                .supplyToComet(
                                    tokenAmount: .amt(2.9, .usdc),
                                    market: .cusdcv3,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
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
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("2.9e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice supplies max to Comet with bridge")
    func testCometSupplyMaxWithBridgeAndQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .cometSupply(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .max(.usdc),
                    on: .arbitrum
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),  // Base fee
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .arbitrum,
                                    // Max calculation results in slightly less
                                    inputTokenAmount: .amt(49.98, .usdc),
                                    outputTokenAmount: .amt(48.4802, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                // 50 (arbitrum balance) + 48.4802 (bridged from base) - 0.04 (quote pay) = 98.4402
                                .supplyToComet(
                                    tokenAmount: .amt(98.4402, .usdc),
                                    market: .cusdcv3,
                                    cappedMax: true,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
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
                                .bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("8453"),
                                        destinationChainId: Number("42161"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("49.98e6"),
                                        outputAmount: Number("48.4802e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.04e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                        )
                                    )
                                ),
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("98.4402e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        comet: EthAddress(
                                            "0x9c4ec768c28520b50860ea7a15bd7213a9ff58bf"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
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

    @Test("Alice supplies to Comet, paying via Quote Pay")
    func testCometSupplyWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .cometSupply(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(1, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .supplyToComet(
                                    tokenAmount: .amt(1, .usdc),
                                    market: .cusdcv3,
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
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice supplies ETH to Comet after bridging, paying via Quote Pay")
    func testCometSupplyAfterBridgeWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .optimism),
                    .tokenBalance(.alice, .amt(1.5, .eth), .optimism),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .cometSupply(
                    from: .alice,
                    market: .cwethv3,
                    amount: .amt(1, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000015, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .optimism,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(
                                        fromWei: Number("1.020207070707070708e18"),
                                        ofToken: .weth
                                    ),
                                    outputTokenAmount: TokenAmount(
                                        fromWei: Number("1.000005e18"),
                                        ofToken: .weth
                                    ),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToComet(
                                    tokenAmount: .amt(1, .weth),
                                    market: .cwethv3,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("10"),
                                        amount: Number("1.020222070707070708e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000015e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("10"),
                                        price: Number("4000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "WETH",
                                        bridgeType: .across,
                                        chainId: Number("10"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "ETH",
                                        inputAmount: Number("1.020207070707070708e18"),
                                        outputAmount: Number("1.000005e18"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("8453"),
                                        amount: Number("1.000005e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000005e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        price: Number("4000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("1e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        comet: EthAddress(
                                            "0x46e6b214b524310239732d51387075e0e70970bf"
                                        ),
                                        price: Number("4000e8"),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
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
}
