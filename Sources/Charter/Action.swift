import Eth
import Foundation
import Prelude
import SwiftNumber

/// An ``Action`` is similar to an ``ActionContext`` but hydrated with data from ``Portfolio``s. This allows us to have more complex data, such as asset information.
public enum Action: Equatable, Identifiable, ActionProtocol, Sendable {
    case transfer(TransferAction)
    case bridge(BridgeAction)
    case bridgeMint(BridgeMintAction)
    case supply(SupplyAction)
    case borrow(BorrowAction)
    case repay(RepayAction)
    case swap(SwapAction)
    case recurringSwap(RecurringSwapAction)
    case claimRewards(ClaimRewardsAction)
    case drip(DripTokensAction)
    case withdraw(WithdrawAction)
    case withdrawBorrow(WithdrawAndBorrowAction)
    case quotePay(QuotePayAction)
    case loopLong(LoopLongAction)
    case unloopLong(UnloopLongAction)
    case addBackingToken(AddBackingTokenAction)
    case withdrawBackingToken(WithdrawBackingTokenAction)
    case multiAction([Action])

    public var id: String {
        switch self {
            case .bridge(let action):
                "bridge:\(action.id)"
            case .bridgeMint(let action):
                "bridgeMint:\(action.id)"
            case .transfer(let action):
                "transfer:\(action.id)"
            case .supply(let action):
                "supply:\(action.id)"
            case .borrow(let action):
                "borrow:\(action.id)"
            case .repay(let action):
                "repay:\(action.id)"
            case .swap(let action):
                "swap:\(action.id)"
            case .recurringSwap(let action):
                "recurringSwap:\(action.id)"
            case .claimRewards(let action):
                "claimRewards:\(action.id)"
            case .drip(let action):
                "drip:\(action.id)"
            case .withdraw(let action):
                "withdraw:\(action.id)"
            case .withdrawBorrow(let action):
                "withdrawBorrow:\(action.id)"
            case .quotePay(let action):
                "quotePay:\(action.id)"
            case .loopLong(let action):
                "loopLong:\(action.id)"
            case .unloopLong(let action):
                "unloopLong:\(action.id)"
            case .addBackingToken(let action):
                "addBackingToken:\(action.id)"
            case .withdrawBackingToken(let action):
                "withdrawBackingToken:\(action.id)"
            case .multiAction(let actions):
                "multi:\(actions.map(\.id).joined(separator: ","))"
        }
    }

    public var isBridge: Bool {
        switch self {
            case .bridge: true
            default: false
        }
    }

    public var isMultiAction: Bool {
        switch self {
            case .multiAction: true
            default: false
        }
    }

    public var isQuotePay: Bool {
        switch self {
            case .quotePay: true
            default: false
        }
    }

    public var isSupply: Bool {
        switch self {
            case .supply: true
            default: false
        }
    }

    public var isWithdraw: Bool {
        switch self {
            case .withdraw: true
            default: false
        }
    }

    public var multis: [ActionProtocol] {
        switch self {
            case .multiAction(let actions): actions
            default: []
        }
    }

    public func swapAction(buyToken: EthAddress, sellToken: EthAddress) -> SwapAction? {
        switch self {
            case .swap(let action):
                if action.buyAmount.asset.address == buyToken
                    && action.sellAmount.asset.address == sellToken
                {
                    return action
                }

                return nil
            case .multiAction(let actions):
                return
                    actions
                    .compactMap { $0.swapAction(buyToken: buyToken, sellToken: sellToken) }
                    .first
            default: return nil
        }
    }

    /// Get the loop long action if self contains a loop long action.
    /// Note that this only returns the first loop long action if it is a multi action
    public var loopLongAction: LoopLongAction? {
        switch self {
            case .loopLong(let action):
                return action
            case .multiAction(let actions):
                return
                    actions
                    .compactMap { $0.loopLongAction }
                    .first
            default: return nil
        }
    }

