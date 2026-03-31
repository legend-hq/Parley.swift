import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

@Suite("Solana Operation Builder Tests")
struct SolanaOperationBuilderTests {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let usdcMint = Atlas.Solana.Assets.USDC.assetAddress
    let usdcDecimals = Int(Atlas.Solana.Assets.USDC.decimals)

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    // MARK: - Helpers

    private func decodeInstructionData(_ instruction: Charter.Chart.SolanaInstruction) throws -> Data {
        guard let data = Data(base64Encoded: instruction.data) else {
            struct InvalidInstructionData: Error {}
            throw InvalidInstructionData()
        }
        return data
    }

    private func littleEndianBytes(_ value: UInt64) -> [UInt8] {
        withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }

    // MARK: - Instruction Builders

    @Test("Native SOL transfer instruction has correct format")
    func nativeSolTransferInstruction() throws {
        let amount = TokenAmount.amt(1, .sol)
        let instruction = Charter.SolanaOperationBuilder.nativeSolTransfer(
            sender: Account.alice.solanaAddress,
            recipient: Account.bob.solanaAddress,
            lamports: amount.toAmount.underlying
        )

        #expect(instruction.programId == SolanaConstants.SYSTEM_PROGRAM)
        #expect(
            instruction.accounts == [
                .init(pubkey: Account.alice.solanaAddress, isSigner: true, isWritable: true),
                .init(pubkey: Account.bob.solanaAddress, isSigner: false, isWritable: true),
            ]
        )

