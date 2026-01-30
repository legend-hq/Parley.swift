import Eth
import Foundation
import Prelude

public enum SwapVenue: String, Sendable {
    case uniswap
    case zeroEx
    case projectX

    public init?(rawValue: String) {
        guard
            rawValue.contains("matcha") || rawValue.contains("uniswap")
                || rawValue.contains("zero_ex") || rawValue.contains("project_x")
        else {
            Logger.error("Unknown SwapVenue: \(rawValue)")
            return nil
        }

        if rawValue.contains("matcha") || rawValue.contains("zero_ex") {
            self = .zeroEx
        } else if rawValue.contains("project_x") {
            self = .projectX
        } else {
            self = .uniswap
        }
    }

    public var dApp: DApp {
        switch self {
            case .zeroEx:
                .ZeroEx
            case .uniswap:
                .Uniswap
            case .projectX:
                .ProjectX
        }
    }
}

public enum Bridge: String, Sendable {
    case across
    case cctp

    public init?(rawValue: String) {
        guard rawValue.contains("cctp") || rawValue.contains("across") else {
            Logger.error("Unknown Bridge: \(rawValue)")
            return nil
        }

        if rawValue.contains("across") {
            self = .across
        } else {
            self = .cctp
        }
    }

    public var dApp: DApp {
        switch self {
            case .across:
                .Across
            case .cctp:
                .CircleBridge
        }
    }
}

public enum SemanticEvent: Equatable, Hashable, Sendable {
    case aaveSupply(EarnMarketEvent)
    case aaveWithdraw(EarnMarketEvent)
    case cometSupplyBaseAsset(EarnMarketEvent)
    case morphoVaultSupply(EarnMarketEvent)
    case cometSupplyCollateral(BorrowMarketCollateralEvent)
    case morphoSupplyCollateral(BorrowMarketCollateralEvent)
    case cometRepay(BorrowMarketBaseAssetEvent)
    case morphoRepay(BorrowMarketBaseAssetEvent)
    case cometWithdrawBaseAsset(EarnMarketEvent)
    case morphoVaultWithdraw(EarnMarketEvent)
    case cometWithdrawCollateral(BorrowMarketCollateralEvent)
    case morphoWithdrawCollateral(BorrowMarketCollateralEvent)
    case cometBorrow(BorrowMarketBaseAssetEvent)
    case morphoBorrow(BorrowMarketBaseAssetEvent)
    case cometLiquidationCollateralAbsorbed(BorrowMarketCollateralEvent)
    case cometLiquidationBaseAssetPaidOut(BorrowMarketBaseAssetEvent)  // TODO: This event is missing "token"
    case morphoLiquidation(MorphoLiquidationEvent)
    case paycall(PayEvent)
    case swap(SwapEvent)
    case bridgeSend(BridgeSendEvent)
    case bridgeReceive(BridgeReceiveEvent)
    case outboundTransfer(OutboundTransferEvent)
    case inboundTransfer(InboundTransferEvent)
    case claimReward(ClaimRewardEvent)
    case loopLong(LoopLongEvent)
    case unloopLong(UnloopLongEvent)
    case addBackingToken(AddBackingTokenEvent)
    case withdrawBackingToken(WithdrawBackingTokenEvent)
    case quotePay(QuotePayEvent)
}

public struct EarnMarketEvent: Equatable, Hashable, Sendable {
    public let earnMarket: EarnMarket
    public let amount: PricedAmount<BaseAsset>

    public init(earnMarket: EarnMarket, amount: PricedAmount<BaseAsset>) {
        self.earnMarket = earnMarket
        self.amount = amount
    }
}

public struct BorrowMarketBaseAssetEvent: Equatable, Hashable, Sendable {
    public let borrowMarket: BorrowMarket
    public let amount: PricedAmount<BaseAsset>

    public init(borrowMarket: BorrowMarket, amount: PricedAmount<BaseAsset>) {
        self.borrowMarket = borrowMarket
        self.amount = amount
    }
}

public struct BorrowMarketCollateralEvent: Equatable, Hashable, Sendable {
    public let borrowMarket: BorrowMarket
    public let amount: PricedAmount<CollateralAsset>

    public init(borrowMarket: BorrowMarket, amount: PricedAmount<CollateralAsset>) {
        self.borrowMarket = borrowMarket
        self.amount = amount
    }
}

public struct MorphoLiquidationEvent: Equatable, Hashable, Sendable {
    public let borrowMarket: BorrowMarket
    public let collateralSeized: PricedAmount<CollateralAsset>
    public let debtRepaid: PricedAmount<BaseAsset>

