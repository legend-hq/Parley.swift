import Foundation
import SwiftNumber

public typealias FixedNumber = Amount

public struct Amount: Codable, Equatable, Hashable, Comparable, FormattableNumeric, Sendable {
    public let underlying: Number
    public let decimals: Int

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedDecimal = try container.decode(CodableDecimal.self)

        underlying = decodedDecimal.value
        decimals = decodedDecimal.precision
    }

    public func encode(to encoder: Encoder) throws {
        let codableDecimal = CodableDecimal(
            precision: decimals,
            value: underlying
        )
        var container = encoder.singleValueContainer()
        try container.encode(codableDecimal)
    }

    public init(_ underlying: Number, decimals: Int) {
        self.underlying = underlying
        self.decimals = decimals
    }

    public init(underlying: Number, decimals: Int) {
        self.underlying = underlying
        self.decimals = decimals
    }

    public func formatted() -> String {
        let decimalAmount = Decimal(string: underlying.description) ?? 0
        let unitAmount = pow(10, decimals)

        let decimalValue = decimalAmount / unitAmount

        return decimalValue.formatTokenAmount()
    }

    public func asInputValue() -> String {
        formatted()
            .replacingOccurrences(of: ",", with: "")
    }

    public static func * (lhs: Percentage, rhs: Amount) -> Amount {
        multiplyPercentage(amount: rhs, percentage: lhs)
    }

    public static func * (lhs: Amount, rhs: Percentage) -> Amount {
        multiplyPercentage(amount: lhs, percentage: rhs)
    }

    public static func / (lhs: Amount, rhs: Percentage) -> Amount {
        multiplyPercentage(amount: lhs, percentage: Percentage.oneHundred / rhs)
    }

    public static func + (lhs: Amount, rhs: Amount) -> Amount {
        Amount(
            lhs.underlying + rhs.scaledTo(decimals: lhs.decimals).underlying,
            decimals: lhs.decimals
        )
    }

    public static func + (lhs: Amount, rhs: Number) -> Amount {
        return Amount(lhs.underlying + rhs, decimals: lhs.decimals)
    }

    public static func += (lhs: inout Amount, rhs: Amount) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout Amount, rhs: Amount) {
        lhs = lhs - rhs
    }

    public static func - (lhs: Amount, rhs: Amount) -> Amount {
        guard lhs > rhs else {
            return Amount(0, decimals: lhs.decimals)
        }

        return Amount(
            lhs.underlying - rhs.scaledTo(decimals: lhs.decimals).underlying,
            decimals: lhs.decimals
        )
    }

    public static func - (lhs: Amount, rhs: Number) -> Amount {
        guard lhs.underlying > rhs else {
            return Amount(0, decimals: lhs.decimals)
        }

        return Amount(lhs.underlying - rhs, decimals: lhs.decimals)
    }

    public static func < (lhs: Amount, rhs: Amount) -> Bool {
        lhs.underlying < rhs.scaledTo(decimals: lhs.decimals).underlying
    }

    public static func <= (lhs: Amount, rhs: Amount) -> Bool {
        lhs.underlying <= rhs.scaledTo(decimals: lhs.decimals).underlying
    }

    public func percentageOf(_ amount: Amount) -> Percentage {
        guard !amount.isZero else {
            return underlying.isZero ? .zero : .oneHundred
        }

        return Percentage(
            SNumber(
                underlying * .pow10(Percentage.FACTOR_SCALE)
                    / amount.scaledTo(decimals: decimals).underlying
            )
        )
    }

    private static func multiplyPercentage(amount: Amount, percentage: Percentage) -> Amount {
        guard percentage.underlying > SNumber.zero else {
            return Amount(0, decimals: amount.decimals)
        }

        return Amount(
            amount.underlying * percentage.underlying.asNumber
                / Number.pow10(percentage.factorScale),
            decimals: amount.decimals
        )
    }

    public func scaledTo(decimals newDecimals: Int) -> Amount {
        Amount(underlying * .pow10(newDecimals) / .pow10(decimals), decimals: newDecimals)
    }

    public var isZero: Bool {
        underlying.isZero
    }

    public var asDouble: Double {
        let underlyingDecimal = Decimal(string: underlying.description) ?? 0.0
        return NSDecimalNumber(decimal: underlyingDecimal / pow(10, decimals)).doubleValue
    }
}

extension Array where Element == Amount {
    public func sum(decimals: Int) -> Amount {
        reduce(Amount(0, decimals: decimals)) { acc, curr in
            acc + curr
        }
    }
}

extension Amount {
    // MARK: – Convenience initialisers ----------------------------------------

    /// Build from `"5.2e6"`  **or**  `"50000//6"`.
    public init<S: StringProtocol>(_ text: S) throws {
        let (underlying, decimals) = try Amount.parse(String(text))
        self.init(underlying, decimals: decimals)
    }

    // MARK: – Internal parser --------------------------------------------------

    /// Returns `(underlying, decimals)` or throws.
    private static func parse(_ raw: String) throws -> (Number, Int) {
        // 1. slash-notation  e.g. "50000//6"
        if let idx = raw.range(of: "//") {
            let lhs = raw[..<idx.lowerBound]
            let rhs = raw[idx.upperBound...]

            guard
                let decimals = Int(rhs),
                let base = Number(String(lhs))
            else {
                throw AmountError.cannotParse(raw)
            }
            return (base, decimals)
        }

        // 2. scientific-notation  e.g. "5.2e6"
        if raw.lowercased().contains("e") {
            return try Amount.parseScientific(raw)
        }

        // 3. fall-through
        throw AmountError.cannotParse(raw)
    }

    /// Handles the `"5.2e6"` case exactly as before.
    private static func parseScientific(_ raw: String)
        throws -> (Number, Int)
    {
        let lower = raw.lowercased()
        guard let eRange = lower.range(of: "e") else {
            throw AmountError.cannotParse(raw)
        }

        let mantissaPart = lower[..<eRange.lowerBound]
        let exponentPart = lower[eRange.upperBound...]

        guard let decimals = Int(exponentPart) else {
            throw AmountError.cannotParse(raw)
        }

        let parts = mantissaPart.split(separator: ".", omittingEmptySubsequences: false)
        let intDigits = parts[0]
        let fracDigits = parts.count == 2 ? parts[1] : Substring()

        guard decimals >= fracDigits.count,
            let base = Number(String(intDigits + fracDigits))
        else {
            throw AmountError.cannotParse(raw)
        }

        let power = decimals - fracDigits.count
        let underlying = base * Number(10).power(power)
        return (underlying, decimals)
    }
}

// ─────────────────────────────────────────────────────────────

// MARK: - Optional literal conformance

// ─────────────────────────────────────────────────────────────
//
//  let wei: Amount = "1e18"
//  let fee: Amount = "2.5e5"
//
extension Amount: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        // A literal that cannot be parsed is a programmer error,
        // so a preconditionFailure is fine here.
        do { try self.init(value) } catch {
            preconditionFailure("Invalid Amount literal: \"\(value)\" — \(error)")
        }
    }
}

// ─────────────────────────────────────────────────────────────

// MARK: - Helper

// ─────────────────────────────────────────────────────────────
private enum AmountError: Error {
    case cannotParse(String)
}
