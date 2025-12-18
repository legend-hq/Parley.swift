import Foundation

extension Decimal {
    public func formatCurrency(sieved: Bool = true, maxDecimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = numDecimalsToShow(maxDecimals: maxDecimals)
        formatter.minimumFractionDigits = numDecimalsToShow(maxDecimals: maxDecimals)
        formatter.decimalSeparator = "."

        // If we aren't sieving the value (formatting with K, M, B), then just format as normal
        if !sieved {
            return formatter.string(from: self as NSDecimalNumber) ?? "0"
        }

        let billion = pow(10, 9)
        let million = pow(10, 6)
        let thousand = pow(10, 3)

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
        let formatter = NumberFormatter()

        formatter.numberStyle = .percent
        if showDecimals {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            formatter.decimalSeparator = "."
        }

        return formatter.string(from: self as NSDecimalNumber) ?? "0"
    }

    public func formatMultiplier(showDecimals: Bool = true, showX: Bool = true) -> String {
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal

        var valueToFormat = self
        if showDecimals {
            // Explicitly round to 2 decimal places for cross-platform consistency
            // (NumberFormatter rounding differs between macOS and Linux)
            var mutableSelf = self
            var rounded = Decimal()
            NSDecimalRound(&rounded, &mutableSelf, 2, .plain)
            valueToFormat = rounded

            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            formatter.decimalSeparator = "."
        }

        var value = formatter.string(from: valueToFormat as NSDecimalNumber) ?? "0"
        if showX { value += "x" }

        return value
    }

    public func formatTokenAmount() -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = numDecimalsToShow(maxDecimals: 4)
        formatter.minimumFractionDigits = numDecimalsToShow(maxDecimals: 4)
        formatter.decimalSeparator = "."

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