    public init(
        borrowMarket: BorrowMarket,
        collateralSeized: PricedAmount<CollateralAsset>,
        debtRepaid: PricedAmount<BaseAsset>
    ) {
        self.borrowMarket = borrowMarket
        self.collateralSeized = collateralSeized
        self.debtRepaid = debtRepaid
    }
}

public struct PayEvent: Equatable, Hashable, Sendable {
    public let amount: PricedAmount<Asset>

    public init(amount: PricedAmount<Asset>) {
        self.amount = amount
    }
}

public struct SwapEvent: Equatable, Hashable, Sendable {
    public let inAmount: PricedAmount<Asset>
    public let outAmount: PricedAmount<Asset>
    public let swapVenue: SwapVenue

    public init(inAmount: PricedAmount<Asset>, outAmount: PricedAmount<Asset>, swapVenue: SwapVenue)
    {
        self.inAmount = inAmount
        self.outAmount = outAmount
        self.swapVenue = swapVenue
    }
}

public struct BridgeSendEvent: Equatable, Hashable, Sendable {
    public let bridgeAmount: PricedAmount<Asset>
    public let bridgeFee: PricedAmount<Asset>
    public let bridge: Bridge
    public let destinationNetwork: Network

    public init(
        bridgeAmount: PricedAmount<Asset>,
        bridgeFee: PricedAmount<Asset>,
        bridge: Bridge,
        destinationNetwork: Network
    ) {
        self.bridgeAmount = bridgeAmount
        self.bridgeFee = bridgeFee
        self.bridge = bridge
        self.destinationNetwork = destinationNetwork
    }
}

public struct BridgeReceiveEvent: Equatable, Hashable, Sendable {
    public let bridgeAmount: PricedAmount<Asset>
    public let bridgeFee: PricedAmount<Asset>
    public let bridge: Bridge

    public init(bridgeAmount: PricedAmount<Asset>, bridgeFee: PricedAmount<Asset>, bridge: Bridge) {
        self.bridgeAmount = bridgeAmount
        self.bridgeFee = bridgeFee
        self.bridge = bridge
    }
}

public struct InboundTransferEvent: Equatable, Hashable, Sendable {
    public let transferAmount: PricedAmount<Asset>
    public let sender: ChainAddress

    public init(transferAmount: PricedAmount<Asset>, sender: ChainAddress) {
        self.transferAmount = transferAmount
        self.sender = sender
    }
}

public struct OutboundTransferEvent: Equatable, Hashable, Sendable {
    public let transferAmount: PricedAmount<Asset>
    public let recipient: ChainAddress

    public init(transferAmount: PricedAmount<Asset>, recipient: ChainAddress) {
        self.transferAmount = transferAmount
        self.recipient = recipient
    }
}

public struct QuotePayEvent: Equatable, Hashable, Sendable {
    public let amount: PricedAmount<Asset>

    public init(amount: PricedAmount<Asset>) {
        self.amount = amount
    }
}

public struct ClaimRewardEvent: Equatable, Hashable, Sendable {
    public let dApp: DApp
    public let claimAmount: PricedAmount<Asset>

    public init(dApp: DApp, claimAmount: PricedAmount<Asset>) {
        self.dApp = dApp
        self.claimAmount = claimAmount
    }
}

public struct LoopLongEvent: Equatable, Hashable, Sendable {
    public let morphoMarket: MorphoMarket
    public let swapVenue: DApp
    public let backingAmount: PricedAmount<Asset>
    public let exposureAmount: PricedAmount<Asset>
    public let swapInputAmount: PricedAmount<Asset>
    public let swapOutputAmount: PricedAmount<Asset>

    public init(
        morphoMarket: MorphoMarket,
        swapVenue: DApp,
        backingAmount: PricedAmount<Asset>,
        exposureAmount: PricedAmount<Asset>,
        swapInputAmount: PricedAmount<Asset>,
        swapOutputAmount: PricedAmount<Asset>
    ) {
        self.morphoMarket = morphoMarket
        self.swapVenue = swapVenue
        self.backingAmount = backingAmount
        self.exposureAmount = exposureAmount
        self.swapInputAmount = swapInputAmount
        self.swapOutputAmount = swapOutputAmount
    }
}

public struct UnloopLongEvent: Equatable, Hashable, Sendable {
    public let morphoMarket: MorphoMarket
    public let swapVenue: DApp
    public let backingAmount: PricedAmount<Asset>
    public let exposureAmount: PricedAmount<Asset>
    public let swapInputAmount: PricedAmount<Asset>
    public let swapOutputAmount: PricedAmount<Asset>

