import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Comet repay flows
struct CharterTradewindsCometRepayTests {

    @Test("Basic Comet repay USDC debt")
    func testBasicCometRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Comet repay USDC debt",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .cometBorrow(.alice, .amt(100, .usdc), .cusdcv3, .base),
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "100e6",  // 100 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,
                        collateralAssetSymbol: "",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        )
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("ETH wrapping for WETH repay")
    func testETHWrappingForWETHRepay() {
        runFlowTest(
            ChartTestCase(
                name: "ETH wrapping for WETH repay",
                givens: [
                    .tokenBalance(.alice, .amt(0.1, .eth), .base),
                    .cometBorrow(.alice, .amt(0.1, .weth), .cwethv3, .base),
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "0.1e18",  // 0.1 WETH
                        assetSymbol: BaseNetwork.Assets.WETH.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,
                        collateralAssetSymbol: "",
                        comet: Comet.cwethv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress.on(Eth.Network.base),
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.1e18"
                        ),
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cwethv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.1e18"
                        ),
                    ],
                    maxFlow: "0.1e18"  // User's existing WETH collateral balance
                )
            )
        )
    }

    @Test("Withdraw collateral only")
    func testWithdrawCollateralOnly() {
        runFlowTest(
            ChartTestCase(
                name: "Withdraw collateral only",
                givens: [
                    .cometCollateral(.alice, .amt(0.200005, .weth), .cusdcv3, .base),
                    .quote(.basic),
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "0",  // No repayment
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.2e18",  // 0.2 WETH (net amount user receives)
                        collateralAssetSymbol: "WETH",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdrawCollateral(isMax: false),
                                source: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "0.200005e18"  // 0.2 WETH + 0.05 QuotePay fee ($0.50 fee / $1000 WETH price)
                            ),
                            amount: "0.200005e18"
                        )
                    ],
                    maxFlow: "0.2e18"  // Net amount user receives (target)
                )
            )
        )
    }

    @Test("Repay and withdraw")
    func testRepayAndWithdraw() {
        runFlowTest(
            ChartTestCase(
                name: "Repay and withdraw",
                givens: [
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .cometBorrow(.alice, .amt(100, .usdc), .cusdcv3, .base),
                    .cometCollateral(.alice, .amt(0.1, .weth), .cusdcv3, .base),
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "50e6",  // 50 USDC repay
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "5e16",  // 0.05 WETH withdraw
                        collateralAssetSymbol: "WETH",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepayAndWithdrawCollateral(
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    collateralAmount: "5e16",
                                    isMaxRepay: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        )
                    ],
                    maxFlow: "50e6"
                )
            )
        )
    }

    @Test("Partial repay")
    func testPartialRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Partial repay",
                givens: [
                    .tokenBalance(.alice, .amt(25, .usdc), .base),
                    .cometBorrow(.alice, .amt(100, .usdc), .cusdcv3, .base),
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "25e6",  // 25 USDC partial repay
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,
                        collateralAssetSymbol: "",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "25e6"
                        )
                    ],
                    maxFlow: "25e6"
                )
            )
        )
    }

    @Test("Max repay")
    func testMaxRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Max repay",
                givens: [
                    .tokenBalance(.alice, .amt(200, .usdc), .base),
                    .cometBorrow(.alice, .amt(100, .usdc), .cusdcv3, .base),
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: Number.MAX_UINT_256,  // MAX repay
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,
                        collateralAssetSymbol: "",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepay(isMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "100.001e6"
                            ),
                            amount: "100.001e6"  // Flow amount is capped by debt + buffer (100.001 USDC)
                        )
                    ],
                    maxFlow: "100.001e6"  // Max flow is capped by debt + buffer (100.001 USDC)
                )
            )
        )
    }

    @Test("Bridge for repay")
    func testBridgeForRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Bridge for repay",
                givens: [
                    .tokenBalance(.alice, .amt(150, .usdc), .ethereum),
                    .cometBorrow(.alice, .amt(100, .usdc), .cusdcv3, .base),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1 USDC flat fee, 1% variable fee
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "100e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,
                        collateralAssetSymbol: "",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "102.020203e6"  // ~102.02 USDC needed to get 100 USDC after fees
                        ),
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                    ],
                    maxFlow: "147500000"  // 150 USDC minus 1 USDC fixed fee minus 1% of 149 = ~147.5 USDC
                )
            )
        )
    }

    @Test("Morpho withdrawal for repay")
    func testMorphoWithdrawalForRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Morpho withdrawal for repay",
                givens: [
                    .morphoVaultSupply(.alice, .amt(120, .usdc), .usdc, .base),
                    .cometBorrow(.alice, .amt(100, .usdc), .cusdcv3, .base),
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "100e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,
                        collateralAssetSymbol: "",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        earnMarketPolicy: .all
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultWithdraw(isMax: false),
                                source: .morphoVaultSupplyBalance(
                                    network: Eth.Network.base,
                                    vault: MorphoVault.usdc.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                    ],
                    maxFlow: "120e6"  // Max flow is limited by available resources (120 USDC in Morpho)
                )
            )
        )
    }

    @Test("Wrapped asset withdrawal")
    func testWrappedAssetWithdrawal() {
        runFlowTest(
            ChartTestCase(
                name: "Wrapped asset withdrawal",
                givens: [
                    .cometCollateral(.alice, .amt(0.1, .weth), .cusdcv3, .base)
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "0",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.1e18",  // 0.1 WETH
                        collateralAssetSymbol: "WETH",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdrawCollateral(isMax: false),
                                source: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",  // Remains WETH, not ETH
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "0.1e18"  // User's existing WETH collateral balance
                            ),
                            amount: "0.1e18"
                        )
                    ],
                    maxFlow: "0.1e18"  // Net amount user receives (target)
                )
            )
        )
    }

    @Test("Complex multi-step")
    func testComplexMultiStep() {
        runFlowTest(
            ChartTestCase(
                name: "Complex multi-step",
                givens: [
                    .tokenBalance(.alice, .amt(50, .usdc), .ethereum),
                    .aaveSupply(.alice, .amt(50, .usdc), .baseV3, .base),
                    .cometBorrow(.alice, .amt(90, .usdc), .cusdcv3, .base),
                    .cometCollateral(.alice, .amt(0.2, .weth), .cusdcv3, .base),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1 USDC flat fee, 1% variable fee
                ],
                intent: .cometRepay(
                    Charter.CometRepayIntent(
                        amount: "90e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.1e18",  // Withdraw 0.1 WETH
                        collateralAssetSymbol: "WETH",
                        comet: Comet.cusdcv3.address(network: .base),
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        earnMarketPolicy: .all
                    )
                ),
                expect: .exactFlows(
                    // We expect specific flows for this test case
                    [
                        // First bridge from Ethereum
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "41414142"  // Bridge ~41.41 USDC to get 40 USDC after fees
                        ),
                        // Then withdraw from Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: AavePool.baseV3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                        // Finally repay and withdraw
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometRepayAndWithdrawCollateral(
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    collateralAmount: "0.1e18",
                                    isMaxRepay: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .cometBorrowPosition(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "90e6"
                        ),
                    ],
                    maxFlow: "98500000"  // 50 USDC from Aave + 48.5 USDC from bridge (50 - 1 - 0.49) = 98.5 USDC
                )
            )
        )
    }
}
