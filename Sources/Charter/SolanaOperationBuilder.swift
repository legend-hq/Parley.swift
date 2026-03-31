import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber

extension Charter {
    public enum SolanaOperationBuilder {

        // MARK: - Instruction Builders

        /// Build a native SOL transfer instruction.
        ///
        /// System Program `Transfer` instruction layout:
        /// - Discriminator: [2, 0, 0, 0] (4 bytes, little-endian u32)
        /// - Amount: 8 bytes little-endian u64 (lamports)
        ///
        /// Accounts:
        /// - [0] sender (signer, writable)
        /// - [1] recipient (writable)
        public static func nativeSolTransfer(
            sender: SolanaAddress,
            recipient: SolanaAddress,
            lamports: Number
        ) -> Chart.SolanaInstruction {
            // Encode instruction data: discriminator (2u32 LE) + amount (u64 LE)
            var data = Data(count: 12)
            data[0] = 2  // Transfer instruction index
            data[1] = 0
            data[2] = 0
            data[3] = 0

            let amount = lamports.asUInt64
            for i in 0..<8 {
                data[4 + i] = UInt8((amount >> (i * 8)) & 0xFF)
            }

            return Chart.SolanaInstruction(
                programId: SolanaConstants.SYSTEM_PROGRAM,
                accounts: [
                    Chart.SolanaAccountMeta(
                        pubkey: sender,
                        isSigner: true,
                        isWritable: true
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: recipient,
                        isSigner: false,
                        isWritable: true
                    ),
                ],
                data: data.base64EncodedString()
            )
        }

        /// Build a `CreateAssociatedTokenAccountIdempotent` instruction.
        ///
        /// Creates the recipient's Associated Token Account if it doesn't already exist.
        /// Idempotent — succeeds silently if the ATA already exists (no-op on chain).
        ///
        /// Associated Token Program instruction layout:
        /// - Discriminator: [1] (1 byte, u8 — variant index 1 = CreateIdempotent)
        ///
        /// Accounts:
        /// - [0] payer (signer, writable) — funds the account creation (rent deposit)
        /// - [1] associatedTokenAccount (writable) — the ATA to create
        /// - [2] wallet — the owner of the new ATA
        /// - [3] mint — the token mint
        /// - [4] System Program
        /// - [5] Token Program
        public static func createAssociatedTokenAccountIdempotent(
            payer: SolanaAddress,
            wallet: SolanaAddress,
            mint: SolanaAddress
        ) -> Chart.SolanaInstruction {
            let ata = SolanaConstants.getAssociatedTokenAddress(
                wallet: wallet,
                mint: mint
            )

            return Chart.SolanaInstruction(
                programId: SolanaConstants.ASSOCIATED_TOKEN_PROGRAM,
                accounts: [
                    Chart.SolanaAccountMeta(
                        pubkey: payer,
                        isSigner: true,
                        isWritable: true
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: ata,
                        isSigner: false,
                        isWritable: true
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: wallet,
                        isSigner: false,
                        isWritable: false
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: mint,
                        isSigner: false,
                        isWritable: false
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: SolanaConstants.SYSTEM_PROGRAM,
                        isSigner: false,
                        isWritable: false
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: SolanaConstants.TOKEN_PROGRAM,
                        isSigner: false,
                        isWritable: false
                    ),
                ],
                data: Data([1]).base64EncodedString()  // CreateIdempotent = variant 1
            )
        }

        /// Build an SPL Token `TransferChecked` instruction.
        ///
        /// Token Program `TransferChecked` instruction layout:
        /// - Discriminator: [12] (1 byte)
        /// - Amount: 8 bytes little-endian u64
        /// - Decimals: 1 byte
        ///
        /// Accounts:
        /// - [0] source ATA (writable)
        /// - [1] mint
        /// - [2] destination ATA (writable)
        /// - [3] owner (signer)
        public static func splTokenTransferChecked(
            sender: SolanaAddress,
            recipient: SolanaAddress,
            mint: SolanaAddress,
            amount: Number,
            decimals: Int
        ) -> Chart.SolanaInstruction {
            let sourceATA = SolanaConstants.getAssociatedTokenAddress(
                wallet: sender,
                mint: mint
            )
            let destATA = SolanaConstants.getAssociatedTokenAddress(
                wallet: recipient,
                mint: mint
            )

            // Encode instruction data: discriminator (12) + amount (u64 LE) + decimals (u8)
            var data = Data(count: 10)
            data[0] = 12  // TransferChecked instruction index

            let rawAmount = amount.asUInt64
            for i in 0..<8 {
                data[1 + i] = UInt8((rawAmount >> (i * 8)) & 0xFF)
            }
            data[9] = UInt8(decimals)

            return Chart.SolanaInstruction(
                programId: SolanaConstants.TOKEN_PROGRAM,
                accounts: [
                    Chart.SolanaAccountMeta(
                        pubkey: sourceATA,
                        isSigner: false,
                        isWritable: true
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: mint,
                        isSigner: false,
                        isWritable: false
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: destATA,
                        isSigner: false,
                        isWritable: true
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: sender,
                        isSigner: true,
                        isWritable: false
                    ),
                ],
                data: data.base64EncodedString()
            )
        }

