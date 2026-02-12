import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

@Suite("Folio Patch Type Tests")
struct FolioPatchTypeTests {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    // MARK: - Single Patch Roundtrip

    @Test("Single patch JSON roundtrip")
    func singlePatchRoundtrip() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "-10e18"
                    )
                ]
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("token/base/USDC/0xaabbccddee1234567890abcdef1234567890abcd"))
        #expect(json.contains("\"-10e18\""))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Multiple Patches Per Trigger (Swap)

    @Test("Multiple patches per trigger for swap")
    func multiplePatchesPerTrigger() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000005"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "-100e6"
                    ),
                    Folio.Patch(
                        target: .token(network: .base, symbol: "WETH", wallet: wallet),
                        delta: "0.04e18"
                    ),
                ]
            ]
        )

        let data = try encoder.encode(folio)
        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Patch With Metadata

    @Test("Patch with full metadata")
    func patchWithMetadata() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "10e6",
                        metadata: Folio.PatchMetadata(
                            operationType: .slowRefund,
                            estimatedEta: 1_739_400_600
                        )
                    )
                ]
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"operation_type\" : \"slow_refund\""))
        #expect(json.contains("\"estimated_eta\" : 1739400600"))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    @Test("Patch with partial metadata — only operationType")
    func patchWithPartialMetadataOperationType() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "10e6",
                        metadata: Folio.PatchMetadata(operationType: .slowRefund)
                    )
                ]
            ]
        )

        let data = try encoder.encode(folio)
        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    @Test("Patch with partial metadata — only estimatedEta")
    func patchWithPartialMetadataEta() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "10e6",
                        metadata: Folio.PatchMetadata(estimatedEta: 1_739_400_600)
                    )
                ]
            ]
        )

        let data = try encoder.encode(folio)
        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Patch With OperationId

    @Test("Patch with operationId")
    func patchWithOperationId() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"
        let operationId: Hex = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "-50e6",
                        operationId: operationId
                    )
                ]
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        #expect(
            json.contains(
                "\"operation_id\" : \"0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890\""
            )
        )

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Bridge Scenario — Two Triggers

    @Test("Bridge scenario with two triggers")
    func bridgeTwoTriggers() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000005"
        let relayHash: Hex = "0x1111111111111111111111111111111111111111111111111111111111111111"
        let operationId: Hex = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "-100e6",
                        operationId: operationId
                    )
                ],
                .acrossFill(wallet: wallet, relayHash: relayHash): [
                    Folio.Patch(
                        target: .token(network: .arbitrum, symbol: "USDC", wallet: wallet),
                        delta: "99e6",
                        operationId: operationId
                    )
                ],
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("quark_nonce"))
        #expect(json.contains("across_fill"))
        #expect(json.contains("token/base/USDC"))
        #expect(json.contains("token/arbitrum/USDC"))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Empty Patches

    @Test("Empty patches field roundtrip")
    func emptyPatches() throws {
        let folio = Folio()

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"patches\" : {\n\n  }"))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }

    // MARK: - Full Folio With Patches + Balances

    @Test("Full Folio with patches and balances")
    func fullFolioWithPatchesAndBalances() throws {
        let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000005"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet): Amount(
                    "100000000",
                    decimals: 6
                ),
                .token(network: .base, symbol: "WETH", wallet: wallet): Amount(
                    "500000000000000000",
                    decimals: 18
                ),
            ],
            prices: [
                .token(symbol: "USDC"): Value("100000000"),
                .token(symbol: "WETH"): Value("245000000000"),
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet),
                        delta: "-50e6"
                    ),
                    Folio.Patch(
                        target: .token(network: .base, symbol: "WETH", wallet: wallet),
                        delta: "0.02e18"
                    ),
                ]
            ]
        )

        let data = try encoder.encode(folio)
        let json = String(data: data, encoding: .utf8)!

        // Verify both balances and patches are present
        #expect(json.contains("\"balances\""))
        #expect(json.contains("\"patches\""))
        #expect(json.contains("\"prices\""))

        let decoded = try decoder.decode(Folio.self, from: data)
        #expect(decoded == folio)
    }
}
