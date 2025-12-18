@preconcurrency import Eth
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Multi Account Tests Tests")
struct MultiAccountTests {
    @Test("Alice transfers 10 USDC to Bob on Ethereum by sourcing founds from Carl on Base")
    func testMultiAccountTransferWithBridgeAndQuotePay() async throws {
        try await testAcceptanceTests(
            test: .init(
                given: [
                    .tokenBalance(.alice, .amt(20, .usdc), .base),
                    .tokenBalance(.carl, .amt(100, .usdc), .base),
                    .quote(.basic),
                    .acrossQuote(.amt(1, .usdc), 0.01),
                ],
                when: .transfer(from: .alice, to: .bob, amount: .amt(10, .usdc), on: .ethereum),
                expect: .successWithActions(
                    .multi([
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.02, .usdc), payee: .stax, quote: .basic),
                                .bridge(
                                    bridge: "Across",
                                    srcNetwork: .base,
                                    destinationNetwork: .ethereum,
                                    inputTokenAmount: .amt(11.212122, .usdc),
                                    outputTokenAmount: .amt(10.10, .usdc),
                                    cappedMax: false
                                ),
                            ],
                            executionType: .immediate
                        ),
                        .multicall(
                            [
                                .quotePay(payment: .amt(0.10, .usdc), payee: .stax, quote: .basic),
                                .transferErc20(
                                    tokenAmount: .amt(10, .usdc),
                                    recipient: .bob,
                                    cappedMax: false,
                                    network: .ethereum
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
                                        destinationChainId: Number("1"),
                                        destinationAssetSymbol: "USDC",
                                        inputAmount: Number("11.212122e6"),
                                        outputAmount: Number("10.1e6"),
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
                                .transfer(
                                    Charter.ActionContext.TransferActionContext(
                                        amount: Number("10e6"),
                                        assetSymbol: "USDC",
                                        chainId: Number("1"),
                                        price: Number("1e8"),
                                        recipient: EthAddress(
                                            "0x00000000000000000000000000000000000b0b0b"
                                        ),
                                        token: EthAddress(
                                            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
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
}
