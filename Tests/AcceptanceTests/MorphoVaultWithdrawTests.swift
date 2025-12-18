@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Morpho Vault Withdraw Tests")
struct MorphoVaultWithdrawTests {
    @Test("Alice withdraws from MorphoVault, paying with QuotePay")
    func testMorphoVaultWithdrawPayingWithQuotepay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .morphoVaultSupply(.alice, .amt(5, .usdc), .usdc, .ethereum),
                    .quote(.basic),
                ],
                when: .morphoVaultWithdraw(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(2, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromMorphoVault(
                                    tokenAmount: .amt(2.1, .usdc),
                                    vault: .usdc,
                                    network: .ethereum
                                ),
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoVaultWithdraw(
                                    Charter.ActionContext.MorphoVaultWithdrawActionContext(
                                        amount: Number("2.1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
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

    @Test("Alice withdraws from MorphoVault, paying the QuotePay with the withdrawn funds")
    func testMorphoVaultWithdrawPayFromWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoVaultSupply(.alice, .amt(2.1, .usdc), .usdc, .ethereum),
                    .quote(.basic),
                ],
                when: .morphoVaultWithdraw(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(2, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromMorphoVault(
                                    tokenAmount: .amt(2.1, .usdc),
                                    vault: .usdc,
                                    network: .ethereum
                                ),
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoVaultWithdraw(
                                    Charter.ActionContext.MorphoVaultWithdrawActionContext(
                                        amount: Number("2.1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
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

    @Test(
        "Alice withdraws from MorphoVault more than she has supplied",
        .disabled("MorphoVault balance checking not currently implemented")
    )
    func testMorphoVaultWithdrawMoreThanSupply() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoVaultSupply(.alice, .amt(1, .usdc), .usdc, .ethereum),
                    .quote(.basic),
                ],
                when: .morphoVaultWithdraw(
                    from: .alice,
                    vault: .usdc,
                    amount: .amt(5, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expect .revert(.unknownRevert("MorphoVaultWithdrawError", "Insufficient supply balance"))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    @Test("Alice withdraws max from MorphoVault")
    func testMorphoVaultWithdrawMax() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoVaultSupply(.alice, .amt(5, .usdc), .usdc, .ethereum),
                    .quote(.basic),
                ],
                when: .morphoVaultWithdraw(
                    from: .alice,
                    vault: .usdc,
                    amount: .max(.usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromMorphoVault(
                                    tokenAmount: .max(.usdc),
                                    vault: .usdc,
                                    network: .ethereum
                                ),
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoVaultWithdraw(
                                    Charter.ActionContext.MorphoVaultWithdrawActionContext(
                                        amount: Number(
                                            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
                                        ),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
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

    @Test(
        "Alice withdraws max from MorphoVault, but the withdrawn amount is not enough to cover QuotePay cost"
    )
    func testMorphoVaultWithdrawMaxRevertsMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoVaultSupply(.alice, .amt(5, .usdc), .usdc, .ethereum),
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
                            fees: [.ethereum: 100]
                        )
                    ),
                ],
                when: .morphoVaultWithdraw(
                    from: .alice,
                    vault: .usdc,
                    amount: .max(.usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }
}
