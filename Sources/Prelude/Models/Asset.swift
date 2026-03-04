import Atlas
import Eth
import Foundation
import SwiftNumber

public protocol ChainAgnosticAssetProtocol: Equatable, Hashable, Identifiable, Sendable {
    var name: String { get }
    var symbol: String { get }
    var decimals: Int { get }
    var displaySymbol: String { get }
    var displayName: String { get }
    var balance: Amount { get }
    var balanceValue: Value { get }
}

extension ChainAgnosticAssetProtocol {
    public var displaySymbol: String {
        Atlas.CrossChainAssets.getCrossChainAsset(symbol: symbol)?.displaySymbol ?? symbol
    }

    public var displayName: String {
        Atlas.CrossChainAssets.getCrossChainAsset(symbol: symbol)?.displayName ?? name
    }

    public var isBridgeable: Bool {
        switch symbol {
            case "USDC", "ETH", "WETH":
                true
            default:
                false
        }
    }

    public var isStablecoin: Bool {
        ["USDC", "USDT", "DAI", "USDe", "FRAX"].contains { $0 == self.symbol }
    }

    public var isUsdc: Bool {
        symbol == "USDC"
    }

    public var token: Token {
        Token(symbol)
    }
}

extension ChainAgnosticAssetProtocol where Self: Equatable {
    /// Check if any type that conforms to `ChainAgnosticAssetProtocol` is equal to Self
    public func isEqualTo(_ other: any ChainAgnosticAssetProtocol) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        return self == other
    }

    /// Check if `chainId` and `symbol` is equal to self
    public func isEqualTo(chainId: Number, symbol: String) -> Bool {
        if let asset = self as? any AssetProtocol {
            return symbol == self.symbol && chainId == asset.chain.chainId
        } else {
            return symbol == self.symbol
        }
    }
}

public protocol AssetProtocol: ChainAgnosticAssetProtocol {
    var address: EthAddress { get }
    var chain: Network { get }
    var price: Value { get }
}

extension AssetProtocol {
    public var balanceValue: Value {
        balance * price
    }

    public var onChain: String {
        "on \(chain.description)"
    }
}

public struct Asset: AssetProtocol, Sendable {
    public var id: String {
        "\(chain.chainId.description):\(address.hex)"
    }

    public let address: EthAddress
    public let chain: Network
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let price: Value
    public let balances: [Balance]
    public let underlyingAsset: UnderlyingAsset?

    public init(
        address: EthAddress,
        chain: Network,
        name: String,
        symbol: String,
        decimals: Int,
        price: Value,
        balances: [Balance],
        underlyingAsset: UnderlyingAsset? = nil
    ) {
        self.address = address
        self.chain = chain
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.price = price
        self.balances = balances
        self.underlyingAsset = underlyingAsset
    }

    public var balance: Amount {
        balances.map {
            ($0.balance * underlyingUnwrapQuote) + $0.underlyingAssetBalance
        }
        .sum(decimals: decimals)
    }

    public var underlyingBalance: Amount {
        balances.map { $0.underlyingAssetBalance }.sum(decimals: decimals)
    }

    public var underlyingUnwrapQuote: Percentage {
        underlyingAsset?.unwrapQuote ?? .oneHundred
    }

    public var underlyingAssetSymbol: String {
        underlyingAsset?.symbol ?? symbol
    }

    public var underlyingPrice: Value {
        price / underlyingUnwrapQuote
    }

    public struct Balance: Equatable, Hashable, Sendable {
        public let wallet: EthAddress
        public let balance: Amount
        public let underlyingAssetBalance: Amount

        public init(wallet: EthAddress, balance: Amount, underlyingAssetBalance: Amount? = nil) {
            self.wallet = wallet
            self.balance = balance
            self.underlyingAssetBalance =
                underlyingAssetBalance ?? Amount(0, decimals: balance.decimals)
        }

        public func fullBalance(underlyingUnwrapQuote: Percentage) -> Amount {
            (balance / underlyingUnwrapQuote) + underlyingAssetBalance
        }
    }

    public struct UnderlyingAsset: Equatable, Hashable, Sendable {
        public let address: EthAddress
        public let name: String
        public let symbol: String
        public let decimals: Int
        public let unwrapQuote: Percentage