        /// Build an `AdvanceNonceAccount` instruction.
        ///
        /// System Program `AdvanceNonceAccount` instruction layout:
        /// - Discriminator: [4, 0, 0, 0] (4 bytes, little-endian u32 — SystemInstruction index 4)
        /// - No additional data
        ///
        /// Accounts:
        /// - [0] nonce account (writable)
        /// - [1] SysvarRecentBlockhashes (readonly)
        /// - [2] nonce authority (signer, readonly)
        public static func advanceNonceAccount(
            nonceAccount: SolanaAddress,
            nonceAuthority: SolanaAddress
        ) -> Chart.SolanaInstruction {
            // AdvanceNonceAccount discriminator: index 4 as u32 LE
            let data = Data([4, 0, 0, 0])

            return Chart.SolanaInstruction(
                programId: SolanaConstants.SYSTEM_PROGRAM,
                accounts: [
                    Chart.SolanaAccountMeta(
                        pubkey: nonceAccount,
                        isSigner: false,
                        isWritable: true
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: SolanaConstants.SYSVAR_RECENT_BLOCKHASHES,
                        isSigner: false,
                        isWritable: false
                    ),
                    Chart.SolanaAccountMeta(
                        pubkey: nonceAuthority,
                        isSigner: true,
                        isWritable: false
                    ),
                ],
                data: data.base64EncodedString()
            )
        }

        // MARK: - Message Serialization

        /// Serializes a list of Solana instructions into a legacy transaction message.
        ///
        /// The message format is:
        /// - Header (3 bytes): num_required_signatures, num_readonly_signed, num_readonly_unsigned
        /// - Account keys (compact-u16 length + N × 32-byte pubkeys)
        /// - Recent blockhash (32 bytes)
        /// - Instructions (compact-u16 length + compiled instructions)
        ///
        /// Accounts are ordered: [writable signers, readonly signers, writable non-signers, readonly non-signers]
        /// The fee payer must be account index 0 (first writable signer).
        public static func serializeMessage(
            instructions: [Chart.SolanaInstruction],
            feePayer: SolanaAddress,
            recentBlockhash: Data
        ) -> Data {
            // 1. Collect all unique accounts with their permissions
            var accountMap: [SolanaAddress: (isSigner: Bool, isWritable: Bool)] = [:]

            // Fee payer is always signer + writable
            accountMap[feePayer] = (isSigner: true, isWritable: true)

            for instruction in instructions {
                // Program ID is a readonly non-signer
                let progId = instruction.programId
                let existing = accountMap[progId] ?? (isSigner: false, isWritable: false)
                accountMap[progId] = existing  // Don't promote program IDs

                for account in instruction.accounts {
                    let existing = accountMap[account.pubkey] ?? (isSigner: false, isWritable: false)
                    accountMap[account.pubkey] = (
                        isSigner: existing.isSigner || account.isSigner,
                        isWritable: existing.isWritable || account.isWritable
                    )
                }
            }

            // 2. Sort accounts into 4 groups per Solana spec
            // Order: writable signers, readonly signers, writable non-signers, readonly non-signers
            // Fee payer is always first
            var writableSigners: [SolanaAddress] = [feePayer]
            var readonlySigners: [SolanaAddress] = []
            var writableNonSigners: [SolanaAddress] = []
            var readonlyNonSigners: [SolanaAddress] = []

            for (address, perms) in accountMap {
                if address == feePayer { continue }  // Already placed first
                if perms.isSigner && perms.isWritable {
                    writableSigners.append(address)
                } else if perms.isSigner && !perms.isWritable {
                    readonlySigners.append(address)
                } else if !perms.isSigner && perms.isWritable {
                    writableNonSigners.append(address)
                } else {
                    readonlyNonSigners.append(address)
                }
            }

            let orderedAccounts = writableSigners + readonlySigners + writableNonSigners + readonlyNonSigners

            // Build account index lookup
            var accountIndex: [SolanaAddress: UInt8] = [:]
            for (i, addr) in orderedAccounts.enumerated() {
                accountIndex[addr] = UInt8(i)
            }

            // 3. Build header
            let numRequiredSignatures = UInt8(writableSigners.count + readonlySigners.count)
            let numReadonlySignedAccounts = UInt8(readonlySigners.count)
            let numReadonlyUnsignedAccounts = UInt8(readonlyNonSigners.count)

            // 4. Serialize the message
            var message = Data()

            // Header (3 bytes)
            message.append(numRequiredSignatures)
            message.append(numReadonlySignedAccounts)
            message.append(numReadonlyUnsignedAccounts)

            // Account keys
            message.append(contentsOf: encodeCompactU16(UInt16(orderedAccounts.count)))
            for account in orderedAccounts {
                message.append(account.data)
            }

            // Recent blockhash (32 bytes) — for durable nonce, this is the nonce value
            message.append(recentBlockhash)

            // Instructions
            message.append(contentsOf: encodeCompactU16(UInt16(instructions.count)))
            for instruction in instructions {
                // Program ID index
                message.append(accountIndex[instruction.programId]!)

                // Account indexes
                let accountIndexes = instruction.accounts.map { accountIndex[$0.pubkey]! }
                message.append(contentsOf: encodeCompactU16(UInt16(accountIndexes.count)))
                message.append(contentsOf: accountIndexes)

                // Instruction data
                guard let instrData = Data(base64Encoded: instruction.data) else {
                    continue
                }
                message.append(contentsOf: encodeCompactU16(UInt16(instrData.count)))
                message.append(instrData)
            }

            return message
        }

