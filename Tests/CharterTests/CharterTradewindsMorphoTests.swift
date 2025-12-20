import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Morpho vault supply and withdraw flows
struct CharterTradewindsMorphoTests {
    @Test("Morpho Vault Withdraw USDC (Alice) [Base]")
    func testMorphoVaultWithdrawAliceBase() {
        runFlowTest(
            ChartTestCase(
                name: "Morpho Vault Withdraw USDC (Alice) [Base]",
                givens: [
                    .morphoVaultSupply(.alice, .amt(100, .usdc), .usdc, .base)
                ],
                intent: .morphoVaultWithdraw(
                    Charter.MorphoVaultWithdrawIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        morphoVault: MorphoVault.usdc.address(network: .base),
                        chainId: BaseNetwork.network.chainId,
                        withdrawer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
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

    @Test("Morpho Vault Supply USDC (Alice) [Base]")
    func testMorphoVaultSupplyAliceBase() {
        runFlowTest(
            ChartTestCase(
                name: "Morpho Vault Supply USDC (Alice) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base)
                ],
                intent: .morphoVaultSupply(
                    Charter.MorphoVaultSupplyIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        morphoVault: MorphoVault.usdc.address(network: .base),
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId
                    )
                ),
                expect: .exactFlows(
                    [
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
                                    vault: MorphoVault.usdc.address(network: .base),
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

    @Test("Transfer using Morpho vault balance (Alice -> Bob) [Base]")
    func testTransferUsingMorphoVaultBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Transfer using Morpho vault balance (Alice -> Bob) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(20, .usdc), .base),
                    .morphoVaultSupply(.alice, .amt(100, .usdc), .usdc, .base),
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
                                type: .morphoVaultWithdraw(isMax: false),
                                source: .morphoVaultSupplyBalance(
                                    network: Eth.Network.base,
                                    vault: MorphoVault.usdc.address(network: .base),
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
                            amount: "50e6"  // Only withdraw 50 USDC from Morpho (using 20 from token balance first)
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

    @Test("Bridge and supply to Morpho vault (Arbitrum -> Base)")
    func testBridgeAndSupplyToMorphoVault() {
        runFlowTest(
            ChartTestCase(
                name: "Bridge and supply to Morpho vault (Arbitrum -> Base)",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .arbitrum),
                    .acrossQuote(.amt(10, .usdc), 0.002),  // 10 USDC flat fee, 0.2% variable fee
                ],
                intent: .morphoVaultSupply(
                    Charter.MorphoVaultSupplyIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        morphoVault: MorphoVault.usdc.address(network: .base),
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId
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
                                rate: Percentage(fromNumber: "998000000000000000"),  // Bridge fee (0.998 as fixed point)
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "10e6")  // 10 USDC relayer fee
                                ],
                                minFlow: "0",
                                maxFlow: "1000000e6"
                            ),
                            amount: "60120241"  // Amount needed including fees
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
                                    vault: MorphoVault.usdc.address(network: .base),
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

    @Test("Max withdraw from Morpho vault")
    func testMaxWithdrawFromMorphoVault() {
        runFlowTest(
            ChartTestCase(
                name: "Max withdraw from Morpho vault",
                givens: [
                    .morphoVaultSupply(.alice, .amt(100, .usdc), .usdc, .base)
                ],
                intent: .morphoVaultWithdraw(
                    Charter.MorphoVaultWithdrawIntent(
                        amount: Number.MAX_UINT_256,
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        morphoVault: MorphoVault.usdc.address(network: .base),
                        chainId: BaseNetwork.network.chainId,
                        withdrawer: EthAddress("0x00000000000000000000000000000000000A11CE")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
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

    @Test("No direct vault-to-vault transfer")
    func testNoDirectVaultToVaultTransfer() {
        runFlowTest(
            ChartTestCase(
                name: "No direct vault-to-vault transfer",
                givens: [
                    .morphoVaultSupply(.alice, .amt(100, .usdc), .usdc, .base)
                ],
                intent: .morphoVaultSupply(
                    Charter.MorphoVaultSupplyIntent(
                        amount: "50e6",
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        morphoVault: EthAddress("0xd1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"),  // Different vault
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: BaseNetwork.network.chainId
                    )
                ),
                expect: .exactFlows(
                    [
                        // Must withdraw from first vault to token
                        .init(
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
                        // Then supply to second vault
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
                                    vault: EthAddress("0xd1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"),
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