        public init(
            address: EthAddress,
            name: String,
            symbol: String,
            decimals: Int,
            unwrapQuote: Percentage
        ) {
            self.address = address
            self.name = name
            self.symbol = symbol
            self.decimals = decimals
            self.unwrapQuote = unwrapQuote
        }
    }
}

public struct MetaAsset: ChainAgnosticAssetProtocol {
    public var id: String {
        symbol
    }

    public var assets: [Asset]
    public var baseAssets: [BaseAsset]
    public var collateralAssets: [CollateralAsset]
    public var rewardAssets: [RewardAsset]
    public var realizedPnL: ProfitAndLossSummary
    public var realizedInterestPnL: ProfitAndLossSummary
    public var realizedRewardPnL: ProfitAndLossSummary
    public var unrealizedPnL: ProfitAndLossSummary
    public var averageCostPosition: AverageCostPosition
    public var cumulativeInterestEarned: Value
    public var cumulativeRewardEarned: Value

    public let name: String
    public let symbol: String
    public let underlyingAssetSymbol: String
    public let decimals: Int

    public init(name: String, symbol: String, decimals: Int, underlyingAssetSymbol: String? = nil) {
        assets = []
        baseAssets = []
        collateralAssets = []
        rewardAssets = []
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.underlyingAssetSymbol = underlyingAssetSymbol ?? symbol
        realizedPnL = .init(profit: .zero, loss: .zero)
        realizedInterestPnL = .init(profit: .zero, loss: .zero)
        realizedRewardPnL = .init(profit: .zero, loss: .zero)
        unrealizedPnL = .init(profit: .zero, loss: .zero)
        averageCostPosition = .init(quantity: Amount(0, decimals: decimals), averageCost: .zero)
        cumulativeInterestEarned = .zero
        cumulativeRewardEarned = .zero
    }

    public var mainAsset: Asset? {
        let sortedChains = assets.map(\.chain).sortedByPriority()
        let sortedAssets =
            assets
            .filter { sortedChains.contains($0.chain) }
            .sorted {
                sortedChains.firstIndex(of: $0.chain)! < sortedChains.firstIndex(of: $1.chain)!
            }

        return sortedAssets.first
    }

    public var isSingleChainAsset: Bool {
        assets.count == 1
    }

    public var price: Value {
        mainAsset.map { $0.price } ?? assets.first.map { $0.price }!
    }

    public var balance: Amount {
        assets.reduce(Amount(0, decimals: decimals)) { $0 + $1.balance }
    }

    public var balanceValue: Value {
        assets.reduce(Value(0)) { $0 + $1.balanceValue }
    }

    public var earningBalance: Amount {
        baseAssets.reduce(Amount(0, decimals: decimals)) { $0 + $1.marketBalance }
    }

    public var earningBalanceValue: Value {
        baseAssets.reduce(Value(0)) { $0 + $1.marketBalanceValue }
    }

    public var earningApr: Percentage {
        if earningBalance.isZero {
            return .zero
        }

        return
            baseAssets
            .map { $0.marketBalanceValue.percentageOf(earningBalanceValue) * $0.earnApr }
            .sum()
    }

    public var earningRewardsApr: Percentage {
        if earningBalance.isZero {
            return .zero
        }

        return
            baseAssets
            .map { $0.marketBalanceValue.percentageOf(earningBalanceValue) * $0.earnRewardsApr }
            .sum()
    }

    public var netEarningApr: Percentage {
        earningApr + earningRewardsApr
    }

    public var weightedEarningApr: Percentage {
        earningBalanceValue.percentageOf(fullBalanceValue) * earningApr
    }

    public var collateralBalance: Amount {
        collateralAssets.reduce(Amount(0, decimals: decimals)) { $0 + $1.marketBalance }
    }

    public var collateralBalanceValue: Value {
        collateralAssets.reduce(Value(0)) { $0 + $1.marketBalanceValue }
    }

    public var rewardOwed: Amount {
        rewardAssets.reduce(Amount(0, decimals: decimals)) { $0 + $1.rewardOwed }
    }

    public var rewardOwedValue: Value {
        rewardAssets.reduce(Value(0)) { $0 + $1.rewardOwedValue }
    }

    public var claimableRewardOwed: Amount {
        rewardAssets.reduce(Amount(0, decimals: decimals)) { $0 + $1.claimableRewardOwed }
    }

    public var claimableRewardOwedValue: Value {
        rewardAssets.reduce(Value(0)) { $0 + $1.claimableRewardOwedValue }
    }

