import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Loop Short Tests

struct CharterTradewindsLoopShortTests {

    // MARK: Basic Loop Short Operations

    @Test("Basic loop short with WETH collateral and USDC exposure")
    func testBasicLoopShortWETHtoUSDC() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Loop Short WETH->USDC",
                givens: [
                    // Alice has 5 WETH on Base
                    .tokenBalance(.alice, .amt(5, .weth), .base),
                    .quote(.basic),
                ],
                intent: .loopShort(
                    Charter.LoopShortIntent(
                        exposureAssetSymbol: "USDC",  // Shorting USDC
                        backingAssetSymbol: "WETH",  // Using WETH as collateral
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("10000e6"),  // Short 10,000 USDC
                        minSwapBackingAmount: Number("3e18"),  // Min 3 WETH from swap
                        providedBackingAmount: Number("5e18"),  // User provides 5 WETH
                        poolFee: 3000,  // 0.3% fee tier
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    minSwapBackingAmount: Number("3e18"),
                                    providedBackingAmount: Number("5e18"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e18"
                        )
                    ],
                    maxFlow: "5e18"
                )
            )
        )
    }

    @Test("Loop short with partial collateral amount")
    func testLoopShortPartialCollateral() {
        runFlowTest(
            ChartTestCase(
                name: "Partial Collateral Loop Short",
                givens: [
                    // Alice has 10 WETH but only wants to use 5
                    .tokenBalance(.alice, .amt(10, .weth), .base),
                    .quote(.basic),
                ],
                intent: .loopShort(
                    Charter.LoopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("15000e6"),  // Short 15,000 USDC
                        minSwapBackingAmount: Number("4e18"),
                        providedBackingAmount: Number("5e18"),  // Only use 5 WETH
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("15000e6"),
                                    minSwapBackingAmount: Number("4e18"),
                                    providedBackingAmount: Number("5e18"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e18"
                        )
                    ],
                    maxFlow: "10e18"  // Total available WETH
                )
            )
        )
    }

    // MARK: Cross-Chain Loop Short

    @Test("Loop short with bridging from Arbitrum to Base")
    func testLoopShortWithBridging() {
        runFlowTest(
            ChartTestCase(
                name: "Cross-Chain Loop Short",
                givens: [
                    // Alice has WETH on Arbitrum but needs it on Base
                    .tokenBalance(.alice, .amt(5.00001, .weth), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .weth), 0.01),  // 1% bridge fee with 1 WETH fixed cost
                ],
                intent: .loopShort(
                    Charter.LoopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("10000e6"),
                        minSwapBackingAmount: Number("2.9e18"),
                        providedBackingAmount: Number("3.95e18"),  // 5 * 0.99 - 1 = 3.95 WETH after bridge fees
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)  // Target chain is Base
                    )
                ),
                expect: .exactFlows(
                    [
                        // Bridge from Arbitrum to Base (WETH arrives as ETH)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: .arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,  // Bridge to ETH on Base
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99 (1% fee)
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e18")  // 1 WETH fixed cost
                                ],
                                minFlow: "0",
                                maxFlow: "5e18"
                            ),
                            amount: "5.00001e18"  // Bridge 5 WETH with fees
                        ),
                        // Wrap ETH to WETH on Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3.95e18"  // Amount after bridge fees
                        ),
                        // Loop short on Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    minSwapBackingAmount: Number("2.9e18"),
                                    providedBackingAmount: Number("3.95e18"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3.95e18"  // Amount after bridge fees
                        ),
                    ],
                    maxFlow: "3.95e18"  // Max flow is the amount after bridge fees
                )
            )
        )
    }

    // MARK: Loop Short Decrease Position

    @Test("Loop short decrease position")
    func testLoopShortDecrease() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Short Decrease Position",
                givens: [
                    // Alice already has a short position and wants to decrease it
                    .tokenBalance(.alice, .amt(3, .weth), .base),
                    .quote(.basic),
                ],
                intent: .loopShort(
                    Charter.LoopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: false,  // Decreasing position
                        exposureAmount: Number("5000e6"),  // Reduce short by 5,000 USDC
                        minSwapBackingAmount: Number("1.5e18"),  // Will receive at least 1.5 WETH
                        providedBackingAmount: Number("3e18"),  // Withdrawing 3 WETH collateral
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("5000e6"),
                                    minSwapBackingAmount: Number("1.5e18"),
                                    providedBackingAmount: Number("3e18"),
                                    poolFee: 3000,
                                    isIncrease: false
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3e18"
                        )
                    ],
                    maxFlow: "3e18"
                )
            )
        )
    }

    // MARK: Edge Cases

    @Test("Loop short with zero backing intent generates virtual source flow")
    func testLoopShortWithZeroBackingIntent() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Short with Zero Backing Intent",
                givens: [
                    .quote(.basic)
                ],
                intent: .loopShort(
                    Charter.LoopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("10000e6"),
                        minSwapBackingAmount: Number("3e18"),
                        providedBackingAmount: Number(0),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    minSwapBackingAmount: Number("3e18"),
                                    providedBackingAmount: Number(0),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .virtualNode(
                                    network: .base,
                                    routeType: .loopShort(
                                        marketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                        ),
                                        exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                        exposureAssetSymbol: "USDC",
                                        exposureAmount: Number("10000e6"),
                                        minSwapBackingAmount: Number("3e18"),
                                        providedBackingAmount: Number(0),
                                        poolFee: 3000,
                                        isIncrease: true
                                    ),
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1"
                        )
                    ],
                    maxFlow: "1"
                )
            )
        )
    }

    @Test("Loop short with zero collateral fails without resources")
    func testLoopShortZeroCollateral() {
        runFlowTest(
            ChartTestCase(
                name: "Zero Collateral Loop Short",
                givens: [
                    // Alice has no WETH
                    .quote(.basic)
                ],
                intent: .loopShort(
                    Charter.LoopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("10000e6"),
                        minSwapBackingAmount: Number("3e18"),
                        providedBackingAmount: Number("5e18"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .failure(
                    Tradewinds.Error.insufficientResources(
                        target: .exact("5e18"),
                        max: "0"
                    ),
                    maxFlow: "0"
                )
            )
        )
    }

    @Test("Loop short with max provided backing amount")
    func testLoopShortMaxProvidedBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Short Max Provided Backing",
                givens: [
                    .tokenBalance(.alice, .amt(5, .weth), .base),
                    .quote(.basic),
                ],
                intent: .loopShort(
                    Charter.LoopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("10000e6"),
                        minSwapBackingAmount: Number("3e18"),
                        providedBackingAmount: Number.MAX_UINT_256,
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    minSwapBackingAmount: Number("3e18"),
                                    providedBackingAmount: Number.MAX_UINT_256,
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e18"
                        )
                    ],
                    maxFlow: "5e18"
                )
            )
        )
    }
}
