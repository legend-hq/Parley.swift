import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

// MARK: - Withdraw Backing Token Tests

struct CharterTradewindsWithdrawBackingTokenTests {

    // MARK: Withdraw Backing from Long Position

    @Test("Withdraw USDC backing from long position")
    func testWithdrawBackingFromLongPosition() {
        runFlowTest(
            ChartTestCase(
                name: "Withdraw Backing from Long",
                givens: [
                    // Alice has a long position with excess backing
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),  // 5 WETH collateral in long position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    // Add Base network QuotePay sink fee (USDC $0.02) so wallet can pay it
                    .tokenBalance(.alice, .amt(0.02, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "WETH",  // Exposure asset
                        backingAssetSymbol: "USDC",  // Withdrawing loan tokens
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw 2,000 USDC (net). Tradewinds will calculate gross amount.
                        amount: Number("2000e6"),  // Withdraw 2,000 USDC net
                        isShort: false,  // Long position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Tradewinds calculates: 2,000 USDC + 0.02 fee = 2,000.02 USDC
                                    amount: Number("2000.02e6"),
                                    isShort: false
                                ),
                                source: .loopVenue(  // Source is the position
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(  // Sink is the wallet
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "2000.02e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256 - Number("0.02e6")
                )
            )
        )
    }

    @Test("Partial backing withdrawal")
    func testPartialBackingWithdrawal() {
        runFlowTest(
            ChartTestCase(
                name: "Partial Backing Withdrawal",
                givens: [
                    // Alice has a long position
                    .morphoCollateral(
                        .alice,
                        .amt(3, .weth),  // 3 WETH collateral in long position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                    // Add Base network QuotePay sink fee (USDC $0.02)
                    .tokenBalance(.alice, .amt(0.02, .usdc), .base),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw only 1,000 USDC (net). Tradewinds will calculate gross amount.
                        amount: Number("1000e6"),
                        isShort: false,  // Long position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Tradewinds calculates: 1,000 USDC + 0.02 fee = 1,000.02 USDC
                                    amount: Number("1000.02e6"),
                                    isShort: false
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1000.02e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256 - Number("0.02e6")
                )
            )
        )
    }

    // MARK: Withdraw Different Assets

    @Test("Withdraw WETH backing")
    func testWithdrawWETHBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Withdraw WETH Backing",
                givens: [
                    // Position with WETH as backing (SHORT position)
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),  // 5 WETH collateral (backing) in short position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                    // Add Base QuotePay sink fee in WETH ($0.02 → 0.000005 WETH)
                    .tokenBalance(.alice, .amt(0.000005, .weth), .base),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "WETH",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw 1 WETH (net). Tradewinds will calculate gross amount.
                        amount: Number("1e18"),
                        isShort: true,  // Short position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    // Tradewinds calculates: 1 WETH + 0.000005 fee = 1.000005 WETH
                                    amount: Number("1.000005e18"),
                                    isShort: true
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.WETH.assetAddress,
                                    symbol: "WETH",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1.000005e18"
                        )
                    ],
                    maxFlow: Number("5e18") - Number("0.000005e18")  // Max is collateral balance (5 WETH) minus fees
                )
            )
        )
    }

    @Test("Withdraw cbBTC backing")
    func testWithdrawCbBTCBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Withdraw cbBTC Backing",
                givens: [
                    // Position with cbBTC as backing (SHORT position)
                    .morphoCollateral(
                        .alice,
                        .amt(0.5, .cbbtc),  // 0.5 cbBTC collateral (backing) in short position
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .base
                    ),
                    // Add Base QuotePay sink fee in cbBTC ($0.02 → 0.0000002 cbBTC)
                    .tokenBalance(.alice, .amt(0.0000002, .cbbtc), .base),
                    .quote(.basic),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "USDC",
                        backingAssetSymbol: "cbBTC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw 0.1 cbBTC (net). Tradewinds will calculate gross amount.
                        amount: Number("0.1e8"),
                        isShort: true,  // Short position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAssetSymbol: "USDC",
                                    // Tradewinds calculates: 0.1 cbBTC + 0.0000002 fee = 0.1000002 cbBTC
                                    amount: Number("10.000020e6"),
                                    isShort: true
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.cbBTC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.cbBTC.assetAddress,
                                    symbol: "cbBTC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "10000020"
                        )
                    ],
                    maxFlow: Number("0.5e8") - Number("20")  // Max is collateral balance (0.5 cbBTC SHORT) minus fees
                )
            )
        )
    }

    // MARK: Maximum Safe Withdrawal

    @Test("Withdraw maximum safe backing amount")
    func testWithdrawMaxSafeBacking() {
        runFlowTest(
            ChartTestCase(
                name: "Max Safe Backing Withdrawal",
                givens: [
                    // Position with sufficient health factor
                    .morphoCollateral(
                        .alice,
                        .amt(8, .weth),  // 8 WETH collateral in long position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                    // Add Base network QuotePay sink fee (USDC $0.02)
                    .tokenBalance(.alice, .amt(0.02, .usdc), .base),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw 5,000 USDC (net). Tradewinds will calculate gross amount.
                        amount: Number("5000e6"),  // Maximum safe amount (net)
                        isShort: false,  // Long position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Tradewinds calculates: 5,000 USDC + 0.02 fee = 5,000.02 USDC
                                    amount: Number("5000.02e6"),
                                    isShort: false
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "5000.02e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256 - Number("0.02e6")
                )
            )
        )
    }

    // MARK: Strategic Withdrawals

    @Test("Withdraw backing to increase leverage")
    func testWithdrawToIncreaseLeverage() {
        runFlowTest(
            ChartTestCase(
                name: "Withdraw to Increase Leverage",
                givens: [
                    // Position is over-collateralized
                    .morphoCollateral(
                        .alice,
                        .amt(5, .weth),  // 5 WETH collateral in long position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                    // Add Base network QuotePay sink fee (USDC $0.02)
                    .tokenBalance(.alice, .amt(0.02, .usdc), .base),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw to increase leverage (net). Tradewinds will calculate gross amount.
                        amount: Number("3000e6"),
                        isShort: false,  // Long position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Tradewinds calculates: 3,000 USDC + 0.02 fee = 3,000.02 USDC
                                    amount: Number("3000.02e6"),
                                    isShort: false
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "3000.02e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256 - Number("0.02e6")
                )
            )
        )
    }

    @Test("Withdraw backing for portfolio rebalancing")
    func testWithdrawForRebalancing() {
        runFlowTest(
            ChartTestCase(
                name: "Withdraw for Rebalancing",
                givens: [
                    .morphoCollateral(
                        .alice,
                        .amt(3, .weth),  // 3 WETH collateral in long position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                    // Add Base network QuotePay sink fee (USDC $0.02)
                    .tokenBalance(.alice, .amt(0.02, .usdc), .base),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw for other opportunities (net). Tradewinds will calculate gross amount.
                        amount: Number("1500e6"),
                        isShort: false,  // Long position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    // Tradewinds calculates: 1,500 USDC + 0.02 fee = 1,500.02 USDC
                                    amount: Number("1500.02e6"),
                                    isShort: false
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "1500.02e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256 - Number("0.02e6")
                )
            )
        )
    }

    // MARK: Exact Withdrawal Enforcement

    @Test("Withdraw backing token enforces exact amount from loop market with existing balance")
    func testWithdrawBackingTokenExactWithdrawalWithExistingBalance() {
        runFlowTest(
            ChartTestCase(
                name: "Exact Withdrawal with Existing Balance",
                givens: [
                    // Alice has a long position
                    .morphoCollateral(
                        .alice,
                        .amt(2, .weth),  // 2 WETH collateral in long position
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    // Alice already has some USDC token balance
                    .tokenBalance(.alice, .amt(1000, .usdc), .base),
                    // Add Base network QuotePay sink fee (USDC $0.02)
                    .tokenBalance(.alice, .amt(0.02, .usdc), .base),
                    .quote(.basic),
                ],
                intent: .withdrawBackingToken(
                    Charter.WithdrawBackingTokenIntent(
                        exposureAssetSymbol: "WETH",
                        backingAssetSymbol: "USDC",
                        marketId: Hex(
                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                        ),
                        // Withdraw 500 USDC - should withdraw from loop market, not use existing balance
                        amount: Number("500e6"),
                        isShort: false,  // Long position
                        sender: EthAddress("0x00000000000000000000000000000000000A11CE"),
                        chainId: Number(BaseNetwork.chainId)
                    )
                ),
                expect: .exactFlows(
                    [
                        Tradewinds.Flow(
                            route: Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
                                type: .withdrawBackingToken(
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureAssetSymbol: "WETH",
                                    amount: Number("500e6"),
                                    isShort: false
                                ),
                                source: .loopVenue(
                                    network: .base,
                                    marketId: Hex(
                                        "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                    ),
                                    backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                sink: .tokenBalance(
                                    network: .base,
                                    address: BaseNetwork.Assets.USDC.assetAddress,
                                    symbol: "USDC",
                                    wallet: EthAddress("0x00000000000000000000000000000000000a11ce")
                                ),
                                rate: .one,
                                minFlow: "0",  // Let Tradewinds optimize
                                maxFlow: Number.MAX_UINT_256
                            ),
                            amount: "500.02e6"
                        )
                    ],
                    maxFlow: Number.MAX_UINT_256 - Number("0.02e6")
                )
            )
        )
    }
}
