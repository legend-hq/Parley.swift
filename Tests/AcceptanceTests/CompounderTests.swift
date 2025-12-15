@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Compounder Tests")
struct CompounderTests {

    // MARK: - Success Cases

    @Test("Alice compounds USDC rewards to WETH and supplies to Comet")
    func testCompounderCometUsdcToWeth() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.01, .weth), .base),
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(99.98, .usdc),
                                    buyAmount: .amt(0.024995, .weth),
                                    feeAmount: .amt(0.0000374925, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 99.98 * (0.025/100) * 1.015 - 0.000005 = 0.025364925 (rate scaled to actual flow)
                                .supplyToComet(
                                    tokenAmount: .amt(0.025364925, .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
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
                                        amounts: [Number("100e6")],
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
                                        amount: Number("20000"),
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
                                Charter.ActionContext.swap(
                                    Charter.ActionContext.SwapActionContext(
                                        chainId: Number("8453"),
                                        feeAmounts: [
                                            Number("37492500000000"),
                                            Number("249950000000000"),
                                        ],
                                        feeAssetSymbols: ["WETH", "WETH"],
                                        feeTokens: [
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                            EthAddress(
                                                "0x4200000000000000000000000000000000000006"
                                            ),
                                        ],
                                        feeTokenPrices: [
                                            Number("4000e8"), Number("4000e8"),
                                        ],
                                        feeDescriptions: ["LEGEND", "ZERO_EX"],
                                        inputAmount: Number("99980000"),
                                        inputAssetSymbol: "USDC",
                                        inputToken: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        ),
                                        inputTokenPrice: Number("1e8"),
                                        outputAmount: Number("24995000000000000"),
                                        outputAssetSymbol: "WETH",
                                        outputToken: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        outputTokenPrice: Number("4000e8"),
                                        isExactOut: false,
                                        isBuy: true,
                                        isCappedMax: true,
                                        useFiller: true
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("5000000000000"),
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
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("25364925000000000"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        comet: EthAddress(
                                            "0x46e6b214b524310239732d51387075e0e70970bf"
                                        ),
                                        price: Number("4000e8"),
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

    @Test("Alice compounds WETH rewards to USDC and supplies to Morpho vault")
    func testCompounderMorphoWethToUsdc() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .base),
                    .cometReward(.alice, .amt(1, .weth), .cwethv3, .wethReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "WETH")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(3840, .usdc),
                        swapQuoteSellAmount: .amt(1, .weth),
                        swapQuoteBuyAmount: .amt(3840, .usdc),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .morpho(.usdc), amount: .max(.usdc),
                        on: .base
                    )
                ),
                expect: .success(
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(0.999995, .weth),
                                    buyAmount: TokenAmount(fromWei: Number("3839980800"), ofToken: .usdc),
                                    feeAmount: TokenAmount(fromWei: Number("5759971"), ofToken: .usdc),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 0.999995 * 3840 * 1.015 - 0.02 (rate scaled to actual flow)
                                .supplyToMorphoVault(
                                    tokenAmount: TokenAmount(fromWei: Number("3897560512"), ofToken: .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice compounds WETH rewards to USDC and supplies to Aave")
    func testCompounderAaveWethToUsdc() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .base),
                    .cometReward(.alice, .amt(1, .weth), .cwethv3, .wethReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "WETH")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(3840, .usdc),
                        swapQuoteSellAmount: .amt(1, .weth),
                        swapQuoteBuyAmount: .amt(3840, .usdc),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .aave(.baseV3), amount: .max(.usdc),
                        on: .base
                    )
                ),
                expect: .success(
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(0.999995, .weth),
                                    buyAmount: TokenAmount(fromWei: Number("3839980800"), ofToken: .usdc),
                                    feeAmount: TokenAmount(fromWei: Number("5759971"), ofToken: .usdc),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 0.999995 * 3840 * 1.015 - 0.02 (rate scaled to actual flow)
                                .supplyToAave(
                                    tokenAmount: TokenAmount(fromWei: Number("3897560512"), ofToken: .usdc),
                                    pool: .baseV3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice compounds WETH rewards to USDC and supplies to Comet USDC market")
    func testCompounderWethToUsdcToComet() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(5, .usdc), .base),
                    .cometReward(.alice, .amt(0.5, .weth), .cwethv3, .wethReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "WETH")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(1920, .usdc),
                        swapQuoteSellAmount: .amt(0.5, .weth),
                        swapQuoteBuyAmount: .amt(1920, .usdc),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                        on: .base
                    )
                ),
                expect: .success(
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(0.499995, .weth),
                                    buyAmount: TokenAmount(fromWei: Number("1919980800"), ofToken: .usdc),
                                    feeAmount: TokenAmount(fromWei: Number("2879971"), ofToken: .usdc),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 0.499995 * 3840 * 1.015 - 0.02 (rate scaled to actual flow)
                                .supplyToComet(
                                    tokenAmount: TokenAmount(fromWei: Number("1948760512"), ofToken: .usdc),
                                    market: .cusdcv3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice compounds multiple rewards from same chain (Comet + Morpho)")
    func testCompounderMultipleRewardsSameChain() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(5, .usdc), .base),
                    .cometReward(.alice, .amt(50, .usdc), .cusdcv3, .usdcReward, .base),
                    .morphoReward(.alice, .amt(50, .usdc), .distributor, .validProof2, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .claimMorphoRewards(
                                    distributors: [.distributor],
                                    accounts: [.alice],
                                    rewardsClaimable: [.amt(50, .usdc)],
                                    proofs: [.validProof2],
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(99.96, .usdc),
                                    buyAmount: .amt(0.02499, .weth),
                                    feeAmount: .amt(0.000037485, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 99.96 * (0.025/100) * 1.015 - 0.000005 = 0.02535985 (rate scaled to actual flow)
                                .supplyToComet(
                                    tokenAmount: .amt(0.02535985, .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice compounds rewards from multiple chains with bridge")
    func testCompounderMultipleRewardsMultiChain() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(80, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(40, .usdc), .cusdcv3, .usdcReward, .ethereum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.001, .weth), 0.01),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [
                        // Swap on Base for 80 USDC rewards
                        (
                            from: .alice,
                            sellAmount: .max(.usdc),
                            buyAmount: .amt(0.017066, .weth),
                            swapQuoteSellAmount: .amt(80, .usdc),
                            swapQuoteBuyAmount: .amt(0.017066, .weth),
                            on: .base
                        ),
                        // Swap on Ethereum for 40 USDC rewards (output bridges to Base)
                        (
                            from: .alice,
                            sellAmount: .max(.usdc),
                            buyAmount: .amt(0.008533, .weth),
                            swapQuoteSellAmount: .amt(40, .usdc),
                            swapQuoteBuyAmount: .amt(0.008533, .weth),
                            on: .ethereum
                        ),
                    ],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .success(
                    .multi([
                        // Ethereum operation: claim → swap → bridge WETH to Base
                        .multicall(
                            [
                                .claimCometRewards(
                                    cometRewards: [.usdcReward],
                                    comets: [.cusdcv3],
                                    accounts: [.alice],
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.1, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(39.9, .usdc),
                                    buyAmount: TokenAmount(fromWei: Number("8511667500000000"), ofToken: .weth),
                                    feeAmount: TokenAmount(fromWei: Number("12767501250000"), ofToken: .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 39.9 * (0.008533/40) * 1.015 - 0.000025 = ~0.008614 WETH (rate scaled to actual flow)
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(fromWei: Number("8614342512500001"), ofToken: .weth),
                                    outputTokenAmount: TokenAmount(fromWei: Number("7528199087375000"), ofToken: .weth),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        // Base operation: claim → swap → wrap bridged ETH → supply combined WETH to Comet
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(79.98, .usdc),
                                    buyAmount: TokenAmount(fromWei: Number("17061733500000001"), ofToken: .weth),
                                    feeAmount: TokenAmount(fromWei: Number("25592600250000"), ofToken: .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 79.98 * (0.017066/80) * 1.015 - 0.000005 (quote pay) + 0.007528 (bridged) = ~0.02484 WETH
                                .supplyToComet(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("24840858589875002"),
                                        ofToken: .weth
                                    ),
                                    market: .cwethv3,
                                    cappedMax: true,
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

    @Test("Alice compounds multiple different rewards (USDC and WETH) with USDC→WETH swap, WETH flows directly")
    func testCompounderMultipleClaimsMultipleSwaps() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(5, .usdc), .base),
                    .cometReward(.alice, .amt(50, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(0.5, .weth), .cwethv3, .wethReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [
                        (from: .alice, assetSymbol: "USDC"),
                        (from: .alice, assetSymbol: "WETH"),
                    ],
                    swaps: [
                        (
                            from: .alice,
                            sellAmount: .max(.usdc),
                            buyAmount: .amt(0.0125, .weth),
                            swapQuoteSellAmount: .amt(50, .usdc),
                            swapQuoteBuyAmount: .amt(0.0125, .weth),
                            on: .base
                        ),
                        (
                            from: .alice,
                            sellAmount: .max(.weth),
                            buyAmount: .amt(0.5075, .weth),
                            swapQuoteSellAmount: .amt(0.5, .weth),
                            swapQuoteBuyAmount: .amt(0.5075, .weth),
                            on: .base
                        ),
                    ],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .success(
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(49.98, .usdc),
                                    buyAmount: .amt(0.012495, .weth),
                                    feeAmount: .amt(0.0000187425, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToComet(
                                    tokenAmount: TokenAmount(fromWei: Number("512672425000000000"), ofToken: .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice compounds USDC rewards from multiple chains with swaps on each chain")
    func testCompounderMultiChainSwaps() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(80, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(40, .usdc), .cusdcv3, .usdcReward, .ethereum),
                    .quote(.basic),
                    .acrossQuote(.amt(10, .weth), 0.01),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [
                        (
                            from: .alice,
                            sellAmount: .max(.usdc),
                            buyAmount: .amt(0.02, .weth),
                            swapQuoteSellAmount: .amt(80, .usdc),
                            swapQuoteBuyAmount: .amt(0.02, .weth),
                            on: .base
                        ),
                        (
                            from: .alice,
                            sellAmount: .max(.usdc),
                            buyAmount: .amt(0.01, .weth),
                            swapQuoteSellAmount: .amt(40, .usdc),
                            swapQuoteBuyAmount: .amt(0.01, .weth),
                            on: .ethereum
                        ),
                    ],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .claimCometRewards(
                                    cometRewards: [.usdcReward],
                                    comets: [.cusdcv3],
                                    accounts: [.alice],
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.1, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(39.9, .usdc),
                                    buyAmount: TokenAmount(fromWei: Number("9975000000000000"), ofToken: .weth),
                                    feeAmount: TokenAmount(fromWei: Number("14962500000000"), ofToken: .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: TokenAmount(fromWei: Number("25000000000000"), ofToken: .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(fromWei: Number("10099625000000000"), ofToken: .weth),
                                    outputTokenAmount: TokenAmount(fromWei: Number("0"), ofToken: .weth),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(79.98, .usdc),
                                    buyAmount: TokenAmount(fromWei: Number("19995000000000000"), ofToken: .weth),
                                    feeAmount: TokenAmount(fromWei: Number("29992500000000"), ofToken: .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToComet(
                                    tokenAmount: TokenAmount(fromWei: Number("20289925000000000"), ofToken: .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
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

    @Test("Alice compounds with capped max only uses swapped amount, not existing balance")
    func testCompounderCappedMaxExcludesExistingBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .weth), .base),
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .success(
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
                                .swap(
                                    filler: .filler,
                                    sellAmount: .amt(99.98, .usdc),
                                    buyAmount: .amt(0.024995, .weth),
                                    feeAmount: .amt(0.0000374925, .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 99.98 * (0.025/100) * 1.015 - 0.000005 = 0.025364925 (rate scaled to actual flow)
                                .supplyToComet(
                                    tokenAmount: .amt(0.025364925, .weth),
                                    market: .cwethv3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    // MARK: - Failure Cases

    @Test("Alice compounds with different senders fails")
    func testCompounderDifferentSendersFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .bob,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .failure(.compounderSenderMismatch)
            )
        )
    }

    @Test("Alice compounds with mismatched swap sell token fails")
    func testCompounderSwapSellMismatchFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(100, .usdc),
                        swapQuoteSellAmount: .amt(0.025, .weth),
                        swapQuoteBuyAmount: .amt(100, .usdc),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                        on: .base
                    )
                ),
                expect: .failure(.compounderTokenMismatch(expected: "USDC", actual: "WETH"))
            )
        )
    }

    @Test("Alice compounds with mismatched supply asset fails")
    func testCompounderSupplyMismatchFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                        on: .base
                    )
                ),
                expect: .failure(.compounderTokenMismatch(expected: "USDC", actual: "WETH"))
            )
        )
    }

    @Test("Alice compounds with no claimable rewards fails")
    func testCompounderNoClaimableRewardsFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .failure(.noClaimableRewardsFound(symbol: "USDC"))
            )
        )
    }

    @Test("Alice compounds with non-max supply amount fails")
    func testCompounderNonMaxSupplyFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .amt(0.01, .weth),
                        on: .base
                    )
                ),
                expect: .failure(.error("Compounder requires supply amount to be .max"))
            )
        )
    }

    @Test("Alice compounds with rewards on different chain than swap fails")
    func testCompounderRewardsDifferentChainFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .ethereum),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .failure(.error("All rewards must be on the same chain as their corresponding swap. Reward for USDC on Ethereum has no matching swap."))
            )
        )
    }

    @Test("Alice compounds cross-chain with non-bridgeable supply asset fails")
    func testCompounderCrossChainNonBridgeableFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.001, .cbbtc),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.001, .cbbtc),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .morpho(.wbtc), amount: .max(.cbbtc),
                        on: .ethereum
                    )
                ),
                expect: .failure(.error("Cross-chain compounding into cbBTC is not supported. Only bridgeable assets (WETH, ETH, USDC) are supported for cross-chain supply."))
            )
        )
    }

    @Test("Alice compounds with no swap intent fails")
    func testCompounderNoSwapIntentFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [(from: .alice, assetSymbol: "USDC")],
                    swaps: [],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .failure(.error("Compounder requires at least one swap intent"))
            )
        )
    }

    @Test("Alice compounds with no claim intent fails")
    func testCompounderNoClaimIntentFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .failure(.error("Compounder requires at least one claim intent"))
            )
        )
    }

    @Test("Alice compounds with claim but no matching swap fails")
    func testCompounderClaimWithoutMatchingSwapFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .base),
                    .cometReward(.alice, .amt(0.5, .weth), .cwethv3, .wethReward, .base),
                    .quote(.basic),
                ],
                when: .compounder(
                    claims: [
                        (from: .alice, assetSymbol: "USDC"),
                        (from: .alice, assetSymbol: "WETH"),
                    ],
                    swaps: [(
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    )],
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .failure(.error("No swap intent found for claimed reward symbol: WETH"))
            )
        )
    }
}
