@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Loop Short Tests")
struct LoopShortTests {
    @Test("Alice loops short WETH using WBTC")
    func testLoopShortSuccess() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .worldChain),
                    .tokenBalance(.alice, .amt(0.5, .wbtc), .worldChain),
                    .quote(.basic),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .amt(20, .weth),
                    providedBackingAmount: .amt(0.5, .wbtc),
                    minSwapBackingAmount: .amt(1, .wbtc),
                    on: .worldChain
                ),
                expect: .successWithActions(
                    .single(
                        .loopShort(
                            exposureAmount: .amt(20, .weth),
                            providedBackingAmount: .amt(0.5, .wbtc),
                            cappedMax: false,
                            minSwapBackingAmount: .amt(1, .wbtc),
                            feeAmount: .amt(0.0004, .wbtc),
                            feeRecipient: .stax,
                            market: .morpho(.wbtc, .weth),
                            network: .worldChain,
                            executionType: .immediate
                        ),
                    ),
                    [
                        Charter.ActionContext.loopShort(
                            Charter.ActionContext.LoopShortActionContext(
                                backingAssetSymbol: "WBTC",
                                backingToken: EthAddress(
                                    "0x03c7054bcb39f7b2e5b2c7acb37583e32d70cfa3"
                                ),
                                backingTokenPrice: Number("100000e8"),
                                minSwapBackingAmount: Number("1e8"),
                                providedBackingAmount: Number("0.5e8"),
                                chainId: Number("480"),
                                isIncrease: false,
                                exposureAmount: Number("20e18"),
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
                                feeAmount: Number("0.00040000e8"),
                                feeAssetSymbol: "WBTC",
                                feeToken: EthAddress(
                                    "0x03c7054bcb39f7b2e5b2c7acb37583e32d70cfa3"
                                ),
                                feeTokenPrice: Number("100000e8")
                            )
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice loops short WETH using max WBTC")
    func testLoopShortMaxSuccess() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .worldChain),
                    .tokenBalance(.alice, .amt(0.5, .wbtc), .worldChain),
                    .quote(.basic),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .amt(20, .weth),
                    providedBackingAmount: .max(.wbtc),
                    minSwapBackingAmount: .amt(1, .wbtc),
                    on: .worldChain
                ),
                expect: .success(
                    .single(
                        .loopShort(
                            exposureAmount: .amt(20, .weth),
                            // Max amount uses all available balance
                            providedBackingAmount: .amt(0.5, .wbtc),
                            cappedMax: true,
                            minSwapBackingAmount: .amt(1, .wbtc),
                            feeAmount: .amt(0.0004, .wbtc),
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

    @Test("Alice tries to loop short with max exposure amount (invalid)")
    func testLoopShortInvalidMaxExposure() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .worldChain),
                    .tokenBalance(.alice, .amt(0.5, .wbtc), .worldChain),
                    .quote(.basic),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .wbtc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .max(.weth),
                    providedBackingAmount: .amt(0.5, .wbtc),
                    minSwapBackingAmount: .amt(1, .wbtc),
                    on: .worldChain
                ),
                expect: .failure(.error("Loop short does not support max exposure amount"))
            )
        )
    }

    @Test("Alice loops short USDC using ETH, which is auto-wrapped to WETH")
    func testLoopShortWithAutoWrapper() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .eth), .base),
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .quote(.basic),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(10000, .usdc),
                    providedBackingAmount: .amt(1, .weth),
                    minSwapBackingAmount: .amt(2, .weth),
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .loopShort(
                                    exposureAmount: .amt(10000, .usdc),
                                    providedBackingAmount: .amt(1, .weth),
                                    cappedMax: false,
                                    minSwapBackingAmount: .amt(2, .weth),
                                    feeAmount: .amt(0.0008, .weth),
                                    feeRecipient: .stax,
                                    market: .morpho(.weth, .usdc),
                                    network: .base
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
                                        chainId: Number("8453"),
                                        amount: Number("1e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
                                    )
                                ),
                                Charter.ActionContext.loopShort(
                                    Charter.ActionContext.LoopShortActionContext(
                                        backingAssetSymbol: "WETH",
                                        backingToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        backingTokenPrice: Number("4000e8"),
                                        minSwapBackingAmount: Number("2e18"),
                                        providedBackingAmount: Number("1e18"),
                                        chainId: Number("8453"),
                                        isIncrease: false,
                                        exposureAmount: Number("10000e6"),
                                        exposureAssetSymbol: "USDC",
                                        exposureToken: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        ),
                                        exposureTokenPrice: Number("1e8"),
                                        swapVenue: "UNISWAP_V3",
                                        borrowVenue: "MORPHO_BLUE",
                                        borrowMarketId: Hex(
                                            "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                                        ),
                                        feeAmount: Number("0.0008e18"),
                                        feeAssetSymbol: "WETH",
                                        feeToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        feeTokenPrice: Number("4000e8")
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice loops short USDC using WETH on Base via bridge")
    func testLoopsShortByBridgingWETH() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .weth), .arbitrum),
                    .tokenBalance(.alice, .amt(1, .usdc), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(10000, .usdc),
                    providedBackingAmount: .amt(0.5, .weth),
                    minSwapBackingAmount: .amt(1, .weth),
                    on: .base
                ),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: TokenAmount(fromWei: "10000000000000", ofToken: .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .arbitrum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(
                                        fromWei: "515151515151515152",
                                        ofToken: .weth
                                    ),
                                    outputTokenAmount: .amt(0.5, .weth),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .loopShort(
                                    exposureAmount: .amt(10000, .usdc),
                                    providedBackingAmount: .amt(0.5, .weth),
                                    cappedMax: false,
                                    minSwapBackingAmount: .amt(1, .weth),
                                    feeAmount: .amt(0.0004, .weth),
                                    feeRecipient: .stax,
                                    market: .morpho(.weth, .usdc),
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice tries to loop short from a Morpho market that does not exist (WETH/USDC)")
    func testLoopShortInvalidMorphoMarketParams() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .usdc,
                        borrowToken: .weth
                    ),
                    exposureAmount: .amt(1, .weth),
                    providedBackingAmount: .amt(1, .usdc),
                    minSwapBackingAmount: .amt(1, .usdc),
                    on: .ethereum
                ),
                // Note: Previously expected .revert(.unknownMorphoMarket(marketId, 1))
                // Now properly returns .morphoMarketNotFound with marketId and network
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

    @Test("Alice tries to loop short with a backing token that she does not have")
    func testLoopShortFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .quote(.basic),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(10000, .usdc),
                    providedBackingAmount: .amt(1, .weth),
                    minSwapBackingAmount: .amt(1, .weth),
                    on: .base
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("WETH", 1000000000000000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(
                    .error("insufficientResources(target: .exact(1000000000000000000), max: 0)")
                )
            )
        )
    }

    @Test("Alice loops short with zero backing amount - increase exposure only")
    func testLoopShortZeroBacking() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                ],
                when: .loopShort(
                    from: .alice,
                    morpho: Morpho(
                        collateralToken: .weth,
                        borrowToken: .usdc
                    ),
                    exposureAmount: .amt(10, .usdc),
                    providedBackingAmount: .amt(0, .weth),
                    minSwapBackingAmount: .amt(0.001, .weth),
                    on: .base
                ),
                expect: .success(
                    .single(
                        .loopShort(
                            exposureAmount: .amt(10, .usdc),
                            providedBackingAmount: .amt(0, .weth),
                            cappedMax: false,
                            minSwapBackingAmount: .amt(0.001, .weth),
                            feeAmount: .amt(0.0000004, .weth),
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
}
