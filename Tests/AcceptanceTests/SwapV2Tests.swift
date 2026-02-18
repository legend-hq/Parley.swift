@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("SwapV2 Tests")
struct SwapV2Tests {
    @Test("SwapV2 exact-in single chain swap")
    func testSwapV2ExactInSingleChain() async throws {
        // Alice swaps 500 USDC for WETH on Base using swap hints
        // Rate: 0.00025 WETH per USDC (1 USDC = 0.00025 WETH, i.e., 1 WETH = 4000 USDC)
        // Output: 500 * 0.00025 = 0.125 WETH
        // Fee: 0.15% of output = 0.125 * 0.0015 = 0.0001875 WETH
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base),
                    .swapHint(on: .base, sell: .usdc, buy: .weth, capacity: .amt(10000, .usdc), rate: 0.00025),
                ],
                when: .swapV2(
                    from: .alice,
                    sellAssetSymbol: "USDC",
                    buyAssetSymbol: "WETH",
                    sellAmount: Number("500e6"),
                    isBuy: true
                ),
                expect: .successWithActions(
                    .single(
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(500, .usdc),
                            // 500 * 0.00025 = 0.125 WETH (+ 1 wei precision)
                            buyAmount: .init(fromWei: 125_000_000_000_000_001, ofToken: .weth),
                            feeAmount: .amt(0.0001875, .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .base,
                            executionType: .immediate
                        )
                    ),
                    [
                        Charter.ActionContext.swap(
                            Charter.ActionContext.SwapActionContext(
                                chainId: Number("8453"),
                                feeAmounts: [Number("0.0001875e18")],
                                feeAssetSymbols: ["WETH"],
                                feeTokens: [EthAddress("0x4200000000000000000000000000000000000006")],
                                feeTokenPrices: [Number("4000e8")],
                                feeDescriptions: ["LEGEND"],
                                inputAmount: Number("500e6"),
                                inputAssetSymbol: "USDC",
                                inputToken: EthAddress("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"),
                                inputTokenPrice: Number("1e8"),
                                outputAmount: Number("0.125000000000000001e18"),
                                outputAssetSymbol: "WETH",
                                outputToken: EthAddress("0x4200000000000000000000000000000000000006"),
                                outputTokenPrice: Number("4000e8"),
                                isExactOut: false,
                                isBuy: true,
                                isCappedMax: false,
                                useFiller: true
                            )
                        ),
                    ]
                )
            )
        )
    }

    @Test("SwapV2 max intent uses all available balance")
    func testSwapV2MaxIntentUsesAllBalance() async throws {
        // Alice swaps all her USDC (max intent) for WETH
        // Balance: 500 USDC, Rate: 0.00025 WETH/USDC
        // Output: 500 * 0.00025 = 0.125 WETH
        // Fee: 0.15% of output = 0.0001875 WETH
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(500, .usdc), .base),
                    .swapHint(on: .base, sell: .usdc, buy: .weth, capacity: .amt(10000, .usdc), rate: 0.00025),
                ],
                when: .swapV2(
                    from: .alice,
                    sellAssetSymbol: "USDC",
                    buyAssetSymbol: "WETH",
                    sellAmount: Number.MAX_UINT_256,
                    isBuy: true
                ),
                expect: .success(
                    .single(
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(500, .usdc),
                            // 500 * 0.00025 = 0.125 WETH (+ 1 wei precision)
                            buyAmount: .init(fromWei: 125_000_000_000_000_001, ofToken: .weth),
                            feeAmount: .amt(0.0001875, .weth),
                            feeRecipient: .stax,
                            cappedMax: true,
                            network: .base,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("SwapV2 exact-in with cross-chain bridge")
    func testSwapV2ExactInWithBridge() async throws {
        // Alice has USDC on Arbitrum but swap hint is on Base
        // 500 USDC bridges from Arbitrum to Base (1% + 1 USDC fee = 494 USDC arrives)
        // Then swaps on Base at 0.00025 rate
        // Output: 494 * 0.00025 = 0.1235 WETH
        // Fee: 0.15% of output = 0.00018525 WETH
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .arbitrum),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% bridge fee + 1 USDC fixed
                    .swapHint(on: .base, sell: .usdc, buy: .weth, capacity: .amt(10000, .usdc), rate: 0.00025),
                ],
                when: .swapV2(
                    from: .alice,
                    sellAssetSymbol: "USDC",
                    buyAssetSymbol: "WETH",
                    sellAmount: Number("500e6"),
                    isBuy: true
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .arbitrum,
                            destinationNetwork: .base,
                            inputTokenAmount: .amt(500, .usdc),
                            // Bridge output: 500 * 0.99 - 1 = 494 USDC
                            outputTokenAmount: .amt(494, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(494, .usdc),
                            // 494 * 0.00025 = 0.1235 WETH (+ 1 wei precision)
                            buyAmount: .init(fromWei: 123_500_000_000_000_001, ofToken: .weth),
                            feeAmount: .amt(0.00018525, .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .base,
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("SwapV2 exact-in fails with insufficient balance")
    func testSwapV2InsufficientBalance() async throws {
        // Alice has 300 USDC but wants to sell 500 USDC
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(300, .usdc), .base),
                    .swapHint(on: .base, sell: .usdc, buy: .weth, capacity: .amt(10000, .usdc), rate: 0.00025),
                ],
                when: .swapV2(
                    from: .alice,
                    sellAssetSymbol: "USDC",
                    buyAssetSymbol: "WETH",
                    sellAmount: Number("500e6"),
                    isBuy: true
                ),
                expect: .failure(
                    Charter.CharterError.insufficientBalance(
                        symbol: "USDC",
                        required: Number("500e6"),
                        available: Number("300e6")
                    )
                )
            )
        )
    }

    @Test("SwapV2 exact-in with multiple tiers")
    func testSwapV2MultipleTiers() async throws {
        // Alice swaps 300 USDC using two tiers:
        // Tier 1: First 100 USDC at rate 0.0003 (1 WETH = 3333 USDC) = 0.03 WETH
        // Tier 2: Next 200 USDC at rate 0.00025 (1 WETH = 4000 USDC) = 0.05 WETH
        // Total: 0.08 WETH
        // Fee: 0.15% of output = 0.00012 WETH
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base),
                    // Tier 1: First 100 USDC at better rate 0.0003
                    .swapHint(on: .base, sell: .usdc, buy: .weth, capacity: .amt(100, .usdc), rate: 0.0003),
                    // Tier 2: Next 900 USDC at rate 0.00025
                    .swapHint(on: .base, sell: .usdc, buy: .weth, capacity: .amt(900, .usdc), rate: 0.00025),
                ],
                when: .swapV2(
                    from: .alice,
                    sellAssetSymbol: "USDC",
                    buyAssetSymbol: "WETH",
                    sellAmount: Number("300e6"),
                    isBuy: true
                ),
                expect: .success(
                    .single(
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(300, .usdc),
                            // 100 * 0.0003 + 200 * 0.00025 = 0.03 + 0.05 = 0.08 WETH (- 1 wei)
                            buyAmount: .init(fromWei: 79_999_999_999_999_999, ofToken: .weth),
                            feeAmount: .init(fromWei: 119_999_999_999_999, ofToken: .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .base,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("SwapV2 exact-in with multi-chain swap hints")
    func testSwapV2MultiChain() async throws {
        // Alice has USDC on both Base and Arbitrum
        // Tradewinds should optimize routing across chains by bridging to the better rate chain
        //
        // Setup:
        // - Base: 600 USDC, rate 0.00025 WETH/USDC (worse)
        // - Arbitrum: 400 USDC, rate 0.0003 WETH/USDC (20% better)
        // - Bridge: 1% fee + 1 USDC fixed cost
        // - Want to swap 500 USDC total
        //
        // Optimal path (chosen by Tradewinds):
        // 1. Bridge 100 USDC from Base to Arbitrum: pays 1% fee + 1 USDC = receives 98 USDC
        // 2. Swap 498 USDC (400 existing + 98 bridged) on Arbitrum at better rate
        //    498 * 0.0003 = 0.1494 WETH (- 2 wei precision)
        //    Fee: 0.15% of 0.1494 WETH = 0.0002241 WETH
        //
        // This gives 0.1494 WETH vs 0.145 WETH if we swapped on both chains separately (~3% more)
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(600, .usdc), .base),
                    .tokenBalance(.alice, .amt(400, .usdc), .arbitrum),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% bridge fee
                    // Better rate on Arbitrum (0.0003 vs 0.00025)
                    .swapHint(on: .base, sell: .usdc, buy: .weth, capacity: .amt(10000, .usdc), rate: 0.00025),
                    .swapHint(on: .arbitrum, sell: .usdc, buy: .weth, capacity: .amt(10000, .usdc), rate: 0.0003),
                ],
                when: .swapV2(
                    from: .alice,
                    sellAssetSymbol: "USDC",
                    buyAssetSymbol: "WETH",
                    sellAmount: Number("500e6"),
                    isBuy: true
                ),
                // Optimal: Bridge to Arbitrum then swap all there at better rate
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            inputTokenAmount: .amt(100, .usdc),
                            // Bridge output: 100 * 0.99 - 1 = 98 USDC
                            outputTokenAmount: .amt(98, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .swap(
                            filler: .filler,
                            sellAmount: .amt(498, .usdc),  // 400 + 98 = 498 USDC
                            // 498 * 0.0003 = 0.1494 WETH (- 2 wei precision)
                            buyAmount: .init(fromWei: 149_399_999_999_999_998, ofToken: .weth),
                            feeAmount: .init(fromWei: 224_099_999_999_999, ofToken: .weth),
                            feeRecipient: .stax,
                            cappedMax: false,
                            network: .arbitrum,
                            executionType: .contingent  // Contingent on bridge completing
                        ),
                    ])
                )
            )
        )
    }

    @Test("SwapV2 with ETH wrapping")
    func testSwapV2WithEthWrapping() async throws {
        // Alice has ETH and wants USDC
        // ETH gets wrapped to WETH first (1:1), then swapped to USDC
        // Swap: 0.5 WETH -> 2000 USDC (1 WETH = 4000 USDC)
        // Fee: 0.15% of output = 3 USDC
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .eth), .base),
                    // Swap hint: WETH -> USDC at rate 4000 USDC/WETH
                    .swapHint(on: .base, sell: .weth, buy: .usdc, capacity: .amt(10, .weth), rate: 4000),
                ],
                when: .swapV2(
                    from: .alice,
                    sellAssetSymbol: "ETH",
                    buyAssetSymbol: "USDC",
                    sellAmount: Number("0.5e18"),
                    isBuy: true
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(0.5, .weth),
                                    // 0.5 * 4000 = 2000 USDC
                                    buyAmount: .amt(2000, .usdc),
                                    feeAmount: .amt(3, .usdc),
                                    feeRecipient: .stax,
                                    cappedMax: false,
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
