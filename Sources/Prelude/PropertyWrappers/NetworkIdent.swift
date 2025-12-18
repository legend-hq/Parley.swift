import Eth
import Foundation

/// Property wrapper for human-readable network identifier encoding
@propertyWrapper
public struct NetworkIdent: Codable, Sendable {
    public var wrappedValue: Network

    public init(wrappedValue: Network) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let ident = try container.decode(String.self)
        self.wrappedValue = try Network(fromIdent: ident)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.networkIdent)
    }
}

extension NetworkIdent: Equatable {
    public static func == (lhs: NetworkIdent, rhs: NetworkIdent) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension NetworkIdent: Hashable {
    public func hash(into hasher: inout Hasher) {
        wrappedValue.hash(into: &hasher)
    }
}
