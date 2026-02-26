@preconcurrency import Eth
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Morpho Repay Tests")
struct MorphoRepayTests {
    @Test("Alice tries to repay with funds she doesn't have")
    func testMorphoRepayFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [.quote(.basic)],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .cbbtc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 1000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(1000000), max: 0)"))
            )
        )
    }

    @Test("Alice withdraws collateral only without repaying")
    func testMorphoWithdrawCollateralOnly() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1.000005, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(0, .usdc),
                    collateralAmount: .amt(1, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .amt(0, .usdc),
                                    collateralAmount: .amt(1.000005, .weth),
                                    market: .morpho(.weth, .usdc),
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
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
                                Charter.ActionContext.morphoRepay(
                                    Charter.ActionContext.MorphoRepayActionContext(
                                        amount: Number("0"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmount: Number("1.000005e18"),
                                        collateralAssetSymbol: "WETH",
                                        collateralTokenPrice: Number("4000e8"),
                                        collateralToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        morpho: EthAddress(
                                            "0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb"
                                        ),
                                        morphoMarketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice tries to repay Morpho balance, but does not have enough USDC for QuotePay")
    func testMorphoRepayMaxCostTooHigh() async throws {
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
                            fees: [.base: 0.5]
                        )
                    ),
                    .tokenBalance(.alice, .amt(1.4, .usdc), .base),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbeth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .cbeth),
                    on: .base
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("UNABLE_TO_CONSTRUCT", "USDC", 500000))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(
                    .error("insufficientResources(target: .exact(1000000), max: 900000)")
                )
            )
        )
    }

    @Test("Alice repays Morpho borrow")
    func testMorphoRepayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .cbbtc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .amt(1, .usdc),
                                    collateralAmount: .amt(1, .cbbtc),
                                    market: .morpho(.cbbtc, .usdc),
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

    @Test("Alice repays MorphoBorrow of WETH with ETH")
    func testMorphoRepayWithAutoWrapper() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.1, .eth), .worldChain),
                    .tokenBalance(.alice, .amt(1, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    repayAmount: .amt(1, .weth),
                    collateralAmount: .amt(0, .wbtc),
                    on: .worldChain
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
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .amt(1, .weth),
                                    collateralAmount: .amt(0, .wbtc),
                                    market: .morpho(.wbtc, .weth),
                                    network: .worldChain
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
                                        chainId: Number("480"),
                                        amount: Number("1.000025e18"),
                                        token: Token.eth.address(network: .worldChain)!,
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
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
                                Charter.ActionContext.morphoRepay(
                                    Charter.ActionContext.MorphoRepayActionContext(
                                        amount: Number("1e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("480"),
                                        collateralAmount: Number("0"),
                                        collateralAssetSymbol: "WBTC",
                                        collateralTokenPrice: Number("0"),
                                        collateralToken: EthAddress(
                                            "0x03c7054bcb39f7b2e5b2c7acb37583e32d70cfa3"
                                        ),
                                        morpho: EthAddress(
                                            "0xe741bc7c34758b4cae05062794e8ae24978af432"
                                        ),
                                        morphoMarketId: Hex(
                                            "0x19c682c3a37025075074cefea866fbe54656abc0fb6a7355b62a53f45b959abf"
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

    @Test("Alice repays Morpho borrow, paying with QuotePay")
    func testMorphoRepayWithQuotePayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(2, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(1, .usdc),
                    collateralAmount: .amt(0, .cbbtc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .amt(1, .usdc),
                                    collateralAmount: .amt(0, .cbbtc),
                                    market: .morpho(.cbbtc, .usdc),
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

    @Test("Alice repays Morpho borrow on Base with funds bridged from Ethereum")
    func testMorphoRepayWithBridgeTest() async throws {
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
                            fees: [
                                .ethereum: 0.1,
                                .base: 0.2,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(2, .usdc),
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            inputTokenAmount: .amt(3.232324, .usdc),
                            outputTokenAmount: .amt(2.200000, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.2, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .amt(2, .usdc),
                                    collateralAmount: .amt(0, .weth),
                                    market: .morpho(.weth, .usdc),
                                    network: .base,
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
                                Charter.ActionContext.morphoRepay(
                                    Charter.ActionContext.MorphoRepayActionContext(
                                        amount: Number("2e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmount: Number("0"),
                                        collateralAssetSymbol: "WETH",
                                        collateralTokenPrice: Number("0"),
                                        collateralToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        morpho: EthAddress(
                                            "0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb"
                                        ),
                                        morphoMarketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
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

    @Test("Alice repays max Morpho borrow")
    func testMorphoRepayMaxTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .amt(10, .usdc),
                        .amt(0.5, .cbbtc),
                        .ethereum
                    ),
                    .tokenBalance(.alice, .amt(20, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    repayAmount: .max(.usdc),
                    collateralAmount: .amt(0, .cbbtc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    // User has sufficient funds (20 USDC > 10.1001 USDC required), using uint256.max for true max repay
                                    repayAmount: .max(.usdc),
                                    collateralAmount: .amt(0, .cbbtc),
                                    market: .morpho(.cbbtc, .usdc),
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
                                Charter.ActionContext.morphoRepay(
                                    Charter.ActionContext.MorphoRepayActionContext(
                                        amount: Number("10.0001e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmount: Number("0"),
                                        collateralAssetSymbol: "cbBTC",
                                        collateralTokenPrice: Number("0"),
                                        collateralToken: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        ),
                                        morpho: EthAddress(
                                            "0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb"
                                        ),
                                        morphoMarketId: Hex(
                                            "0x64d65c9a2d91c36d56fbc42d69e979335320169b3df63bf92789e2c8883fcc64"
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

    @Test("Alice repays max Morpho borrow on Base with funds bridged from Ethereum")
    func testMorphoRepayMaxWithBridgeTest() async throws {
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
                                .ethereum: 0.1,
                                .base: 0.1,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                    .tokenBalance(.alice, .amt(50, .usdc), .ethereum),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(10, .usdc),
                        .amt(1, .weth),
                        .base
                    ),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .max(.usdc),
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .success(
                    .multi([
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
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    // User has sufficient funds after bridge, using uint256.max for true max repay
                                    repayAmount: .max(.usdc),
                                    collateralAmount: .amt(0, .weth),
                                    market: .morpho(.weth, .usdc),
                                    network: .base,
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice partially repays Morpho borrow using max")
    func testPartialRepayUsingMaxTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .amt(20, .usdc),
                        .amt(1.0, .cbbtc),
                        .ethereum
                    ),
                    .tokenBalance(.alice, .amt(5, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    repayAmount: .max(.usdc),
                    collateralAmount: .amt(0, .cbbtc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    // 5 USDC available - 0.1 USDC quote fee = 4.9 USDC partial repay
                                    repayAmount: .amt(4.9, .usdc),
                                    collateralAmount: .amt(0, .cbbtc),
                                    market: .morpho(.cbbtc, .usdc),
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
                                Charter.ActionContext.morphoRepay(
                                    Charter.ActionContext.MorphoRepayActionContext(
                                        amount: Number("4.9e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmount: Number("0"),
                                        collateralAssetSymbol: "cbBTC",
                                        collateralTokenPrice: Number("0"),
                                        collateralToken: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        ),
                                        morpho: EthAddress(
                                            "0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb"
                                        ),
                                        morphoMarketId: Hex(
                                            "0x64d65c9a2d91c36d56fbc42d69e979335320169b3df63bf92789e2c8883fcc64"
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

    @Test("Alice repays max balance Morpho borrow with funds bridged from Ethereum")
    func testMorphoRepayMaxBalanceWithBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(50, .usdc),
                        .amt(1, .weth),
                        .base
                    ),
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
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .max(.usdc),
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            // 10 USDC available, all bridged (no source chain fee)
                            inputTokenAmount: .amt(10, .usdc),
                            // 10 USDC - 1% Across fee - 0.1 USDC Across fixed fee = 8.9 USDC arrives on Base
                            outputTokenAmount: .amt(8.9, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    // 8.9 USDC arrived - 0.1 USDC quote fee = 8.8 USDC repay
                                    repayAmount: .amt(8.8, .usdc),
                                    collateralAmount: .amt(0, .weth),
                                    market: .morpho(.weth, .usdc),
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

    @Test("Alice repays max Morpho borrow with funds split across Ethereum and Base")
    func testMorphoRepayMaxWithFundsSplitAcrossChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(10, .usdc),
                        .amt(1, .weth),
                        .base
                    ),
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
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .max(.usdc),
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            // Need 10.1001 total on Base - 3 already on Base = 7.1001 to bridge
                            // 7.1001 + 1.0 Across fixed fee + ~0.0819 Across pct fee = 8.18192 input
                            inputTokenAmount: .amt(8.18192, .usdc),
                            // 7.1001 USDC arrives on Base (10 USDC debt + 1% buffer + quote fee - 3 USDC local)
                            outputTokenAmount: .amt(7.1001, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    // User has sufficient total funds (3 + 7.1001 = 10.1001), using uint256.max for true max repay
                                    repayAmount: .max(.usdc),
                                    collateralAmount: .amt(0, .weth),
                                    market: .morpho(.weth, .usdc),
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

    @Test("Alice repays max Morpho borrow requiring bridge due to insufficient local funds")
    func testMorphoRepayMaxRequiresBridgeFromInsufficientLocal() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .tokenBalance(.alice, .amt(50, .usdc), .ethereum),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(10, .usdc),
                        .amt(1, .weth),
                        .base
                    ),
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
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .max(.usdc),
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .ethereum,
                            destinationNetwork: .base,
                            // Need 10.1001 total on Base - 3 already on Base = 7.1001 to bridge
                            // 7.1001 + 1.0 Across fixed fee + ~0.0819 Across pct fee = 8.18192 input
                            inputTokenAmount: .amt(8.18192, .usdc),
                            // 7.1001 USDC arrives on Base (10 USDC debt + 0.0001 buffer + 0.1 quote fee - 3 USDC local)
                            outputTokenAmount: .amt(7.1001, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    // User has sufficient total funds (3 + 7.1001 = 10.1001), using uint256.max for true max repay
                                    repayAmount: .max(.usdc),
                                    collateralAmount: .amt(0, .weth),
                                    market: .morpho(.weth, .usdc),
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

    @Test("Morpho repay max respects Across bridge minimum with QuotePay")
    func testMorphoRepayMaxWithBridgeMinimumAndQuotePay() async throws {
        // Test derived from Quark Intent 1254 on staging:
        // Repay max was failing because Tradewinds was not creating a bridge operation
        // World Chain USDC: 7.102492; Base USDC: 2.017901; Debt on Base: 2.012328.
        // Across (World→Base): minDeposit=0.500157 USDC, fixed=0.002075 USDC, rate=0.99966483667478448.
        // QuotePay: World=0.002230 USDC, Base=0.006061 USDC.

        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(7.102492, .usdc), .worldChain),
                    .tokenBalance(.alice, .amt(2.017901, .usdc), .base),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(2.012328, .usdc),
                        .amt(1.0, .weth),
                        .base
                    ),
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
                                .worldChain: 0.00223,
                                .base: 0.006061,
                            ]
                        )
                    ),
                    .acrossQuoteWithMin(
                        .amt(0.002075, .usdc),
                        0.00033516332521552,  // 1 - 0.99966483667478448
                        .amt(0.500157, .usdc)
                    ),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .max(.usdc),
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .worldChain,
                            destinationNetwork: .base,
                            // Solver chooses max bridge; no source chain fee
                            inputTokenAmount: .amt(7.002184, .usdc),
                            outputTokenAmount: .amt(6.997762, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.006061, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .max(.usdc),
                                    collateralAmount: .amt(0, .weth),
                                    market: .morpho(.weth, .usdc),
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

    @Test("Repay amount exceeding debt throws error")
    func testMorphoRepayAmountExceedsDebtError() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .ethereum),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .amt(1, .usdc),
                        .amt(0.01, .cbbtc),
                        .ethereum
                    ),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                    repayAmount: .amt(5, .usdc),
                    collateralAmount: .amt(0, .cbbtc),
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
    func testMorphoWithdrawMaxCollateralResolvesActualBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1.5, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(0, .usdc),
                    collateralAmount: .max(.weth),
                    on: .base
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .amt(0, .usdc),
                                    collateralAmount: .amt(1.5, .weth),
                                    market: .morpho(.weth, .usdc),
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
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
    func testMorphoRepayAndWithdrawMaxCollateralResolvesActualBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .base),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(5, .usdc),
                        .amt(2.0, .weth),
                        .base
                    ),
                    .quote(.basic),
                ],
                when: .morphoRepay(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    repayAmount: .amt(5, .usdc),
                    collateralAmount: .max(.weth),
                    on: .base
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .repayAndWithdrawCollateralFromMorpho(
                                    repayAmount: .amt(5, .usdc),
                                    collateralAmount: .amt(2.0, .weth),
                                    market: .morpho(.weth, .usdc),
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
}
