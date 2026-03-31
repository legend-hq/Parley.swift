@preconcurrency import Eth
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("QuotePay Tests")
struct QuotePayTests {
    @Test("Alice pays with QuotePay using USDC")
    func testQuotePayWithUSDC() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(100, .usdc), .ethereum),
                    .quote(.basic),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(10, .usdc), on: .ethereum),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                .transfer(
                                    tokenAmount: .amt(10, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .ethereum
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
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("10e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ).on(Network.fromChainId(Number("1"))),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
                                        ).on(Network.fromChainId(Number("1")))
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
        "Alice performs action using WETH while also paying with QuotePay using WETH (should wrap only once)"
    )
    func testQuotePayOnlyWrapsOnce() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(1, .eth), .ethereum),
                    .quote(.basic),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(0.5, .weth), on: .ethereum),
                expect: .successWithActions(
                    .single(
                        .multicall(
                            [
                                .wrapAsset(.eth),
                                .quotePay(
                                    payment: .amt(0.000025, .weth),
                                    payee: .stax,
                                    quote: .basic
                                ),
                                .transfer(
                                    tokenAmount: .amt(0.5, .weth),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .ethereum
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
                                        chainId: Number("1"),
                                        amount: Number("0.500025e18"),
                                        token: EthAddress(
                                            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                                        ),
                                        fromAssetSymbol: "ETH",
                                        toAssetSymbol: "WETH"
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
                                Charter.ActionContext.transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("0.5e18"),
                                        assetSymbol: "WETH",
                                        chainId: Number("1"),
                                        price: Number("4000e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ).on(Network.fromChainId(Number("1"))),
                                        token: EthAddress(
                                            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                                        ).on(Network.fromChainId(Number("1")))
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
        "Alice does not have enough ETH to cover QuotePay cost after spending it on an action"
    )
    func testNotEnoughEthToCoverQuotePayCost() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(0.5, .eth), .ethereum),
                    .quote(.basic),
                ],
                when: .payWith(
                    currency: .weth,
                    .transfer(from: .alice, to: .bob, amount: .amt(0.5, .weth), on: .ethereum)
                ),
                // Note: Previously expected .revert(.unableToConstructQuotePay("IMPOSSIBLE_TO_CONSTRUCT", "WETH", 0))
                // but Tradewinds now returns .error("insufficientResources") when QuotePay cannot be constructed after other actions
                expect: .failure(
                    .error(
                        "insufficientResources(target: .exact(500000000000000000), max: 499975000000000000)"
                    )
                )
            )
        )
    }
}
