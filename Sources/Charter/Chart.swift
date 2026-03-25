import Eth
import Foundation
import Prelude
import SwiftNumber

extension Charter {
    public struct Chart: Codable, Sendable, Equatable {
        public let version: String

        // MARK: - Canonical fields

        /// Canonical array of operation-action pairs (EVM + Solana). Always populated.
        /// For old-format charts, derived from `quarkOperationActions` during deserialization.
        public let operationActions: [OperationAction]

        /// Compound signing envelope. Always populated.
        /// For old-format charts, derived from `eip712Data` during deserialization.
        public let signingData: SigningData

        /// Execution DAG. Steps index into `operationActions`.
        public let steps: [Step]

        // MARK: - Legacy fields (derived, for backward compatibility)

        /// EVM-only projection. Derived from `operationActions` for new charts.
        public let quarkOperationActions: [QuarkOperationAction]

        /// EVM signing data. Derived from `signingData.quark` for new charts. `nil` for Solana-only charts.
        public let eip712Data: EIP712Data?

        public enum CodingKeys: String, CodingKey {
            case version
            case operationActions = "operation_actions"
            case signingData = "signing_data"
            case quarkOperationActions = "quark_operation_actions"
            case steps
            case eip712Data = "eip712_data"
        }

        public init(
            version: String,
            operationActions: [OperationAction],
            signingData: SigningData,
            quarkOperationActions: [QuarkOperationAction],
            steps: [Step],
            eip712Data: EIP712Data?
        ) {
            self.version = version
            self.operationActions = operationActions
            self.signingData = signingData
            self.quarkOperationActions = quarkOperationActions
            self.steps = steps
            self.eip712Data = eip712Data
        }

        /// Convenience initializer for backward compatibility: builds canonical fields from EVM-only inputs.
        public init(
            version: String,
            quarkOperationActions: [QuarkOperationAction],
            steps: [Step],
            eip712Data: EIP712Data
        ) {
            self.version = version
            self.quarkOperationActions = quarkOperationActions
            self.steps = steps
            self.eip712Data = eip712Data
            self.operationActions = quarkOperationActions.map { qoa in
                OperationAction.fromQuarkOperationAction(qoa)
            }
            self.signingData = SigningData(
                quark: EIP712SigningData(
                    digest: eip712Data.digest,
                    domainSeparator: eip712Data.domainSeparator,
                    hashStruct: eip712Data.hashStruct
                ),
                solana: nil
            )
        }

        // MARK: - Codable

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(version, forKey: .version)
            try container.encode(operationActions, forKey: .operationActions)
            try container.encode(signingData, forKey: .signingData)
            try container.encode(steps, forKey: .steps)
            try container.encode(quarkOperationActions, forKey: .quarkOperationActions)
            try container.encodeIfPresent(eip712Data, forKey: .eip712Data)
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.version = try container.decode(String.self, forKey: .version)
            self.quarkOperationActions = try container.decode(
                [QuarkOperationAction].self,
                forKey: .quarkOperationActions
            )
            self.steps = try container.decode([Step].self, forKey: .steps)
            self.eip712Data = try container.decodeIfPresent(
                EIP712Data.self,
                forKey: .eip712Data
            )

            // Canonical fields: decode if present, derive from legacy fields if absent
            if let decoded = try container.decodeIfPresent(
                [OperationAction].self,
                forKey: .operationActions
            ) {
                self.operationActions = decoded
            } else {
                self.operationActions = self.quarkOperationActions.map {
                    OperationAction.fromQuarkOperationAction($0)
                }
            }

            if let decoded = try container.decodeIfPresent(
                SigningData.self,
                forKey: .signingData
            ) {
                self.signingData = decoded
            } else if let eip712 = self.eip712Data {
                self.signingData = SigningData(
                    quark: EIP712SigningData(
                        digest: eip712.digest,
                        domainSeparator: eip712.domainSeparator,
                        hashStruct: eip712.hashStruct
                    ),
                    solana: nil
                )
            } else {
                self.signingData = SigningData(quark: nil, solana: nil)
            }
        }

        // MARK: - Unified Data Model Types

        /// A Solana account meta entry specifying a pubkey and its role in the instruction.
        public struct SolanaAccountMeta: Codable, Sendable, Equatable {
            public let pubkey: SolanaAddress
            public let isSigner: Bool
            public let isWritable: Bool

