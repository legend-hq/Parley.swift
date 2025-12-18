import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Unloop Long Tests

struct CharterTradewindsUnloopLongTests {

    // MARK: Basic Unloop Long Operations

    @Test("Basic unloop long from WETH exposure to USDC")
    func testBasicUnloopLongWETHtoUSDC() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Unloop Long WETH->USDC",
                givens: [
                    // Alice has an existing long position to unwind
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),  // 5 WETH collateral in position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "WETH",  // Selling WETH collateral
                        backingAssetSymbol: "USDC",  // Receiving USDC
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("3e18"),  // Sell 3 WETH
                        backingAmountToExit: Number("10000e6"),  // Exit with 10,000 USDC
                        minSwapBackingAmount: Number("8000e6"),  // Min 8,000 USDC from swap
                        poolFee: 3000,  // 0.3% fee tier
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("3e18"),
                                    backingAmountToExit: Number("10000e6"),
                                    minSwapBackingAmount: Number("8000e6"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(  // Source is the loop venue
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(  // Sink is the token balance
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }

    @Test("Partial unloop long")
    func testPartialUnloopLong() {
        runFlowTest(
            ChartTestCase(
                name: "Partial Unloop Long",
                givens: [
                    // Alice has a position and wants to partially unwind
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),  // 5 WETH collateral in position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("1e18"),  // Sell only 1 WETH
                        backingAmountToExit: Number("3000e6"),  // Exit with 3,000 USDC
                        minSwapBackingAmount: Number("2500e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("1e18"),
                                    backingAmountToExit: Number("3000e6"),
                                    minSwapBackingAmount: Number("2500e6"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }

    // MARK: Unloop Long with Different Assets

    @Test("Unloop long with WBTC exposure")
    func testUnloopLongWBTC() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Long WBTC->USDC",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(5, .cbbtc),  // 5 cbBTC collateral (ample capacity for 35k USDC)
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "cbBTC",  // Selling cbBTC
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("0.5e8"),  // 0.5 cbBTC
                        backingAmountToExit: Number("35000e6"),
                        minSwapBackingAmount: Number("30000e6"),  // Min 30,000 USDC
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.cbBTC.assetAddress,
                                    exposureAssetSymbol: "cbBTC",
                                    exposureAmount: Number("0.5e8"),
                                    backingAmountToExit: Number("35000e6"),
                                    minSwapBackingAmount: Number("30000e6"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.cbBTC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "35000e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }

    // MARK: Complete Position Exit

    @Test("Complete unloop of long position")
    func testCompleteUnloopLong() {
        runFlowTest(
            ChartTestCase(
                name: "Complete Unloop Long",
                givens: [
                    // Alice wants to completely exit her position
                    .morphoCollateral(
                        .alice,
                        .amt(10, .weth),  // 10 WETH collateral in position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("10e18"),  // Sell all 10 WETH collateral
                        backingAmountToExit: Number("50000e6"),  // Exit entire position
                        minSwapBackingAmount: Number("25000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("10e18"),
                                    backingAmountToExit: Number("50000e6"),
                                    minSwapBackingAmount: Number("25000e6"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50000e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }

    // MARK: Unloop to WETH

    @Test("Unloop long with WETH as backing")
    func testUnloopLongToWETH() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Long USDC->WETH",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(50000, .usdc),  // 50000 USDC collateral (ample capacity for 5 WETH)
                        Morpho(collateralToken: .usdc, borrowToken: .weth),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "USDC",  // Selling USDC collateral
                        backingAssetSymbol: "WETH",  // Receiving WETH
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("10000e6"),
                        backingAmountToExit: Number("5e18"),  // Exit with 5 WETH
                        minSwapBackingAmount: Number("3e18"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    exposureAmount: Number("10000e6"),
                                    backingAmountToExit: Number("5e18"),
                                    minSwapBackingAmount: Number("3e18"),
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
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e18"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }

    @Test("Unloop long with max exposure amount")
    func testUnloopLongMaxExposure() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Long Max Exposure",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number.MAX_UINT_256,
                        backingAmountToExit: 0,
                        minSwapBackingAmount: Number("8000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number.MAX_UINT_256,
                                    backingAmountToExit: 0,
                                    minSwapBackingAmount: Number("8000e6"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: Number.MAX_UINT_256
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }

    @Test(
        "Unloop long with max backing amount to exit"
    )
    func testUnloopLongMaxBackingToExit() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Long Max Backing To Exit",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("3e18"),
                        backingAmountToExit: Number.MAX_UINT_256,
                        minSwapBackingAmount: Number("8000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("3e18"),
                                    backingAmountToExit: Number.MAX_UINT_256,
                                    minSwapBackingAmount: Number("8000e6"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: Number.MAX_UINT_256
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }

    @Test(
        "Unloop long with max exposure and max backing to exit"
    )
    func testUnloopLongMaxBoth() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Long Max Both",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number.MAX_UINT_256,
                        backingAmountToExit: Number.MAX_UINT_256,
                        minSwapBackingAmount: Number("8000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.error(
                        "Invalid unloop long: when exposureAmount is max (full unloop), backingAmountToExit must be 0"
                    )
                )
            )
        )
    }

    // MARK: Edge Cases

    @Test("Unloop long with zero backing exit intent generates virtual sink flow")
    func testUnloopLongWithZeroBackingExit() {
        runFlowTest(
            ChartTestCase(
                name: "Unloop Long with Zero Backing Exit",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic)
                ],
                intent: .unloopLong(
                    Charter.UnloopLongIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        exposureAmount: Number("2e18"),
                        backingAmountToExit: Number(0),
                        minSwapBackingAmount: Number("5000e6"),
                        poolFee: 3000,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .unloopLong(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    exposureAmount: Number("2e18"),
                                    backingAmountToExit: Number(0),
                                    minSwapBackingAmount: Number("5000e6"),
                                    poolFee: 3000
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .virtualNode(
                                    network: .base,
                                    routeType: .unloopLong(
                                        marketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                        ),
                                        exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                        exposureAssetSymbol: "WETH",
                                        exposureAmount: Number("2e18"),
                                        backingAmountToExit: Number(0),
                                        minSwapBackingAmount: Number("5000e6"),
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
                    maxFlow: Number.MAX_UINT_256
                )
            )
        )
    }
}
