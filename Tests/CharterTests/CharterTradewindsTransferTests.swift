import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Legend transfers
struct CharterTradewindsTransferTests {
    @Test("Simple Transfer (Alice -> Bob) [Base]")
    func testSimpleTransferAliceToBobBase() {
        runFlowTest(
            ChartTestCase(
                name: "Simple Transfer (Alice -> Bob) [Base]",
                givens: [
                    .tokenBalance(.alice, .amt(5, .usdc), .base)
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "3e6",
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
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "3e6"
                        )
                    ],
                    maxFlow: "5e6"
                )
            )
        )
    }

    @Test("Transfer MAX USDC (uint256.max) (Alice [Base] -> Bob [Arbitrum])")
    func testTransferMaxUsdcFromAliceToBobBaseToArbitrum() {
        runFlowTest(
            ChartTestCase(
                name: "Transfer MAX USDC (uint256.max) (Alice [Base] -> Bob [Arbitrum])",
                givens: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: Number.max,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x000000000000000000000000000000000000B0BA")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress.on(Eth.Network.arbitrum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000a11ce").on(Eth.Network.arbitrum)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                fees: [
                                    Tradewinds.Fee(
                                        type: LegendFeeType.bridgeAcross,
                                        isInFee: false,
                                        amount: "1e6"
                                    )
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "50e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x000000000000000000000000000000000000b0ba").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "98.5e6"
                        ),
                    ],
                    maxFlow: "98.5e6"
                )
            )
        )
    }

    @Test("Bridge Transfer with Fixed Cost Edge Case (Alice [Arbitrum] -> Bob [Base])")
    func testBridgeTransferWithFixedCostEdgeCase() {
        // Test case where the fixed cost significantly impacts the transfer amount
        runFlowTest(
            ChartTestCase(
                name: "Bridge Transfer with Fixed Cost Edge Case",
                givens: [
                    .tokenBalance(.alice, .amt(10, .usdc), .arbitrum),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% fee, 1 USDC fixed cost
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "8e6",  // Want to receive 8 USDC on Base
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress.on(Eth.Network.arbitrum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.arbitrum)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                fees: [
                                    Tradewinds.Fee(
                                        type: LegendFeeType.bridgeAcross,
                                        isInFee: false,
                                        amount: "1e6"
                                    )
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "9.090910e6"  // (8e6 + 1e6) / 0.99 = 9.09091e6 (rounded up)
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "8e6"
                        ),
                    ],
                    maxFlow: "8.9e6"  // (10e6 * 0.99) - 1e6 = 8.9e6
                )
            )
        )
    }

    @Test("Small Bridge Transfer Where Fixed Cost Dominates")
    func testSmallBridgeTransferWithHighFixedCost() {
        // Test case where fixed cost is a large percentage of the transfer
        runFlowTest(
            ChartTestCase(
                name: "Small Bridge Transfer Where Fixed Cost Dominates",
                givens: [
                    .tokenBalance(.alice, .amt(5, .usdc), .arbitrum),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% fee, 1 USDC fixed cost
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "2e6",  // Want to receive 2 USDC on Base (50% goes to fixed cost!)
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress.on(Eth.Network.arbitrum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.arbitrum)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                fees: [
                                    Tradewinds.Fee(
                                        type: LegendFeeType.bridgeAcross,
                                        isInFee: false,
                                        amount: "1e6"
                                    )
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "3.030304e6"  // (2e6 + 1e6) / 0.99 = 3.030303e6 (rounded up)
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "2e6"
                        ),
                    ],
                    maxFlow: "3.95e6"  // (5e6 * 0.99) - 1e6 = 3.95e6
                )
            )
        )
    }

    @Test("Simple Transfer (Alice -> Bob) [Base] with Quote Pay")
    func testSimpleTransferAliceToBobBaseWithQuotePay() {
        runFlowTest(
            ChartTestCase(
                name: "Simple Transfer (Alice -> Bob) [Base] with Quote Pay",
                givens: [
                    .tokenBalance(.alice, .amt(5, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x0000000000000000000000000000000000000000000000000000000000000000"
                            ),
                            prices: [.usdc: 1.00],
                            fees: [.base: 0.50]
                        )
                    ),
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "3e6",
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
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "3.50e6"
                        )
                    ],
                    maxFlow: "4.50e6"
                )
            )
        )
    }

    // MARK: - Solana Transfer Tests

    @Test("Simple Solana USDC Transfer (Alice -> Bob)")
    func testSolanaUsdcTransfer() {
        runFlowTest(
            ChartTestCase(
                name: "Simple Solana USDC Transfer (Alice -> Bob)",
                givens: [
                    .tokenBalance(.alice, .amt(10, .usdc), .solana),
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        assetSymbol: "USDC",
                        amount: "5e6",
                        sender: .solana(Account.alice.solanaAddress),
                        recipient: .solana(Account.bob.solanaAddress)
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: .solana,
                                    address: .solana(Atlas.Solana.Assets.USDC.assetAddress),
                                    symbol: "USDC",
                                    wallet: .solana(Account.alice.solanaAddress)
                                ),
                                sink: .tokenBalance(
                                    network: .solana,
                                    address: .solana(Atlas.Solana.Assets.USDC.assetAddress),
                                    symbol: "USDC",
                                    wallet: .solana(Account.bob.solanaAddress)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e6"
                        )
                    ],
                    maxFlow: "10e6"
                )
            )
        )
    }

    @Test("Simple Solana Native SOL Transfer (Alice -> Bob)")
    func testSolanaSolTransfer() {
        runFlowTest(
            ChartTestCase(
                name: "Simple Solana Native SOL Transfer (Alice -> Bob)",
                givens: [
                    .tokenBalance(.alice, .amt(2, .sol), .solana),
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        assetSymbol: "SOL",
                        amount: "1e9",
                        sender: .solana(Account.alice.solanaAddress),
                        recipient: .solana(Account.bob.solanaAddress)
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: .solana,
                                    address: .solana(SolanaConstants.SYSTEM_PROGRAM),
                                    symbol: "SOL",
                                    wallet: .solana(Account.alice.solanaAddress)
                                ),
                                sink: .tokenBalance(
                                    network: .solana,
                                    address: .solana(SolanaConstants.SYSTEM_PROGRAM),
                                    symbol: "SOL",
                                    wallet: .solana(Account.bob.solanaAddress)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1e9"
                        )
                    ],
                    maxFlow: "2e9"
                )
            )
        )
    }
}
