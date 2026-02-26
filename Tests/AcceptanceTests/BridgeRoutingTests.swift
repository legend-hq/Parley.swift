@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Bridge Routing Tests")
struct BridgeRoutingTests {
    @Test("Supply intent chooses 2-hop Base→Arbitrum→Optimism over direct Base→Optimism")
    func testSupplyChooses2HopRoute() async throws {
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
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            inputTokenAmount: .amt(10.02, .usdc),
                            outputTokenAmount: .amt(10.02, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .arbitrum,
                            destinationNetwork: .optimism,
                            inputTokenAmount: .amt(10.02, .usdc),
                            outputTokenAmount: .amt(10.02, .usdc),
                            cappedMax: false,
                            executionType: .contingent
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
    //   - Base→Arbitrum: ~9.09 (via intermediate chain)
    //   - Base→Optimism: ~10.0 (direct, limited by max 10)
    //   - Arbitrum→Optimism: ~9.07 (forwarding from Base→Arbitrum)
    // Total arriving on Optimism: ~19 USDC
    //
    // Execution order:
    //   1. Base operations (IMMEDIATE): initiate both bridges from Base
    //   2. Arbitrum→Optimism (CONTINGENT): waits for tokens to arrive from Base→Arbitrum
    //   3. Final transfer (CONTINGENT): waits for all bridges to complete
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
                        // Step 1: Base operations - initiate both bridges from Base
                        .multicall(
                            [
                                // Base→Arbitrum: stages tokens for the Arbitrum→Optimism bridge
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: .amt(9.09, .usdc),
                                    outputTokenAmount: .amt(9.08, .usdc),
                                    cappedMax: false
                                ),
                                // Base→Optimism: direct bridge (limited by max 10)
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .optimism,
                                    inputTokenAmount: .amt(10, .usdc),
                                    outputTokenAmount: .amt(9.99, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        // Step 2: Arbitrum→Optimism - waits for tokens to arrive from Base→Arbitrum
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .arbitrum,
                            destinationNetwork: .optimism,
                            inputTokenAmount: .amt(9.08, .usdc),
                            outputTokenAmount: .amt(9.07, .usdc),
                            cappedMax: false,
                            executionType: .contingent
                        ),
                        // Step 3: Final transfer - waits for all bridges to complete
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.06, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
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

    @Test("Transfer intent chooses 2-hop Base→Arbitrum→Optimism over direct Base→Optimism")
    func testTransferChooses2HopRoute() async throws {
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
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            inputTokenAmount: .amt(10.02, .usdc),
                            outputTokenAmount: .amt(10.02, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .arbitrum,
                            destinationNetwork: .optimism,
                            inputTokenAmount: .amt(10.02, .usdc),
                            outputTokenAmount: .amt(10.02, .usdc),
                            cappedMax: false,
                            executionType: .contingent
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
