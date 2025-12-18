import Foundation
import SwiftNumber

public typealias Price = Value

// Value represents a token value in USD, a fixed point number scaled by 10^8
public struct Value: Codable, Equatable, Hashable, Comparable, AdditiveArithmetic,
    FormattableNumeric, Sendable
{
    public let underlying: Number

    public init(_ underlying: Number) {
        self.underlying = underlying
    }

    public init(underlying: Number) {
        self.underlying = underlying
    }

    public init(double: Double) {
        guard double > 0.0 else {
            self.init(Number.zero)
            return
        }

        let significantFigures = pow(10, Double(10))
        let underlying =
            Number(floor(double * significantFigures)) * Number.pow10(Value.priceFeedDecimalsInt)
            / Number(significantFigures)
        self.init(underlying)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // First, try string form:
        if let str = try? container.decode(String.self) {
            if let value = try? Value.init(scientificString: str) {
                self = value
                return
            }

            guard let big = Number(str, radix: 10) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid Number string: \(str)"
                )
            }
            self.init(big)
            return
        }

        // Next, try a JSON number (UInt / Int):
        if let u = try? container.decode(UInt.self) {
            self.init(Number(u))
            return
        }
        if let i = try? container.decode(Int.self) {
            guard i >= 0 else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Negative integer not allowed for Value"
                )
            }
            self.init(Number(i))
            return
        }
        if let d = try? container.decode(CodableDecimal.self) {
            let value = d.value * .pow10(Self.priceFeedDecimalsInt) / .pow10(d.precision)
            self.init(value)
            return
        }

        // If we get here, it wasn't a string or a (non‐negative) number:
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected string or unsigned integer for Value"
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.scientific)
    }

    public func formatted() -> String {
        formatted(sieved: false)
    }

    public func formattedSieved() -> String {
        formatted(sieved: true)
    }

    private func formatted(sieved: Bool) -> String {
        let decimalRawValue = Decimal(string: underlying.description) ?? 0
        let priceFeedDecimals = pow(10, Value.priceFeedDecimalsInt)
        let decimalValue = decimalRawValue / priceFeedDecimals

        return decimalValue.formatCurrency(sieved: sieved, maxDecimals: 2)
    }

    public func asInputValue() -> String {
        formatted()
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
    }

    public static func * (lhs: Value, rhs: Value) -> Value {
        Value(lhs.underlying * rhs.underlying)
    }

    public static func * (lhs: Value, rhs: Amount) -> Value {
        multiplyAmount(price: lhs, amount: rhs)
    }

    public static func * (lhs: Amount, rhs: Value) -> Value {
        multiplyAmount(price: rhs, amount: lhs)
    }

    public static func * (lhs: Value, rhs: Percentage) -> Value {
        multiplyPercentage(price: lhs, percentage: rhs)
    }

    public static func * (lhs: Percentage, rhs: Value) -> Value {
        multiplyPercentage(price: rhs, percentage: lhs)
    }

    public static func / (lhs: Value, rhs: Value) -> Value {
        Value(lhs.underlying / rhs.underlying)
    }

    public static func / (lhs: Value, rhs: Amount) -> Value {
        Value(lhs.underlying * Number.pow10(rhs.decimals) / rhs.underlying)
    }

    public static func / (lhs: Value, rhs: Percentage) -> Value {
        dividePercentage(price: lhs, percentage: rhs)
    }

    public static func + (lhs: Value, rhs: Value) -> Value {
        Value(lhs.underlying + rhs.underlying)
    }

    public static func - (lhs: Value, rhs: Value) -> Value {
        guard rhs < lhs else {
            return Value.zero
        }

        return Value(lhs.underlying - rhs.underlying)
    }

    public static func += (lhs: inout Value, rhs: Value) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout Value, rhs: Value) {
        lhs = lhs - rhs
    }

    /// Return the Percentage by taking self / value
    public func percentageOf(_ value: Value, factorScale: Int = Percentage.FACTOR_SCALE)
        -> Percentage
    {
        guard !value.isZero else {
            return underlying.isZero ? Percentage(0) : Percentage(double: 100.0)
        }

        return Percentage(
            underlying.asSNumber * SNumber.pow10(factorScale) / value.underlying.asSNumber
        )
    }

    /// Return the number of tokens for Self dollar amount and a given price
    public func toTokenAmount(price: Value, decimals: Int) -> Amount {
        guard !price.isZero else {
            return Amount(0, decimals: decimals)
        }

        return Amount(underlying * Number.pow10(decimals) / price.underlying, decimals: decimals)
    }

    public static func < (lhs: Value, rhs: Value) -> Bool {
        lhs.underlying < rhs.underlying
    }

    @inlinable public static var zero: Self {
        Value(0)
    }

    public static let priceFeedDecimalsInt = 8

    @inlinable public static var priceFeedDecimals: Self {
        Value(Number.pow10(priceFeedDecimalsInt))
    }

    private static func multiplyAmount(price: Value, amount: Amount) -> Value {
        Value(price.underlying * amount.underlying / Number.pow10(amount.decimals))
    }

    private static func multiplyPercentage(price: Value, percentage: Percentage) -> Value {
        guard percentage.underlying > SNumber.zero else {
            return Value(0)
        }

        return Value(
            price.underlying * percentage.underlying.asNumber / Number.pow10(percentage.factorScale)
        )
    }

    private static func dividePercentage(price: Value, percentage: Percentage) -> Value {
        guard percentage.underlying > SNumber.zero else {
            return Value(0)
        }

        return Value(
            price.underlying * Number.pow10(percentage.factorScale) / percentage.underlying.asNumber
        )
    }

    public var isZero: Bool {
        underlying.isZero
    }

    public var asDouble: Double {
        return NSDecimalNumber(decimal: asDecimal / pow(10, Value.priceFeedDecimalsInt))
            .doubleValue
    }

    public var asDecimal: Decimal {
        Decimal(string: underlying.description) ?? 0.0
    }
}
