@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Add Backing Token Tests")
struct AddBackingTokenTests {
    // ===== Tests for long positions =====

    @Test("Alice adds USDC backing token to WBTC loop long position")
    func testAddBackingTokenToLongSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(101, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                    exposureToken: .cbbtc,
                    backingAmount: .amt(100, .usdc),
                    isShort: false,
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .addBackingToken(
                                    backingAmount: .amt(100, .usdc),
                                    cappedMax: false,
                                    market: .morpho(.cbbtc, .usdc),
                                    isShort: false,
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
                                Charter.ActionContext.addBackingToken(
                                    Charter.ActionContext.AddBackingTokenActionContext(
                                        amount: Number("100e6"),
                                        backingAssetSymbol: "USDC",
                                        backingToken: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        ),
                                        backingTokenPrice: Number("1e8"),
                                        chainId: Number("1"),
                                        exposureAssetSymbol: "cbBTC",
                                        exposureToken: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        ),
                                        exposureTokenPrice: Number("100000e8"),
                                        borrowVenue: "MORPHO_BLUE",
                                        borrowMarketId: Hex(
                                            "0x64d65c9a2d91c36d56fbc42d69e979335320169b3df63bf92789e2c8883fcc64"
                                        ),
                                        isShort: false
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice adds max USDC backing token to WBTC loop long position")
    func testAddMaxBackingTokenToLongSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                    exposureToken: .cbbtc,
                    backingAmount: .max(.usdc),
                    isShort: false,
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .addBackingToken(
                                    // We subtract the network fee of 0.1 to calculate the available balance
                                    backingAmount: .amt(99.9, .usdc),
                                    cappedMax: true,
                                    market: .morpho(.cbbtc, .usdc),
                                    isShort: false,
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

    @Test("Alice adds USDC backing token to cbETH loop long position on Base via bridge")
    func testAddBackingTokenToLongSuccessByBridgingUSDC() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(110, .usdc), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .cbeth, borrowToken: .usdc),
                    exposureToken: .cbeth,
                    backingAmount: .amt(100, .usdc),
                    isShort: false,
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .arbitrum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(102.040405, .usdc),
                                    outputTokenAmount: .amt(100.02, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .addBackingToken(
                                    backingAmount: .amt(100, .usdc),
                                    cappedMax: false,
                                    market: .morpho(.cbeth, .usdc),
                                    isShort: false,
                                    network: .base,
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("42161"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("102.040405e6"),
                                        outputAmount: Number("100.02e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                        )
                                    )
                                ),
                            ]
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
                                Charter.ActionContext.addBackingToken(
                                    Charter.ActionContext.AddBackingTokenActionContext(
                                        amount: Number("100e6"),
                                        backingAssetSymbol: "USDC",
                                        backingToken: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        ),
                                        backingTokenPrice: Number("1e8"),
                                        chainId: Number("8453"),
                                        exposureAssetSymbol: "cbETH",
                                        exposureToken: EthAddress(
                                            "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22"
                                        ),
                                        exposureTokenPrice: Number("4000e8"),
                                        borrowVenue: "MORPHO_BLUE",
                                        borrowMarketId: Hex(
                                            "0x1c21c59df9db44bf6f645d854ee710a8ca17b479451447e9f56758aee10a2fad"
                                        ),
                                        isShort: false
                                    )
                                ),
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice tries to add backing token to a long position of an asset she does not have")
    func testAddBackingTokenToLongFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                    exposureToken: .cbbtc,
                    backingAmount: .amt(1, .usdc),
                    isShort: false,
                    on: .base
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 1000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no resources are available
                expect: .failure(.error("insufficientResources(target: .exact(1000000), max: 0)"))
            )
        )
    }

    @Test(
        "Alice tries to add backing token to a long position, but the operation cost exceeds her USDC balance"
    )
    func testAddBackingTokenToLongMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.4, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .base: 0.5
                            ]
                        )
                    ),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .cbeth, borrowToken: .usdc),
                    exposureToken: .cbeth,
                    backingAmount: .amt(1, .usdc),
                    isShort: false,
                    on: .base
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("UNABLE_TO_CONSTRUCT", "USDC", 500000))
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed due to insufficient funds
                expect: .failure(
                    .error("insufficientResources(target: .exact(1000000), max: 900000)")
                )
            )
        )
    }

    @Test(
        "Alice tries to add backing token to a long position on a Morpho market that does not exist (WETH/USDC)"
    )
    func testAddBackingTokenToLongInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(101, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    exposureToken: .weth,
                    backingAmount: .amt(100, .usdc),
                    isShort: false,
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unknownMorphoMarket(marketId, 1))
                // Now properly returns .morphoMarketNotFound with marketId and network
                expect: .failure(
                    .morphoMarketNotFound(
                        marketId: Morpho(collateralToken: .weth, borrowToken: .usdc)
                            .marketId(.ethereum),
                        network: .ethereum
                    )
                )
            )
        )
    }

    // ===== Tests for short positions =====

    @Test("Alice adds WBTC backing token to WETH loop short position")
    func testAddBackingTokenToShortSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.01, .usdc), .worldChain),
                    .tokenBalance(.alice, .amt(1.01, .wbtc), .worldChain),
                    .quote(.basic),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .wbtc, borrowToken: .weth),
                    exposureToken: .weth,
                    backingAmount: .amt(1, .wbtc),
                    isShort: true,
                    on: .worldChain
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000001, .wbtc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .addBackingToken(
                                    backingAmount: .amt(1, .wbtc),
                                    cappedMax: false,
                                    market: .morpho(.wbtc, .weth),
                                    isShort: true,
                                    network: .worldChain
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice adds max WBTC backing token to WETH loop short position")
    func testAddMaxBackingTokenToShortSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .worldChain),
                    .tokenBalance(.alice, .amt(1, .wbtc), .worldChain),
                    .quote(.basic),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .wbtc, borrowToken: .weth),
                    exposureToken: .weth,
                    backingAmount: .max(.wbtc),
                    isShort: true,
                    on: .worldChain
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.000001, .wbtc), payee: .stax, quote: .basic),
                                .addBackingToken(
                                    // We subtract the quote fee
                                    backingAmount: .amt(0.999999, .wbtc),
                                    cappedMax: true,
                                    market: .morpho(.wbtc, .weth),
                                    isShort: true,
                                    network: .worldChain
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice adds WETH backing token to USDC loop short position on Base via bridge")
    func testAddBackingTokenToShortSuccessByBridgingUSDCTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(1.1, .weth), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    exposureToken: .usdc,
                    backingAmount: .amt(1, .weth),
                    isShort: true,
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.00001, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .arbitrum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(
                                        fromWei: "1020207070707070708",
                                        ofToken: .weth
                                    ),
                                    outputTokenAmount: .amt(1.000005, .weth),
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
                                .addBackingToken(
                                    backingAmount: .amt(1, .weth),
                                    cappedMax: false,
                                    market: .morpho(.weth, .usdc),
                                    isShort: true,
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

    @Test("Alice tries to add backing token to a short position of an asset she does not have")
    func testAddBackingTokenToShortFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    exposureToken: .usdc,
                    backingAmount: .amt(1, .weth),
                    isShort: true,
                    on: .base
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("WETH", 1000000000000000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no resources are available
                expect: .failure(
                    .error("insufficientResources(target: .exact(1000000000000000000), max: 0)")
                )
            )
        )
    }

    @Test(
        "Alice tries to add backing token to a short position, but the operation cost exceeds her balance"
    )
    func testAddBackingTokenToShortMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .weth), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0, Token.weth: 4000.0],
                            fees: [
                                .base: 0.5
                            ]
                        )
                    ),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    exposureToken: .usdc,
                    backingAmount: .amt(1, .weth),
                    isShort: true,
                    on: .base
                ),
                // Note: Previously expected .unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 500000)
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed due to insufficient funds
                expect: .failure(
                    .error(
                        "insufficientResources(target: .exact(1000000000000000000), max: 999875000000000000)"
                    )
                )
            )
        )
    }

    @Test(
        "Alice tries to add backing token to a short position on a Morpho market that does not exist (WETH/USDC)"
    )
    func testAddBackingTokenToShortInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(101, .weth), .ethereum),
                    .quote(.basic),
                ],
                when: .addBackingToken(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    exposureToken: .usdc,
                    backingAmount: .amt(100, .weth),
                    isShort: true,
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unknownMorphoMarket(marketId, 1))
                // Now properly returns .morphoMarketNotFound with marketId and network
                expect: .failure(
                    .morphoMarketNotFound(
                        marketId: Morpho(collateralToken: .weth, borrowToken: .usdc)
                            .marketId(.ethereum),
                        network: .ethereum
                    )
                )
            )
        )
    }
}
