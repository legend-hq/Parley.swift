import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Step Generation Tests")
struct StepGenerationTests {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    // MARK: - Helpers

    private func makeAction(
        chainId: Number,
        actionType: String,
        actionContext: Charter.ActionContext,
        executionType: Charter.Chart.Action.ExecutionType
    ) -> Charter.Chart.EVMAction {
        Charter.Chart.EVMAction(
            chainId: chainId,
            quarkAccount: EthAddress("0x1234567890123456789012345678901234567890"),
            actionType: actionType,
            actionContext: actionContext,
            nonceSecret: Hex(Data(repeating: 0xAB, count: 32)),
            totalPlays: 1,
            executionType: executionType
        )
    }

    private func makeSwapContext(chainId: Number) -> Charter.ActionContext {
        .swap(
            Charter.ActionContext.SwapActionContext(
                chainId: chainId,
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
    }

    private func makeBridgeContext(
        srcChainId: Number,
        dstChainId: Number,
        bridgeType: Charter.ActionContext.BridgeActionContext.BridgeType = .across
    ) -> Charter.ActionContext {
        .bridge(
            Charter.ActionContext.BridgeActionContext(
                assetSymbol: "USDC",
                bridgeType: bridgeType,
                chainId: srcChainId,
                destinationChainId: dstChainId,
                destinationAssetSymbol: "USDC",
                inputAmount: Number("1e6"),
                outputAmount: Number("0.99e6"),
                price: Number("1e8"),
                recipient: EthAddress("0x1234567890123456789012345678901234567890"),
                token: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913")
            )
        )
    }

    private func makeTransferContext(chainId: Number) -> Charter.ActionContext {
        .transfer(
            Charter.ActionContext.TransferActionContext(
                amount: Number("1e6"),
                assetSymbol: "USDC",
                chainId: chainId,
                price: Number("1e8"),
                recipient: EthAddress("0x1234567890123456789012345678901234567890").on(Network.fromChainId(chainId)),
                token: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913").on(Network.fromChainId(chainId))
            )
        )
    }

    // MARK: - Single chain, single action

    @Test("Single-chain swap produces 1 quark_operation step, no exogenous steps")
    func singleChainSwap() throws {
        let actions = [
            makeAction(
                chainId: Number("8453"),
                actionType: "SWAP",
                actionContext: makeSwapContext(chainId: Number("8453")),
                executionType: .immediate
            )
        ]

        let steps = Charter.generateSteps(actions: actions)

        #expect(steps.count == 1)

        guard case .quarkOperation(let qoStep) = steps[0] else {
            Issue.record("Expected quark_operation step at index 0")
            return
        }
        #expect(qoStep.chainId == Number("8453"))
        #expect(qoStep.operationIndex == 0)
        #expect(qoStep.dependsOn == [])
        #expect(qoStep.expectedActions.count == 1)
        #expect(qoStep.expectedActions[0].actionType == "SWAP")
    }

    // MARK: - Bridge intent (cross-chain)

    @Test("Bridge intent produces correct step DAG: quark_op -> exogenous -> quark_op")
    func bridgeIntent() throws {
        let bridgeContext = makeBridgeContext(
            srcChainId: Number("1"),
            dstChainId: Number("8453")
        )

        let actions = [
            // Step 0: IMMEDIATE bridge send on chain 1
            makeAction(
                chainId: Number("1"),
                actionType: "BRIDGE",
                actionContext: bridgeContext,
                executionType: .immediate
            ),
            // Step 2: CONTINGENT swap on chain 8453 (depends on bridge receive)
            makeAction(
                chainId: Number("8453"),
                actionType: "SWAP",
                actionContext: makeSwapContext(chainId: Number("8453")),
                executionType: .contingent
            ),
        ]

        let steps = Charter.generateSteps(actions: actions)

        // Should produce 3 steps:
        // [0] quark_operation (bridge send, chain 1, dependsOn: [])
        // [1] exogenous (bridge receive, chain 8453, dependsOn: [0])
        // [2] quark_operation (swap, chain 8453, dependsOn: [1])
        #expect(steps.count == 3)

        // Step 0: quark_operation for bridge send
        guard case .quarkOperation(let sendStep) = steps[0] else {
            Issue.record("Expected quark_operation step at index 0")
            return
        }
        #expect(sendStep.chainId == Number("1"))
        #expect(sendStep.operationIndex == 0)
        #expect(sendStep.dependsOn == [])
        #expect(sendStep.expectedActions.count == 1)
        #expect(sendStep.expectedActions[0].actionType == "BRIDGE")

        // Step 1: exogenous bridge receive
        guard case .exogenous(let bridgeReceiveStep) = steps[1] else {
            Issue.record("Expected exogenous step at index 1")
            return
        }
        #expect(bridgeReceiveStep.chainId == Number("8453"))
        #expect(bridgeReceiveStep.executionType == .bridgeReceive)
        #expect(bridgeReceiveStep.dependsOn == [0])
        #expect(bridgeReceiveStep.expectedActions.count == 1)
        #expect(bridgeReceiveStep.expectedActions[0].actionType == "BRIDGE_MINT")

        // Step 2: quark_operation for swap (depends on bridge receive)
        guard case .quarkOperation(let swapStep) = steps[2] else {
            Issue.record("Expected quark_operation step at index 2")
            return
        }
        #expect(swapStep.chainId == Number("8453"))
        #expect(swapStep.operationIndex == 1)
        #expect(swapStep.dependsOn == [1])
    }

    // MARK: - Multi-action on one chain

    @Test("Multi-action extracts expected actions per sub-context")
    func multiActionExpectedActions() throws {
        let transferContext = makeTransferContext(chainId: Number("8453"))
        let swapContext = makeSwapContext(chainId: Number("8453"))
        let multiAction = Charter.ActionContext.multiAction([transferContext, swapContext])

        let actions = [
            makeAction(
                chainId: Number("8453"),
                actionType: Charter.ActionContext.MultiActionContext.actionType,
                actionContext: multiAction,
                executionType: .immediate
            )
        ]

        let steps = Charter.generateSteps(actions: actions)

        #expect(steps.count == 1)

        guard case .quarkOperation(let qoStep) = steps[0] else {
            Issue.record("Expected quark_operation step at index 0")
            return
        }
        #expect(qoStep.expectedActions.count == 2)
        #expect(qoStep.expectedActions[0].actionType == "TRANSFER")
        #expect(qoStep.expectedActions[1].actionType == "SWAP")
        #expect(qoStep.dependsOn == [])
    }

    // MARK: - Multi-action with bridge (bridge + swap on source chain)

    @Test("Multi-action containing bridge produces exogenous step for destination")
    func multiActionWithBridge() throws {
        let bridgeContext = makeBridgeContext(
            srcChainId: Number("1"),
            dstChainId: Number("8453")
        )
        let swapContext = makeSwapContext(chainId: Number("1"))
        let multiAction = Charter.ActionContext.multiAction([swapContext, bridgeContext])

        let actions = [
            // Source chain: multi-action with swap + bridge
            makeAction(
                chainId: Number("1"),
                actionType: Charter.ActionContext.MultiActionContext.actionType,
                actionContext: multiAction,
                executionType: .immediate
            ),
            // Destination chain: contingent on bridge receive
            makeAction(
                chainId: Number("8453"),
                actionType: "SWAP",
                actionContext: makeSwapContext(chainId: Number("8453")),
                executionType: .contingent
            ),
        ]

        let steps = Charter.generateSteps(actions: actions)

        #expect(steps.count == 3)

        // Step 0: quark_operation (multi-action on chain 1)
        guard case .quarkOperation(let srcStep) = steps[0] else {
            Issue.record("Expected quark_operation step at index 0")
            return
        }
        #expect(srcStep.expectedActions.count == 2)
        #expect(srcStep.dependsOn == [])

        // Step 1: exogenous bridge receive on chain 8453
        guard case .exogenous(let exoStep) = steps[1] else {
            Issue.record("Expected exogenous step at index 1")
            return
        }
        #expect(exoStep.chainId == Number("8453"))
        #expect(exoStep.dependsOn == [0])

        // Step 2: quark_operation on chain 8453 (depends on exogenous)
        guard case .quarkOperation(let dstStep) = steps[2] else {
            Issue.record("Expected quark_operation step at index 2")
            return
        }
        #expect(dstStep.dependsOn == [1])
    }

    // MARK: - Fan-in: two bridges to the same destination chain

    @Test("Fan-in bridges (A->D, C->D) produce two exogenous steps and contingent depends on both")
    func fanInBridges() throws {
        let actions = [
            // Op 0: IMMEDIATE bridge A->D
            makeAction(
                chainId: Number("8453"),
                actionType: "BRIDGE",
                actionContext: makeBridgeContext(
                    srcChainId: Number("8453"),
                    dstChainId: Number("1")
                ),
                executionType: .immediate
            ),
            // Op 1: IMMEDIATE bridge C->D
            makeAction(
                chainId: Number("42161"),
                actionType: "BRIDGE",
                actionContext: makeBridgeContext(
                    srcChainId: Number("42161"),
                    dstChainId: Number("1")
                ),
                executionType: .immediate
            ),
            // Op 2: CONTINGENT swap on D (depends on both bridge receives)
            makeAction(
                chainId: Number("1"),
                actionType: "SWAP",
                actionContext: makeSwapContext(chainId: Number("1")),
                executionType: .contingent
            ),
        ]

        let steps = Charter.generateSteps(actions: actions)

        // Expected: 5 steps
        // [0] quark_operation (bridge A->D, dependsOn: [])
        // [1] exogenous (bridge receive on D from A, dependsOn: [0])
        // [2] quark_operation (bridge C->D, dependsOn: [])
        // [3] exogenous (bridge receive on D from C, dependsOn: [2])
        // [4] quark_operation (swap on D, dependsOn: [1, 3])
        #expect(steps.count == 5)

        // Step 0: bridge send from A
        guard case .quarkOperation(let op0) = steps[0] else {
            Issue.record("Expected quark_operation at index 0")
            return
        }
        #expect(op0.operationIndex == 0)
        #expect(op0.dependsOn == [])

        // Step 1: exogenous bridge receive on D (from A)
        guard case .exogenous(let exo1) = steps[1] else {
            Issue.record("Expected exogenous at index 1")
            return
        }
        #expect(exo1.chainId == Number("1"))
        #expect(exo1.dependsOn == [0])

        // Step 2: bridge send from C
        guard case .quarkOperation(let op2) = steps[2] else {
            Issue.record("Expected quark_operation at index 2")
            return
        }
        #expect(op2.operationIndex == 1)
        #expect(op2.dependsOn == [])

        // Step 3: exogenous bridge receive on D (from C)
        guard case .exogenous(let exo3) = steps[3] else {
            Issue.record("Expected exogenous at index 3")
            return
        }
        #expect(exo3.chainId == Number("1"))
        #expect(exo3.dependsOn == [2])

        // Step 4: contingent swap on D depends on BOTH exogenous steps
        guard case .quarkOperation(let op4) = steps[4] else {
            Issue.record("Expected quark_operation at index 4")
            return
        }
        #expect(op4.operationIndex == 2)
        #expect(op4.dependsOn == [1, 3])
    }

    // MARK: - Step Codable round-trip

    @Test("Step encoding/decoding round-trip for quark_operation")
    func quarkOperationStepCodable() throws {
        let step = Charter.Chart.Step.quarkOperation(
            Charter.Chart.Step.OperationStep(
                chainId: Number("8453"),
                operationIndex: 0,
                expectedActions: [
                    Charter.Chart.ExpectedAction(
                        actionType: "SWAP",
                        actionContext: makeSwapContext(chainId: Number("8453"))
                    )
                ],
                dependsOn: []
            )
        )

        let data = try encoder.encode(step)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify discriminator
        #expect(json["type"] as? String == "quark_operation")
        #expect(json["chain_id"] as? String == "8453")
        #expect(json["operation_index"] as? Int == 0)
        #expect((json["depends_on"] as? [Int]) == [])

        // Round-trip
        let decoded = try decoder.decode(Charter.Chart.Step.self, from: data)
        #expect(decoded == step)
    }

    @Test("Step encoding/decoding round-trip for exogenous")
    func exogenousStepCodable() throws {
        let step = Charter.Chart.Step.exogenous(
            Charter.Chart.Step.ExogenousStep(
                chainId: Number("8453"),
                executionType: .bridgeReceive,
                expectedActions: [
                    Charter.Chart.ExpectedAction(
                        actionType: "BRIDGE_MINT",
                        actionContext: .bridgeMint(
                            Charter.ActionContext.BridgeMintActionContext(
                                assetSymbol: "USDC",
                                bridgeType: .across,
                                chainId: Number("8453"),
                                sourceChainId: Number("1"),
                                inputAmount: Number("1e6"),
                                outputAmount: Number("0.99e6"),
                                maxFee: Number("0.01e6"),
                                recipient: EthAddress("0x1234567890123456789012345678901234567890"),
                                token: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913")
                            )
                        )
                    )
                ],
                dependsOn: [0]
            )
        )

        let data = try encoder.encode(step)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["type"] as? String == "exogenous")
        #expect(json["execution_type"] as? String == "bridge_receive")
        #expect(json["chain_id"] as? String == "8453")
        #expect((json["depends_on"] as? [Int]) == [0])

        // Round-trip
        let decoded = try decoder.decode(Charter.Chart.Step.self, from: data)
        #expect(decoded == step)
    }

    // MARK: - ExpectedAction encoding contract

    @Test("ExpectedAction action_context does not contain redundant action_type")
    func expectedActionContextExcludesActionType() throws {
        let expectedAction = Charter.Chart.ExpectedAction(
            actionType: "SWAP",
            actionContext: makeSwapContext(chainId: Number("8453"))
        )

        let data = try encoder.encode(expectedAction)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // action_type at the top level
        #expect(json["action_type"] as? String == "SWAP")

        // action_context should NOT contain action_type (it lives on the expected_action level)
        let actionContext = json["action_context"] as! [String: Any]
        #expect(actionContext["action_type"] == nil)
        #expect(actionContext["chain_id"] as? String == "8453")
        #expect(actionContext["input_amount"] != nil)
        #expect(actionContext["output_amount"] != nil)
    }

    @Test("ExpectedAction round-trip after encoding fix")
    func expectedActionRoundTrip() throws {
        let expectedAction = Charter.Chart.ExpectedAction(
            actionType: "BRIDGE_MINT",
            actionContext: .bridgeMint(
                Charter.ActionContext.BridgeMintActionContext(
                    assetSymbol: "USDC",
                    bridgeType: .across,
                    chainId: Number("8453"),
                    sourceChainId: Number("1"),
                    inputAmount: Number("1e6"),
                    outputAmount: Number("0.99e6"),
                    maxFee: Number("0.01e6"),
                    recipient: EthAddress("0x1234567890123456789012345678901234567890"),
                    token: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913")
                )
            )
        )

        let data = try encoder.encode(expectedAction)
        let decoded = try decoder.decode(Charter.Chart.ExpectedAction.self, from: data)
        #expect(decoded == expectedAction)
    }

    @Test("Step with ExpectedAction round-trips correctly after encoding fix")
    func stepWithExpectedActionRoundTrip() throws {
        let step = Charter.Chart.Step.quarkOperation(
            Charter.Chart.Step.OperationStep(
                chainId: Number("8453"),
                operationIndex: 0,
                expectedActions: [
                    Charter.Chart.ExpectedAction(
                        actionType: "SWAP",
                        actionContext: makeSwapContext(chainId: Number("8453"))
                    ),
                    Charter.Chart.ExpectedAction(
                        actionType: "TRANSFER",
                        actionContext: .transfer(
                            Charter.ActionContext.TransferActionContext(
                                amount: Number("1e6"),
                                assetSymbol: "USDC",
                                chainId: Number("8453"),
                                price: Number("1e8"),
                                recipient: EthAddress("0x1234567890123456789012345678901234567890").on(Network.fromChainId(Number("8453"))),
                                token: EthAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913").on(Network.fromChainId(Number("8453")))
                            )
                        )
                    ),
                ],
                dependsOn: []
            )
        )

        let data = try encoder.encode(step)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify expected_actions encoding
        let expectedActions = json["expected_actions"] as! [[String: Any]]
        #expect(expectedActions.count == 2)

        // Each expected_action's action_context should NOT contain action_type
        for ea in expectedActions {
            let ctx = ea["action_context"] as! [String: Any]
            #expect(ctx["action_type"] == nil)
        }

        // Verify action_type at the expected_action level
        #expect(expectedActions[0]["action_type"] as? String == "SWAP")
        #expect(expectedActions[1]["action_type"] as? String == "TRANSFER")

        // Round-trip
        let decoded = try decoder.decode(Charter.Chart.Step.self, from: data)
        #expect(decoded == step)
    }

    // MARK: - Solana step encoding/decoding

    @Test("Step encoding/decoding round-trip for solana_operation")
    func solanaOperationStepCodable() throws {
        let step = Charter.Chart.Step.solanaOperation(
            Charter.Chart.Step.OperationStep(
                chainId: Network.solana.chainId,
                operationIndex: 0,
                expectedActions: [
                    Charter.Chart.ExpectedAction(
                        actionType: "TRANSFER",
                        actionContext: .transfer(
                            Charter.ActionContext.TransferActionContext(
                                amount: Number("1e6"),
                                assetSymbol: "USDC",
                                chainId: Network.solana.chainId,
                                price: Number("1e8"),
                                recipient: .solana(SolanaAddress(
                                    fromBase58: "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
                                )!),
                                token: .solana(Atlas.Solana.Assets.USDC.assetAddress)
                            )
                        )
                    )
                ],
                dependsOn: []
            )
        )

        let data = try encoder.encode(step)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify discriminator
        #expect(json["type"] as? String == "solana_operation")
        #expect(json["chain_id"] as? String == Network.solana.chainId.description)
        #expect(json["operation_index"] as? Int == 0)
        #expect((json["depends_on"] as? [Int]) == [])

        // Round-trip
        let decoded = try decoder.decode(Charter.Chart.Step.self, from: data)
        #expect(decoded == step)
    }

    @Test("Single Solana operation action produces 1 solana_operation step")
    func singleSolanaOperationAction() {
        let amount = TokenAmount.amt(5, .usdc)
        let operationAction = Charter.SolanaOperationBuilder.transfer(
            sender: Account.alice.solanaAddress,
            recipient: Account.bob.solanaAddress,
            assetSymbol: amount.token.symbol,
            mint: Atlas.Solana.Assets.USDC.assetAddress,
            amount: amount.toAmount.underlying,
            decimals: amount.token.decimals,
            price: Number("1e8"),
            feePayer: SolanaFixtures.feePayer
        )

        let steps = Charter.generateStepsFromOperationActions([operationAction])

        #expect(steps.count == 1)

        guard case .solanaOperation(let step) = steps[0] else {
            Issue.record("Expected solana_operation step at index 0")
            return
        }
        #expect(step.chainId == Network.solana.chainId)
        #expect(step.operationIndex == 0)
        #expect(step.dependsOn == [])
        #expect(step.expectedActions.count == 1)
        #expect(step.expectedActions[0].actionType == "TRANSFER")
    }
}
