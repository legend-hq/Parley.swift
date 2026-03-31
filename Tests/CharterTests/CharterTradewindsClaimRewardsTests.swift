import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

/// Comprehensive Tradewinds unit tests for unified Claim Rewards flows
/// Covers all scenarios from both legacy Comet and Morpho test files
struct CharterTradewindsClaimRewardsTests {

    // MARK: - Single Protocol Single Asset Tests

    @Test("Claim Rewards - USDC from Comet only on Base")
    func testClaimRewardsUSDCFromCometBase() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - USDC from Comet only on Base",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("100e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "100e6"
                        ),
                        // USDC TokenBalance -> RewardSettlement virtual route
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Claim Rewards - WETH from Comet only on Base")
    func testClaimRewardsWETHFromCometBase() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - WETH from Comet only on Base",
                givens: [
                    .cometReward(.alice, .amt(2, .weth), .cwethv3, .wethReward, .base),
                    .prices([.weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.WETH.assetAddress],
                                    comets: [Comet.cwethv3.address(network: .base)],
                                    amounts: [Number("2e18")],
                                    symbols: ["WETH"],
                                    prices: [Number("4000e8")],
                                    tokens: [BaseNetwork.Assets.WETH.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cwethv3.address(network: .base),
                                    token: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2e18"
                        ),
                        // WETH TokenBalance -> RewardSettlement virtual route
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2e18"
                        ),
                    ],
                    maxFlow: "2e18"
                )
            )
        )
    }

    @Test("Claim Rewards - WETH from Morpho only on Ethereum")
    func testClaimRewardsWETHFromMorphoEthereum() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - WETH from Morpho only on Ethereum",
                givens: [
                    .morphoReward(.alice, .amt(10, .weth), .distributor, .validProof1, .ethereum),
                    .prices([.weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [
                                        EthereumNetwork.MorphoRewardDistributors.distributor_0
                                            .distributor
                                    ],
                                    rewards: [EthereumNetwork.Assets.WETH.assetAddress],
                                    claimables: ["10e18"],
                                    claimableNows: ["10e18"],
                                    proofs: [MorphoClaimProof.validProof1.data],
                                    symbols: ["WETH"],
                                    prices: ["4000e8"]
                                ),
                                source: .morphoReward(
                                    network: Eth.Network.ethereum,
                                    distributor: EthereumNetwork.MorphoRewardDistributors
                                        .distributor_0.distributor,
                                    token: EthereumNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10e18"
                        ),
                        // WETH TokenBalance -> RewardSettlement virtual route
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10e18"
                        ),
                    ],
                    maxFlow: "10e18"
                )
            )
        )
    }

    @Test("Claim Rewards - WETH from Merkl distributor")
    func testClaimRewardsWETHFromMerklDistributor() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - WETH from Merkl distributor",
                givens: [
                    .morphoReward(
                        .alice,
                        .amt(15, .weth),
                        .merklDistributor,
                        .validProof3,
                        .ethereum
                    ),
                    .prices([.weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "WETH"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [MorphoDistributor.MERKL_DISTRIBUTOR_ADDRESS],
                                    rewards: [EthereumNetwork.Assets.WETH.assetAddress],
                                    claimables: ["15e18"],
                                    claimableNows: ["15e18"],
                                    proofs: [MorphoClaimProof.validProof3.data],
                                    symbols: ["WETH"],
                                    prices: ["4000e8"]
                                ),
                                source: .morphoReward(
                                    network: Eth.Network.ethereum,
                                    distributor: MorphoDistributor.MERKL_DISTRIBUTOR_ADDRESS,
                                    token: EthereumNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "15e18"
                        ),
                        // WETH TokenBalance -> RewardSettlement virtual route
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "15e18"
                        ),
                    ],
                    maxFlow: "15e18"
                )
            )
        )
    }

    // MARK: - Cross-Protocol Same Asset Tests

    @Test("Claim Rewards - USDC from both Comet and Morpho")
    func testClaimRewardsUSDCFromBothProtocols() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - USDC from both Comet and Morpho",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .morphoReward(.alice, .amt(50, .usdc), .distributor, .validProof2, .base),
                    .prices([.usdc: 1.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"
                    )
                ),
                expect: .exactFlows(
                    [
                        // Morpho USDC reward route (comes first in actual output)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [
                                        BaseNetwork.MorphoRewardDistributors.distributor_0
                                            .distributor
                                    ],
                                    rewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    claimables: ["50e6"],
                                    claimableNows: ["50e6"],
                                    proofs: [MorphoClaimProof.validProof2.data],
                                    symbols: ["USDC"],
                                    prices: ["1e8"]
                                ),
                                source: .morphoReward(
                                    network: Eth.Network.base,
                                    distributor: BaseNetwork.MorphoRewardDistributors.distributor_0
                                        .distributor,
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                        // Comet USDC reward route (comes second in actual output)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("100e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "100e6"
                        ),
                        // USDC TokenBalance -> RewardSettlement virtual route (handles both sources)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "150e6"  // Combined amount from both protocols
                        ),
                    ],
                    maxFlow: "150e6"
                )
            )
        )
    }

    // MARK: - Cross-Network Same Asset Tests

    @Test("Claim Rewards - USDC from multiple networks")
    func testClaimRewardsUSDCFromMultipleNetworks() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - USDC from multiple networks",
                givens: [
                    .cometReward(.alice, .amt(70, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(40, .usdc), .cusdcv3, .usdcReward, .ethereum),
                    .prices([.usdc: 1.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"
                    )
                ),
                // Equal-cost 1:1 routes allow both orderings; order doesn't affect delivered amounts.
                // Non-determinism stems from tie-breaking among equal-cost executable flows.
                expect: .unorderedFlows(
                    [
                        // Ethereum network comes first with deterministic sorting
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [
                                        Atlas.getAssetBySymbol(network: .ethereum, symbol: "USDC")!
                                            .assetAddress
                                    ],
                                    comets: [Comet.cusdcv3.address(network: .ethereum)],
                                    amounts: [Number("40e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [
                                        Atlas.getAssetBySymbol(network: .ethereum, symbol: "USDC")!
                                            .assetAddress
                                    ]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.ethereum,
                                    comet: Comet.cusdcv3.address(network: .ethereum),
                                    token: Atlas.getAssetBySymbol(
                                        network: .ethereum,
                                        symbol: "USDC"
                                    )!
                                    .assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: Atlas.getAssetBySymbol(
                                        network: .ethereum,
                                        symbol: "USDC"
                                    )!
                                    .assetAddress.on(Eth.Network.ethereum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "40e6"
                        ),
                        // Base network comes second with deterministic sorting
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("70e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "70e6"
                        ),
                        // Ethereum USDC TokenBalance -> RewardSettlement virtual route
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: Atlas.getAssetBySymbol(
                                        network: .ethereum,
                                        symbol: "USDC"
                                    )!
                                    .assetAddress.on(Eth.Network.ethereum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "40e6"
                        ),
                        // Base USDC TokenBalance -> RewardSettlement virtual route
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "70e6"
                        ),
                    ],
                    maxFlow: "110e6"
                )
            )
        )
    }

    // MARK: - Mixed Distributor Tests

    @Test("Claim Rewards - WETH from mixed reward sources types")
    func testClaimRewardsWETHFromMixedRewardSources() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - WETH from mixed distributor types",
                givens: [
                    .morphoReward(.alice, .amt(3, .weth), .distributor, .validProof1, .ethereum),
                    .morphoReward(
                        .alice,
                        .amt(7, .weth),
                        .merklDistributor,
                        .validProof3,
                        .ethereum
                    ),
                    .cometReward(.alice, .amt(2, .weth), .cwethv3, .wethReward, .base),
                    .prices([.weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "WETH"
                    )
                ),
                expect: .unorderedFlows(
                    [
                        // Morpho distributor WETH claim on Ethereum first (non-Merkl comes first)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [
                                        EthereumNetwork.MorphoRewardDistributors.distributor_0
                                            .distributor
                                    ],
                                    rewards: [EthereumNetwork.Assets.WETH.assetAddress],
                                    claimables: ["3e18"],
                                    claimableNows: ["3e18"],
                                    proofs: [MorphoClaimProof.validProof1.data],
                                    symbols: ["WETH"],
                                    prices: ["4000e8"]
                                ),
                                source: .morphoReward(
                                    network: Eth.Network.ethereum,
                                    distributor: EthereumNetwork.MorphoRewardDistributors
                                        .distributor_0.distributor,
                                    token: EthereumNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3e18"
                        ),
                        // Merkl distributor WETH claim on Ethereum second
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [MorphoDistributor.MERKL_DISTRIBUTOR_ADDRESS],
                                    rewards: [EthereumNetwork.Assets.WETH.assetAddress],
                                    claimables: ["7e18"],
                                    claimableNows: ["7e18"],
                                    proofs: [MorphoClaimProof.validProof3.data],
                                    symbols: ["WETH"],
                                    prices: ["4000e8"]
                                ),
                                source: .morphoReward(
                                    network: Eth.Network.ethereum,
                                    distributor: MorphoDistributor.MERKL_DISTRIBUTOR_ADDRESS,
                                    token: EthereumNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "7e18"
                        ),
                        // Comet WETH claim on Base third
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.WETH.assetAddress],
                                    comets: [Comet.cwethv3.address(network: .base)],
                                    amounts: [Number("2e18")],
                                    symbols: ["WETH"],
                                    prices: [Number("4000e8")],
                                    tokens: [BaseNetwork.Assets.WETH.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cwethv3.address(network: .base),
                                    token: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2e18"
                        ),
                        // Base WETH TokenBalance -> RewardSettlement virtual route (2e18 from Comet)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(Eth.Network.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2e18"
                        ),
                        // Ethereum WETH TokenBalance -> RewardSettlement virtual route (10e18 total from both Morpho distributors)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10e18"
                        ),
                    ],
                    maxFlow: "12e18"
                )
            )
        )
    }

    // MARK: - Edge Cases

    @Test("Claim Rewards - No rewards for specified asset")
    func testClaimRewardsNoRewardsForAsset() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - No rewards for specified asset",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "WETH"  // Asking for WETH but only USDC rewards available
                    )
                ),
                expect: .charterFailure(.noClaimableRewardsFound(symbol: "WETH"))
            )
        )
    }

    @Test("Claim Rewards - No Morpho rewards for requested asset")
    func testClaimRewardsNoMorphoRewardsForAsset() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - No Morpho rewards for requested asset",
                givens: [
                    .morphoReward(.alice, .amt(100, .usdc), .distributor, .validProof1, .base),
                    .prices([.usdc: 1.0, .weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "WETH"  // Asking for WETH but only USDC rewards available
                    )
                ),
                expect: .charterFailure(.noClaimableRewardsFound(symbol: "WETH"))
            )
        )
    }

    @Test("Claim Rewards - Zero amount rewards")
    func testClaimRewardsZeroAmount() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - Zero amount rewards",
                givens: [
                    .cometReward(.alice, .amt(0, .usdc), .cusdcv3, .usdcReward, .base),
                    .morphoReward(.alice, .amt(0, .weth), .distributor, .validProof1, .ethereum),
                    .prices([.usdc: 1.0, .weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"
                    )
                ),
                // Zero amount rewards are filtered out, resulting in no rewards found
                expect: .charterFailure(.noClaimableRewardsFound(symbol: "USDC"))
            )
        )
    }

    @Test("Claim Rewards - Different claimer unauthorized")
    func testClaimRewardsDifferentClaimer() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - Different claimer unauthorized",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: TestHelpers.Account.bob.address,  // Bob trying to claim Alice's rewards
                        assetSymbol: "USDC"
                    )
                ),
                expect: .charterFailure(.noClaimableRewardsFound(symbol: "USDC"))
            )
        )
    }

    @Test("Claim Rewards - Missing price")
    func testClaimRewardsMissingPrice() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - Missing price",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base)
                    // No price provided for USDC
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"
                    )
                ),
                expect: .charterFailure(.unpricedAsset(symbol: "USDC"))
            )
        )
    }

    @Test("Claim Rewards - With existing balance")
    func testClaimRewardsWithExistingBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - With existing balance",
                givens: [
                    .tokenBalance(.alice, .amt(50, .usdc), .base),  // Existing USDC balance
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("100e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Claim Rewards - Different assets filtered out")
    func testClaimRewardsDifferentAssetsFiltered() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - Different assets filtered out",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(3, .weth), .cwethv3, .wethReward, .base),
                    .morphoReward(.alice, .amt(5, .weth), .distributor, .validProof1, .ethereum),
                    .prices([.usdc: 1.0, .weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"  // Only claiming USDC, WETH rewards should be filtered out
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("100e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    @Test("Claim Rewards - Case insensitive asset symbol")
    func testClaimRewardsCaseInsensitiveAssetSymbol() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - Case insensitive asset symbol",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "usdc"  // lowercase
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("100e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                    ],
                    maxFlow: "100e6"
                )
            )
        )
    }

    // MARK: - Additional Missing Tests from Old Files

    @Test("Claim Rewards - Morpho rewards across multiple networks")
    func testClaimRewardsMorphoMultipleNetworks() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - Morpho rewards across multiple networks",
                givens: [
                    // Morpho regular distributor on Ethereum
                    .morphoReward(.alice, .amt(5, .weth), .distributor, .validProof1, .ethereum),
                    // Merkl distributor on Base (different network)
                    .morphoReward(.alice, .amt(3, .weth), .merklDistributor, .validProof2, .base),
                    .prices([.weth: 4000.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "WETH"
                    )
                ),
                // Equal-cost 1:1 routes allow both orderings; order doesn't affect delivered amounts.
                // Non-determinism stems from tie-breaking among equal-cost executable flows.
                expect: .unorderedFlows(
                    [
                        // Base Merkl claim (comes first with deterministic sorting)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [
                                        EthAddress("0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae")
                                    ],
                                    rewards: [BaseNetwork.Assets.WETH.assetAddress],
                                    claimables: [Number("3e18")],
                                    claimableNows: [Number("3e18")],
                                    proofs: [MorphoClaimProof.validProof2.data],
                                    symbols: ["WETH"],
                                    prices: [Number("4000e8")]
                                ),
                                source: .morphoReward(
                                    network: .base,
                                    distributor: EthAddress(
                                        "0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae"
                                    ),
                                    token: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
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
                            amount: "3e18"
                        ),
                        // Ethereum Morpho claim (comes second)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [
                                        EthAddress("0x2efd4625d0c149ebadf118ec5446c6de24d916a4")
                                    ],
                                    rewards: [EthereumNetwork.Assets.WETH.assetAddress],
                                    claimables: [Number("5e18")],
                                    claimableNows: [Number("5e18")],
                                    proofs: [MorphoClaimProof.validProof1.data],
                                    symbols: ["WETH"],
                                    prices: [Number("4000e8")]
                                ),
                                source: .morphoReward(
                                    network: .ethereum,
                                    distributor: EthAddress(
                                        "0x2efd4625d0c149ebadf118ec5446c6de24d916a4"
                                    ),
                                    token: EthereumNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.ethereum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e18"
                        ),
                        // Settlement routes (Base comes before Ethereum in actual output)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress.on(.base),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3e18"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: .ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress.on(.ethereum),
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(.ethereum)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5e18"
                        ),
                    ],
                    maxFlow: "8e18"
                )
            )
        )
    }

    @Test("Claim Rewards - Multiple Comet rewards same asset different networks")
    func testClaimRewardsMultipleCometsSameAssetDifferentNetworks() {
        runFlowTest(
            ChartTestCase(
                name: "Claim Rewards - Multiple Comet rewards same asset different networks",
                givens: [
                    .cometReward(.alice, .amt(50, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(30, .usdc), .cusdcv3, .usdcReward, .ethereum),
                    .prices([.usdc: 1.0]),
                ],
                intent: .claimRewards(
                    Charter.ClaimRewardsIntent(
                        claimer: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        assetSymbol: "USDC"
                    )
                ),
                // Equal-cost 1:1 claim routes make either order valid; amounts are identical either way.
                // Solver may emit either ordering due to tie-breaking among equal-cost executable flows.
                expect: .unorderedFlows(
                    [
                        // Ethereum USDC claim (comes first with deterministic sorting)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [EthereumNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .ethereum)],
                                    amounts: [Number("30e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [EthereumNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.ethereum,
                                    comet: Comet.cusdcv3.address(network: .ethereum),
                                    token: EthereumNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "30e6"
                        ),
                        // Base USDC claim (comes second with deterministic sorting)
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("50e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
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
                        // Ethereum USDC TokenBalance -> RewardSettlement
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress.on(Eth.Network.ethereum),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.ethereum)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "30e6"
                        ),
                        // Base USDC TokenBalance -> RewardSettlement
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .rewardSettlement,
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress.on(Eth.Network.base),
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce").on(Eth.Network.base)
                                ),
                                sink: .rewardSettlement(
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                    ],
                    maxFlow: "80e6"
                )
            )
        )
    }
}
