import Foundation

extension Decimal: ScientificEncodable {
    public init(scientificString: String) throws {
        let trimmed = scientificString.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.lowercased().contains("e") {
            // Handle scientific notation: "1.23e4" or "1.23E4"
            let parts = trimmed.lowercased().split(separator: "e")
            guard parts.count == 2 else {
                throw ScientificEncodingError.invalidScientificNotation(scientificString)
            }

            let coefficientStr = String(parts[0])
            let exponentStr = String(parts[1])

            // Parse coefficient as Decimal
            guard let coefficient = Decimal(string: coefficientStr) else {
                throw ScientificEncodingError.invalidDecimalString(coefficientStr)
            }

            // Parse exponent as Int
            guard let exponent = Int(exponentStr) else {
                throw ScientificEncodingError.invalidScientificNotation(scientificString)
            }

            // Calculate result using Decimal arithmetic
            // coefficient * 10^exponent
            if exponent == 0 {
                self = coefficient
            } else if exponent > 0 {
                var result = coefficient
                for _ in 0..<exponent {
                    result *= 10
                }
                self = result
            } else {
                // Negative exponent
                var result = coefficient
                for _ in 0..<abs(exponent) {
                    result /= 10
                }
                self = result
            }
        } else {
            // Direct decimal parsing - validate format first
            // Valid decimal: optional minus, digits, optional (decimal point + digits)
            let decimalPattern = "^-?\\d+(\\.\\d+)?$"
            let regex = try? NSRegularExpression(pattern: decimalPattern)
            let range = NSRange(trimmed.startIndex..., in: trimmed)

            guard regex?.firstMatch(in: trimmed, range: range) != nil,
                  let decimal = Decimal(string: trimmed) else {
                throw ScientificEncodingError.invalidDecimalString(scientificString)
            }
            self = decimal
        }
    }

    public var scientific: String {
        // Use native description to preserve full precision
        var result = self.description

        // Remove unnecessary trailing zeros after decimal point
        if result.contains(".") {
            while result.hasSuffix("0") && !result.hasSuffix(".0") {
                result.removeLast()
            }
            if result.hasSuffix(".") {
                result.removeLast()
            }
        }

        return result
    }
}
