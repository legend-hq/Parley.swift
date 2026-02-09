import Foundation
import Prelude

/// Represents a Legend Loop Position which can be either Long or Short
public struct LoopPosition: Identifiable, Sendable {
    public var id: MarketIdentifier { morphoMarket.id }
    public let side: LoopPositionSide
    public let morphoMarket: MorphoMarket
    /// Backing amounts over time
    private let backingAmounts: [Annotated<PricedAmount<Asset>>]
    public let backingAsset: Asset
    /// Exposure amounts over time
    private let exposureAmounts: [Annotated<PricedAmount<Asset>>]
    public let exposureAsset: Asset
    public let borrows: [Annotated<Amount>]
    public let events: [Event]
    public let activityIds: [Int]
    /// The entry prices for the position (open and increase exposure)
    private let entryPrices: [Annotated<PricedAmount<Asset>>]
    /// The price the position was liquidated at
    private let liquidatedPrice: Value?
    public let openedAt: Date
    public let pending: Bool

    public init(
        side: LoopPositionSide,
        morphoMarket: MorphoMarket,
        backingAmount: Annotated<PricedAmount<Asset>>,
        exposureAmount: Annotated<PricedAmount<Asset>>,
        borrow: Annotated<Amount>,
        activityId: Int,
        openedAt: Date,
        pending: Bool
    ) {
        self.side = side
        self.morphoMarket = morphoMarket
        self.backingAmounts = [backingAmount]
        self.backingAsset = backingAmount.value.asset
        self.exposureAmounts = [exposureAmount]
        self.exposureAsset = exposureAmount.value.asset
        self.borrows = [borrow]
        self.events = [.init(type: .open, date: openedAt)]
        self.activityIds = [activityId]
        self.openedAt = openedAt
        self.pending = pending
        self.entryPrices = [exposureAmount]
        self.liquidatedPrice = nil
    }

    public init(
        _ loopPosition: LoopPosition,
        eventType: Event,
        backingAmount: Annotated<PricedAmount<Asset>>? = nil,
        exposureAmount: Annotated<PricedAmount<Asset>>? = nil,
        borrow: Annotated<Amount>? = nil,
        activityId: Int,
        pending: Bool,
        liquidatedPrice: Value? = nil
    ) {
        self.side = loopPosition.side
        self.morphoMarket = loopPosition.morphoMarket
        self.backingAsset = loopPosition.backingAsset
        self.exposureAsset = loopPosition.exposureAsset

        self.backingAmounts = loopPosition.backingAmounts + (backingAmount.map { [$0] } ?? [])
        self.exposureAmounts = loopPosition.exposureAmounts + (exposureAmount.map { [$0] } ?? [])

        self.borrows = loopPosition.borrows + (borrow.map { [$0] } ?? [])

        self.events = loopPosition.events + [eventType]
        self.openedAt = loopPosition.openedAt
        self.activityIds = loopPosition.activityIds + [activityId]

        // A loop position can re-enter the pending state if there is another loop action in flight
        // for the same position
        self.pending = pending

        if case .increase = eventType.type, let exposureAmount {
            self.entryPrices = loopPosition.entryPrices + [exposureAmount]
        } else {
            self.entryPrices = loopPosition.entryPrices
        }

        self.liquidatedPrice = liquidatedPrice
    }

    /// Test initializer that allows direct creation with all properties
    public init(
        side: LoopPositionSide,
        morphoMarket: MorphoMarket,
        backingAmounts: [Annotated<PricedAmount<Asset>>],
        backingAsset: Asset,
        exposureAmounts: [Annotated<PricedAmount<Asset>>],
        exposureAsset: Asset,
        borrows: [Annotated<Amount>],
        events: [Event],
        activityIds: [Int],
        entryPrices: [Annotated<PricedAmount<Asset>>],
        openedAt: Date,
        pending: Bool
    ) {
        self.side = side
        self.morphoMarket = morphoMarket
        self.backingAmounts = backingAmounts
        self.backingAsset = backingAsset
        self.exposureAmounts = exposureAmounts
        self.exposureAsset = exposureAsset
        self.borrows = borrows
        self.events = events
        self.activityIds = activityIds
        self.entryPrices = entryPrices
        self.openedAt = openedAt
        self.pending = pending
        self.liquidatedPrice = nil
    }

