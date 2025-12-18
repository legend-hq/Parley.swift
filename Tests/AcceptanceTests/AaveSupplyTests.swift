@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Aave Supply Tests")
struct AaveSupplyTests {
    @Test("Alice supplies 0.5 WETH to Aave on Ethereum")
    func testAaveSupplyWETH() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.0, .weth), .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .weth,
                    .aaveSupply(
                        from: .alice,
                        market: .baseV3,
                        amount: .amt(0.5, .weth),
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToAave(
                                    tokenAmount: .amt(0.5, .weth),
                                    pool: .baseV3,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        Charter.ActionContext.multiAction(
                            [
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
                                Charter.ActionContext.aaveSupply(
                                    Charter.ActionContext.AaveSupplyActionContext(
                                        amount: Number("0.5e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
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

    @Test("Alice supplies 0.5 ETH to Aave activate auto wrapper")
    func testAaveSupplyETH() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.0, .eth), .base),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .weth,
                    .aaveSupply(
                        from: .alice,
                        market: .baseV3,
                        amount: .amt(0.5, .weth),
                        on: .base
                    )
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToAave(
                                    tokenAmount: .amt(0.5, .weth),
                                    pool: .baseV3,
                                    cappedMax: false,
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
                                        amount: Number("0.500005e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
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
                                Charter.ActionContext.aaveSupply(
                                    Charter.ActionContext.AaveSupplyActionContext(
                                        amount: Number("0.5e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("8453"),
                                        aavePool: EthAddress(
                                            "0xa238dd80c259a72e81d7e4664a9801593f98d1c5"
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

    @Test("Alice supplies max with bridge and QuotePay")
    func testAaveSupplyMaxWithBridgeAndQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3.0, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3.0, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .payWith(
                    currency: .usdc,
                    .aaveSupply(from: .alice, market: .baseV3, amount: .max(.usdc), on: .base)
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(2.900000, .usdc),
                                    outputTokenAmount: .amt(1.871, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                // 3 (base balance) + 1.871 (bridged) - 0.02 (quote pay) = 4.851
                                .supplyToAave(
                                    tokenAmount: .amt(4.851, .usdc),
                                    pool: .baseV3,
                                    cappedMax: true,
                                    network: .base
                                ),

                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
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
                                .bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("2.9e6"),
                                        outputAmount: Number("1.871e6"),
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
                        .multiAction([
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
                                    amount: Number("4.851e6"),
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
                        ]),
                    ]
                )
            )
        )
    }

    @Test("Alice supplies to Aave more than she has")
    func testAaveSupplyInsufficientFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0, .usdc), .base),
                    .quote(.basic),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .amt(2, .usdc),
                    on: .base
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 2000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when no path is found
                expect: .failure(.error("insufficientResources(target: .exact(2000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies to Aave, but the operation cost is too high")
    func testAaveSupplyMaxCostTooHigh() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: Dictionary(
                                uniqueKeysWithValues: Token.knownCases.map { token in
                                    (token, token.defaultUsdPrice)
                                }
                            ),
                            fees: [
                                .ethereum: 1,
                                .base: 1000,
                            ]
                        )
                    ),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .amt(1, .usdc),
                    on: .base
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "USDC", 1000000000))
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed
                expect: .failure(.error("insufficientResources(target: .exact(1000000), max: 0)"))
            )
        )
    }

    @Test("Alice supplies to Aave, but her funds are on an unreachable chain (7777)")
    func testAaveSupplyFundsUnavailable() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(0, .usdc), .base),
                    .tokenBalance(.alice, .amt(100, .usdc), .unknown(7777)),
                    .quote(.basic),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .amt(2, .usdc),
                    on: .base
                ),
                // Note: Previously expected .revert(.badInputInsufficientFunds("USDC", 2000000, 0))
                // but Tradewinds now returns .error("insufficientResources") when funds are on unreachable chains
                expect: .failure(.error("insufficientResources(target: .exact(2000000), max: 0)"))
            )
        )
    }

    @Test("Alice simply supplies to Aave, paying with QuotePay")
    func testSimpleAaveSupplyTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .amt(1, .usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToAave(
                                    tokenAmount: .amt(1, .usdc),
                                    pool: .baseV3,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                .quotePay(
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
                                .aaveSupply(
                                    Charter.ActionContext.AaveSupplyActionContext(
                                        amount: Number("1e6"),
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

    @Test("Alice supplies max to Aave")
    func testSimpleAaveSupplyMax() async throws {
        /*
         +1.5 on Ethereum
         +1.5 on Base
         -1 for Across gasFee
         -(1.5 * .01) for Across pctFee
         -0.1 (Eth operation fee)
         -0.02 (Base operation fee)
         = 1.865 USDC supplied
         */

        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .max(.usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(1.400000, .usdc),
                                    outputTokenAmount: .amt(0.386, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),

                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                // 1.5 (base balance) + 0.386 (bridged) - 0.02 (quote pay) = 1.866
                                .supplyToAave(
                                    tokenAmount: .amt(1.866, .usdc),
                                    pool: .baseV3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                .quotePay(
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
                                .bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("1.4e6"),
                                        outputAmount: Number("0.386e6"),
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
                                        amount: Number("1.866e6"),
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

    @Test("Alice supplies to Aave, paying with QuotePay")
    func testAaveSupplyWithQuotePayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.5, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(1.5, .usdc), .base),
                    .quote(.basic),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .amt(1, .usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.02, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .supplyToAave(
                                    tokenAmount: .amt(1, .usdc),
                                    pool: .baseV3,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                .quotePay(
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
                                .aaveSupply(
                                    Charter.ActionContext.AaveSupplyActionContext(
                                        amount: Number("1e6"),
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

    @Test("Alice supplies to Aave, bridging funds from Ethereum to Base")
    func testAaveSupplyWithBridgeTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .amt(5, .usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(3.050506, .usdc),
                                    outputTokenAmount: .amt(2.02, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .supplyToAave(
                                    tokenAmount: .amt(5, .usdc),
                                    pool: .baseV3,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),

                    ]),
                    [
                        .multiAction(
                            [
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
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("3.050506e6"),
                                        outputAmount: Number("2.02e6"),
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
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice supplies max to Aave, bridging funds")
    func testAaveSupplyMaxWithBridgeTest() async throws {
        /*
         +3 on Base
         +3 on Ethereum
         -1 for Across gas fee
         -(3 * 0.01) for Across pct fee
         -0.1 for Ethereum operation fee
         -0.02 for Base operation fee
         = 4.85 USDC supplied to Aave
         */

        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .max(.usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(2.90, .usdc),
                                    outputTokenAmount: .amt(1.871, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                // 3 (base balance) + 1.871 (bridged) - 0.02 (quote pay) = 4.851
                                .supplyToAave(
                                    tokenAmount: .amt(4.851, .usdc),
                                    pool: .baseV3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                .quotePay(
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
                                .bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("2.9e6"),
                                        outputAmount: Number("1.871e6"),
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
                        .multiAction([
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
                                    amount: Number("4.851e6"),
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

    @Test("Alice supplies max to Aave, bridging funds and paying with QuotePay")
    func testAaveSupplyMaxWithBridgeAndQuotePayAndCustomQuote() async throws {
        /*
         +3 on Ethereum
         +3 on Base
         -1 for Across gas fee
         -(3 * .01) for Across pct fee
         -0.5 for Ethereum operation fee
         -0.1 for Base operation fee
         = 4.37 USDC supplied
         */

        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: Dictionary(
                                uniqueKeysWithValues: Token.knownCases.map { token in
                                    (token, token.defaultUsdPrice)
                                }
                            ),
                            fees: [
                                .ethereum: 0.5,
                                .base: 0.1,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .max(.usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.50, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(2.50, .usdc),
                                    outputTokenAmount: .amt(1.475, .usdc),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                // 3 (base balance) + 1.475 (bridged) - 0.1 (quote pay) = 4.375
                                .supplyToAave(
                                    tokenAmount: .amt(4.375, .usdc),
                                    pool: .baseV3,
                                    cappedMax: true,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                .quotePay(
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
                                .bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("2.5e6"),
                                        outputAmount: Number("1.475e6"),
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
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
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
                                        amount: Number("4.375e6"),
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

    @Test("Alice supplies to Aave, bridging funds and paying with QuotePay")
    func testAaveSupplyWithBridgeAndQuotePayTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(4, .usdc), .ethereum),
                    .tokenBalance(.alice, .amt(3, .usdc), .base),
                    .quote(
                        .custom(
                            quoteId: Hex(
                                "0x00000000000000000000000000000000000000000000000000000000000000CC"
                            ),
                            prices: Dictionary(
                                uniqueKeysWithValues: Token.knownCases.map { token in
                                    (token, token.defaultUsdPrice)
                                }
                            ),
                            fees: [
                                .ethereum: 0.5,
                                .base: 0.1,
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .baseV3,
                    amount: .amt(5, .usdc),
                    on: .base
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.5, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .ethereum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(3.131314, .usdc),
                                    outputTokenAmount: .amt(2.10, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.1, .usdc), payee: .stax, quote: .basic),
                                .supplyToAave(
                                    tokenAmount: .amt(5, .usdc),
                                    pool: .baseV3,
                                    cappedMax: false,
                                    network: .base
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "USDC",
                                        bridgeType: .across,
                                        chainId: Number("1"),
                                        destinationChainId: Number("8453"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("3.131314e6"),
                                        outputAmount: Number("2.1e6"),
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
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.1e6"),
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
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice supplies to an unknown Aave pool")
    func testAaveSupplyUnknownPool() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1.0, .usdc), .base),
                    .quote(.basic),
                ],
                when: .aaveSupply(
                    from: .alice,
                    market: .unknownPool(EthAddress("0x1234567890123456789012345678901234567890")),
                    amount: .amt(0.5, .usdc),
                    on: .base
                ),
                // Note: Previously expected .revert(.unknownAaveMarket(pool, chainId))
                // but market validation now returns a custom Charter error type
                expect: .failure(
                    .aaveMarketNotFound(
                        pool: EthAddress("0x1234567890123456789012345678901234567890"),
                        network: .base
                    )
                )
            )
        )
    }
}
