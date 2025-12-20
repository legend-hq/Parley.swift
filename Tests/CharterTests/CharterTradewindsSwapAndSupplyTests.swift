import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for swap and supply intents
struct CharterTradewindsSwapAndSupplyTests {
    @Test("Basic flow: USDC → ETH → Aave supply (same chain)")
    func testBasicSwapAndSupplySameChain() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Swap and Supply Same Chain",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: "1000e6",  // 1000 USDC
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.333e18",  // 0.333 ETH (rate: 3000 USDC/ETH)
                            swapQuoteSellAmount: "1000e6",
                            swapQuoteBuyAmount: "0.333e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number.MAX_UINT_256,  // Supply all ETH received
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.333e18",
                                    swapQuoteSellAmount: "1000e6",
                                    swapQuoteBuyAmount: "0.333e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isBuy: false,
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
                                    fromRatio: Number("0.333e18").asSNumber,
                                    over: Number("1000e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "1000e6"
                            ),
                            amount: "1000e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.333e18"
                        ),
                    ],
                    maxFlow: "0.333e18"  // Max flow is the supply amount
                )
            )
        )
    }

    @Test("Cross-chain flow: Swap USDC→WETH on Arbitrum, supply to Aave on Base")
    func testCrossChainSwapAndSupply() {
        runFlowTest(
            ChartTestCase(
                name: "Cross-chain Swap and Supply",
                givens: [
                    .tokenBalance(.alice, .amt(2000, .usdc), .arbitrum),
                    .acrossQuote(.amt(0.01, .weth), 0.01),  // 1% fee and 0.01 WETH fixed cost
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(ArbitrumNetwork.chainId),
                            sellToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                            sellAmount: "2000e6",  // 2000 USDC
                            buyToken: ArbitrumNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.667e18",  // 0.667 ETH (enough to cover bridge fees)
                            swapQuoteSellAmount: "2000e6",
                            swapQuoteBuyAmount: "0.667e18",
                            feeToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.667e18",
                                    swapQuoteSellAmount: "2000e6",
                                    swapQuoteBuyAmount: "0.667e18",
                                    feeToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isBuy: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.667e18").asSNumber,
                                    over: Number("2000e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "2000e6"
                            ),
                            amount: "2000e6"
                        ),
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
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "0.01e18")
                                ],
                                minFlow: "0",
                                maxFlow: "10000e18"  // 10000 ETH max
                            ),
                            amount: "0.667e18"
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
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.65033e18"  // Wrap exactly what we need to supply
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.65033e18"
                        ),
                    ],
                    maxFlow: "0.65033e18"  // Max flow is the supply amount
                )
            )
        )
    }

    @Test("With wrapping: ETH → WETH swap → Morpho supply")
    func testSwapWithWrappingToMorpho() {
        runFlowTest(
            ChartTestCase(
                name: "Swap with Wrapping to Morpho",
                givens: [
                    .tokenBalance(.alice, .amt(5, .eth), .base),
                    .quote(.basic),  // Include basic quote for ETH/WETH wrapping
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.WETH.assetAddress,
                            sellAmount: "2e18",  // 2 WETH
                            buyToken: BaseNetwork.Assets.USDC.assetAddress,
                            buyAmount: "6000e6",  // 6000 USDC
                            swapQuoteSellAmount: "2e18",
                            swapQuoteBuyAmount: "6000e6",
                            feeToken: BaseNetwork.Assets.WETH.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: Number.MAX_UINT_256,  // Supply MAX (all USDC received)
                                assetSymbol: "USDC",
                                morphoVault: EthAddress(
                                    "0x8eB67A509616cd6A7c1B3c8C21D48FF57df3d458"
                                ),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        )
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
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2e18"  // Wrap only what's needed for swap (respects maxFlow)
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.USDC.assetAddress,
                                    buyAmount: "6000e6",
                                    swapQuoteSellAmount: "2e18",
                                    swapQuoteBuyAmount: "6000e6",
                                    feeToken: BaseNetwork.Assets.WETH.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isBuy: false,
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
                                    fromRatio: Number("6000e6").asSNumber,
                                    over: Number("2e18").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "2e18"
                            ),
                            amount: "2e18"  // Swap constrained by maxFlow
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: Eth.Network.base,
                                    vault: EthAddress("0x8eB67A509616cd6A7c1B3c8C21D48FF57df3d458"),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "6000e6"  // Supply what we got from swap (2 WETH * 3000 = 6000)
                        ),
                    ],
                    maxFlow: "5999.98e6"  // 6000 USDC - 0.02 fee (respects swap maxFlow constraint)
                )
            )
        )
    }

    @Test("Complex cross-chain exact flows")
    func testComplexCrossChainGatherSwapAndSupplyExactFlows() {
        runFlowTest(
            ChartTestCase(
                name: "Complex Cross-chain Gather Swap and Supply",
                givens: [
                    .tokenBalance(.alice, .amt(3000, .usdc), .optimism),
                    .tokenBalance(.alice, .amt(500, .usdc), .arbitrum),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% fee, 1 USDC fixed cost
                    .acrossQuote(.amt(0.01, .weth), 0.01),  // 1% fee for WETH bridge
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(ArbitrumNetwork.chainId),
                            sellToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                            sellAmount: "3000e6",  // 3000 USDC total
                            buyToken: ArbitrumNetwork.Assets.WETH.assetAddress,
                            buyAmount: "1e18",  // 1 ETH
                            swapQuoteSellAmount: "3000e6",
                            swapQuoteBuyAmount: "1e18",
                            feeToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,  // Supply all swap output
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: EthAddress("0x46e6b214b524310239732D51387075E0e70970bf"),  // cWETHv3 on Base
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .exactFlows(
                    [
                        // Bridge USDC from Optimism to Arbitrum
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
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
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
                            amount: "2526262627"  // Bridge to get 2500 USDC on Arbitrum (plus 500 already there = 3000 for swap): (2500 + 1) / 0.99 ≈ 2526.26
                        ),
                        // Swap USDC to WETH on Arbitrum (exact-in: must swap exactly 3000 USDC)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "1e18",
                                    swapQuoteSellAmount: "3000e6",
                                    swapQuoteBuyAmount: "1e18",
                                    feeToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isBuy: false,
                                    isCappedMax: false
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(
                                    fromRatio: Number("1e18").asSNumber,
                                    over: Number("3000e6").asSNumber
                                ),
                                minFlow: "3000e6",  // Exact-in swap requires exact amount
                                maxFlow: "3000e6"
                            ),
                            amount: "3000000000"  // Exact-in swap: must use exactly 3000 USDC
                        ),
                        // Bridge WETH from Arbitrum to Base (.max semantics: bridge all swap output)
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
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "0.01e18")
                                ],
                                minFlow: "0",
                                maxFlow: "10000e18"
                            ),
                            amount: "1000000000000000000"  // Bridge all 1 ETH from swap
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
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "980000000000000000"  // Wrap all ETH received after bridge (0.98 ETH)
                        ),
                        // Supply WETH to Comet on Base
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
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "980000000000000000"  // Supply all WETH (.max semantics)
                        ),
                    ],
                    maxFlow: "980000000000000000"  // Max flow achievable with exact-in swap constraint (0.98 WETH after all fees)
                )
            )
        )
    }

    @Test("MAX amounts: Swap specific, supply MAX")
    func testSwapSpecificSupplyMax() {
        runFlowTest(
            ChartTestCase(
                name: "Swap Specific Supply MAX",
                givens: [
                    .tokenBalance(.alice, .amt(1500, .usdc), .base)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: "1500e6",  // Swap all 1500 USDC
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.5e18",  // 0.5 ETH
                            swapQuoteSellAmount: "1500e6",
                            swapQuoteBuyAmount: "0.5e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number.MAX_UINT_256,  // Supply ALL ETH received
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.5e18",
                                    swapQuoteSellAmount: "1500e6",
                                    swapQuoteBuyAmount: "0.5e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isBuy: false,
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
                                    fromRatio: Number("0.5e18").asSNumber,
                                    over: Number("1500e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "1500e6"
                            ),
                            amount: "1500e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "500000000000000000"  // 0.5 ETH
                        ),
                    ],
                    maxFlow: "500000000000000000"  // Max flow is 0.5 ETH
                )
            )
        )
    }

    @Test("Insufficient balance: Not enough for swap")
    func testInsufficientBalanceForSwap() {
        runFlowTest(
            ChartTestCase(
                name: "Insufficient Balance for Swap",
                givens: [
                    .tokenBalance(.alice, .amt(500, .usdc), .base)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: "1000e6",  // Want to sell 1000 but only have 500
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.333e18",
                            swapQuoteSellAmount: "1000e6",
                            swapQuoteBuyAmount: "0.333e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number.MAX_UINT_256,  // Supply all swap output
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .failure(
                    Tradewinds.Error.insufficientResources(target: .max, max: "0"),
                    maxFlow: "0"
                )  // Cannot partially execute swap quote (quote is for 1000 USDC, not 500)
            )
        )
    }

    @Test("Amount validation: Supply must be .max")
    func testSupplyMustBeMax() {
        runFlowTest(
            ChartTestCase(
                name: "Supply Must Be Max",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: "1000e6",
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.3e18",
                            swapQuoteSellAmount: "1000e6",
                            swapQuoteBuyAmount: "0.3e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: "0.4e18",  // Non-.max supply amount (invalid)
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.error(
                        "SwapAndSupply requires supply amount to be .max (supply all swap output)"
                    )
                )
            )
        )
    }

    @Test("No bridge path: Buy token doesn't exist on supply network")
    func testNoBridgePath() {
        runFlowTest(
            ChartTestCase(
                name: "No Bridge Path",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .arbitrum)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(ArbitrumNetwork.chainId),
                            sellToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                            sellAmount: "1000e6",
                            buyToken: EthAddress("0x0000000000000000000000000000000000faca01"),  // Fake token
                            buyAmount: "1000e18",
                            swapQuoteSellAmount: "1000e6",
                            swapQuoteBuyAmount: "1000e18",
                            feeToken: ArbitrumNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: "1000e18",
                                assetSymbol: "FAKE",  // Asset doesn't exist on Base
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.unknownAsset(
                        symbol: nil,
                        network: Eth.Network.arbitrum,
                        address: EthAddress("0x0000000000000000000000000000000000faca01")
                    )
                )
            )
        )
    }

    @Test("Validation: Different senders")
    func testDifferentSenders() {
        runFlowTest(
            ChartTestCase(
                name: "Different Senders Validation",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: "1000e6",
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.333e18",
                            swapQuoteSellAmount: "1000e6",
                            swapQuoteBuyAmount: "0.333e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: "0.333e18",
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000B0B0B")  // Different sender
                            )
                        )
                    )
                ),
                expect: .charterFailure(Charter.CharterError.swapAndSupplyMustHaveSameSender)
            )
        )
    }

    @Test("Validation: Asset mismatch")
    func testAssetMismatch() {
        runFlowTest(
            ChartTestCase(
                name: "Asset Mismatch Validation",
                givens: [
                    .tokenBalance(.alice, .amt(1000, .usdc), .base)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: "1000e6",
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,  // Buying WETH
                            buyAmount: "0.333e18",
                            swapQuoteSellAmount: "1000e6",
                            swapQuoteBuyAmount: "0.333e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: "1000e6",
                                assetSymbol: "USDC",  // But trying to supply USDC
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.swapBuyTokenMustMatchSupplyAsset(
                        swapBuyToken: "WETH",
                        supplyAsset: "USDC"
                    )
                )
            )
        )
    }

    @Test("Max Swap and Supply")
    func testMaxSwapAndSupply() {
        runFlowTest(
            ChartTestCase(
                name: "Max Swap and Supply",
                givens: [
                    .tokenBalance(.alice, .amt(2000, .usdc), .base)
                ],
                intent: .swapAndSupply(
                    Charter.SwapAndSupplyIntent(
                        swapIntent: Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.667e18",  // 0.667 ETH
                            swapQuoteSellAmount: "2000e6",
                            swapQuoteBuyAmount: "0.667e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                            isExactOut: false,
                            isBuy: false
                        ),
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        )
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.667e18",
                                    swapQuoteSellAmount: "2000e6",
                                    swapQuoteBuyAmount: "0.667e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isBuy: false,
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
                                    fromRatio: Number("0.677005e18").asSNumber,
                                    over: Number("2000e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "2000e6"
                            ),
                            amount: "2000e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("1e18")),  // 1:1
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.677005e18"
                        ),
                    ],
                    maxFlow: "0.677005e18"
                )
            )
        )
    }
}
