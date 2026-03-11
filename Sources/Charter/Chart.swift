import Eth
import Prelude
import SwiftNumber

extension Charter {
    public struct Chart: Codable, Sendable, Equatable {
        public let version: String
        public let quarkOperationActions: [QuarkOperationAction]
        public let steps: [Step]
        public let eip712Data: EIP712Data

        public enum CodingKeys: String, CodingKey {
            case version
            case quarkOperationActions = "quark_operation_actions"
            case steps
            case eip712Data = "eip712_data"
        }

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
        }

        public struct Action: Codable, Sendable, Equatable {
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

            public var chainId: Number
            public let quarkAccount: EthAddress
            public let actionType: String
            public let actionContext: Charter.ActionContext
            public let nonceSecret: Hex
            public let totalPlays: Number
            public var executionType: ExecutionType

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
                executionType: ExecutionType
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
                    ExecutionType.self,
                    forKey: .executionType
                )
                self.actionContext = try Charter.ActionContext(from: decoder)
            }

            var network: Network {
                Network.fromChainId(chainId)
            }
        }

        public struct QuarkOperation: Codable, Sendable, Equatable {
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

        public enum Step: Codable, Sendable, Equatable {
            case quarkOperation(QuarkOperationStep)
            case exogenous(ExogenousStep)

            public struct QuarkOperationStep: Codable, Sendable, Equatable {
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
                            try QuarkOperationStep(from: decoder)
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

        public struct EIP712Data: Codable, Sendable, Equatable {
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
    }
}

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