    /// Create all of the users open Loop positions based on the activities
    public static func createLoopPositions(
        activities: [Activity],
        portfolios: [Portfolio]
    ) -> [LoopPosition] {
        var loopPositions: [MarketIdentifier: LoopPosition] = [:]

        let sortedActivities =
            activities
            .sorted(by: \.occurredAt, using: <)
            .filter { $0.isCompleted || $0.isPending }

        for activity in sortedActivities {
            for metadata in activity.activityMetadata {
                let actionContext = metadata.actionContext
                let hasLiquidationEvent = {
                    if actionContext != nil {
                        return false
                    }

                    return metadata.semanticEventContexts.contains {
                        if case .morphoLiquidation = $0.eventType { true } else { false }
                    }
                }

                // Skip over metadatas that don't match
                guard
                    actionContext?.isLoopLong == true || actionContext?.isUnloopLong == true
                        || actionContext?.isAddBackingToken == true
                        || actionContext?.isWithdrawBackingToken == true || hasLiquidationEvent()
                else {
                    continue
                }

                let semanticEvents = metadata.semanticEvents(portfolios: portfolios)

                // Loop Long
                if let loopLongAction = actionContext?.toAction(portfolios: portfolios)?
                    .loopLongAction
                {
                    if let event = semanticEvents.loopLongEvent {
                        guard let executedAt = metadata.executedAt else {
                            Logger.error("Executed at for loop long semantic event not found")
                            continue
                        }

                        let marketId = event.morphoMarket.id
                        if let existingLoopPosition = loopPositions[marketId] {
                            loopPositions[marketId] = LoopPosition(
                                existingLoopPosition,
                                eventType: .init(type: .increase, date: executedAt),
                                backingAmount: .init(event.backingAmount, isIncrease: true),
                                exposureAmount: .init(event.exposureAmount, isIncrease: true),
                                borrow: .init(
                                    event.swapInputAmount.amount - event.backingAmount.amount,
                                    isIncrease: true
                                ),
                                activityId: activity.id,
                                pending: false
                            )
                        } else {
                            loopPositions[marketId] = LoopPosition(
                                side: .long,
                                morphoMarket: event.morphoMarket,
                                backingAmount: .init(event.backingAmount, isIncrease: true),
                                exposureAmount: .init(event.exposureAmount, isIncrease: true),
                                borrow: .init(
                                    event.swapInputAmount.amount - event.backingAmount.amount,
                                    isIncrease: true
                                ),
                                activityId: activity.id,
                                openedAt: executedAt,
                                pending: false
                            )
                        }
                    } else {
                        let marketId = loopLongAction.morphoMarket.id
                        if let existingLoopPosition = loopPositions[marketId] {
                            loopPositions[marketId] = LoopPosition(
                                existingLoopPosition,
                                eventType: .init(type: .increase, date: Date()),
                                backingAmount: .init(
                                    loopLongAction.maxProvidedBackingAmount,
                                    isIncrease: true
                                ),
                                exposureAmount: .init(
                                    loopLongAction.exposureAmount,
                                    isIncrease: true
                                ),
                                borrow: .init(
                                    loopLongAction.maxSwapBackingAmount.amount
                                        - loopLongAction.maxProvidedBackingAmount.amount,
                                    isIncrease: true
                                ),
                                activityId: activity.id,
                                pending: true
                            )
                        } else {
                            loopPositions[marketId] = LoopPosition(
                                side: .long,
                                morphoMarket: loopLongAction.morphoMarket,
                                backingAmount: .init(
                                    loopLongAction.maxProvidedBackingAmount,
                                    isIncrease: true
                                ),
                                exposureAmount: .init(
                                    loopLongAction.exposureAmount,
                                    isIncrease: true
                                ),
                                borrow: .init(
                                    loopLongAction.maxSwapBackingAmount.amount
                                        - loopLongAction.maxProvidedBackingAmount.amount,
                                    isIncrease: true
                                ),
                                activityId: activity.id,
                                openedAt: Date(),
                                pending: true
                            )
                        }
                    }
                }

                // Unloop Long
                if let unloopLongAction = actionContext?.toAction(portfolios: portfolios)?
                    .unloopLongAction
                {
                    let marketId = unloopLongAction.morphoMarket.id
                    guard let existingLoopPosition = loopPositions[marketId] else {
                        Logger.error("Found unloop activity with no preceeding loop. Ignoring")
                        continue
                    }

                    let isMax = unloopLongAction.exposureAmount.amount.underlying.isMaxUint256

                    // A max unloop long closes out the position
                    if isMax {
                        loopPositions.removeValue(forKey: marketId)
                        continue
                    }

                    if let event = semanticEvents.unloopLongEvent {
                        guard let executedAt = metadata.executedAt else {
                            Logger.error("Executed at for unloop long semantic event not found")
                            continue
                        }

                        loopPositions[marketId] = LoopPosition(
                            existingLoopPosition,
                            eventType: .init(type: .close, date: executedAt),
                            backingAmount: .init(event.backingAmountWithdrawn, isIncrease: false),
                            exposureAmount: .init(event.exposureAmount, isIncrease: false),
                            borrow: .init(event.repaid.amount, isIncrease: false),
                            activityId: activity.id,
                            pending: false
                        )
                    } else {
                        loopPositions[marketId] = LoopPosition(
                            existingLoopPosition,
                            eventType: .init(type: .close, date: Date()),
                            backingAmount: .init(
                                unloopLongAction.backingAmountWithdrawn,
                                isIncrease: false
                            ),
                            exposureAmount: .init(
                                unloopLongAction.exposureAmount,
                                isIncrease: false
                            ),
                            borrow: .init(unloopLongAction.repaid, isIncrease: false),
                            activityId: activity.id,
                            pending: true
                        )
                    }
                }

                // Add backing token
                if let addBackingTokenAction = actionContext?.toAction(portfolios: portfolios)?
                    .addBackingTokenAction
                {
                    let marketId = addBackingTokenAction.morphoMarket.id
                    guard let existingLoopPosition = loopPositions[marketId] else {
                        Logger.error(
                            "Found add backing token activity with no preceeding loop. Ignoring"
                        )
                        continue
                    }

                    if let event = semanticEvents.addBackingTokenEvent {
                        guard let executedAt = metadata.executedAt else {
                            Logger.error(
                                "Executed at for add backing token semantic event not found"
                            )
                            continue
                        }

                        loopPositions[marketId] = LoopPosition(
                            existingLoopPosition,
                            eventType: .init(type: .addBackingToken, date: executedAt),
                            backingAmount: .init(event.backingAmount, isIncrease: true),
                            borrow: .init(event.backingAmount.amount, isIncrease: false),
                            activityId: activity.id,
                            pending: false
                        )
                    } else {
                        loopPositions[marketId] = LoopPosition(
                            existingLoopPosition,
                            eventType: .init(type: .addBackingToken, date: Date()),
                            backingAmount: .init(
                                addBackingTokenAction.backingAmount,
                                isIncrease: true
                            ),
                            borrow: .init(
                                addBackingTokenAction.backingAmount.amount,
                                isIncrease: false
                            ),
                            activityId: activity.id,
                            pending: false
                        )
                    }
                }

                // Withdraw backing token
                if let withdrawBackingTokenAction = actionContext?.toAction(portfolios: portfolios)?
                    .withdrawBackingTokenAction
                {
                    let marketId = withdrawBackingTokenAction.morphoMarket.id
                    guard let existingLoopPosition = loopPositions[marketId] else {
                        Logger.error(
                            "Found add backing token activity with no preceeding loop. Ignoring"
                        )
                        continue
                    }

                    if let event = semanticEvents.withdrawBackingTokenEvent {
                        guard let executedAt = metadata.executedAt else {
                            Logger.error(
                                "Executed at for withdraw backing token semantic event not found"
                            )
                            continue
                        }

                        loopPositions[marketId] = LoopPosition(
                            existingLoopPosition,
                            eventType: .init(type: .withdrawBackingToken, date: executedAt),
                            backingAmount: .init(event.backingAmount, isIncrease: false),
                            borrow: .init(event.backingAmount.amount, isIncrease: true),
                            activityId: activity.id,
                            pending: false
                        )
                    } else {
                        loopPositions[marketId] = LoopPosition(
                            existingLoopPosition,
                            eventType: .init(type: .withdrawBackingToken, date: Date()),
                            backingAmount: .init(
                                withdrawBackingTokenAction.backingAmount,
                                isIncrease: false
                            ),
                            borrow: .init(
                                withdrawBackingTokenAction.backingAmount.amount,
                                isIncrease: true
                            ),
                            activityId: activity.id,
                            pending: false
                        )
                    }
                }

                // Liquidation event
                if let liquidationEvent = semanticEvents.morphoLiquidationEvent {
                    let marketId = liquidationEvent.borrowMarket.market.id
                    guard let existingLoopPosition = loopPositions[marketId] else {
                        // No logging here since it's expected that liquidation events may exist
                        // for non-loop positions
                        continue
                    }

                    loopPositions[marketId] = LoopPosition(
                        existingLoopPosition,
                        eventType: .init(type: .liquidation, date: activity.occurredAt),
                        activityId: activity.id,
                        pending: false,
                        liquidatedPrice: liquidationEvent.collateralSeized.price
                    )
                }
            }
        }

        return Array(loopPositions.values).filter { $0.pending || $0.collateralValue > .zero }
    }

