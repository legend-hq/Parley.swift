@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Aave Withdraw Tests")
struct AaveWithdrawTests {
    @Test("Alice withdraw 0.5 WETH to Aave")
    func testAaveWithdrawWETHTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .aaveSupply(.alice, .amt(1.0, .weth), .baseV3, .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .weth,
                    .aaveWithdraw(
                        from: .alice,
                        market: .baseV3,
                        amount: .amt(0.5, .weth),
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromAave(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("500005e12"),  // 0.5 WETH + 0.000005 WETH fee
                                        ofToken: .weth
                                    ),
                                    pool: .baseV3,
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
                                Charter.ActionContext.aaveWithdraw(
                                    Charter.ActionContext.AaveWithdrawActionContext(
                                        amount: Number("500005e12"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("4000e8"),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
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

    @Test("Alice withdraw 0.5 WETH to Aave and pay QuotePay with the withdrawn funds")
    func testAaveWithdrawWETHPayFromWithdrawTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .aaveSupply(.alice, .amt(0.500005, .weth), .baseV3, .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .weth,
                    .aaveWithdraw(
                        from: .alice,
                        market: .baseV3,
                        amount: .amt(0.5, .weth),
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromAave(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("500005e12"),  // 0.5 WETH + 0.000005 WETH fee
                                        ofToken: .weth
                                    ),
                                    pool: .baseV3,
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
                                Charter.ActionContext.aaveWithdraw(
                                    Charter.ActionContext.AaveWithdrawActionContext(
                                        amount: Number("500005e12"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("4000e8"),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
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

    @Test("Alice withdraws from Aave, paying with QuotePay")
    func testAaveWithdrawPayingWithQuotepayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .aaveSupply(.alice, .amt(0.52, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .usdc,
                    .aaveWithdraw(
                        from: .alice,
                        market: .baseV3,
                        amount: .amt(0.5, .usdc),
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromAave(
                                    tokenAmount: .amt(0.52, .usdc),
                                    pool: .baseV3,
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
                                Charter.ActionContext.aaveWithdraw(
                                    Charter.ActionContext.AaveWithdrawActionContext(
                                        amount: Number("0.52e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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

    @Test("Alice withdraws from Aave, paying the QuotePay with the withdrawn funds")
    func testAaveWithdrawPayFromWithdrawTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .aaveSupply(.alice, .amt(0.52, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .usdc,
                    .aaveWithdraw(
                        from: .alice,
                        market: .baseV3,
                        amount: .amt(0.5, .usdc),
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromAave(
                                    tokenAmount: .amt(0.52, .usdc),
                                    pool: .baseV3,
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
                                Charter.ActionContext.aaveWithdraw(
                                    Charter.ActionContext.AaveWithdrawActionContext(
                                        amount: Number("0.52e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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

    @Test("Alice withdraws max from Aave")
    func testAaveWithdrawMaxTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .aaveSupply(.alice, .amt(5, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .usdc,
                    .aaveWithdraw(
                        from: .alice,
                        market: .baseV3,
                        amount: .max(.usdc),
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromAave(
                                    tokenAmount: .max(.usdc),
                                    pool: .baseV3,
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
                                Charter.ActionContext.aaveWithdraw(
                                    Charter.ActionContext.AaveWithdrawActionContext(
                                        amount: Number(
                                            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
                                        ),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
        "Alice withdraws max from Aave, but the withdrawn amount is not enough to cover QuotePay cost"
    )
    func testAaveWithdrawMaxRevertsMaxCostTooHighTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .aaveSupply(.alice, .amt(50, .usdc), .baseV3, .base),  // Has 50 USDC but fee is 100 USDC
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
                            fees: [.base: 100]
                        )
                    ),
                ],
                when: .payWith(
                    currency: .usdc,
                    .aaveWithdraw(
                        from: .alice,
                        market: .baseV3,
                        amount: .max(.usdc),
                        on: .base
                    )
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }
}