    /// Get the unloop long action if self contains a loop long action.
    /// Note that this only returns the first loop long action if it is a multi action
    public var unloopLongAction: UnloopLongAction? {
        switch self {
            case .unloopLong(let action):
                return action
            case .multiAction(let actions):
                return
                    actions
                    .compactMap { $0.unloopLongAction }
                    .first
            default: return nil
        }
    }

    public var addBackingTokenAction: AddBackingTokenAction? {
        switch self {
            case .addBackingToken(let action):
                return action
            case .multiAction(let actions):
                return
                    actions
                    .compactMap { $0.addBackingTokenAction }
                    .first
            default: return nil
        }
    }

    public var withdrawBackingTokenAction: WithdrawBackingTokenAction? {
        switch self {
            case .withdrawBackingToken(let action):
                return action
            case .multiAction(let actions):
                return
                    actions
                    .compactMap { $0.withdrawBackingTokenAction }
                    .first
            default: return nil
        }
    }
}

/// A ``TransferAction`` is a wrapped version of ``Actions.TransferActionContext``
public struct TransferAction: Equatable, Identifiable, Sendable {
    public let transferAmount: PricedAmount<Asset>
    public let recipient: ChainAddress

    public var id: String {
        "\(transferAmount.asset.chain.chainId):\(transferAmount.asset.address.hex):\(recipient.displayString):\(transferAmount.amount.underlying)"
    }

    public init(transferAmount: PricedAmount<Asset>, recipient: ChainAddress) {
        self.transferAmount = transferAmount
        self.recipient = recipient
    }
}

/// A ``BridgeAction`` is a wrapped version of ``Actions.BridgeActionContext``
public struct BridgeAction: Equatable, Identifiable, Sendable {
    public let bridgeAmount: PricedAmount<Asset>
    public let bridgeFee: PricedAmount<Asset>
    public let recipient: ChainAddress
    public let bridgeType: DApp

    public var id: String {
        "\(bridgeAmount.asset.chain.chainId):\(bridgeAmount.asset.address.hex):\(recipient.displayString):\(bridgeAmount.amount.underlying)"
    }

    public init(
        bridgeAmount: PricedAmount<Asset>,
        bridgeFee: PricedAmount<Asset>,
        recipient: ChainAddress,
        bridgeType: DApp
    ) {
        self.bridgeAmount = bridgeAmount
        self.bridgeFee = bridgeFee
        self.recipient = recipient
        self.bridgeType = bridgeType
    }
}

/// A ``BridgeMintAction`` is a wrapped version of ``Actions.BridgeMintActionContext``
/// Represents the mint/receiving side of a cross-chain bridge operation
public struct BridgeMintAction: Equatable, Identifiable, Sendable {
    public let mintAmount: PricedAmount<Asset>
    public let feeAmount: PricedAmount<Asset>
    public let sender: ChainAddress
    public let bridgeType: DApp

    public var id: String {
        "\(mintAmount.asset.chain.chainId):\(mintAmount.asset.address.hex):\(sender.displayString):\(mintAmount.amount.underlying):\(bridgeType.displayName)"
    }

    public init(
        mintAmount: PricedAmount<Asset>,
        feeAmount: PricedAmount<Asset>,
        sender: ChainAddress,
        bridgeType: DApp
    ) {
        self.mintAmount = mintAmount
        self.feeAmount = feeAmount
        self.sender = sender
        self.bridgeType = bridgeType
    }
}

/// A ``SupplyAction`` is a wrapped version of ``Actions.CometSupplyActionContext`` and ``Actions.MorphoVaultSupplyActionContext``
public struct SupplyAction: Equatable, Identifiable, Sendable {
    public let earnMarket: EarnMarket
    public let supplyAmount: PricedAmount<BaseAsset>

    public var id: String {
        "\(supplyAmount.asset.chain.chainId):\(supplyAmount.asset.address.hex):\(earnMarket.id.description):\(supplyAmount.amount.underlying)"
    }

    public var supplyValue: Value {
        earnMarket.baseAsset.marketBalanceValue + supplyAmount.amountValue
    }

