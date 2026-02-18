import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for swap intents
struct CharterTradewindsSwapTests {
    @Test("Simple Swap USDC -> ETH")
    func testSimpleSwapUsdcToEth() {
        runFlowTest(
            ChartTestCase(
                name: "Simple Swap USDC -> ETH",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base)
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: "100e6",
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,
                        buyAmount: "0.03e18",  // 0.03 ETH
                        swapQuoteSellAmount: "100e6",
                        swapQuoteBuyAmount: "0.03e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.03e18",
                                    swapQuoteSellAmount: "100e6",
                                    swapQuoteBuyAmount: "0.03e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.03e18").asSNumber,
                                    over: Number("100e6").asSNumber
                                ),
                                minFlow: "100e6",
                                maxFlow: "100e6"
                            ),
                            amount: "100e6"
                        )
                    ],
                    maxFlow: "0.03e18"
                )
            )
        )
    }

    @Test("Swap Only Uses Sender Funds")
    func testSwapOnlyUsesSenderFunds() {
        runFlowTest(
            ChartTestCase(
                name: "Swap Only Uses Sender Funds",
                givens: [
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .tokenBalance(.bob, .amt(75, .usdc), .base),
                    .tokenBalance(.carl, .amt(100, .usdc), .base),
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: "50e6",  // Alice only has 50 USDC
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,
                        buyAmount: "0.02e18",  // 0.02 ETH
                        swapQuoteSellAmount: "50e6",
                        swapQuoteBuyAmount: "0.02e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.02e18",
                                    swapQuoteSellAmount: "50e6",
                                    swapQuoteBuyAmount: "0.02e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.02e18").asSNumber,
                                    over: Number("50e6").asSNumber
                                ),
                                minFlow: "50e6",
                                maxFlow: "50e6"
                            ),
                            amount: "50e6"  // Uses all of Alice's balance
                        )
                    ],
                    maxFlow: "0.02e18"
                )
            )
        )
    }

    @Test("Swap Exact Out Mode")
    func testSwapExactOutMode() {
        runFlowTest(
            ChartTestCase(
                name: "Swap Exact Out Mode",
                givens: [
                    // Add +$0.02 (Base QuotePay) so exact-out can include fee
                    .tokenBalance(.alice, .amt(500.02, .usdc), .base)
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: "150.02e6",  // Max sell amount (includes Base QuotePay buffer)
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,
                        buyAmount: "0.05e18",  // Exact out: 0.05 ETH
                        swapQuoteSellAmount: "145e6",  // Quoted sell amount
                        swapQuoteBuyAmount: "0.05e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: true,
                        isBuy: true
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.05e18",
                                    swapQuoteSellAmount: "145e6",
                                    swapQuoteBuyAmount: "0.05e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: true,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.05e18").asSNumber,
                                    over: Number("150.02e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "150.02e6"
                            ),
                            amount: "150.02e6"  // Includes Base QuotePay fee buffer
                        )
                    ],
                    maxFlow: "0.05e18"  // Exact target achieved with rounding-based precision
                )
            )
        )
    }

    @Test("Swap with Wrapped Token (ETH -> USDC via WETH)")
    func testSwapWithWrappedToken() {
        runFlowTest(
            ChartTestCase(
                name: "Swap with Wrapped Token",
                givens: [
                    .tokenBalance(.alice, .amt(1, .weth), .base),
                    .quote(.basic),  // Include basic quote for wrapper quotes
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.WETH.assetAddress,
                        sellAmount: "0.5e18",  // 0.5 WETH
                        buyToken: BaseNetwork.Assets.USDC.assetAddress,
                        buyAmount: "1500e6",  // 1500 USDC
                        swapQuoteSellAmount: "0.5e18",
                        swapQuoteBuyAmount: "1500e6",
                        feeToken: BaseNetwork.Assets.WETH.assetAddress,
                        feeAmount: "0.001e18",  // 0.001 WETH fee
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.USDC.assetAddress,
                                    buyAmount: "1500e6",
                                    swapQuoteSellAmount: "0.5e18",
                                    swapQuoteBuyAmount: "1500e6",
                                    feeToken: BaseNetwork.Assets.WETH.assetAddress,
                                    feeAmount: "0.001e18",
                                    isExactOut: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("1500e6").asSNumber,
                                    over: Number("0.5e18").asSNumber
                                ),
                                minFlow: "0.5e18",
                                maxFlow: "0.5e18"
                            ),
                            amount: "0.5e18"
                        )
                    ],
                    maxFlow: "1500e6"
                )
            )
        )
    }

    @Test("Swap Insufficient Balance")
    func testSwapInsufficientBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Swap Insufficient Balance",
                givens: [
                    .tokenBalance(.alice, .amt(50, .usdc), .base)
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: "100e6",  // Wants to sell 100 but only has 50
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,
                        buyAmount: "0.03e18",
                        swapQuoteSellAmount: "100e6",
                        swapQuoteBuyAmount: "0.03e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .failure(
                    Tradewinds.Error.insufficientResources(target: .max, max: "0"),
                    maxFlow: "0"
                )  // Exact-in requires exact amount, no partial
            )
        )
    }

    @Test("Swap with ETH Wrapping (ETH -> WETH -> USDC)")
    func testSwapWithEthWrapping() {
        runFlowTest(
            ChartTestCase(
                name: "Swap with ETH Wrapping",
                givens: [
                    .tokenBalance(.alice, .amt(2, .eth), .base),
                    .quote(.basic),  // Include quotes for ETH/WETH wrapping
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.WETH.assetAddress,
                        sellAmount: "1e18",  // 1 WETH
                        buyToken: BaseNetwork.Assets.USDC.assetAddress,
                        buyAmount: "3000e6",  // 3000 USDC
                        swapQuoteSellAmount: "1e18",
                        swapQuoteBuyAmount: "3000e6",
                        feeToken: BaseNetwork.Assets.WETH.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
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
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.USDC.assetAddress,
                                    buyAmount: "3000e6",
                                    swapQuoteSellAmount: "1e18",
                                    swapQuoteBuyAmount: "3000e6",
                                    feeToken: BaseNetwork.Assets.WETH.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("3000e6").asSNumber,
                                    over: Number("1e18").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "1e18"
                            ),
                            amount: "1e18"
                        ),
                    ],
                    maxFlow: "3000e6"  // Max flow is buy amount (USDC)
                )
            )
        )
    }

    @Test("Swap with Cross-Chain Bridge (USDC Arbitrum -> Base swap to WETH)")
    func testSwapWithCrossChainBridge() {
        runFlowTest(
            ChartTestCase(
                name: "Swap with Cross-Chain Bridge",
                givens: [
                    // Add extra USDC on Arbitrum to cover bridge amount + QuotePay fee
                    .tokenBalance(.alice, .amt(5000.4, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(100.02, .usdc), .base),  // Small balance on Base + QuotePay
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% fee, 1 USDC fixed cost
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: "3000e6",  // 3000 USDC
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,
                        buyAmount: "1e18",  // 1 ETH
                        swapQuoteSellAmount: "3000e6",
                        swapQuoteBuyAmount: "1e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "2930.282829e6"  // Bridge amount accounts for 1% rate and 1 USDC fixed outFee to net ~2900e6, plus existing 100e6 on Base = 3000e6
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "1e18",
                                    swapQuoteSellAmount: "3000e6",
                                    swapQuoteBuyAmount: "1e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("1e18").asSNumber,
                                    over: Number("3000e6").asSNumber
                                ),
                                minFlow: "3000e6",
                                maxFlow: "3000e6"
                            ),
                            amount: "3000e6"  // Exact-in requires exact sellAmount
                        ),
                    ],
                    maxFlow: "1e18"  // Exact swap of 3000 USDC -> 1 ETH
                )
            )
        )
    }

    @Test("Swap with Bridge and Wrap (USDC Arbitrum -> ETH Base via WETH)")
    func testSwapWithBridgeAndUnwrap() {
        runFlowTest(
            ChartTestCase(
                name: "Swap with Bridge and Target ETH",
                givens: [
                    // Add extra USDC on Arbitrum to cover bridge amount + QuotePay fee
                    .tokenBalance(.alice, .amt(5000.4, .usdc), .arbitrum),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% fee, 1 USDC fixed cost
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: "3000e6",  // 3000 USDC
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,  // Target WETH (not ETH directly)
                        buyAmount: "1e18",  // 1 WETH
                        swapQuoteSellAmount: "3000e6",
                        swapQuoteBuyAmount: "1e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "3031.313132e6"  // Bridge delivers full amount (3000/0.99 + 1)
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "1e18",
                                    swapQuoteSellAmount: "3000e6",
                                    swapQuoteBuyAmount: "1e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("1e18").asSNumber,
                                    over: Number("3000e6").asSNumber
                                ),
                                minFlow: "3000e6",
                                maxFlow: "3000e6"
                            ),
                            amount: "3000e6"  // Exact-in requires exact sellAmount
                        ),
                    ],
                    maxFlow: "1e18"  // Exact swap of 3000 USDC -> 1 ETH
                )
            )
        )
    }

    @Test("Swap with Multiple Bridges (USDC from multiple chains to Base)")
    func testSwapWithMultipleBridges() {
        runFlowTest(
            ChartTestCase(
                name: "Swap with Multiple Bridges",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(1500, .usdc), .optimism),
                    .tokenBalance(.alice, .amt(500, .usdc), .base),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% fee, 1 USDC fixed cost
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: "2500e6",  // 2500 USDC total
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,
                        buyAmount: "0.8e18",  // 0.8 ETH
                        swapQuoteSellAmount: "2500e6",
                        swapQuoteBuyAmount: "0.8e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // Use Base balance first (500 USDC)
                        // Then bridge from Arbitrum (1000 USDC available)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "1000e6"  // Bridge all from Arbitrum
                        ),
                        // Then bridge from Optimism
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.optimism,
                                    address: OptimismNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "1022.222223e6"  // Need about 1011 USDC after fees to reach 2500 total
                        ),
                        // Finally swap
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.8e18",
                                    swapQuoteSellAmount: "2500e6",
                                    swapQuoteBuyAmount: "0.8e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.8e18").asSNumber,
                                    over: Number("2500e6").asSNumber
                                ),
                                minFlow: "2500e6",
                                maxFlow: "2500e6"
                            ),
                            amount: "2500e6"
                        ),
                    ],
                    maxFlow: "0.8e18"  // Exact-in swap: 2500 USDC -> 0.8 ETH
                )
            )
        )
    }

    @Test("Max Swap USDC -> ETH")
    func testMaxSwapUsdcToEth() {
        runFlowTest(
            ChartTestCase(
                name: "Max Swap USDC -> ETH",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base)
                ],
                intent: .swap(
                    Charter.SwapIntent(
                        chainId: Number(BaseNetwork.chainId),
                        sellToken: BaseNetwork.Assets.USDC.assetAddress,
                        sellAmount: Number.MAX_UINT_256,
                        buyToken: BaseNetwork.Assets.WETH.assetAddress,
                        buyAmount: "0.3e18",  // 0.3 ETH
                        swapQuoteSellAmount: "1000e6",
                        swapQuoteBuyAmount: "0.3e18",
                        feeToken: BaseNetwork.Assets.USDC.assetAddress,
                        feeAmount: "0",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        isExactOut: false,
                        isBuy: false
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.3e18",
                                    swapQuoteSellAmount: "1000e6",
                                    swapQuoteBuyAmount: "0.3e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.3045e18").asSNumber,
                                    over: Number("1000e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "1000e6"
                            ),
                            amount: "1000e6"
                        )
                    ],
                    maxFlow: "0.3045e18"
                )
            )
        )
    }
}
