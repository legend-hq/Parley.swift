import Foundation

/// Protocol for types that can be encoded/decoded in scientific notation
public protocol ScientificEncodable: Codable {
    init(scientificString: String) throws
    var scientific: String { get }
}

/// Property wrapper that encodes numeric types in scientific notation or as clean decimals
@propertyWrapper
public struct Scientific<T>: Codable, Sendable where T: ScientificEncodable & Sendable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        self.wrappedValue = try T(scientificString: str)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.scientific)
    }
}

/// Property wrapper for Optional ScientificEncodable types
@propertyWrapper
public struct ScientificNil<T>: Codable, Sendable where T: ScientificEncodable & Sendable {
    public var wrappedValue: T?

    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.wrappedValue = nil
        } else {
            let str = try container.decode(String.self)
            self.wrappedValue = try T(scientificString: str)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = wrappedValue {
            try container.encode(value.scientific)
        } else {
            try container.encodeNil()
        }
    }
}

/// Extension to support Optional ScientificEncodable types
extension Scientific: Equatable where T: Equatable {
    public static func == (lhs: Scientific<T>, rhs: Scientific<T>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Scientific: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        wrappedValue.hash(into: &hasher)
    }
}

extension ScientificNil: Equatable where T: Equatable {
    public static func == (lhs: ScientificNil<T>, rhs: ScientificNil<T>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension ScientificNil: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        wrappedValue.hash(into: &hasher)
    }
}

/// Error types for scientific encoding
public enum ScientificEncodingError: Error, CustomStringConvertible, LocalizedError {
    case invalidScientificNotation(String)
    case invalidDecimalString(String)
    case invalidNumberString(String)
    case invalidRawNumberString(String)
    case invalidNumberStringForExponent(String, Int)
    case invalidDecimalsForPrice(String)

    public var description: String {
        switch self {
            case .invalidScientificNotation(let str):
                return "Invalid scientific notation: \(str)"
            case .invalidDecimalString(let str):
                return "Invalid decimal string: \(str)"
            case .invalidNumberString(let str):
                return "Invalid number string: \(str)"
            case .invalidRawNumberString(let str):
                return "Invalid raw number string: \(str)"
            case .invalidNumberStringForExponent(let str, let exp):
                return "Invalid number string: \(str) exp=\(exp)"
            case .invalidDecimalsForPrice(let str):
                return "Invalid decimals for price: \(str)"
        }
    }

    public var errorDescription: String? {
        return description
    }
}
