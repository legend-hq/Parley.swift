import Eth
import Foundation
import SwiftNumber

public enum MarketIdentifier: Equatable, Hashable, Sendable {
    case cometMarket(Network, EthAddress)
    case morphoMarket(Network, Hex)
    case morphoVault(Network, EthAddress)
    case aaveMarket(Network, market: EthAddress, baseAsset: EthAddress)

    public var description: String {
        switch self {
            case .cometMarket(let network, let marketAddress):
                return "\(network.chainId)-\(marketAddress.hex)"
            case .morphoMarket(let network, let marketId):
                return "\(network.chainId)-\(marketId)"
            case .morphoVault(let network, let marketAddress):
                return "\(network.chainId)-\(marketAddress.hex)"
            case .aaveMarket(let network, let marketAddress, let baseAssetAddress):
                return "\(network.chainId)-\(marketAddress.hex)-\(baseAssetAddress.hex)"
        }
    }
}

public protocol MarketProtocol: Equatable, Identifiable, Hashable, Sendable, DAppedUp {
    var id: MarketIdentifier { get }
    var chain: Network { get }
    var name: String { get }
    var baseAsset: BaseAsset { get }
    var rewardAssets: [RewardAsset] { get }
}

public extension MarketProtocol {
    var onChain: String {
        "on \(chain.description)"
    }

    func rewardAsset(symbol: String) -> RewardAsset? {
        rewardAssets.first { $0.symbol.equalIgnoringCase(symbol) }
    }

    func hasRewardAsset(symbol: String) -> Bool {
        rewardAssets.contains { $0.symbol.equalIgnoringCase(symbol) }
    }
}

public enum Market: MarketProtocol {
    case borrowMarket(BorrowMarket)
    case earnMarket(EarnMarket)

    public enum Side: String, CaseIterable, Identifiable {
        public var id: String { rawValue }
        case borrow = "Borrow"
        case earn = "Earn"

        public var isEarn: Bool { self == .earn }
    }

    private var market: any MarketProtocol {
        switch self {
            case .borrowMarket(let borrowMarket):
                borrowMarket
            case .earnMarket(let earnMarket):
                earnMarket
        }
    }

    public var id: MarketIdentifier {
        market.id
    }

    public var name: String {
        market.name
    }

    public var chain: Eth.Network {
        market.chain
    }

    public var baseAsset: BaseAsset {
        market.baseAsset
    }

    public var rewardAssets: [RewardAsset] {
        market.rewardAssets
    }

    public var dApp: DApp {
        market.dApp
    }

    public var isEarnMarket: Bool {
        switch self {
            case .borrowMarket:
                return false
            case .earnMarket:
                return true
        }
    }

    public var netApr: Percentage {
        switch self {
            case .earnMarket(let earnMarket):
                return earnMarket.netEarnApr
            case .borrowMarket(let borrowMarket):
                return borrowMarket.netBorrowApr
        }
    }

    public var apr: Percentage {
        switch self {
            case .earnMarket(let earnMarket):
                return earnMarket.earnApr
            case .borrowMarket(let borrowMarket):
                return borrowMarket.borrowApr
        }
    }

    public var rewardsApr: Percentage {
        switch self {
            case .earnMarket(let earnMarket):
                return earnMarket.earnRewardsApr
            case .borrowMarket(let borrowMarket):
                return borrowMarket.borrowRewardsApr
        }
    }
}

public protocol EarnMarketProtocol: MarketProtocol {
    var address: EthAddress { get }
    var earnApr: Percentage { get }
    var earnRewardsApr: Percentage { get }
    var totalSupply: Amount { get }
}

public enum EarnMarket: EarnMarketProtocol {
    case cometMarket(CometMarket)
    case morphoVault(MorphoVaultMarket)
    case aaveMarket(AaveMarket)

    public var market: any EarnMarketProtocol {
        switch self {
            case .cometMarket(let market):
                market
            case .morphoVault(let market):
                market
            case .aaveMarket(let market):
                market
        }
    }

    public var id: MarketIdentifier {
        market.id
    }

    public var address: EthAddress {
        market.address
    }

    public var chain: Network {
        market.chain
    }

    public var name: String {
        market.name
    }

    public var baseAsset: BaseAsset {
        market.baseAsset
    }

    public var rewardAssets: [RewardAsset] {
        market.rewardAssets
    }

    public var earnApr: Percentage {
        market.earnApr
    }

    public var earnRewardsApr: Percentage {
        rewardAssets.map(\.supplyRewardsApr).sum()
    }

    public var totalSupply: Amount {
        market.totalSupply
    }

    public var netEarnApr: Percentage {
        earnApr + earnRewardsApr
    }