    public init(earnMarket: EarnMarket, supplyAmount: PricedAmount<BaseAsset>) {
        self.earnMarket = earnMarket
        self.supplyAmount = supplyAmount
    }
}

public protocol BorrowActionProtocol {
    var borrowMarket: BorrowMarket { get }
    var borrowValue: Value { get }
    var collateralValue: Value { get }
    var borrowCapacityValue: Value { get }
    var liquidationCapacityValue: Value { get }
    var liquidationPoint: Value { get }
}

extension BorrowActionProtocol {
    public var liquidationPoint: Value {
        return liquidationCapacityValue.isZero
            ? Value(0)
            : collateralValue
                - (((liquidationCapacityValue - borrowValue) * collateralValue)
                    / liquidationCapacityValue)
    }
}

/// A ``BorrowAction`` is a wrapped version of ``Actions.BorrowActionContext``
public struct BorrowAction: BorrowActionProtocol, Equatable, Identifiable, Sendable {
    public let borrowMarket: BorrowMarket
    public let borrowAmount: PricedAmount<BaseAsset>
    public let collateralAmounts: [PricedAmount<CollateralAsset>]

    public init(
        borrowMarket: BorrowMarket,
        borrowAmount: PricedAmount<BaseAsset>,
        collateralAmounts: [PricedAmount<CollateralAsset>]
    ) {
        self.borrowMarket = borrowMarket
        self.borrowAmount = borrowAmount
        self.collateralAmounts = collateralAmounts
    }

    public var id: String {
        "\(borrowAmount.asset.chain.chainId):\(borrowAmount.asset.address.hex):\(borrowMarket.id.description):\(borrowAmount.amount.underlying)"
    }

    public var borrowValue: Value {
        borrowMarket.userBorrowValue + borrowAmount.amountValue
    }

    public var collateralValue: Value {
        let currentCollateralValue =
            borrowMarket
            .collateralAssets.map { $0.marketBalanceValue }
            .sum()
        let additionalCollateralValue = collateralAmounts.map { $0.amountValue }.sum()

        return currentCollateralValue + additionalCollateralValue
    }

    public var borrowCapacityValue: Value {
        let additionalBorrowCapacityValue =
            collateralAmounts
            .map { $0.amountValue * $0.asset.borrowCollateralFactor }
            .sum()

        return borrowMarket.borrowCapacityValue + additionalBorrowCapacityValue
    }

    public var liquidationCapacityValue: Value {
        let addtionalLiquidationCapacityValue =
            collateralAmounts
            .map { $0.amountValue * $0.asset.liquidateCollateralFactor }
            .sum()

        return borrowMarket.liquidationCapacityValue + addtionalLiquidationCapacityValue
    }
}

/// A ``RepayAction`` is a wrapped version of ``Actions.RepayActionContext``
public struct RepayAction: BorrowActionProtocol, Equatable, Identifiable, Sendable {
    public let borrowMarket: BorrowMarket
    public let repayAmount: PricedAmount<BaseAsset>
    public let collateralAmounts: [PricedAmount<CollateralAsset>]

    public init(
        borrowMarket: BorrowMarket,
        repayAmount: PricedAmount<BaseAsset>,
        collateralAmounts: [PricedAmount<CollateralAsset>]
    ) {
        self.borrowMarket = borrowMarket
        self.repayAmount = repayAmount
        self.collateralAmounts = collateralAmounts
    }

    public var id: String {
        "\(repayAmount.asset.chain.chainId):\(repayAmount.asset.address.hex):\(borrowMarket.id.description):\(repayAmount.amount.underlying)"
    }

    public var dApp: DApp {
        borrowMarket.dApp
    }

    public var borrowValue: Value {
        return max(borrowMarket.userBorrowValue - repayAmount.amountValue, Value.zero)
    }

    public var collateralValue: Value {
        let currentCollateralValue = borrowMarket.collateralAssets.map { $0.marketBalanceValue }
            .sum()
        let additionalCollateralValue = collateralAmounts.map { $0.amountValue }.sum()

        return max(currentCollateralValue - additionalCollateralValue, Value.zero)
    }

