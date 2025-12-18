import Foundation
import SwiftNumber

/// Frequency represents the frequency at which a transaction is replayed. When `oneTime`, the transaction is
/// just executed once and never replayed
public enum Frequency: CaseIterable, Equatable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case oneTime
    case daily
    case weekly
    case monthly

    public init(interval: Number) {
        self =
            Frequency.allCases.first {
                $0.interval == interval
            } ?? .oneTime
    }

    public var title: String {
        switch self {
            case .oneTime:
                "One Time"
            case .daily:
                "Daily"
            case .weekly:
                "Weekly"
            case .monthly:
                "Monthly"
        }
    }

    public var subtitle: String {
        switch self {
            case .oneTime:
                "Default"
            case .daily:
                "Every day"
            case .weekly:
                "Every 7 days"
            case .monthly:
                "Every 30 days"
        }
    }

    /// Returns the interval in seconds for the given frequency
    public var interval: Number {
        let day = 24 * 60 * 60
        let week = day * 7
        let month = day * 30

        return switch self {
            case .oneTime:
                .zero
            case .daily:
                Number(day)
            case .weekly:
                Number(week)
            case .monthly:
                Number(month)
        }
    }
}
