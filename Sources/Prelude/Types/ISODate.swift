//  A wrapper for Date that always encodes/decodes as ISO-8601

import Foundation

public struct ISODate: Codable, Equatable, Hashable {
    public let date: Date

    public init(_ date: Date) {
        self.date = date
    }

    public init?(_ date: Date?) {
        if let date {
            self.date = date
        } else {
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format"
            )
        }

        self.date = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        try container.encode(dateString)
    }

    public var formatted: String {
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)

        return dateString
    }
}