    public var dApp: DApp {
        market.dApp
    }

    public var marketType: String {
        switch self {
            case .cometMarket:
                return "COMET"
            case .morphoVault:
                return "MORPHO"
            case .aaveMarket:
                return "AAVE"
        }
    }

    public func isMigrateable(destinationChain: Network) -> Bool {
        if baseAsset.chain == destinationChain {
            true
        } else {
            baseAsset.isBridgeable
        }
    }
}

public protocol BorrowMarketProtocol: MarketProtocol {
    var userBorrow: Amount { get }
    var borrowCapacity: Amount { get }
    var liquidationCapacity: Amount { get }
    var borrowApr: Percentage { get }
    var borrowRewardsApr: Percentage { get }
    var totalBorrow: Amount { get }
    var totalSupply: Amount { get }
}

public extension BorrowMarketProtocol {
    var userBorrowValue: Value {
        userBorrow * baseAsset.price
    }

    var borrowCapacityValue: Value {
        borrowCapacity * baseAsset.price
    }

    var liquidationCapacityValue: Value {
        liquidationCapacity * baseAsset.price
    }

    var netBorrowApr: Percentage {
        borrowApr - borrowRewardsApr
    }

    var remainingBorrowCapacity: Amount {
        borrowCapacity - userBorrow
    }

    var remainingBorrowCapacityValue: Value {
        borrowCapacityValue - userBorrowValue
    }
}

public enum BorrowMarket: BorrowMarketProtocol {
    case cometMarket(CometMarket)
    case morphoMarket(MorphoMarket)

    public var market: any BorrowMarketProtocol {
        switch self {
            case .cometMarket(let market):
                market
            case .morphoMarket(let market):
                market
        }
    }

    public var id: MarketIdentifier {
        market.id
    }

    public var chain: Network {
        market.chain
    }

    public var name: String {
        market.name
    }

    public var baseAsset: BaseAsset {
        market.baseAsset
    }

    public var collateralAssets: [CollateralAsset] {
        switch self {
            case .cometMarket(let market): market.collateralAssets
            case .morphoMarket(let market): [market.collateralAsset]
        }
    }

    public var totalBorrow: Amount {
        market.totalBorrow
    }

    public var totalSupply: Amount {
        market.totalSupply
    }

    public var userBorrow: Amount {
        market.userBorrow
    }

    public var userBorrowValue: Value {
        market.userBorrowValue
    }

    public var borrowCapacity: Amount {
        market.borrowCapacity
    }

    public var borrowCapacityValue: Value {
        market.borrowCapacityValue
    }

    public var liquidationCapacity: Amount {
        market.liquidationCapacity
    }

    public var liquidationCapacityValue: Value {
        market.liquidationCapacityValue
    }

    public var borrowApr: Percentage {
        market.borrowApr
    }

    public var rewardAssets: [RewardAsset] {
        market.rewardAssets
    }

    public var borrowRewardsApr: Percentage {
        market.rewardAssets.map(\.borrowRewardsApr).sum()
    }

    var remainingBorrowCapacityValue: Value {
        market.remainingBorrowCapacityValue
    }

    /// The full value of collateral at which the user gets liquidated
    ///
    /// ```
    /// liquidationPoint = (1 - (liquidatoinFactorValue - borrowValue) / liquidationFactorValue) * fullCollateralValue
    /// liquidationPoint = (fullCollateralValue - (liquidatoinFactorValue - borrowValue) * fullCollateralValue / liquidationFactorValue)
    /// ```
    public var liquidationPoint: Value {
        guard !liquidationCapacityValue.isZero else {
            return Value.zero
        }

        let fullCollateralValue: Value = collateralAssets.map { $0.marketBalanceValue }.sum()
        return fullCollateralValue
            - (((liquidationCapacityValue - userBorrowValue) * fullCollateralValue)
                / liquidationCapacityValue)
    }

    public var liquidationValue: Value {
        collateralAssets.map { $0.marketBalanceValue * $0.liquidateCollateralFactor }
            .sum()
    }

    public var availableLiquidityValue: Value {
        (totalSupply - totalBorrow) * baseAsset.price
    }

    public func potentialBorrowCapacityValue(metaAssets: [MetaAsset]) -> Value {
        collateralAssets.reduce(into: Value(0)) { result, asset in
            let balance: Amount

            if let metaAsset = metaAssets.getMetaAsset(symbol: asset.symbol), metaAsset.isBridgeable
            {
                balance = metaAsset.balance
            } else {
                balance = asset.balance
            }

            let totalCollateral = balance + asset.marketBalance
            let borrowLimit = totalCollateral * asset.borrowCollateralFactor
            let borrowLimitValue = borrowLimit * asset.price

            result += borrowLimitValue
        }
    }

