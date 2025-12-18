import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Morpho borrow flows
struct CharterTradewindsMorphoBorrowTests {

    @Test("Basic Morpho borrow with WETH collateral")
    func testBasicMorphoBorrow() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Morpho borrow with WETH collateral",
                givens: [
                    .tokenBalance(.alice, .amt(0.1, .weth), .base)
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "100e6",  // 100 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),  // Base USDC/WETH market
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.1e18",  // 0.1 WETH
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "100e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.1e18"
                        )
                    ],
                    maxFlow: "0.1e18"  // User has 0.1 WETH collateral
                )
            )
        )
    }

    @Test("Morpho borrow with ETH that needs wrapping")
    func testMorphoBorrowWithWrapping() {
        runFlowTest(
            ChartTestCase(
                name: "Morpho borrow with ETH that needs wrapping",
                givens: [
                    .tokenBalance(.alice, .amt(0.05, .eth), .base)
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "50e6",  // 50 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "5e16",  // 0.05 ETH
                        collateralAssetSymbol: "ETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
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
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e16"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "50e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e16"
                        ),
                    ],
                    maxFlow: "5e16"
                )
            )
        )
    }

    @Test("Just borrow using existing collateral")
    func testJustBorrow() {
        runFlowTest(
            ChartTestCase(
                name: "Just borrow using existing collateral",
                givens: [
                    .morphoCollateral(.alice, .amt(0.5, .weth), .morpho(.weth, .usdc), .base),
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "200e6",  // 200 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",  // No new collateral
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoBorrow(
                                    asset: BaseNetwork.Assets.USDC.assetAddress,
                                    amount: "200e6"
                                ),
                                source: .morphoBorrowCapacity(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "200e6"
                        )
                    ],
                    maxFlow: "1685.6e6"  // 0.5 WETH * $4000 * 0.86 (LLTV) * 0.98 (safety cap) = $1685.6
                )
            )
        )
    }

    @Test("Borrow capacity reduced by existing borrows")
    func testBorrowCapacityWithExistingBorrows() {
        runFlowTest(
            ChartTestCase(
                name: "Borrow capacity reduced by existing borrows",
                givens: [
                    .morphoCollateral(.alice, .amt(0.5, .weth), .morpho(.weth, .usdc), .base),
                    .morphoBorrow(.alice, .morpho(.weth, .usdc), .amt(1000, .usdc), .amt(0, .weth), .base),
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "100e6",  // 100 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoBorrow(
                                    asset: BaseNetwork.Assets.USDC.assetAddress,
                                    amount: "100e6"
                                ),
                                source: .morphoBorrowCapacity(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
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
                        )
                    ],
                    // Full capacity: 0.5 WETH * $4000 * 0.86 * 0.98 = $1685.6
                    // Minus existing borrow: $1685.6 - $1000 = $685.6
                    maxFlow: "685.6e6"
                )
            )
        )
    }

    @Test("Supply collateral only, no borrow")
    func testSupplyCollateralOnly() {
        runFlowTest(
            ChartTestCase(
                name: "Supply collateral only",
                givens: [
                    .tokenBalance(.alice, .amt(2, .weth), .base)
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "0",  // No borrow
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "2e18",  // 2 WETH
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoSupplyCollateral(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2e18"
                        )
                    ],
                    maxFlow: "2e18"
                )
            )
        )
    }

    @Test("Borrow with bridged collateral")
    func testBorrowWithBridgedCollateral() {
        runFlowTest(
            ChartTestCase(
                name: "Borrow with bridged collateral",
                givens: [
                    .tokenBalance(.alice, .amt(0.17, .weth), .arbitrum),  // Extra for bridge fees
                    .acrossQuote(.amt(0.01, .weth), 0.01),  // 1% fee with 0.01 WETH fixed cost
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "150e6",  // 150 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "15e16",  // 0.15 WETH
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromDouble: 0.99),  // 1% fee
                                fees: [
                                    Tradewinds.Fee(type: .bridge, isInFee: false, amount: "1e16")  // 0.01 WETH fixed cost
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "161616161616161617"  // (0.15e18 + 0.01e18) / 0.99
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
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
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "15e16"  // 0.15 WETH
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "150e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "15e16"
                        ),
                    ],
                    maxFlow: "158300000000000000"  // 0.17e18 * 0.99 - 0.01e18 = 0.1583e18
                )
            )
        )
    }

    @Test("Borrow using Morpho vault withdrawal")
    func testBorrowWithMorphoVaultWithdrawal() {
        runFlowTest(
            ChartTestCase(
                name: "Borrow using Morpho vault withdrawal",
                givens: [
                    .morphoVaultSupply(.alice, .amt(0.2031, .weth), .weth, .worldChain),  // WETH in Morpho on WorldChain (enough for 0.2 after fees)
                    .acrossQuote(.amt(0.001, .weth), 0.01),  // 1% bridge fee
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "300e6",  // 300 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.2e18",  // 0.2 WETH
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultWithdraw(isMax: false),
                                source: .morphoVaultSupplyBalance(
                                    network: Eth.Network.worldChain,
                                    vault: EthAddress("0x0Db7E405278c2674F462aC9D9eb8b8346D1c1571"),  // WorldChain WETH vault
                                    baseAsset: EthAddress(
                                        "0x4200000000000000000000000000000000000006"
                                    ),  // WETH on WorldChain
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.worldChain,
                                    address: EthAddress(
                                        "0x4200000000000000000000000000000000000006"
                                    ),  // WETH on WorldChain
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "203030303030303031"  // Amount calculated by algorithm
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.worldChain,
                                    address: EthAddress(
                                        "0x4200000000000000000000000000000000000006"
                                    ),  // WETH on WorldChain
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 1% bridge fee
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "203030303030303031"  // Bridge full amount
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
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
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.2e18"  // 0.2 WETH
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "300e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.2e18"  // 0.2 WETH after bridge fee
                        ),
                    ],
                    maxFlow: "200069000000000000"  // Actual max flow after fees
                ),
                allowUsingEarningBalances: true  // Always enable earning balances for this test
            )
        )
    }

    @Test("Max collateral borrow")
    func testMaxCollateralBorrow() {
        runFlowTest(
            ChartTestCase(
                name: "Max collateral borrow",
                givens: [
                    .tokenBalance(.alice, .amt(10, .weth), .base)
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "1000e6",  // 1000 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: Number.MAX_UINT_256,  // Max amount
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "1000e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10e18"  // Uses all available WETH
                        )
                    ],
                    maxFlow: "10e18"
                )
            )
        )
    }

    @Test("Complex borrow with bridging and wrapping")
    func testComplexBorrowWithBridgingAndWrapping() {
        runFlowTest(
            ChartTestCase(
                name: "Complex borrow with bridging and wrapping",
                givens: [
                    .tokenBalance(.alice, .amt(0.111111111111111112, .eth), .arbitrum),  // ETH on Arbitrum
                    .tokenBalance(.alice, .amt(0.05, .weth), .base),  // Some WETH on Base
                    .acrossQuoteWithMin(.amt(0.01, .weth), 0.01, .amt(0.01, .weth)),  // 1% fee + 0.01 WETH minimum
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: "400e6",  // 400 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "15e16",  // 0.15 WETH total needed
                        collateralAssetSymbol: "ETH"  // Specified as ETH, but will be wrapped to WETH
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "111111111111111112"  // Wrap ETH to WETH
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromDouble: 0.99),  // 1% fee
                                fees: [
                                    Tradewinds.Fee(type: .bridge, isInFee: false, amount: "1e16")  // 0.01 WETH minimum
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "111111111111111112"  // Bridge WETH after wrapping
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
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
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10e16"  // 0.1 WETH
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "400e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoCollateralBalance(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "15e16"  // Total 0.15 WETH (0.05 existing + 0.1 from bridge)
                        ),
                    ],
                    maxFlow: "150000000000000008"  // 0.15e18 + 8 wei rounding
                )
            )
        )
    }

    @Test("Max borrow amount using existing collateral")
    func testMaxBorrowAmount() {
        runFlowTest(
            ChartTestCase(
                name: "Max borrow amount using existing collateral",
                givens: [
                    .morphoCollateral(.alice, .amt(0.5, .weth), .morpho(.weth, .usdc), .base),
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: Number.MAX_UINT_256,  // Max borrow
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0",  // No new collateral
                        collateralAssetSymbol: ""
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoBorrow(
                                    asset: BaseNetwork.Assets.USDC.assetAddress,
                                    amount: Number.MAX_UINT_256
                                ),
                                source: .morphoBorrowCapacity(
                                    network: Eth.Network.base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "1685.6e6"  // Max borrow capacity: 0.5 WETH * $4000 * 0.86 (LLTV) * 0.98 = $1685.6
                        )
                    ],
                    maxFlow: "1685.6e6"
                )
            )
        )
    }

    @Test("Max borrow amount with new collateral fails")
    func testMaxBorrowAmountWithCollateralFails() {
        runFlowTest(
            ChartTestCase(
                name: "Max borrow amount with new collateral fails",
                givens: [
                    .tokenBalance(.alice, .amt(0.5, .weth), .base)
                ],
                intent: .morphoBorrow(
                    Charter.MorphoBorrowIntent(
                        amount: Number.MAX_UINT_256,  // Max borrow
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.5e18",  // 0.5 WETH
                        collateralAssetSymbol: "WETH"
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.error(
                        "Max borrow is not supported in supply+borrow flow. Please specify an exact borrow amount."
                    )
                )
            )
        )
    }
}