    public var borrowCapacityValue: Value {
        let removedBorrowCapacityValue =
            collateralAmounts
            .map { $0.amountValue * $0.asset.borrowCollateralFactor }
            .sum()

        return max(borrowMarket.borrowCapacityValue - removedBorrowCapacityValue, Value.zero)
    }

    public var liquidationCapacityValue: Value {
        let removedLiquidationCapacityValue =
            collateralAmounts
            .map { $0.amountValue * $0.asset.liquidateCollateralFactor }
            .sum()

        return max(
            borrowMarket.liquidationCapacityValue - removedLiquidationCapacityValue,
            Value.zero
        )
    }

    public var displayRepayAmount: Amount {
        if repayAmount.amount.underlying.isMaxUint256 {
            borrowMarket.userBorrow
        } else {
            repayAmount.amount
        }
    }

    public var displayRepayAmountValue: Value {
        if repayAmount.amount.underlying.isMaxUint256 {
            borrowMarket.userBorrowValue
        } else {
            repayAmount.amountValue
        }
    }
}

/// A ``SwapAction`` is a wrapped version of ``Actions.SwapActionContext``
public struct SwapAction: Equatable, Identifiable, Sendable {
    public let buyAmount: PricedAmount<Asset>
    public let sellAmount: PricedAmount<Asset>
    public let feeAmounts: [PricedAmount<Asset>]
    public let feeDescriptions: [String]
    public let isBuy: Bool
    public let swapVenue: DApp

    public var id: String {
        "\(buyAmount.asset.chain.chainId):\(buyAmount.asset.address.hex):\(buyAmount.amount.underlying):\(sellAmount.asset.chain.chainId):\(sellAmount.asset.address.hex):\(sellAmount.amount.underlying)"
    }

    public init(
        buyAmount: PricedAmount<Asset>,
        sellAmount: PricedAmount<Asset>,
        feeAmounts: [PricedAmount<Asset>],
        feeDescriptions: [String],
        isBuy: Bool,
        swapVenue: DApp = .ZeroEx
    ) {
        self.buyAmount = buyAmount
        self.sellAmount = sellAmount
        self.feeAmounts = feeAmounts
        self.feeDescriptions = feeDescriptions
        self.isBuy = isBuy
        self.swapVenue = swapVenue
    }

    public var fees: [(String, PricedAmount<Asset>)] {
        return zip(feeDescriptions, feeAmounts).filter { !$1.amount.isZero }
    }
}

/// A ``RecurringSwapAction`` is a wrapped version of ``Actions.RecurringSwapActionContext``
public struct RecurringSwapAction: Equatable, Identifiable, Sendable {
    public let buyAmount: PricedAmount<Asset>
    public let sellAmount: PricedAmount<Asset>
    public let feeAmount: PricedAmount<Asset>?
    public let frequency: Frequency
    public let isExactOut: Bool
    public let isBuy: Bool

    public var id: String {
        "\(buyAmount.asset.chain.chainId):\(buyAmount.asset.address.hex):\(buyAmount.amount.underlying):\(sellAmount.asset.chain.chainId):\(sellAmount.asset.address.hex):\(sellAmount.amount.underlying):\(frequency.id):\(isExactOut)"
    }

    public init(
        buyAmount: PricedAmount<Asset>,
        sellAmount: PricedAmount<Asset>,
        feeAmount: PricedAmount<Asset>?,
        frequency: Frequency,
        isExactOut: Bool,
        isBuy: Bool
    ) {
        self.buyAmount = buyAmount
        self.sellAmount = sellAmount
        self.feeAmount = feeAmount
        self.frequency = frequency
        self.isExactOut = isExactOut
        self.isBuy = isBuy
    }
}

/// A ``ClaimRewardsAction`` is a wrapped version of ``Actions.CometClaimRewardsActionContext | Actions.MorphoClaimRewardsActionContext``
public struct ClaimRewardsAction: Equatable, Identifiable, Sendable {
    public let dApp: DApp
    public let claimAmounts: [PricedAmount<Asset>]

