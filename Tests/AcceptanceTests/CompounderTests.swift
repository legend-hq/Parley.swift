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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "WETH"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(3840, .usdc),
                        swapQuoteSellAmount: .amt(1, .weth),
                        swapQuoteBuyAmount: .amt(3840, .usdc),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "WETH"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(3840, .usdc),
                        swapQuoteSellAmount: .amt(1, .weth),
                        swapQuoteBuyAmount: .amt(3840, .usdc),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "WETH"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(1920, .usdc),
                        swapQuoteSellAmount: .amt(0.5, .weth),
                        swapQuoteBuyAmount: .amt(1920, .usdc),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
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
                    .acrossQuote(.amt(10, .usdc), 0.01),
                ],
                when: .compounder(
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.0256, .weth),
                        swapQuoteSellAmount: .amt(120, .usdc),
                        swapQuoteBuyAmount: .amt(0.0256, .weth),
                        on: .base
                    ),
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
                                .quotePay(
                                    payment: .amt(0.1, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(39.8, .usdc),
                                    outputTokenAmount: .amt(29.402, .usdc),
                                    cappedMax: false
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
                                    sellAmount: .amt(109.382, .usdc),
                                    buyAmount: TokenAmount(fromWei: Number("23334826666666666"), ofToken: .weth),
                                    feeAmount: TokenAmount(fromWei: Number("35002239999999"), ofToken: .weth),
                                    feeRecipient: .stax,
                                    cappedMax: true,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 109.382 * (0.0256/120) * 1.015 - 0.000005 = 0.02367985 (rate scaled to actual flow)
                                .supplyToComet(
                                    tokenAmount: TokenAmount(
                                        fromWei: Number("23679849066666666"),
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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .bob,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.weth),
                        buyAmount: .amt(100, .usdc),
                        swapQuoteSellAmount: .amt(0.025, .weth),
                        swapQuoteBuyAmount: .amt(100, .usdc),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
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
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .amt(0.01, .weth),
                        on: .base
                    )
                ),
                expect: .failure(.error("Compounder requires supply amount to be .max"))
            )
        )
    }


    @Test("Alice compounds with rewards on different chain but no bridge fails")
    func testCompounderRewardsNoBridgeFails() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometReward(.alice, .amt(100, .usdc), .cusdcv3, .usdcReward, .ethereum),
                    .quote(.basic),
                ],
                when: .compounder(
                    claim: (from: .alice, assetSymbol: "USDC"),
                    swap: (
                        from: .alice,
                        sellAmount: .max(.usdc),
                        buyAmount: .amt(0.025, .weth),
                        swapQuoteSellAmount: .amt(100, .usdc),
                        swapQuoteBuyAmount: .amt(0.025, .weth),
                        on: .base
                    ),
                    supply: (
                        from: .alice, market: .comet(.cwethv3), amount: .max(.weth),
                        on: .base
                    )
                ),
                expect: .failure(.error("insufficientResources(target: .max, max: 0)"))
            )
        )
    }
}
