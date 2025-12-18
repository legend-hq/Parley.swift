@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Unloop Long Tests")
struct UnloopLongTests {
    @Test("Alice unloops long on WBTC")
    func testUnloopLongSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .unloopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(1, .cbbtc),
                    backingAmountToExit: .amt(20000, .usdc),
                    minSwapBackingAmount: .amt(85000, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .unloopLong(
                            exposureAmount: .amt(1, .cbbtc),
                            backingAmountToExit: .amt(20000, .usdc),
                            minSwapBackingAmount: .amt(85000, .usdc),
                            feeAmount: .amt(34, .usdc),
                            feeRecipient: .stax,
                            market: .morpho(.cbbtc, .usdc),
                            network: .ethereum,
                            executionType: .immediate
                        )
                    ),
                    [
                        Charter.ActionContext.unloopLong(
                            Charter.ActionContext.UnloopLongActionContext(
                                backingAssetSymbol: "USDC",
                                backingToken: EthAddress(
                                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                ),
                                backingTokenPrice: Number("1e8"),
                                minSwapBackingAmount: Number("85000e6"),
                                backingAmountToExit: Number("20000e6"),
                                chainId: Number("1"),
                                exposureAmount: Number("1e8"),
                                exposureAssetSymbol: "cbBTC",
                                exposureToken: EthAddress(
                                    "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                ),
                                exposureTokenPrice: Number("100000e8"),
                                swapVenue: "UNISWAP_V3",
                                borrowVenue: "MORPHO_BLUE",
                                borrowMarketId: Hex(
                                    "0x64d65c9a2d91c36d56fbc42d69e979335320169b3df63bf92789e2c8883fcc64"
                                ),
                                feeAmount: Number("34e6"),
                                feeAssetSymbol: "USDC",
                                feeToken: EthAddress(
                                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                ),
                                feeTokenPrice: Number("1e8")
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice tries to unloop loop from a Morpho market that does not exist (WETH/USDC)")
    func testUnloopLongInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .unloopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(1, .weth),
                    backingAmountToExit: .amt(20000, .usdc),
                    minSwapBackingAmount: .amt(1, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unknownMorphoMarket(marketId, 1))
                // Now properly returns .morphoMarketNotFound with marketId and network
                expect: .failure(
                    .morphoMarketNotFound(
                        marketId: Morpho(collateralToken: .weth, borrowToken: .usdc)
                            .marketId(.ethereum),
                        network: .ethereum
                    )
                )
            )
        )
    }

    @Test("Alice unloops long using max exposure amount")
    func testUnloopLongMaxExposure() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .cbbtc),
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .ethereum
                    ),
                    .tokenBalance(.alice, .amt(0.1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .unloopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .max(.cbbtc),
                    backingAmountToExit: .amt(0, .usdc),
                    minSwapBackingAmount: .amt(85000, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .unloopLong(
                            exposureAmount: .max(.cbbtc),
                            backingAmountToExit: .amt(0, .usdc),
                            minSwapBackingAmount: .amt(85000, .usdc),
                            feeAmount: .amt(34, .usdc),
                            feeRecipient: .stax,
                            market: .morpho(.cbbtc, .usdc),
                            network: .ethereum,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice unloops long using max backing amount to exit")
    func testUnloopLongMaxBackingToExit() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .cbbtc),
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .ethereum
                    ),
                    .tokenBalance(.alice, .amt(0.1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .unloopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(0.5, .cbbtc),
                    backingAmountToExit: .max(.usdc),
                    minSwapBackingAmount: .amt(40000, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .unloopLong(
                            exposureAmount: .amt(0.5, .cbbtc),
                            backingAmountToExit: .max(.usdc),
                            minSwapBackingAmount: .amt(40000, .usdc),
                            feeAmount: .amt(16, .usdc),
                            feeRecipient: .stax,
                            market: .morpho(.cbbtc, .usdc),
                            network: .ethereum,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice unloops long with zero backing exit - reduce exposure only")
    func testUnloopLongZeroBackingExit() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .unloopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(0.0001, .cbbtc),
                    backingAmountToExit: .amt(0, .usdc),
                    minSwapBackingAmount: .amt(10, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .unloopLong(
                            exposureAmount: .amt(0.0001, .cbbtc),
                            backingAmountToExit: .amt(0, .usdc),
                            minSwapBackingAmount: .amt(10, .usdc),
                            // fee = minSwapBackingAmount(10 USDC) * 0.0004 = 0.004 USDC
                            feeAmount: .amt(0.004, .usdc),
                            feeRecipient: .stax,
                            market: .morpho(.cbbtc, .usdc),
                            network: .ethereum,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice tries to unloop long with max exposure and max backing (invalid - should fail)")
    func testUnloopLongMaxBoth() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .cbbtc),
                        Morpho(collateralToken: .cbbtc, borrowToken: .usdc),
                        .ethereum
                    ),
                    .tokenBalance(.alice, .amt(0.1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .unloopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .max(.cbbtc),
                    backingAmountToExit: .max(.usdc),
                    minSwapBackingAmount: .amt(85000, .usdc),
                    on: .ethereum
                ),
                expect: .failure(
                    .error(
                        "Invalid unloop long: when exposureAmount is max (full unloop), backingAmountToExit must be 0"
                    )
                )
            )
        )
    }
}
