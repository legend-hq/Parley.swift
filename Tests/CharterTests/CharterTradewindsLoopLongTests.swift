import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Loop Long Tests

struct CharterTradewindsLoopLongTests {

    // MARK: Basic Loop Long Operations

    @Test("Basic loop long with USDC backing and WETH exposure")
    func testBasicLoopLongUSDCtoWETH() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Loop Long USDC->WETH",
                givens: [
                    // Alice has 10,000 USDC on Base
                    .tokenBalance(.alice, .amt(10_000, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // Example Morpho market
                        isIncrease: true,
                        exposureAmount: Number("3e18"),  // 3 WETH
                        maxSwapBackingAmount: Number("40000e6"),  // Max 40,000 USDC to borrow and swap
                        maxProvidedBackingAmount: Number("10000e6"),  // User provides 10,000 USDC
                        poolFee: 3000,  // 0.3% fee tier
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,  // Using WETH as a placeholder
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("3e18"),
                                    maxSwapBackingAmount: Number("40000e6"),
                                    maxProvidedBackingAmount: Number("10000e6"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,  // Using WETH as a placeholder
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000e6"
                        )
                    ],
                    maxFlow: "10000e6"
                )
            )
        )
    }

    @Test("Loop long with partial backing amount")
    func testLoopLongPartialBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Partial Backing Loop Long",
                givens: [
                    // Alice has 15,000 USDC but only wants to use 10,000
                    .tokenBalance(.alice, .amt(15_000, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",  // Using WETH for this test
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("5e18"),  // 5 WETH
                        maxSwapBackingAmount: Number("40000e6"),
                        maxProvidedBackingAmount: Number("10000e6"),  // Only use 10,000 USDC
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("5e18"),
                                    maxSwapBackingAmount: Number("40000e6"),
                                    maxProvidedBackingAmount: Number("10000e6"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000e6"
                        )
                    ],
                    maxFlow: "15000e6"  // Total available USDC
                )
            )
        )
    }

    // MARK: Cross-Chain Loop Long

    @Test("Loop long with bridging from Arbitrum to Base")
    func testLoopLongWithBridging() {
        runFlowTest(
            ChartTestCase(
                name: "Cross-Chain Loop Long",
                givens: [
                    // Alice has USDC on Arbitrum but needs it on Base
                    .tokenBalance(.alice, .amt(10_000, .usdc), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% bridge fee
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("3e18"),
                        maxSwapBackingAmount: Number("40000e6"),
                        maxProvidedBackingAmount: Number("9899e6"),  // Amount after bridge fees (10000 * 0.99 - 1)
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)  // Target chain is Base
                    )
                ),
                expect: .exactFlows(
                    [
                        // Bridge from Arbitrum to Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: .arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress.on(.arbitrum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.arbitrum)
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99 (1% fee)
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "10000e6"  // Bridge 10000 USDC
                        ),
                        // Loop long on Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("3e18"),
                                    maxSwapBackingAmount: Number("40000e6"),
                                    maxProvidedBackingAmount: Number("9899e6"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "9899e6"  // Amount after bridge fees
                        ),
                    ],
                    maxFlow: "9899e6"  // Max flow is the amount after bridge fees
                )
            )
        )
    }

    // MARK: Loop Long with Earning Balances

    @Test("Loop long withdrawing from Aave to fund position")
    func testLoopLongWithAaveWithdraw() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Long with Aave Withdrawal",
                givens: [
                    // Alice has USDC supplied to Aave
                    .aaveSupply(.alice, .amt(10_000.02, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("3e18"),
                        maxSwapBackingAmount: Number("40000e6"),
                        maxProvidedBackingAmount: Number("10000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId),
                        earnMarketPolicy: .all
                    )
                ),
                expect: .exactFlows(
                    [
                        // Withdraw from Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: AavePool.baseV3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000.02e6"
                        ),
                        // Loop long
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("3e18"),
                                    maxSwapBackingAmount: Number("40000e6"),
                                    maxProvidedBackingAmount: Number("10000e6"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000e6"
                        ),
                    ],
                    maxFlow: "10000e6"
                )
            )
        )
    }

    // MARK: Loop Long with ETH/WETH

    @Test("Loop long with ETH wrapping to WETH")
    func testLoopLongWithETHWrapping() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Long with ETH Wrapping",
                givens: [
                    // Alice has ETH but needs WETH as backing asset
                    .tokenBalance(.alice, .amt(5, .eth), .base),
                    .quote(.basic),
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",  // Need WETH
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("10000e6"),  // 10,000 USDC
                        maxSwapBackingAmount: Number("4e18"),  // Max 4 WETH to borrow and swap
                        maxProvidedBackingAmount: Number("5e18"),  // User provides 5 WETH
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        // Wrap ETH to WETH
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.ETH.assetAddress.on(.base),
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e18"
                        ),
                        // Loop long with WETH
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    maxSwapBackingAmount: Number("4e18"),
                                    maxProvidedBackingAmount: Number("5e18"),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
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
                        ),
                    ],
                    maxFlow: "5e18"
                )
            )
        )
    }

    // MARK: Loop Long Decrease Position

    @Test("Loop long decrease position")
    func testLoopLongDecrease() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Long Decrease Position",
                givens: [
                    // Alice already has a position and wants to decrease it
                    .tokenBalance(.alice, .amt(5_000, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: false,  // Decreasing position
                        exposureAmount: Number("2e18"),  // Reduce exposure by 2 WETH
                        maxSwapBackingAmount: Number("6000e6"),  // Will receive up to 6,000 USDC
                        maxProvidedBackingAmount: Number("5000e6"),  // Repaying 5,000 USDC
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("2e18"),
                                    maxSwapBackingAmount: Number("6000e6"),
                                    maxProvidedBackingAmount: Number("5000e6"),
                                    poolFee: 3000,
                                    isIncrease: false
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000e6"
                        )
                    ],
                    maxFlow: "5000e6"
                )
            )
        )
    }

    // MARK: Edge Cases

    @Test("Loop long with zero backing intent generates virtual source flow")
    func testLoopLongWithZeroBackingIntent() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Long with Zero Backing Intent",
                givens: [
                    .quote(.basic)
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("3e18"),
                        maxSwapBackingAmount: Number("40000e6"),
                        maxProvidedBackingAmount: Number(0),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("3e18"),
                                    maxSwapBackingAmount: Number("40000e6"),
                                    maxProvidedBackingAmount: Number(0),
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .virtualNode(
                                    network: .base,
                                    routeType: .loopLong(
                                        marketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                        ),
                                        exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                        exposureAssetSymbol: "WETH",
                                        exposureAmount: Number("3e18"),
                                        maxSwapBackingAmount: Number("40000e6"),
                                        maxProvidedBackingAmount: Number(0),
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
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
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

    @Test("Loop long with zero backing amount fails without resources")
    func testLoopLongZeroBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Zero Backing Loop Long",
                givens: [
                    // Alice has no USDC
                    .quote(.basic)
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("3e18"),
                        maxSwapBackingAmount: Number("40000e6"),
                        maxProvidedBackingAmount: Number("10000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .failure(
                    Tradewinds.Error.insufficientResources(
                        target: .exact("10000e6"),
                        max: "0"
                    ),
                    maxFlow: "0"
                )
            )
        )
    }

    @Test("Loop long with insufficient backing")
    func testLoopLongInsufficientBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Insufficient Backing Loop Long",
                givens: [
                    // Alice has only 5,000 USDC but needs 10,000
                    .tokenBalance(.alice, .amt(5_000, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("5e18"),
                        maxSwapBackingAmount: Number("40000e6"),
                        maxProvidedBackingAmount: Number("10000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .failure(
                    Tradewinds.Error.insufficientResources(
                        target: .exact("10000e6"),
                        max: "5000e6"
                    ),
                    maxFlow: "5000e6"
                )
            )
        )
    }

    @Test("Loop long with max provided backing amount")
    func testLoopLongMaxProvidedBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Loop Long Max Provided Backing",
                givens: [
                    .tokenBalance(.alice, .amt(10_000, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .loopLong(
                    Charter.LoopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        isIncrease: true,
                        exposureAmount: Number("3e18"),
                        maxSwapBackingAmount: Number("40000e6"),
                        maxProvidedBackingAmount: Number.MAX_UINT_256,
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .loopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("3e18"),
                                    maxSwapBackingAmount: Number("40000e6"),
                                    maxProvidedBackingAmount: Number.MAX_UINT_256,
                                    poolFee: 3000,
                                    isIncrease: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000e6"
                        )
                    ],
                    maxFlow: "10000e6"
                )
            )
        )
    }
}
