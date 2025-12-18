@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Morpho Borrow Tests")
struct MorphoBorrowTests {
    @Test("Alice tries to borrow from a Morpho market that does not exist (WETH/USDC)")
    func testMorphoBorrowInvalidMarketParamsTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.1, .wbtc), .ethereum),
                    .tokenBalance(.alice, .amt(1.1, .weth), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: .init(collateralToken: .weth, borrowToken: .usdc),
                    borrowAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .weth),
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

    @Test("Alice tries to supply collateral that she does not have")
    func testMorphoBorrowFundsUnavailableTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    borrowAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .cbbtc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("cbBTC", 100000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(100000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies WBTC and borrows USDC from Morpho")
    func testMorphoBorrowSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.1, .cbbtc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    borrowAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .cbbtc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000001, .cbbtc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyCollateralAndBorrowFromMorpho(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmount: .amt(1, .cbbtc),
                                    cappedMax: false,
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
                                        amount: Number("0.000001e8"),
                                        assetSymbol: "cbBTC",
                                        chainId: Number("1"),
                                        price: Number("100000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        )
                                    )
                                ),
                                Charter.ActionContext.morphoBorrow(
                                    Charter.ActionContext.MorphoBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmount: Number("1e8"),
                                        collateralAssetSymbol: "cbBTC",
                                        collateralTokenPrice: Number("100000e8"),
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

    @Test("Alice supplies ETH to Morpho, which is auto-wrapped to WETH")
    func testMorphoBorrowWithAutoWrapperTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .eth), .base),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    borrowAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyCollateralAndBorrowFromMorpho(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmount: .amt(1, .weth),
                                    cappedMax: false,
                                    market: .morpho(.weth, .usdc),
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
                                Charter.ActionContext.morphoBorrow(
                                    Charter.ActionContext.MorphoBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        collateralAmount: Number("1e18"),
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
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice borrows USDC with WBTC collateral, paying for the operation via QuotePay")
    func testMorphoBorrowWithQuotePayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.1, .cbbtc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    borrowAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .cbbtc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000001, .cbbtc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyCollateralAndBorrowFromMorpho(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmount: .amt(1, .cbbtc),
                                    cappedMax: false,
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
                                        amount: Number("0.000001e8"),
                                        assetSymbol: "cbBTC",
                                        chainId: Number("1"),
                                        price: Number("100000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        )
                                    )
                                ),
                                Charter.ActionContext.morphoBorrow(
                                    Charter.ActionContext.MorphoBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmount: Number("1e8"),
                                        collateralAssetSymbol: "cbBTC",
                                        collateralTokenPrice: Number("100000e8"),
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

    @Test(
        "Alice borrows USDC with WBTC collateral, paying for the operation using the USDC she borrowed"
    )
    func testMorphoBorrowPayFromBorrowTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.1, .cbbtc), .ethereum),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    borrowAmount: .amt(1, .usdc),
                    collateralAmount: .amt(1, .cbbtc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000001, .cbbtc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyCollateralAndBorrowFromMorpho(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmount: .amt(1, .cbbtc),
                                    cappedMax: false,
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
                                        amount: Number("0.000001e8"),
                                        assetSymbol: "cbBTC",
                                        chainId: Number("1"),
                                        price: Number("100000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        )
                                    )
                                ),
                                Charter.ActionContext.morphoBorrow(
                                    Charter.ActionContext.MorphoBorrowActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        collateralAmount: Number("1e8"),
                                        collateralAssetSymbol: "cbBTC",
                                        collateralTokenPrice: Number("100000e8"),
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

    // Borrow capacity calculation for WBTC/WETH market on worldChain:
    //   collateralValue = 2 WBTC × $100,000 = $200,000
    //   borrowableValue = $200,000 × 0.915 (LLTV) × 0.98 (safety cap) ≈ $179,340
    //   borrowCapacity  = $179,340 / $4,000 (WETH price) ≈ 44.8 WETH
    //   fee             = $100,000 / $4,000 = 25 WETH
    //   totalNeeded     = 20 WETH (borrow) + 25 WETH (fee) = 45 WETH
    // Since totalNeeded (45 WETH) > borrowCapacity (44.8 WETH), this fails.
    @Test("Alice tries to borrow from Morpho, but the operation cost exceeds her borrow capacity")
    func testMorphoBorrowMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(2, .wbtc),
                        Morpho(collateralToken: .wbtc, borrowToken: .weth),
                        .worldChain
                    ),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0, Token.weth: 4000.0, Token.wbtc: 100_000.0],
                            fees: [
                                .worldChain: 100_000.0
                            ]
                        )
                    ),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    borrowAmount: .amt(20, .weth),
                    collateralAmount: .amt(0, .wbtc),
                    on: .worldChain
                ),
                expect: .failure(
                    .error("insufficientResources(target: .exact(20000000000000000000), max: 19835000000000000000)")
                )
            )
        )
    }

    @Test("Alice tries to borrow from Morpho without existing collateral")
    func testMorphoBorrowWithoutExistingCollateral() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    borrowAmount: .amt(100, .usdc),
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .failure(
                    .noCollateralInBorrowMarket(network: .base)
                )
            )
        )
    }

    @Test("Alice borrows from Morpho, supplying max cbBTC collateral and paying with cbBTC")
    func testMorphoBorrowWithMaxCollateralTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(5, .cbbtc), .ethereum),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .cbbtc,
                    .morphoBorrow(
                        from: .alice,
                        morpho: Morpho(
                            collateralToken: .cbbtc,
                            borrowToken: .usdc
                        ),
                        borrowAmount: .amt(1, .usdc),
                        collateralAmount: .max(.cbbtc),
                        on: .ethereum
                    )
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .init(fromWei: 100, ofToken: .cbbtc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyCollateralAndBorrowFromMorpho(
                                    borrowAmount: .amt(1, .usdc),
                                    collateralAmount: .amt(4.999999, .cbbtc),
                                    cappedMax: true,
                                    market: .init(collateralToken: .cbbtc, borrowToken: .usdc),
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

    @Test("Alice pure borrows from existing collateral with QuotePay fees from borrowed asset")
    func testPureBorrowWithQuotePayFromBorrowedAsset() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(5, .cbbtc),
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .ethereum
                    ),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                    borrowAmount: .amt(1, .usdc),
                    collateralAmount: .amt(0, .cbbtc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .supplyCollateralAndBorrowFromMorpho(
                                    borrowAmount: .amt(1.1, .usdc),
                                    collateralAmount: .amt(0, .cbbtc),
                                    cappedMax: false,
                                    market: .morpho(.cbbtc, .usdc),
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
                    )
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
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    borrowAmount: .max(.usdc),
                    collateralAmount: .amt(0.5, .weth),
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
        // 0.5 WETH × $4000 × 86% LLTV × 98% safety cap = $1685.6 USDC
        // The calculated amount (not MAX_UINT_256) is passed to the contract since Morpho
        // does not support MAX_UINT_256 for borrow amounts.
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(0.5, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                when: .morphoBorrow(
                    from: .alice,
                    morpho: Morpho(collateralToken: .weth, borrowToken: .usdc),
                    borrowAmount: .max(.usdc),  // Max borrow intent
                    collateralAmount: .amt(0, .weth),
                    on: .base
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .supplyCollateralAndBorrowFromMorpho(
                                    borrowAmount: .amt(1685.6, .usdc),  // Calculated borrow capacity
                                    collateralAmount: .amt(0, .weth),
                                    cappedMax: false,
                                    market: .morpho(.weth, .usdc),
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

    // TODO: add bridging tests
}
