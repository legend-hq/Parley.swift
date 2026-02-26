@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Loop Long Tests")
struct LoopLongTests {
    @Test("Alice loops long on WBTC using USDC")
    func testLoopLongSuccess() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(20010, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(1, .cbbtc),
                    providedBackingAmount: .amt(20000, .usdc),
                    maxSwapBackingAmount: .amt(85000, .usdc),
                    on: .ethereum
                ),
                expect: .successWithActions(
                    .single(
                        .loopLong(
                            exposureAmount: .amt(1, .cbbtc),
                            providedBackingAmount: .amt(20000, .usdc),
                            cappedMax: false,
                            maxSwapBackingAmount: .amt(85000, .usdc),
                            feeAmount: .amt(0.00040016, .cbbtc),  // fee = exposureAmount * 0.0004 / 0.9996
                            feeRecipient: .stax,
                            market: .morpho(.cbbtc, .usdc),
                            network: .ethereum,
                            executionType: .immediate
                        ),
                    ),
                    [
                        Charter.ActionContext.loopLong(
                            Charter.ActionContext.LoopLongActionContext(
                                backingAssetSymbol: "USDC",
                                backingToken: EthAddress(
                                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                ),
                                backingTokenPrice: Number("1e8"),
                                maxSwapBackingAmount: Number("85000e6"),
                                maxProvidedBackingAmount: Number("20000e6"),
                                chainId: Number("1"),
                                isIncrease: false,
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
                                feeAmount: Number("0.00040016e8"),
                                feeAssetSymbol: "cbBTC",
                                feeToken: EthAddress(
                                    "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
                                ),
                                feeTokenPrice: Number("100000e8")
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice loops long on WBTC using max USDC")
    func testLoopLongMaxSuccess() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(20010, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(1, .cbbtc),
                    providedBackingAmount: .max(.usdc),
                    maxSwapBackingAmount: .amt(85000, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .loopLong(
                            exposureAmount: .amt(1, .cbbtc),
                            // Max amount uses all available balance
                            providedBackingAmount: .amt(20010, .usdc),
                            cappedMax: true,
                            maxSwapBackingAmount: .amt(85000, .usdc),
                            feeAmount: .amt(0.00040016, .cbbtc),  // fee = exposureAmount * 0.0004 / 0.9996
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

    @Test("Alice tries to loop long with max exposure amount (invalid)")
    func testLoopLongInvalidMaxExposure() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(20010, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .max(.cbbtc),
                    providedBackingAmount: .amt(20000, .usdc),
                    maxSwapBackingAmount: .amt(85000, .usdc),
                    on: .ethereum
                ),
                expect: .failure(.error("Loop long does not support max exposure amount"))
            )
        )
    }

    @Test("Alice loops long cbETH using ETH, which is auto-wrapped to WETH")
    func testLoopLongWithAutoWrapper() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .eth), .worldChain),
                    .tokenBalance(.alice, .amt(1, .usdc), .worldChain),
                    .quote(.basic),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .amt(0.04, .wbtc),
                    providedBackingAmount: .amt(1, .weth),
                    maxSwapBackingAmount: .amt(2, .weth),
                    on: .worldChain
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .loopLong(
                                    exposureAmount: .amt(0.04, .wbtc),
                                    providedBackingAmount: .amt(1, .weth),
                                    cappedMax: false,
                                    maxSwapBackingAmount: .amt(2, .weth),
                                    feeAmount: .amt(0.000016, .wbtc),  // fee = exposureAmount * 0.0004 / 0.9996
                                    feeRecipient: .stax,
                                    market: .morpho(.wbtc, .weth),
                                    network: .worldChain
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("480"),
                                        amount: Number("1e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
                                    )
                                ),
                                Charter.ActionContext.loopLong(
                                    Charter.ActionContext.LoopLongActionContext(
                                        backingAssetSymbol: "WETH",
                                        backingToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        backingTokenPrice: Number("4000e8"),
                                        maxSwapBackingAmount: Number("2e18"),
                                        maxProvidedBackingAmount: Number("1e18"),
                                        chainId: Number("480"),
                                        isIncrease: false,
                                        exposureAmount: Number("0.04e8"),
                                        exposureAssetSymbol: "WBTC",
                                        exposureToken: EthAddress(
                                            "0x03c7054bcb39f7b2e5b2c7acb37583e32d70cfa3"
                                        ),
                                        exposureTokenPrice: Number("100000e8"),
                                        swapVenue: "UNISWAP_V3",
                                        borrowVenue: "MORPHO_BLUE",
                                        borrowMarketId: Hex(
                                            "0x19c682c3a37025075074cefea866fbe54656abc0fb6a7355b62a53f45b959abf"
                                        ),
                                        feeAmount: Number("0.00001600e8"),
                                        feeAssetSymbol: "WBTC",
                                        feeToken: EthAddress(
                                            "0x03c7054bcb39f7b2e5b2c7acb37583e32d70cfa3"
                                        ),
                                        feeTokenPrice: Number("100000e8")
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice loops long cbETH using USDC on Base via bridge")
    func testLoopsLongByBridgingUSDC() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(21000, .usdc), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbeth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(1, .cbeth),
                    providedBackingAmount: .amt(20000, .usdc),
                    maxSwapBackingAmount: .amt(85000, .usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .arbitrum,
                            destinationNetwork: .base,
                            inputTokenAmount: .amt(20203.030304, .usdc),
                            outputTokenAmount: .amt(20000, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .loopLong(
                            exposureAmount: .amt(1, .cbeth),
                            providedBackingAmount: .amt(20000, .usdc),
                            cappedMax: false,
                            maxSwapBackingAmount: .amt(85000, .usdc),
                            feeAmount: .amt(0.00040016006402561, .cbeth),  // fee = exposureAmount * 0.0004 / 0.9996
                            feeRecipient: .stax,
                            market: .morpho(.cbeth, .usdc),
                            network: .base,
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("42161"),
                                destinationChainId: Number("8453"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("20203.030304e6"),
                                outputAmount: Number("20000e6"),
                                price: Number("1e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                )
                            )
                        ),
                        .loopLong(
                            Charter.ActionContext.LoopLongActionContext(
                                backingAssetSymbol: "USDC",
                                backingToken: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                ),
                                backingTokenPrice: Number("1e8"),
                                maxSwapBackingAmount: Number("85000e6"),
                                maxProvidedBackingAmount: Number("20000e6"),
                                chainId: Number("8453"),
                                isIncrease: false,
                                exposureAmount: Number("1e18"),
                                exposureAssetSymbol: "cbETH",
                                exposureToken: EthAddress(
                                    "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22"
                                ),
                                exposureTokenPrice: Number("4000e8"),
                                swapVenue: "UNISWAP_V3",
                                borrowVenue: "MORPHO_BLUE",
                                borrowMarketId: Hex(
                                    "0x1c21c59df9db44bf6f645d854ee710a8ca17b479451447e9f56758aee10a2fad"
                                ),
                                feeAmount: Number("0.00040016006402561e18"),
                                feeAssetSymbol: "cbETH",
                                feeToken: EthAddress(
                                    "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22"
                                ),
                                feeTokenPrice: Number("4000e8")
                            )
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice tries to loop long from a Morpho market that does not exist (WETH/USDC)")
    func testLoopLongInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(1, .weth),
                    providedBackingAmount: .amt(1, .usdc),
                    maxSwapBackingAmount: .amt(1, .usdc),
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

    @Test("Alice tries to loop long with a backing token that she does not have")
    func testLoopLongFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .cbbtc), .ethereum),
                    .quote(.basic),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(1, .cbbtc),
                    providedBackingAmount: .amt(1, .usdc),
                    maxSwapBackingAmount: .amt(1, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 1000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(1000000), max: 0)"))
            )
        )
    }

    @Test("Alice loops long with zero backing amount - increase exposure only")
    func testLoopLongZeroBacking() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                ],
                when: .loopLong(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .cbbtc,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(0.0001, .cbbtc),
                    providedBackingAmount: .amt(0, .usdc),
                    maxSwapBackingAmount: .amt(10, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .loopLong(
                            exposureAmount: .amt(0.0001, .cbbtc),
                            providedBackingAmount: .amt(0, .usdc),
                            cappedMax: false,
                            maxSwapBackingAmount: .amt(10, .usdc),
                            feeAmount: .amt(0.00000004, .cbbtc),
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
}
