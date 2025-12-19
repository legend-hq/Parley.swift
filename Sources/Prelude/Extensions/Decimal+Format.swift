import Foundation

private enum DecimalFormatters {
    // MARK: - Currency Formatters (2, 4, 8 fraction digits)

    static let currency2: NumberFormatter = makeCurrencyFormatter(fractionDigits: 2)
    static let currency3: NumberFormatter = makeCurrencyFormatter(fractionDigits: 3)
    static let currency4: NumberFormatter = makeCurrencyFormatter(fractionDigits: 4)
    static let currency5: NumberFormatter = makeCurrencyFormatter(fractionDigits: 5)
    static let currency6: NumberFormatter = makeCurrencyFormatter(fractionDigits: 6)
    static let currency7: NumberFormatter = makeCurrencyFormatter(fractionDigits: 7)
    static let currency8: NumberFormatter = makeCurrencyFormatter(fractionDigits: 8)

    private static func makeCurrencyFormatter(fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        return formatter
    }

    static func currency(fractionDigits: Int) -> NumberFormatter {
        switch fractionDigits {
            case ...2: return currency2
            case 3: return currency3
            case 4: return currency4
            case 5: return currency5
            case 6: return currency6
            case 7: return currency7
            case 8: return currency8
            default: return makeCurrencyFormatter(fractionDigits: fractionDigits)
        }
    }

    // MARK: - Decimal Formatters (2, 4, 8 fraction digits)

    static let decimal2: NumberFormatter = makeDecimalFormatter(fractionDigits: 2)
    static let decimal3: NumberFormatter = makeDecimalFormatter(fractionDigits: 3)
    static let decimal4: NumberFormatter = makeDecimalFormatter(fractionDigits: 4)
    static let decimal5: NumberFormatter = makeDecimalFormatter(fractionDigits: 5)
    static let decimal6: NumberFormatter = makeDecimalFormatter(fractionDigits: 6)
    static let decimal7: NumberFormatter = makeDecimalFormatter(fractionDigits: 7)
    static let decimal8: NumberFormatter = makeDecimalFormatter(fractionDigits: 8)

    private static func makeDecimalFormatter(fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        return formatter
    }

    static func decimal(fractionDigits: Int) -> NumberFormatter {
        switch fractionDigits {
            case ...2: return decimal2
            case 3: return decimal3
            case 4: return decimal4
            case 5: return decimal5
            case 6: return decimal6
            case 7: return decimal7
            case 8: return decimal8
            default: return makeDecimalFormatter(fractionDigits: fractionDigits)
        }
    }

    // MARK: - Other Formatters
    static let percentageWithDecimals: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.decimalSeparator = "."
        return formatter
    }()

    static let percentageNoDecimals: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()

    static let multiplierWithDecimals: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.decimalSeparator = "."
        return formatter
    }()

    static let multiplierNoDecimals: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension Decimal {
    public func formatCurrency(sieved: Bool = true, maxDecimals: Int = 2) -> String {
        let decimals = numDecimalsToShow(maxDecimals: maxDecimals)
        let formatter = DecimalFormatters.currency(fractionDigits: decimals)

        if !sieved {
            return formatter.string(from: self as NSDecimalNumber) ?? "0"
        }

        let billion: Decimal = pow(10, 9)
        let million: Decimal = pow(10, 6)
        let thousand: Decimal = pow(10, 3)

        let (sievedDecimalValue, suffix) =
            if self >= billion {
                (self / billion, "B")
            } else if self >= million {
                (self / million, "M")
            } else if self >= thousand {
                (self / thousand, "K")
            } else {
                (self, "")
            }

        return (formatter.string(from: sievedDecimalValue as NSDecimalNumber) ?? "0") + suffix
    }

    public func formatPercentage(showDecimals: Bool = true) -> String {
        let formatter =
            showDecimals
            ? DecimalFormatters.percentageWithDecimals
            : DecimalFormatters.percentageNoDecimals
        return formatter.string(from: self as NSDecimalNumber) ?? "0"
    }

    public func formatMultiplier(showDecimals: Bool = true, showX: Bool = true) -> String {
        let formatter =
            showDecimals
            ? DecimalFormatters.multiplierWithDecimals
            : DecimalFormatters.multiplierNoDecimals

        var valueToFormat = self
        if showDecimals {
            // Explicitly round to 2 decimal places for cross-platform consistency
            // (NumberFormatter rounding differs between macOS and Linux)
            var mutableSelf = self
            var rounded = Decimal()
            NSDecimalRound(&rounded, &mutableSelf, 2, .plain)
            valueToFormat = rounded
        }

        var value = formatter.string(from: valueToFormat as NSDecimalNumber) ?? "0"
        if showX { value += "x" }

        return value
    }

    public func formatTokenAmount() -> String {
        let decimals = numDecimalsToShow(maxDecimals: 4)
        let formatter = DecimalFormatters.decimal(fractionDigits: decimals)
        return formatter.string(from: self as NSDecimalNumber) ?? "0"
    }

    private func numDecimalsToShow(maxDecimals: Int) -> Int {
        let stringRepresentation = description
        let components = stringRepresentation.split(separator: ".")

        guard components.count == 2 else {
            return maxDecimals  // No decimal part, show ".00"
        }

        if components[0] != "0" {
            return maxDecimals  // Has a whole part, eg. show "12.23"
        }

        let decimalPart = components[1]
        var count = 0

        // This loop finds the first non-zero decimal and increments count until it is found
        // If the next digit after the found one is also non zero, include that as well so we
        // always have at least two significant figures of decimals and no trailing zeros
        for (index, char) in decimalPart.enumerated() {
            if char != "0" {
                if index + 1 < decimalPart.count {
                    let nextChar = decimalPart[
                        decimalPart.index(decimalPart.startIndex, offsetBy: index + 1)
                    ]
                    if nextChar != "0" {
                        count += 2
                    } else {
                        count += 1
                    }
                } else {
                    count += 1
                }

                break
            }

            count += 1
        }

        // Never return fewer than maxDecimals
        if count < maxDecimals {
            return maxDecimals
        } else {
            return count
        }
    }
}

extension Double {
    public func formatCurrency(sieved: Bool = true, maxDecimals: Int = 2) -> String {
        Decimal(self).formatCurrency(sieved: sieved, maxDecimals: maxDecimals)
    }

    public func formatPercentage(showDecimals: Bool = true) -> String {
        Decimal(self).formatPercentage(showDecimals: showDecimals)
    }

    public func formatTokenAmount() -> String {
        Decimal(self).formatTokenAmount()
    }
}
