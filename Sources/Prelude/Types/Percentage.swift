import Foundation
import SwiftNumber

public typealias FixedDecimal = Percentage

public struct Percentage: Equatable, Hashable, Comparable, Codable, AdditiveArithmetic, Sendable,
    ExpressibleByFloatLiteral
{
    // Currently, this assumes all percentage values come from Comet which has a
    // scale of 18 for percentages. When we support other DApps, this needs to be considered
    public static let FACTOR_SCALE = 18

    public let underlying: SNumber
    public let factorScale: Int

    enum CodingKeys: String, CodingKey {
        case underlying = "uint_string"
        case factorScale = "precision"
        case type
    }

    public init(_ underlying: SNumber, factorScale: Int = Percentage.FACTOR_SCALE) {
        self.underlying =
            underlying * SNumber.pow10(Percentage.FACTOR_SCALE) / SNumber.pow10(factorScale)
        self.factorScale = Percentage.FACTOR_SCALE
    }

    public init(underlying: SNumber, factorScale: Int = Percentage.FACTOR_SCALE) {
        self.init(underlying, factorScale: factorScale)
    }

    public init(fromNumber underlying: Number, factorScale: Int = Percentage.FACTOR_SCALE) {
        self.underlying =
            underlying.asSNumber * SNumber.pow10(Percentage.FACTOR_SCALE)
            / SNumber.pow10(factorScale)
        self.factorScale = Percentage.FACTOR_SCALE
    }

    public init(fromDouble double: Double, factorScale: Int = Percentage.FACTOR_SCALE) {
        self.init(
            fromNumber: Number(double * pow(10, Double(factorScale))),
            factorScale: factorScale
        )
    }

    public init(floatLiteral value: Double) {
        self.init(fromDouble: value)
    }

    public init(fromBps bps: Number) {
        // Convert basis points to decimal (divide by 10,000)
        // Then scale to internal representation (multiply by 10^18)
        // bps / 10,000 * 10^18 = bps * 10^14
        let underlying = bps.asSNumber * SNumber.pow10(14)
        self.init(underlying)
    }

    public init(fromBps bps: SNumber) {
        // Convert basis points to decimal (divide by 10,000)
        // Then scale to internal representation (multiply by 10^18)
        // bps / 10,000 * 10^18 = bps * 10^14
        let underlying = bps * SNumber.pow10(14)
        self.init(underlying)
    }

    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()

        if let str = try? singleValueContainer.decode(String.self) {
            if let percentage = try? Percentage.init(scientificString: str) {
                self = percentage
                return
            }
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(String.self, forKey: .type)
        guard type == "decimal" else {
            let context = DecodingError.Context(
                codingPath: container.codingPath + [CodingKeys.type],
                debugDescription: "Invalid type: \(type). Expected 'decimal'."
            )
            throw DecodingError.dataCorrupted(context)
        }
        let underlyingStr = try container.decode(String.self, forKey: .underlying)
        let factorScale = try container.decode(Int.self, forKey: .factorScale)
        guard let value = SNumber(underlyingStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .underlying,
                in: container,
                debugDescription: "Invalid Number string: \(underlyingStr)"
            )
        }

        self.init(value, factorScale: factorScale)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.scientific)
    }

    public init(double: Double, factorScale: Int = Percentage.FACTOR_SCALE) {
        let significantFigures = pow(10, Double(10))
        let numerator =
            SNumber(Int(floor(double * significantFigures))) * SNumber.pow10(factorScale)
        let denominator = SNumber(significantFigures)
        self.init(numerator / denominator, factorScale: factorScale)
    }

    public init(fromRatio: SNumber, over: SNumber) {
        self.init(fromRatio * .pow10(Self.FACTOR_SCALE) / over)
    }

    public func formatted(showDecimals: Bool = true) -> String {
        let decimalValue = toDecimal()

        return decimalValue.formatPercentage(showDecimals: showDecimals)
    }

    public func formattedMultiplier(showDecimals: Bool = true, showX: Bool = true) -> String {
        let decimalValue = toDecimal()

        return decimalValue.formatMultiplier(showDecimals: showDecimals, showX: showX)
    }

    public var asDouble: Double {
        NSDecimalNumber(decimal: toDecimal()).doubleValue
    }

    public func toDecimal() -> Decimal {
        let decimalAmount = Decimal(string: underlying.description) ?? 0
        let unitAmount = pow(10, factorScale)

        return decimalAmount / unitAmount
    }

    public func toCgFloat() -> CGFloat {
        let decimalValue: Decimal = toDecimal()
        let doubleValue: Double = NSDecimalNumber(decimal: decimalValue).doubleValue
        return CGFloat(doubleValue)
    }

    public func formatDelta() -> String {
        if underlying >= 0 {
            "↗ \(formatted())"
        } else {
            "↘ \(self.abs().formatted())"
        }
    }

    public func arrow() -> String {
        underlying >= 0 ? "↗" : "↘"
    }

    public static func + (lhs: Percentage, rhs: Percentage) -> Percentage {
        return Percentage(lhs.underlying + rhs.underlying)
    }

    public static func - (lhs: Percentage, rhs: Percentage) -> Percentage {
        return Percentage(lhs.underlying - rhs.underlying)
    }

    public static func * (lhs: Percentage, rhs: Percentage) -> Percentage {
        let product = lhs.underlying * rhs.underlying
        let scale = SNumber.pow10(min(lhs.factorScale, rhs.factorScale))
        return Percentage(product / scale)
    }

    public static func / (lhs: Percentage, rhs: Percentage) -> Percentage {
        return Percentage(lhs.underlying * SNumber.pow10(Self.FACTOR_SCALE) / rhs.underlying)
    }

    public static func < (lhs: Percentage, rhs: Percentage) -> Bool {
        lhs.underlying < rhs.underlying
    }

    public static func == (lhs: Percentage, rhs: Percentage) -> Bool {
        lhs.underlying * SNumber.pow10(rhs.factorScale) == rhs.underlying
            * SNumber.pow10(lhs.factorScale)
    }

    public static func * (lhs: SNumber, rhs: Percentage) -> SNumber {
        let product = lhs * rhs.underlying
        let scale = SNumber.pow10(rhs.factorScale)
        // Round to nearest (not floor) to preserve precision
        return (product + scale / 2) / scale
    }

    public static func / (lhs: SNumber, rhs: Percentage) -> SNumber {
        let numerator = lhs * .pow10(rhs.factorScale)
        // Round to nearest (not floor) to preserve precision
        return (numerator + rhs.underlying / 2) / rhs.underlying
    }

    public static func * (lhs: Number, rhs: Percentage) -> SNumber {
        return SNumber(lhs) * rhs
    }

    public static func / (lhs: Number, rhs: Percentage) -> SNumber {
        return SNumber(lhs) / rhs
    }

    public var isZero: Bool {
        underlying.isZero
    }

    public var isOneHundred: Bool {
        self == Self.oneHundred
    }

    public func abs() -> Percentage {
        underlying < 0 ? Percentage(-underlying) : Percentage(underlying)
    }

    @inlinable public static var zero: Percentage {
        Percentage(0)
    }

    @inlinable public static var oneHundred: Percentage {
        Percentage(SNumber.pow10(Percentage.FACTOR_SCALE))
    }

    @inlinable public static var one: Percentage {
        Percentage(SNumber.pow10(Percentage.FACTOR_SCALE))
    }
}
