@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Transfer Tests")
struct TransferTests {
    @Test("Alice transfers 10 USDC to Foodie on Ethereum")
    func testTransferUsdcToFoodieEthereum() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .transfer(
                    from: .alice,
                    to: .unknownAccount("0x0000000000000000000000000000000000f00d1e"),
                    amount: .amt(10, .usdc),
                    on: .ethereum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.10, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .transferErc20(
                                    tokenAmount: .amt(10, .usdc),
                                    recipient: .unknownAccount(
                                        "0x0000000000000000000000000000000000f00d1e"
                                    ),
                                    cappedMax: false,
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

    @Test("Alice transfers 10 USDC to Bob on Arbitrum")
    func testTransferUsdcToBobArbitrum() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .arbitrum),
                    .quote(.basic),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(10, .usdc),
                    on: .arbitrum
                ),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transferErc20(
                                    tokenAmount: .amt(10, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice transfers 10 USDC to Bob on Optimism")
    func testTransferUsdcToBobOptimism() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .optimism),
                    .quote(.basic),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(10, .usdc), on: .optimism),
                expect: .success(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.06, .usdc), payee: .stax, quote: .basic),
                                .transferErc20(
                                    tokenAmount: .amt(10, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .optimism
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    @Test("Alice attempts to transfer perceived MAX USDC to Bob on Arbitrum")
    func testTransferPerceivedMaxUsdcToBobArbitrum() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .arbitrum),
                    .quote(.basic),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(100, .usdc),
                    on: .arbitrum
                ),
                // Note: Previously expected .unableToConstructQuotePayForAsset
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed
                expect: .failure(
                    .error("insufficientResources(target: .exact(100000000), max: 99960000)")
                )
            )
        )
    }

    @Test("Alice attempts to transfer perceived MAX USDC to Bob on Arbitrum via Bridge")
    func testTransferPerceivedMaxUsdcViaBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(100, .usdc),
                    on: .arbitrum
                ),
                // Note: Previously expected .unableToConstructBridgeForAsset(symbol: "USDC", network: arbitrum, bridgeFees: 1.5 USDC)
                // but Tradewinds now returns .error("insufficientResources") when bridge construction fails due to insufficient funds
                expect: .failure(
                    .error("insufficientResources(target: .exact(100000000), max: 98440200)")
                )
            )
        )
    }

    @Test("Alice transfers MAX USDC (uint256.max) to Bob on Arbitrum via Bridge")
    func testTransferMaxUsdcUint256ViaBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .max(.usdc),
                    on: .arbitrum
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: .amt(49.980000, .usdc),
                                    outputTokenAmount: .amt(48.480200, .usdc),
                                    cappedMax: true,
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transferErc20(
                                    tokenAmount: .amt(98.440200, .usdc),
                                    recipient: .bob,
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
                                        inputAmount: Number("49.98e6"),
                                        outputAmount: Number("48.4802e6"),
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
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("98.4402e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
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

    @Test("Alice bridges sumSrcBalance via Across when inputAmount > sumSrcBalance")
    func testBridgeSumSrcBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(99, .usdc),
                    on: .arbitrum
                ),
                // Note: Previously expected .unableToConstructBridgeForAsset(symbol: "USDC", network: arbitrum, bridgeFees: 1.5 USDC)
                // but Tradewinds now returns .error("insufficientResources") when bridge construction fails
                expect: .failure(
                    .error("insufficientResources(target: .exact(99000000), max: 98440200)")
                )
            )
        )
    }

    // TODO: Should we fail if we can't find a network fee?
    @Test("Alice transfers 75 USDC to Bob on Arbitrum via Bridge without all quotes", .disabled())
    func testTransfer75UsdcViaBridgeWithoutAllQuotes() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
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
                                .arbitrum: 0.04
                            ]
                        )
                    ),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(75, .usdc),
                    on: .arbitrum
                ),
                // Note: Previously expected .revert(.networkOperationFeeNotFound(network: base))
                expect: .failure(.error("insufficientResources"))
            )
        )
    }

    @Test("Alice transfers USDC to Bob on Arbitrum via Bridge")
    func testTransferUsdcToBobViaBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(98, .usdc),
                    on: .arbitrum
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: .amt(49.535354, .usdc),
                                    outputTokenAmount: .amt(48.040000, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transferErc20(
                                    tokenAmount: .amt(98, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .arbitrum,
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
                                        inputAmount: Number("49.535354e6"),
                                        outputAmount: Number("48.04e6"),
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
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("98e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
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

    @Test("Alice transfers ETH. WETH is unwrapped and ETH is transferred")
    func testTransferETHTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.5, .eth), .base),
                    .tokenBalance(.alice, .amt(0.21, .weth), .base),
                    .quote(.basic),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(0.7, .eth), on: .base),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .unwrapWETHUpTo(
                                    tokenAmount: .amt(0.200005, .weth)
                                ),
                                .wrapUpTo(
                                    tokenAmount: .amt(0.000005, .eth)
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .unwrapWETHUpTo(
                                    tokenAmount: .amt(0.7, .weth)
                                ),
                                .transferNativeToken(
                                    tokenAmount: .amt(0.7, .eth),
                                    recipient: .bob,
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
                                Charter.ActionContext.unwrap(
                                    Charter.ActionContext.UnwrapActionContext(
                                        chainId: Number("8453"),
                                        amount: Number("0.200005e18"),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        fromAssetSymbol: "WETH",
                                        toAssetSymbol: "ETH"
                                    )
                                ),
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("8453"),
                                        amount: Number("0.000005e18"),
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
                                Charter.ActionContext.unwrap(
                                    Charter.ActionContext.UnwrapActionContext(
                                        chainId: Number("8453"),
                                        amount: Number("0.7e18"),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        ),
                                        fromAssetSymbol: "WETH",
                                        toAssetSymbol: "ETH"
                                    )
                                ),
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("0.7e18"),
                                        assetSymbol: "ETH",
                                        chainId: Number("8453"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
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

    @Test("Alice transfers ETH over bridge. WETH is unwrapped and ETH is transferred", .disabled())
    func testTransferETHOverBridgeTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.8, .eth), .base),
                    .tokenBalance(.alice, .amt(5, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(0.7, .eth), on: .arbitrum),
                expect: .successWithActions(
                    .multi(
                        [
                            .multicall(
                                [
                                    .wrapUpTo(
                                        tokenAmount: .amt(0.000005, .eth)
                                    ),
                                    .quotePay(
                                        payment: .amt(0.000005, .weth),
                                        payee: .stax,
                                        quote: .basic
                                    ),
                                    .bridge(
                                        bridge: "Across",
                                        srcNetwork: .base,
                                        destinationNetwork: .arbitrum,
                                        inputTokenAmount: TokenAmount(
                                            fromWei: Number("0.717181818181818112e18"),
                                            ofToken: TestHelpers.Token.weth
                                        ),
                                        outputTokenAmount: .amt(0.70001, .weth),
                                        cappedMax: false
                                    ),
                                ],
                                executionType: .immediate
                            ),
                            .multicall(
                                [
                                    // TODO: IS this missing a wrap upto?
                                    .unwrapWETHUpTo(
                                        tokenAmount: .amt(0.7, .weth)
                                    ),
                                    // TODO: Should this be eth or weth?
                                    .quotePay(
                                        payment: .amt(0.00001, .eth),
                                        payee: .stax,
                                        quote: .basic
                                    ),
                                    .transferNativeToken(
                                        tokenAmount: .amt(0.7, .eth),
                                        recipient: .bob,
                                        cappedMax: false,
                                        network: .arbitrum
                                    ),
                                ],
                                executionType: .contingent
                            ),
                        ]
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("8453"),
                                        amount: Number("0.8e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
                                    )
                                ),
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "WETH",
                                        bridgeType: .across,
                                        chainId: Number("8453"),
                                        destinationChainId: Number("42161"),
                                        destinationAssetSymbol: "ETH",
                                        inputAmount: Number("0.717e18"),
                                        outputAmount: Number("0.7e18"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.06e6"),
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
                        .multiAction(
                            [
                                Charter.ActionContext.unwrap(
                                    Charter.ActionContext.UnwrapActionContext(
                                        chainId: Number("42161"),
                                        amount: Number("0.7e18"),
                                        token: EthAddress(
                                            "0x82af49447d8a07e3bd95bd0d56f35241523fbab1"
                                        ),
                                        fromAssetSymbol: "WETH",
                                        toAssetSymbol: "ETH"
                                    )
                                ),
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("0.7e18"),
                                        assetSymbol: "ETH",
                                        chainId: Number("42161"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
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

    // TODO: Native token issues
    @Test("Alice transfers WETH to Bob on Arbitrum via Across [Pay with WETH]", .disabled())
    func testTransferWethAndPayWithWethTest() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.5, .weth), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .payWith(
                    currency: .weth,
                    .transfer(from: .alice, to: .bob, amount: .amt(0.3, .weth), on: .arbitrum)
                ),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .arbitrum,
                                    inputTokenAmount: TokenAmount(
                                        fromWei: "313141414141414142",
                                        ofToken: .weth
                                    ),
                                    outputTokenAmount: .amt(0.30001, .weth),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .wrapUpTo(
                                    tokenAmount: .amt(0.00001, .eth)
                                ),
                                .quotePay(
                                    payment: .amt(0.00001, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // TODO: Transfer ERC20 or transfer native token?
                                .transferNativeToken(
                                    tokenAmount: .amt(0.3, .weth),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "WETH",
                                        bridgeType: .across,
                                        chainId: Number("8453"),
                                        destinationChainId: Number("42161"),
                                        destinationAssetSymbol: "ETH",
                                        inputAmount: Number("0.313e18"),
                                        outputAmount: Number("0.3e18"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.000015e18"),
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
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.unwrap(
                                    Charter.ActionContext.UnwrapActionContext(
                                        chainId: Number("42161"),
                                        amount: Number("0.3e18"),
                                        token: EthAddress(
                                            "0x82af49447d8a07e3bd95bd0d56f35241523fbab1"
                                        ),
                                        fromAssetSymbol: "WETH",
                                        toAssetSymbol: "ETH"
                                    )
                                ),
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("0.3e18"),
                                        assetSymbol: "ETH",
                                        chainId: Number("42161"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
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
        "Alice transfers MAX USDC (with uint256.max) to Bob on Arbitrum via Bridge, but some funds are unbridgeable"
    )
    func testTransferMaxWithSomeUnbridgeableFunds() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                    .acrossQuoteWithMin(.amt(1, .usdc), 0.01, .amt(51, .usdc)),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .max(.usdc), on: .arbitrum),
                expect: .success(
                    .single(
                        // Only 50 USDC is transferred because the other 50 USDC is unbridgeable (bridge min is 51 USDC).
                        // Payment is made on Base, where there are unbridgeable funds
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.04, .usdc),
                                    payee: .stax,
                                    quote: .basic,
                                ),
                                .transferErc20(
                                    tokenAmount: .amt(49.960000, .usdc),
                                    recipient: .bob,
                                    cappedMax: true,
                                    network: .arbitrum,
                                ),
                            ],
                            executionType: .immediate
                        )
                    )
                )
            )
        )
    }

    // TODO: This is failing on insufficient resources
    @Test(
        "Alice transfers to Bob on Arbitrum via Bridge, with bridge amount adjusted to be the min bridge amount",
        .disabled()
    )
    func testTransferAdjustingBridgeAmountToMin() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(50, .usdc), .base),
                    .quote(.basic),
                    .acrossQuoteWithMin(.amt(0.1, .usdc), 0.01, .amt(0.5, .usdc)),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(50.1, .usdc), on: .arbitrum),
                expect: .successWithActions(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            // Normally would bridge 0.1, but bridge min is 0.5
                            inputTokenAmount: .amt(0.5, .usdc),
                            outputTokenAmount: .amt(0.395, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .transferErc20(
                                    tokenAmount: .amt(50.1, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .arbitrum,
                                ),
                                .quotePay(payment: .amt(0.06, .usdc), payee: .stax, quote: .basic),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        Charter.ActionContext.bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("8453"),
                                destinationChainId: Number("42161"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("0.5e6"),
                                outputAmount: Number("0.395e6"),
                                price: Number("1.0e8"),
                                recipient: EthAddress("0x00000000000000000000000000000000000a11ce"),
                                token: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913")
                            )
                        ),
                        .multiAction(
                            [
                                .transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("50.1e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                        )
                                    )
                                ),
                                .quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("0.06e6"),
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
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test(
        "Alice transfers to Bob on Arbitrum via Bridge, when total paymentFees > unbridgeableAmount"
    )
    func testTransferWithBridgeWithPaymentFeesGtUnbridgeableAmount() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(30, .usdc), .base),
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
                            fees: [.arbitrum: 40, .base: 5]
                        )
                    ),
                    .acrossQuoteWithMin(.amt(0.1, .usdc), 0.01, .amt(50, .usdc)),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(20, .usdc), on: .arbitrum),
                // Note: Previously expected .error("unableToConstructQuotePayForAsset")
                // There is no way to construct a valid transfer of 20 USDC
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed
                expect: .failure(
                    .error("insufficientResources(target: .exact(20000000), max: 10000000)")
                )
            )
        )
    }

    // Regression test for QuarkBuilder bug where bridging ETH with only WETH balance
    // would generate unwrapWETHUpTo(0), causing bridge to use inputAmount=0 and fail.
    // Mercator bridges WETH directly (more efficient), avoiding the bug entirely.
    // https://github.com/legend-hq/legend-scripts/pull/187
    @Test("Transfer max ETH cross-chain with only WETH balance")
    func testTransferMaxEthWithOnlyWethBalanceUnwrapsAll() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(3, .weth), .arbitrum),
                    .tokenBalance(.alice, .amt(5, .usdc), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .max(.eth), on: .base),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.00001, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .arbitrum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: .amt(2.99999, .weth),
                                    outputTokenAmount: .amt(2.9599901, .weth),
                                    cappedMax: true
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .wrapUpTo(tokenAmount: .amt(0.000005, .eth)),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .unwrapWETHUpTo(
                                    tokenAmount: TokenAmount(
                                        // 2.9599851e18 (transfer amount)
                                        fromWei: "2959985100000000000",
                                        ofToken: .weth
                                    )
                                ),
                                .transferNativeToken(
                                    tokenAmount: .amt(2.9599851, .eth),
                                    recipient: .bob,
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

    // Regression test for QuarkBuilder bug where calculateAmountToWrapOrUnwrap checked
    // source token (WETH) balance instead of target token (ETH) balance for unwrap amounts.
    // Mercator bridges WETH directly without unwrapping, avoiding the calculation bug.
    // https://github.com/legend-hq/legend-scripts/pull/190
    @Test("Transfer ETH cross-chain paying with WETH")
    func testTransferEthPayWithWethUsesCorrectUnwrapBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.3, .weth), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .payWith(
                    currency: .weth,
                    .transfer(from: .alice, to: .bob, amount: .amt(0.25, .eth), on: .base)
                ),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.00001, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .arbitrum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(
                                        fromWei: "262631313131313132",
                                        ofToken: TestHelpers.Token.weth
                                    ),
                                    outputTokenAmount: TokenAmount(
                                        fromWei: "250005000000000000",
                                        ofToken: TestHelpers.Token.weth
                                    ),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .wrapUpTo(tokenAmount: .amt(0.000005, .eth)),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .unwrapWETHUpTo(
                                    tokenAmount: TokenAmount(
                                        // 0.25e18 (transfer amount)
                                        fromWei: "250000000000000000",
                                        ofToken: .weth
                                    )
                                ),
                                .transferNativeToken(
                                    tokenAmount: .amt(0.25, .eth),
                                    recipient: .bob,
                                    cappedMax: false,
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

    @Test(
        "Alice transfers MAX to Bob on Arbitrum via Bridge, when total paymentFees > unbridgeableAmount"
    )
    func testTransferMaxWithBridgeWithPaymentFeesGtUnbridgeableAmount() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
                    .tokenBalance(.alice, .amt(30, .usdc), .base),
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
                            fees: [.arbitrum: 40, .base: 5]
                        )
                    ),
                    .acrossQuoteWithMin(.amt(0.1, .usdc), 0.01, .amt(50, .usdc)),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .max(.usdc), on: .arbitrum),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(40, .usdc),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                // Only 10 USDC is available to transfer since payment has to be made on Arbitrum
                                // due to unbridgeable funds on Base
                                .transferErc20(
                                    tokenAmount: .amt(10, .usdc),
                                    recipient: .bob,
                                    cappedMax: true,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .immediate
                        )
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("40e6"),
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
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("10e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
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

    @Test("Alice transfers ETH as WETH to Polygon - ends up in WETH")
    func testTransferETHasWETHtoPolygon() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.8, .eth), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(0.7, .weth), on: .polygon),
                expect: .successWithActions(
                    .multi(
                        [
                            .multicall(
                                [
                                    .wrapAsset(.eth),
                                    .quotePay(
                                        payment: .amt(0.000005, .weth),
                                        payee: .stax,
                                        quote: .basic
                                    ),
                                    .bridge(
                                        bridge: "Across",
                                        srcNetwork: .base,
                                        destinationNetwork: .polygon,
                                        inputTokenAmount: TokenAmount(
                                            fromWei: "0.717171717171717172e18",
                                            ofToken: TestHelpers.Token.weth
                                        ),
                                        outputTokenAmount: .amt(0.70, .weth),
                                        cappedMax: false
                                    ),
                                ],
                                executionType: .immediate
                            ),
                            .transferErc20(
                                tokenAmount: .amt(0.70  , .weth),
                                recipient: .bob,
                                cappedMax: false,
                                network: .polygon,
                                executionType: .contingent
                            ),
                        ]
                    ),
                    [
                        .multiAction(
                            [
                                Charter.ActionContext.wrap(
                                    Charter.ActionContext.WrapActionContext(
                                        chainId: Number("8453"),
                                        amount: Number("0.717176717171717172e18"),
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "WETH",
                                        bridgeType: .across,
                                        chainId: Number("8453"),
                                        destinationChainId: Number("137"),
                                        destinationAssetSymbol: "WETH",
                                        inputAmount: Number("0.717171717171717172e18"),
                                        outputAmount: Number("0.7e18"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                            ]
                        ),
                        Charter.ActionContext.transfer(
                            Charter.ActionContext.TransferActionContext(
                                amount: Number("0.7e18"),
                                assetSymbol: "WETH",
                                chainId: Number("137"),
                                price: Number("4000e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000b0b0b"
                                ),
                                token: EthAddress(
                                    "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619"
                                )
                            )
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice transfers WETH as WETH to Polygon - ends up in WETH")
    func testTransferWETHasWETHtoPolygon() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.8, .weth), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(0.7, .weth), on: .polygon),
                expect: .successWithActions(
                    .multi(
                        [
                            .multicall(
                                [
                                    .quotePay(
                                        payment: .amt(0.000005, .weth),
                                        payee: .stax,
                                        quote: .basic
                                    ),
                                    .bridge(
                                        bridge: "Across",
                                        srcNetwork: .base,
                                        destinationNetwork: .polygon,
                                        inputTokenAmount: TokenAmount(
                                            fromWei: "0.717171717171717172e18",
                                            ofToken: TestHelpers.Token.weth
                                        ),
                                        outputTokenAmount: .amt(0.70, .weth),
                                        cappedMax: false
                                    ),
                                ],
                                executionType: .immediate
                            ),
                            .transferErc20(
                                tokenAmount: .amt(0.70  , .weth),
                                recipient: .bob,
                                cappedMax: false,
                                network: .polygon,
                                executionType: .contingent
                            ),
                        ]
                    ),
                    [
                        .multiAction(
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
                                Charter.ActionContext.bridge(
                                    Charter.ActionContext.BridgeActionContext(
                                        assetSymbol: "WETH",
                                        bridgeType: .across,
                                        chainId: Number("8453"),
                                        destinationChainId: Number("137"),
                                        destinationAssetSymbol: "WETH",
                                        inputAmount: Number("0.717171717171717172e18"),
                                        outputAmount: Number("0.7e18"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000a11ce"
                                        ),
                                        token: EthAddress(
                                            "0x4200000000000000000000000000000000000006"
                                        )
                                    )
                                ),
                            ]
                        ),
                        Charter.ActionContext.transfer(
                            Charter.ActionContext.TransferActionContext(
                                amount: Number("0.7e18"),
                                assetSymbol: "WETH",
                                chainId: Number("137"),
                                price: Number("4000e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000b0b0b"
                                ),
                                token: EthAddress(
                                    "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619"
                                )
                            )
                        ),
                    ]
                )
            )
        )
    }

    @Test("Transfer ETH after bridging WETH with existing WETH balance on destination")
    func testTransferEthAfterBridgingWethWithExistingBalance() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .weth), .base),
                    .tokenBalance(.alice, .amt(1, .weth), .arbitrum),
                    .quote(.basic),
                    .acrossQuote(.amt(0.01, .weth), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(1.5, .eth), on: .base),
                expect: .success(
                    .multi([
                        .multicall(
                            [
                                .quotePay(
                                    payment: .amt(0.00001, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .arbitrum,
                                    destinationNetwork: .base,
                                    inputTokenAmount: TokenAmount(
                                        fromWei: "515156565656565657",
                                        ofToken: TestHelpers.Token.weth
                                    ),
                                    outputTokenAmount: TokenAmount(
                                        fromWei: "500005000000000000",
                                        ofToken: TestHelpers.Token.weth
                                    ),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                // Note: There's a bug where only the existing WETH balance is unwrapped, not the newly bridged WETH.
                                // We fixed this by the optimistically unwrapping WETH before native ETH transfers (as can be seen below,
                                // before the transferNativeToken operation).
                                .unwrapWETHUpTo(
                                    tokenAmount: .amt(1, .weth)
                                ),
                                .wrapUpTo(
                                    tokenAmount: .amt(0.000005, .eth)
                                ),
                                .quotePay(
                                    payment: .amt(0.000005, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .unwrapWETHUpTo(
                                    tokenAmount: .amt(1.5, .weth)
                                ),
                                .transferNativeToken(
                                    tokenAmount: .amt(1.5, .eth),
                                    recipient: .bob,
                                    cappedMax: false,
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
}