            public enum CodingKeys: String, CodingKey {
                case pubkey
                case isSigner = "is_signer"
                case isWritable = "is_writable"
            }

            public init(
                pubkey: SolanaAddress,
                isSigner: Bool,
                isWritable: Bool
            ) {
                self.pubkey = pubkey
                self.isSigner = isSigner
                self.isWritable = isWritable
            }
        }

        /// A single Solana instruction — program ID, accounts, and base64-encoded data.
        public struct SolanaInstruction: Codable, Sendable, Equatable {
            public let programId: SolanaAddress
            public let accounts: [SolanaAccountMeta]
            public let data: String

            public enum CodingKeys: String, CodingKey {
                case programId = "program_id"
                case accounts
                case data
            }

            public init(
                programId: SolanaAddress,
                accounts: [SolanaAccountMeta],
                data: String
            ) {
                self.programId = programId
                self.accounts = accounts
                self.data = data
            }
        }

        /// Solana-specific operation data — a list of instructions that form a Solana transaction.
        public struct SolanaOperation: Codable, Sendable, Equatable {
            public let instructions: [SolanaInstruction]

            public init(instructions: [SolanaInstruction]) {
                self.instructions = instructions
            }
        }

        /// Quark wallet operation data — script execution details plus replay protection fields.
        /// Combines the legacy `LegacyQuarkOperation` fields with `nonceSecret`/`totalPlays` from `EVMAction`.
        public struct QuarkOperation: Codable, Sendable, Equatable {
            public let scriptAddress: EthAddress
            public let scriptCalldata: Hex
            public let scriptSources: [Hex]
            public let nonce: Hex
            public let expiry: Number
            public let isReplayable: Bool
            public let nonceSecret: Hex
            public let totalPlays: Number

            public enum CodingKeys: String, CodingKey {
                case scriptAddress = "script_address"
                case scriptCalldata = "script_calldata"
                case scriptSources = "script_sources"
                case nonce
                case expiry
                case isReplayable = "is_replayable"
                case nonceSecret = "nonce_secret"
                case totalPlays = "total_plays"
            }

            public init(
                scriptAddress: EthAddress,
                scriptCalldata: Hex,
                scriptSources: [Hex],
                nonce: Hex,
                expiry: Number,
                isReplayable: Bool,
                nonceSecret: Hex,
                totalPlays: Number
            ) {
                self.scriptAddress = scriptAddress
                self.scriptCalldata = scriptCalldata
                self.scriptSources = scriptSources
                self.nonce = nonce
                self.expiry = expiry
                self.isReplayable = isReplayable
                self.nonceSecret = nonceSecret
                self.totalPlays = totalPlays
            }
        }

        /// Discriminated union of chain-specific operation types.
        public enum Operation: Codable, Sendable, Equatable {
            case quark(QuarkOperation)
            case solana(SolanaOperation)

            enum CodingKeys: String, CodingKey {
                case type
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                    case .quark(let op):
                        try container.encode("quark", forKey: .type)
                        try op.encode(to: encoder)
                    case .solana(let op):
                        try container.encode("solana", forKey: .type)
                        try op.encode(to: encoder)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(String.self, forKey: .type)
                switch type {
                    case "quark":
                        self = .quark(try QuarkOperation(from: decoder))
                    case "solana":
                        self = .solana(try SolanaOperation(from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(
                            forKey: .type,
                            in: container,
                            debugDescription: "Unknown operation type: \(type)"
                        )
                }
            }
        }

        /// Chain-agnostic action — describes _what_ the user wants to do.
        /// Uses `ChainAddress` for `account` (replaces EVM-only `quarkAccount`).
        /// `nonceSecret` and `totalPlays` are moved to `QuarkOperation`.
        public struct Action: Codable, Sendable, Equatable {
            // TODO: ExecutionType is no longer used for scheduling (replaced by Steps depends_on).
            // Still needed for :recurrent semantics (payment validation, activity keys).
            // Remove once recurrent operations are fully migrated to Steps.
            public enum ExecutionType: Codable, Comparable, Sendable, Equatable {
                case immediate
                case delayed
                case recurrent
                case contingent
                case unknown(String)

