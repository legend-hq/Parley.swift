import SwiftNumber

public struct PricedAmount<A: AssetProtocol & Equatable & Hashable>: Equatable, Hashable, Sendable {
    public let amount: Amount
    public let amountValue: Value
    public let asset: A
    public let price: Value

    public init(amount: Amount, amountValue: Value, asset: A) {
        self.asset = asset
        self.amount = amount
        self.amountValue = amountValue
        price = amount.isZero ? Value.zero : amountValue / amount
    }

    public init(_ amount: Number, forAsset asset: A, withPrice price: Number) {
        self.asset = asset
        let amount_ = Amount(amount, decimals: asset.decimals)
        self.amount = amount_
        let price_ = Value(price)
        self.price = price_
        amountValue = amount_ * price_
    }

    public init(_ amount: Number, forAsset asset: A, dollarValue value: Number) {
        let amount_ = Amount(amount, decimals: asset.decimals)
        let amountValue_ = Value(value)
        self.init(amount: amount_, amountValue: amountValue_, asset: asset)
    }

    public init(value: Value, price: Number, asset: A) {
        let amount = value.toTokenAmount(price: .init(price), decimals: asset.decimals)
        self.init(amount: amount, amountValue: value, asset: asset)
    }

    public func formatTokenAmountWithSymbol() -> String {
        "\(amount.formatted()) \(asset.displaySymbol)"
    }
}
