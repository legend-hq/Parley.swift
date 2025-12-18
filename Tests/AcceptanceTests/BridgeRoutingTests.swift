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

    // Tests that maxAmountInstant constraint forces Tradewinds to use multiple bridge hops.
    // With max 10 USDC per bridge and target 19 USDC, the router uses:
    //   - Base→Optimism: ~9.98 (direct, limited by max 10)
    //   - Base→Polygon→Optimism: ~9.11→9.10→9.09 (multi-hop via intermediate chain)
    // Total arriving on Optimism: ~19 USDC
    @Test("Bridge max amount forces Tradewinds to use multiple bridge hops")
    func testBridgeMaxForcesMultipleHops() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(30, .usdc), .base),
                    .quote(.basic),
                    // 0.01 USDC fixed cost per bridge, 0% fee, max 10 USDC per bridge
                    .acrossQuoteWithMax(.amt(0.01, .usdc), 0.0, .amt(10, .usdc)),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(19, .usdc),
                    on: .optimism
                ),
                expect: .success(
                    .multi([
                        // Polygon→Optimism executes first (uses tokens bridged from Base→Polygon)
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .polygon,
                            destinationNetwork: .optimism,
                            inputTokenAmount: .amt(9.10, .usdc),  // 9.10 in
                            outputTokenAmount: .amt(9.09, .usdc),  // 9.09 out (minus 0.01 fee)
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // Base→Polygon: stages tokens for the Polygon→Optimism bridge
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .polygon,
                                    inputTokenAmount: .amt(9.11, .usdc),  // 9.11 in
                                    outputTokenAmount: .amt(9.10, .usdc),  // 9.10 out (minus 0.01 fee)
                                    cappedMax: false
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // Base→Optimism: direct bridge (limited by max 10)
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .optimism,
                                    inputTokenAmount: .amt(9.98, .usdc),  // 9.98 in
                                    outputTokenAmount: .amt(9.97, .usdc),  // 9.97 out (minus 0.01 fee)
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                // Total quotePay: 0.02 + 0.02 + 0.02 = 0.06 USDC
                                .quotePay(
                                    payment: .amt(0.06, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // Final transfer: 9.09 + 9.97 ≈ 19.06 USDC available, send 19 USDC
                                .transferErc20(
                                    tokenAmount: .amt(19, .usdc),
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