                public init(rawValue: String) {
                    switch rawValue {
                        case ExecutionType.IMMEDIATE:
                            self = .immediate
                        case ExecutionType.DELAYED:
                            self = .delayed
                        case ExecutionType.RECURRENT:
                            self = .recurrent
                        case ExecutionType.CONTINGENT:
                            self = .contingent
                        default:
                            self = .unknown(rawValue)
                    }
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = ExecutionType(rawValue: rawValue)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()
                    try container.encode(rawValue)
                }

                public var rawValue: String {
                    switch self {
                        case .immediate:
                            return ExecutionType.IMMEDIATE
                        case .delayed:
                            return ExecutionType.DELAYED
                        case .recurrent:
                            return ExecutionType.RECURRENT
                        case .contingent:
                            return ExecutionType.CONTINGENT
                        case .unknown(let value):
                            return value
                    }
                }

                public var isImmediate: Bool {
                    self == .immediate
                }

                public static let IMMEDIATE = "IMMEDIATE"
                public static let DELAYED = "DELAYED"
                public static let RECURRENT = "RECURRENT"
                public static let CONTINGENT = "CONTINGENT"
            }

            public let chainId: Number
            public let account: ChainAddress
            public let actionType: String
            public let actionContext: Charter.ActionContext
            public let executionType: ExecutionType

            public enum CodingKeys: String, CodingKey {
                case chainId = "chain_id"
                case account
                case actionType = "action_type"
                case actionContext = "action_context"
                case executionType = "execution_type"
            }

            public init(
                chainId: Number,
                account: ChainAddress,
                actionType: String,
                actionContext: Charter.ActionContext,
                executionType: ExecutionType
            ) {
                self.chainId = chainId
                self.account = account
                self.actionType = actionType
                self.actionContext = actionContext
                self.executionType = executionType
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(chainId, forKey: .chainId)
                // Encode account as a plain string (hex or base58)
                try container.encode(account.displayString, forKey: .account)
                try container.encode(actionType, forKey: .actionType)
                try container.encode(executionType, forKey: .executionType)
                try actionContext.encode(
                    to: container.superEncoder(forKey: .actionContext)
                )
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.chainId = try container.decode(Number.self, forKey: .chainId)
                let accountString = try container.decode(String.self, forKey: .account)
                let network = Network.fromChainId(chainId)

                // Resolve account type from chain_id context
                if accountString.hasPrefix("0x") {
                    guard let ethAddr = EthAddress(fromHexString: accountString) else {
                        throw DecodingError.dataCorruptedError(
                            forKey: .account,
                            in: container,
                            debugDescription: "Invalid EVM address: \(accountString)"
                        )
                    }
                    if ChainAddress.supports(network) {
                        self.account = ChainAddress(ethAddr, chain: network)
                    } else {
                        throw DecodingError.dataCorruptedError(
                            forKey: .account,
                            in: container,
                            debugDescription: "Unsupported EVM network: \(network)"
                        )
                    }
                } else {
                    guard let solAddr = SolanaAddress(fromBase58: accountString) else {
                        throw DecodingError.dataCorruptedError(
                            forKey: .account,
                            in: container,
                            debugDescription: "Invalid Solana address: \(accountString)"
                        )
                    }
                    self.account = .solana(solAddr)
                }

                self.actionType = try container.decode(String.self, forKey: .actionType)
                self.executionType = try container.decode(
                    ExecutionType.self,
                    forKey: .executionType
                )
                self.actionContext = try Charter.ActionContext(from: decoder)
            }

            var network: Network {
                Network.fromChainId(chainId)
            }
        }

        /// A unified operation-action pair for both EVM and Solana.
        public struct OperationAction: Codable, Sendable, Equatable {
            public let operation: Operation
            public let action: Action

            public enum CodingKeys: String, CodingKey {
                case operation
                case action
            }

            public init(operation: Operation, action: Action) {
                self.operation = operation
                self.action = action
            }