    public var id: String {
        guard let claimAmount = claimAmounts.first else {
            return "\(dApp.displayName.uppercased())_CLAIM_REWARDS_ACTION"
        }

        return
            "\(claimAmount.asset.chain.chainId):\(claimAmounts.map { "\($0.asset.address.hex):\($0.amount.underlying)" }.joined(separator: ":"))"
    }

    public init(
        dApp: DApp,
        claimAmounts: [PricedAmount<Asset>]
    ) {
        self.dApp = dApp
        self.claimAmounts = claimAmounts
    }
}

/// A ``DripTokensAction`` is a wrapped version of ``Actions.DripTokensActionContext``
public struct DripTokensAction: Equatable, Identifiable, Sendable {
    public let network: Network

    public init(network: Network) {
        self.network = network
    }

    public var id: String {
        "\(network.chainId)"
    }
}

public protocol WithdrawActionProtocol {
    var earnMarket: EarnMarket { get }
    var withdrawAmount: PricedAmount<BaseAsset> { get }
    var displayWithdrawAmount: Amount { get }
    var displayWithdrawAmountValue: Value { get }
}

extension WithdrawActionProtocol {
    public var displayWithdrawAmount: Amount {
        if withdrawAmount.amount.underlying.isMaxUint256 {
            earnMarket.baseAsset.marketBalance
        } else {
            withdrawAmount.amount
        }
    }

    public var displayWithdrawAmountValue: Value {
        if withdrawAmount.amount.underlying.isMaxUint256 {
            earnMarket.baseAsset.marketBalanceValue
        } else {
            withdrawAmount.amountValue
        }
    }
}

/// A ``WithdrawAction`` is a wrapped version of ``Actions.CometWithdrawActionContext`` or ``Actions.MorphoVaultWithdrawActionContext``
public struct WithdrawAction: WithdrawActionProtocol, Equatable, Identifiable, Sendable {
    public let earnMarket: EarnMarket
    public let withdrawAmount: PricedAmount<BaseAsset>

    public var id: String {
        "\(earnMarket.id.description):\(withdrawAmount.amount.underlying)"
    }

    public init(earnMarket: EarnMarket, withdrawAmount: PricedAmount<BaseAsset>) {
        self.earnMarket = earnMarket
        self.withdrawAmount = withdrawAmount
    }
}

/// A ``WithdrawAndBorrowAction`` is a wrapped version of ``Actions.WithdrawAndBorrowActionContext``
public struct WithdrawAndBorrowAction: WithdrawActionProtocol, BorrowActionProtocol, Equatable,
    Identifiable, Sendable
{
    public let earnMarket: EarnMarket
    public let borrowMarket: BorrowMarket
    public let withdrawAmount: PricedAmount<BaseAsset>
    public let borrowAmount: PricedAmount<BaseAsset>
    public let collateralAmounts: [PricedAmount<CollateralAsset>]

    public var id: String {
        "\(borrowMarket.baseAsset.chain.chainId):\(borrowMarket.baseAsset.address.hex):\(borrowMarket.id.description):\(withdrawAmount.amount.underlying):\(borrowAmount.amount.underlying)"
    }

    public init(
        earnMarket: EarnMarket,
        borrowMarket: BorrowMarket,
        withdrawAmount: PricedAmount<BaseAsset>,
        borrowAmount: PricedAmount<BaseAsset>,
        collateralAmounts: [PricedAmount<CollateralAsset>]
    ) {
        self.earnMarket = earnMarket
        self.borrowMarket = borrowMarket
        self.withdrawAmount = withdrawAmount
        self.borrowAmount = borrowAmount
        self.collateralAmounts = collateralAmounts
    }

    public var borrowValue: Value {
        borrowMarket.userBorrowValue + borrowAmount.amountValue
    }

    public var collateralValue: Value {
        let currentCollateralValue = borrowMarket.collateralAssets.map { $0.marketBalanceValue }
            .sum()
        let additionalCollateralValue = collateralAmounts.map { $0.amountValue }.sum()

        return currentCollateralValue + additionalCollateralValue
    }

    public var borrowCapacityValue: Value {
        let additionalBorrowCapacityValue =
            collateralAmounts
            .map { $0.amountValue * $0.asset.borrowCollateralFactor }
            .sum()

        return borrowMarket.borrowCapacityValue + additionalBorrowCapacityValue
    }

    public var liquidationCapacityValue: Value {
        let addtionalLiquidationCapacityValue =
            collateralAmounts
            .map { $0.amountValue * $0.asset.liquidateCollateralFactor }
            .sum()

        return borrowMarket.liquidationCapacityValue + addtionalLiquidationCapacityValue
    }
}

