import Foundation
import Testing

@testable import Prelude

@Test("Decimal Scientific encoding - standard decimals")
func decimalScientificStandardDecimals() throws {
    // Basic decimal parsing
    let decimal1 = try Decimal(scientificString: "123.456")
    #expect(decimal1 == Decimal(string: "123.456")!)

    let decimal2 = try Decimal(scientificString: "0.001")
    #expect(decimal2 == Decimal(string: "0.001")!)

    let decimal3 = try Decimal(scientificString: "1000000")
    #expect(decimal3 == Decimal(string: "1000000")!)

    // Negative numbers
    let decimal4 = try Decimal(scientificString: "-123.45")
    #expect(decimal4 == Decimal(string: "-123.45")!)

    // Zero
    let decimal5 = try Decimal(scientificString: "0")
    #expect(decimal5 == Decimal.zero)

    // Very small number
    let decimal6 = try Decimal(scientificString: "0.0000000001")
    #expect(decimal6 == Decimal(string: "0.0000000001")!)
}

@Test("Decimal Scientific encoding - scientific notation")
func decimalScientificNotation() throws {
    // Positive exponent
    let decimal1 = try Decimal(scientificString: "1.23e4")
    #expect(decimal1 == Decimal(12300))

    let decimal2 = try Decimal(scientificString: "1.23E4")  // Capital E
    #expect(decimal2 == Decimal(12300))

    // Negative exponent
    let decimal3 = try Decimal(scientificString: "1.5e-3")
    #expect(decimal3 == Decimal(string: "0.0015")!)

    // Large number
    let decimal4 = try Decimal(scientificString: "9.9e10")
    #expect(decimal4 == Decimal(99_000_000_000))

    // Zero exponent
    let decimal5 = try Decimal(scientificString: "123.456e0")
    #expect(decimal5 == Decimal(string: "123.456")!)

    // Negative coefficient with positive exponent
    let decimal6 = try Decimal(scientificString: "-1.5e2")
    #expect(decimal6 == Decimal(-150))

    // Negative coefficient with negative exponent
    let decimal7 = try Decimal(scientificString: "-2.5e-2")
    #expect(decimal7 == Decimal(string: "-0.025")!)
}

@Test("Decimal Scientific encoding - output format")
func decimalScientificOutput() throws {
    // Clean integers
    let decimal1 = Decimal(1000)
    #expect(decimal1.scientific == "1000")

    // Decimals with trailing zeros removed
    let decimal2 = Decimal(string: "123.4500")!
    #expect(decimal2.scientific == "123.45")

    // Very small decimals
    let decimal3 = Decimal(string: "0.00001")!
    #expect(decimal3.scientific == "0.00001")

    // Negative numbers
    let decimal4 = Decimal(string: "-123.45")!
    #expect(decimal4.scientific == "-123.45")

    // Zero
    let decimal5 = Decimal.zero
    #expect(decimal5.scientific == "0")

    // Number with many decimal places
    let decimal6 = Decimal(string: "3.141592653589793")!
    #expect(decimal6.scientific == "3.141592653589793")

    // Whole number with decimal point
    let decimal7 = Decimal(string: "100.0")!
    #expect(decimal7.scientific == "100")
}

@Test("Decimal Scientific encoding - error cases")
func decimalScientificErrors() throws {
    // Invalid decimal string
    #expect(throws: ScientificEncodingError.self) {
        try Decimal(scientificString: "abc")
    }

    // Invalid scientific notation - missing exponent
    #expect(throws: ScientificEncodingError.self) {
        try Decimal(scientificString: "1.23e")
    }

    // Invalid scientific notation - missing coefficient
    #expect(throws: ScientificEncodingError.self) {
        try Decimal(scientificString: "e10")
    }

    // Multiple decimal points
    #expect(throws: ScientificEncodingError.self) {
        try Decimal(scientificString: "1.2.3")
    }

    // Invalid exponent
    #expect(throws: ScientificEncodingError.self) {
        try Decimal(scientificString: "1.23eX")
    }

    // Multiple e's
    #expect(throws: ScientificEncodingError.self) {
        try Decimal(scientificString: "1e2e3")
    }
}

@Test("Decimal Scientific encoding - whitespace handling")
func decimalScientificWhitespace() throws {
    let decimal1 = try Decimal(scientificString: "  123.45  ")
    #expect(decimal1 == Decimal(string: "123.45")!)

    let decimal2 = try Decimal(scientificString: "\n1.23e4\t")
    #expect(decimal2 == Decimal(12300))
}
