import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Unit tests for SwapHints helper functions (tier aggregation).
struct CharterTradewindsSwapHintTests {

    // MARK: - Tier Aggregation Tests

    /// Test that the aggregation function correctly combines flows with the same venue
    @Test("Aggregation combines parallel swap flows")
    func testAggregationCombinesParallelSwapFlows() {
        let wallet = EthAddress("0x00000000000000000000000000000000000A11CE")
        let usdcSource = TradewindsLegendNode.tokenBalance(
            network: .base, address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
            symbol: "USDC", wallet: wallet.on(.base)
        )
        let wethSink = TradewindsLegendNode.tokenBalance(
            network: .base, address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
            symbol: "WETH", wallet: wallet.on(.base)
        )

        // Two swap flows from same venue (should be aggregated)
        let swapFlow1 = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: Tradewinds.Route(
                type: .swap(
                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                    buyAmount: "0.04e18",
                    swapQuoteSellAmount: "100e6",
                    swapQuoteBuyAmount: "0.04e18",
                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                    feeAmount: Number(0),
                    isExactOut: false,
                    isCappedMax: true,
                    venue: "0x"
                ),
                source: usdcSource, sink: wethSink,
                rate: Percentage(fromRatio: Number("0.04e18").asSNumber, over: Number("100e6").asSNumber),
                minFlow: Number(0), maxFlow: "100e6"
            ),
            amount: "100e6"
        )

        let swapFlow2 = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: Tradewinds.Route(
                type: .swap(
                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                    buyAmount: "0.34e18",
                    swapQuoteSellAmount: "400e6",
                    swapQuoteBuyAmount: "0.34e18",
                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                    feeAmount: Number(0),
                    isExactOut: false,
                    isCappedMax: true,
                    venue: "0x"
                ),
                source: usdcSource, sink: wethSink,
                rate: Percentage(fromRatio: Number("0.34e18").asSNumber, over: Number("900e6").asSNumber),
                minFlow: Number(0), maxFlow: "900e6"
            ),
            amount: "400e6"
        )

        // Bridge flow (should pass through unchanged)
        let bridgeFlow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: Tradewinds.Route(
                type: .bridge(bridgeType: .across, isCappedMax: false),
                source: usdcSource,
                sink: .tokenBalance(
                    network: .arbitrum, address: ArbitrumNetwork.Assets.USDC.assetAddress.on(.arbitrum),
                    symbol: "USDC", wallet: wallet.on(.arbitrum)
                ),
                rate: Percentage(1),
                minFlow: Number(0), maxFlow: Number.MAX_UINT_256
            ),
            amount: "50e6"
        )

        let aggregated = SwapHints.aggregateFlows([swapFlow1, swapFlow2, bridgeFlow])

        // Expected: [aggregatedSwap, bridge] - swaps aggregated at position of first swap
        let expectedBuyAmount = swapFlow1.sinkAmount + swapFlow2.sinkAmount
        let expectedAggregatedSwap = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: Tradewinds.Route(
                type: .swap(
                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                    buyAmount: expectedBuyAmount,
                    swapQuoteSellAmount: Number("500e6"),
                    swapQuoteBuyAmount: expectedBuyAmount,
                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                    feeAmount: Number(0),
                    isExactOut: false,
                    isCappedMax: true,
                    venue: "0x"
                ),
                source: usdcSource, sink: wethSink,
                rate: Percentage(fromRatio: expectedBuyAmount.asSNumber, over: Number("500e6").asSNumber),
                minFlow: Number(0), maxFlow: Number("500e6")
            ),
            amount: Number("500e6")
        )

        #expect(aggregated == [expectedAggregatedSwap, bridgeFlow])
    }

    /// Test that flows from different venues are NOT aggregated together
    @Test("Aggregation keeps different venues separate")
    func testAggregationKeepsDifferentVenuesSeparate() {
        let wallet = EthAddress("0x00000000000000000000000000000000000A11CE")
        let usdcSource = TradewindsLegendNode.tokenBalance(
            network: .base, address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
            symbol: "USDC", wallet: wallet.on(.base)
        )
        let wethSink = TradewindsLegendNode.tokenBalance(
            network: .base, address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
            symbol: "WETH", wallet: wallet.on(.base)
        )

        let flow0x = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: Tradewinds.Route(
                type: .swap(
                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                    buyAmount: "0.04e18",
                    swapQuoteSellAmount: "100e6",
                    swapQuoteBuyAmount: "0.04e18",
                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                    feeAmount: Number(0),
                    isExactOut: false,
                    isCappedMax: true,
                    venue: "0x"
                ),
                source: usdcSource, sink: wethSink,
                rate: Percentage(fromRatio: Number("0.04e18").asSNumber, over: Number("100e6").asSNumber),
                minFlow: Number(0), maxFlow: "100e6"
            ),
            amount: "100e6"
        )

        let flowUniswap = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: Tradewinds.Route(
                type: .swap(
                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                    buyAmount: "0.042e18",
                    swapQuoteSellAmount: "100e6",
                    swapQuoteBuyAmount: "0.042e18",
                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                    feeAmount: Number(0),
                    isExactOut: false,
                    isCappedMax: true,
                    venue: "uniswap"
                ),
                source: usdcSource, sink: wethSink,
                rate: Percentage(fromRatio: Number("0.042e18").asSNumber, over: Number("100e6").asSNumber),
                minFlow: Number(0), maxFlow: "100e6"
            ),
            amount: "100e6"
        )

        let aggregated = SwapHints.aggregateFlows([flow0x, flowUniswap])

        // Different venues should NOT be aggregated - both flows unchanged
        #expect(aggregated == [flow0x, flowUniswap])
    }
}