public struct QuotePayAction: Equatable, Identifiable, Sendable {
    public let amount: PricedAmount<Asset>
    public let quoteId: Hex

    public var id: String {
        "\(quoteId.description)"
    }

    public init(amount: PricedAmount<Asset>, quoteId: Hex) {
        self.amount = amount
        self.quoteId = quoteId
    }
}

public struct LoopLongAction: Equatable, Identifiable, Sendable {
    public let morphoMarket: MorphoMarket
    public let swapVenue: DApp
    public let maxSwapBackingAmount: PricedAmount<Asset>
    public let maxProvidedBackingAmount: PricedAmount<Asset>
    public let exposureAmount: PricedAmount<Asset>
    public let borrowAmount: PricedAmount<Asset>
    public let feeAmount: PricedAmount<Asset>
    public let isIncrease: Bool

    public var id: String {
        "\(morphoMarket.id):\(swapVenue.displayName):\(maxSwapBackingAmount.asset.address.hex):\(maxProvidedBackingAmount.asset.address.hex):\(exposureAmount.asset.address.hex)"
    }

    public init(
        morphoMarket: MorphoMarket,
        swapVenue: DApp,
        maxSwapBackingAmount: PricedAmount<Asset>,
        maxProvidedBackingAmount: PricedAmount<Asset>,
        exposureAmount: PricedAmount<Asset>,
        borrowAmount: PricedAmount<Asset>,
        feeAmount: PricedAmount<Asset>,
        isIncrease: Bool
    ) {
        self.morphoMarket = morphoMarket
        self.swapVenue = swapVenue
        self.maxSwapBackingAmount = maxSwapBackingAmount
        self.maxProvidedBackingAmount = maxProvidedBackingAmount
        self.exposureAmount = exposureAmount
        self.borrowAmount = borrowAmount
        self.feeAmount = feeAmount
        self.isIncrease = isIncrease
    }
}

public struct UnloopLongAction: Equatable, Identifiable, Sendable {
    public let morphoMarket: MorphoMarket
    public let swapVenue: DApp
    public let minSwapBackingAmount: PricedAmount<Asset>
    public let exposureAmount: PricedAmount<Asset>
    public let feeAmount: PricedAmount<Asset>

    public var id: String {
        "\(morphoMarket.id):\(swapVenue.displayName):\(minSwapBackingAmount.asset.address.hex):\(exposureAmount.asset.address.hex)"
    }

    public init(
        morphoMarket: MorphoMarket,
        swapVenue: DApp,
        minSwapBackingAmount: PricedAmount<Asset>,
        exposureAmount: PricedAmount<Asset>,
        feeAmount: PricedAmount<Asset>,
    ) {
        self.morphoMarket = morphoMarket
        self.swapVenue = swapVenue
        self.minSwapBackingAmount = minSwapBackingAmount
        self.exposureAmount = exposureAmount
        self.feeAmount = feeAmount
    }

    public var displayExposureAmount: Amount {
        if exposureAmount.amount.underlying.isMaxUint256 {
            morphoMarket.collateralAsset.marketBalance
        } else {
            exposureAmount.amount
        }
    }

    public var displayExposureAmountValue: Value {
        if exposureAmount.amount.underlying.isMaxUint256 {
            morphoMarket.collateralAsset.marketBalanceValue
        } else {
            exposureAmount.amountValue
        }
    }

