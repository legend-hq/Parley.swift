import Foundation

extension String {
    /// Split a path string on unescaped forward slashes
    fileprivate func splitPath() -> [String] {
        var components: [String] = []
        var current = ""
        var escaped = false

        for char in self {
            if escaped {
                current.append(char)
                escaped = false
            } else if char == "\\" {
                escaped = true
                current.append(char)
            } else if char == "/" {
                components.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }

        if !current.isEmpty {
            components.append(current)
        }

        return components.map { $0.unescapingSlashes() }
    }
}

@propertyWrapper
public struct PathDict<K: StringListCodable & Hashable & Codable & Sendable, V: Codable & Sendable>:
    Codable, Sendable
{
    public var wrappedValue: [K: V]

    public init(wrappedValue: [K: V]) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        var result = [K: V]()

        // Check if V conforms to ScientificEncodable
        if let scientificType = V.self as? any ScientificEncodable.Type {
            // Decode from String dictionary for scientific values
            let stringDict = try container.decode([String: String].self)

            for (keyString, valueString) in stringDict {
                let components = keyString.splitPath()
                let (key, remaining) = try K.fromStringList(components)
                guard remaining.isEmpty else {
                    throw StringListCodableError.invalidFormat(
                        "Unexpected remaining components: \(remaining)"
                    )
                }
                // Create the scientific value from the string
                if let value = try scientificType.init(scientificString: valueString) as? V {
                    result[key] = value
                }
            }
        } else {
            // Regular decoding for non-scientific values
            let stringDict = try container.decode([String: V].self)

            for (keyString, value) in stringDict {
                let components = keyString.splitPath()
                let (key, remaining) = try K.fromStringList(components)
                guard remaining.isEmpty else {
                    throw StringListCodableError.invalidFormat(
                        "Unexpected remaining components: \(remaining)"
                    )
                }
                result[key] = value
            }
        }
        self.wrappedValue = result
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        // Check if V conforms to ScientificEncodable at compile time
        if let _ = V.self as? any ScientificEncodable.Type {
            // Encode as String dictionary for scientific values
            var stringDict = [String: String]()
            for (key, value) in wrappedValue {
                let pathComponents = key.toStringList().map { $0.escapingSlashes() }
                let pathString = pathComponents.joined(separator: "/")
                if let scientificValue = value as? any ScientificEncodable {
                    stringDict[pathString] = scientificValue.scientific
                }
            }
            try container.encode(stringDict)
        } else {
            // Regular encoding for non-scientific values
            var stringDict = [String: V]()
            for (key, value) in wrappedValue {
                let pathComponents = key.toStringList().map { $0.escapingSlashes() }
                let pathString = pathComponents.joined(separator: "/")
                stringDict[pathString] = value
            }
            try container.encode(stringDict)
        }
    }
}

extension PathDict: Equatable where K: Equatable, V: Equatable {
    public static func == (lhs: PathDict<K, V>, rhs: PathDict<K, V>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension PathDict: Hashable where K: Hashable, V: Hashable {
    public func hash(into hasher: inout Hasher) {
        wrappedValue.hash(into: &hasher)
    }
}
