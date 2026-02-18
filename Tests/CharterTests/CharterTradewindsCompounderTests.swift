import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Compounder Tests

struct CharterTradewindsCompounderTests {

    // MARK: - Single Chain Happy Path Tests

    @Test("Compounder - Comet USDC rewards → swap to WETH → supply to Comet")
    func testCompounderCometUsdcToWethToComet() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Comet USDC to WETH to Comet",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.04e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.04e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
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
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.04e18",
                                    swapQuoteSellAmount: "100e6",
                                    swapQuoteBuyAmount: "0.04e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.0406e18").asSNumber,
                                    over: Number("100e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "100e6"
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: Comet.cwethv3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.0406e18"
                        ),
                    ],
                    maxFlow: "0.0406e18"
                )
            )
        )
    }

    @Test("Compounder - Morpho WETH rewards → swap to USDC → supply to Morpho vault")
    func testCompounderMorphoWethToUsdcToMorpho() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Morpho WETH to USDC to Morpho",
                givens: [
                    .morphoReward(.alice, .amt(1, .weth), .distributor, .validProof1, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "WETH"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.WETH.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.USDC.assetAddress,
                            buyAmount: "2500e6",
                            swapQuoteSellAmount: "1e18",
                            swapQuoteBuyAmount: "2500e6",
                            feeToken: BaseNetwork.Assets.WETH.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "USDC",
                                morphoVault: EthAddress("0x8eB67A509616cd6A7c1B3c8C21D48FF57df3d458"),
                                sender: TestHelpers.Account.alice.address,
                                chainId: Number(BaseNetwork.chainId)
                            )
                        )
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [
                                        BaseNetwork.MorphoRewardDistributors.distributor_0.distributor
                                    ],
                                    rewards: [BaseNetwork.Assets.WETH.assetAddress],
                                    claimables: ["1e18"],
                                    claimableNows: ["1e18"],
                                    proofs: [MorphoClaimProof.validProof1.data],
                                    symbols: ["WETH"],
                                    prices: ["2500e8"]
                                ),
                                source: .morphoReward(
                                    network: Eth.Network.base,
                                    distributor: BaseNetwork.MorphoRewardDistributors.distributor_0
                                        .distributor,
                                    token: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
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
                                    buyAmount: "2500e6",
                                    swapQuoteSellAmount: "1e18",
                                    swapQuoteBuyAmount: "2500e6",
                                    feeToken: BaseNetwork.Assets.WETH.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(
                                    fromRatio: Number("2537.5e6").asSNumber,
                                    over: Number("1e18").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "1e18"
                            ),
                            amount: "1e18"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoVaultSupply(isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .morphoVaultSupplyBalance(
                                    network: Eth.Network.base,
                                    vault: EthAddress("0x8eB67A509616cd6A7c1B3c8C21D48FF57df3d458"),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2537.5e6"
                        ),
                    ],
                    maxFlow: "2537.5e6"
                )
            )
        )
    }

    @Test("Compounder - Comet USDC rewards → swap to WETH → supply to Aave")
    func testCompounderCometUsdcToWethToAave() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Comet USDC to WETH to Aave",
                givens: [
                    .cometReward(.alice, .amt(500, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.2e18",
                            swapQuoteSellAmount: "500e6",
                            swapQuoteBuyAmount: "0.2e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                aavePool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .exactFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [BaseNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .base)],
                                    amounts: [Number("500e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [BaseNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.base,
                                    comet: Comet.cusdcv3.address(network: .base),
                                    token: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "500e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.2e18",
                                    swapQuoteSellAmount: "500e6",
                                    swapQuoteBuyAmount: "0.2e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.203e18").asSNumber,
                                    over: Number("500e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "500e6"
                            ),
                            amount: "500e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveSupply(isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .aaveSupplyBalance(
                                    network: Eth.Network.base,
                                    pool: EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.203e18"
                        ),
                    ],
                    maxFlow: "0.203e18"
                )
            )
        )
    }

    // MARK: - Cross-Network Tests

    @Test("Compounder - Cross-network: swap on Base, supply on Ethereum")
    func testCompounderCrossNetworkSwapBaseSupplyEthereum() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Cross-network Base to Ethereum",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                    .acrossQuote(.amt(0.001, .weth), 0.01),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.04e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.04e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(EthereumNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .ethereum),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .unorderedFlows(
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
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.04e18",
                                    swapQuoteSellAmount: "100e6",
                                    swapQuoteBuyAmount: "0.04e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.0406e18").asSNumber,
                                    over: Number("100e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "100e6"
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "0.001e18")
                                ],
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.0406e18"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .wrap,
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.ETH.assetAddress,
                                    symbol: "ETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.039194e18"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.ethereum,
                                    comet: Comet.cwethv3.address(network: .ethereum),
                                    baseAsset: EthereumNetwork.Assets.WETH.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.039194e18"
                        ),
                    ],
                    maxFlow: "0.039194e18"
                )
            )
        )
    }

    @Test("Compounder - Existing token balance is NOT included in supply (only swap output)")
    func testCompounderDoesNotSupplyExistingBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Existing balance not supplied",
                givens: [
                    .tokenBalance(.alice, .amt(1.0, .weth), .base),
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.04e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.04e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
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
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.04e18",
                                    swapQuoteSellAmount: "100e6",
                                    swapQuoteBuyAmount: "0.04e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.0406e18").asSNumber,
                                    over: Number("100e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "100e6"
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: Comet.cwethv3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.0406e18"
                        ),
                    ],
                    maxFlow: "0.0406e18"
                )
            )
        )
    }

    // MARK: - Multi-Chain Claiming Tests

    // TODO: Re-enable when bridging rewards before swap is supported.
    // Multi-chain compounding IS supported when each chain has its own swap (see testCompounderMultipleRewardsMultiChain).
    // This test is disabled because it tries to bridge rewards BEFORE swapping (single swap on destination chain).
    // Current implementation requires swaps on the same chain as their rewards.
    @Test("Compounder - Claims from multiple chains and bridges to swap network", .disabled("Bridging rewards before swap not yet supported - each chain must have its own swap"))
    func testCompounderMultiChainClaimWithBridge() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Multi-chain claim with bridge",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(50, .usdc), .cusdcv3, .usdcReward, .ethereum),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                    .acrossQuote(.amt(10, .usdc), 0.01),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.0558e18",
                            swapQuoteSellAmount: "139.5e6",
                            swapQuoteBuyAmount: "0.0558e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .unorderedFlows(
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
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometClaimRewards(
                                    cometRewards: [EthereumNetwork.Assets.USDC.assetAddress],
                                    comets: [Comet.cusdcv3.address(network: .ethereum)],
                                    amounts: [Number("50e6")],
                                    symbols: ["USDC"],
                                    prices: [Number("1e8")],
                                    tokens: [EthereumNetwork.Assets.USDC.assetAddress]
                                ),
                                source: .cometReward(
                                    network: Eth.Network.ethereum,
                                    comet: Comet.cusdcv3.address(network: .ethereum),
                                    token: EthereumNetwork.Assets.USDC.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: Eth.Network.ethereum,
                                    address: EthereumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(0.99),
                                minFlow: "10e6",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.0558e18",
                                    swapQuoteSellAmount: "139.5e6",
                                    swapQuoteBuyAmount: "0.0558e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.056637e18").asSNumber,
                                    over: Number("139.5e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "139.5e6"
                            ),
                            amount: "139.5e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: Comet.cwethv3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.056637e18"
                        ),
                    ],
                    maxFlow: "0.056637e18"
                )
            )
        )
    }

    // MARK: - Error Case Tests

    @Test("Compounder - Error: Different senders")
    func testCompounderErrorDifferentSenders() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Error: Different senders",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.04e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.04e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.bob.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.compounderSenderMismatch
                )
            )
        )
    }

    @Test("Compounder - Error: Swap sell token does not match claim asset")
    func testCompounderErrorSwapSellTokenMismatch() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Error: Swap sell token mismatch",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.WETH.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.USDC.assetAddress,
                            buyAmount: "5000e6",
                            swapQuoteSellAmount: "1e18",
                            swapQuoteBuyAmount: "5000e6",
                            feeToken: BaseNetwork.Assets.WETH.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cusdcv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.compounderTokenMismatch(
                        expected: "USDC",
                        actual: "WETH"
                    )
                )
            )
        )
    }

    @Test("Compounder - Error: Swap buy token does not match supply asset")
    func testCompounderErrorSwapBuyTokenMismatch() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Error: Swap buy token mismatch",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "1e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "1e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "USDC",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cusdcv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.compounderTokenMismatch(
                        expected: "USDC",
                        actual: "WETH"
                    )
                )
            )
        )
    }

    @Test("Compounder - Error: Supply amount must be max")
    func testCompounderErrorSupplyAmountNotMax() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Error: Supply amount not max",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.04e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.04e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: "1000e6",
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.error("Compounder requires supply amount to be .max")
                )
            )
        )
    }

    @Test("Compounder - Error: No claimable rewards found")
    func testCompounderErrorNoClaimableRewards() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Error: No claimable rewards",
                givens: [
                    .prices([.usdc: 1.0, .weth: 2500.0])
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.04e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.04e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.noClaimableRewardsFound(symbol: "USDC")
                )
            )
        )
    }

    @Test("Compounder - Multiple reward sources (Comet + Morpho)")
    func testCompounderMultipleRewardSources() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Multiple reward sources combined",
                givens: [
                    .cometReward(.alice, .amt(50, .usdc), .cusdcv3, .usdcReward, .base),
                    .morphoReward(.alice, .amt(50, .usdc), .distributor, .validProof2, .base),
                    .prices([.usdc: 1.0, .weth: 2500.0]),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: BaseNetwork.Assets.WETH.assetAddress,
                            buyAmount: "0.04e18",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.04e18",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .comet(
                            Charter.CometSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "WETH",
                                chainId: Number(BaseNetwork.chainId),
                                comet: Comet.cwethv3.address(network: .base),
                                sender: TestHelpers.Account.alice.address
                            )
                        )
                    )
                ),
                expect: .unorderedFlows(
                    [
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .morphoClaimRewards(
                                    distributors: [
                                        BaseNetwork.MorphoRewardDistributors.distributor_0.distributor
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
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
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
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "50e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .swap(
                                    buyToken: BaseNetwork.Assets.WETH.assetAddress,
                                    buyAmount: "0.04e18",
                                    swapQuoteSellAmount: "100e6",
                                    swapQuoteBuyAmount: "0.04e18",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeAmount: "0",
                                    isExactOut: false,
                                    isCappedMax: true
                                ),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: Percentage(
                                    fromRatio: Number("0.0406e18").asSNumber,
                                    over: Number("100e6").asSNumber
                                ),
                                minFlow: "0",
                                maxFlow: "100e6"
                            ),
                            amount: "100e6"
                        ),
                        .init(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .cometSupply(isCappedMax: true),
                                source: .tokenBalance(
                                    network: Eth.Network.base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                sink: .cometSupplyBalance(
                                    network: Eth.Network.base,
                                    comet: Comet.cwethv3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: TestHelpers.Account.alice.address
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "0.0406e18"
                        ),
                    ],
                    maxFlow: "0.0406e18"
                )
            )
        )
    }

    @Test("Compounder - Error: Cross-chain with non-bridgeable supply asset")
    func testCompounderCrossChainNonBridgeableAsset() {
        runFlowTest(
            ChartTestCase(
                name: "Compounder - Cross-chain non-bridgeable asset fails",
                givens: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                ],
                intent: .compounder(
                    Charter.CompounderIntent(
                        claimRewardsIntents: [Charter.ClaimRewardsIntent(
                            claimer: TestHelpers.Account.alice.address,
                            assetSymbol: "USDC"
                        )],
                        swapIntents: [Charter.SwapIntent(
                            chainId: Number(BaseNetwork.chainId),
                            sellToken: BaseNetwork.Assets.USDC.assetAddress,
                            sellAmount: Number.MAX_UINT_256,
                            buyToken: Token.cbbtc.address(network: .base)!,
                            buyAmount: "0.001e8",
                            swapQuoteSellAmount: "100e6",
                            swapQuoteBuyAmount: "0.001e8",
                            feeToken: BaseNetwork.Assets.USDC.assetAddress,
                            feeAmount: "0",
                            sender: TestHelpers.Account.alice.address,
                            isExactOut: false,
                            isBuy: false
                        )],
                        supplyIntent: .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: Number.MAX_UINT_256,
                                assetSymbol: "cbBTC",
                                morphoVault: MorphoVault.wbtc.address(network: .ethereum),
                                sender: TestHelpers.Account.alice.address,
                                chainId: Number(EthereumNetwork.chainId)
                            )
                        )
                    )
                ),
                expect: .charterFailure(
                    Charter.CharterError.error("Cross-chain compounding into cbBTC is not supported. Only bridgeable assets (WETH, ETH, USDC) are supported for cross-chain supply.")
                )
            )
        )
    }
}
