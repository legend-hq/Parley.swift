public struct ProfitAndLossSummary: Equatable, Hashable, Sendable {
    public let profit: Value
    public let loss: Value

    public init(profit: Value, loss: Value) {
        self.profit = profit
        self.loss = loss
    }
}

public struct AverageCostPosition: Equatable, Hashable, Sendable {
    public let quantity: Amount
    public let averageCost: Value

    public init(quantity: Amount, averageCost: Value) {
        self.quantity = quantity
        self.averageCost = averageCost
    }
}