    public func remainingPotentialBorrowCapacityValue(metaAssets: [MetaAsset]) -> Value {
        potentialBorrowCapacityValue(metaAssets: metaAssets) - userBorrowValue
    }

    public func getCollateralAsset(symbol: String) -> CollateralAsset? {
        collateralAssets.first { $0.symbol.equalIgnoringCase(symbol) }
    }

    public func getCollateralAsset(token: EthAddress) -> CollateralAsset? {
        collateralAssets.first { $0.address == token }
    }

    public var dApp: DApp {
        market.dApp
    }

    /// Indicates whether the current BorrowMarket supports borrowing against multiple collaterals
    public var supportsMultiCollateral: Bool {
        switch self {
            case .cometMarket: true
            case .morphoMarket: false
        }
    }
}

public struct CometMarket: BorrowMarketProtocol, EarnMarketProtocol {
    public var id: MarketIdentifier {
        .cometMarket(chain, address)
    }

    public var dApp: DApp {
        .Compound
    }

    public let chain: Network
    public let address: EthAddress
    public let name: String
    public let totalSupply: Amount
    public let totalBorrow: Amount
    public let userBorrow: Amount
    public let borrowCapacity: Amount
    public let liquidationCapacity: Amount
    public let earnApr: Percentage
    public let earnRewardsApr: Percentage
    public let borrowApr: Percentage
    public let borrowRewardsApr: Percentage
    public let baseAsset: BaseAsset
    public let collateralAssets: [CollateralAsset]
    public let rewardAssets: [RewardAsset]

    public init(
        chain: Network,
        address: EthAddress,
        name: String,
        totalSupply: Amount,
        totalBorrow: Amount,
        userBorrow: Amount,
        borrowCapacity: Amount,
        liquidationCapacity: Amount,
        earnApr: Percentage,
        earnRewardsApr: Percentage,
        borrowApr: Percentage,
        borrowRewardsApr: Percentage,
        baseAsset: BaseAsset,
        collateralAssets: [CollateralAsset],
        rewardAssets: [RewardAsset]
    ) {
        self.chain = chain
        self.address = address
        self.name = name
        self.totalSupply = totalSupply
        self.totalBorrow = totalBorrow
        self.userBorrow = userBorrow
        self.borrowCapacity = borrowCapacity
        self.liquidationCapacity = liquidationCapacity
        self.earnApr = earnApr
        self.earnRewardsApr = earnRewardsApr
        self.borrowApr = borrowApr
        self.borrowRewardsApr = borrowRewardsApr
        self.baseAsset = baseAsset
        self.collateralAssets = collateralAssets
        self.rewardAssets = rewardAssets
    }
}

public struct MorphoMarket: BorrowMarketProtocol {
    public var id: MarketIdentifier {
        .morphoMarket(chain, marketId)
    }

    public var dApp: DApp {
        .Morpho
    }

    public let chain: Network
    public let address: EthAddress
    public let marketId: Hex
    public let name: String
    public let totalSupply: Amount
    public let totalBorrow: Amount
    public let userBorrow: Amount
    public let borrowCapacity: Amount
    public let liquidationCapacity: Amount
    public let borrowApr: Percentage
    public let borrowRewardsApr: Percentage
    public let baseAsset: BaseAsset
    public let collateralAsset: CollateralAsset
    public let rewardAssets: [RewardAsset]

    public init(
        chain: Network,
        address: EthAddress,
        marketId: Hex,
        name: String,
        totalSupply: Amount,
        totalBorrow: Amount,
        userBorrow: Amount,
        borrowCapacity: Amount,
        liquidationCapacity: Amount,
        borrowApr: Percentage,
        borrowRewardsApr: Percentage,
        baseAsset: BaseAsset,
        collateralAsset: CollateralAsset,
        rewardAssets: [RewardAsset]
    ) {
        self.chain = chain
        self.address = address
        self.marketId = marketId
        self.name = name
        self.totalSupply = totalSupply
        self.totalBorrow = totalBorrow
        self.userBorrow = userBorrow
        self.borrowCapacity = borrowCapacity
        self.liquidationCapacity = liquidationCapacity
        self.borrowApr = borrowApr
        self.borrowRewardsApr = borrowRewardsApr
        self.baseAsset = baseAsset
        self.collateralAsset = collateralAsset
        self.rewardAssets = rewardAssets
    }
}

public struct MorphoVaultMarket: EarnMarketProtocol {
    public var id: MarketIdentifier {
        .morphoVault(chain, address)
    }

    public var dApp: DApp {
        .Morpho
    }

