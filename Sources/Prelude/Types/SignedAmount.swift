import Foundation
import SwiftNumber

public struct SignedAmount: Codable, Equatable, Hashable, Sendable {
    public let underlying: SNumber
    public let decimals: Int

    public init(_ underlying: SNumber, decimals: Int) {
        self.underlying = underlying
        self.decimals = decimals
    }

    public init(underlying: SNumber, decimals: Int) {
        self.underlying = underlying
        self.decimals = decimals
    }

    /// Parse from scientific notation: `"-10e18"`, `"+5.2e6"`, `"0e18"`
    public init<S: StringProtocol>(_ text: S) throws {
        let raw = String(text)
        let (underlying, decimals) = try SignedAmount.parseScientific(raw)
        self.init(underlying, decimals: decimals)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        try self.init(str)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.scientific)
    }

    // MARK: - Properties

    public var isNegative: Bool {
        underlying < SNumber.zero
    }

    public var isZero: Bool {
        underlying.isZero
    }

    /// The unsigned absolute value as an `Amount`.
    public var magnitude: Amount {
        let abs = underlying < SNumber.zero ? -underlying : underlying
        return Amount(abs.asNumber, decimals: decimals)
    }

    public func scaledTo(decimals newDecimals: Int) -> SignedAmount {
        SignedAmount(
            underlying * SNumber.pow10(newDecimals) / SNumber.pow10(decimals),
            decimals: newDecimals
        )
    }

    // MARK: - Parsing

    private static func parseScientific(_ raw: String) throws -> (SNumber, Int) {
        let lower = raw.lowercased()

        guard lower.contains("e") else {
            throw SignedAmountError.cannotParse(raw)
        }

        // Strip sign
        let negative = lower.hasPrefix("-")
        let positive = lower.hasPrefix("+")
        let unsigned: String
        if negative || positive {
            unsigned = String(lower.dropFirst())
        } else {
            unsigned = lower
        }

        guard let eRange = unsigned.range(of: "e") else {
            throw SignedAmountError.cannotParse(raw)
        }

        let mantissaPart = unsigned[..<eRange.lowerBound]
        let exponentPart = unsigned[eRange.upperBound...]

        guard let decimals = Int(exponentPart) else {
            throw SignedAmountError.cannotParse(raw)
        }

        let parts = mantissaPart.split(separator: ".", omittingEmptySubsequences: false)
        let intDigits = parts[0]
        let fracDigits = parts.count == 2 ? parts[1] : Substring()

        guard decimals >= fracDigits.count,
            let base = Number(String(intDigits + fracDigits))
        else {
            throw SignedAmountError.cannotParse(raw)
        }

        let power = decimals - fracDigits.count
        let coefficient = base * Number(10).power(power)
        let result = negative ? -SNumber(coefficient) : SNumber(coefficient)
        return (result, decimals)
    }
}

// MARK: - Operators

extension Amount {
    /// `Amount + SignedAmount` — if delta is negative, delegates to `Amount - Amount`
    /// (which clamps to zero); if positive, delegates to `Amount + Amount`.
    public static func + (lhs: Amount, rhs: SignedAmount) -> Amount {
        if rhs.isNegative {
            return lhs - rhs.magnitude.scaledTo(decimals: lhs.decimals)
        } else {
            return lhs + Amount(rhs.underlying.asNumber, decimals: rhs.decimals)
        }
    }
}

extension SignedAmount {
    public static func + (lhs: SignedAmount, rhs: SignedAmount) -> SignedAmount {
        SignedAmount(
            lhs.underlying + rhs.scaledTo(decimals: lhs.decimals).underlying,
            decimals: lhs.decimals
        )
    }

    public static prefix func - (value: SignedAmount) -> SignedAmount {
        SignedAmount(-value.underlying, decimals: value.decimals)
    }
}

// MARK: - ExpressibleByStringLiteral

extension SignedAmount: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        do { try self.init(value) } catch {
            preconditionFailure("Invalid SignedAmount literal: \"\(value)\" — \(error)")
        }
    }
}

// MARK: - Helper

private enum SignedAmountError: Error {
    case cannotParse(String)
}
