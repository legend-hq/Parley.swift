import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Unloop Short Tests

struct CharterTradewindsUnloopShortTests {

    // MARK: Basic Unloop Short Operations

    @Test("Basic unloop short from USDC exposure to WETH")
    func testBasicUnloopShortUSDCtoWETH() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Unloop Short USDC->WETH",
                givens: [
                    // Alice has an existing short position to unwind
                    .morphoCollateral(
                        .alice,
                        .amt(10, .weth),  // 10 WETH collateral (backing) in position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",  // Buying back USDC to close short
                        backingAssetSymbol: "WETH",  // Receiving WETH collateral
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("10000e6"),  // Buy back 10,000 USDC
                        backingAmountToExit: Number("4e18"),  // Exit with 4 WETH
                        maxSwapBackingAmount: Number("4e18"),  // Max 4 WETH to spend
                        poolFee: 3000,  // 0.3% fee tier
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    backingAmountToExit: Number("4e18"),
                                    maxSwapBackingAmount: Number("4e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(  // Source is the loop venue
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(  // Sink is the token balance
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "4e18"
                        )
                    ],
                    maxFlow: "10e18"  // Max is the collateral balance (10 WETH)
                )
            )
        )
    }

    @Test("Partial unloop short")
    func testPartialUnloopShort() {
        runFlowTest(
            ChartTestCase(
                name: "Partial Unloop Short",
                givens: [
                    // Alice has a short position and wants to partially unwind
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),  // 5 WETH collateral (backing) in position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("5000e6"),  // Buy back only 5,000 USDC
                        backingAmountToExit: Number("2e18"),  // Exit with 2 WETH
                        maxSwapBackingAmount: Number("2e18"),  // Max 2 WETH to spend
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("5000e6"),
                                    backingAmountToExit: Number("2e18"),
                                    maxSwapBackingAmount: Number("2e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                            amount: "2e18"
                        )
                    ],
                    maxFlow: "5e18"  // Max is collateral balance (5 WETH)
                )
            )
        )
    }

    // MARK: Unloop Short with Different Assets

    @Test("Unloop short with WBTC as collateral")
    func testUnloopShortWBTC() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Short USDC->WBTC",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(1.5, .cbbtc),  // 1.5 cbBTC collateral (backing) in position
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",  // Buying back USDC
                        backingAssetSymbol: "cbBTC",  // Receiving cbBTC collateral
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("50000e6"),  // Buy back 50,000 USDC
                        backingAmountToExit: Number("1e8"),  // Exit with 1 cbBTC
                        maxSwapBackingAmount: Number("1e8"),  // Max 1 cbBTC to spend
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("50000e6"),
                                    backingAmountToExit: Number("1e8"),
                                    maxSwapBackingAmount: Number("1e8"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.cbBTC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.cbBTC.assetAddress.on(.base),
                                    symbol: "cbBTC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1e8"
                        )
                    ],
                    maxFlow: "1.5e8"  // Max is collateral balance (1.5 cbBTC)
                )
            )
        )
    }

    // MARK: Complete Position Exit

    @Test("Complete unloop of short position")
    func testCompleteUnloopShort() {
        runFlowTest(
            ChartTestCase(
                name: "Complete Unloop Short",
                givens: [
                    // Alice wants to completely exit her short position
                    .morphoCollateral(
                        .alice,
                        .amt(20, .weth),  // 20 WETH collateral (backing) in position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("50000e6"),  // Buy back all 50,000 USDC debt
                        backingAmountToExit: Number("20e18"),  // Exit with 20 WETH
                        maxSwapBackingAmount: Number("20e18"),  // Max 20 WETH to spend
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("50000e6"),
                                    backingAmountToExit: Number("20e18"),
                                    maxSwapBackingAmount: Number("20e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                            amount: "20e18"
                        )
                    ],
                    maxFlow: "20e18"  // Max is collateral balance (20 WETH)
                )
            )
        )
    }

    // MARK: Unloop Short with Stablecoins

    @Test("Unloop short USDC position")
    func testUnloopShortUSDC() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Short USDC->WETH",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(10, .weth),  // 10 WETH collateral (ample capacity for 3 WETH)
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",  // Buying back USDC
                        backingAssetSymbol: "WETH",  // Receiving WETH
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("8000e6"),  // Buy back 8,000 USDC
                        backingAmountToExit: Number("3e18"),  // Exit with 3 WETH
                        maxSwapBackingAmount: Number("3e18"),  // Max 3 WETH
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("8000e6"),
                                    backingAmountToExit: Number("3e18"),
                                    maxSwapBackingAmount: Number("3e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                            amount: "3e18"
                        )
                    ],
                    maxFlow: "10e18"  // Max is collateral balance (10 WETH)
                )
            )
        )
    }

    // MARK: Profit Taking Scenario

    @Test("Unloop short after profitable trade")
    func testUnloopShortProfitable() {
        runFlowTest(
            ChartTestCase(
                name: "Profitable Unloop Short",
                givens: [
                    // Alice shorted at higher prices and now closing with profit
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),  // 5 WETH collateral (backing) in position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("10000e6"),  // Buy back 10,000 USDC
                        backingAmountToExit: Number("3e18"),  // Exit with 3 WETH
                        maxSwapBackingAmount: Number("3e18"),  // Only need 3 WETH now (was 4 WETH when opened)
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    backingAmountToExit: Number("3e18"),
                                    maxSwapBackingAmount: Number("3e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                            amount: "3e18"
                        )
                    ],
                    maxFlow: "5e18"
                )
            )
        )
    }

    @Test("Unloop short with max exposure amount")
    func testUnloopShortMaxExposure() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Short Max Exposure",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(10, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number.MAX_UINT_256,
                        backingAmountToExit: 0,
                        maxSwapBackingAmount: Number("4e18"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number.MAX_UINT_256,
                                    backingAmountToExit: 0,
                                    maxSwapBackingAmount: Number("4e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                            amount: "10e18"
                        )
                    ],
                    maxFlow: "10e18"
                )
            )
        )
    }

    @Test(
        "Unloop short with max backing amount to exit"
    )
    func testUnloopShortMaxBackingToExit() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Short Max Backing To Exit",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(10, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("10000e6"),
                        backingAmountToExit: Number.MAX_UINT_256,
                        maxSwapBackingAmount: Number("4e18"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    backingAmountToExit: Number.MAX_UINT_256,
                                    maxSwapBackingAmount: Number("4e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                            amount: Number("10e18")
                        )
                    ],
                    maxFlow: "10e18"
                )
            )
        )
    }

    @Test(
        "Unloop short with max exposure and max backing to exit"
    )
    func testUnloopShortMaxBoth() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Short Max Both",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(10, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number.MAX_UINT_256,
                        backingAmountToExit: Number.MAX_UINT_256,
                        maxSwapBackingAmount: Number("4e18"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.error(
                        "Invalid unloop short: when exposureAmount is max (full unloop), backingAmountToExit must be 0"
                    )
                )
            )
        )
    }

    // MARK: Edge Cases

    @Test("Unloop short with zero backing exit intent generates virtual sink flow")
    func testUnloopShortWithZeroBackingExit() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Short with Zero Backing Exit",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(10, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopShort(
                    Charter.UnloopShortIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("10000e6"),
                        backingAmountToExit: Number(0),
                        maxSwapBackingAmount: Number("4e18"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopShort(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    backingAmountToExit: Number(0),
                                    maxSwapBackingAmount: Number("4e18"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .virtualNode(
                                    network: .base,
                                    routeType: .unloopShort(
                                        marketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                        ),
                                        exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                        exposureAssetSymbol: "USDC",
                                        exposureAmount: Number("10000e6"),
                                        backingAmountToExit: Number(0),
                                        maxSwapBackingAmount: Number("4e18"),
                                        poolFee: 3000
                                    ),
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1"
                        )
                    ],
                    maxFlow: "10e18"
                )
            )
        )
    }
}