            /// Convert a legacy `QuarkOperationAction` to the unified `OperationAction`.
            public static func fromQuarkOperationAction(
                _ qoa: QuarkOperationAction
            ) -> OperationAction {
                let quarkOp = QuarkOperation(
                    scriptAddress: qoa.operation.scriptAddress,
                    scriptCalldata: qoa.operation.scriptCalldata,
                    scriptSources: qoa.operation.scriptSources,
                    nonce: qoa.operation.nonce,
                    expiry: qoa.operation.expiry,
                    isReplayable: qoa.operation.isReplayable,
                    nonceSecret: qoa.action.nonceSecret,
                    totalPlays: qoa.action.totalPlays
                )
                let network = qoa.action.network
                let account: ChainAddress
                if ChainAddress.supports(network) {
                    account = ChainAddress(qoa.action.quarkAccount, chain: network)
                } else {
                    // Fallback for unknown EVM networks
                    account = .ethereum(qoa.action.quarkAccount)
                }
                let action = Action(
                    chainId: qoa.action.chainId,
                    account: account,
                    actionType: qoa.action.actionType,
                    actionContext: qoa.action.actionContext,
                    executionType: qoa.action.executionType
                )
                return OperationAction(
                    operation: .quark(quarkOp),
                    action: action
                )
            }

        }

        /// Compound signing envelope keyed by signing domain.
        /// Each domain produces an independent digest that may be signed by a different account.
        /// Future domains (e.g. Hyperliquid HyperCore, Polymarket CLOB) will add optional
        /// `EIP712SigningData` fields here — each uses its own EIP-712 domain/types.
        public struct SigningData: Codable, Sendable, Equatable {
            /// Quark wallet multi-op EIP-712 digest (EVM).
            public let quark: EIP712SigningData?
            /// Solana transaction message.
            public let solana: SolanaSigningData?

            public init(quark: EIP712SigningData?, solana: SolanaSigningData?) {
                self.quark = quark
                self.solana = solana
            }
        }

        /// EIP-712 signing data — digest, domain separator, and hash struct.
        /// Used by any signing domain that requires EIP-712 signatures (Quark, Polymarket, Hypercore, etc.).
        public struct EIP712SigningData: Codable, Sendable, Equatable {
            public let digest: Hex
            public let domainSeparator: Hex
            public let hashStruct: Hex

            public enum CodingKeys: String, CodingKey {
                case digest
                case domainSeparator = "domain_separator"
                case hashStruct = "hash_struct"
            }

            public init(
                digest: Hex,
                domainSeparator: Hex,
                hashStruct: Hex
            ) {
                self.digest = digest
                self.domainSeparator = domainSeparator
                self.hashStruct = hashStruct
            }
        }

        /// Solana signing data — serialized transaction message bytes.
        public struct SolanaSigningData: Codable, Sendable, Equatable {
            public let serializedMessage: String

            public enum CodingKeys: String, CodingKey {
                case serializedMessage = "serialized_message"
            }

            public init(serializedMessage: String) {
                self.serializedMessage = serializedMessage
            }
        }

        // MARK: - Legacy Types (kept for backward compatibility)

        public struct EVMAction: Codable, Sendable, Equatable {
            public var chainId: Number
            public let quarkAccount: EthAddress
            public let actionType: String
            public let actionContext: Charter.ActionContext
            public let nonceSecret: Hex
            public let totalPlays: Number
            public var executionType: Action.ExecutionType

            public enum CodingKeys: String, CodingKey {
                case chainId = "chain_id"
                case quarkAccount = "quark_account"
                case actionType = "action_type"
                case actionContext = "action_context"
                case nonceSecret = "nonce_secret"
                case totalPlays = "total_plays"
                case executionType = "execution_type"
            }

