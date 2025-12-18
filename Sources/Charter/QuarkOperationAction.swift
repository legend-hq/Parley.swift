extension Charter {
    public struct QuarkOperationAction: Equatable, Codable, Sendable {
        public let operation: Charter.Chart.QuarkOperation
        public let action: Charter.Chart.Action

        public enum CodingKeys: String, CodingKey {
            case operation
            case action
        }

        public init(operation: Charter.Chart.QuarkOperation, action: Charter.Chart.Action) {
            self.operation = operation
            self.action = action
        }
    }
}
