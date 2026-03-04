import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tradewinds unit tests for Legend bridge operations
struct CharterTradewindsBridgeTests {
    @Test("Bridge Transfer with CCTP v2 Only")
    func testBridgeTransferWithCCTPv2Only() {
        // Test USDC transfer using CCTP v2 bridge
        runFlowTest(
            ChartTestCase(
                name: "Bridge Transfer with CCTP v2 Only",
                givens: [
                    .tokenBalance(.alice, .amt(20, .usdc), .arbitrum),
                    .cctpV2Quote(.amt(0.5, .usdc), 0.005),  // 0.5 USDC fixed cost, 0.5% fee
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "10e6",  // Want to receive 10 USDC on Base
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        // Bridge route: Arbitrum USDC -> Base USDC (collapsed CCTP v2)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .cctpV2, isCappedMax: false),
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
                                rate: Percentage(fromNumber: Number("995000000000000000")),  // 0.995
                                fees: [
                                    Tradewinds.Fee(
                                        type: LegendFeeType.bridgeCCTPv2,
                                        isInFee: false,
                                        amount: "500000"
                                    )
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "10.552764e6"  // (10e6 + 0.5e6) / 0.995 = 10.552764e6 (rounded)
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
                                maxFlow: "10000e6"
                            ),
                            amount: "10e6"
                        ),
                    ],
                    maxFlow: "19400000"  // (20e6 * 0.995) - 0.5e6 = 19.4e6
                )
            )
        )
    }

    @Test("Bridge Transfer with Both Across and CCTP v2 - Cheaper CCTP v2 Selected")
    func testBridgeTransferWithBothBridgesCheaperCCTPv2() {
        // Test that Tradewinds selects the cheaper bridge option (CCTP v2 in this case)
        runFlowTest(
            ChartTestCase(
                name: "Bridge Transfer with Both Bridges - CCTP v2 Cheaper",
                givens: [
                    .tokenBalance(.alice, .amt(20, .usdc), .arbitrum),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1 USDC fixed cost, 1% fee
                    .cctpV2Quote(.amt(0.3, .usdc), 0.003),  // 0.3 USDC fixed cost, 0.3% fee (cheaper)
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "15e6",  // Want to receive 15 USDC on Base
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        // Bridge route: Arbitrum USDC -> Base USDC (collapsed CCTP v2)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .cctpV2, isCappedMax: false),  // Should select CCTP v2 as it's cheaper
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
                                rate: Percentage(fromNumber: Number("997000000000000000")),  // 0.997
                                fees: [
                                    Tradewinds.Fee(
                                        type: LegendFeeType.bridgeCCTPv2,
                                        isInFee: false,
                                        amount: "300000"
                                    )
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "15346039"  // (15e6 + 0.3e6) / 0.997 = 15.346039e6 (rounded)
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
                                maxFlow: "10000e6"
                            ),
                            amount: "15e6"
                        ),
                    ],
                    maxFlow: "19640000"  // (20e6 * 0.997) - 0.3e6 = 19.64e6
                )
            )
        )
    }

    @Test("Bridge Transfer with Both Bridges - Cheaper Across Selected")
    func testBridgeTransferWithBothBridgesCheaperAcross() {
        // Test that Tradewinds selects the cheaper bridge option (Across in this case)
        runFlowTest(
            ChartTestCase(
                name: "Bridge Transfer with Both Bridges - Across Cheaper",
                givens: [
                    .tokenBalance(.alice, .amt(20, .usdc), .arbitrum),
                    .acrossQuote(.amt(0.2, .usdc), 0.002),  // 0.2 USDC fixed cost, 0.2% fee (cheaper)
                    .cctpV2Quote(.amt(0.8, .usdc), 0.008),  // 0.8 USDC fixed cost, 0.8% fee
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "15e6",  // Want to receive 15 USDC on Base
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),  // Should select Across as it's cheaper
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
                                rate: Percentage(fromNumber: Number("998000000000000000")),  // 0.998
                                fees: [
                                    Tradewinds.Fee(
                                        type: LegendFeeType.bridgeAcross,
                                        isInFee: false,
                                        amount: "200000"
                                    )
                                ],
                                minFlow: "0",
                                maxFlow: "10000e6"
                            ),
                            amount: "15230461"  // (15e6 + 0.2e6) / 0.998 = 15.230461e6 (rounded)
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
                                maxFlow: "10000e6"
                            ),
                            amount: "15e6"
                        ),
                    ],
                    maxFlow: "19760000"  // (20e6 * 0.998) - 0.2e6 = 19.76e6
                )
            )
        )
    }
}