            public init(
                chainId: Number,
                quarkAccount: EthAddress,
                actionType: String,
                actionContext: ActionContext,
                nonceSecret: Hex,
                totalPlays: Number,
                executionType: Action.ExecutionType
            ) {
                self.chainId = chainId
                self.quarkAccount = quarkAccount
                self.actionType = actionType
                self.actionContext = actionContext
                self.nonceSecret = nonceSecret
                self.totalPlays = totalPlays
                self.executionType = executionType
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(chainId, forKey: .chainId)
                try container.encode(quarkAccount, forKey: .quarkAccount)
                try container.encode(actionType, forKey: .actionType)
                try container.encode(nonceSecret, forKey: .nonceSecret)
                try container.encode(totalPlays, forKey: .totalPlays)
                try container.encode(executionType, forKey: .executionType)

                // Encode actionContext body without redundant action_type
                try actionContext.encode(
                    to: container.superEncoder(forKey: .actionContext)
                )
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.chainId = try container.decode(Number.self, forKey: .chainId)
                self.quarkAccount = try container.decode(EthAddress.self, forKey: .quarkAccount)
                self.actionType = try container.decode(String.self, forKey: .actionType)
                self.nonceSecret = try container.decode(Hex.self, forKey: .nonceSecret)
                self.totalPlays = try container.decode(Number.self, forKey: .totalPlays)
                self.executionType = try container.decode(
                    Action.ExecutionType.self,
                    forKey: .executionType
                )
                self.actionContext = try Charter.ActionContext(from: decoder)
            }

            var network: Network {
                Network.fromChainId(chainId)
            }
        }

        public struct LegacyQuarkOperation: Codable, Sendable, Equatable {
            public let nonce: Hex
            public let isReplayable: Bool
            public let scriptAddress: EthAddress
            public let scriptSources: [Hex]
            public let scriptCalldata: Hex
            public let expiry: Number

            public enum CodingKeys: String, CodingKey {
                case nonce
                case isReplayable = "is_replayable"
                case scriptAddress = "script_address"
                case scriptSources = "script_sources"
                case scriptCalldata = "script_calldata"
                case expiry
            }

            public init(
                nonce: Hex,
                isReplayable: Bool,
                scriptAddress: EthAddress,
                scriptSources: [Hex],
                scriptCalldata: Hex,
                expiry: Number
            ) {
                self.nonce = nonce
                self.isReplayable = isReplayable
                self.scriptAddress = scriptAddress
                self.scriptSources = scriptSources
                self.scriptCalldata = scriptCalldata
                self.expiry = expiry
            }
        }

        // MARK: - Steps (execution DAG)

        public enum Step: Codable, Sendable, Equatable {
            case quarkOperation(OperationStep)
            case solanaOperation(OperationStep)
            case exogenous(ExogenousStep)

            public struct OperationStep: Codable, Sendable, Equatable {
                public let chainId: Number
                public let operationIndex: Int
                public let expectedActions: [ExpectedAction]
                public let dependsOn: [Int]

                public enum CodingKeys: String, CodingKey {
                    case chainId = "chain_id"
                    case operationIndex = "operation_index"
                    case expectedActions = "expected_actions"
                    case dependsOn = "depends_on"
                }

                public init(
                    chainId: Number,
                    operationIndex: Int,
                    expectedActions: [ExpectedAction],
                    dependsOn: [Int]
                ) {
                    self.chainId = chainId
                    self.operationIndex = operationIndex
                    self.expectedActions = expectedActions
                    self.dependsOn = dependsOn
                }
            }

            public struct ExogenousStep: Codable, Sendable, Equatable {
                public let chainId: Number
                public let executionType: ExogenousExecutionType
                public let expectedActions: [ExpectedAction]
                public let dependsOn: [Int]

                public enum CodingKeys: String, CodingKey {
                    case chainId = "chain_id"
                    case executionType = "execution_type"
                    case expectedActions = "expected_actions"
                    case dependsOn = "depends_on"
                }

                public init(
                    chainId: Number,
                    executionType: ExogenousExecutionType,
                    expectedActions: [ExpectedAction],
                    dependsOn: [Int]
                ) {
                    self.chainId = chainId
                    self.executionType = executionType
                    self.expectedActions = expectedActions
                    self.dependsOn = dependsOn
                }
            }

            public enum ExogenousExecutionType: String, Codable, Sendable, Equatable {
                case bridgeReceive = "bridge_receive"
            }

            enum CodingKeys: String, CodingKey {
                case type
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                    case .quarkOperation(let step):
                        try container.encode("quark_operation", forKey: .type)
                        try step.encode(to: encoder)
                    case .solanaOperation(let step):
                        try container.encode("solana_operation", forKey: .type)
                        try step.encode(to: encoder)
                    case .exogenous(let step):
                        try container.encode("exogenous", forKey: .type)
                        try step.encode(to: encoder)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(String.self, forKey: .type)
                switch type {
                    case "quark_operation":
                        self = .quarkOperation(
                            try OperationStep(from: decoder)
                        )
                    case "solana_operation":
                        self = .solanaOperation(
                            try OperationStep(from: decoder)
                        )
                    case "exogenous":
                        self = .exogenous(
                            try ExogenousStep(from: decoder)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(
                            forKey: .type,
                            in: container,
                            debugDescription: "Unknown step type: \(type)"
                        )
                }
            }
        }

