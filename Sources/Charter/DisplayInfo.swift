/// Display settings extracted from intents that affect operation building.
public struct DisplayInfo: Sendable, Equatable {
    /// True if user is "buying". Only relevant for swaps.
    public let isBuy: Bool?

    public init(isBuy: Bool? = nil) {
        self.isBuy = isBuy
    }

    /// Extracts display settings from an intent. Returns nil for intents without display settings.
    public static func from(intent: Charter.QuarkIntent.Type_) -> DisplayInfo? {
        switch intent {
        case .swap(let swapIntent):
            return DisplayInfo(isBuy: swapIntent.isBuy)
        case .swapV2(let swapIntentV2):
            return DisplayInfo(isBuy: swapIntentV2.isBuy)
        case .swapAndSupply(let swapAndSupplyIntent):
            return DisplayInfo(isBuy: swapAndSupplyIntent.swapIntent.isBuy)
        case .compounder(let compounderIntent):
            return DisplayInfo(isBuy: compounderIntent.swapIntents.first?.isBuy)
        default:
            return nil
        }
    }
}
