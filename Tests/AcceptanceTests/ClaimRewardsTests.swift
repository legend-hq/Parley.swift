import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Testing

@testable import Charter

@Suite("Claim Rewards Tests")
struct ClaimRewardsTests {

    // MARK: - Comet Protocol Tests

    @Test("Alice claims USDC rewards from Comet only, paying with QuotePay")
    func testCometClaimRewardsUSDCWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(2, .usdc), .base),
                    .cometReward(.alice, .amt(10, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(1, .weth), .cwethv3, .wethReward, .base),
                    .quote(.basic),
                ],
                when: .claimRewards(
                    from: .alice,
                    assetSymbol: "USDC"
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimCometRewards(
                                    cometRewards: [.usdcReward],
                                    comets: [.cusdcv3],
                                    accounts: [.alice],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometClaimRewards(
                                    Charter.ActionContext.CometClaimRewardsActionContext(
                                        amounts: [Number("10e6")],
                                        assetSymbols: ["USDC"],
                                        chainId: Number("8453"),
                                        prices: [Number("1e8")],
                                        tokens: [
                                            EthAddress(
                                                "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.02e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice claims WETH rewards from Comet only when both USDC and WETH available")
    func testCometClaimRewardsWETHOnly() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.01, .weth), .base),
                    .cometReward(.alice, .amt(80, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(3, .weth), .cwethv3, .wethReward, .base),
                    .prices([.usdc: 1.0, .weth: 4000.0]),
                    .quote(.basic),
                ],
                when: .claimRewards(from: .alice, assetSymbol: "WETH"),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimCometRewards(
                                    cometRewards: [.wethReward],
                                    comets: [.cwethv3],
                                    accounts: [.alice],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometClaimRewards(
                                    Charter.ActionContext.CometClaimRewardsActionContext(
                                        amounts: [Number("3e18")],
                                        assetSymbols: ["WETH"],
                                        chainId: Number("8453"),
                                        prices: [Number("4000e8")],
                                        tokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000005e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        price: Number("4000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice claims USDC rewards from Comet, paying with claimed rewards")
    func testCometClaimRewardsPayFromWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(10, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [.usdc: 1.0],
                            fees: [
                                .base: 1.0
                            ]
                        )
                    ),
                ],
                when: .claimRewards(
                    from: .alice,
                    assetSymbol: "USDC"
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimCometRewards(
                                    cometRewards: [.usdcReward],
                                    comets: [.cusdcv3],
                                    accounts: [.alice],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(1, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometClaimRewards(
                                    Charter.ActionContext.CometClaimRewardsActionContext(
                                        amounts: [Number("10e6")],
                                        assetSymbols: ["USDC"],
                                        chainId: Number("8453"),
                                        prices: [Number("1e8")],
                                        tokens: [
                                            EthAddress(
                                                "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice fails to claim Comet rewards when cost is too high")
    func testCometClaimRewardsCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(0.01, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [.usdc: 1.0],
                            fees: [
                                .base: 1.0
                            ]
                        )
                    ),
                ],
                when: .claimRewards(
                    from: .alice,
                    assetSymbol: "USDC"
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 1000000))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }

    // MARK: - Morpho Protocol Tests

    @Test("Alice claims USDC rewards from Morpho only, paying with QuotePay")
    func testMorphoClaimRewardsUSDCWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.5, .usdc), .base),
                    .morphoReward(.alice, .amt(1, .weth), .distributor, .validProof1, .ethereum),
                    .morphoReward(.alice, .amt(0.1, .wbtc), .distributor, .validProof2, .ethereum),
                    .morphoReward(.alice, .amt(10, .usdc), .distributor, .validProof3, .base),
                    .quote(.basic),
                ],
                when: .claimRewards(
                    from: .alice,
                    assetSymbol: "USDC"
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimMorphoRewards(
                                    distributors: [.distributor],
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(10, .usdc)],
                                    proofs: [.validProof3],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoClaimRewards(
                                    Charter.ActionContext.MorphoClaimRewardsActionContext(
                                        amounts: [Number("10e6")],
                                        assetSymbols: ["USDC"],
                                        chainId: Number("8453"),
                                        prices: [Number("1e8")],
                                        tokens: [
                                            EthAddress(
                                                "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.02e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice claims WETH rewards from Morpho when multiple assets available")
    func testMorphoClaimRewardsWETHOnly() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(2, .usdc), .ethereum),
                    .morphoReward(.alice, .amt(1, .weth), .distributor, .validProof1, .ethereum),
                    .morphoReward(.alice, .amt(50, .usdc), .distributor, .validProof2, .ethereum),
                    .quote(.basic),
                ],
                when: .claimRewards(from: .alice, assetSymbol: "WETH"),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimMorphoRewards(
                                    distributors: [.distributor],
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(1, .weth)],
                                    proofs: [.validProof1],
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoClaimRewards(
                                    Charter.ActionContext.MorphoClaimRewardsActionContext(
                                        amounts: [Number("1e18")],
                                        assetSymbols: ["WETH"],
                                        chainId: Number("1"),
                                        prices: [Number("4000e8")],
                                        tokens: [
                                            EthAddress(
                                                "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000025e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        price: Number("4000e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice claims USDC rewards from both Morpho and Merkl distributors")
    func testMorphoMerklClaimRewardsUSDC() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .morphoReward(
                        .alice,
                        .amt(0.1, .wbtc),
                        .merklDistributor,
                        .validProof2,
                        .ethereum
                    ),
                    .morphoReward(.alice, .amt(10, .usdc), .merklDistributor, .validProof3, .base),
                    .morphoReward(.alice, .amt(5, .usdc), .distributor, .validProof1, .ethereum),
                    .quote(.basic),
                ],
                when: .claimRewards(
                    from: .alice,
                    assetSymbol: "USDC"
                ),
                expect: .successWithActions(
                    .multi([
                        // Ethereum USDC claim from regular Morpho distributor with QuotePay
                        .multicall(
                            [
                                .claimMorphoRewards(
                                    distributors: [.distributor],
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(5, .usdc)],
                                    proofs: [.validProof1],
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.10, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        ),
                        // Base USDC claim from Merkl with QuotePay
                        .multicall(
                            [
                                .claimMerklRewards(
                                    distributor: .merklDistributor,
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(10, .usdc)],
                                    proofs: [.validProof3],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoClaimRewards(
                                    Charter.ActionContext.MorphoClaimRewardsActionContext(
                                        amounts: [Number("5e6")],
                                        assetSymbols: ["USDC"],
                                        chainId: Number("1"),
                                        prices: [Number("1e8")],
                                        tokens: [
                                            EthAddress(
                                                "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.morphoClaimRewards(
                                    Charter.ActionContext.MorphoClaimRewardsActionContext(
                                        amounts: [Number("10e6")],
                                        assetSymbols: ["USDC"],
                                        chainId: Number("8453"),
                                        prices: [Number("1e8")],
                                        tokens: [
                                            EthAddress(
                                                "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.02e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice claims Morpho rewards paying with claimed rewards")
    func testMorphoClaimRewardsPayFromWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoReward(.alice, .amt(10, .usdc), .distributor, .validProof1, .ethereum),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [.usdc: 1.0],
                            fees: [
                                .ethereum: 0.5
                            ]
                        )
                    ),
                ],
                when: .claimRewards(
                    from: .alice,
                    assetSymbol: "USDC"
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimMorphoRewards(
                                    distributors: [.distributor],
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(10, .usdc)],
                                    proofs: [.validProof1],
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.5, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoClaimRewards(
                                    Charter.ActionContext.MorphoClaimRewardsActionContext(
                                        amounts: [Number("10e6")],
                                        assetSymbols: ["USDC"],
                                        chainId: Number("1"),
                                        prices: [Number("1e8")],
                                        tokens: [
                                            EthAddress(
                                                "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                            )
                                        ]
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
                                    )
                                ),
                            ]
                        )
                    ]
                )
            )
        )
    }

    @Test("Alice fails to claim Morpho rewards when cost is too high")
    func testMorphoClaimRewardsCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoReward(.alice, .amt(0.4, .usdc), .distributor, .validProof1, .ethereum),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: [.usdc: 1.0],
                            fees: [
                                .ethereum: 0.5
                            ]
                        )
                    ),
                ],
                when: .claimRewards(
                    from: .alice,
                    assetSymbol: "USDC"
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 500000))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }

    // MARK: - Mixed Protocol Tests

    @Test("Alice claims USDC from both Comet and Morpho on same network")
    func testMixedProtocolsSameAssetSameNetwork() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .cometReward(.alice, .amt(10, .usdc), .cusdcv3, .usdcReward, .base),
                    .morphoReward(.alice, .amt(5, .usdc), .distributor, .validProof1, .base),
                    .prices([.usdc: 1.0]),
                    .quote(.basic),
                ],
                when: .claimRewards(from: .alice, assetSymbol: "USDC"),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimMorphoRewards(
                                    distributors: [.distributor],
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(5, .usdc)],
                                    proofs: [.validProof1],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .claimCometRewards(
                                    cometRewards: [.usdcReward],
                                    comets: [.cusdcv3],
                                    accounts: [.alice],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    nil
                )
            )
        )
    }

    @Test("Alice claims WETH from Comet on Base and Morpho on Ethereum")
    func testMixedProtocolsSameAssetDifferentNetworks() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.01, .weth), .base),
                    .tokenBalance(.alice, .amt(0.01, .weth), .ethereum),
                    .cometReward(.alice, .amt(2, .weth), .cwethv3, .wethReward, .base),
                    .morphoReward(.alice, .amt(3, .weth), .distributor, .validProof1, .ethereum),
                    .prices([.weth: 4000.0]),
                    .quote(.basic),
                ],
                when: .claimRewards(from: .alice, assetSymbol: "WETH"),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .claimMorphoRewards(
                                    distributors: [.distributor],
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(3, .weth)],
                                    proofs: [.validProof1],
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .claimCometRewards(
                                    cometRewards: [.wethReward],
                                    comets: [.cwethv3],
                                    accounts: [.alice],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        ),
                    ]),
                    nil
                )
            )
        )
    }

    // MARK: - Edge Cases

    @Test("Alice claims no rewards when requesting asset with no rewards")
    func testNoRewardsForSpecifiedAsset() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .base),
                    .cometReward(.alice, .amt(5, .usdc), .cusdcv3, .usdcReward, .base),
                    .morphoReward(.alice, .amt(2, .usdc), .distributor, .validProof1, .base),
                    .prices([.usdc: 1.0, .weth: 4000.0, .wbtc: 100000.0]),
                    .quote(.basic),
                ],
                when: .claimRewards(from: .alice, assetSymbol: "WBTC"),  // No WBTC rewards available
                expect: .failure(.noClaimableRewardsFound(symbol: "WBTC"))
            )
        )
    }

    @Test("Case insensitive asset symbol claiming")
    func testCaseInsensitiveAssetSymbol() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .cometReward(.alice, .amt(10, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .claimRewards(from: .alice, assetSymbol: "usdc"),  // lowercase
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .claimCometRewards(
                                    cometRewards: [.usdcReward],
                                    comets: [.cusdcv3],
                                    accounts: [.alice],
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    nil
                )
            )
        )
    }
}
