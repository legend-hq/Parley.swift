import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Morpho repay flows
struct CharterTradewindsMorphoRepayTests {

    @Test("Basic Morpho repay USDC debt")
    func testBasicMorphoRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Morpho repay USDC debt",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(0.2, .weth),
                        .amt(100, .usdc),
                        .base
                    ),
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "100e6",  // 100 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
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
                    .tokenBalance(.alice, .amt(0.1, .eth), .worldChain),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .wbtc, borrowToken: .weth),
                        .amt(0.1, .weth),
                        .amt(0.001, .wbtc),
                        .worldChain
                    ),
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "0.1e18",  // 0.1 WETH
                        assetSymbol: "WETH",
                        marketId: Hex(
                            "0x19c682c3a37025075074cefea866fbe54656abc0fb6a7355b62a53f45b959abf"
                        ),  // WBTC/WETH market on World Chain
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: "480",  // World Chain
                        collateralAmount: "0",
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.worldChain,
                                    address: EthAddress(
                                        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
                                    ),  // ETH
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.worldChain,
                                    address: EthAddress(
                                        "0x4200000000000000000000000000000000000006"
                                    ),  // WETH
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.1e18"
                        ),
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.worldChain,
                                    address: EthAddress(
                                        "0x4200000000000000000000000000000000000006"
                                    ),  // WETH
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.worldChain,
                                    marketId: Hex(
                                        "0x19c682c3a37025075074cefea866fbe54656abc0fb6a7355b62a53f45b959abf"
                                    ),
                                    borrowAsset: EthAddress(
                                        "0x4200000000000000000000000000000000000006"
                                    ),  // WETH
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
                    .morphoCollateral(
                        .alice,
                        .amt(0.200005, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "0",  // No repayment
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.2e18",  // 0.2 WETH (net amount user receives)
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoWithdrawCollateral(isMax: false),
                                source: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(0.3, .weth),
                        .amt(100, .usdc),
                        .base
                    ),
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "50e6",  // 50 USDC repay
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "5e16",  // 0.05 WETH withdraw
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoRepayAndWithdrawCollateral(
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    collateralAmount: "5e16",
                                    isMaxRepay: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
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
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(0.2, .weth),
                        .amt(100, .usdc),
                        .base
                    ),
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "25e6",  // 25 USDC partial repay
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
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
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(100, .usdc),
                        .amt(0.2, .weth),
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: Number.MAX_UINT_256,  // MAX repay
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoRepay(isMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "100.021e6"  // 100.001 USDC buffered debt (100 * 1.00001) + 0.02 USDC quotePay
                            ),
                            amount: "100.021e6"  // Flow at source: 100.001 USDC buffered debt + 0.02 USDC quotePay
                        )
                    ],
                    maxFlow: "100.001e6"  // Max flow to sink: 100 USDC debt * 1.00001 buffer
                )
            )
        )
    }

    @Test("Invalid market validation")
    func testInvalidMarketValidation() {
        // This should fail as the market doesn't exist
        let intent = Charter.MorphoRepayIntent(
            amount: "100e6",
            assetSymbol: BaseNetwork.Assets.USDC.symbol,
            marketId: Hex("0x0000000000000000000000000000000000000000000000000000000000000000"),  // Invalid market
            repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
            chainId: BaseNetwork.network.chainId,
            collateralAmount: "0",
            collateralAssetSymbol: ""
        )

        let result = Charter.QuarkIntent.Type_.morphoRepay(intent)
            .tradewindsInfo(
                folio: generateFolio(from: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(0.2, .weth),
                        .amt(100, .usdc),
                        .base
                    ),
                ]),
                allowUsingEarningBalances: false
            )

        if case .failure(let error) = result {
            #expect(
                error
                    == Charter.CharterError.morphoMarketNotFound(
                        marketId: Hex(
                            "0x0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        network: Eth.Network.base
                    )
            )
        } else {
            Issue.record("Invalid market should not be supported")
        }
    }

    @Test("Bridge for repay")
    func testBridgeForRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Bridge for repay",
                givens: [
                    .tokenBalance(.alice, .amt(150, .usdc), .ethereum),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(0.2, .weth),
                        .amt(100, .usdc),
                        .base
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1 USDC flat fee, 1% variable fee
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "100e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "102020203"  // ~102.02 USDC needed to get 100 USDC after fees
                        ),
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
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

    @Test("Comet withdrawal for Morpho repay")
    func testCometWithdrawalForMorphoRepay() {
        runFlowTest(
            ChartTestCase(
                name: "Comet withdrawal for Morpho repay",
                givens: [
                    .cometSupply(.alice, .amt(120, .usdc), .cusdcv3, .base),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(0.2, .weth),
                        .amt(100, .usdc),
                        .base
                    ),
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "100e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoRepay(isMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
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
                    maxFlow: "120e6"  // Max flow is limited by available resources (120 USDC in Comet)
                ),
                allowUsingEarningBalances: true
            )
        )
    }

    @Test("Wrapped asset withdrawal")
    func testWrappedAssetWithdrawal() {
        runFlowTest(
            ChartTestCase(
                name: "Wrapped asset withdrawal",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(0.1, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    )
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "0",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.1e18",  // 0.1 WETH
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoWithdrawCollateral(isMax: false),
                                source: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",  // Remains WETH, not ETH
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .amt(0.3, .weth),
                        .amt(90, .usdc),
                        .base
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1 USDC flat fee, 1% variable fee
                ],
                intent: .morphoRepay(
                    Charter.MorphoRepayIntent(
                        amount: "90e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // WETH/USDC market on Base
                        repayer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.1e18",  // Withdraw 0.1 WETH
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    // We expect specific flows for this test case
                    [
                        // First bridge from Ethereum
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                                type: .morphoRepayAndWithdrawCollateral(
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    collateralAmount: "0.1e18",
                                    isMaxRepay: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoBorrowPosition(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
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
                ),
                allowUsingEarningBalances: true
            )
        )
    }
}
