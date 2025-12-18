import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Charter

@Suite("ActionContext Encoding Tests")
struct ActionContextEncodingTests {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    // MARK: - Multi Action Tests

    @Test("MultiAction encoding with multiple actions")
    func multiActionEncoding() throws {
        // Create some sample actions to include in the multi-action
        let transferAction = Charter.ActionContext.transfer(
            Charter.ActionContext.TransferActionContext(
                amount: Number("1e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),  // Base chain
                price: Number("1e8"),
                recipient: EthAddress("0x1234567890123456789012345678901234567890"),
                token: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913")
            )
        )

        let swapAction = Charter.ActionContext.swap(
            Charter.ActionContext.SwapActionContext(
                chainId: Number("8453"),
                feeAmounts: [Number("0.001e6")],
                feeAssetSymbols: ["USDC"],
                feeTokens: [EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913")],
                feeTokenPrices: [Number("1e8")],
                feeDescriptions: ["LEGEND"],
                inputAmount: Number("1e6"),
                inputAssetSymbol: "USDC",
                inputToken: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"),
                inputTokenPrice: Number("1e8"),
                outputAmount: Number("1e18"),
                outputAssetSymbol: "ETH",
                outputToken: EthAddress("0x4200000000000000000000000000000000000006"),
                outputTokenPrice: Number("3000e8"),
                isExactOut: false,
                isBuy: false,
                isCappedMax: false,
                useFiller: false
            )
        )

        // Create the multi-action
        let multiAction = Charter.ActionContext.multiAction([transferAction, swapAction])

        // Encode it
        let data = try encoder.encode(multiAction)
        let json = String(data: data, encoding: .utf8)!

        // Print for debugging
        print("Encoded JSON:")
        print(json)

        // Parse the JSON to verify structure
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify the top-level action_type
        #expect(jsonObject["action_type"] as? String == "MULTI_ACTION")

        // Verify action_types array at root level
        let actionTypes = jsonObject["action_types"] as? [String]
        #expect(actionTypes == ["TRANSFER", "SWAP"])

        // Verify action_contexts array exists and has 2 elements at root level
        let actionContexts = jsonObject["action_contexts"] as? [[String: Any]]
        #expect(actionContexts?.count == 2)

        // Verify first action context (transfer)
        if let transferContext = actionContexts?[0] {
            #expect(transferContext["amount"] as? String == "1000000")
            #expect(transferContext["asset_symbol"] as? String == "USDC")
            #expect(transferContext["chain_id"] as? String == "8453")
        }

        // Verify second action context (swap)
        if let swapContext = actionContexts?[1] {
            #expect(swapContext["input_amount"] as? String == "1000000")
            #expect(swapContext["input_asset_symbol"] as? String == "USDC")
            #expect(swapContext["output_asset_symbol"] as? String == "ETH")
        }

        // Also verify that we can decode it back
        let decoded = try decoder.decode(Charter.ActionContext.self, from: data)
        if case .multiAction(let decodedActions) = decoded {
            #expect(decodedActions.count == 2)

            // Verify the decoded actions match
            if case .transfer(let decodedTransfer) = decodedActions[0] {
                #expect(decodedTransfer.amount == Number("1e6"))
                #expect(decodedTransfer.assetSymbol == "USDC")
            } else {
                Issue.record("Expected first action to be transfer")
            }

            if case .swap(let decodedSwap) = decodedActions[1] {
                #expect(decodedSwap.inputAmount == Number("1e6"))
                #expect(decodedSwap.outputAssetSymbol == "ETH")
            } else {
                Issue.record("Expected second action to be swap")
            }
        } else {
            Issue.record("Expected decoded result to be multiAction")
        }
    }

    @Test("MultiAction encoding with empty actions")
    func multiActionEncodingEmpty() throws {
        let multiAction = Charter.ActionContext.multiAction([])

        let data = try encoder.encode(multiAction)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(jsonObject["action_type"] as? String == "MULTI_ACTION")
        #expect((jsonObject["action_types"] as? [String])?.isEmpty == true)
        #expect((jsonObject["action_contexts"] as? [Any])?.isEmpty == true)
    }

    @Test("MultiAction encoding with single action")
    func multiActionEncodingSingle() throws {
        let transferAction = Charter.ActionContext.transfer(
            Charter.ActionContext.TransferActionContext(
                amount: Number("1e6"),
                assetSymbol: "USDC",
                chainId: Number("1"),
                price: Number("1e8"),
                recipient: EthAddress("0x1234567890123456789012345678901234567890"),
                token: EthAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
            )
        )

        let multiAction = Charter.ActionContext.multiAction([transferAction])

        let data = try encoder.encode(multiAction)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(jsonObject["action_type"] as? String == "MULTI_ACTION")
        #expect(jsonObject["action_types"] as? [String] == ["TRANSFER"])
        #expect((jsonObject["action_contexts"] as? [Any])?.count == 1)
    }

    @Test("MultiAction round-trip encoding/decoding")
    func multiActionRoundTrip() throws {
        // Create various action types to test

        let swapAction = Charter.ActionContext.swap(
            Charter.ActionContext.SwapActionContext(
                chainId: Number("1"),
                feeAmounts: [Number("0.0015e6")],
                feeAssetSymbols: ["USDC"],
                feeTokens: [EthAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")],
                feeTokenPrices: [Number("1e8")],
                feeDescriptions: ["LEGEND"],
                inputAmount: Number("2e6"),
                inputAssetSymbol: "USDC",
                inputToken: EthAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"),
                inputTokenPrice: Number("1e8"),
                outputAmount: Number("1e18"),
                outputAssetSymbol: "ETH",
                outputToken: EthAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"),
                outputTokenPrice: Number("2000e8"),
                isExactOut: true,
                isBuy: true,
                isCappedMax: false,
                useFiller: true
            )
        )

        let bridgeAction = Charter.ActionContext.bridge(
            Charter.ActionContext.BridgeActionContext(
                assetSymbol: "USDC",
                bridgeType: .across,
                chainId: Number("1"),
                destinationChainId: Number("8453"),
                destinationAssetSymbol: "USDC",
                inputAmount: Number("1e6"),
                outputAmount: Number("0.99e6"),
                price: Number("1e8"),
                recipient: EthAddress("0x1234567890123456789012345678901234567890"),
                token: EthAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
            )
        )

        // Create original multiAction
        let originalMultiAction = Charter.ActionContext.multiAction([swapAction, bridgeAction])

        // Encode
        let data = try encoder.encode(originalMultiAction)

        // Print the encoded JSON
        let jsonString = String(data: data, encoding: .utf8)!
        print("Round-trip test - Encoded JSON:")
        print(jsonString)

        // Decode
        let decodedMultiAction = try decoder.decode(Charter.ActionContext.self, from: data)

        // Verify it's a multiAction
        guard case .multiAction(let decodedActions) = decodedMultiAction else {
            Issue.record("Expected decoded result to be multiAction")
            return
        }

        // Verify count matches
        #expect(decodedActions.count == 2)

        // Verify each action matches
        if case .swap(let decodedSwap) = decodedActions[0] {
            #expect(decodedSwap.chainId == Number("1"))
            #expect(decodedSwap.feeAmounts == [Number("0.0015e6")])
            #expect(decodedSwap.feeAssetSymbols == ["USDC"])
            #expect(decodedSwap.inputAmount == Number("2e6"))
            #expect(decodedSwap.inputAssetSymbol == "USDC")
            #expect(decodedSwap.outputAmount == Number("1e18"))
            #expect(decodedSwap.outputAssetSymbol == "ETH")
            #expect(decodedSwap.isExactOut == true)
            #expect(decodedSwap.isBuy == true)
            #expect(decodedSwap.isCappedMax == false)
            #expect(decodedSwap.useFiller == true)
        } else {
            Issue.record("Expected first action to be swap")
        }

        if case .bridge(let decodedBridge) = decodedActions[1] {
            #expect(decodedBridge.assetSymbol == "USDC")
            #expect(decodedBridge.bridgeType == .across)
            #expect(decodedBridge.chainId == Number("1"))
            #expect(decodedBridge.destinationChainId == Number("8453"))
            #expect(decodedBridge.destinationAssetSymbol == "USDC")
            #expect(decodedBridge.inputAmount == Number("1e6"))
            #expect(decodedBridge.outputAmount == Number("0.99e6"))
            #expect(decodedBridge.price == Number("1e8"))
            #expect(
                decodedBridge.recipient == EthAddress("0x1234567890123456789012345678901234567890")
            )
            #expect(decodedBridge.token == EthAddress("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"))
        } else {
            Issue.record("Expected second action to be bridge")
        }

        // Test equality if ActionContext conforms to Equatable
        #expect(decodedMultiAction == originalMultiAction)
    }
}
