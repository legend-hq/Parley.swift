import Foundation
import SwiftNumber

extension Value: ScientificEncodable {
    public init(scientificString: String) throws {
        if scientificString.contains("e") || scientificString.contains("E") {
            throw ScientificEncodingError.invalidNumberString("Value includes suffix: \(scientificString)")
        }
        let suffixedString = "\(scientificString)e8"
        guard let amount = try? Amount.init(scientificString: suffixedString) else {
            throw ScientificEncodingError.invalidDecimalsForPrice("suffixedString: \(suffixedString)")
        }
        guard amount.decimals == 8 else {
            throw ScientificEncodingError.invalidDecimalsForPrice(scientificString)
        }
        self = Value.init(amount.underlying)
    }

    public var scientific: String {
        Amount(self.underlying, decimals: 8).scientific.removingSuffix("e8")
    }
}

extension String {
    func removingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
}
