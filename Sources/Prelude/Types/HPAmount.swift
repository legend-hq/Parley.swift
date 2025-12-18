import Foundation
import SwiftNumber

/// High-precision amount for intermediate calculations
///
/// HPAmount prevents precision loss during multi-step arithmetic operations by maintaining
/// additional decimal places beyond the source token's native precision. This is critical in
/// Tradewinds where operations chain together (fee deductions → rate applications → more fees),
/// and standard integer arithmetic would accumulate rounding errors.
///
/// The struct scales input values by 10^5 internally, performs calculations at higher precision,
/// then rounds back to the original precision via `toNumber()`. This eliminates off-by-one errors
/// that occurred when intermediate results were truncated prematurely.
///
/// ## Usage
/// HPAmount is used exclusively within Tradewinds flow calculations:
/// - Fee application (in-fees and out-fees)
/// - Rate/percentage transformations
/// - Capacity backpropagation across multi-hop paths
///
/// Operations maintain HP precision until the final conversion back to `Number`.
///
/// ## Example
/// ```swift
/// let amount = HPAmount(from: Number("1000000"))  // 1M tokens scaled to HP
/// let afterFee = amount - Number("150")           // Subtract 150 at HP precision
/// let afterRate = afterFee * Percentage(0.995)    // Apply 99.5% rate at HP precision
/// let final = afterRate.toNumber()                // Round to nearest integer: 999850
/// ```
public struct HPAmount: Sendable {
    let value: SNumber

    private static let scale = 5
    private static let multiplier = SNumber.pow10(scale)

    public static let zero = HPAmount(scaledValue: SNumber(0))

    public init(from number: Number) {
        self.value = SNumber(number) * Self.multiplier
    }

    public init(from sNumber: SNumber) {
        self.value = sNumber * Self.multiplier
    }

    private init(scaledValue: SNumber) {
        self.value = scaledValue
    }

    public static func / (lhs: HPAmount, rhs: Percentage) -> HPAmount {
        let result = lhs.value / rhs
        return HPAmount(scaledValue: result)
    }

    public static func * (lhs: HPAmount, rhs: Percentage) -> HPAmount {
        let result = lhs.value * rhs
        return HPAmount(scaledValue: result)
    }

    public static func + (lhs: HPAmount, rhs: Number) -> HPAmount {
        let rhsScaled = SNumber(rhs) * Self.multiplier
        return HPAmount(scaledValue: lhs.value + rhsScaled)
    }

    public static func + (lhs: HPAmount, rhs: HPAmount) -> HPAmount {
        return HPAmount(scaledValue: lhs.value + rhs.value)
    }

    public static func - (lhs: HPAmount, rhs: Number) -> HPAmount {
        let rhsScaled = SNumber(rhs) * Self.multiplier
        return HPAmount(scaledValue: lhs.value - rhsScaled)
    }

    public static func - (lhs: HPAmount, rhs: HPAmount) -> HPAmount {
        return HPAmount(scaledValue: lhs.value - rhs.value)
    }

    public static func > (lhs: HPAmount, rhs: Number) -> Bool {
        let rhsScaled = SNumber(rhs) * Self.multiplier
        return lhs.value > rhsScaled
    }

    public static func >= (lhs: HPAmount, rhs: Number) -> Bool {
        let rhsScaled = SNumber(rhs) * Self.multiplier
        return lhs.value >= rhsScaled
    }

    public static func < (lhs: HPAmount, rhs: Number) -> Bool {
        let rhsScaled = SNumber(rhs) * Self.multiplier
        return lhs.value < rhsScaled
    }

    public static func min(_ lhs: HPAmount, _ rhs: Number) -> HPAmount {
        let rhsScaled = SNumber(rhs) * Self.multiplier
        return lhs.value <= rhsScaled ? lhs : HPAmount(scaledValue: rhsScaled)
    }

    public static func min(_ lhs: HPAmount, _ rhs: HPAmount) -> HPAmount {
        return lhs.value <= rhs.value ? lhs : rhs
    }

    public func ceil() -> HPAmount {
        let remainder = value % Self.multiplier
        if remainder > 0 && value > 0 {
            let quotient = (value - remainder) / Self.multiplier
            return HPAmount(scaledValue: (quotient + 1) * Self.multiplier)
        } else if remainder < 0 && value < 0 {
            return HPAmount.zero
        } else {
            return self
        }
    }

    public func floor() -> HPAmount {
        let quotient = value / Self.multiplier
        return quotient >= 0 ? HPAmount(scaledValue: quotient * Self.multiplier) : HPAmount.zero
    }

    public func toNumber() -> Number {
        let rounded = (value + Self.multiplier / 2) / Self.multiplier
        return rounded >= 0 ? Number(rounded.magnitude) : Number(0)
    }
}
