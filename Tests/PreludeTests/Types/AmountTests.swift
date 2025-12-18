import SwiftNumber
import Testing
import Foundation

@testable import Prelude

@Test("Amount Scientific encoding")
func amountScientificEncoding() throws {
    let amount = try Amount(scientificString: "1.00e18")
    #expect(amount == Amount("1000000000000000000", decimals: 18))

    let amount2 = try Amount(scientificString: "5000.00e18")
    #expect(amount2 == Amount("5000000000000000000000", decimals: 18))

    let amount3 = try Amount(scientificString: "5000.123456789123456789e18")
    #expect(amount3 == Amount("5000123456789123456789", decimals: 18))
}

@Test("Amount Scientific encoding - precision preservation")
func amountScientificPrecisionPreservation() throws {
    // Test the specific case: 0.105531317983966714 ETH
    // underlying: 105531317983966714, decimals: 18
    let underlying = Number("105531317983966714")
    let decimals = 18
    let amount = Amount(underlying, decimals: decimals)

    // Encode to scientific notation
    let scientificString = amount.scientific
    print("Scientific encoding: \(scientificString)")

    // Decode back from scientific notation
    let decodedAmount = try Amount(scientificString: scientificString)

    // Verify the underlying value is preserved exactly
    #expect(decodedAmount.underlying == underlying, "Underlying value should be preserved: expected \(underlying), got \(decodedAmount.underlying)")
    #expect(decodedAmount.decimals == decimals, "Decimals should be preserved: expected \(String(decimals)), got \(String(decodedAmount.decimals))")
    #expect(decodedAmount == amount, "Amount should roundtrip exactly")
}

@Test("Amount Scientific encoding - JSON roundtrip")
func amountScientificJSONRoundtrip() throws {
    struct TestWrapper: Codable, Equatable {
        @Scientific var balance: Amount

        init(balance: Amount) {
            self.balance = balance
        }
    }

    // Create amount with the problematic value
    let underlying = Number("105531317983966714")
    let amount = Amount(underlying, decimals: 18)
    let wrapper = TestWrapper(balance: amount)

    // Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let jsonData = try encoder.encode(wrapper)
    let jsonString = String(data: jsonData, encoding: .utf8)!
    print("JSON output:\n\(jsonString)")

    // Decode from JSON
    let decoder = JSONDecoder()
    let decodedWrapper = try decoder.decode(TestWrapper.self, from: jsonData)

    // Verify exact match
    #expect(decodedWrapper == wrapper, "Wrapper should roundtrip exactly")
    #expect(decodedWrapper.balance.underlying == underlying, "Underlying value should be preserved after JSON roundtrip: expected \(underlying), got \(decodedWrapper.balance.underlying)")
    #expect(decodedWrapper.balance.decimals == 18, "Decimals should be preserved")
}

@Test("Amount Scientific encoding - high precision decimals")
func amountScientificHighPrecision() throws {
    struct TestCase {
        let base: Number
        let decimals: Int
        let encoded: String
        let description: String
    }

    let testCases: [TestCase] = [
        TestCase(
            base: Number("105531317983966714"),
            decimals: 18,
            encoded: "0.105531317983966714e18",
            description: "Original problematic value"
        ),
        TestCase(
            base: Number("123456789012345678"),
            decimals: 18,
            encoded: "0.123456789012345678e18",
            description: "18 significant digits"
        ),
        TestCase(
            base: Number("999999999999999999"),
            decimals: 18,
            encoded: "0.999999999999999999e18",
            description: "Max 18 digit value"
        ),
        TestCase(
            base: Number("100000000000000001"),
            decimals: 18,
            encoded: "0.100000000000000001e18",
            description: "Edge case: mostly zeros with 1 at end"
        ),
        TestCase(
            base: Number("123456789123456789"),
            decimals: 18,
            encoded: "0.123456789123456789e18",
            description: "Pattern that might expose rounding"
        ),
        TestCase(
            base: Number("31415926535892"),
            decimals: 13,
            encoded: "3.1415926535892e13",
            description: "Non-18 decimals case"
        ),
        TestCase(
            base: Number("1234567890123456789012345678"),
            decimals: 18,
            encoded: "1234567890.123456789012345678e18",
            description: "10 digits before decimal, 18 after"
        ),
    ]

    for testCase in testCases {
        let amount = Amount(testCase.base, decimals: testCase.decimals)

        // Test encoding produces expected string
        let scientificString = amount.scientific
        #expect(scientificString == testCase.encoded, "Encoding failed for \(testCase.description): expected \(testCase.encoded), got \(scientificString)")

        // Test roundtrip preserves exact value
        let decoded = try Amount(scientificString: scientificString)
        #expect(decoded.underlying == testCase.base, "Roundtrip failed for \(testCase.description): expected \(testCase.base.description), got \(decoded.underlying.description)")
        #expect(decoded.decimals == testCase.decimals, "Decimals mismatch for \(testCase.description)")
    }
}
