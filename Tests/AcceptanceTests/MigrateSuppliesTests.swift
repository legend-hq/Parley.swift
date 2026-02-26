@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

// TODO: These have a plethora of actual issues
@Suite("Migrate Supplies Tests")
struct MigrateSuppliesTests {
    @Test("Alice migrates USDC from Comet to Aave on same chain, paying with QuotePay")
    func testMigrateFromCometToAaveWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(5, .usdc), .cusdcv3, .base),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (from: .alice, market: .comet(.cusdcv3), amount: .amt(5, .usdc), on: .base)
                    ],
                    supply: (
                        from: .alice, market: .aave(.baseV3), amount: .max(.usdc), on: .base
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(5, .usdc),
                                    market: .cusdcv3,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 5 withdrawn - 0.02 fee - 0.02 fee = 4.96
                                .supplyToAave(
                                    tokenAmount: .amt(4.96, .usdc),
                                    pool: .baseV3,
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
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        comet: EthAddress(
                                            "0xb125e6687d4313864e53df431d5425969c15eb2f"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
                                Charter.ActionContext.aaveSupply(
                                    Charter.ActionContext.AaveSupplyActionContext(
                                        amount: Number("4.96e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("1e8"),
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

    // Regression test for QuarkBuilder bug where max semantics were lost when reordering
    // QuotePay operations during migration, causing incorrect supply amounts to Aave.
    // Mercator uses one quotePay per operation (3 total vs 1 in QuarkBuilder), preserving max semantics.
    // https://github.com/legend-hq/legend-scripts/pull/185
    @Test("Migrate max to Aave paying with withdrawn funds preserves max semantics")
    func testMigrateMaxToAavePayingWithWithdrawnFundsPreservesMax() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(5, .usdc), .cusdcv3, .base),
                    .morphoVaultSupply(.alice, .amt(5, .usdc), .usdc, .base),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .base),
                        (from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .base),
                    ],
                    supply: (from: .alice, market: .aave(.baseV3), amount: .max(.usdc), on: .base),
                    migrateOnlySupplyBalances: true
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .withdrawFromMorphoVault(
                                    tokenAmount: .max(.usdc),
                                    vault: .usdc,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // (5 + 5) * 1.00001 (max buffer) - 0.02 - 0.02 - 0.02 = 9.9401
                                .supplyToAave(
                                    tokenAmount: .amt(9.9401, .usdc),
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

    @Test("Alice migrates USDC from Aave to Comet on same chain, paying with QuotePay")
    func testMigrateFromAaveToCometWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .aaveSupply(.alice, .amt(5, .usdc), .baseV3, .base),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (from: .alice, market: .aave(.baseV3), amount: .amt(5, .usdc), on: .base)
                    ],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .base
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromAave(
                                    tokenAmount: .amt(5, .usdc),
                                    pool: .baseV3,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 5 withdrawn - 0.02 fee - 0.02 fee = 4.96
                                .supplyToComet(
                                    tokenAmount: .amt(4.96, .usdc),
                                    market: .cusdcv3,
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
                                Charter.ActionContext.aaveWithdraw(
                                    Charter.ActionContext.AaveWithdrawActionContext(
                                        amount: Number("5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("4.96e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        comet: EthAddress(
                                            "0xb125e6687d4313864e53df431d5425969c15eb2f"
                                        ),
                                        price: Number("1e8"),
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

    @Test("Alice migrates USDC from Comet to Morpho on same chain, paying with QuotePay")
    func testMigrateFromCometToMorphoWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(5, .usdc), .cusdcv3, .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .amt(5, .usdc),
                            on: .ethereum
                        )
                    ],
                    supply: (
                        from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .ethereum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(5, .usdc),
                                    market: .cusdcv3,
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
                                // 5 withdrawn - 0.1 fee - 0.1 fee = 4.8
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(4.8, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
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
                                Charter.ActionContext.morphoVaultSupply(
                                    Charter.ActionContext.MorphoVaultSupplyActionContext(
                                        amount: Number("4.8e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
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

    @Test("Alice migrates USDC from Morpho to Comet on same chain, paying with QuotePay")
    func testMigrateFromMorphoToCometWithQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoVaultSupply(.alice, .amt(5, .usdc), .usdc, .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .morpho(.usdc), amount: .amt(5, .usdc),
                            on: .ethereum
                        )
                    ],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                        on: .ethereum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromMorphoVault(
                                    tokenAmount: .amt(5, .usdc),
                                    vault: .usdc,
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
                                // 5 withdrawn - 0.1 fee - 0.1 fee = 4.8
                                .supplyToComet(
                                    tokenAmount: .amt(4.8, .usdc),
                                    market: .cusdcv3,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.morphoVaultWithdraw(
                                    Charter.ActionContext.MorphoVaultWithdrawActionContext(
                                        amount: Number("5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
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
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("4.8e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
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

    @Test("Alice migrates USDC and supplies some from existing balance")
    func testMigrateByUsingExistingBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(5, .usdc), .cusdcv3, .ethereum),
                    .tokenBalance(.alice, .amt(5, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .amt(5, .usdc),
                            on: .ethereum
                        )
                    ],
                    supply: (
                        from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .ethereum
                    ),
                    migrateOnlySupplyBalances: false
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(5, .usdc),
                                    market: .cusdcv3,
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
                                // 5 withdrawn + 5 from token balance - 0.1 fee - 0.1 fee = 9.8
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(9.8, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
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
                                Charter.ActionContext.morphoVaultSupply(
                                    Charter.ActionContext.MorphoVaultSupplyActionContext(
                                        amount: Number("9.8e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
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

    @Test("Alice migrates USDC on same chain, paying with withdrawn funds")
    func testMigratePayFromWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(5, .usdc), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .amt(5, .usdc),
                            on: .ethereum
                        )
                    ],
                    supply: (
                        from: .alice, market: .morpho(.usdc), amount: .max(.usdc),
                        on: .ethereum
                    ),
                    migrateOnlySupplyBalances: false
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(5, .usdc),
                                    market: .cusdcv3,
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
                                // 5 withdrawn - 0.1 fee - 0.1 fee = 4.8
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(4.8, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("5e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
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
                                Charter.ActionContext.morphoVaultSupply(
                                    Charter.ActionContext.MorphoVaultSupplyActionContext(
                                        amount: Number("4.8e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        morphoVault: EthAddress(
                                            "0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"
                                        ),
                                        price: Number("1e8"),
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

    @Test(
        "Alice migrates USDC by withdrawing max to supply on same chain, paying with withdrawn funds",
    )
    func testMigrateByWithdrawingMaxAndPayWithWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(5, .usdc), .cusdcv3, .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                            on: .ethereum
                        )
                    ],
                    supply: (
                        from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .ethereum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
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
                                // 5 * 1.00001 (max buffer) - 0.1 - 0.1 = 4.80005
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(4.80005, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test(
        "Alice migrates max USDC to Comet on same chain, paying with withdrawn funds"
    )
    func testMigrateMaxToCometAndPayWithWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .morphoVaultSupply(.alice, .amt(5, .usdc), .usdc, .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .ethereum)
                    ],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .ethereum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .withdrawFromMorphoVault(
                                    tokenAmount: .max(.usdc),
                                    vault: .usdc,
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
                                // 5 * 1.00001 (max buffer) - 0.1 - 0.1 = 4.80005
                                .supplyToComet(
                                    tokenAmount: .amt(4.80005, .usdc),
                                    market: .cusdcv3,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test(
        "Alice migrates max USDC to Morpho on same chain, paying with withdrawn funds"
    )
    func testMigrateMaxToMorphoAndPayWithWithdraw() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(5, .usdc), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                            on: .ethereum
                        )
                    ],
                    supply: (
                        from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .ethereum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
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
                                // 5 * 1.00001 (max buffer) - 0.1 - 0.1 = 4.80005
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(4.80005, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .ethereum
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test(
        "Alice migrates USDC from different chains, bridging withdrawn funds to supply on destination chain"
    )
    func testMigrateFromDifferentChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .ethereum),
                    .morphoVaultSupply(.alice, .amt(10, .usdc), .usdc, .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .amt(10, .usdc),
                            on: .ethereum
                        ),
                        (from: .alice, market: .morpho(.usdc), amount: .amt(10, .usdc), on: .base),
                    ],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                        on: .arbitrum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(10, .usdc),
                                    market: .cusdcv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.1, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: .amt(9.9, .usdc),
                                    outputTokenAmount: .amt(8.801, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .withdrawFromMorphoVault(
                                    tokenAmount: .amt(10, .usdc),
                                    vault: .usdc,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: .amt(9.98, .usdc),
                                    outputTokenAmount: .amt(8.8802, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.04, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 8.801 bridged + 8.8802 bridged - 0.04 fee = 17.6412
                                .supplyToComet(
                                    tokenAmount: .amt(17.6412, .usdc),
                                    market: .cusdcv3,
                                    cappedMax: true,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("10e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("42161"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("9.9e6"),
                                        outputAmount: Number("8.801e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
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
                                Charter.ActionContext.morphoVaultWithdraw(
                                    Charter.ActionContext.MorphoVaultWithdrawActionContext(
                                        amount: Number("10e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        morphoVault: EthAddress(
                                            "0xc1256ae5ff1cf2719d4937adb3bbccab2e00a2ca"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("8453"),
                                        destinationChainId: Number("42161"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("9.98e6"),
                                        outputAmount: Number("8.8802e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.04e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                        )
                                    )
                                ),
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("17.6412e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        comet: EthAddress(
                                            "0x9c4ec768c28520b50860ea7a15bd7213a9ff58bf"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
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

    @Test(
        "Alice migrates max USDC from different chains, bridging withdrawn funds to supply on destination chain"
    )
    func testMigrateMaxFromDifferentChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .ethereum),
                    .morphoVaultSupply(.alice, .amt(10, .usdc), .usdc, .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc),
                            on: .ethereum
                        ),
                        (from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .base),
                    ],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .arbitrum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
                                    network: .ethereum
                                ),
                                .quotePay(
                                    payment: .amt(0.1, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: .amt(9.900100, .usdc),
                                    outputTokenAmount: .amt(8.801099, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .withdrawFromMorphoVault(
                                    tokenAmount: .max(.usdc),
                                    vault: .usdc,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: .amt(9.980100, .usdc),
                                    outputTokenAmount: .amt(8.880299, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.04, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 8.801099 bridged + 8.880299 bridged - 0.04 fee = 17.641398
                                .supplyToComet(
                                    tokenAmount: .amt(17.641398, .usdc),
                                    market: .cusdcv3,
                                    cappedMax: true,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number(
                                            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
                                        ),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        comet: EthAddress(
                                            "0xc3d688b66703497daa19211eedff47f25384cdc3"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        )
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("42161"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("9.90010e6"),
                                        outputAmount: Number("8.801099e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
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
                                Charter.ActionContext.morphoVaultWithdraw(
                                    Charter.ActionContext.MorphoVaultWithdrawActionContext(
                                        amount: Number(
                                            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
                                        ),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        morphoVault: EthAddress(
                                            "0xc1256ae5ff1cf2719d4937adb3bbccab2e00a2ca"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("8453"),
                                        destinationChainId: Number("42161"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("9.98010e6"),
                                        outputAmount: Number("8.880299e6"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
                                    )
                                ),
                            ]
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.04e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("1e8"),
                                        payee: EthAddress(
                                            "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                        ),
                                        quoteId: Hex(
                                            "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                        ),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                        )
                                    )
                                ),
                                Charter.ActionContext.cometSupply(
                                    Charter.ActionContext.CometSupplyActionContext(
                                        amount: Number("17.641398e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        comet: EthAddress(
                                            "0x9c4ec768c28520b50860ea7a15bd7213a9ff58bf"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
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

    @Test("Alice migrates, but the withdrawn amount cannot cover the supply")
    func testMigratesButNotEnoughToSupply() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .ethereum),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .ethereum)
                    ],
                    supply: (
                        from: .alice, market: .comet(.cusdcv3), amount: .amt(11, .usdc),
                        on: .arbitrum
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .failure(.error("MigrateSupplies requires supply amount to be .max (supply all specified assets)"))
            )
        )
    }

    @Test(
        "Alice migrates exact amount from Comet despite having sufficient token balance"
    )
    func testMigrateExactWithdrawalDespiteExistingBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .cometSupply(.alice, .amt(500, .usdc), .cusdcv3, .base),
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .quote(.basic),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (
                            from: .alice, market: .comet(.cusdcv3), amount: .amt(500, .usdc),
                            on: .base
                        )
                    ],
                    supply: (
                        from: .alice, market: .aave(.baseV3), amount: .max(.usdc), on: .base
                    ),
                    migrateOnlySupplyBalances: true
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .amt(500, .usdc),
                                    market: .cusdcv3,
                                    network: .base
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // 500 withdrawn - 0.02 fee - 0.02 fee = 499.96
                                .supplyToAave(
                                    tokenAmount: .amt(499.96, .usdc),
                                    pool: .baseV3,
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
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number("500e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        comet: EthAddress(
                                            "0xb125e6687d4313864e53df431d5425969c15eb2f"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
                                Charter.ActionContext.aaveSupply(
                                    Charter.ActionContext.AaveSupplyActionContext(
                                        amount: Number("499.96e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("1e8"),
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

    @Test("Alice migrates, on same chain but with available assets on another chain")
    func testMigratesToSameChainWithAvailableAssetsElsewhere() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .base),
                    .tokenBalance(.alice, .amt(4, .usdc), .arbitrum),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .base)
                    ],
                    supply: (from: .alice, market: .aave(.baseV3), amount: .max(.usdc), on: .base),
                    migrateOnlySupplyBalances: false
                ),
                expect: .successWithActions(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .arbitrum,
                            destinationNetwork: .base,
                            inputTokenAmount: .amt(4, .usdc),
                            outputTokenAmount: .amt(2.96, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
                                    network: .base
                                ),
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                // 10 * 1.00001 (max buffer) + 2.96 (bridged) - 0.02 - 0.02 = 12.9201
                                .supplyToAave(
                                    tokenAmount: .amt(12.9201, .usdc),
                                    pool: .baseV3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        Charter.ActionContext.bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("42161"),
                                destinationChainId: Number("8453"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("4e6"),
                                outputAmount: Number("2.96e6"),
                                price: Number("1e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                )
                            )
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.cometWithdraw(
                                    Charter.ActionContext.CometWithdrawActionContext(
                                        amount: Number(
                                            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
                                        ),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        comet: EthAddress(
                                            "0xb125e6687d4313864e53df431d5425969c15eb2f"
                                        ),
                                        price: Number("1e8"),
                                        token: EthAddress(
                                            "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                        )
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
                                Charter.ActionContext.aaveSupply(
                                    Charter.ActionContext.AaveSupplyActionContext(
                                        amount: Number("12.9201e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
                                        ),
                                        price: Number("1e8"),
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

    @Test("Alice migrates max USDC to Morpho on multiple chains, paying with withdrawn funds")
    func testMigrateSuppliesOnMultipleChains() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .unichain),
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .base),
                    .cometSupply(.alice, .amt(10, .usdc), .cusdcv3, .optimism),
                    .tokenBalance(.alice, .amt(60, .usdc), .worldChain),
                ],
                when: .migrateSupplies(
                    withdraw: [
                        (from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .unichain),
                        (from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .base),
                        (from: .alice, market: .comet(.cusdcv3), amount: .max(.usdc), on: .optimism),
                    ],
                    supply: (from: .alice, market: .morpho(.usdc), amount: .max(.usdc), on: .worldChain),
                    migrateOnlySupplyBalances: true
                ),
                expect: .success(
                    .multi([
                        // Optimism, Unichain, Base order - sorted by chainId (10 < 130 < 8453)
                        // All three are independent bridges to World Chain (no dependency between them)
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
                                    network: .optimism
                                ),
                                .quotePay(payment: .amt(0.06, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .optimism,
                                    destinationNetwork: .worldChain,
                                    inputTokenAmount: .amt(9.9401, .usdc),
                                    outputTokenAmount: .amt(8.840699, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
                                    network: .unichain
                                ),
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .unichain,
                                    destinationNetwork: .worldChain,
                                    inputTokenAmount: .amt(9.9801, .usdc),
                                    outputTokenAmount: .amt(8.880299, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .withdrawFromComet(
                                    tokenAmount: .max(.usdc),
                                    market: .cusdcv3,
                                    network: .base
                                ),
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .worldChain,
                                    inputTokenAmount: .amt(9.9801, .usdc),
                                    outputTokenAmount: .amt(8.880299, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                // 8.840699 bridged + 8.880299 bridged + 8.880299 bridged - 0.1 fee = 26.501297
                                .supplyToMorphoVault(
                                    tokenAmount: .amt(26.501297, .usdc),
                                    vault: .usdc,
                                    cappedMax: true,
                                    network: .worldChain
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }
}
