import Foundation
import SwiftNumber

extension Amount: ScientificEncodable {
    public init(scientificString: String) throws {
        if scientificString.contains("e") {
            let parts = scientificString.split(separator: "e")
            guard parts.count == 2 else {
                throw ScientificEncodingError.invalidScientificNotation(scientificString)
            }

            let coefficientStr = String(parts[0])
            let exponentStr = String(parts[1])

            guard let exponent = Int(exponentStr) else {
                throw ScientificEncodingError.invalidScientificNotation(scientificString)
            }

            guard let coefficient = Number(coefficientStr, andPrecision: exponent) else {
                throw ScientificEncodingError.invalidNumberStringForExponent(coefficientStr, exponent)
            }
            self.init(coefficient, decimals: exponent)
        } else {
            guard let value = Number(scientificString) else {
                throw ScientificEncodingError.invalidRawNumberString(scientificString)
            }
            self.init(value, decimals: 0)
        }
    }

    public var scientific: String {
        if decimals > 0 {
            let divisor = Number(10).power(decimals)
            let quotient = underlying / divisor
            let remainder = underlying % divisor

            if remainder == 0 {
                return "\(quotient)e\(decimals)"
            } else {
                guard let decimalValue = Decimal(string: underlying.description) else {
                    Logger.error("Amount.scientific - Failed to convert to Decimal, using underlying.description: \(underlying)")
                    return underlying.description
                }

                let decimalDivisor = pow(Decimal(10), decimals)
                let coefficient = decimalValue / decimalDivisor

                // Use Decimal's native description to preserve full precision
                let coefficientStr = (coefficient as NSDecimalNumber).description(withLocale: nil)
                return "\(coefficientStr)e\(decimals)"
            }
        } else {
            return underlying.description
        }
    }
}
