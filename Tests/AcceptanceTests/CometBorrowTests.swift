@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Comet Borrow Tests")
struct CometBorrowTests {
    @Test("Alice tries to supply collateral that she doesn't have")
    func testBorrowFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(1, .usdc),
                    collateralAmounts: [.amt(1, .weth)],
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("WETH", 1000000000000000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(
                    .error("insufficientResources(target: .exact(1000000000000000000), max: 0)")
                )
            )
        )
    }

    @Test("Alice supplies 1 ETH and borrows 1 USDC on mainnet cUSDCv3")
    func testBorrow() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .eth), .ethereum),
                    .quote(.basic),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(1, .usdc),
                    collateralAmounts: [.amt(1, .eth)],
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
                                .supplyMultipleAssetsAndBorrowFromComet(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmounts: [.amt(1, .weth)],
                                    cappedMaxes: [false],
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
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("1"),
                                        amount: Number("1.000025e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
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
                                Charter.ActionContext.cometBorrow(
                                    Charter.ActionContext.CometBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("1e18")],
                                        collateralAssetSymbols: ["WETH"],
                                        collateralTokenPrices: [Number("4000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
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

    @Test("Alice supplies 10 ETH, which are auto-wrapped to WETH")
    func testBorrowWithAutoWrapper() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .eth), .ethereum),
                    .quote(.basic),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(1, .usdc),
                    collateralAmounts: [.amt(9.999975, .weth)],
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
                                .supplyMultipleAssetsAndBorrowFromComet(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmounts: [.amt(9.999975, .weth)],
                                    cappedMaxes: [false],
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
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("1"),
                                        amount: Number("10e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
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
                                Charter.ActionContext.cometBorrow(
                                    Charter.ActionContext.CometBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("9.999975e18")],
                                        collateralAssetSymbols: ["WETH"],
                                        collateralTokenPrices: [Number("4000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
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

    @Test("Alice borrows from Comet, paying with QuotePay")
    func testCometBorrowWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(5, .cbeth), .base),
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
                            fees: [.ethereum: 0.1, .base: 1]
                        )
                    ),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(1, .usdc),
                    collateralAmounts: [.amt(1, .cbeth)],
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.00025, .cbeth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyMultipleAssetsAndBorrowFromComet(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmounts: [.amt(1, .cbeth)],
                                    cappedMaxes: [false],
                                    market: .cusdcv3,
                                    network: .base
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
                                        amount: Number("0.00025e18"),
                                        assetSymbol: "cbETH",
                                        chainId: Number("8453"),
                                        price: Number("4000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22"
                                        )
                                    )
                                ),
                                Charter.ActionContext.cometBorrow(
                                    Charter.ActionContext.CometBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmounts: [Number("1e18")],
                                        collateralAssetSymbols: ["cbETH"],
                                        collateralTokenPrices: [Number("4000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22"
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
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice borrows from Comet on Optimism")
    func testCometBorrowOnOptimism() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(5, .wbtc), .optimism),
                    .quote(.basic),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(1, .usdc),
                    collateralAmounts: [.amt(1, .wbtc)],
                    on: .optimism
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.0000006, .wbtc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyMultipleAssetsAndBorrowFromComet(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmounts: [.amt(1, .wbtc)],
                                    cappedMaxes: [false],
                                    market: .cusdcv3,
                                    network: .optimism
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
                                        amount: Number("0.0000006e8"),
                                        assetSymbol: "WBTC",
                                        chainId: Number("10"),
                                        price: Number("100000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x68f180fcce6836688e9084f035309e29bf0a2095"
                                        )
                                    )
                                ),
                                Charter.ActionContext.cometBorrow(
                                    Charter.ActionContext.CometBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("10"),
                                        collateralAmounts: [Number("1e8")],
                                        collateralAssetSymbols: ["WBTC"],
                                        collateralTokenPrices: [Number("100000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0x68f180fcce6836688e9084f035309e29bf0a2095"
                                            )
                                        ],
                                        comet: EthAddress(
                                            "0x2e44e174f7d53f0212823acc11c01a11d58c5bcb"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"
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

    @Test("Alice pays for a QuotePay with WETH before borrowing")
    func testBorrowPayFromBorrow() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .eth), .base),
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
                            fees: [.base: 0.000375]  // 0.000375 USD fee
                        )
                    ),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(2, .usdc),
                    collateralAmounts: [.amt(0.999625, .weth)],
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.00000009375, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyMultipleAssetsAndBorrowFromComet(
                                    borrowAmount: .amt(2, .usdc),
                                    collateralAmounts: [.amt(0.999625, .weth)],
                                    cappedMaxes: [false],
                                    market: .cusdcv3,
                                    network: .base
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
                                        chainId: Number("8453"),
                                        amount: Number("0.999625093750e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.00000009375e18"),
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
                                Charter.ActionContext.cometBorrow(
                                    Charter.ActionContext.CometBorrowActionContext(
                                        amount: Number("2e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmounts: [Number("0.999625e18")],
                                        collateralAssetSymbols: ["WETH"],
                                        collateralTokenPrices: [Number("4000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
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
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice supplies bridged USDC and borrows against it", .disabled("reverts with `Panic`"))
    func testBorrowWithBridgedCollateralAsset() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4, .usdc), .ethereum),
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
                when: .cometBorrow(
                    from: .alice,
                    market: .cwethv3,
                    borrowAmount: .amt(1, .weth),
                    collateralAmounts: [.amt(2, .usdc)],
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall([
                            .bridge(
                                bridge: "Across",
                                srcNetwork: .ethereum,
                                destinationNetwork: .base,
                                inputTokenAmount: .amt(2.2, .usdc),
                                outputTokenAmount: .amt(1.178, .usdc),
                                cappedMax: false,
                                executionType: .immediate
                            ),
                            .quotePay(
                                payment: .amt(0.3, .usdc),
                                payee: .stax,
                                quote: .basic,
                                executionType: .immediate
                            ),
                        ]),
                        .supplyMultipleAssetsAndBorrowFromComet(
                            borrowAmount: .amt(2, .usdc),
                            collateralAmounts: [.amt(1, .weth)],
                            cappedMaxes: [false],
                            market: .cusdcv3,
                            network: .base,
                            executionType: .contingent
                        ),
                    ]),
                    []
                )
            )
        )
    }

    @Test("Alice borrows from Comet, supplying max weth collateral and paying with weth")
    func testCometBorrowWithMaxCollateral() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(5, .weth), .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .weth,
                    .cometBorrow(
                        from: .alice,
                        market: .cusdcv3,
                        borrowAmount: .amt(1, .usdc),
                        collateralAmounts: [.max(.weth)],
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyMultipleAssetsAndBorrowFromComet(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmounts: [
                                        .amt(4.999995, .weth)
                                    ],
                                    cappedMaxes: [true],
                                    market: .cusdcv3,
                                    network: .base
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
                                Charter.ActionContext.cometBorrow(
                                    Charter.ActionContext.CometBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmounts: [Number("4.999995e18")],
                                        collateralAssetSymbols: ["WETH"],
                                        collateralTokenPrices: [Number("4000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
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
                        )
                    ]
                )
            )
        )
    }

    @Test(
        "Alice borrows from Comet, supplying max weth collateral and paying with weth when no weth balance"
    )
    func testCometBorrowWithMaxCollateralAndNoWethBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .payWith(
                    currency: .weth,
                    .cometBorrow(
                        from: .alice,
                        market: .cusdcv3,
                        borrowAmount: .amt(1, .usdc),
                        collateralAmounts: [.max(.weth)],
                        on: .base
                    )
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "WETH", 0))
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }

    @Test("Alice tries to borrow from Comet without existing collateral")
    func testCometBorrowWithoutExistingCollateral() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .quote(.basic),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(100, .usdc),
                    collateralAmounts: [],
                    on: .base
                ),
                expect: .failure(
                    .noCollateralInBorrowMarket(network: .base)
                )
            )
        )
    }

    @Test("Alice pure borrows from existing collateral with QuotePay fees from borrowed asset")
    func testPureBorrowWithQuotePayFromBorrowedAsset() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometCollateral(.alice, .amt(5, .weth), .cusdcv3, .base),
                    .quote(.basic),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(1, .usdc),
                    collateralAmounts: [],
                    on: .base
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(1.02, .usdc),
                                    market: .cusdcv3,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
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

    @Test("Alice adds collateral without borrowing")
    func testAddCollateralOnly() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.000025, .weth), .ethereum),
                    .quote(.basic)
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .amt(0, .usdc),  // Zero borrow amount
                    collateralAmounts: [.amt(1, .weth)],
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
                                .supplyMultipleAssetsAndBorrowFromComet(
                                    borrowAmount: .amt(0, .usdc),  // Zero borrow
                                    collateralAmounts: [.amt(1, .weth)],
                                    cappedMaxes: [false],
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
                                // This should be cometBorrow, NOT cometSupply!
                                Charter.ActionContext.cometBorrow(
                                    Charter.ActionContext.CometBorrowActionContext(
                                        amount: Number("0"),  // Zero borrow amount
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmounts: [Number("1e18")],
                                        collateralAssetSymbols: ["WETH"],
                                        collateralTokenPrices: [Number("4000e8")],
                                        collateralTokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
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

    @Test("Alice tries to borrow max with new collateral supply (not supported)")
    func testMaxBorrowWithSupplyNotSupported() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .weth), .base),
                    .quote(.basic),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .max(.usdc),
                    collateralAmounts: [.amt(0.5, .weth)],
                    on: .base
                ),
                expect: .failure(
                    .error("Max borrow is not supported in supply+borrow flow. Please specify an exact borrow amount.")
                )
            )
        )
    }

    @Test("Alice borrows max amount from existing collateral")
    func testMaxBorrowFromExistingCollateral() async throws {
        // Max borrow calculates borrow capacity based on collateral:
        // 0.5 WETH × $4000 × 85% liquidation factor × 98% safety cap = $1666 USDC
        // The calculated amount (not MAX_UINT_256) is passed to the contract since Comet
        // does not support MAX_UINT_256 for borrow amounts.
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometCollateral(.alice, .amt(0.5, .weth), .cusdcv3, .base),
                    .quote(.basic),
                ],
                when: .cometBorrow(
                    from: .alice,
                    market: .cusdcv3,
                    borrowAmount: .max(.usdc),  // Max borrow intent
                    collateralAmounts: [],
                    on: .base
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(1666, .usdc),  // Calculated borrow capacity
                                    market: .cusdcv3,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),  // Fee based on basic quote
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
}
