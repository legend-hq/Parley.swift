@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

// TODO: These have a variety of issues (getting insufficient resources everywhere)
@Suite("Withdraw Backing Token Tests")
struct WithdrawBackingTokenTests {
    // Tests for long positions

    // TODO: This is getting an error on insufficient resources!
    @Test("Alice withdraws USDC backing token from WBTC loop long position", .disabled())
    func testWithdrawsBackingTokenFromLongSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .withdrawBackingToken(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureToken: .cbbtc,
                    backingAmount: .amt(100, .usdc),
                    isShort: false,
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawBackingToken(
                                    backingAmount: .amt(100, .usdc),
                                    market: .morpho(.cbbtc, .usdc),
                                    isShort: false,
                                    network: .ethereum
                                ),
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction([
                            Charter.ActionContext.withdrawBackingToken(
                                Charter.ActionContext.WithdrawBackingTokenActionContext(
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

    // TODO: This is _not_ getting insufficient resources!!
    @Test(
        "Alice tries to withdraw backing token from a long position, but the operation cost exceeds her USDC balance",
        .disabled()
    )
    func testWithdrawBackingTokenFromLongMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.4, .usdc), .worldChain),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .worldChain: 0.5
                            ]
                        )
                    ),
                ],
                when: .withdrawBackingToken(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureToken: .wbtc,
                    backingAmount: .amt(1, .weth),
                    isShort: false,
                    on: .worldChain
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 0.5))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    // TODO: This is getting invalid resources!!
    @Test(
        "Alice tries to withdraw backing token from a long position on a Morpho market that does not exist (WETH/USDC)",
        .disabled("getting invalid resources")
    )
    func testWithdrawBackingTokenFromLongInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .withdrawBackingToken(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureToken: .weth,
                    backingAmount: .amt(100, .usdc),
                    isShort: false,
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unknownMorphoMarket(marketId, 1))
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

    // Tests for short positions
    @Test(
        "Alice withdraws WBTC backing token from WETH loop short position",
        .disabled("insufficient resources")
    )
    func testWithdrawBackingTokenFromShortSuccess() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .withdrawBackingToken(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureToken: .weth,
                    backingAmount: .amt(1, .wbtc),
                    isShort: true,
                    on: .worldChain
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawBackingToken(
                                    backingAmount: .amt(1, .wbtc),
                                    market: .morpho(.wbtc, .weth),
                                    isShort: true,
                                    network: .worldChain
                                ),
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.withdrawBackingToken(
                                    Charter.ActionContext.WithdrawBackingTokenActionContext(
                                        amount: Number("1e8"),
                                        backingAssetSymbol: "WBTC",
                                        backingToken: EthAddress(
                                            "0x03c7054bcb39f7b2e5b2c7acb37583e32d70cfa3"
                                        ),
                                        backingTokenPrice: Number("100000e8"),
                                        chainId: Number("480"),
                                        exposureAssetSymbol: "WETH",
                                        exposureToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        exposureTokenPrice: Number("4000e8"),
                                        borrowVenue: "MORPHO_BLUE",
                                        borrowMarketId: Hex(
                                            "0x19c682c3a37025075074cefea866fbe54656abc0fb6a7355b62a53f45b959abf"
                                        ),
                                        isShort: true
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("480"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x79a02482a880bce3f13e09da970dc34db4cd24d1"
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
        "Alice withdraws backing token where fee exceeds withdrawal amount - Tradewinds calculates total needed"
    )
    func testWithdrawBackingTokenFromShortWithFeeLargerThanAmount() async throws {
        // User wants 0.00000001 WETH net, fee is 0.000005 WETH
        // Tradewinds should withdraw 0.00000501 WETH total (amount + fee)
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                when: .withdrawBackingToken(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureToken: .usdc,
                    backingAmount: .amt(0.00000001, .weth),
                    isShort: true,
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawBackingToken(
                                    backingAmount: .amt(0.00000501, .weth),
                                    market: .morpho(.weth, .usdc),
                                    isShort: true,
                                    network: .base
                                ),
                                .quotePay(payment: .amt(0.000005, .weth), payee: .stax, quote: .basic),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction([
                            Charter.ActionContext.withdrawBackingToken(
                                Charter.ActionContext.WithdrawBackingTokenActionContext(
                                    amount: Number("5010000000000"),  // 0.00000001 + 0.000005 = 0.00000501 WETH
                                    backingAssetSymbol: "WETH",
                                    backingToken: EthAddress(
                                        "0x4200000000000000000000000000000000000006"
                                    ),
                                    backingTokenPrice: Number("400000000000"),
                                    chainId: Number("8453"),
                                    exposureAssetSymbol: "USDC",
                                    exposureToken: EthAddress(
                                        "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                    ),
                                    exposureTokenPrice: Number("100000000"),
                                    borrowVenue: "MORPHO_BLUE",
                                    borrowMarketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    isShort: true
                                )
                            ),
                            Charter.ActionContext.quotePay(
                                Charter.ActionContext.QuotePayActionContext(
                                    amount: Number("5000000000000"),
                                    assetSymbol: "WETH",
                                    chainId: Number("8453"),
                                    price: Number("400000000000"),
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
                        ])
                    ]
                )
            )
        )
    }

    @Test(
        "Alice tries to withdraw backing token from a short position on a Morpho market that does not exist (WETH/USDC)",
        .disabled("insufficient resources")
    )
    func testWithdrawBackingTokenFromShortInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .weth), .ethereum),
                    .quote(.basic),
                ],
                when: .withdrawBackingToken(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureToken: .usdc,
                    backingAmount: .amt(100, .weth),
                    isShort: true,
                    on: .ethereum
                ),
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

    @Test(
        "Alice withdraws backing token with existing balance - should force exact withdrawal from loot market"
    )
    func testWithdrawBackingTokenExactWithdrawalDespiteExistingBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    // Alice already has existing USDC token balance (more than she wants to withdraw)
                    .tokenBalance(.alice, .amt(1000, .usdc), .base),
                    .quote(.basic),
                ],
                when: .withdrawBackingToken(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureToken: .weth,
                    backingAmount: .amt(500, .usdc),  // Less than existing balance to test exact withdrawal
                    isShort: false,  // Long position
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawBackingToken(
                                    backingAmount: .amt(500.02, .usdc),  // 500 + 0.02 fee
                                    market: .morpho(.weth, .usdc),
                                    isShort: false,
                                    network: .base
                                ),
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.withdrawBackingToken(
                                    Charter.ActionContext.WithdrawBackingTokenActionContext(
                                        amount: Number("500.02e6"),  // 500 + 0.02 fee
                                        backingAssetSymbol: "USDC",
                                        backingToken: EthAddress(
                                            "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
                                        ),
                                        backingTokenPrice: Number("1e8"),
                                        chainId: Number("8453"),
                                        exposureAssetSymbol: "WETH",
                                        exposureToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        exposureTokenPrice: Number("4000e8"),
                                        borrowVenue: "MORPHO_BLUE",
                                        borrowMarketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                        ),
                                        isShort: false
                                    )
                                ),
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
                                            "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
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