        let data = try decodeInstructionData(instruction)
        #expect(data.count == 12)
        #expect(Array(data.prefix(4)) == [2, 0, 0, 0])
        #expect(Array(data.dropFirst(4)) == littleEndianBytes(1_000_000_000))
    }

    @Test("SPL USDC TransferChecked instruction has correct format")
    func splUsdcTransferCheckedInstruction() throws {
        let amount = TokenAmount.amt(1, .usdc)
        let senderAta = SolanaConstants.getAssociatedTokenAddress(
            wallet: Account.alice.solanaAddress,
            mint: usdcMint
        )
        let recipientAta = SolanaConstants.getAssociatedTokenAddress(
            wallet: Account.bob.solanaAddress,
            mint: usdcMint
        )
        let instruction = Charter.SolanaOperationBuilder.splTokenTransferChecked(
            sender: Account.alice.solanaAddress,
            recipient: Account.bob.solanaAddress,
            mint: usdcMint,
            amount: amount.toAmount.underlying,
            decimals: amount.token.decimals
        )

        #expect(instruction.programId == SolanaConstants.TOKEN_PROGRAM)
        #expect(
            instruction.accounts == [
                .init(pubkey: senderAta, isSigner: false, isWritable: true),
                .init(pubkey: usdcMint, isSigner: false, isWritable: false),
                .init(pubkey: recipientAta, isSigner: false, isWritable: true),
                .init(pubkey: Account.alice.solanaAddress, isSigner: true, isWritable: false),
            ]
        )

        let data = try decodeInstructionData(instruction)
        #expect(data.count == 10)
        #expect(data[0] == 12)
        #expect(Array(data.dropFirst().dropLast()) == littleEndianBytes(1_000_000))
        #expect(data[9] == UInt8(usdcDecimals))
    }

    @Test("ATA derivation produces canonical addresses")
    func ataDerivation() {
        let aliceAta = SolanaConstants.getAssociatedTokenAddress(
            wallet: Account.alice.solanaAddress,
            mint: usdcMint
        )
        let bobAta = SolanaConstants.getAssociatedTokenAddress(
            wallet: Account.bob.solanaAddress,
            mint: usdcMint
        )

        #expect(aliceAta.base58 == "42JrewdefrETKYFymk8F8FCtJSxLpQQjSyLb4GwueWHG")
        #expect(aliceAta.data.count == 32)
        #expect(aliceAta != Account.alice.solanaAddress)
        #expect(aliceAta != usdcMint)
        #expect(
            SolanaConstants.getAssociatedTokenAddress(
                wallet: Account.alice.solanaAddress,
                mint: usdcMint
            ) == aliceAta
        )
        #expect(bobAta.base58 == "FGETo8T8wMcN2wCjav8VK6eh3dLk63evNDPxzLSJra8B")
    }

    // MARK: - Operation Builder

    @Test("SolanaOperationBuilder.transfer produces a USDC operation action")
    func solanaTransferUSDC() {
        let amount = TokenAmount.amt(5, .usdc)
        let operationAction = Charter.SolanaOperationBuilder.transfer(
            sender: Account.alice.solanaAddress,
            recipient: Account.bob.solanaAddress,
            assetSymbol: amount.token.symbol,
            mint: usdcMint,
            amount: amount.toAmount.underlying,
            decimals: amount.token.decimals,
            price: Number("1e8"),
            feePayer: SolanaFixtures.feePayer
        )

        guard case .solana(let operation) = operationAction.operation else {
            Issue.record("Expected .solana operation")
            return
        }

        #expect(operation.instructions.count == 2)
        #expect(operation.instructions[0].programId == SolanaConstants.ASSOCIATED_TOKEN_PROGRAM)
        #expect(operation.instructions[1].programId == SolanaConstants.TOKEN_PROGRAM)
        #expect(operationAction.action.chainId == Network.solana.chainId)
        #expect(operationAction.action.account == .solana(Account.alice.solanaAddress))
        #expect(operationAction.action.executionType == .immediate)
    }

    @Test("SolanaOperationBuilder.transfer produces a native SOL operation action")
    func solanaTransferNativeSOL() {
        let amount = TokenAmount.amt(1, .sol)
        let operationAction = Charter.SolanaOperationBuilder.transfer(
            sender: Account.alice.solanaAddress,
            recipient: Account.bob.solanaAddress,
            assetSymbol: amount.token.symbol,
            mint: nil,
            amount: amount.toAmount.underlying,
            decimals: amount.token.decimals,
            price: Number("150e8"),
            feePayer: SolanaFixtures.feePayer
        )

        guard case .solana(let operation) = operationAction.operation else {
            Issue.record("Expected .solana operation")
            return
        }

        #expect(operation.instructions.count == 1)
        #expect(operation.instructions[0].programId == SolanaConstants.SYSTEM_PROGRAM)
    }

    @Test("TransferIntent round-trips with Solana addresses")
    func transferIntentSolanaCodable() throws {
        let amount = TokenAmount.amt(1, .usdc)
        let intent = Charter.TransferIntent(
            assetSymbol: amount.token.symbol,
            amount: amount.toAmount.underlying,
            sender: Account.alice.chainAddress(on: .solana),
            recipient: Account.bob.chainAddress(on: .solana)
        )

        #expect(intent.sender.isSolana == true)
        #expect(intent.chainId == Network.solana.chainId)

        let data = try encoder.encode(intent)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["chain_id"] as? String == Network.solana.chainId.description)
        #expect(json["sender"] as? String == Account.alice.solanaAddress.base58)
        #expect(json["recipient"] as? String == Account.bob.solanaAddress.base58)
        #expect(json["asset_symbol"] as? String == "USDC")

        let decoded = try decoder.decode(Charter.TransferIntent.self, from: data)
        #expect(decoded.sender == .solana(Account.alice.solanaAddress))
        #expect(decoded.recipient == .solana(Account.bob.solanaAddress))
        #expect(decoded.assetSymbol == "USDC")
        #expect(decoded.sender.isSolana == true)
    }

    @Test("Solana chart round-trips through Codable")
    func solanaChartCodable() throws {
        let givens: [Given] = [
            .tokenBalance(.alice, .amt(10, .usdc), .solana)
        ]
        let amount = TokenAmount.amt(5, .usdc)
        let intent = Charter.QuarkIntent(
            type: .transfer(
                Charter.TransferIntent(
                    assetSymbol: amount.token.symbol,
                    amount: amount.toAmount.underlying,
                    sender: Account.alice.chainAddress(on: .solana),
                    recipient: Account.bob.chainAddress(on: .solana)
                )
            ),
            blockTimestamp: Number("1700000000")
        )

        guard case .success(let chart) = Charter.chart(
            intent: intent,
            folio: generateFolio(from: givens)
        ) else {
            Issue.record("Expected chart construction to succeed")
            return
        }

        let data = try encoder.encode(chart)
        let decoded = try decoder.decode(Charter.Chart.self, from: data)

        #expect(decoded.operationActions.count == chart.operationActions.count)
        #expect(decoded.steps.count == chart.steps.count)
        #expect(decoded.signingData.solana != nil)
        #expect(decoded.signingData.quark == nil)
        #expect(decoded.eip712Data == nil)
        #expect(decoded.quarkOperationActions.isEmpty)
    }
}
