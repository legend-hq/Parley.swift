@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Unloop Short Tests")
struct UnloopShortTests {
    @Test("Alice unloops short on WETH backed by WBTC")
    func testUnloopShortSuccessTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .wbtc),
                        Morpho(collateralToken: .wbtc, borrowToken: .weth),
                        .worldChain
                    ),
                    .tokenBalance(.alice, .amt(0.1, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .unloopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .amt(40, .weth),
                    backingAmountToExit: .amt(0.5, .wbtc),
                    maxSwapBackingAmount: .amt(1, .wbtc),
                    on: .worldChain
                ),
                expect: .successWithActions(
                    .single(
                        .unloopShort(
                            exposureAmount: .amt(40, .weth),
                            backingAmountToExit: .amt(0.5, .wbtc),
                            maxSwapBackingAmount: .amt(1, .wbtc),
                            feeAmount: .init(fromWei: 16_006_402_561_024_409, ofToken: .weth),  // fee = exposureAmount * 0.0004 / 0.9996
                            feeRecipient: .stax,
                            market: .morpho(.wbtc, .weth),
                            network: .worldChain,
                            executionType: .immediate
                        )
                    ),
                    [
                        Charter.ActionContext.unloopShort(
                            Charter.ActionContext.UnloopShortActionContext(
                                backingAssetSymbol: "WBTC",
                                backingToken: EthAddress(
                                    "0x03c7054bcb39f7b2e5b2c7acb37583e32d70cfa3"
                                ),
                                backingTokenPrice: Number("100000e8"),
                                maxSwapBackingAmount: Number("1e8"),
                                chainId: Number("480"),
                                exposureAmount: Number("40e18"),
                                exposureAssetSymbol: "WETH",
                                exposureToken: EthAddress(
                                    "0x4200000000000000000000000000000000000006"
                                ),
                                exposureTokenPrice: Number("4000e8"),
                                swapVenue: "UNISWAP_V3",
                                borrowVenue: "MORPHO_BLUE",
                                borrowMarketId: Hex(
                                    "0x19c682c3a37025075074cefea866fbe54656abc0fb6a7355b62a53f45b959abf"
                                ),
                                feeAmount: Number("0.016006402561024409e18"),
                                feeAssetSymbol: "WETH",
                                feeToken: EthAddress(
                                    "0x4200000000000000000000000000000000000006"
                                ),
                                feeTokenPrice: Number("4000e8")
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test(
        "Alice tries to unloop short from a Morpho market that does not exist (WETH/USDC)"
    )
    func testUnloopShortInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic)
                ],
                when: .unloopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .usdc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .amt(1, .weth),
                    backingAmountToExit: .amt(0, .usdc),
                    maxSwapBackingAmount: .amt(1, .usdc),
                    on: .ethereum
                ),
                expect: .failure(
                    .morphoMarketNotFound(
                        marketId: Morpho(collateralToken: .usdc, borrowToken: .weth)
                            .marketId(.ethereum),
                        network: .ethereum
                    )
                )
            )
        )
    }

    @Test("Alice unloops short using max exposure amount")
    func testUnloopShortMaxExposure() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .wbtc),
                        Morpho(collateralToken: .wbtc, borrowToken: .weth),
                        .worldChain
                    ),
                    .morphoBorrow(
                        .alice,
                        Morpho(collateralToken: .wbtc, borrowToken: .weth),
                        .amt(20, .weth),
                        .amt(1, .wbtc),
                        .worldChain
                    ),
                    .tokenBalance(.alice, .amt(0.1, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .unloopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .max(.weth),
                    backingAmountToExit: .amt(0, .wbtc),
                    maxSwapBackingAmount: .amt(1, .wbtc),
                    on: .worldChain
                ),
                expect: .success(
                    .single(
                        .unloopShort(
                            exposureAmount: .max(.weth),
                            backingAmountToExit: .amt(0, .wbtc),
                            maxSwapBackingAmount: .amt(1, .wbtc),
                            // fee = maxExposure(20 WETH) * 0.0004 / 0.9996 = 8_003_201_280_512_204 wei
                            feeAmount: .init(
                                fromWei: Number(
                                    8_003_201_280_512_204
                                ),
                                ofToken: .weth
                            ),
                            feeRecipient: .stax,
                            market: .morpho(.wbtc, .weth),
                            network: .worldChain,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }
    @Test("Alice unloops short using max backing amount to exit")
    func testUnloopShortMaxBackingToExit() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .wbtc),
                        Morpho(collateralToken: .wbtc, borrowToken: .weth),
                        .worldChain
                    ),
                    .tokenBalance(.alice, .amt(0.1, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .unloopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .amt(20, .weth),
                    backingAmountToExit: .max(.wbtc),
                    maxSwapBackingAmount: .amt(1, .wbtc),
                    on: .worldChain
                ),
                expect: .success(
                    .single(
                        .unloopShort(
                            exposureAmount: .amt(20, .weth),
                            backingAmountToExit: .amt(1, .wbtc),  // Resolved from .max to actual available
                            maxSwapBackingAmount: .amt(1, .wbtc),
                            feeAmount: .init(fromWei: 8_003_201_280_512_204, ofToken: .weth),  // Updated fee
                            feeRecipient: .stax,
                            market: .morpho(.wbtc, .weth),
                            network: .worldChain,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice unloops short with zero backing exit - reduce exposure only")
    func testUnloopShortZeroBackingExit() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(0.001, .weth),
                        Morpho(collateralToken: .weth, borrowToken: .usdc),
                        .base
                    ),
                    .quote(.basic),
                ],
                when: .unloopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(10, .usdc),
                    backingAmountToExit: .amt(0, .weth),
                    maxSwapBackingAmount: .amt(0.001, .weth),
                    on: .base
                ),
                expect: .success(
                    .single(
                        .unloopShort(
                            exposureAmount: .amt(10, .usdc),
                            backingAmountToExit: .amt(0, .weth),
                            maxSwapBackingAmount: .amt(0.001, .weth),
                            // fee = exposureAmount(10 USDC) * 0.0004 / 0.9996 = 0.0040016006402561024 USDC
                            feeAmount: .amt(0.0040016006402561024, .usdc),
                            feeRecipient: .stax,
                            market: .morpho(.weth, .usdc),
                            network: .base,
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice tries to unloop short with max exposure and max backing (invalid - should fail)")
    func testUnloopShortMaxBoth() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoCollateral(
                        .alice,
                        .amt(1, .wbtc),
                        Morpho(collateralToken: .wbtc, borrowToken: .weth),
                        .worldChain
                    ),
                    .tokenBalance(.alice, .amt(0.1, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .unloopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .max(.weth),
                    backingAmountToExit: .max(.wbtc),
                    maxSwapBackingAmount: .amt(1, .wbtc),
                    on: .worldChain
                ),
                expect: .failure(
                    .error(
                        "Invalid unloop short: when exposureAmount is max (full unloop), backingAmountToExit must be 0"
                    )
                )
            )
        )
    }

}
