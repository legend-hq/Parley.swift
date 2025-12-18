import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Aave supply and withdraw flows
struct CharterTradewindsAaveTests {
    @Test("Aave Withdraw USDC (Alice) [Base]")
    func testAaveWithdrawAliceBase() {
        runFlowTest(
            ChartTestCase(
                name: "Aave Withdraw USDC (Alice) [Base]",
                givens: [
                    .aaveSupply(.alice, .amt(100, .usdc), .baseV3, .base)
                ],
                intent: .aaveWithdraw(
                    Charter.AaveWithdrawIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        aavePool: AavePool.baseV3.address(network: .base),
                        withdrawer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
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
                        )
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Aave Supply USDC (Alice) [Base]")
    func testAaveSupplyAliceBase() {
        runFlowTest(
            ChartTestCase(
                name: "Aave Supply USDC (Alice) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base)
                ],
                intent: .aaveSupply(
                    Charter.AaveSupplyIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        aavePool: AavePool.baseV3.address(network: .base),
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: AavePool.baseV3.address(network: .base),
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

    @Test("Transfer using Aave balance (Alice -> Bob) [Base]")
    func testTransferUsingAaveBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Transfer using Aave balance (Alice -> Bob) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(20, .usdc), .base),
                    .aaveSupply(.alice, .amt(100, .usdc), .baseV3, .base),
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
                            amount: "50e6"  // Only withdraw 50 USDC from Aave (using 20 from token balance first)
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

    @Test("Bridge and supply to Aave (Arbitrum -> Base)")
    func testBridgeAndSupplyToAave() {
        runFlowTest(
            ChartTestCase(
                name: "Bridge and supply to Aave (Arbitrum -> Base)",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .arbitrum),
                    .acrossQuote(.amt(10, .usdc), 0.002),  // 10 USDC flat fee, 0.2% variable fee
                ],
                intent: .aaveSupply(
                    Charter.AaveSupplyIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        aavePool: AavePool.baseV3.address(network: .base),
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(isCappedMax: false),
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
                                rate: Percentage(fromNumber: "998000000000000000"),  // Bridge fee (0.998 as fixed point)
                                fees: [
                                    Tradewinds.Fee(type: .bridge, isInFee: false, amount: "10e6")  // 10 USDC relayer fee
                                ],
                                minFlow: "0",
                                maxFlow: "1000000e6"
                            ),
                            amount: "60120241"  // Amount needed including fees
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: AavePool.baseV3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                    ],
                    maxFlow: "89800000"
                )
            )
        )
    }

    @Test("Max withdraw from Aave")
    func testMaxWithdrawFromAave() {
        runFlowTest(
            ChartTestCase(
                name: "Max withdraw from Aave",
                givens: [
                    .aaveSupply(.alice, .amt(100, .usdc), .baseV3, .base)
                ],
                intent: .aaveWithdraw(
                    Charter.AaveWithdrawIntent(
                        amount: Number.MAX_UINT_256,
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        aavePool: AavePool.baseV3.address(network: .base),
                        withdrawer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
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
                                rate: Percentage(fromNumber: "1.00001e18"),
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"  // Withdraw entire balance
                        )
                    ],
                    maxFlow: "100.001e6"
                )
            )
        )
    }

    // TODO: Test uses fake second Aave pool (0xd1256...2Ca) which is rejected by aaveMarketNotFound
    // validation added in e5f6689. Atlas currently only has one Aave pool per network.
    @Test("No direct pool-to-pool transfer", .disabled("fake pool rejected by validation"))
    func testNoDirectPoolToPoolTransfer() {
        runFlowTest(
            ChartTestCase(
                name: "No direct pool-to-pool transfer",
                givens: [
                    .aaveSupply(.alice, .amt(100, .usdc), .baseV3, .base)
                ],
                intent: .aaveSupply(
                    Charter.AaveSupplyIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        chainId: BaseNetwork.network.chainId,
                        aavePool: EthAddress("0xd1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"),  // Different pool
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        // Must withdraw from first pool to token
                        .init(
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
                        // Then supply to second pool
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: EthAddress("0xd1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                    ],
                    maxFlow: "100e6"
                ),
                allowUsingEarningBalances: true
            )
        )
    }
}