    public init(
        morphoMarket: MorphoMarket,
        swapVenue: DApp,
        backingAmount: PricedAmount<Asset>,
        exposureAmount: PricedAmount<Asset>,
        swapInputAmount: PricedAmount<Asset>,
        swapOutputAmount: PricedAmount<Asset>
    ) {
        self.morphoMarket = morphoMarket
        self.swapVenue = swapVenue
        self.backingAmount = backingAmount
        self.exposureAmount = exposureAmount
        self.swapInputAmount = swapInputAmount
        self.swapOutputAmount = swapOutputAmount
    }

    /// Backing token amount withdrawn
    public var backingAmountWithdrawn: PricedAmount<Asset> {
        let amount = swapOutputAmount.amount - backingAmount.amount

        return PricedAmount(
            amount.underlying,
            forAsset: backingAmount.asset,
            withPrice: backingAmount.price.underlying
        )
    }

    public var repaid: PricedAmount<Asset> {
        backingAmount
    }
}

public struct AddBackingTokenEvent: Equatable, Hashable, Sendable {
    public let morphoMarket: MorphoMarket
    public let backingAmount: PricedAmount<Asset>
    public let isShort: Bool

    public init(morphoMarket: MorphoMarket, backingAmount: PricedAmount<Asset>, isShort: Bool) {
        self.morphoMarket = morphoMarket
        self.backingAmount = backingAmount
        self.isShort = isShort
    }
}

public struct WithdrawBackingTokenEvent: Equatable, Hashable, Sendable {
    public let morphoMarket: MorphoMarket
    public let backingAmount: PricedAmount<Asset>
    public let isShort: Bool

    public init(morphoMarket: MorphoMarket, backingAmount: PricedAmount<Asset>, isShort: Bool) {
        self.morphoMarket = morphoMarket
        self.backingAmount = backingAmount
        self.isShort = isShort
    }
}