    public var backingValue: Value {
        backingAmounts.reduce(Value.zero) {
            if $1.isIncrease {
                $0 + $1.value.amountValue
            } else {
                $0 - $1.value.amountValue
            }
        }
    }

    public var exposureValue: Value {
        exposureAmounts.reduce(Value.zero) {
            if $1.isIncrease {
                $0 + $1.value.amountValue
            } else {
                $0 - $1.value.amountValue
            }
        }
    }

    public var exposureAmount: Amount {
        exposureAmounts.reduce(Amount(.zero, decimals: exposureAsset.decimals)) {
            if $1.isIncrease {
                $0 + $1.value.amount
            } else {
                $0 - $1.value.amount
            }
        }
    }

    /// Total that the user has borrowed excluding interest
    public var totalBorrowed: Amount {
        var total = borrows[0].value
        for i in 1..<borrows.count {
            if borrows[i].isIncrease {
                total += borrows[i].value
            } else {
                total -= borrows[i].value
            }
        }
        return total
    }

    /// The current dollar value of the amount the user receives after closing the position
    public var positionValue: Value {
        collateralValue - morphoMarket.userBorrowValue
    }

    /// The multiplier of the position. This value stays fixed for the lifetime of the LoopPosition
    public var multiplier: Percentage {
        guard let initialBackingValue = backingAmounts.first?.value,
            let initialExposureValue = exposureAmounts.first?.value
        else {
            return .zero
        }

        return initialExposureValue.amountValue.percentageOf(initialBackingValue.amountValue)
    }

