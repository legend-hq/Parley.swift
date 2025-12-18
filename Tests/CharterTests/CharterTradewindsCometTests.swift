import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Comet supply and withdraw flows
struct CharterTradewindsCometTests {
    @Test("Comet Withdraw USDC (Alice) [Base]")
    func testCometWithdrawAliceBase() {
        runFlowTest(
            ChartTestCase(
                name: "Comet Withdraw USDC (Alice) [Base]",
                givens: [
                    .cometSupply(.alice, .amt(100, .usdc), .cusdcv3, .base)
                ],
                intent: .cometWithdraw(
                    Charter.CometWithdrawIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),  // cUSDCv3 on Base
                        withdrawer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                        )
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Transfer using Comet balance (Alice -> Bob) [Base]")
    func testTransferUsingCometBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Transfer using Comet balance (Alice -> Bob) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(20, .usdc), .base),
                    .cometSupply(.alice, .amt(100, .usdc), .cusdcv3, .base),
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: BaseNetwork.network.chainId,
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "70e6",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                            amount: "50e6"  // Only withdraw 50 USDC from Comet (using 20 from token balance first)
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "70e6"
                        ),
                    ],
                    maxFlow: "120e6"
                ),
                allowUsingEarningBalances: true
            )
        )
    }

    @Test("Transfer without using Comet balance (Alice -> Bob) [Base]")
    func testTransferWithoutUsingCometBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Transfer without using Comet balance (Alice -> Bob) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .cometSupply(.alice, .amt(100, .usdc), .cusdcv3, .base),
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: BaseNetwork.network.chainId,
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "30e6",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "30e6"
                        )
                    ],
                    maxFlow: "50e6"  // Only token balance, not including Comet
                )
            )
        )
    }

    @Test("Bridge using Comet balance (Alice Base -> Alice Arbitrum)")
    func testBridgeUsingCometBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Bridge using Comet balance (Alice Base -> Alice Arbitrum)",
                givens: [
                    .tokenBalance(.alice, .amt(10, .usdc), .base),
                    .cometSupply(.alice, .amt(100, .usdc), .cusdcv3, .base),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: ArbitrumNetwork.network.chainId,
                        assetSymbol: ArbitrumNetwork.Assets.USDC.symbol,
                        amount: "50e6",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                            amount: "41515152"  // (50e6 + 1e6) / 0.99 - 10e6 = 41,515,151.51
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                fees: [
                                    Tradewinds.Fee(type: .bridge, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "51515152"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                    ],
                    maxFlow: "107900000"  // (110e6 * 0.99) - 1e6 = 107.9e6
                ),
                allowUsingEarningBalances: true
            )
        )
    }

    @Test("Comet Supply USDC (Alice) [Base]")
    func testCometSupplyAliceBase() {
        runFlowTest(
            ChartTestCase(
                name: "Comet Supply USDC (Alice) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base)
                ],
                intent: .cometSupply(
                    Charter.CometSupplyIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),  // cUSDCv3 on Base
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        )
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Comet Supply with ETH wrapping (Alice) [Base]")
    func testCometSupplyWithWrapping() {
        runFlowTest(
            ChartTestCase(
                name: "Comet Supply with ETH wrapping (Alice) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(1, .eth), .base)
                    // tokenWrapperQuotes for ETH/WETH are hardcoded in PortfolioGenerators
                ],
                intent: .cometSupply(
                    Charter.CometSupplyIntent(
                        amount: "1e18",
                        assetSymbol: BaseNetwork.Assets.WETH.symbol,
                        chainId: BaseNetwork.network.chainId,
                        comet: EthAddress("0x46e6b214b524310239732D51387075E0e70970bf"),  // cWETHv3 on Base
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE")
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
                            amount: "1e18"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0x46e6b214b524310239732D51387075E0e70970bf"),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1e18"
                        ),
                    ],
                    maxFlow: "1e18"
                )
            )
        )
    }

    @Test("Bridge with Fixed Cost using Only Comet Balance")
    func testBridgeWithFixedCostUsingOnlyCometBalance() {
        // Test where we need to withdraw exact amount from Comet to cover bridge fees
        runFlowTest(
            ChartTestCase(
                name: "Bridge with Fixed Cost using Only Comet Balance",
                givens: [
                    .cometSupply(.alice, .amt(20, .usdc), .cusdcv3, .base),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% fee, 1 USDC fixed cost
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: ArbitrumNetwork.network.chainId,
                        assetSymbol: ArbitrumNetwork.Assets.USDC.symbol,
                        amount: "15e6",  // Want to receive 15 USDC on Arbitrum
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                            amount: "16161617"  // (15e6 + 1e6) / 0.99 = 16.161616e6 (rounded up)
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                fees: [
                                    Tradewinds.Fee(type: .bridge, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "16161617"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "15e6"
                        ),
                    ],
                    maxFlow: "18800000"  // (20e6 * 0.99) - 1e6 = 18.8e6
                ),
                allowUsingEarningBalances: true
            )
        )
    }

    @Test("Complex Bridge Path with Comet and Fixed Costs")
    func testComplexBridgePathWithCometAndFixedCosts() {
        // Test combining token balance, Comet withdrawal, and bridge with fixed costs
        runFlowTest(
            ChartTestCase(
                name: "Complex Bridge Path with Comet and Fixed Costs",
                givens: [
                    .tokenBalance(.alice, .amt(5, .usdc), .base),
                    .cometSupply(.alice, .amt(30, .usdc), .cusdcv3, .base),
                    .acrossQuote(.amt(2, .usdc), 0.02),  // 2% fee, 2 USDC fixed cost
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: ArbitrumNetwork.network.chainId,
                        assetSymbol: ArbitrumNetwork.Assets.USDC.symbol,
                        amount: "25e6",  // Want to receive 25 USDC on Arbitrum
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                            amount: "22551021"  // Expected: (25+2)/0.98 - 5 = 22.551021
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.98e18")),  // 0.98 (2% fee)
                                fees: [
                                    Tradewinds.Fee(type: .bridge, isInFee: false, amount: "2e6")
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "27551021"  // Expected: (25+2)/0.98 = 27.551021
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "25e6"
                        ),
                    ],
                    maxFlow: "32300000"  // (35e6 * 0.98) - 2e6 = 32.3e6
                ),
                allowUsingEarningBalances: true
            )
        )
    }

    @Test("Comet Withdraw with amount below QuotePay fee")
    func testCometWithdrawAmountBelowQuotePayFee() {
        // User wants 0.1 USDC net, but QuotePay fee is 0.5 USDC.
        // Tradewinds figures out to withdraw 0.6 USDC (0.1 target + 0.5 fee).
        runFlowTest(
            ChartTestCase(
                name: "Comet Withdraw with amount below QuotePay fee",
                givens: [
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [Token.usdc: 1.0],
                            fees: [
                                .base: 0.5
                            ]
                        )
                    ),
                ],
                intent: .cometWithdraw(
                    Charter.CometWithdrawIntent(
                        amount: "0.1e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                        withdrawer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
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
                            amount: "0.6e6"
                        )
                    ],
                    maxFlow: "9.5e6"
                )
            )
        )
    }

    @Test("Comet Supply WETH with ETH+WETH available - should use WETH directly [Base]")
    func testCometSupplyWethWithBothEthAndWethAvailable() {
        runFlowTest(
            ChartTestCase(
                name: "Comet Supply WETH with ETH+WETH available - should use WETH directly [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(0.005, .eth), .base),
                    .tokenBalance(.alice, .amt(0.121, .weth), .base),
                ],
                intent: .cometSupply(
                    Charter.CometSupplyIntent(
                        amount: Number("312784753874691"),
                        assetSymbol: BaseNetwork.Assets.WETH.symbol,
                        chainId: BaseNetwork.network.chainId,
                        comet: EthAddress("0x46e6b214b524310239732d51387075e0e70970bf"),
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: EthAddress("0x46e6b214b524310239732d51387075e0e70970bf"),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: Number("312784753874691")
                        )
                    ],
                    maxFlow: Number("126000000000000000")
                )
            )
        )
    }

}
