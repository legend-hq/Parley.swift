import Foundation

extension Double: ScientificEncodable {
    public init(scientificString: String) throws {
        let trimmed = scientificString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to parse using Double's built-in parsing which handles scientific notation
        if let value = Double(trimmed) {
            self = value
        } else {
            // If standard parsing fails, try manual scientific notation parsing
            if trimmed.lowercased().contains("e") {
                throw ScientificEncodingError.invalidScientificNotation(scientificString)
            } else {
                throw ScientificEncodingError.invalidDecimalString(scientificString)
            }
        }
    }

    public var scientific: String {
        // Handle special cases
        if self.isNaN {
            return "NaN"
        }
        if self.isInfinite {
            return self > 0 ? "Infinity" : "-Infinity"
        }

        // Use NumberFormatter for consistent output
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 15  // Double precision limit
        formatter.decimalSeparator = "."

        // Format and remove trailing zeros
        if let formatted = formatter.string(from: NSNumber(value: self)) {
            // Remove unnecessary trailing zeros after decimal point
            if formatted.contains(".") {
                var result = formatted
                while result.hasSuffix("0") && !result.hasSuffix(".0") {
                    result.removeLast()
                }
                if result.hasSuffix(".") {
                    result.removeLast()
                }
                return result
            }
            return formatted
        }

        // Fallback to string interpolation
        return "\(self)"
    }
}