    public var utilization: Percentage {
        morphoMarket.userBorrowValue.percentageOf(morphoMarket.liquidationCapacityValue)
    }

    /// Current returns of the LoopPosition
    public var returns: Percentage {
        let numerator =
            (collateralValue.underlying.asSNumber
                - morphoMarket.userBorrowValue.underlying.asSNumber
                - backingValue.underlying.asSNumber) * .pow10(Percentage.FACTOR_SCALE)
        let denominator = backingValue.underlying.asSNumber

        guard denominator > 0 else {
            return .zero
        }

        return Percentage(numerator / denominator)
    }

    public var returnsValue: Value {
        returns.abs() * backingValue
    }

    /// Total amount borrowed over the lifetime of the position (only increases)
    public var totalAmountBorrowed: Amount {
        borrows.reduce(Amount(.zero, decimals: backingAsset.decimals)) { total, borrow in
            if borrow.isIncrease {
                return total + borrow.value
            } else {
                return total
            }
        }
    }

    /// Total amount repaid over the lifetime of the position (only decreases)
    public var totalAmountRepaid: Amount {
        borrows.reduce(Amount(.zero, decimals: backingAsset.decimals)) { total, borrow in
            if !borrow.isIncrease {
                return total + borrow.value
            } else {
                return total
            }
        }
    }

    /// Total interest accrued over the lifetime of the position
    public var interestAccruedValue: Value {
        let totalInterest = morphoMarket.userBorrow + totalAmountRepaid - totalAmountBorrowed
        return totalInterest * morphoMarket.baseAsset.price
    }

    public var collateralValue: Value {
        morphoMarket.collateralAsset.marketBalanceValue
    }

    public var collateralAmount: Amount {
        morphoMarket.collateralAsset.marketBalance
    }

    /// Flag indicating whether the underlying borrow for the loop position has been liquidated
    public var isLiquidated: Bool {
        liquidationEvent != nil
    }

    public var liquidationEvent: Event? {
        events.first { $0.type == .liquidation }
    }

    /// Either the price the position was liquidated at or the price at which the position would be liquidated
    public var liquidationPrice: Value {
        if let liquidatedPrice {
            return liquidatedPrice
        }

        return latestPrice * utilization
    }

    public var latestPrice: Value {
        exposureAsset.price
    }

    /// The average price of the open and all subsequent position increases
    public var averageEntryPrice: Value {
        let totalValue = entryPrices.reduce(Value.zero) { acc, curr in
            acc + curr.value.amountValue
        }
        let totalAmount = entryPrices.reduce(Amount(0, decimals: exposureAsset.decimals)) {
            acc,
            curr in
            acc + curr.value.amount
        }
        return totalValue / totalAmount
    }

    /// Annotates a value with useful information for managing the loop position
    public struct Annotated<T: Sendable>: Sendable {
        public let value: T
        public let isIncrease: Bool

        public init(
            _ value: T,
            isIncrease: Bool
        ) {
            self.value = value
            self.isIncrease = isIncrease
        }
    }

    public struct Event: Sendable {
        public let type: `Type`
        public let date: Date

        public enum `Type`: Sendable {
            case open
            case increase
            case close
            case addBackingToken
            case withdrawBackingToken
            case liquidation
        }
    }
}
