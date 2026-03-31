import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Comet borrow flows
struct CharterTradewindsCometBorrowTests {

    @Test("Basic Comet borrow with WETH collateral")
    func testBasicCometBorrow() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Comet borrow with WETH collateral",
                givens: [
                    .tokenBalance(.alice, .amt(0.1, .weth), .base)
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "100e6",  // 100 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.1e18",  // 0.1 WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")  // cUSDCv3 on Base
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupplyCollateralAndBorrow(
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
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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

    @Test("Comet borrow with ETH that needs wrapping")
    func testCometBorrowWithWrapping() {
        runFlowTest(
            ChartTestCase(
                name: "Comet borrow with ETH that needs wrapping",
                givens: [
                    .tokenBalance(.alice, .amt(0.05, .eth), .base)
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "50e6",  // 50 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "5e16",  // 0.05 ETH
                        collateralAssetSymbol: "ETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
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
                                type: .cometSupplyCollateralAndBorrow(
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
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                    .cometCollateral(.alice, .amt(0.5, .weth), .cusdcv3, .base),
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "200e6",  // 200 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,  // No new collateral
                        collateralAssetSymbol: "",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometBorrow(
                                    asset: BaseNetwork.Assets.USDC.assetAddress,
                                    amount: "200e6"
                                ),
                                source: .cometBorrowCapacity(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                    maxFlow: "1666e6"  // 0.5 WETH * $4000 * 0.85 (liquidate factor) * 0.98 (safety cap) = $1666
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
                    .cometCollateral(.alice, .amt(0.5, .weth), .cusdcv3, .base),
                    .cometBorrow(.alice, .amt(1000, .usdc), .cusdcv3, .base),
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "100e6",  // 100 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,
                        collateralAssetSymbol: "",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometBorrow(
                                    asset: BaseNetwork.Assets.USDC.assetAddress,
                                    amount: "100e6"
                                ),
                                source: .cometBorrowCapacity(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                    // Full capacity: 0.5 WETH * $4000 * 0.85 * 0.98 = $1666
                    // Minus existing borrow: $1666 - $1000 = $666
                    maxFlow: "666e6"
                )
            )
        )
    }

    @Test("Supply collateral only (no borrow)")
    func testSupplyCollateralOnly() {
        runFlowTest(
            ChartTestCase(
                name: "Supply collateral only (no borrow)",
                givens: [
                    .tokenBalance(.alice, .amt(2, .weth), .base)
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "0",  // No borrow
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "2e18",  // 2 WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupplyCollateral(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                    .tokenBalance(.alice, .amt(0.17, .weth), .arbitrum),  // WETH on Arbitrum (need extra for bridge fees)
                    .acrossQuote(.amt(0.01, .weth), 0.01),  // 1% bridge fee
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "150e6",  // 150 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,  // Base
                        collateralAmount: "15e16",  // 0.15 WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
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
                                rate: Percentage(fromNumber: "990000000000000000"),  // 0.99 (1% fee)
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e16")  // 0.01 WETH fixed cost
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
                                type: .cometSupplyCollateralAndBorrow(
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
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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

    @Test("Borrow using collateral from Morpho withdrawal")
    func testBorrowWithMorphoWithdrawal() {
        runFlowTest(
            ChartTestCase(
                name: "Borrow using collateral from Morpho withdrawal",
                givens: [
                    .morphoVaultSupply(.alice, .amt(0.2031, .weth), .weth, .worldChain),  // WETH in Morpho on WorldChain (enough for 0.2 after fees)
                    .acrossQuote(.amt(0.001, .weth), 0.01),  // 1% bridge fee
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "300e6",  // 300 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.2e18",  // 0.2 WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                        earnMarketPolicy: .all
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
                                type: .bridge(bridgeType: .across, isCappedMax: false),
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
                                type: .cometSupplyCollateralAndBorrow(
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
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.2e18"  // 0.2 WETH after bridge fee (0.202 * 0.99 ≈ 0.2)
                        ),
                    ],
                    maxFlow: "200069000000000000"  // Actual max flow after fees
                )
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
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "1000e6",  // 1000 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: Number.MAX_UINT_256,  // Max WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupplyCollateralAndBorrow(
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
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10e18"  // All available WETH
                        )
                    ],
                    maxFlow: "10e18"
                )
            )
        )
    }

    @Test("Supply additional collateral to existing position")
    func testSupplyAdditionalCollateral() {
        runFlowTest(
            ChartTestCase(
                name: "Supply additional collateral to existing position",
                givens: [
                    // User already has 0.5 WETH as collateral
                    .cometCollateral(.alice, .amt(0.5, .weth), .cusdcv3, .base),
                    // User has 1 WETH in their wallet
                    .tokenBalance(.alice, .amt(1, .weth), .base),
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "0",  // No borrow, just supply collateral
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "1e18",  // Supply 1 WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupplyCollateral(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1e18"  // Supply 1 WETH (resulting in 1.5 WETH total collateral)
                        )
                    ],
                    maxFlow: "1e18"  // Can supply up to 1 WETH from wallet
                )
            )
        )
    }

    @Test("Supply additional collateral and borrow with existing position")
    func testSupplyAdditionalCollateralAndBorrow() {
        runFlowTest(
            ChartTestCase(
                name: "Supply additional collateral and borrow with existing position",
                givens: [
                    // User already has 0.5 WETH as collateral
                    .cometCollateral(.alice, .amt(0.5, .weth), .cusdcv3, .base),
                    // User has 1 WETH in their wallet
                    .tokenBalance(.alice, .amt(1, .weth), .base),
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "500e6",  // Borrow 500 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "1e18",  // Supply 1 WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "500e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1e18"  // Supply 1 WETH and borrow 500 USDC
                        )
                    ],
                    maxFlow: "1e18"  // Can supply up to 1 WETH from wallet
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
                    .tokenBalance(.alice, .amt(0.11, .eth), .arbitrum),  // ETH on Arbitrum (extra for bridge fees)
                    .tokenBalance(.alice, .amt(0.05, .weth), .base),  // Some WETH on Base
                    .acrossQuote(.amt(0.001, .eth), 0.01),  // 1% bridge fee
                    .acrossQuote(.amt(0.001, .weth), 0.01),  // 1% bridge fee
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: "250e6",  // 250 USDC
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "15e16",  // 0.15 WETH total needed
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        // First wrap ETH to WETH on Arbitrum
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
                            amount: "0.102020202020202021e18"  // Amount needed to wrap for bridging
                        ),
                        // Bridge WETH from Arbitrum to Base
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
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
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99 (1% fee)
                                fees: [
                                    Tradewinds.Fee(
                                        type: .bridgeAcross,
                                        isInFee: false,
                                        amount: "0.001e18"
                                    )  // 0.001 WETH fixed cost
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.102020202020202021e18"  // Amount to bridge
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
                        // Supply WETH as collateral and borrow
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupplyCollateralAndBorrow(
                                    borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    borrowAmount: "250e6",
                                    isCappedMaxSupply: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .cometCollateralBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                                    collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "15e16"  // 0.15 WETH
                        ),
                    ],
                    maxFlow: "157900000000000000"  // 0.05e18 + (0.11e18 * 0.99) - 0.001e18
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
                    .cometCollateral(.alice, .amt(0.5, .weth), .cusdcv3, .base),
                ],
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: Number.MAX_UINT_256,  // Max borrow
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: .zero,  // No new collateral
                        collateralAssetSymbol: "",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometBorrow(
                                    asset: BaseNetwork.Assets.USDC.assetAddress,
                                    amount: Number.MAX_UINT_256
                                ),
                                source: .cometBorrowCapacity(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                            amount: "1666e6"  // Max borrow capacity: 0.5 WETH * $4000 * 0.85 * 0.98 = $1666
                        )
                    ],
                    maxFlow: "1666e6"
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
                intent: .cometBorrow(
                    Charter.CometBorrowIntent(
                        amount: Number.MAX_UINT_256,  // Max borrow
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        borrower: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId,
                        collateralAmount: "0.5e18",  // 0.5 WETH
                        collateralAssetSymbol: "WETH",
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
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
