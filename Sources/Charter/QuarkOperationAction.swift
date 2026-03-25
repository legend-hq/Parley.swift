extension Charter {
    public struct QuarkOperationAction: Equatable, Codable, Sendable {
        public let operation: Charter.Chart.LegacyQuarkOperation
        public let action: Charter.Chart.EVMAction

        public enum CodingKeys: String, CodingKey {
            case operation
            case action
        }

        public init(operation: Charter.Chart.LegacyQuarkOperation, action: Charter.Chart.EVMAction) {
            self.operation = operation
            self.action = action
        }
    }
}
