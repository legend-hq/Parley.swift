@preconcurrency import Eth
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Comet Repay Tests")
struct CometRepayTests {
    @Test("Alice repays 1 USDC after supplying 1 COMP")
    func testCometRepayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(2, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(1, .usdc), .cusdcv3, .ethereum),
                    .cometSupply(.alice, .amt(1, .comp), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .amt(1, .usdc),
                    collateralAmounts: [.amt(1, .comp)],
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(1, .usdc),
                                    collateralAmounts: [.amt(1, .comp)],
                                    market: .cusdcv3,
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("1e18")],
                                        collateralAssetSymbols: ["COMP"],
                                        collateralTokenPrices: [Number("40e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xc00e94cb662c3520282e6f5717214004a7f26888"
                                            )
                                        ],
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

    @Test("Alice withdraws collateral only without repaying")
    func testCometWithdrawCollateralOnly() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(1, .usdc), .cusdcv3, .ethereum),
                    .cometCollateral(.alice, .amt(1.0025, .comp), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .amt(0, .usdc),
                    collateralAmounts: [.amt(1, .comp)],
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(0, .usdc),
                                    collateralAmounts: [.amt(1.0025, .comp)],
                                    market: .cusdcv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.0025, .comp),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("0"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("1.0025e18")],
                                        collateralAssetSymbols: ["COMP"],
                                        collateralTokenPrices: [Number("40e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xc00e94cb662c3520282e6f5717214004a7f26888"
                                            )
                                        ],
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.0025e18"),
                                        assetSymbol: "COMP",
                                        chainId: Number("1"),
                                        price: Number("40e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xc00e94cb662c3520282e6f5717214004a7f26888"
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

    @Test("Alice tries to repay with insufficient funds")
    func testCometRepayFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .amt(1, .usdc),
                    collateralAmounts: [],
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 1000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no resources are available
                expect: .failure(.error("insufficientResources(target: .exact(1000000), max: 0)"))
            )
        )
    }

    @Test("Alice repays WETH with insufficient USDC")
    func testCometRepayNotEnoughPaymentToken() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.4, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1, .weth), .ethereum),
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
                            fees: [.ethereum: 0.5]
                        )
                    ),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cwethv3,
                    repayAmount: .amt(1, .weth),
                    collateralAmounts: [],
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 500000))
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed
                expect: .failure(
                    .error(
                        "insufficientResources(target: .exact(1000000000000000000), max: 999875000000000000)"
                    )
                )
            )
        )
    }

    @Test("Alice repays with auto-wrapped ETH")
    func testCometRepayWithAutoWrapper() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.1, .eth), .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cwethv3,
                    repayAmount: .amt(1, .weth),
                    collateralAmounts: [.amt(1, .comp)],
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(1, .weth),
                                    collateralAmounts: [.amt(1, .comp)],
                                    market: .cwethv3,
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
                                        amount: Number("1.000025e18"),
                                        token: Token.eth.address(network: .ethereum)!,
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("1e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("1e18")],
                                        collateralAssetSymbols: ["COMP"],
                                        collateralTokenPrices: [Number("40e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xc00e94cb662c3520282e6f5717214004a7f26888"
                                            )
                                        ],
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

    @Test("Alice repays and pays from withdrawn collateral")
    func testCometRepayPayFromWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.1, .weth), .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cwethv3,
                    repayAmount: .amt(1, .weth),
                    collateralAmounts: [.amt(1, .usdc)],
                    on: .ethereum
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
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(1, .weth),
                                    collateralAmounts: [.amt(1, .usdc)],
                                    market: .cwethv3,
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("1e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("1e6")],
                                        collateralAssetSymbols: ["USDC"],
                                        collateralTokenPrices: [Number("1e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                            )
                                        ],
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

    @Test("Alice repays max USDC and pays with QuotePay")
    func testCometRepayMaxWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(10, .usdc), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .max(.usdc),
                    collateralAmounts: [],
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    // User has sufficient funds (50 USDC > 10.1001 USDC required), using uint256.max for true max repay
                                    repayAmount: .max(.usdc),
                                    collateralAmounts: [],
                                    market: .cusdcv3,
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("10.0001e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmounts: [],
                                        collateralAssetSymbols: [],
                                        collateralTokenPrices: [],
                                        collateralTokens: [],
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

    @Test("Alice repays max balance USDC with QuotePay")
    func testCometRepayMaxBalanceWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(50, .usdc), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .max(.usdc),
                    collateralAmounts: [],
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    // 10 USDC available - 0.1 USDC quote fee = 9.9 USDC repay
                                    repayAmount: .amt(9.9, .usdc),
                                    collateralAmounts: [],
                                    market: .cusdcv3,
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("9.9e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmounts: [],
                                        collateralAssetSymbols: [],
                                        collateralTokenPrices: [],
                                        collateralTokens: [],
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

    @Test("Alice repays with a bridge")
    func testCometRepayWithBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(5, .cbbtc), .base),
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
                            fees: [.ethereum: 0.1, .base: 0.2]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .amt(2, .usdc),
                    collateralAmounts: [.amt(1, .cbbtc)],
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
                                    inputTokenAmount: .amt(3.232324, .usdc),
                                    outputTokenAmount: .amt(2.2, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.2, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(2, .usdc),
                                    collateralAmounts: [.amt(1, .cbbtc)],
                                    market: .cusdcv3,
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
                                        inputAmount: Number("3.232324e6"),
                                        outputAmount: Number("2.2e6"),
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
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.2e6"),
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("2e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmounts: [Number("1e8")],
                                        collateralAssetSymbols: ["cbBTC"],
                                        collateralTokenPrices: [Number("100000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                            )
                                        ],
                                        comet: EthAddress(
                                            "0xb125e6687d4313864e53df431d5425969c15eb2f"
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

    @Test("Alice repays max USDC with a bridge")
    func testCometRepayMaxWithBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(10, .usdc), .cusdcv3, .base),
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
                            fees: [.ethereum: 0.1, .base: 0.1]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .max(.usdc),
                    collateralAmounts: [],
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
                                    // Amount to bridge = 10 USDC debt + 1% max repay buffer (10.0001)
                                    // + 0.1 USDC quote fee on Base + 1.0 USDC Across fixed fee
                                    // + ~0.0121 USDC Across percentage fee = 11.212223 USDC input
                                    inputTokenAmount: .amt(11.212223, .usdc),
                                    // 10 USDC debt + 1% max repay buffer + 0.1 USDC quote fee = 10.1001 USDC output
                                    outputTokenAmount: .amt(10.1001, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    // User has sufficient funds, using uint256.max for true max repay
                                    repayAmount: .max(.usdc),
                                    collateralAmounts: [],
                                    market: .cusdcv3,
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
                                        inputAmount: Number("11.212223e6"),
                                        outputAmount: Number("10.1001e6"),
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
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("10.0001e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmounts: [],
                                        collateralAssetSymbols: [],
                                        collateralTokenPrices: [],
                                        collateralTokens: [],
                                        comet: EthAddress(
                                            "0xb125e6687d4313864e53df431d5425969c15eb2f"
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

    @Test("Alice repays max balance USDC with a bridge")
    func testCometRepayMaxBalanceWithBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(50, .usdc), .cusdcv3, .base),
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
                            fees: [.ethereum: 0.1, .base: 0.1]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .max(.usdc),
                    collateralAmounts: [],
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
                                    // 10 USDC available - 0.1 USDC quote fee = 9.9 USDC to bridge
                                    inputTokenAmount: .amt(9.9, .usdc),
                                    // 9.9 USDC - 1% Across fee - 0.099 USDC Across fixed fee = 8.801 USDC arrives on Base
                                    outputTokenAmount: .amt(8.801, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    // 8.801 USDC arrived - 0.1 USDC quote fee = 8.701 USDC repay
                                    repayAmount: .amt(8.701, .usdc),
                                    collateralAmounts: [],
                                    market: .cusdcv3,
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
                                        inputAmount: Number("9.9e6"),
                                        outputAmount: Number("8.801e6"),
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
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
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
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("8.701e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmounts: [],
                                        collateralAssetSymbols: [],
                                        collateralTokenPrices: [],
                                        collateralTokens: [],
                                        comet: EthAddress(
                                            "0xb125e6687d4313864e53df431d5425969c15eb2f"
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

    @Test("Alice repays max USDC with funds split across Ethereum and Base")
    func testCometRepayMaxWithFundsSplitAcrossChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(10, .usdc), .cusdcv3, .base),
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
                            fees: [.ethereum: 0.1, .base: 0.1]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .max(.usdc),
                    collateralAmounts: [],
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
                                    // Need 10.1001 total on Base - 3 already on Base = 7.1001 to bridge
                                    // 7.1001 + 1.0 Across fixed fee + ~0.0819 Across pct fee = 8.18192 input
                                    inputTokenAmount: .amt(8.18192, .usdc),
                                    // 7.1001 USDC arrives on Base (10 USDC debt + 1% buffer + quote fee - 3 USDC local)
                                    outputTokenAmount: .amt(7.1001, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    // User has sufficient total funds (3 + 7.1001 = 10.1001), using uint256.max for true max repay
                                    repayAmount: .max(.usdc),
                                    collateralAmounts: [],
                                    market: .cusdcv3,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    nil
                )
            )
        )
    }

    @Test("Repay amount exceeding debt throws error")
    func testCometRepayAmountExceedsDebtError() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(1, .usdc), .cusdcv3, .ethereum),  // Only 1 USDC debt
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .amt(5, .usdc),  // Trying to repay 5 USDC when debt is only 1
                    collateralAmounts: [],
                    on: .ethereum
                ),
                expect: .failure(
                    Charter.CharterError.repayAmountExceedsDebt(
                        network: .ethereum,
                        repayAsset: "USDC",
                        repayAmount: Amount(Number("5000000"), decimals: 0),
                        existingDebt: Amount(Number("1000000"), decimals: 0)
                    )
                )
            )
        )
    }

    @Test("Alice withdraws max collateral only - resolves actual balance from folio")
    func testCometWithdrawMaxCollateralResolvesActualBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(1, .usdc), .cusdcv3, .ethereum),
                    .cometCollateral(.alice, .amt(1.0025, .comp), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .amt(0, .usdc),
                    collateralAmounts: [.max(.comp)],
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(0, .usdc),
                                    collateralAmounts: [.amt(1.0025, .comp)],
                                    market: .cusdcv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.0025, .comp),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice repays and withdraws max collateral - resolves actual balance from folio")
    func testCometRepayAndWithdrawMaxCollateralResolvesActualBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .base),
                    .cometBorrow(.alice, .amt(5, .usdc), .cusdcv3, .base),
                    .cometCollateral(.alice, .amt(2.0, .weth), .cusdcv3, .base),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cusdcv3,
                    repayAmount: .amt(5, .usdc),
                    collateralAmounts: [.max(.weth)],
                    on: .base
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(5, .usdc),
                                    collateralAmounts: [.amt(2.0, .weth)],
                                    market: .cusdcv3,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice withdraws USDC collateral from WETH Comet - verifies correct decimals handling")
    func testCometWithdrawCollateralDecimalsMismatch() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .weth), .ethereum),
                    .cometBorrow(.alice, .amt(0.5, .weth), .cwethv3, .ethereum),
                    .cometCollateral(.alice, .amt(1.1, .usdc), .cwethv3, .ethereum),
                    .quote(.basic),
                ],
                when: .cometRepay(
                    from: .alice,
                    market: .cwethv3,
                    repayAmount: .amt(0, .weth),
                    collateralAmounts: [.amt(1, .usdc)],
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .repayAndWithdrawMultipleAssetsFromComet(
                                    repayAmount: .amt(0, .weth),
                                    collateralAmounts: [.amt(1.1, .usdc)],
                                    market: .cwethv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.1, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometRepay(
                                    Charter.ActionContext.CometRepayActionContext(
                                        amount: Number("0"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("1.1e6")],
                                        collateralAssetSymbols: ["USDC"],
                                        collateralTokenPrices: [Number("1e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                            )
                                        ],
                                        comet: EthAddress(
                                            "0xa17581a9e3356d9a858b789d68b4d866e593ae94"
                                        ),
                                        price: Number("4000e8"),
                                        token: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                        )
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
                            ]
                        )
                    ]
                )
            )
        )
    }
}