    private var percentageRepaid: Percentage {
        exposureAmount.amount.underlying.isMaxUint256
            ? Percentage(double: 1.0)
            : exposureAmount.amount.percentageOf(morphoMarket.collateralAsset.marketBalance)
    }

    public var repaid: Amount {
        percentageRepaid * morphoMarket.userBorrow
    }

    public var repaidValue: Value {
        percentageRepaid * morphoMarket.userBorrowValue
    }

    public var backingAmountWithdrawn: PricedAmount<Asset> {
        let amount = minSwapBackingAmount.amount - repaid

        return PricedAmount(
            amount.underlying,
            forAsset: minSwapBackingAmount.asset,
            withPrice: minSwapBackingAmount.price.underlying
        )
    }
}

public struct AddBackingTokenAction: Equatable, Identifiable, Sendable {
    public let morphoMarket: MorphoMarket
    public let backingAmount: PricedAmount<Asset>
    public let side: LoopPositionSide

    public init(
        morphoMarket: MorphoMarket,
        backingAmount: PricedAmount<Asset>,
        side: LoopPositionSide
    ) {
        self.morphoMarket = morphoMarket
        self.backingAmount = backingAmount
        self.side = side
    }

    public var id: String {
        "\(morphoMarket.id):\(backingAmount.asset.address.hex):\(side)"
    }
}

public struct WithdrawBackingTokenAction: Equatable, Identifiable, Sendable {
    public let morphoMarket: MorphoMarket
    public let backingAmount: PricedAmount<Asset>
    public let side: LoopPositionSide

    public init(
        morphoMarket: MorphoMarket,
        backingAmount: PricedAmount<Asset>,
        side: LoopPositionSide
    ) {
        self.morphoMarket = morphoMarket
        self.backingAmount = backingAmount
        self.side = side
    }

    public var id: String {
        "\(morphoMarket.id):\(backingAmount.asset.address.hex):\(side)"
    }
}

/// Extension to filter different ``Action``s out of an ``[Action]``.
extension Array where Element == Action {
    public var justBorrowActions: [any BorrowActionProtocol] {
        extractedActions { action in
            if case .borrow(let borrowAction) = action {
                return borrowAction
            } else if case .repay(let repayAction) = action {
                return repayAction
            } else if case .withdrawBorrow(let withdrawAction) = action {
                return withdrawAction
            }

            return nil
        }
    }

    public var justBridgeActions: [BridgeAction] {
        extractedActions { action in
            if case .bridge(let bridgeAction) = action {
                return bridgeAction
            }
            return nil
        }
    }

    public var justSupplyActions: [SupplyAction] {
        extractedActions { action in
            if case .supply(let supplyAction) = action {
                return supplyAction
            }
            return nil
        }
    }

    public var justSwapActions: [SwapAction] {
        extractedActions { action in
            if case .swap(let swapAction) = action {
                return swapAction
            }
            return nil
        }
    }

    public var justRecurringSwapActions: [RecurringSwapAction] {
        extractedActions { action in
            if case .recurringSwap(let action) = action {
                return action
            }
            return nil
        }
    }

    public var justLoopLongActions: [LoopLongAction] {
        extractedActions { action in
            if case .loopLong(let action) = action {
                return action
            }
            return nil
        }
    }

    public var justUnloopLongActions: [UnloopLongAction] {
        extractedActions { action in
            if case .unloopLong(let action) = action {
                return action
            }
            return nil
        }
    }

    public var justQuotePayActions: [QuotePayAction] {
        extractedActions { action in
            if case .quotePay(let action) = action {
                return action
            }
            return nil
        }
    }

    /// Extract all actions that return a non-nil value for the given `using` closure
    public func extractedActions<T>(using extractor: (Action) -> T?) -> [T] {
        return flatMap { action in
            if let extracted = extractor(action) {
                return [extracted]
            }
            if case .multiAction(let actions) = action {
                return actions.compactMap(extractor)
            }
            return []
        }
    }
}