    public var accessibleBalance: Amount {
        balance + earningBalance
    }

    public var accessibleBalanceValue: Value {
        balanceValue + earningBalanceValue
    }

    /// Amount available to be supplied into the specified market. This excludes the earning balance
    /// in the specified market
    public func suppliableBalance(for market: EarnMarket) -> Amount {
        accessibleBalance - market.baseAsset.marketBalance
    }

    public func suppliableBalanceValue(for market: EarnMarket) -> Value {
        accessibleBalanceValue - market.baseAsset.marketBalanceValue
    }

    public var fullBalance: Amount {
        balance + earningBalance + collateralBalance + rewardOwed
    }

    public var fullBalanceValue: Value {
        balanceValue + earningBalanceValue + collateralBalanceValue + rewardOwedValue
    }

    public var networks: [Network] {
        assets.map(\.chain).sortedByPriority()
    }

    public func balanceForNetwork(_ network: Network) -> Amount {
        assets.filter { $0.chain == network }.map { $0.balance }.sum(decimals: decimals)
    }

    public func fullBalanceForNetwork(_ network: Network) -> Amount {
        func isSameNetwork<T: AssetProtocol>(asset: T) -> Bool { asset.chain == network }

        let balance = assets.filter(isSameNetwork).map { $0.balance }.sum(decimals: decimals)
        let earningBalance = baseAssets.filter(isSameNetwork).map { $0.marketBalance }
            .sum(
                decimals: decimals
            )
        let collateralBalance = collateralAssets.filter(isSameNetwork).map { $0.marketBalance }
            .sum(
                decimals: decimals
            )
        let rewardBalance = rewardAssets.filter(isSameNetwork).map { $0.rewardOwed }
            .sum(
                decimals: decimals
            )

        return balance + earningBalance + collateralBalance + rewardBalance
    }

    public var unrealizedProfitAndLossNumberFormatted: String {
        if unrealizedPnL.loss <= unrealizedPnL.profit {
            return "↗ \(unrealizedPnL.profit.formatted())"
        } else {
            return "↘ \(unrealizedPnL.loss.formatted())"
        }
    }

    public var unrealizedProfitAndLossPercentage: Percentage {
        let totalValue = averageCostPosition.averageCost * averageCostPosition.quantity
        if unrealizedPnL.loss <= unrealizedPnL.profit {
            return Percentage(
                (unrealizedPnL.profit - unrealizedPnL.loss).percentageOf(totalValue).underlying
            )
        } else {
            return Percentage(
                -(unrealizedPnL.loss - unrealizedPnL.profit).percentageOf(totalValue).underlying
            )
        }
    }
}

extension Array where Element: ChainAgnosticAssetProtocol {
    public func sortedByDescendingValue() -> [Element] {
        sorted { $0.balanceValue > $1.balanceValue }
    }
}

extension Array where Element: AssetProtocol {
    public func sortedByAscendingPrice() -> [Element] {
        sorted { $0.price < $1.price }
    }
}

extension Array where Element == MetaAsset {
    public var hasBalance: Bool {
        contains(where: { !$0.fullBalance.isZero })
    }

    public func sortedAlphabetically() -> [Element] {
        sorted { $0.displayName < $1.displayName }
    }

    public func getMetaAsset(symbol: String) -> MetaAsset? {
        first { $0.symbol.equalIgnoringCase(symbol) }
    }
}

public protocol DAppedUp {
    var dApp: DApp { get }
}

public protocol MarketAssetProtocol: AssetProtocol, DAppedUp {
    var marketBalance: Amount { get }
    var marketBalanceValue: Value { get }
}

extension MarketAssetProtocol {
    public var marketBalanceValue: Value {
        marketBalance * price
    }
}

public struct BaseAsset: MarketAssetProtocol, Equatable {
    public var id: EthAddress {
        address
    }

    public let address: EthAddress
    public let chain: Network
    public let dApp: DApp
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let price: Value
    public let balances: [Asset.Balance]
    public let marketBalances: [Asset.Balance]
    public let earnApr: Percentage
    public let earnRewardsApr: Percentage