        public struct ExpectedAction: Codable, Sendable, Equatable {
            public let actionType: String
            public let actionContext: Charter.ActionContext

            public enum CodingKeys: String, CodingKey {
                case actionType = "action_type"
                case actionContext = "action_context"
            }

            public init(
                actionType: String,
                actionContext: Charter.ActionContext
            ) {
                self.actionType = actionType
                self.actionContext = actionContext
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(actionType, forKey: .actionType)
                try actionContext.encodeBody(
                    to: container.superEncoder(forKey: .actionContext)
                )
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.actionType = try container.decode(String.self, forKey: .actionType)
                self.actionContext = try Charter.ActionContext.decodeBody(
                    from: container.superDecoder(forKey: .actionContext),
                    actionType: actionType
                )
            }
        }

        /// Legacy EIP-712 signing data. Identical to `EIP712SigningData`.
        public typealias EIP712Data = EIP712SigningData
    }
}

// MARK: - EIP712 Data Computation (legacy)

extension Charter.QuarkOperationAction {
    var eip712Data: Charter.Chart.EIP712Data? {
        guard let chainId = action.network.chainId.uInt else {
            return nil
        }

        let domain = ABI.EIP712.Domain(
            name: "Quark Wallet",
            version: "1",
            chainId: chainId,
            verifyingContract: action.quarkAccount
        )

        let types: [String: ABI.EIP712.TypeDefinition] = [
            "QuarkOperation": .init(fields: [
                .init(name: "nonce", type: .bytes32),
                .init(name: "isReplayable", type: .bool),
                .init(name: "scriptAddress", type: .address),
                .init(name: "scriptSources", type: .array(.bytes)),
                .init(name: "scriptCalldata", type: .bytes),
                .init(name: "expiry", type: .uint256),
            ])
        ]

        let message: [String: ABI.Value] = [
            "nonce": .bytes32(operation.nonce),
            "isReplayable": .bool(operation.isReplayable),
            "scriptAddress": .address(operation.scriptAddress),
            "scriptSources": .array(.bytes, operation.scriptSources.map { .bytes($0) }),
            "scriptCalldata": .bytes(operation.scriptCalldata),
            "expiry": .uint256(operation.expiry),
        ]

        let typedData = ABI.EIP712.TypedData(
            domain: domain,
            types: types,
            primaryType: "QuarkOperation",
            message: message
        )

        if let components = try? typedData.components() {
            return .init(
                digest: components.digest,
                domainSeparator: components.domainSeparator,
                hashStruct: components.hashStruct
            )
        } else {
            return nil
        }
    }
}

extension Array where Element == Charter.QuarkOperationAction {
    var eip712Data: Charter.Chart.EIP712Data? {
        if self.count == 1 {
            // Single quark operation
            return self[0].eip712Data
        } else {
            // Multi quark operation
            let domain = ABI.EIP712.Domain(
                name: "Quark Wallet",
                version: "1"
            )

            let types: [String: ABI.EIP712.TypeDefinition] = [
                "MultiQuarkOperation": .init(fields: [
                    .init(name: "opDigests", type: .array(.bytes32))
                ])
            ]

            let opDigests = self.compactMap(\.eip712Data)

            // Make sure all digests are not nil, otherwise return nil ourselves
            guard opDigests.count == self.count else {
                return nil
            }

            let message: [String: ABI.Value] = [
                "opDigests": .array(.bytes32, opDigests.map { .bytes32($0.digest) })
            ]

            let typedData = ABI.EIP712.TypedData(
                domain: domain,
                types: types,
                primaryType: "MultiQuarkOperation",
                message: message
            )

            if let components = try? typedData.components() {
                return .init(
                    digest: components.digest,
                    domainSeparator: components.domainSeparator,
                    hashStruct: components.hashStruct
                )
            } else {
                return nil
            }
        }
    }
}
