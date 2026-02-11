import Charter
import Eth
import Foundation
import Prelude

public struct ActivityMetadata: Codable, Equatable, Sendable {
    public let quarkOperationId: Int?
    public let quarkOperationNonce: Hex?
    public let quarkWalletAddress: EthAddress
    public let network: Network
    public let actionContext: Charter.ActionContext?
    public let semanticEventContexts: [SemanticEventContext]
    public let success: Bool?
    public let transactionHash: Hex?
    public let revertReason: String?
    public let revertSignature: String?
    public let revertValues: String?
    public let revertedAt: Date?
    public let executedAt: Date?
    public let executedAtBlockNumber: Int?
    public let activityRecordType: ActivityRecordType

    public init(
        quarkOperationId: Int?,
        quarkOperationNonce: Hex?,
        quarkWalletAddress: EthAddress,
        network: Network,
        actionContext: Charter.ActionContext?,
        semanticEventContexts: [SemanticEventContext],
        transactionHash: Hex? = nil,
        success: Bool? = nil,
        revertSignature: String?,
        revertValues: String?,
        revertedAt: Date?,
        executedAt: Date?,
        executedAtBlockNumber: Int?,
        activityRecordType: ActivityRecordType
    ) {
        self.quarkOperationId = quarkOperationId
        self.quarkOperationNonce = quarkOperationNonce
        self.quarkWalletAddress = quarkWalletAddress
        self.network = network
        self.actionContext = actionContext
        self.semanticEventContexts = semanticEventContexts
        self.transactionHash = transactionHash
        self.success = success
        self.revertSignature = revertSignature
        self.revertValues = revertValues
        self.revertReason = nil
        self.revertedAt = revertedAt
        self.executedAt = executedAt
        self.executedAtBlockNumber = executedAtBlockNumber
        self.activityRecordType = activityRecordType
    }

    private enum CodingKeys: String, CodingKey {
        case quarkOperationId = "quark_operation_id"
        case quarkOperationNonce = "quark_operation_nonce"
        case quarkWalletAddress = "quark_wallet_address"
        case network = "chain_id"
        case semanticEventContexts = "semantic_events"
        case success
        case transactionHash = "transaction_hash"
        case revertReason = "revert_reason"
        case revertSignature = "revert_signature"
        case revertValues = "revert_values"
        case revertedAt = "reverted_at"
        case executedAt = "executed_at"
        case executedAtBlockNumber = "executed_at_block_number"
        case activityRecordType = "activity_record_type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.quarkOperationId = try? container.decode(Int?.self, forKey: .quarkOperationId)
        self.quarkOperationNonce = try? container.decode(Hex?.self, forKey: .quarkOperationNonce)
        self.quarkWalletAddress = try container.decode(EthAddress.self, forKey: .quarkWalletAddress)
        self.network = try container.decode(Network.self, forKey: .network)
        self.actionContext = try? Charter.ActionContext(from: decoder)

        // Semantic event contexts don't come sorted, but we can sort them by the first log index
        let semanticEventContexts = try container.decode(
            [SemanticEventContext].self,
            forKey: .semanticEventContexts
        )
        self.semanticEventContexts = semanticEventContexts.sorted { left, right in
            guard let leftLogIndex = left.logIndices.first, let leftLogIndex,
                  let rightLogIndex = right.logIndices.first, let rightLogIndex
            else {
                return false
            }

            return leftLogIndex < rightLogIndex
        }

        self.success = try? container.decode(Bool.self, forKey: .success)
        self.transactionHash = try? container.decode(Hex?.self, forKey: .transactionHash)
        self.revertReason = try? container.decode(String.self, forKey: .revertReason)
        self.revertSignature = try? container.decode(String.self, forKey: .revertSignature)
        self.revertValues = try? container.decode(String.self, forKey: .revertValues)
        self.revertedAt = try? container.decode(Date?.self, forKey: .revertedAt)
        self.executedAt = try? container.decode(Date?.self, forKey: .executedAt)
        self.executedAtBlockNumber = try? container.decode(
            Int?.self,
            forKey: .executedAtBlockNumber
        )
        self.activityRecordType = try container.decode(
            ActivityRecordType.self,
            forKey: .activityRecordType
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quarkOperationId, forKey: .quarkOperationId)
        try container.encode(quarkOperationNonce, forKey: .quarkOperationNonce)
        try container.encode(quarkWalletAddress, forKey: .quarkWalletAddress)
        try container.encode(network, forKey: .network)

        if let actionContext {
            try actionContext.encode(to: encoder)
        }

        try container.encode(semanticEventContexts, forKey: .semanticEventContexts)
        try container.encode(success, forKey: .success)
        try container.encode(transactionHash, forKey: .transactionHash)
        try container.encode(revertReason, forKey: .revertReason)
        try container.encode(revertSignature, forKey: .revertSignature)
        try container.encode(revertValues, forKey: .revertValues)
        try container.encode(revertedAt, forKey: .revertedAt)
        try container.encode(executedAt, forKey: .executedAt)
        try container.encode(executedAtBlockNumber, forKey: .executedAtBlockNumber)
        try container.encode(activityRecordType, forKey: .activityRecordType)
    }

    public enum ActivityRecordType: String, Codable, Sendable {
        case executed
        case unexecuted
        case exogenous
    }