    public init(
        address: EthAddress,
        chain: Network,
        dApp: DApp,
        name: String,
        symbol: String,
        decimals: Int,
        price: Value,
        balances: [Asset.Balance],
        marketBalances: [Asset.Balance],
        earnApr: Percentage,
        earnRewardsApr: Percentage
    ) {
        self.address = address
        self.chain = chain
        self.dApp = dApp
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.price = price
        self.balances = balances
        self.marketBalances = marketBalances
        self.earnApr = earnApr
        self.earnRewardsApr = earnRewardsApr
    }

    public var balance: Amount {
        balances.map { $0.balance }.sum(decimals: decimals)
    }

    public var marketBalance: Amount {
        marketBalances.map { $0.balance }.sum(decimals: decimals)
    }
}

public struct CollateralAsset: MarketAssetProtocol, Equatable {
    public var id: EthAddress {
        address
    }

    public let address: EthAddress
    public let chain: Network
    public let dApp: DApp
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let price: Value
    public let balances: [Asset.Balance]
    public let marketBalances: [Asset.Balance]
    public let borrowCollateralFactor: Percentage
    public let liquidateCollateralFactor: Percentage
    public let supplyCap: Amount

    public init(
        address: EthAddress,
        chain: Network,
        dApp: DApp,
        name: String,
        symbol: String,
        decimals: Int,
        price: Value,
        balances: [Asset.Balance],
        marketBalances: [Asset.Balance],
        borrowCollateralFactor: Percentage,
        liquidateCollateralFactor: Percentage,
        supplyCap: Amount
    ) {
        self.address = address
        self.chain = chain
        self.dApp = dApp
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.price = price
        self.balances = balances
        self.marketBalances = marketBalances
        self.borrowCollateralFactor = borrowCollateralFactor
        self.liquidateCollateralFactor = liquidateCollateralFactor
        self.supplyCap = supplyCap
    }

    public var balance: Amount {
        balances.map { $0.balance }.sum(decimals: decimals)
    }

    public var marketBalance: Amount {
        marketBalances.map { $0.balance }.sum(decimals: decimals)
    }

    public var loopFactor: Percentage {
        Percentage(double: 1.0) / (Percentage(double: 1.0) - borrowCollateralFactor)
    }

    public var balanceBorrowValue: Value {
        balanceValue * borrowCollateralFactor
    }

    public var balanceLiquidationValue: Value {
        balanceValue * liquidateCollateralFactor
    }

    public var cometBalanceBorrowValue: Value {
        marketBalanceValue * borrowCollateralFactor
    }

    public var cometBalanceLiquidationValue: Value {
        marketBalanceValue * liquidateCollateralFactor
    }
}

extension Array where Element == CollateralAsset {
    public var justActiveCollateral: [CollateralAsset] {
        filter { !$0.marketBalance.isZero }
    }

    public func sortedByBalanceValue() -> [CollateralAsset] {
        sorted { $0.balanceValue > $1.balanceValue }
    }

    public func sortedByMarketBalalnceValue() -> [CollateralAsset] {
        sorted { $0.marketBalanceValue > $1.marketBalanceValue }
    }
}

public struct RewardAsset: AssetProtocol, DAppedUp {
    public var id: EthAddress {
        address
    }

    public let address: EthAddress
    public let chain: Network
    public let dApp: DApp
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let price: Value
    public let balances: [Asset.Balance]
    public let rewardAddress: EthAddress
    public let rewardOwed: Amount
    public let claimableRewardOwed: Amount
    public let borrowRewardsApr: Percentage
    public let supplyRewardsApr: Percentage

    public init(
        address: EthAddress,
        chain: Network,
        dApp: DApp,
        name: String,
        symbol: String,
        decimals: Int,
        price: Value,
        balances: [Asset.Balance],
        rewardAddress: EthAddress,
        rewardOwed: Amount,
        claimableRewardOwed: Amount,
        borrowRewardsApr: Percentage,
        supplyRewardsApr: Percentage
    ) {
        self.address = address
        self.chain = chain
        self.dApp = dApp
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.price = price
        self.balances = balances
        self.rewardAddress = rewardAddress
        self.rewardOwed = rewardOwed
        self.claimableRewardOwed = claimableRewardOwed
        self.borrowRewardsApr = borrowRewardsApr
        self.supplyRewardsApr = supplyRewardsApr
    }

    public var balance: Amount {
        balances.map { $0.balance }.sum(decimals: decimals)
    }

    public var rewardOwedValue: Value {
        rewardOwed * price
    }

    public var claimableRewardOwedValue: Value {
        claimableRewardOwed * price
    }
}
