@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Bridge Routing Tests")
struct BridgeRoutingTests {
    @Test("Supply intent chooses direct route Base→Optimism over 2-hop Base→Arbitrum→Optimism")
    func testSupplyChoosesDirectRoute() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(20, .usdc), .base),
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
                                .base: 0.10,
                                .arbitrum: 0.04,
                                .optimism: 0.02,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(0, .usdc), 0.0),
                ],
                when: .cometSupply(
                    from: .alice,
                    market: .cusdcv3,
                    amount: .amt(10, .usdc),
                    on: .optimism
                ),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.10, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .optimism,
                                    inputTokenAmount: .amt(10.02, .usdc),
                                    outputTokenAmount: .amt(10.02, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToComet(
                                    tokenAmount: .amt(10, .usdc),
                                    market: .cusdcv3,
                                    cappedMax: false,
                                    network: .optimism
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Transfer intent chooses direct route Base→Optimism over 2-hop Base→Arbitrum→Optimism")
    func testTransferChoosesDirectBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
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
                                .base: 0.10,
                                .arbitrum: 0.04,
                                .optimism: 0.02,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(0, .usdc), 0.0),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(10, .usdc),
                    on: .optimism
                ),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.10, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .optimism,
                                    inputTokenAmount: .amt(10.02, .usdc),
                                    outputTokenAmount: .amt(10.02, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .transferErc20(
                                    tokenAmount: .amt(10, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .optimism
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }
}
