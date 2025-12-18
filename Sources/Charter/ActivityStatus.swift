import Eth
import Foundation
import Prelude

public struct ActivityStatus: Codable, Hashable, Equatable {
    public let steps: [Step]

    public init(steps: [Step]) {
        self.steps = steps
    }

    public enum Status: String, Codable {
        case pending
        case completed
        case failed
    }

    public struct Step: Codable, Hashable, Equatable {
        public let actionContext: Charter.ActionContext
        public let network: Network
        public let executedAt: ISODate?
        public let revertedAt: ISODate?

        enum CodingKeys: String, CodingKey {
            case actionType = "action_type"
            case actionContext = "action_context"
            case network = "chain_id"
            case executedAt = "executed_at"
            case revertedAt = "reverted_at"
        }

        public init(
            actionContext: Charter.ActionContext,
            network: Network,
            executedAt: ISODate?,
            revertedAt: ISODate?
        ) {
            self.actionContext = actionContext
            self.network = network
            self.executedAt = executedAt
            self.revertedAt = revertedAt
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            network = try container.decode(Network.self, forKey: .network)
            executedAt = try container.decode(ISODate?.self, forKey: .executedAt)
            revertedAt = try container.decode(ISODate?.self, forKey: .revertedAt)
            actionContext = try Charter.ActionContext(from: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(network, forKey: .network)
            try container.encode(executedAt, forKey: .executedAt)
            try container.encode(revertedAt, forKey: .revertedAt)
            try actionContext.encode(to: encoder)
        }

        public var status: Status {
            if executedAt != nil {
                .completed
            } else if revertedAt != nil {
                .failed
            } else {
                .pending
            }
        }
    }

    public var completedSteps: Int {
        steps.filter { $0.status == .completed || $0.status == .failed }.count
    }

    public var totalSteps: Int {
        steps.count
    }

    // TODO: This doesn't handle failures
    public var progress: Double {
        Double(completedSteps) / Double(totalSteps)
    }
}
