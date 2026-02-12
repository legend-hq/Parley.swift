import Foundation
import SwiftNumber

extension SignedAmount: ScientificEncodable {
    public init(scientificString: String) throws {
        try self.init(scientificString)
    }

    public var scientific: String {
        if decimals > 0 {
            let divisor = SNumber(10).power(decimals)
            let quotient = underlying / divisor
            let remainder = underlying % divisor

            if remainder == 0 {
                return "\(quotient)e\(decimals)"
            } else {
                guard let decimalValue = Decimal(string: underlying.description) else {
                    return underlying.description
                }

                let decimalDivisor = pow(Decimal(10), decimals)
                let coefficient = decimalValue / decimalDivisor

                let coefficientStr = (coefficient as NSDecimalNumber).description(withLocale: nil)
                return "\(coefficientStr)e\(decimals)"
            }
        } else {
            return underlying.description
        }
    }
}