    public let chain: Network
    public let address: EthAddress
    public let name: String
    public let baseAsset: BaseAsset
    public let rewardAssets: [RewardAsset]
    public let earnApr: Percentage
    public let earnRewardsApr: Percentage
    public let totalSupply: Amount

    public init(
        chain: Network,
        address: EthAddress,
        name: String,
        baseAsset: BaseAsset,
        rewardAssets: [RewardAsset],
        earnApr: Percentage,
        earnRewardsApr: Percentage,
        totalSupply: Amount
    ) {
        self.chain = chain
        self.address = address
        self.name = name
        self.baseAsset = baseAsset
        self.rewardAssets = rewardAssets
        self.earnApr = earnApr
        self.earnRewardsApr = earnRewardsApr
        self.totalSupply = totalSupply
    }
}

public struct AaveMarket: EarnMarketProtocol {
    public var id: MarketIdentifier {
        .aaveMarket(chain, market: address, baseAsset: baseAsset.address)
    }

    public var dApp: DApp {
        .Aave
    }

    public let chain: Network
    public let address: EthAddress
    public let name: String
    public let baseAsset: BaseAsset
    public let rewardAssets: [RewardAsset]
    public let earnApr: Percentage
    public let earnRewardsApr: Percentage
    public let totalSupply: Amount

    public init(
        chain: Network,
        address: EthAddress,
        name: String,
        baseAsset: BaseAsset,
        rewardAssets: [RewardAsset],
        earnApr: Percentage,
        earnRewardsApr: Percentage,
        totalSupply: Amount
    ) {
        self.chain = chain
        self.address = address
        self.name = name
        self.baseAsset = baseAsset
        self.rewardAssets = rewardAssets
        self.earnApr = earnApr
        self.earnRewardsApr = earnRewardsApr
        self.totalSupply = totalSupply
    }
}

public extension Array where Element: MarketProtocol {
    func marketsByBaseMetaAsset(metaAssets: [MetaAsset]) -> [MetaAsset: [Element]] {
        let metaAssetsDict = Dictionary(uniqueKeysWithValues: metaAssets.map { ($0.symbol, $0) })

        return reduce(into: [MetaAsset: [Element]]()) { result, market in
            if let metaAsset = metaAssetsDict[market.baseAsset.symbol] {
                var markets = result[metaAsset, default: []]
                markets += [market]

                result[metaAsset] = markets
            }
        }
    }

    func firstMarketWithId(_ id: Element.ID) -> Element? {
        first(where: { $0.id == id })
    }
}

public extension Array where Element == EarnMarket {
    var maxEarnApr: Percentage? {
        self.max(by: { $0.netEarnApr < $1.netEarnApr })?.netEarnApr
    }

    func marketsWithSupplyBalance(baseAssetSymbol: String) -> [Element] {
        filter { baseAssetSymbol == $0.baseAsset.symbol && !$0.baseAsset.marketBalance.isZero }
    }

    func sortedBySupplyBalance(baseAssetSymbol: String) -> [Element] {
        sorted {
            guard $0.baseAsset.symbol == baseAssetSymbol else {
                return false
            }

            return $0.baseAsset.marketBalance > $1.baseAsset.marketBalance
        }
    }
}

public extension Array where Element == BorrowMarket {
    var minBorrowApr: Percentage? {
        self.min(by: { $0.netBorrowApr < $1.netBorrowApr })?.netBorrowApr
    }

    var marketsWithBorrowBalance: [Element] {
        filter { !$0.userBorrow.isZero }
    }

    var marketsWithBorrowCapacity: [Element] {
        filter { !$0.borrowCapacity.isZero }
    }

    func getMaxBorrowCollateralFactor(collateralAssetSymbol: String) -> Percentage? {
        flatMap { $0.collateralAssets }
            .filter { $0.symbol == collateralAssetSymbol }
            .map { $0.borrowCollateralFactor }
            .max()
    }

    func marketsWithCollateralBalance(collateralAssetSymbol: String) -> [Element] {
        filter {
            $0.collateralAssets.contains { collateralAsset in
                collateralAssetSymbol == collateralAsset.symbol
                    && !collateralAsset.marketBalance.isZero
            }
        }
    }

    func sortedByCollateralBalance(collateralAssetSymbol: String) -> [Element] {
        sorted {
            guard let collateralAssetLeft = $0.getCollateralAsset(symbol: collateralAssetSymbol),
                let collateralAssetRight = $1.getCollateralAsset(symbol: collateralAssetSymbol)
            else {
                return false
            }

            return collateralAssetLeft.marketBalance > collateralAssetRight.marketBalance
        }
    }
}
