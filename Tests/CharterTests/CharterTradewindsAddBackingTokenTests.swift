import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Add Backing Token Tests

struct CharterTradewindsAddBackingTokenTests {

    // MARK: Add Backing to Long Position

    @Test("Add USDC backing to long position")
    func testAddBackingToLongPosition() {
        runFlowTest(
            ChartTestCase(
                name: "Add Backing to Long",
                givens: [
                    // Alice has additional USDC to add to her long position.
                    // Add +$0.02 (Base QuotePay fee) so the route can deliver exactly 5,000 USDC.
                    .tokenBalance(.alice, .amt(5_000.02, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .addBackingToken(
                    Charter.AddBackingTokenIntent(
                        exposureAssetSymbol: "WETH",  // Exposure asset
                        backingAssetSymbol: "USDC",  // Adding loan tokens
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        amount: Number("5000e6"),  // Add 5,000 USDC
                        isShort: false,  // Long position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .addBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Source amount includes the Base QuotePay in-fee (0.02 USDC)
                                    amount: Number("5000.02e6"),
                                    isShort: false
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
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

    // MARK: Add Backing to Short Position

    @Test("Add WETH collateral to short position")
    func testAddBackingToShortPosition() {
        runFlowTest(
            ChartTestCase(
                name: "Add Backing to Short",
                givens: [
                    // Alice has additional WETH to add as collateral to her short.
                    // Add +0.000006 WETH (~$0.024 on Base) to ensure fee + rounding coverage.
                    .tokenBalance(.alice, .amt(2.000006, .weth), .base),
                    .quote(.basic),
                ],
                intent: .addBackingToken(
                    Charter.AddBackingTokenIntent(
                        exposureAssetSymbol: "USDC",  // Shorting USDC
                        backingAssetSymbol: "WETH",  // Adding collateral
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        amount: Number("2e18"),  // Target 2 WETH net collateral
                        isShort: true,  // Short position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .addBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    amount: Number("2.000005e18"),
                                    isShort: true
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2.000005e18"
                        )
                    ],
                    // With +0.000006 WETH in wallet and 0.000005 WETH fee, max sink is 2.000001 WETH
                    maxFlow: "2.000001e18"
                )
            )
        )
    }

    // MARK: Cross-Chain Add Backing

    @Test("Add backing with bridging from Arbitrum")
    func testAddBackingWithBridging() {
        runFlowTest(
            ChartTestCase(
                name: "Cross-Chain Add Backing",
                givens: [
                    // Alice has USDC on Arbitrum but position is on Base.
                    .tokenBalance(.alice, .amt(5_000.020203, .usdc), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),  // 1% bridge fee
                ],
                intent: .addBackingToken(
                    Charter.AddBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        amount: Number("4949e6"),  // Amount after bridge fees
                        isShort: false,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        // Bridge from Arbitrum to Base (includes 1% rate and 1 USDC fixed fee)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .bridge(bridgeType: .across, isCappedMax: false),
                                source: .tokenBalance(
                                    network: .arbitrum,
                                    address: ArbitrumNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: Percentage(fromNumber: Number("0.99e18")),  // 0.99 (1% fee)
                                fees: [
                                    Tradewinds.Fee(type: .bridgeAcross, isInFee: false, amount: "1e6")
                                ],
                                minFlow: "0",
                                maxFlow: "5000e6"
                            ),
                            // (4949.02e6 + 1e6)/0.99 ≈ 5000.020203e6 (ceil to micro-units)
                            amount: "5000.020203e6"
                        ),
                        // Add backing on Base
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .addBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Source includes Base QuotePay in-fee (0.02 USDC)
                                    amount: Number("4949.02e6"),
                                    isShort: false
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "4949.02e6"  // Amount after bridge + Base QuotePay
                        ),
                    ],
                    maxFlow: "4949e6"
                )
            )
        )
    }

    // MARK: Add Backing from Earning Balance

    @Test("Add backing withdrawing from Aave")
    func testAddBackingFromAave() {
        runFlowTest(
            ChartTestCase(
                name: "Add Backing from Aave",
                givens: [
                    // Alice has USDC in Aave. Include extra $0.02 for withdraw fee and $0.02 for add-backing fee.
                    .aaveSupply(.alice, .amt(3_000.04, .usdc), .baseV3, .base),
                    .quote(.basic),
                ],
                intent: .addBackingToken(
                    Charter.AddBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        amount: Number("3000e6"),
                        isShort: false,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId),
                        earnMarketPolicy: .all
                    )
                ),
                expect: .exactFlows(
                    [
                        // Withdraw from Aave (includes Base QuotePay in-fee 0.02 USDC + 0.02 for downstream add-backing)
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .aaveWithdraw(isMax: false),
                                source: .aaveSupplyBalance(
                                    network: .base,
                                    pool: AavePool.baseV3.address(network: .base),
                                    baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000.04e6"
                        ),
                        // Add backing
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .addBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Source includes Base QuotePay in-fee (0.02 USDC)
                                    amount: Number("3000.02e6"),
                                    isShort: false
                                ),
                                source: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000.02e6"
                        ),
                    ],
                    maxFlow: "3000e6"
                )
            )
        )
    }

    // MARK: Edge Cases

    @Test("Add backing with zero amount should fail")
    func testAddBackingZeroAmount() {
        runFlowTest(
            ChartTestCase(
                name: "Zero Amount Add Backing",
                givens: [
                    // Alice has no backing to add
                    .quote(.basic)
                ],
                intent: .addBackingToken(
                    Charter.AddBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        amount: Number("5000e6"),
                        isShort: false,
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .failure(
                    Tradewinds.Error.insufficientResources(target: .exact("5000e6"), max: "0"),
                    maxFlow: "0"
                )
            )
        )
    }
}
