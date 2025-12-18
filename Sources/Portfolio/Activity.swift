import Charter
import Eth
import Foundation
import Prelude

public struct Activity: Codable, Equatable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let accountId: Int
    public let activityMetadata: [ActivityMetadata]
    public let activityType: ActivityType
    public let occurredAt: Date
    public let liveActivityPushToken: Hex?

    public init(
        activityId: Int,
        accountId: Int,
        activityMetadata: [ActivityMetadata],
        activityType: ActivityType,
        occurredAt: Date,
        liveActivityPushToken: Hex?,
    ) {
        self.id = activityId
        self.accountId = accountId
        self.activityMetadata = activityMetadata
        self.activityType = activityType
        self.occurredAt = occurredAt
        self.liveActivityPushToken = liveActivityPushToken
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case activityMetadata = "activity_metadata"
        case activityType = "activity_type"
        case occurredAt = "occurred_at"
        case liveActivityPushToken = "live_activity_push_token"
    }

    public var steps: [ActivityStatus.Step] {
        activityMetadata.compactMap { $0.asStep }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public enum State {
        case notStarted
        case pending
        case completed
        case reverted

        public var description: String {
            switch self {
                case .notStarted:
                    "Not Started"
                case .pending:
                    "Pending"
                case .completed:
                    "Complete"
                case .reverted:
                    "Failed"
            }
        }
    }

    public var isNotStarted: Bool {
        state == .notStarted
    }

    public var isPending: Bool {
        state == .pending
    }

    public var isCompleted: Bool {
        state == .completed
    }

    public var isReverted: Bool {
        state == .reverted
    }

    public var state: State {
        if activityMetadata.allSatisfy({ $0.isCompleted }) {
            return .completed
        } else if activityMetadata.contains(where: { $0.isReverted }) {
            return .reverted
        } else {
            // NOTE: This unifies .notStarted and .pending activities into one group for now
            // until we properly support delayed transactions
            return .pending
        }
    }

    public var bridgeReceivedMetadata: ActivityMetadata? {
        return activityMetadata.first {
            $0.isBridgeReceivedMetadata
        }
    }

    public var bridgeReceived: Bool {
        bridgeReceivedMetadata != nil
    }

    public var completedSteps: Int {
        activityMetadata.filter { metadata in
            guard metadata.actionContext != nil else {
                return false
            }

            let state = metadata.activityDetailState(activityMetadata)
            return state == .completed || state == .reverted
        }
        .count
    }

    public var isInboundTransfer: Bool {
        activityMetadata.count == 1 && activityMetadata[0].isInboundTransferMetadata
    }

    public var totalActions: Int {
        activityMetadata.reduce(0) {
            $0 + ($1.actionContext?.actionCount ?? 0)
        }
    }

    /// True if the activity is related to the asset symbol when determining recent transactions
    public func isRelatedTo(assetSymbol: String, portfolios: [Portfolio]) -> Bool {
        activityMetadata.contains {
            let isQuotePay = $0.actionContext?.isQuotePay ?? false

            return $0.isRelatedTo(assetSymbol: assetSymbol, portfolios: portfolios)
                && !isQuotePay
        }
    }
}
