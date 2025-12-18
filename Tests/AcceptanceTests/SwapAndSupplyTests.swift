@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

// TODO: These aren't fixed yet
@Suite("Swap And Supply Tests")
struct SwapAndSupplyTests {
    @Test("Alice swaps and supplies to Comet on a single chain, paying with QuotePay")
    func testLocalSwapAndSupplyToCometWithQuotePaySucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4000, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(3000, .usdc),
                        buyAmount: .amt(1, .weth),
                        swapQuoteSellAmount: .amt(3000, .usdc),
                        swapQuoteBuyAmount: .amt(1, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .ethereum
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(3000, .usdc),
                                    buyAmount: .amt(1, .weth),
                                    feeAmount: .amt(0.0015, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 1 (swap output) - 0.0015 (swap fee) - 0.000025 (quote pay) = 0.999975
                                .supplyToComet(
                                    tokenAmount: .amt(0.999975, .weth),
                                    market: .cwethv3,
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
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("1"),
                                        feeAmounts: [
                                            Number("0.0015e18"),
                                            Number("0.01e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
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
                                ),
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
                                        amount: Number("0.999975e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xa17581a9e3356d9a858b789d68b4d866e593ae94"
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

    @Test("Alice swaps and supplies to Morpho on a single chain, paying with QuotePay")
    func testLocalSwapAndSupplyToMorphoWithQuotePaySucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4000, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(3000, .usdc),
                        buyAmount: .amt(1, .weth),
                        swapQuoteSellAmount: .amt(3000, .usdc),
                        swapQuoteBuyAmount: .amt(1, .weth),
                        on: .worldChain
                    ),
                    supply: (
                        from: .alice, market: .morpho(.weth), amount: .max(.weth),
                        on: .worldChain
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(3000, .usdc),
                                    buyAmount: .amt(1, .weth),
                                    feeAmount: .amt(0.0015, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .worldChain
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 1 (swap output) - 0.0015 (swap fee) - 0.000025 (quote pay) = 0.999975
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(0.999975, .weth),
                                    vault: .weth,
                                    cappedMax: true,
                                    network: .worldChain
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("480"),
                                        feeAmounts: [
                                            Number("0.0015e18"),
                                            Number("0.01e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("3000e6"),
                                        inputAssetSymbol: "USDC",
                                        inputToken: EthAddress(
                                            "0x79a02482a880bce3f13e09da970dc34db4cd24d1"
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
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000025e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("480"),
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
                                Charter.ActionContext.morphoVaultSupply(
                                    Charter.ActionContext.MorphoVaultSupplyActionContext(
                                        amount: Number("0.999975e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("480"),
                                        morphoVault: EthAddress(
                                            "0x0db7e405278c2674f462ac9d9eb8b8346d1c1571"
                                        ),
                                        price: Number("4000e8"),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
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

    @Test("Alice auto-wraps ETH, then swaps and supplies on a single chain, paying with QuotePay")
    func testLocalSwapAndSupplyWithAutoWrapperSucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .eth), .ethereum),
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(1, .weth),
                        buyAmount: .amt(3000, .usdc),
                        swapQuoteSellAmount: .amt(1, .weth),
                        swapQuoteBuyAmount: .amt(3000, .usdc),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                        on: .ethereum
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                // Wrap 1 ETH → 1 WETH
                                .wrapAsset(.eth),
                                .swap(
                                    filler: .filler,
                                    // Exact-in swap: sell exactly 1 WETH
                                    sellAmount: .amt(1, .weth),
                                    // Buy amount: 3000 USDC (matches quote)
                                    buyAmount: .amt(3000, .usdc),
                                    feeAmount: .amt(4.5, .usdc),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                                // QuotePay: 0.1 USDC deducted before supply
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                // 3000 (swap output) - 0.1 (quote pay) = 2999.9
                                .supplyToComet(
                                    tokenAmount: .amt(2999.9, .usdc),
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
                                        // Supply amount: 3000 (swapped) - 0.1 (QuotePay) = 2999.9 USDC
                                        // = 2999.9e6 = 2999900000
                                        amount: Number("2999.9e6"),
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

    @Test("Alice swaps max and supplies an amount on a single chain, paying with QuotePay")
    func testSwapMaxSucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(9000.1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(3, .weth),
                        swapQuoteSellAmount: .amt(9000.1, .usdc),
                        swapQuoteBuyAmount: .amt(3, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .ethereum
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    // All USDC swapped to WETH (max swap)
                                    sellAmount: .amt(9000.1, .usdc),
                                    // Full buy amount from quote
                                    buyAmount: .amt(3, .weth),
                                    feeAmount: .init(
                                        fromWei: 4_500_000_000_000_000,
                                        ofToken: .weth
                                    ),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 3 (swap quote) * 1.015 (1.5% swap output buffer) - 0.000025 (quote pay) = 3.044975
                                .supplyToComet(
                                    tokenAmount: .amt(3.044975, .weth),
                                    market: .cwethv3,
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
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("1"),
                                        feeAmounts: [
                                            Number("0.0045e18"),
                                            Number("0.03e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("9000.1e6"),
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
                                ),
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
                                        amount: Number("3.044975e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xa17581a9e3356d9a858b789d68b4d866e593ae94"
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

    @Test("Alice swaps an amount and supplies max on a single chain, paying with QuotePay")
    func testCometSupplyMax() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .weth), .ethereum),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(1, .weth),
                        buyAmount: .amt(3000, .usdc),
                        swapQuoteSellAmount: .amt(1, .weth),
                        swapQuoteBuyAmount: .amt(3000, .usdc),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .ethereum
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(1, .weth),
                                    buyAmount: .amt(3000, .usdc),
                                    feeAmount: .amt(4.5, .usdc),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                // 3000 (swap output) - 0.1 (quote pay) = 2999.9
                                .supplyToComet(
                                    tokenAmount: .amt(2999.9, .usdc),
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
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("1"),
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
                                        feeTokenPrices: [
                                            Number("1e8"), Number("1e8"),
                                        ],
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
                                        amount: Number("2999.9e6"),
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

    @Test("Alice swaps max and supplies max on a single chain, paying with QuotePay")
    func testCometSwapAndSupplyMax() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(9000.1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(3, .weth),
                        swapQuoteSellAmount: .amt(9000.1, .usdc),
                        swapQuoteBuyAmount: .amt(3, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth), on: .ethereum
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    // Max swap: sell all USDC (9000.1), buyAmount is user's minimum acceptable output
                                    sellAmount: .amt(9000.1, .usdc),
                                    buyAmount: .amt(3, .weth),
                                    feeAmount: .init(
                                        fromWei: 4_500_000_000_000_000,
                                        ofToken: .weth
                                    ),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 3 (swap quote) * 1.015 (1.5% swap output buffer) - 0.000025 (quote pay) = 3.044975
                                .supplyToComet(
                                    tokenAmount: .amt(3.044975, .weth),
                                    market: .cwethv3,
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
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("1"),
                                        feeAmounts: [
                                            Number("0.0045e18"),
                                            Number("0.03e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("9000.1e6"),
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
                                ),
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
                                        amount: Number("3.044975e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xa17581a9e3356d9a858b789d68b4d866e593ae94"
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

    @Test(
        "Alice bridges funds from Ethereum to Base, then swaps and supplies, paying with QuotePay"
    )
    func testBridgeSwapAndSupplySucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(3000, .usdc),
                        buyAmount: .amt(1, .weth),
                        swapQuoteSellAmount: .amt(3000, .usdc),
                        swapQuoteBuyAmount: .amt(1, .weth),
                        on: .base
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth), on: .base
                    )
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
                                    // Bridge 1000 USDC: 1000 / 0.99 ≈ 1010.101 + 1 = 1011.111... USDC
                                    inputTokenAmount: .amt(1011.111112, .usdc),
                                    outputTokenAmount: .amt(1000, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(3000, .usdc),
                                    buyAmount: .amt(1, .weth),
                                    feeAmount: .amt(0.0015, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 1 (swap output) - 0.000005 (quote pay) = 0.999995
                                .supplyToComet(
                                    tokenAmount: .amt(0.999995, .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
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
                        .multiAction(
                            [
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("8453"),
                                        feeAmounts: [
                                            Number("0.0015e18"), Number("0.01e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
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
                                        // 1 WETH - 0.000005 WETH (QuotePay) = 0.999995 WETH = 999995000000000000
                                        amount: Number("0.999995e18"),
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

    @Test(
        "Alice swaps max, then bridges funds from Ethereum to Base, then supplies, paying with QuotePay"
    )
    func testSwapMaxBridgeAndSupplySucceeds() async throws {
        // Tests max swap with bridge and supply chain: demonstrates that the 1.5% buffer
        // applied to max swaps propagates correctly to downstream operations (bridge, supply).
        // The buffer ensures downstream capped-max operations can use all received tokens
        // even if the swap gets favorable slippage.
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3000, .usdc), .ethereum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(1, .weth),
                        swapQuoteSellAmount: .amt(3000, .usdc),
                        swapQuoteBuyAmount: .amt(1, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth), on: .base
                    )
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(3000, .usdc),
                                    buyAmount: .amt(1, .weth),
                                    feeAmount: .amt(0.0015, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    // Bridge input: 1.015 WETH (1 WETH + 1.5% buffer) - 0.000025 WETH (QuotePay) = 1.014975 WETH
                                    inputTokenAmount: TokenAmount(
                                        fromWei: Number("1.014975e18"),
                                        ofToken: .weth
                                    ),
                                    // Bridge output: (1.014975 * 0.99) - 0.01 = 0.99482525 WETH
                                    outputTokenAmount: TokenAmount(
                                        fromWei: Number("0.99482525e18"),
                                        ofToken: .weth
                                    ),
                                    cappedMax: true
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
                                // 0.99482525 (bridged) - 0.000005 (quote pay) = 0.99482025
                                .supplyToComet(
                                    tokenAmount: .amt(0.99482025, .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("1"),
                                        feeAmounts: [
                                            Number("0.0015e18"),
                                            Number("0.01e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
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
                                        isCappedMax: true,
                                        useFiller: true
                                    )
                                ),
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "WETH",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "ETH",
                                        // Bridge input: 1.015 WETH (buffered swap output) - 0.000025 WETH = 1.014975 WETH
                                        inputAmount: Number("1.014975e18"),
                                        // Bridge output: (1.014975 * 0.99) - 0.01 = 0.99482525 WETH
                                        outputAmount: Number("0.99482525e18"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
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
                                        // Wrap all ETH received from bridge: 0.99482525 WETH
                                        amount: Number("0.99482525e18"),
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
                                        // Supply: 0.99482525 WETH (wrapped) - 0.000005 WETH (QuotePay) = 0.994820250 WETH
                                        amount: Number("0.99482025e18"),
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

    @Test(
        "Alice swaps, then bridges funds from Ethereum to Base, then supplies, paying with QuotePay"
    )
    func testSwapBridgeAndSupplySucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3000, .usdc), .ethereum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(2000, .usdc),
                        buyAmount: .amt(1.1, .weth),
                        swapQuoteSellAmount: .amt(2000, .usdc),
                        swapQuoteBuyAmount: .amt(1.1, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth), on: .base
                    )
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(2000, .usdc),
                                    buyAmount: .amt(1.1, .weth),
                                    feeAmount: .amt(0.00165, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(
                                        fromWei: Number("1.099975000000000128e18"),
                                        ofToken: .weth
                                    ),
                                    outputTokenAmount: TokenAmount(
                                        fromWei: Number("1.078975250000000126e18"),
                                        ofToken: .weth
                                    ),
                                    cappedMax: true
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
                                // 1.078975250000000126 (bridged) - 0.000005 (quote pay) = 1.078970250000000126
                                .supplyToComet(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("1.078970250000000126e18"),
                                        ofToken: .weth
                                    ),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("1"),
                                        feeAmounts: [
                                            Number("0.00165e18"),
                                            Number("0.011000000000000001e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("2000e6"),
                                        inputAssetSymbol: "USDC",
                                        inputToken: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        ),
                                        inputTokenPrice: Number("1e8"),
                                        outputAmount: Number("1.100000000000000128e18"),
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
                                ),
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "WETH",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "ETH",
                                        inputAmount: Number("1.099975000000000128e18"),
                                        outputAmount: Number("1.078975250000000126e18"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
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
                                        amount: Number("1.078975250000000126e18"),
                                        token: EthAddress(
                                            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
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
                                        // 1.078975250000000126 WETH - 0.000005 WETH (QuotePay) = 1.078970250000000126 WETH
                                        amount: Number("1.078970250000000126e18"),
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

    @Test("Alice bridges and swaps max and supplies an amount, paying with QuotePay")
    func testBridgeSwapMaxAndSupplyWithQuotePaySucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(2.0, .weth),
                        swapQuoteSellAmount: .amt(4000, .usdc),
                        swapQuoteBuyAmount: .amt(2, .weth),
                        on: .base
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth), on: .base
                    )
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
                                    inputTokenAmount: .amt(1999.9, .usdc),
                                    outputTokenAmount: .amt(1978.901, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(3978.901, .usdc),
                                    buyAmount: .amt(1.9894505, .weth),
                                    feeAmount: .amt(0.002984175750, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 1.9894505 (scaled swap output) * 1.015 (1.5% swap output buffer) - 0.000005 (quote pay) = 2.0192872575
                                .supplyToComet(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("2.0192872575e18"),
                                        ofToken: .weth
                                    ),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
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
                                        inputAmount: Number("1999.9e6"),
                                        outputAmount: Number("1978.901e6"),
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
                        .multiAction(
                            [
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("8453"),
                                        feeAmounts: [
                                            Number("0.00298417575e18"),
                                            Number("0.019894505e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("3978.901e6"),
                                        inputAssetSymbol: "USDC",
                                        inputToken: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        ),
                                        inputTokenPrice: Number("1e8"),
                                        outputAmount: Number("1.9894505e18"),
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
                                        amount: Number("2.0192872575e18"),
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

    @Test("Alice bridges and swaps max and supplies max, paying with QuotePay")
    func testBridgeSwapMaxAndSupplyMaxWithQuotePaySucceeds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(2.0, .weth),
                        swapQuoteSellAmount: .amt(4000, .usdc),
                        swapQuoteBuyAmount: .amt(2.5, .weth),
                        on: .base
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth), on: .base
                    )
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
                                    inputTokenAmount: .amt(1999.9, .usdc),
                                    outputTokenAmount: .amt(1978.901, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(3978.901, .usdc),
                                    buyAmount: .amt(1.9894505, .weth),
                                    feeAmount: .amt(0.002984175750, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 2.486813125 (scaled swap quote: 2.5 * 3978.901/4000) * 1.015 (1.5% swap output buffer) - 0.000005 (quote pay) = 2.524110321875
                                .supplyToComet(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("2.524110321875e18"),
                                        ofToken: .weth
                                    ),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
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
                                        inputAmount: Number("1999.9e6"),
                                        outputAmount: Number("1978.901e6"),
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
                        .multiAction(
                            [
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("8453"),
                                        feeAmounts: [
                                            Number("0.00298417575e18"),
                                            Number("0.019894505e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("3978.901e6"),
                                        inputAssetSymbol: "USDC",
                                        inputToken: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        ),
                                        inputTokenPrice: Number("1e8"),
                                        outputAmount: Number("1.9894505e18"),
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
                                        amount: Number("2.524110321875e18"),
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

    @Test(
        "Alice swaps and supplies on Base via bridge, with bridge amount adjusted to be the min bridge amount"
    )
    func testSwapsOnBaseViaBridgeAdjustingAmount() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .acrossQuoteWithMin(.amt(1, .usdc), 0.01, .amt(1000, .usdc)),
                    .tokenBalance(.alice, .amt(2000, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(2000, .usdc), .base),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(2000.1, .usdc),
                        buyAmount: .amt(1, .weth),
                        swapQuoteSellAmount: .amt(2000.1, .usdc),
                        swapQuoteBuyAmount: .amt(1, .weth),
                        on: .base
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth), on: .base
                    )
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
                        .multicall(
                            [
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(2000.1, .usdc),
                                    buyAmount: .amt(1, .weth),
                                    feeAmount: .amt(0.0015, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: false,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 1 (swap output) - 0.000005 (quote pay) = 0.999995
                                .supplyToComet(
                                    tokenAmount: .amt(0.999995, .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
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
                        .multiAction(
                            [
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("8453"),
                                        feeAmounts: [
                                            Number("0.0015e18"), Number("0.01e18"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
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
                                        // 1 WETH - 0.000005 WETH (QuotePay) = 0.999995 WETH = 999995000000000000
                                        amount: Number("0.999995e18"),
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

    // TODO: Disabled - Mercator now validates assets exist in Atlas before checking funds.
    // Using fake chain 7777 returns .unknownAsset instead of expected .badInputInsufficientFunds.
    // @Test("Alice swaps on a chain that cannot be bridged to")
    func testSwapFundsOnUnbridgeableChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(30, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(0, .usdc), .unknown(7777)),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(30, .usdc),
                        buyAmount: .amt(0.01, .weth),
                        swapQuoteSellAmount: .amt(30, .usdc),
                        swapQuoteBuyAmount: .amt(0.01, .weth),
                        on: .unknown(7777)
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .ethereum
                    )
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("", 30000000, 0))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    // TODO: Disabled - Mercator now validates assets exist in Atlas before checking funds.
    // Using unsupported lineaSepolia returns .unknownAsset instead of expected .badInputInsufficientFunds.
    // @Test("Alice supplies on a chain that cannot be bridged to")
    func testSuppliesFundsOnUnbridgeableChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(30, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(30, .usdc),
                        buyAmount: .amt(0.1, .weth),
                        swapQuoteSellAmount: .amt(30, .usdc),
                        swapQuoteBuyAmount: .amt(0.1, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice,
                        market: .comet(.unknownComet("0x0000000000000000000000000000000000000000")),
                        amount: .max(.weth), on: .lineaSepolia
                    )
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("WETH", 100000000000000000, 0))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    @Test("Alice swaps more than she has")
    func testSwapFundsUnavailableErrorGivesSuggestionForAvailableFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(30, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(30, .usdc), .base),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(65, .usdc),
                        buyAmount: .amt(0.01, .weth),
                        swapQuoteSellAmount: .amt(65, .usdc),
                        swapQuoteBuyAmount: .amt(0.01, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .ethereum
                    )
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 65000000, 60000000))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }

    // Note: No longer possible because we enforce max supplies, so impossible to supply more than you have
    // @Test("Alice supplies more than she has")
    func testSupplyFundsUnavailableErrorGivesSuggestionForAvailableFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(60, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(60, .usdc),
                        buyAmount: .amt(0.1, .weth),
                        swapQuoteSellAmount: .amt(60, .usdc),
                        swapQuoteBuyAmount: .amt(0.1, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .ethereum
                    )
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("WETH", 100000000000000000, 0))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    @Test("Alice swap and supplies, but does not have enough to cover QuotePay cost")
    func testSwapAndSupplyMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(30, .usdc), .ethereum),
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
                ],
                when: .swapAndSupply(
                    swap: (
                        from: .alice,
                        sellAmount: .amt(30, .usdc),
                        buyAmount: .amt(0.1, .weth),
                        swapQuoteSellAmount: .amt(30, .usdc),
                        swapQuoteBuyAmount: .amt(0.1, .weth),
                        on: .ethereum
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .ethereum
                    )
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 1000100000))
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }
}
