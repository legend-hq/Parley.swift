import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for SwapV2 intents (swap hints with virtual balance constraint)
struct CharterTradewindsSwapV2Tests {
    /// Test SwapV2 exact-in with single chain swap hint.
    /// With virtual balance node, exactly sellAmount flows from virtual → tokenBalance → swap.
    @Test("SwapV2 exact-in with single chain swap hint")
    func testSwapV2ExactInSingleChain() {
        runFlowTest(
            ChartTestCase(
                name: "SwapV2 exact-in single chain",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base),
                    // Swap hint: USDC → WETH on Base at rate 0.0003 (300 USDC = 0.09 WETH)
                    .swapHint(.base, .usdc, .weth, "0x", Number("10000e6"), .amt(10000, .usdc), 0.0003e12),
                ],
                intent: .swapV2(
                    Charter.SwapIntentV2(
                        sellAssetSymbol: "USDC",
                        buyAssetSymbol: "WETH",
                        sellAmount: Number("500e6"),  // Sell exactly 500 USDC
                        sender: Account.alice.address,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Virtual balance node to token balance
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .balancePassthrough,
                                source: .virtualBalance(
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number("1000e6")  // maxFlow = actual chain balance
                            ),
                            amount: "500e6"
                        ),
                        // Flow 2: Token balance to swap
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: Number("2.97e18"),  // 10000 * 0.0003 * 0.99 slippage = 2.97 WETH
                                    swapQuoteSellAmount: Number("10000e6"),
                                    swapQuoteBuyAmount: Number("2.97e18"),  // Slippage-adjusted tier buy amount
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: Number(0),
                                    isExactOut: false,
                                    isCappedMax: false,
                                    venue: "0x"
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                // Rate = swap hint rate * slippage factor (0.99)
                                rate: Percentage(fromDouble: 0.0003e12) * (Percentage.one - Charter.SWAP_MAX_SLIPPAGE),
                                minFlow: Number(0),
                                maxFlow: Number("10000e6")
                            ),
                            amount: "500e6"
                        ),
                        // Flow 3: Settlement (WETH to settlement node)
                        // Note: Due to precision in rate calculations, actual amount is ~2 wei less than ideal
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swapSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                sink: .swapSettlement(wallet: Account.alice.address),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: Number("0.148499999999999998e18")
                        ),
                    ],
                    maxFlow: Number("0.148499999999999998e18")  // Max flow is the WETH output
                )
            )
        )
    }

    /// Test SwapV2 max intent (no sell amount constraint).
    /// When sellAmount is MAX_UINT_256, virtual balance node resource is .max.
    @Test("SwapV2 max intent uses all available balance")
    func testSwapV2MaxIntentUsesAllBalance() {
        runFlowTest(
            ChartTestCase(
                name: "SwapV2 max intent",
                givens: [
                    .tokenBalance(.alice, .amt(500, .usdc), .base),
                    .swapHint(.base, .usdc, .weth, "0x", Number("10000e6"), .amt(10000, .usdc), 0.0003e12),
                ],
                intent: .swapV2(
                    Charter.SwapIntentV2(
                        sellAssetSymbol: "USDC",
                        buyAssetSymbol: "WETH",
                        sellAmount: Number.MAX_UINT_256,  // Max intent
                        sender: Account.alice.address,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // For max intent, virtual node resource is .max (no constraint)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .balancePassthrough,
                                source: .virtualBalance(
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number("500e6")  // maxFlow = actual chain balance
                            ),
                            amount: "500e6"  // Uses all available balance
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: Number("2.97e18"),  // Full tier * 0.99 slippage
                                    swapQuoteSellAmount: Number("10000e6"),
                                    swapQuoteBuyAmount: Number("2.97e18"),
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: Number(0),
                                    isExactOut: false,
                                    isCappedMax: true,
                                    venue: "0x"
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                // Rate = base rate * SWAP_OUTPUT_BUFFER (1.015) * slippage (0.99)
                                rate: Percentage(fromDouble: 0.0003e12) * Charter.SWAP_OUTPUT_BUFFER * (Percentage.one - Charter.SWAP_MAX_SLIPPAGE),
                                minFlow: Number(0),
                                maxFlow: Number("10000e6")
                            ),
                            amount: "500e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swapSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                sink: .swapSettlement(wallet: Account.alice.address),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number.MAX_UINT_256
                            ),
                            // Actual computed value with precision
                            amount: Number("0.150727499999999998e18")
                        ),
                    ],
                    maxFlow: Number("0.150727499999999998e18")
                )
            )
        )
    }

    /// Test SwapV2 exact-in with bridging.
    /// The virtual balance constrains source-side (what leaves wallet), not swap-side.
    @Test("SwapV2 exact-in with cross-chain bridge")
    func testSwapV2ExactInWithBridge() {
        runFlowTest(
            ChartTestCase(
                name: "SwapV2 exact-in with bridge",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .arbitrum),  // Balance on Arbitrum
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% bridge fee, 1 USDC fixed
                    // Swap hint on Base
                    .swapHint(.base, .usdc, .weth, "0x", Number("10000e6"), .amt(10000, .usdc), 0.0003e12),
                ],
                intent: .swapV2(
                    Charter.SwapIntentV2(
                        sellAssetSymbol: "USDC",
                        buyAssetSymbol: "WETH",
                        sellAmount: Number("500e6"),  // Sell exactly 500 USDC from wallet
                        sender: Account.alice.address,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Virtual balance to token balance (passthrough)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .balancePassthrough,
                                source: .virtualBalance(
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number("1000e6")  // Actual chain balance
                            ),
                            amount: "500e6"
                        ),
                        // Flow 2: Bridge from Arbitrum to Base (500 USDC in, ~494 USDC out after 1% + 1 fee)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 1% fee
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e6")
                                ],
                                minFlow: Number(0),
                                maxFlow: Number("10000e6")
                            ),
                            amount: "500e6"  // 500 in, ~494 out
                        ),
                        // Flow 3: Swap on Base (~494 USDC → ~0.1467 WETH after slippage)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: Number("2.97e18"),  // Full tier * 0.99 slippage
                                    swapQuoteSellAmount: Number("10000e6"),
                                    swapQuoteBuyAmount: Number("2.97e18"),
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: Number(0),
                                    isExactOut: false,
                                    isCappedMax: false,
                                    venue: "0x"
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                // Rate = swap hint rate * slippage factor (0.99)
                                rate: Percentage(fromDouble: 0.0003e12) * (Percentage.one - Charter.SWAP_MAX_SLIPPAGE),
                                minFlow: Number(0),
                                maxFlow: Number("10000e6")
                            ),
                            amount: "494e6"
                        ),
                        // Flow 4: Settlement
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swapSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                sink: .swapSettlement(wallet: Account.alice.address),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number.MAX_UINT_256
                            ),
                            // Actual computed value with precision
                            amount: Number("0.146717999999999998e18")
                        ),
                    ],
                    maxFlow: Number("0.146717999999999998e18")
                )
            )
        )
    }

    /// Test SwapV2 with multiple tiers from same venue.
    /// Virtual balance should constrain total sell, Tradewinds optimally fills tiers.
    @Test("SwapV2 exact-in with multiple tiers")
    func testSwapV2ExactInWithMultipleTiers() {
        runFlowTest(
            ChartTestCase(
                name: "SwapV2 exact-in multiple tiers",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base),
                    // Tier 1: First 100 USDC at rate 0.0004 (better rate)
                    .swapHint(.base, .usdc, .weth, "0x", Number("100e6"), .amt(100, .usdc), 0.0004e12),
                    // Tier 2: Next 900 USDC at rate 0.00035 (worse rate)
                    .swapHint(.base, .usdc, .weth, "0x", Number("1000e6"), .amt(900, .usdc), 0.00035e12),
                ],
                intent: .swapV2(
                    Charter.SwapIntentV2(
                        sellAssetSymbol: "USDC",
                        buyAssetSymbol: "WETH",
                        sellAmount: Number("300e6"),  // Sell 300 USDC (fills tier 1 + part of tier 2)
                        sender: Account.alice.address,
                        isBuy: false
                    )
                ),
                // Use unorderedFlows because tier order from Tradewinds may vary
                expect: .unorderedFlows(
                    [
                        // Virtual balance to token balance (passthrough)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .balancePassthrough,
                                source: .virtualBalance(
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number("1000e6")  // Actual chain balance
                            ),
                            amount: "300e6"
                        ),
                        // Tier 1: Fill 100 USDC at rate 0.0004 * 0.99 slippage
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: Number("0.0396e18"),  // 100 * 0.0004 * 0.99 = 0.0396 WETH
                                    swapQuoteSellAmount: Number("100e6"),
                                    swapQuoteBuyAmount: Number("0.0396e18"),
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: Number(0),
                                    isExactOut: false,
                                    isCappedMax: false,
                                    venue: "0x"
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                // Rate = swap hint rate * slippage factor (0.99)
                                rate: Percentage(fromDouble: 0.0004e12) * (Percentage.one - Charter.SWAP_MAX_SLIPPAGE),
                                minFlow: Number(0),
                                maxFlow: Number("100e6")
                            ),
                            amount: "100e6"
                        ),
                        // Tier 2: Fill remaining 200 USDC at rate 0.00035 * 0.99 slippage
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: Number("0.31185e18"),  // 900 * 0.00035 * 0.99 = 0.31185 WETH
                                    swapQuoteSellAmount: Number("900e6"),
                                    swapQuoteBuyAmount: Number("0.31185e18"),
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: Number(0),
                                    isExactOut: false,
                                    isCappedMax: false,
                                    venue: "0x"
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                // Rate = swap hint rate * slippage factor (0.99)
                                rate: Percentage(fromDouble: 0.00035e12) * (Percentage.one - Charter.SWAP_MAX_SLIPPAGE),
                                minFlow: Number(0),
                                maxFlow: Number("900e6")
                            ),
                            amount: "200e6"
                        ),
                        // Settlement
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swapSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: Account.alice.address
                                ),
                                sink: .swapSettlement(wallet: Account.alice.address),
                                rate: Percentage.one,
                                minFlow: Number(0),
                                maxFlow: Number.MAX_UINT_256
                            ),
                            // Actual computed value with precision
                            amount: Number("0.108899999999999999e18")
                        ),
                    ],
                    maxFlow: Number("0.108899999999999999e18")
                )
            )
        )
    }

    /// Test SwapV2 exact-in fails when insufficient balance.
    @Test("SwapV2 exact-in fails with insufficient balance")
    func testSwapV2ExactInInsufficientBalance() {
        runFlowTest(
            ChartTestCase(
                name: "SwapV2 exact-in insufficient balance",
                givens: [
                    .tokenBalance(.alice, .amt(300, .usdc), .base),
                    .swapHint(.base, .usdc, .weth, "0x", Number("10000e6"), .amt(10000, .usdc), 0.0003e12),
                ],
                intent: .swapV2(
                    Charter.SwapIntentV2(
                        sellAssetSymbol: "USDC",
                        buyAssetSymbol: "WETH",
                        sellAmount: Number("500e6"),  // Want to sell 500 but only have 300
                        sender: Account.alice.address,
                        isBuy: false
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.insufficientBalance(
                        symbol: "USDC",
                        required: Number("500e6"),
                        available: Number("300e6")
                    )
                )
            )
        )
    }

    /// Test SwapIntentV2 fails when no matching hints exist
    @Test("SwapV2 fails when no matching hints in Folio")
    func testSwapV2FailsWithNoMatchingHints() {
        runFlowTest(
            ChartTestCase(
                name: "SwapV2 fails when no matching hints",
                givens: [
                    .tokenBalance(.alice, .amt(500, .usdc), .base),
                    // Only USDC -> LINK hint available
                    .swapHint(.base, .usdc, .link, "0x", Number("100e6"), .amt(100, .usdc), 0.04e12),
                ],
                intent: .swapV2(Charter.SwapIntentV2(
                    sellAssetSymbol: "USDC",
                    buyAssetSymbol: "WETH",  // No hints for this pair
                    sellAmount: Number("100e6"),
                    sender: Account.alice.address,
                    isBuy: false
                )),
                // No path to WETH (no hints produce WETH), so flowWithResult returns insufficientResources
                expect: .failure(
                    Tradewinds.Error.insufficientResources(target: .max, max: Number(0)),
                    maxFlow: Number(0)
                )
            )
        )
    }
}
