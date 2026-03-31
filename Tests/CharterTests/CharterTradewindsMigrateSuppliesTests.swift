import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Migrate Supplies Tests

struct CharterTradewindsMigrateSuppliesTests {

    // MARK: Basic Migrate Supplies Operations

    @Test("Basic migrate supplies from single Aave market to Comet")
    func testBasicMigrateSuppliesAaveToComet() {
        runFlowTest(
            ChartTestCase(
                name: "Basic Migrate Supplies Aave->Comet",
                givens: [
                    // Alice has 10,000 USDC supplied in Aave on Base
                    .aaveSupply(.alice, .amt(10000.04, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("10000.04e6"),  // Withdraw 10,000 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply 10,000 USDC
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: EthAddress("0xb125e6687d4313864e53df431d5425969c15eb2f"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw from Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000.04e6"
                        ),
                        // Flow 2: Supply to Comet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000.02e6"  // 10000.04 - 0.02 QuotePay fee
                        ),
                    ],
                    maxFlow: "10000e6"
                )
            )
        )
    }

    @Test("Migrate supplies from multiple markets to single target")
    func testMigrateSuppliesMultipleWithdrawals() {
        runFlowTest(
            ChartTestCase(
                name: "Multiple Withdrawals to Different Target",
                givens: [
                    // Alice has USDC in Aave and Comet (but NOT in Morpho)
                    .aaveSupply(.alice, .amt(3_000.04, .usdc), .baseV3, .base),
                    .cometSupply(.alice, .amt(2_000.02, .usdc), .cusdcv3, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("3000.04e6"),
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("2000.02e6"),
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                        ],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: .MAX_UINT_256,  // Total from both withdrawals
                                assetSymbol: "USDC",
                                morphoVault: EthAddress(
                                    "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"
                                ),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw 3000 USDC from Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000.04e6"
                        ),
                        // Flow 2: Withdraw 2000 USDC from Comet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2000.02e6"
                        ),
                        // Flow 3: Supply 5000 USDC to Morpho
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000.02e6"
                        ),
                    ],
                    maxFlow: "5000e6"
                )  // No optimization: All withdrawals execute since target (Morpho) differs from sources
            )
        )
    }

    @Test("Migrate supplies optimizes by skipping withdrawal when source matches target")
    func testMigrateSuppliesOptimizesWhenSourceMatchesTarget() {
        runFlowTest(
            ChartTestCase(
                name: "Migrate with Same-Market Optimization",
                givens: [
                    // Alice has USDC in multiple markets
                    .aaveSupply(.alice, .amt(5_000.02, .usdc), .baseV3, .base),
                    .cometSupply(.alice, .amt(3_000.02, .usdc), .cusdcv3, .base),
                    .morphoVaultSupply(.alice, .amt(2_000.02, .usdc), .usdc, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("5000.02e6"),
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("3000.02e6"),
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .morpho(
                                Charter.MorphoVaultWithdrawIntent(
                                    amount: Number("2000.02e6"),
                                    assetSymbol: "USDC",
                                    morphoVault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    chainId: Number(BaseNetwork.chainId),
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                        ],
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: .MAX_UINT_256,  // Total supply amount
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw 3000 USDC from Comet to wallet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000.02e6"
                        ),
                        // Flow 2: Withdraw 2000 USDC from Morpho vault to wallet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultWithdraw(isMax: false),
                                source: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2000.02e6"
                        ),
                        // Flow 3: Supply 5000 USDC (total from withdrawals) to Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000e6"
                        ),
                    ],
                    maxFlow: "10000e6"
                )  // Optimization: When source (Aave) matches target (Aave), Tradewinds skips the withdrawal
                // and only withdraws from other markets (Comet, Morpho). The 5000 USDC already in Aave
                // stays in place, and only 5000 USDC from other markets is actively supplied.
            )
        )
    }

    @Test("Migrate supplies with max amount withdrawal")
    func testMigrateSuppliesMaxWithdrawal() {
        runFlowTest(
            ChartTestCase(
                name: "Max Amount Migrate Supplies",
                givens: [
                    // Alice has 10,000 USDC in Aave
                    .aaveSupply(.alice, .amt(10_000.02, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number.MAX_UINT_256,  // Withdraw all
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: Number.MAX_UINT_256,  // Supply all
                                assetSymbol: "USDC",
                                morphoVault: EthAddress(
                                    "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"
                                ),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw max (10000 USDC) from Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: Percentage(fromNumber: "1.00001e18"),
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000.02e6"
                        ),
                        // Flow 2: Supply all to Morpho
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000.1e6"
                        ),
                    ],
                    maxFlow: "10000.08e6"
                )
            )
        )
    }

    @Test("Migrate supplies from Morpho to Aave")
    func testMigrateSuppliesMorphoToAave() {
        runFlowTest(
            ChartTestCase(
                name: "Migrate Supplies Morpho->Aave",
                givens: [
                    // Alice has 7,500 USDC in Morpho Vault
                    .morphoVaultSupply(.alice, .amt(7_500.04, .usdc), .usdc, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .morpho(
                                Charter.MorphoVaultWithdrawIntent(
                                    amount: Number("7500.04e6"),
                                    assetSymbol: "USDC",
                                    morphoVault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    chainId: Number(BaseNetwork.chainId),
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw 7500 USDC from Morpho vault to wallet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultWithdraw(isMax: false),
                                source: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "7500.04e6"
                        ),
                        // Flow 2: Supply 7500 USDC from wallet to Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "7500.02e6"
                        ),
                    ],
                    maxFlow: "7500e6"
                )  // Limited by source balance
            )
        )
    }

    @Test("Migrate supplies from Comet to Morpho")
    func testMigrateSuppliesCometToMorpho() {
        runFlowTest(
            ChartTestCase(
                name: "Migrate Supplies Comet->Morpho",
                givens: [
                    // Alice has 5,000 USDC in Comet
                    .cometSupply(.alice, .amt(5_000.04, .usdc), .cusdcv3, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("5000.04e6"),
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "USDC",
                                morphoVault: EthAddress(
                                    "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"
                                ),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw 5000 USDC from Comet to wallet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000.04e6"
                        ),
                        // Flow 2: Supply 5000 USDC from wallet to Morpho vault
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000.02e6"
                        ),
                    ],
                    maxFlow: "5000e6"
                )  // Limited by source balance
            )
        )
    }

    // MARK: Additional Tests

    @Test("Migrate supplies from empty withdrawal intents")
    func testMigrateSuppliesEmptyWithdrawals() {
        runFlowTest(
            ChartTestCase(
                name: "Empty Withdrawals Migrate Supplies",
                givens: [
                    // Alice has USDC in wallet
                    .tokenBalance(.alice, .amt(5_000.02, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [],  // Empty withdrawals
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // Single flow: Supply from wallet to Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000.02e6"
                        )
                    ],
                    maxFlow: "5000e6"
                )
            )
        )
    }

    @Test("Migrate supplies with zero balance in withdrawal market")
    func testMigrateSuppliesZeroBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Zero Balance Migrate Supplies",
                givens: [
                    // Alice has no balance in Aave
                    .aaveSupply(
                        .alice,
                        .amt(0, .usdc),
                        .baseV3,
                        .base
                    ),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("1000e6"),  // Try to withdraw 1000 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .charterFailure(
                    .insufficientEarnMarketBalance(
                        network: Network.base,
                        market: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                        symbol: "USDC",
                        required: Amount(Number("1000e6"), decimals: 6),
                        available: Amount(Number("0"), decimals: 6)
                    )
                )
            )
        )
    }

    // MARK: Cross-Chain Migration Tests

    @Test("Migrate USDC from multiple chains to single target")
    func testMigrateSuppliesMultiChainUSDC() {
        runFlowTest(
            ChartTestCase(
                name: "Multi-Chain USDC Aggregation",
                givens: [
                    // Alice has USDC across multiple chains
                    .aaveSupply(
                        .alice,
                        .amt(5_000.04, .usdc),
                        .arbitrumV3,
                        .arbitrum
                    ),
                    .cometSupply(
                        .alice,
                        .amt(3_000.06, .usdc),
                        .cusdcv3,
                        .optimism
                    ),
                    // Quotes
                    .quote(.basic),
                    // Across quotes last
                    .acrossQuote(.amt(5, .usdc), 0.001),  // 0.1% fee for bridging
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("5000.04e6"),  // Withdraw from Arbitrum
                                    assetSymbol: "USDC",
                                    chainId: Number(ArbitrumNetwork.chainId),
                                    aavePool: ArbitrumNetwork.AaveMarkets.ArbitrumAaveMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("3000.06e6"),  // Withdraw from Optimism
                                    assetSymbol: "USDC",
                                    chainId: Number(OptimismNetwork.chainId),
                                    comet: OptimismNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                        ],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                // TODO: This is a quirky test, we should come back to it.
                                amount: .MAX_UINT_256,  // Supply total to Base (after bridge fees: 4990 + 2992) less 0.02¢ fee
                                assetSymbol: "USDC",
                                morphoVault: EthAddress(
                                    "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"
                                ),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw 5000 USDC from Aave on Arbitrum
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .arbitrum,
                                    pool: ArbitrumNetwork.AaveMarkets.ArbitrumAaveMarket.pool,
                                    baseAsset: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress.on(.arbitrum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.arbitrum)
                                ),
                                // TODO: this should be the proper bridge rate, but it's not checked by tests
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000.04e6"
                        ),
                        // Flow 2: Withdraw 3000 USDC from Comet on Optimism
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .optimism,
                                    comet: OptimismNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: OptimismNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .optimism,
                                    address: OptimismNetwork.Assets.USDC.assetAddress.on(.optimism),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.optimism)
                                ),
                                // TODO: this should be the proper bridge rate, but it's not checked by tests
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000.06e6"
                        ),
                        // Flow 3: Bridge 3000 USDC from Optimism to Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: .optimism,
                                    address: OptimismNetwork.Assets.USDC.assetAddress.on(.optimism),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.optimism)
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: Percentage(fromDouble: 0.999),  // Bridge rate (slight fee)
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "5e6")
                                ],
                                minFlow: "1e6",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000e6"  // Matches solver-selected source for exact delivery
                        ),
                        // Flow 4: Bridge 5000 USDC from Arbitrum to Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: .arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress.on(.arbitrum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.arbitrum)
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: Percentage(fromDouble: 0.999),  // Bridge rate (slight fee)
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "5e6")
                                ],
                                minFlow: "1e6",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000e6"  // Matches solver-selected source for exact delivery
                        ),
                        // Flow 5: Supply USDC to Morpho on Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "7982e6"  // Matches solver supply source
                        ),
                    ],
                    maxFlow: "7981.98e6"  // Matches solver total sink after fees
                )
            )
        )
    }

    @Test("Migrate WETH from multiple markets on different chains")
    func testMigrateSuppliesMultiChainWETH() {
        runFlowTest(
            ChartTestCase(
                name: "Multi-Chain WETH Migration",
                givens: [
                    // Alice has WETH in different markets on different chains
                    .aaveSupply(
                        .alice,
                        .amt(2.00001, .weth),
                        .arbitrumV3,
                        .arbitrum
                    ),
                    .cometSupply(
                        .alice,
                        .amt(3.000015, .weth),
                        .cwethv3,  // Use WETH market, not USDC
                        .optimism
                    ),
                    // Note: No Morpho vault on Base for this test
                    .quote(.basic),
                    // Add bridge quotes for cross-chain WETH transfers
                    .acrossQuote(.amt(0.005, .weth), 0.001),  // Bridge fee
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("2e18"),
                                    assetSymbol: "WETH",
                                    chainId: Number(ArbitrumNetwork.chainId),
                                    aavePool: ArbitrumNetwork.AaveMarkets.ArbitrumAaveMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("3e18"),
                                    assetSymbol: "WETH",
                                    chainId: Number(OptimismNetwork.chainId),
                                    comet: OptimismNetwork.Comets.cWETHv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            // No Morpho withdrawal - Base doesn't have Morpho vaults configured
                        ],
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply total 4.985 WETH to Base (1.993 + 2.992)
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw 2 WETH from Aave on Arbitrum
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .arbitrum,
                                    pool: ArbitrumNetwork.AaveMarkets.ArbitrumAaveMarket.pool,
                                    baseAsset: ArbitrumNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress.on(.arbitrum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.arbitrum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2e18"
                        ),
                        // Flow 2: Withdraw 3 WETH from Comet on Optimism
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .optimism,
                                    comet: OptimismNetwork.Comets.cWETHv3.cometAddress,
                                    baseAsset: OptimismNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .optimism,
                                    address: OptimismNetwork.Assets.WETH.assetAddress.on(.optimism),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.optimism)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3e18"
                        ),
                        // Flow 3: Bridge 2 WETH from Arbitrum to Base (as ETH)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: .arbitrum,
                                    address: ArbitrumNetwork.Assets.WETH.assetAddress.on(.arbitrum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.arbitrum)
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.ETH.assetAddress.on(.base),
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: Percentage(fromDouble: 0.999),  // Bridge rate (slight fee)
                                fees: [
                                    Tradewinds.Fee(
                                        type: .bridgeAcross,
                                        isInFee: false,
                                        amount: "0.005e18"
                                    )
                                ],
                                minFlow: "1e16",  // 0.01 WETH min
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1.99999e18"  // Matches solver-selected source
                        ),
                        // Flow 4: Bridge 3 WETH from Optimism to Base (as ETH)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: .optimism,
                                    address: OptimismNetwork.Assets.WETH.assetAddress.on(.optimism),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.optimism)
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.ETH.assetAddress.on(.base),
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: Percentage(fromDouble: 0.999),  // Bridge rate (slight fee)
                                fees: [
                                    Tradewinds.Fee(
                                        type: .bridgeAcross,
                                        isInFee: false,
                                        amount: "0.005e18"
                                    )
                                ],
                                minFlow: "1e16",  // 0.01 WETH min
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2.999985e18"  // Matches solver-selected source
                        ),
                        // Flow 5: Wrap ETH to WETH on Base (combined)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.ETH.assetAddress.on(.base),
                                    symbol: "ETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: Number("4.984975025e18")  // Matches solver wrap amount
                        ),
                        // Flow 6: Supply all WETH to Aave on Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: Number("4.984975025e18")
                        ),
                    ],
                    maxFlow: Number("4.984970025e18")  // Matches solver total sink after fees
                )  // Cross-chain WETH aggregation
            )
        )
    }

    @Test("Migrate supplies respects exact withdrawal amounts despite existing token balance")
    func testMigrateSuppliesRespectsExactWithdrawalAmounts() {
        runFlowTest(
            ChartTestCase(
                name: "Exact Withdrawal Amounts with Token Balance",
                givens: [
                    // Alice has both token balance AND supplied amounts.
                    // Add +$0.02 (Base QuotePay fee) so the supply can deliver exactly 7,000 USDC.
                    .tokenBalance(.alice, .amt(2_000.04, .usdc), .base),  // 2000.04 USDC covers multiple Base fees
                    .aaveSupply(.alice, .amt(10_000, .usdc), .baseV3, .base),  // 10000 USDC supplied in Aave
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("5000e6"),  // Withdraw exactly 5000 USDC from Aave
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply 7000 USDC total (5000 from withdrawal + 2000 existing)
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: EthAddress("0xb125e6687d4313864e53df431d5425969c15eb2f"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Must withdraw exactly 5000 USDC from Aave (not less due to existing balance)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                // Exact withdraw amount at source (net logic applies fee elsewhere)
                                minFlow: "5000e6",
                                maxFlow: "5000e6"
                            ),
                            amount: "5000e6"
                        ),
                        // Flow 2: Supply 7000 USDC to Comet (using 5000 from withdrawal + 2000 existing)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "7000.02e6"  // Source includes Base QuotePay fee for supply
                        ),
                    ],
                    maxFlow: "7000e6"
                )
            )
        )
    }

    @Test("Migrate supplies withdraws exact specified amounts from each market")
    func testMigrateSuppliesWithdrawsExactAmountsPerMarket() {
        runFlowTest(
            ChartTestCase(
                name: "Exact Withdrawal Amounts Per Market",
                givens: [
                    // Alice has substantial token balance and supplied amounts
                    .tokenBalance(.alice, .amt(3_000.06, .usdc), .base),  // 3000 USDC token balance + QuotePay
                    .aaveSupply(.alice, .amt(8_000, .usdc), .baseV3, .base),  // 8000 USDC in Aave
                    .cometSupply(.alice, .amt(6_000, .usdc), .cusdcv3, .base),  // 6000 USDC in Comet
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            // Withdraw specific amounts less than total available
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("4000e6"),  // Withdraw 4000 of 8000 USDC from Aave
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("2000e6"),  // Withdraw 2000 of 6000 USDC from Comet
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                        ],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply 9000 total (4000+2000 from withdrawals + 3000 existing)
                                assetSymbol: "USDC",
                                morphoVault: EthAddress(
                                    "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"
                                ),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        ),
                        migrateOnlySupplyBalances: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // Must withdraw exactly the specified amounts from each market
                        // Flow 1: Withdraw exactly 4000 from Aave (not less)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "4000e6",  // Force exact withdrawal
                                maxFlow: "4000e6"
                            ),
                            amount: "4000e6"
                        ),
                        // Flow 2: Withdraw exactly 2000 from Comet (not less)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "2000e6",  // Force exact withdrawal
                                maxFlow: "2000e6"
                            ),
                            amount: "2000e6"
                        ),
                        // Flow 3: Supply 9000 total to Morpho
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "9000.02e6"  // Total: 4000 + 2000 + 3000 existing + QuotePay
                        ),
                    ],
                    maxFlow: "9000e6"
                )
            )
        )
    }

    // MARK: Error Handling Tests

    @Test("Migrate supplies fails with insufficient Aave balance")
    func testMigrateSuppliesInsufficientAaveBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Insufficient Aave balance for migration",
                givens: [
                    // Alice has only 5,000 USDC in Aave
                    .aaveSupply(.alice, .amt(5_000, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("10000e6"),  // Try to withdraw 10,000 USDC (more than available)
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: EthAddress("0xb125e6687d4313864e53df431d5425969c15eb2f"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .charterFailure(
                    .insufficientEarnMarketBalance(
                        network: Network.base,
                        market: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                        symbol: "USDC",
                        required: Amount(Number("10000e6"), decimals: 6),
                        available: Amount(Number("5000e6"), decimals: 6)
                    )
                )
            )
        )
    }

    @Test("Migrate supplies succeeds with exact Morpho balance")
    func testMigrateSuppliesExactMorphoBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Migrate exact Morpho balance",
                givens: [
                    // Alice has exactly 7,500 USDC in Morpho and a small Base USDC balance to fund QuotePay.
                    .morphoVaultSupply(.alice, .amt(7_500, .usdc), .usdc, .base),
                    .tokenBalance(.alice, .amt(0.04, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .morpho(
                                Charter.MorphoVaultWithdrawIntent(
                                    amount: Number("7500e6"),  // Withdraw exactly 7,500 USDC (all available)
                                    assetSymbol: "USDC",
                                    morphoVault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    chainId: Number(BaseNetwork.chainId),
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw from Morpho
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultWithdraw(isMax: false),
                                source: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "7500e6"
                        ),
                        // Flow 2: Supply to Aave
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "7499.98e6"  // 7500 withdrawn minus 0.02 supply fee
                        ),
                    ],
                    maxFlow: "7499.96e6"  // 7500 withdrawn minus 0.04 total fees
                )
            )
        )
    }

    @Test("Migrate supplies fails with insufficient Comet balance")
    func testMigrateSuppliesInsufficientCometBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Insufficient Comet balance for migration",
                givens: [
                    // Alice has only 2,000 USDC in Comet
                    .cometSupply(.alice, .amt(2_000, .usdc), .cusdcv3, .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("5000e6"),  // Try to withdraw 5,000 USDC (more than available)
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: .MAX_UINT_256,
                                assetSymbol: "USDC",
                                morphoVault: EthAddress(
                                    "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"
                                ),
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .charterFailure(
                    .insufficientEarnMarketBalance(
                        network: Network.base,
                        market: BaseNetwork.Comets.cUSDCv3.cometAddress,
                        symbol: "USDC",
                        required: Amount(Number("5000e6"), decimals: 6),
                        available: Amount(Number("2000e6"), decimals: 6)
                    )
                )
            )
        )
    }

    @Test("Migrate supplies prefers earn balance over token balance when both exist")
    func testMigrateSuppliesPrefersEarnBalanceOverTokenBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Prefer Earn Balance Over Token Balance",
                givens: [
                    .tokenBalance(.alice, .amt(2_000, .usdc), .base),
                    // Alice has 2000 USDC in each lending market
                    .aaveSupply(.alice, .amt(2_000, .usdc), .baseV3, .base),
                    .cometSupply(.alice, .amt(2_000, .usdc), .cusdcv3, .base),
                    .morphoVaultSupply(.alice, .amt(2_000, .usdc), .usdc, .base),
                    // Alice also has 2000 USDC as token balance (should NOT be used)
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            // Withdraw 2000 from each lending market
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("2000e6"),  // Withdraw 2000 USDC from Aave
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("2000e6"),  // Withdraw 2000 USDC from Comet
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                            .morpho(
                                Charter.MorphoVaultWithdrawIntent(
                                    amount: Number("2000e6"),  // Withdraw 2000 USDC from Morpho
                                    assetSymbol: "USDC",
                                    morphoVault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    chainId: Number(BaseNetwork.chainId),
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            ),
                        ],
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply 6000 USDC total (2000×3) to Aave
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw exactly 2000 from Comet (not using token balance)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "2000e6",  // Force exact withdrawal from Comet
                                maxFlow: "2000e6"
                            ),
                            amount: "2000e6"
                        ),
                        // Flow 2: Withdraw exactly 2000 from Morpho (not using token balance)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultWithdraw(isMax: false),
                                source: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "2000e6",  // Force exact withdrawal from Morpho
                                maxFlow: "2000e6"
                            ),
                            amount: "2000e6"
                        ),
                        // Flow 3: Supply 6000 to Aave (4000 from withdrawals + 2000 already in Aave)
                        // Note: Since we're supplying to Aave and already have 2000 in Aave,
                        // only 4000 needs to be actively supplied (2000 from Comet + 2000 from Morpho)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3999.96e6"  // 4000 withdrawn minus 0.04 fees (2000 stays in Aave)
                        ),
                    ],
                    maxFlow: "5999.94e6"  // 6000 from withdrawals minus 0.06 fees (excludes 2000 token balance)
                )
                // This test verifies that:
                // 1. Each lending market withdrawal is exactly 2000 USDC (forced by minFlow=maxFlow)
                // 2. The 2000 USDC token balance is never used (remains untouched)
                // 3. When supplying to Aave, the optimization keeps existing Aave balance in place
            )
        )
    }

    @Test("Migrate supplies correctly withdraws from earn market despite equal token balance")
    func testMigrateSuppliesCorrectlyWithdrawsFromEarnMarketDespiteEqualTokenBalance() {
        // BUG IN COST FUNCTION:
        // The MigrateSupplies cost function has a fundamental flaw. It applies penalties
        // to individual ROUTES based on route.source, but the graph structure means all
        // supply operations must go through tokenBalance as an intermediate node.
        //
        // Graph structure for supplies:
        // Path A (WRONG - use existing balance):
        //   tokenBalance -> targetMarket (source=tokenBalance, +10 penalty)
        //
        // Path B (CORRECT - withdraw from earn market):
        //   earnMarket -> tokenBalance (source=earnMarket, no penalty)
        //   tokenBalance -> targetMarket (source=tokenBalance, +10 penalty)
        //
        // Both paths include the tokenBalance->targetMarket route with +10 penalty!
        // Total cost: Path A = 10, Path B = 0 + 10 = 10 (SAME!)
        //
        // The cost function cannot distinguish between using existing token balance
        // vs withdrawing from earn markets then using the resulting balance.
        //
        // POTENTIAL FIXES:
        // 1. Track "fresh" vs "existing" token balances with different node types
        // 2. Apply penalties at the path level instead of route level
        // 3. Add context to routes about their origin in the optimization
        //
        // This test currently passes, likely due to tie-breaking or ordering heuristics,
        // but the cost function design is flawed.
        runFlowTest(
            ChartTestCase(
                name: "Correctly Withdraws from Earn Market Despite Token Balance",
                givens: [
                    // Alice has 3000 USDC in Aave
                    .aaveSupply(.alice, .amt(3_000, .usdc), .baseV3, .base),
                    // Alice ALSO has 3000 USDC as token balance
                    .tokenBalance(.alice, .amt(3_000, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("3000e6"),  // Request to withdraw 3000
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply 3000 USDC to Comet
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Flow 1: Withdraw from Aave (correctly uses earn market)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000e6"
                        ),
                        // Flow 2: Supply to Comet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2999.98e6"
                        ),
                    ],
                    maxFlow: "2999.96e6"  // With migrateOnlySupplyBalances=true: only 3000 Aave - 0.04e6 total QuotePay fees
                )
                // This test shows that the system correctly prioritizes withdrawing from
                // specified earn markets even when token balance is available
            )
        )
    }

    @Test(
        "Migrate supplies correctly withdraws from earn market with withdrawal intent"
    )
    func testMigrateSuppliesCorrectlyWithdrawsFromEarnMarket() {
        // This test verifies that when a withdrawal intent is specified,
        // the system correctly withdraws from the earn market rather than
        // using token balance.
        //
        // WHAT WE SPECIFY:
        // - Withdraw 2000 USDC from Aave (explicit intent)
        // - Supply 2000 USDC to Comet
        //
        // EXPECTED (if no bug): Withdraw from Aave -> Supply to Comet
        //
        // However, the cost function bug means both paths have equal cost:
        // - Path A: tokenBalance -> Comet (source=tokenBalance, +10 penalty)
        // - Path B: Aave -> tokenBalance (source=Aave, 0 penalty for specified market)
        //           tokenBalance -> Comet (source=tokenBalance, +10 penalty)
        // Total: Path A = 10, Path B = 0 + 10 = 10 (SAME COST!)
        //
        // If the bug manifests, the optimizer might choose Path A despite
        // our explicit withdrawal intent, demonstrating the flaw.
        runFlowTest(
            ChartTestCase(
                name: "Correctly Withdraws From Earn Market Instead of Token Balance",
                givens: [
                    // Alice has 2000 USDC in Aave
                    .aaveSupply(.alice, .amt(2_000, .usdc), .baseV3, .base),
                    // Alice ALSO has 2000 USDC as token balance
                    .tokenBalance(.alice, .amt(2_000, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("2000e6"),  // SPECIFY withdrawal
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],  // WITH withdrawal intent specified!
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply 2000 USDC to Comet
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // EXPECTED (correct behavior): Should withdraw from Aave first
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2000e6"
                        ),
                        // Then supply to Comet
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1999.98e6"  // 2000 withdrawn minus 0.02 supply fee
                        ),
                        // The optimizer correctly withdraws from Aave first as specified,
                        // then supplies to Comet
                    ],
                    maxFlow: "1999.96e6"  // 2000 withdrawn minus 0.04 fees (excludes 2000 token balance)
                )
            )
        )
    }

    @Test("Migrate supplies bug with partial withdrawal: uses token balance for remainder")
    func testMigrateSuppliesBugWithPartialWithdrawal() {
        // This test tries to trigger the bug with partial withdrawals.
        // We request to withdraw LESS than needed and expect the system to
        // use token balance for the remainder, but it might not work as expected.
        runFlowTest(
            ChartTestCase(
                name: "Bug Demo: Partial Withdrawal Plus Token Balance",
                givens: [
                    // Alice has 3000 USDC in Aave
                    .aaveSupply(.alice, .amt(3_000, .usdc), .baseV3, .base),
                    // Alice has 3000 USDC as token balance + QuotePay fee
                    .tokenBalance(.alice, .amt(3_000.04, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number("1000e6"),  // Withdraw only 1000 (not enough!)
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    aavePool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: .MAX_UINT_256,  // Supply 4000 USDC (needs 1000 from Aave + 3000 from somewhere)
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE")
                            )
                        ),
                        migrateOnlySupplyBalances: false
                    )
                ),
                expect: .exactFlows(
                    [
                        // We expect it to withdraw 1000 from Aave as specified
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1000e6"
                        ),
                        // Then supply 4000 to Comet (using 1000 from withdrawal + 3000 existing)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "4000.02e6"
                        ),
                    ],
                    maxFlow: "4000e6"  // Total: 1000 from Aave (exact withdrawal) + 3000 token
                )
            )
        )
    }

    @Test("Withdrawal amount respected - withdraws exact specified amount")
    func testWithdrawalAmountRespected() {
        // This test verifies that Tradewinds respects the exact withdrawal amount specified.
        //
        // Scenario: User has 100 USDC in Comet, withdrawal intent says 80 USDC,
        // and only needs to supply 60 USDC to Morpho. The system withdraws the full 80 USDC
        // as specified in the intent, not just what's needed for the supply.
        runFlowTest(
            ChartTestCase(
                name: "Withdrawal amount respected - withdraws exact specified amount",
                givens: [
                    // Alice has 100 USDC in Comet
                    .cometSupply(.alice, .amt(100, .usdc), .cusdcv3, .base),
                    // Alice also has 50 USDC token balance
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .migrateSupplies(
                    Charter.MigrateSuppliesIntent(
                        withdrawIntents: [
                            .comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number("80e6"),  // INTENT: Withdraw exactly 80 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number(BaseNetwork.chainId),
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    withdrawer: EthAddress(
                                        "0x00000000000000000000000000000000000A11CE"
                                    )
                                )
                            )
                        ],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: .MAX_UINT_256,  // Only supplying 60 USDC
                                assetSymbol: "USDC",
                                morphoVault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                                chainId: Number(BaseNetwork.chainId)
                            )
                        ),
                        migrateOnlySupplyBalances: true
                    )
                ),
                expect: .exactFlows(
                    [
                        // Withdraws the exact amount specified in the withdrawal intent
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometWithdraw(isMax: false),
                                source: .cometSupplyBalance(
                                    network: .base,
                                    comet: BaseNetwork.Comets.cUSDCv3.cometAddress,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "80e6"  // Withdraws exact amount specified in intent
                        ),
                        // Supply the requested 80 USDC to Morpho
                        // Note: Uses 80 USDC from the total 130 USDC available (80 withdrawn + 50 existing)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: false),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: .base,
                                    vault: BaseNetwork.MorphoVaults.mwUSDC.vault,
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "79.98e6"  // Supply after QuotePay fee deducted from withdrawn amount
                        ),
                    ],
                    maxFlow: "79.96e6"  // Max flow: 80e6 withdrawn - 0.04e6 QuotePay fee (migrateOnlySupplyBalances excludes token balance)
                )
            )
        )
    }
}
