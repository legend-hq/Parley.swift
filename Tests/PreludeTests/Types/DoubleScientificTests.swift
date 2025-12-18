import Foundation
import Testing

@testable import Prelude

@Test("Double Scientific encoding - standard decimals")
func doubleScientificStandardDecimals() throws {
    // Basic decimal parsing
    let double1 = try Double(scientificString: "123.456")
    #expect(double1 == 123.456)

    let double2 = try Double(scientificString: "0.001")
    #expect(double2 == 0.001)

    let double3 = try Double(scientificString: "1000000")
    #expect(double3 == 1000000.0)

    // Negative numbers
    let double4 = try Double(scientificString: "-123.45")
    #expect(double4 == -123.45)

    // Zero
    let double5 = try Double(scientificString: "0")
    #expect(double5 == 0.0)

    // Very small number
    let double6 = try Double(scientificString: "0.0000000001")
    #expect(double6 == 0.0000000001)
}

@Test("Double Scientific encoding - scientific notation")
func doubleScientificNotation() throws {
    // Positive exponent
    let double1 = try Double(scientificString: "1.23e4")
    #expect(double1 == 12300.0)

    let double2 = try Double(scientificString: "1.23E4")  // Capital E
    #expect(double2 == 12300.0)

    // Negative exponent
    let double3 = try Double(scientificString: "1.5e-3")
    #expect(double3 == 0.0015)

    // Large number
    let double4 = try Double(scientificString: "9.9e10")
    #expect(double4 == 99000000000.0)

    // Zero exponent
    let double5 = try Double(scientificString: "123.456e0")
    #expect(double5 == 123.456)

    // Negative coefficient with positive exponent
    let double6 = try Double(scientificString: "-1.5e2")
    #expect(double6 == -150.0)

    // Negative coefficient with negative exponent
    let double7 = try Double(scientificString: "-2.5e-2")
    #expect(double7 == -0.025)

    // Very large exponent
    let double8 = try Double(scientificString: "1.5e308")
    #expect(double8 == 1.5e308)

    // Very small (negative) exponent
    let double9 = try Double(scientificString: "1.5e-308")
    #expect(double9 == 1.5e-308)
}

@Test("Double Scientific encoding - output format")
func doubleScientificOutput() throws {
    // Clean integers
    let double1 = 1000.0
    #expect(double1.scientific == "1000")

    // Decimals with trailing zeros removed
    let double2 = 123.4500
    #expect(double2.scientific == "123.45")

    // Very small decimals
    let double3 = 0.00001
    #expect(double3.scientific == "0.00001")

    // Negative numbers
    let double4 = -123.45
    #expect(double4.scientific == "-123.45")

    // Zero
    let double5 = 0.0
    #expect(double5.scientific == "0")

    // Number with many decimal places
    let double6 = 3.141592653589793
    #expect(double6.scientific == "3.141592653589793")

    // Whole number that's technically a double
    let double7 = 100.0
    #expect(double7.scientific == "100")

    // Very large number
    let double8 = 1.23456789e20
    #expect(double8.scientific == "123456789000000000000")
}

@Test("Double Scientific encoding - special values")
func doubleScientificSpecialValues() throws {
    // NaN
    let nan = Double.nan
    #expect(nan.scientific == "NaN")

    // Positive infinity
    let posInf = Double.infinity
    #expect(posInf.scientific == "Infinity")

    // Negative infinity
    let negInf = -Double.infinity
    #expect(negInf.scientific == "-Infinity")
}

@Test("Double Scientific encoding - error cases")
func doubleScientificErrors() throws {
    // Invalid decimal string
    #expect(throws: ScientificEncodingError.self) {
        try Double(scientificString: "abc")
    }

    // Empty string
    #expect(throws: ScientificEncodingError.self) {
        try Double(scientificString: "")
    }

    // Multiple decimal points
    #expect(throws: ScientificEncodingError.self) {
        try Double(scientificString: "1.2.3")
    }

    // Special strings that aren't numbers
    #expect(throws: ScientificEncodingError.self) {
        try Double(scientificString: "one point five")
    }
}

@Test("Double Scientific encoding - whitespace handling")
func doubleScientificWhitespace() throws {
    let double1 = try Double(scientificString: "  123.45  ")
    #expect(double1 == 123.45)

    let double2 = try Double(scientificString: "\n1.23e4\t")
    #expect(double2 == 12300.0)

    let double3 = try Double(scientificString: " -99.9 ")
    #expect(double3 == -99.9)
}

@Test("Double Scientific encoding - edge cases")
func doubleScientificEdgeCases() throws {
    // Plus sign
    let double1 = try Double(scientificString: "+123.45")
    #expect(double1 == 123.45)

    // Leading zeros
    let double2 = try Double(scientificString: "00123.45")
    #expect(double2 == 123.45)

    // Decimal point at start
    let double3 = try Double(scientificString: ".5")
    #expect(double3 == 0.5)

    // Decimal point at end
    let double4 = try Double(scientificString: "123.")
    #expect(double4 == 123.0)
}
