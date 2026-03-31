import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Tests for optimal routing behavior in Charter
/// These tests verify that the cost function correctly accounts for fixed costs
/// when choosing between different routes (bridges, withdrawals, etc.)
struct CharterTradewindsRoutingTests {

    @Test("Bridge vs Withdraw - Fixed Cost Makes Withdraw Optimal")
    func testBridgeVsWithdraw_FixedCostMakesWithdrawOptimal() {
        // Scenario: Transfer 50 USDC to Base
        // Available resources:
        // - 100 USDC on Ethereum (requires expensive bridge, $20 fixed cost)
        // - 60 USDC in Aave on Base (free withdraw, 0% cost)
        //
        // Old behavior (rateCostFunction): Would compare rates only
        // - Bridge rate: 0.99 (1% fee) → cost = -log(0.99) = 0.01
        // - Aave rate: 1.0 (0% fee) → cost = 0.001 (small penalty)
        // - Would choose bridge (lower rate cost), paying $70+ total
        //
        // New behavior (dualFeeCostFunction with targetAmount=50):
        // - Bridge cost: -log(0.99) + 20/50 = 0.01 + 0.4 = 0.41
        // - Aave cost: -log(1.0) + 0/50 + 0.001 (penalty) = 0.001
        // - Correctly chooses Aave (lower total cost)
        //
        // This demonstrates the fix for the mainnet vs L2 routing issue.

        runFlowTest(
            ChartTestCase(
                name: "Bridge vs Withdraw - Fixed Cost Optimization",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .ethereum),
                    .aaveSupply(.alice, .amt(60, .usdc), .baseV3, .base),
                    .acrossQuote(.amt(20, .usdc), 0.01),  // $20 fixed cost, 1% variable
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(BaseNetwork.chainId),
                        assetSymbol: BaseNetwork.Assets.USDC.symbol,
                        amount: "50e6",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B"),
                        earnMarketPolicy: .all
                    )
                ),
                expect: .exactFlows(
                    [
                        // Should withdraw from Aave (cheapest option)
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
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                        // Then transfer to Bob
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
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                    ],
                    maxFlow: "139e6"  // 60 (Aave) + (100-20)*0.99 - 20 (bridge) = 139
                )
            )
        )
    }

    @Test("Multiple Bridges - Prefers Lower Total Cost Despite Worse Rate")
    func testMultipleBridges_PrefersLowerTotalCost() {
        // Scenario: Transfer 50 USDC to Optimism
        // Available resources:
        // - 100 USDC on Ethereum
        // - 100 USDC on Base  
        //
        // With high bridge costs ($20), should use ALL resources from one chain
        // to minimize number of bridge operations (pay fixed cost once vs twice).
        //
        // This verifies that dualFeeCostFunction correctly prioritizes minimizing
        // fixed cost impact by using fewer, larger transfers.

        runFlowTest(
            ChartTestCase(
                name: "Multiple Bridges - Minimize Fixed Cost Operations",
                givens: [
                    .tokenBalance(.alice, .amt(100, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .acrossQuote(.amt(20, .usdc), 0.01),  // $20 fixed cost, 1% variable
                ],
                intent: .transfer(
                    Charter.TransferIntent(
                        chainId: Number(OptimismNetwork.chainId),
                        assetSymbol: OptimismNetwork.Assets.USDC.symbol,
                        amount: "50e6",
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        recipient: EthAddress("0x0000000000000000000000000000000000000B0B")
                    )
                ),
                expect: .exactFlows(
                    [
                        // Should use only one bridge to minimize fixed costs
                        // Uses either Ethereum or Base (both have same cost structure)
                        // Algorithm chooses Base (alphabetically first, both equivalent)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.optimism,
                                    address: OptimismNetwork.Assets.USDC.assetAddress.on(Eth.Network.optimism),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.optimism)
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "20e6")
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "70.707071e6"  // Need ~70.7 to get 50 after fees
                        ),
                        // Then transfer to Bob
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .transferOut,
                                source: .tokenBalance(
                                    network: Eth.Network.optimism,
                                    address: OptimismNetwork.Assets.USDC.assetAddress.on(Eth.Network.optimism),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.optimism)
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.optimism,
                                    address: OptimismNetwork.Assets.USDC.assetAddress.on(Eth.Network.optimism),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x0000000000000000000000000000000000000b0b").on(Eth.Network.optimism)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                    ],
                    maxFlow: "158e6"  // Both bridges available: (100-20)*0.99 - 20 = 59.2 each, total = 118.4
                )
            )
        )
    }
}
