@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Comet Withdraw Tests")
struct CometWithdrawTests {
    @Test("Alice withdraws 1 cbBTC from Comet, paying with QuotePay")
    func testCometWithdrawWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(1.5, .cbbtc), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .cometWithdraw(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(1, .cbbtc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("100000100"),  // 1 cbBTC + 0.000001 cbBTC fee
                                        ofToken: .cbbtc
                                    ),
                                    market: .cusdcv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000001, .cbbtc),
                                    payee: .stax,
                                    quote: .basic  // Same currency as withdrawal
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("100000100"),  // 1 cbBTC + 0.000001 fee
                                        assetSymbol: "cbBTC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("100000e8"),  // $100k in proper units
                                        token: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        )  // cbBTC address
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000001e8"),  // 0.000001 cbBTC fee
                                        assetSymbol: "cbBTC",
                                        chainId: Number("1"),  // Same currency as withdrawal
                                        price: Number("100000e8"),  // $100k in proper units
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                        )  // cbBTC address
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice withdraws from Comet, paying with the withdrawn funds")
    func testCometWithdrawPayFromWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(2, .usdc), .cusdcv3, .ethereum),  // Need USDC in Comet to withdraw
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .ethereum: 0.5
                            ]
                        )
                    ),
                ],
                when: .cometWithdraw(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(1, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(1.5, .usdc),
                                    market: .cusdcv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.5, .usdc),
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
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("1.5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),  // Proper price units
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        price: Number("1e8"),  // Proper price units
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

    @Test("Alice withdraws max from Comet")
    func testCometWithdrawMax() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .cometSupply(.alice, .amt(1, .usdc), .cusdcv3, .ethereum),
                ],
                when: .cometWithdraw(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .max(.usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
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
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number(
                                            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
                                        ),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),  // Proper price units
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        price: Number("1e8"),  // Proper price units
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

    @Test("Alice withdraws, but the withdrawn amount cannot cover the operation cost")
    func testCometWithdrawCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .ethereum: 5
                            ]
                        )
                    )
                ],
                when: .cometWithdraw(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(1, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 0))
                // but now returns .routeNotFound when withdrawal amount can't cover operation cost
                expect: .failure(.routeNotFound(symbol: "USDC", routeType: "cometWithdraw"))
            )
        )
    }

    @Test(
        "Alice withdraws max from Comet, but the withdrawn amount cannot cover the operation cost"
    )
    func testCometWithdrawMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(1, .usdc), .cusdcv3, .ethereum),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .ethereum: 100
                            ]
                        )
                    ),
                ],
                when: .cometWithdraw(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .max(.usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }

    @Test("Alice withdraws amount below QuotePay fee from Comet")
    func testCometWithdrawAmountBelowQuotePayFee() async throws {
        // User wants 0.1 USDC net, but QuotePay fee is 0.5 USDC.
        // Tradewinds figures out to withdraw 0.6 USDC (0.1 target + 0.5 fee)
        // so the user ends up with 0.1 USDC after paying the fee.
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .ethereum),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .ethereum: 0.5
                            ]
                        )
                    ),
                ],
                when: .cometWithdraw(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(0.1, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(0.6, .usdc),
                                    market: .cusdcv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.5, .usdc),
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