extension SemanticEvent {
    public func isRelatedTo(assetSymbol: String) -> Bool {
        switch self {
            case .aaveSupply(let event):
                event.amount.asset.symbol == assetSymbol
            case .aaveWithdraw(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometSupplyBaseAsset(let event):
                event.amount.asset.symbol == assetSymbol
            case .morphoVaultSupply(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometSupplyCollateral(let event):
                event.amount.asset.symbol == assetSymbol
            case .morphoSupplyCollateral(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometRepay(let event):
                event.amount.asset.symbol == assetSymbol
            case .morphoRepay(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometWithdrawBaseAsset(let event):
                event.amount.asset.symbol == assetSymbol
            case .morphoVaultWithdraw(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometWithdrawCollateral(let event):
                event.amount.asset.symbol == assetSymbol
            case .morphoWithdrawCollateral(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometBorrow(let event):
                event.amount.asset.symbol == assetSymbol
            case .morphoBorrow(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometLiquidationCollateralAbsorbed(let event):
                event.amount.asset.symbol == assetSymbol
            case .cometLiquidationBaseAssetPaidOut(let event):
                event.amount.asset.symbol == assetSymbol
            case .morphoLiquidation(let event):
                event.debtRepaid.asset.symbol == assetSymbol
                    || event.collateralSeized.asset.symbol == assetSymbol
            case .paycall(let event):
                event.amount.asset.symbol == assetSymbol
            case .swap(let event):
                if assetSymbol == "USDC" {
                    false
                } else {
                    event.inAmount.asset.symbol == assetSymbol
                        || event.outAmount.asset.symbol == assetSymbol
                }
            case .outboundTransfer(let event):
                event.transferAmount.asset.symbol == assetSymbol
            case .inboundTransfer(let event):
                event.transferAmount.asset.symbol == assetSymbol
            case .claimReward(let event):
                event.claimAmount.asset.symbol == assetSymbol
            case .loopLong(let event):
                event.exposureAmount.asset.symbol == assetSymbol
            case .unloopLong(let event):
                event.exposureAmount.asset.symbol == assetSymbol
            case .addBackingToken(let event):
                event.backingAmount.asset.symbol == assetSymbol
            case .withdrawBackingToken(let event):
                event.backingAmount.asset.symbol == assetSymbol
            case .quotePay, .bridgeSend, .bridgeReceive:
                false
        }
    }
}

extension Array where Element == SemanticEvent {
    public var supplyEvent: EarnMarketEvent? {
        compactMap {
            switch $0 {
                case .cometSupplyBaseAsset(let event), .morphoVaultSupply(let event),
                    .aaveSupply(let event):
                    return event
                default:
                    return nil
            }
        }
        .first
    }

    public var supplyCollateralEvents: [BorrowMarketCollateralEvent] {
        compactMap {
            switch $0 {
                case .cometSupplyCollateral(let event), .morphoSupplyCollateral(let event):
                    return event
                default:
                    return nil
            }
        }
    }

    public var repayEvent: BorrowMarketBaseAssetEvent? {
        compactMap { (element: SemanticEvent) -> BorrowMarketBaseAssetEvent? in
            switch element {
                case .cometRepay(let event), .morphoRepay(let event):
                    if event.amount.amount.isZero {
                        return nil
                    }

                    return event
                default:
                    return nil
            }
        }
        .first
    }

    public var withdrawEvents: [EarnMarketEvent] {
        compactMap {
            switch $0 {
                case .cometWithdrawBaseAsset(let event), .morphoVaultWithdraw(let event),
                    .aaveWithdraw(let event):
                    return event
                default:
                    return nil
            }
        }
    }

    public var withdrawEvent: EarnMarketEvent? {
        withdrawEvents.first
    }

    public func withdrawEvent(earnMarket: EarnMarket) -> EarnMarketEvent? {
        withdrawEvents.first { $0.earnMarket == earnMarket }
    }

    public var withdrawCollateralEvents: [BorrowMarketCollateralEvent] {
        compactMap {
            switch $0 {
                case .cometWithdrawCollateral(let event), .morphoWithdrawCollateral(let event):
                    return event
                default:
                    return nil
            }
        }
    }

    public var borrowEvent: BorrowMarketBaseAssetEvent? {
        compactMap { (element: SemanticEvent) -> BorrowMarketBaseAssetEvent? in
            switch element {
                case .cometBorrow(let event), .morphoBorrow(let event):
                    if event.amount.amount.isZero {
                        return nil
                    }

                    return event
                default:
                    return nil
            }
        }
        .first
    }

    public var morphoLiquidationEvent: MorphoLiquidationEvent? {
        compactMap { (element: SemanticEvent) -> MorphoLiquidationEvent? in
            switch element {
                case .morphoLiquidation(let event):
                    return event

                default:
                    return nil
            }
        }
        .first
    }

    public var outboundTransferEvent: OutboundTransferEvent? {
        compactMap { (element: SemanticEvent) -> OutboundTransferEvent? in
            guard case .outboundTransfer(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }

    public var outboundTransferEvents: [OutboundTransferEvent] {
        compactMap {
            guard case .outboundTransfer(let event) = $0 else {
                return nil
            }
            return event
        }
    }

    public var inboundTransferEvent: InboundTransferEvent? {
        compactMap { (element: SemanticEvent) -> InboundTransferEvent? in
            guard case .inboundTransfer(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }

    public var swapEvents: [SwapEvent] {
        compactMap {
            guard case .swap(let event) = $0 else {
                return nil
            }
            return event
        }
    }

    public var swapEvent: SwapEvent? {
        swapEvents.first
    }

    public func swapEvent(buyToken: EthAddress, sellToken: EthAddress) -> SwapEvent? {
        swapEvents.first {
            $0.outAmount.asset.address == buyToken && $0.inAmount.asset.address == sellToken
        }
    }

    public var claimEvents: [ClaimRewardEvent] {
        compactMap {
            guard case .claimReward(let event) = $0 else {
                return nil
            }
            return event
        }
    }

    public var bridgeSendEvent: BridgeSendEvent? {
        compactMap { (element: SemanticEvent) -> BridgeSendEvent? in
            guard case .bridgeSend(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }

    public var bridgeReceiveEvent: BridgeReceiveEvent? {
        compactMap { (element: SemanticEvent) -> BridgeReceiveEvent? in
            guard case .bridgeReceive(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }

    public var loopLongEvent: LoopLongEvent? {
        compactMap { (element: SemanticEvent) -> LoopLongEvent? in
            guard case .loopLong(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }

    public var unloopLongEvent: UnloopLongEvent? {
        compactMap { (element: SemanticEvent) -> UnloopLongEvent? in
            guard case .unloopLong(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }

    public var addBackingTokenEvent: AddBackingTokenEvent? {
        compactMap { (element: SemanticEvent) -> AddBackingTokenEvent? in
            guard case .addBackingToken(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }

    public var withdrawBackingTokenEvent: WithdrawBackingTokenEvent? {
        compactMap { (element: SemanticEvent) -> WithdrawBackingTokenEvent? in
            guard case .withdrawBackingToken(let event) = element else {
                return nil
            }
            return event
        }
        .first
    }
}
