import Charter
@preconcurrency import Eth
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@Suite("Bridge Tests")
struct BridgeTests {
    @Test("Alice transfers Perceived MAX USDC to Bob on Arbitrum via Bridge")
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
                expect: .failure(.error("insufficientResources(target: .exact(100000000), max: 98460000)"))
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
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            inputTokenAmount: .amt(50, .usdc),
                            outputTokenAmount: .amt(48.5, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transfer(
                                    tokenAmount: .amt(98.46, .usdc),
                                    recipient: .bob,
                                    cappedMax: true,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        .bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("8453"),
                                destinationChainId: Number("42161"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("50000000"),
                                outputAmount: Number("48500000"),
                                price: Number("100000000"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                )
                            )
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("40000"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("100000000"),
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
                                        amount: Number("98460000"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("100000000"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ).on(Network.fromChainId(Number("42161"))),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                        ).on(Network.fromChainId(Number("42161")))
                                    )
                                ),
                            ]
                        ),
                    ]
                )
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
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            inputTokenAmount: .amt(49.535354, .usdc),
                            outputTokenAmount: .amt(48.040000, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transfer(
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
                        .bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("8453"),
                                destinationChainId: Number("42161"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("49535354"),
                                outputAmount: Number("48040000"),
                                price: Number("100000000"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                )
                            )
                        ),
                        .multiAction(
                            [
                                Charter.ActionContext.quotePay(
                                    Charter.ActionContext.QuotePayActionContext(
                                        amount: Number("40000"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("100000000"),
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
                                        amount: Number("98000000"),
                                        assetSymbol: "USDC",
                                        chainId: Number("42161"),
                                        price: Number("100000000"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ).on(Network.fromChainId(Number("42161"))),
                                        token: EthAddress(
                                            "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                        ).on(Network.fromChainId(Number("42161")))
                                    )
                                ),
                            ]
                        ),
                    ]
                )
            )
        )
    }

    @Test("Alice transfers all of Base USDC to Bob on Arbitrum via Bridge")
    func testTransferMaxUsdcViaBridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .max(.usdc), on: .arbitrum),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            inputTokenAmount: .amt(100, .usdc),
                            outputTokenAmount: .amt(98, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transfer(
                                    tokenAmount: .amt(97.96, .usdc),
                                    recipient: .bob,
                                    cappedMax: true,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice transfers all of Base USDC to Bob on Arbitrum via CCTPv2 Bridge")
    func testTransferMaxUsdcViaCCTPv2Bridge() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .quote(.basic),
                    .cctpV2Quote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .max(.usdc), on: .arbitrum),
                expect: .successWithActions(
                    .multi([
                        // CCTPv2 Burn standalone on source chain (Base) - no quotePay
                        .bridge(
                            bridge: "CCTPv2",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            inputTokenAmount: .amt(100, .usdc),
                            outputTokenAmount: .amt(98, .usdc),
                            cappedMax: true,
                            executionType: .immediate
                        ),
                        // CCTPv2 Mint and subsequent operations happen on destination chain (Arbitrum)
                        .multicall(
                            [
                                .bridgeMint(
                                    network: .arbitrum,  // Mint happens on destination network
                                    bridgeType: .CircleBridge,
                                    executionType: nil
                                ),
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                // Bridge 100 -> 98 arrives on arbitrum - 0.04 quote pay -> 97.96 USDC transfer
                                .transfer(
                                    tokenAmount: .amt(97.96, .usdc),
                                    recipient: .bob,
                                    cappedMax: true,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        // Bridge standalone on source chain
                        .bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .cctpV2,
                                chainId: Number("8453"),
                                destinationChainId: Number("42161"),
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("100000000"),
                                outputAmount: Number("98000000"),
                                price: Number("1.0e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"
                                )
                            )
                        ),
                        // Mint, quote pay, and transfer happen together on destination chain
                        .multiAction([
                            Charter.ActionContext.bridgeMint(
                                Charter.ActionContext.BridgeMintActionContext(
                                    assetSymbol: "USDC",
                                    bridgeType: .cctpV2,
                                    chainId: Number("42161"),
                                    sourceChainId: Number("8453"),
                                    inputAmount: Number("100000000"),
                                    outputAmount: Number("98000000"),
                                    maxFee: Number("2000000"),
                                    recipient: EthAddress(
                                        "0x00000000000000000000000000000000000a11ce"
                                    ),
                                    token: EthAddress(
                                        "0xaf88d065e77c8cc2239327c5edb3a432268e5831"  // USDC on Arbitrum
                                    )
                                )
                            ),
                            Charter.ActionContext.quotePay(
                                Charter.ActionContext.QuotePayActionContext(
                                    amount: Number("40000"),  // 0.04 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number("42161"),
                                    price: Number("1.0e8"),
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
                                    amount: Number("97960000"),  // 97.96 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number("42161"),
                                    price: Number("1.0e8"),
                                    recipient: EthAddress(
                                        "0x00000000000000000000000000000000000b0b0b"
                                    ).on(Network.fromChainId(Number("42161"))),
                                    token: EthAddress(
                                        "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
                                    ).on(Network.fromChainId(Number("42161")))
                                )
                            ),
                        ]),
                    ]
                )
            )
        )
    }

    @Test("CCTPv2 bridge mint correctly reconstructs burn input amount with ceiling division")
    func testCCTPv2BridgeMintCeilingRounding() async throws {
        // This test verifies that the mint side correctly reconstructs the burn input amount
        // using ceiling division to prevent -1 rounding discrepancies.
        //
        // The issue: When burn side calculates inputAmount using ceil(), and mint side
        // tries to reconstruct it using floor division, there can be a -1 discrepancy.
        //
        // Example with rate = 0.98 (2% fee):
        // - Burn: burnInputAmount = ceil((targetOutput + fixedCost) / 0.98) = 5153062
        // - Mint without ceiling: reconstructed = floor(...) = 5153061 <- WRONG, -1 error!
        // - Mint with ceiling: reconstructed = ceil(...) = 5153062    <- CORRECT
        //
        // We use a 2% fee rate which will produce fractional values during reverse calculation.
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(10, .usdc), .base),
                    .quote(.basic),
                    // 0.01 USDC fixed cost, 2% fee (rate = 0.98)
                    // This rate will cause fractional values in reverse calculation
                    .cctpV2Quote(.amt(0.01, .usdc), 0.02),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(5, .usdc), on: .arbitrum),
                expect: .successWithActions(
                    .multi([
                        // CCTPv2 Burn standalone on source chain (Base) - no quotePay
                        .bridge(
                            bridge: "CCTPv2",
                            srcNetwork: .base,
                            destinationNetwork: .arbitrum,
                            // Burn side calculates:
                            // - Need to deliver 5 USDC + 0.04 quote pay = 5.04 USDC to destination
                            // - With 2% fee: ceil((5.04 + 0.01) / 0.98) = ceil(5153061.22...) = 5153062
                            // - Output: floor(5153062 * 0.98 - 10000) = floor(5040000.76) = 5040000
                            inputTokenAmount: .amt(5.153062, .usdc),
                            outputTokenAmount: .amt(5.04, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        // CCTPv2 Mint happens on destination chain (Arbitrum)
                        .multicall(
                            [
                                .bridgeMint(
                                    network: .arbitrum,
                                    bridgeType: .CircleBridge,
                                    executionType: nil
                                ),
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transfer(
                                    tokenAmount: .amt(5, .usdc),  // 5.04 - 0.04 quote pay = 5.0 USDC
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .arbitrum
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        // Bridge standalone on source chain
                        .bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .cctpV2,
                                chainId: Number("8453"),  // Base
                                destinationChainId: Number("42161"),  // Arbitrum
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("5153062"),  // 5.153062 USDC (burn input)
                                outputAmount: Number("5040000"),  // 5.04 USDC (burn output = mint input)
                                price: Number("1.0e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"  // USDC on Base
                                )
                            )
                        ),
                        // Mint, quote pay, and transfer happen together on destination chain
                        .multiAction([
                            Charter.ActionContext.bridgeMint(
                                Charter.ActionContext.BridgeMintActionContext(
                                    assetSymbol: "USDC",
                                    bridgeType: .cctpV2,
                                    chainId: Number("42161"),  // Arbitrum
                                    sourceChainId: Number("8453"),  // Base
                                    // These values must match the burn side exactly!
                                    // With ceiling fix: inputAmount = 5153062, maxFee = 113062
                                    // Without ceiling fix: inputAmount = 5153061 (-1 error!), maxFee = 113061
                                    inputAmount: Number("5153062"),  // Must match burn side's inputAmount
                                    outputAmount: Number("5040000"),  // 5.04 USDC (mint output)
                                    maxFee: Number("113062"),  // 5153062 - 5040000 = 113062
                                    recipient: EthAddress(
                                        "0x00000000000000000000000000000000000a11ce"
                                    ),
                                    token: EthAddress(
                                        "0xaf88d065e77c8cc2239327c5edb3a432268e5831"  // USDC on Arbitrum
                                    )
                                )
                            ),
                            Charter.ActionContext.quotePay(
                                Charter.ActionContext.QuotePayActionContext(
                                    amount: Number("40000"),  // 0.04 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number("42161"),  // Arbitrum
                                    price: Number("1.0e8"),
                                    payee: EthAddress(
                                        "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                    ),
                                    quoteId: Hex(
                                        "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                    ),
                                    token: EthAddress(
                                        "0xaf88d065e77c8cc2239327c5edb3a432268e5831"  // USDC on Arbitrum
                                    )
                                )
                            ),
                            Charter.ActionContext.transfer(
                                Charter.ActionContext.TransferActionContext(
                                    amount: Number("5000000"),  // 5.0 USDC (5.04 - 0.04)
                                    assetSymbol: "USDC",
                                    chainId: Number("42161"),  // Arbitrum
                                    price: Number("1.0e8"),
                                    recipient: EthAddress(
                                        "0x00000000000000000000000000000000000b0b0b"
                                    ).on(Network.fromChainId(Number("42161"))),
                                    token: EthAddress(
                                        "0xaf88d065e77c8cc2239327c5edb3a432268e5831"  // USDC on Arbitrum
                                    ).on(Network.fromChainId(Number("42161")))
                                )
                            ),
                        ]),
                    ]
                )
            )
        )
    }

    @Test("Alice transfers USDC from Base to Bob on HyperEVM via Across Bridge")
    func testTransferUsdcFromBaseToBobOnHyperEVMViaAcross() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(50, .usdc),
                    on: .hyperEVM
                ),
                expect: .success(
                    .multi([
                        .bridge(
                            bridge: "Across",
                            srcNetwork: .base,
                            destinationNetwork: .hyperEVM,
                            inputTokenAmount: .amt(51.555556, .usdc),
                            outputTokenAmount: .amt(50.04, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transfer(
                                    tokenAmount: .amt(50, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .hyperEVM
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ])
                )
            )
        )
    }

    @Test("Alice transfers USDC from Base to Bob on HyperEVM via CCTPv2 Bridge")
    func testTransferUsdcFromBaseToBobOnHyperEVMViaCCTPv2() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .base),
                    .quote(.basic),
                    .cctpV2Quote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(
                    from: .alice,
                    to: .bob,
                    amount: .amt(50, .usdc),
                    on: .hyperEVM
                ),
                expect: .successWithActions(
                    .multi([
                        // CCTPv2 Burn standalone on source chain (Base) - no quotePay
                        .bridge(
                            bridge: "CCTPv2",
                            srcNetwork: .base,
                            destinationNetwork: .hyperEVM,
                            inputTokenAmount: .amt(51.555556, .usdc),
                            outputTokenAmount: .amt(50.04, .usdc),
                            cappedMax: false,
                            executionType: .immediate
                        ),
                        // CCTPv2 Mint and subsequent operations on destination chain (HyperEVM)
                        .multicall(
                            [
                                .bridgeMint(
                                    network: .hyperEVM,
                                    bridgeType: .CircleBridge,
                                    executionType: nil
                                ),
                                .quotePay(payment: .amt(0.04, .usdc), payee: .stax, quote: .basic),
                                .transfer(
                                    tokenAmount: .amt(50, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .hyperEVM
                                ),
                            ],
                            executionType: .contingent
                        ),
                    ]),
                    [
                        // Bridge standalone on source chain
                        .bridge(
                            Charter.ActionContext.BridgeActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .cctpV2,
                                chainId: Number("8453"),  // Base
                                destinationChainId: Number("999"),  // HyperEVM
                                destinationAssetSymbol: "USDC",
                                inputAmount: Number("51555556"),
                                outputAmount: Number("50040000"),
                                price: Number("1.0e8"),
                                recipient: EthAddress(
                                    "0x00000000000000000000000000000000000a11ce"
                                ),
                                token: EthAddress(
                                    "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"  // USDC on Base
                                )
                            )
                        ),
                        // Mint, quote pay, and transfer happen together on destination chain
                        .multiAction([
                            Charter.ActionContext.bridgeMint(
                                Charter.ActionContext.BridgeMintActionContext(
                                    assetSymbol: "USDC",
                                    bridgeType: .cctpV2,
                                    chainId: Number("999"),  // HyperEVM
                                    sourceChainId: Number("8453"),  // Base
                                    inputAmount: Number("51555556"),
                                    outputAmount: Number("50040000"),
                                    maxFee: Number("1515556"),
                                    recipient: EthAddress(
                                        "0x00000000000000000000000000000000000a11ce"
                                    ),
                                    token: EthAddress(
                                        "0xb88339cb7199b77e23db6e890353e22632ba630f"  // USDC on HyperEVM
                                    )
                                )
                            ),
                            Charter.ActionContext.quotePay(
                                Charter.ActionContext.QuotePayActionContext(
                                    amount: Number("40000"),  // 0.04 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number("999"),  // HyperEVM
                                    price: Number("1.0e8"),
                                    payee: EthAddress(
                                        "0x7ea8d6119596016935543d90ee8f5126285060a1"
                                    ),
                                    quoteId: Hex(
                                        "0x00000000000000000000000000000000000000000000000000000000000000cc"
                                    ),
                                    token: EthAddress(
                                        "0xb88339cb7199b77e23db6e890353e22632ba630f"  // USDC on HyperEVM
                                    )
                                )
                            ),
                            Charter.ActionContext.transfer(
                                Charter.ActionContext.TransferActionContext(
                                    amount: Number("50000000"),  // 50 USDC
                                    assetSymbol: "USDC",
                                    chainId: Number("999"),  // HyperEVM
                                    price: Number("1.0e8"),
                                    recipient: EthAddress(
                                        "0x00000000000000000000000000000000000b0b0b"
                                    ).on(Network.fromChainId(Number("999"))),
                                    token: EthAddress(
                                        "0xb88339cb7199b77e23db6e890353e22632ba630f"  // USDC on HyperEVM
                                    ).on(Network.fromChainId(Number("999")))
                                )
                            ),
                        ]),
                    ]
                )
            )
        )
    }
}
