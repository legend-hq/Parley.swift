import SwiftNumber
import Testing
import Foundation

@testable import Prelude

// MARK: - Parsing

@Test("SignedAmount parsing - negative scientific notation")
func signedAmountParsingNegative() throws {
    let sa: SignedAmount = try SignedAmount("-10e18")
    #expect(sa.underlying == SNumber("-10000000000000000000"))
    #expect(sa.decimals == 18)
    #expect(sa.isNegative == true)
}

@Test("SignedAmount parsing - positive with explicit sign")
func signedAmountParsingPositiveExplicit() throws {
    let sa = try SignedAmount("+5.2e6")
    #expect(sa.underlying == SNumber("5200000"))
    #expect(sa.decimals == 6)
    #expect(sa.isNegative == false)
}

@Test("SignedAmount parsing - zero")
func signedAmountParsingZero() throws {
    let sa = try SignedAmount("0e18")
    #expect(sa.underlying == SNumber.zero)
    #expect(sa.decimals == 18)
    #expect(sa.isZero == true)
}

@Test("SignedAmount parsing - negative with decimal coefficient")
func signedAmountParsingNegativeDecimal() throws {
    let sa = try SignedAmount("-0.5e6")
    #expect(sa.underlying == SNumber("-500000"))
    #expect(sa.decimals == 6)
}

@Test("SignedAmount parsing - positive without explicit sign")
func signedAmountParsingPositiveImplicit() throws {
    let sa = try SignedAmount("100e18")
    #expect(sa.underlying == SNumber("100000000000000000000"))
    #expect(sa.decimals == 18)
    #expect(sa.isNegative == false)
}

// MARK: - Scientific encoding roundtrip

@Test("SignedAmount scientific encoding roundtrip")
func signedAmountScientificRoundtrip() throws {
    struct TestCase {
        let underlying: SNumber
        let decimals: Int
        let description: String
    }

    let testCases: [TestCase] = [
        TestCase(underlying: SNumber("-10000000000000000000"), decimals: 18, description: "Negative integer"),
        TestCase(underlying: SNumber("5200000"), decimals: 6, description: "Positive with fractional coefficient"),
        TestCase(underlying: SNumber.zero, decimals: 18, description: "Zero"),
        TestCase(underlying: SNumber("-105531317983966714"), decimals: 18, description: "Negative with remainder"),
        TestCase(underlying: SNumber("123456789012345678"), decimals: 18, description: "18 significant digits"),
    ]

    for tc in testCases {
        let sa = SignedAmount(tc.underlying, decimals: tc.decimals)
        let encoded = sa.scientific
        let decoded = try SignedAmount(scientificString: encoded)
        #expect(decoded.underlying == tc.underlying, "Roundtrip failed for \(tc.description): expected \(tc.underlying), got \(decoded.underlying)")
        #expect(decoded.decimals == tc.decimals, "Decimals mismatch for \(tc.description)")
    }
}

// MARK: - Arithmetic

@Test("Amount + SignedAmount (negative delta)")
func amountPlusNegativeSignedAmount() throws {
    let balance: Amount = "100e18"
    let delta: SignedAmount = "-10e18"
    let result = balance + delta
    #expect(result == Amount("90e18"))
}

@Test("Amount + SignedAmount (clamp to zero)")
func amountPlusSignedAmountClamp() throws {
    let balance: Amount = "5e18"
    let delta: SignedAmount = "-10e18"
    let result = balance + delta
    #expect(result == Amount(0, decimals: 18))
}

@Test("Amount + SignedAmount (positive delta)")
func amountPlusPositiveSignedAmount() throws {
    let balance: Amount = "100e18"
    let delta: SignedAmount = "+10e18"
    let result = balance + delta
    #expect(result == Amount("110e18"))
}

@Test("SignedAmount + SignedAmount (both negative)")
func signedAmountPlusBothNegative() throws {
    let a: SignedAmount = "-10e18"
    let b: SignedAmount = "-5e18"
    let result = a + b
    #expect(result == SignedAmount(SNumber("-15000000000000000000"), decimals: 18))
}

@Test("SignedAmount + SignedAmount (cancel out)")
func signedAmountPlusCancelOut() throws {
    let a: SignedAmount = "-10e18"
    let b: SignedAmount = "+10e18"
    let result = a + b
    #expect(result.isZero)
}

@Test("SignedAmount negation")
func signedAmountNegation() throws {
    let a: SignedAmount = "-10e18"
    let negated = -a
    #expect(negated.underlying == SNumber("10000000000000000000"))
    #expect(negated.isNegative == false)
}

// MARK: - Codable / JSON roundtrip

@Test("SignedAmount JSON roundtrip with @Scientific")
func signedAmountJSONRoundtrip() throws {
    struct TestWrapper: Codable, Equatable {
        @Scientific var delta: SignedAmount

        init(delta: SignedAmount) {
            self.delta = delta
        }
    }

    let delta = SignedAmount(SNumber("-105531317983966714"), decimals: 18)
    let wrapper = TestWrapper(delta: delta)

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(wrapper)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TestWrapper.self, from: jsonData)

    #expect(decoded == wrapper)
    #expect(decoded.delta.underlying == delta.underlying)
    #expect(decoded.delta.decimals == delta.decimals)
}

@Test("SignedAmount JSON roundtrip - negative value preserves sign")
func signedAmountJSONPreservesSign() throws {
    let sa: SignedAmount = "-10e18"

    let encoder = JSONEncoder()
    let data = try encoder.encode(sa)
    let jsonString = String(data: data, encoding: .utf8)!

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(SignedAmount.self, from: data)

    #expect(decoded == sa)
    #expect(jsonString.contains("-"))
}

// MARK: - String literal

@Test("SignedAmount string literal")
func signedAmountStringLiteral() throws {
    let x: SignedAmount = "-10e18"
    #expect(x.isNegative)
    #expect(x.decimals == 18)
    #expect(x.underlying == SNumber("-10000000000000000000"))
}

// MARK: - Magnitude

@Test("SignedAmount magnitude")
func signedAmountMagnitude() throws {
    let sa: SignedAmount = "-10e18"
    let mag = sa.magnitude
    #expect(mag == Amount("10e18"))
}