        /// Encodes a u16 value using Solana's compact-u16 format.
        /// Uses 1 byte for values 0-127, 2 bytes for 128-16383, 3 bytes for larger values.
        static func encodeCompactU16(_ value: UInt16) -> [UInt8] {
            var val = value
            var bytes: [UInt8] = []
            while true {
                var elem = UInt8(val & 0x7F)
                val >>= 7
                if val != 0 {
                    elem |= 0x80
                }
                bytes.append(elem)
                if val == 0 {
                    break
                }
            }
            return bytes
        }

        // MARK: - High-Level Builder

        /// Nonce data for constructing a durable nonce transaction.
        /// When provided, the `AdvanceNonceAccount` instruction is prepended and the nonce value
        /// is used as the `recent_blockhash` in the serialized message.
        public struct NonceData {
            public let nonceValue: Data          // 32-byte nonce hash
            public let nonceAccount: SolanaAddress
            public let nonceAuthority: SolanaAddress  // typically = sender
            public let feePayer: SolanaAddress         // Legend's payer

            public init(
                nonceValue: Data,
                nonceAccount: SolanaAddress,
                nonceAuthority: SolanaAddress,
                feePayer: SolanaAddress
            ) {
                self.nonceValue = nonceValue
                self.nonceAccount = nonceAccount
                self.nonceAuthority = nonceAuthority
                self.feePayer = feePayer
            }
        }

        /// Build a SolanaOperation + Action pair for a Solana transfer.
        ///
        /// Produces the operation-level instructions only. Nonce handling and message
        /// serialization happen later in `solanaSigningData()`, mirroring how EIP-712 signing
        /// data is computed from QuarkOperationActions after operation construction.
        ///
        /// - Parameter feePayer: Legend's fee payer address. Used as the ATA creation payer
        ///   (pays rent for new token accounts) so the user doesn't need SOL.
        ///   For native SOL transfers, no ATA is created so feePayer is unused.
        public static func transfer(
            sender: SolanaAddress,
            recipient: SolanaAddress,
            assetSymbol: String,
            mint: SolanaAddress?,
            amount: Number,
            decimals: Int,
            price: Number,
            feePayer: SolanaAddress
        ) -> Chart.OperationAction {
            var instructions: [Chart.SolanaInstruction] = []
            let effectiveMint: SolanaAddress

            if let mint = mint {
                // SPL token transfer: prepend idempotent ATA creation for the recipient.
                // Legend's fee payer pays the rent so the user doesn't need SOL.
                instructions.append(createAssociatedTokenAccountIdempotent(
                    payer: feePayer,
                    wallet: recipient,
                    mint: mint
                ))
                instructions.append(splTokenTransferChecked(
                    sender: sender,
                    recipient: recipient,
                    mint: mint,
                    amount: amount,
                    decimals: decimals
                ))
                effectiveMint = mint
            } else {
                // Native SOL transfer — no ATA needed.
                instructions.append(nativeSolTransfer(
                    sender: sender,
                    recipient: recipient,
                    lamports: amount
                ))
                effectiveMint = SolanaConstants.SYSTEM_PROGRAM
            }

            let operation = Chart.SolanaOperation(instructions: instructions)

            let actionContext = ActionContext.transfer(
                ActionContext.TransferActionContext(
                    amount: amount,
                    assetSymbol: assetSymbol,
                    price: price,
                    recipient: .solana(recipient),
                    token: .solana(effectiveMint)
                )
            )

            let action = Chart.Action(
                account: .solana(sender),
                actionType: ActionContext.TransferActionContext.actionType,
                actionContext: actionContext,
                executionType: .immediate
            )

            return Chart.OperationAction(
                operation: .solana(operation),
                action: action
            )
        }
    }
}

// MARK: - Number convenience

extension Number {
    /// Converts a Number to UInt64, clamping at UInt64.max.
    var asUInt64: UInt64 {
        guard let uint = self.uInt else {
            return UInt64.max
        }
        return UInt64(clamping: uint)
    }
}
