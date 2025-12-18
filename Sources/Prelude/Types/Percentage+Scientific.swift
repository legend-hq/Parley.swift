import Foundation
import SwiftNumber

extension Percentage: ScientificEncodable {
    public init(scientificString: String) throws {
        let exponent = 18
        let negative = scientificString.starts(with: "-")
        let coefficientStr = String(scientificString.trimmingPrefix("-"))
        guard let coefficient = Number(coefficientStr, andPrecision: exponent) else {
            throw ScientificEncodingError.invalidNumberStringForExponent(coefficientStr, exponent)
        }
        let result: SNumber
        if negative {
            result = SNumber(coefficient) * -1
        } else {
            result = SNumber(coefficient)
        }
        self.init(result)
    }

    public var scientific: String {
        let decimals = 18
        let divisor = SNumber(10).power(decimals)
        let quotient = underlying / divisor
        let remainder = underlying % divisor

        if remainder == 0 {
            return "\(quotient)"
        } else {
            guard let decimalValue = Decimal(string: underlying.description) else {
                Logger.error(
                    "Percentage.scientific - Failed to convert to Decimal, using underlying.description: \(underlying)"
                )
                return underlying.description
            }

            let decimalDivisor = pow(Decimal(10), decimals)
            let coefficient = decimalValue / decimalDivisor

            // Use Decimal's native description to preserve full precision
            let coefficientStr = (coefficient as NSDecimalNumber).description(withLocale: nil)
            return "\(coefficientStr)"
        }
    }
}
