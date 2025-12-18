import Foundation

public protocol StringListCodable {
    static func fromStringList(_ values: [String]) throws -> (Self, [String])
    func toStringList() -> [String]
}

public enum StringListCodableError: Error {
    case insufficientValues(expected: Int, got: Int)
    case unknownDiscriminator(String)
    case invalidFormat(String)
}

extension String {
    func escapingSlashes() -> String {
        return self.replacingOccurrences(of: "/", with: "\\/")
    }

    func unescapingSlashes() -> String {
        return self.replacingOccurrences(of: "\\/", with: "/")
    }
}