    public func semanticEvents(portfolios: [Portfolio]) -> [SemanticEvent] {
        return semanticEventContexts.compactMap {
            $0.toSemanticEvent(network: network, portfolios: portfolios)
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

    public var state: Activity.State {
        let notWaitingForSemanticEvents =
            !semanticEventContexts.isEmpty
                || Date().timeIntervalSince1970 - (executedAt?.timeIntervalSince1970 ?? .infinity) >= 60

        if let success, success, transactionHash != nil, notWaitingForSemanticEvents {
            return .completed
        } else if revertedAt != nil {
            return .reverted
        } else if transactionHash != nil {
            return .pending
        } else {
            return .notStarted
        }
    }

    public var asStep: ActivityStatus.Step? {
        guard let actionContext else { return nil }

        return ActivityStatus.Step(
            actionContext: actionContext,
            network: network,
            executedAt: ISODate(executedAt),
            revertedAt: ISODate(revertedAt)
        )
    }

    public var isBridgeReceivedMetadata: Bool {
        semanticEventContexts.contains { $0.eventType == .bridgeReceive }
    }

    public var isInboundTransferMetadata: Bool {
        semanticEventContexts.contains { $0.eventType == .inboundTransfer }
    }

    public var isLiquidationMetadata: Bool {
        semanticEventContexts.contains {
            $0.eventType == .morphoLiquidation || $0.eventType == .cometLiquidationCollateralAbsorbed || $0.eventType == .cometLiquidationBasePaidOut
        }
    }

    public var isExogenousMetadata: Bool {
        activityRecordType == .exogenous
    }

    // Returns an Activity.State for the current ActivityMetadata considering all other
    // ActivityMetadata objects in the Activity as well
    public func activityDetailState(_ activityMetadata: [ActivityMetadata]) -> Activity.State {
        guard let actionContext,
              actionContext.isBridge,
              isCompleted
        else {
            return state
        }

        return activityMetadata.allSatisfy { $0.isCompleted }
            || activityMetadata.contains { $0.isBridgeReceivedMetadata } ? .completed : .pending
    }

    public func isRelatedTo(assetSymbol: String, portfolios: [Portfolio]) -> Bool {
        let hasRelatedActionContext = actionContext?.isRelatedTo(assetSymbol: assetSymbol) ?? false
        let hasRelatedSemanticEvents = semanticEvents(portfolios: portfolios)
            .contains {
                $0.isRelatedTo(assetSymbol: assetSymbol)
            }

        return hasRelatedActionContext || hasRelatedSemanticEvents
    }

    public var bridgeActionContext: Charter.ActionContext.BridgeActionContext? {
        actionContext?.bridgeActionContext
    }

    public var relayHash: Hex? {
        semanticEventContexts.compactMap { event in
            switch event.type {
                case .bridgeSend(let bridgeSend):
                    return bridgeSend.relayHash
                default:
                    return nil
            }
        }
        .first
    }

    public var cctpV2SourceChainId: UInt64? {
        semanticEventContexts.compactMap { event in
            switch event.type {
                case .bridgeSend(let bridgeSend):
                    return bridgeSend.sourceChainId
                default:
                    return nil
            }
        }
        .first
    }

    public var cctpV2Nonce: Hex? {
        semanticEventContexts.compactMap { event in
            switch event.type {
                case .bridgeSend(let bridgeSend):
                    return bridgeSend.nonce
                default:
                    return nil
            }
        }
        .first
    }

    /// Returns whether or not this activity metadata is included in the given portfolio.
    /// Note: returns nil when that state is unknown (i.e. because the quark nonce status is not included in the portfolio)
    public func isIncluded(inPortfolio portfolio: Portfolio) -> Bool? {
        for status in portfolio.quarkNonceStatuses {
            if status.nonce == quarkOperationNonce {
                return status.submitted
            }
        }
        return nil
    }

    /// Returns whether or not this activity metadata is an Across bridge which is filled in the given portfolio.
    /// Note: returns nil when that state is unknown (i.e. because the across fill status is not included in the portfolio)
    /// Note: returns nil if we don't have a relay hash for this activity metadata (i.e. it's either not a bridge send
    /// or it's non-deterministic and we haven't been assigned a relay hash yet).
    public func isAcrossBridgeFilled(inPortfolio portfolio: Portfolio) -> Bool? {
        if let relayHash {
            for status in portfolio.acrossFillStatuses {
                if status.relayHash == relayHash {
                    return status.filled
                }
            }
            return nil
        } else {
            return nil
        }
    }

    /// Returns whether or not this activity metadata is a CCTPv2 bridge which is filled in the given portfolio.
    /// Note: returns nil when that state is unknown (i.e. because the cctp_v2 fill status is not included in the portfolio)
    /// Note: returns nil if we don't have a nonce for this activity metadata.
    public func isCctpV2BridgeFilled(inPortfolio portfolio: Portfolio) -> Bool? {
        if let cctpV2Nonce {
            for status in portfolio.cctpV2FillStatuses {
                if status.nonce == cctpV2Nonce {
                    return status.filled
                }
            }
            return nil
        } else {
            return nil
        }
    }

    public func shouldPatchPortfolio(_ portfolio: Portfolio) -> Bool {
        guard revertedAt == nil else {
            return false
        }

        if actionContext != nil && portfolio.chain.chainId == network.chainId {
            if let isIncluded = isIncluded(inPortfolio: portfolio) {
                return !isIncluded
            }

            if executedAtBlockNumber == nil || executedAtBlockNumber! > portfolio.block.number {
                return true
            }
        }

        return false
    }
}
