import Eth
import Foundation
import Prelude
import SwiftNumber

extension Array where Element == Portfolio {
    /// Balance + Comet balances of base assets + Comet balances of collaterals + Reward Owed - Liabilities
    public var nav: Value {
        let balanceTotal =
            Portfolio
            .getMetaAssets(portfolios: self, loopPositions: [])
            .map(\.fullBalanceValue)
            .sum()

        let liabilities = reduce(into: Value(0)) { accum, portfolio in
            accum += portfolio
                .borrowMarkets
                .reduce(into: Value(0)) { accum, borrowMarket in
                    accum += borrowMarket.userBorrowValue
                }
        }

        return balanceTotal - liabilities
    }

    public var cometMarkets: [CometMarket] {
        flatMap { $0.cometMarkets }
    }

    public var morphomarkets: [MorphoMarket] {
        flatMap { $0.morphoMarkets }
    }

    public var morphoVaultMarkets: [MorphoVaultMarket] {
        flatMap { $0.morphoVaultMarkets }
    }

    public var borrowMarkets: [BorrowMarket] {
        flatMap { $0.borrowMarkets }
    }

    public var earnMarkets: [EarnMarket] {
        flatMap { $0.earnMarkets }
    }

    public var longMarkets: [MorphoMarket] {
        borrowMarkets.compactMap {
            switch $0 {
                case .morphoMarket(let market):
                    // Hardcoded loop asset support for highly liquid assets
                    let supportedAssetNetworkPairs: [(String, Network)] = [
                        ("WETH", .base),
                        ("cbBTC", .base),
                        ("WLD", .worldChain),
                    ]

                    func isSupportedMarket(_ market: MorphoMarket) -> Bool {
                        supportedAssetNetworkPairs.contains { symbol, network in
                            market.collateralAsset.symbol == symbol && market.chain == network
                        }
                    }

                    guard isSupportedMarket(market) else {
                        return nil
                    }

                    guard market.baseAsset.isUsdc else {
                        return nil
                    }

                    return market
                default:
                    return nil
            }
        }
    }

    public func longMarkets(assetSymbol: String) -> [MorphoMarket] {
        longMarkets.filter { $0.collateralAsset.symbol == assetSymbol }
    }

    public var shortMarkets: [MorphoMarket] {
        borrowMarkets.compactMap {
            switch $0 {
                case .morphoMarket(let market): market.collateralAsset.isUsdc ? market : nil
                default: nil
            }
        }
    }

    public func shortMarkets(assetSymbol: String) -> [MorphoMarket] {
        shortMarkets.filter { $0.baseAsset.symbol == assetSymbol }
    }

    public var loopMarkets: [MorphoMarket] {
        longMarkets + shortMarkets
    }

    public func loopMarkets(assetSymbol: String) -> [MorphoMarket] {
        longMarkets(assetSymbol: assetSymbol) + shortMarkets(assetSymbol: assetSymbol)
    }

    public var maxEarnApr: Percentage? {
        earnMarkets.maxEarnApr
    }

    public var minBorrowApr: Percentage? {
        borrowMarkets.minBorrowApr
    }

    public func maxEarnApr(assetSymbol: String) -> Percentage? {
        earnMarkets.filter { $0.baseAsset.symbol == assetSymbol }.maxEarnApr
    }

    public func minBorrowApr(assetSymbol: String) -> Percentage? {
        borrowMarkets.filter { $0.baseAsset.symbol == assetSymbol }.minBorrowApr
    }

    public func borrowMarketsByBaseMetaAsset(metaAssets: [MetaAsset]) -> [MetaAsset: [BorrowMarket]]
    {
        borrowMarkets.marketsByBaseMetaAsset(metaAssets: metaAssets)
    }

    public func earnMarketsByBaseMetaAsset(metaAssets: [MetaAsset]) -> [MetaAsset: [EarnMarket]] {
        earnMarkets.marketsByBaseMetaAsset(metaAssets: metaAssets)
    }

    private func getMaxLoopFactor(_ morphoMarkets: [MorphoMarket]) -> Percentage {
        morphoMarkets
            .max { $0.collateralAsset.loopFactor < $1.collateralAsset.loopFactor }
            .map(\.collateralAsset.loopFactor)
            ?? .zero
    }

    public var maxLongFactor: Percentage {
        getMaxLoopFactor(longMarkets)
    }

    public var maxShortFactor: Percentage {
        getMaxLoopFactor(shortMarkets)
    }

    public func maxLongFactor(assetSymbol: String) -> Percentage {
        getMaxLoopFactor(longMarkets(assetSymbol: assetSymbol))
    }

    public func maxShortFactor(assetSymbol: String) -> Percentage {
        getMaxLoopFactor(shortMarkets(assetSymbol: assetSymbol))
    }

    public func getCometMarkets(baseAssetSymbol: String) -> [CometMarket] {
        cometMarkets
            .filter { $0.baseAsset.symbol.equalIgnoringCase(baseAssetSymbol) }
    }

    public func getCometMarkets(collateralAssetSymbol: String) -> [CometMarket] {
        cometMarkets
            .filter { cometMarket in
                cometMarket.collateralAssets.contains { collateralAsset in
                    collateralAsset.symbol.equalIgnoringCase(collateralAssetSymbol)
                }
            }
    }

    public func getCometMarkets(rewardAssetSymbol: String) -> [CometMarket] {
        cometMarkets
            .filter { $0.hasRewardAsset(symbol: rewardAssetSymbol) }
    }

    public func getBorrowMarket(id: MarketIdentifier) -> BorrowMarket? {
        return borrowMarkets.first { $0.id == id }
    }

    public func getBorrowMarkets(baseAssetSymbol: String) -> [BorrowMarket] {
        borrowMarkets
            .filter { $0.baseAsset.symbol.equalIgnoringCase(baseAssetSymbol) }
    }

    public func getBorrowMarkets(collateralAssetSymbol: String) -> [BorrowMarket] {
        borrowMarkets
            .filter { borrowMarket in
                borrowMarket.collateralAssets.contains { collateralAsset in
                    collateralAsset.symbol.equalIgnoringCase(collateralAssetSymbol)
                }
            }
    }

    public func getBorrowMarkets(rewardAssetSymbol: String) -> [BorrowMarket] {
        borrowMarkets
            .filter { $0.hasRewardAsset(symbol: rewardAssetSymbol) }
    }

    public func getBorrowMarketsWithBorrowBalance() -> [BorrowMarket] {
        borrowMarkets.marketsWithBorrowBalance
    }

    public func getBorrowMarketsWithBorrowCapacity() -> [BorrowMarket] {
        borrowMarkets.marketsWithBorrowCapacity
    }

    public func getEarnMarket(id: MarketIdentifier) -> EarnMarket? {
        earnMarkets.first { $0.id == id }
    }

    public func getEarnMarkets(baseAssetSymbol: String) -> [EarnMarket] {
        earnMarkets
            .filter { $0.baseAsset.symbol.equalIgnoringCase(baseAssetSymbol) }
    }

    public func getEarnMarkets(rewardAssetSymbol: String) -> [EarnMarket] {
        earnMarkets
            .filter { $0.hasRewardAsset(symbol: rewardAssetSymbol) }
    }

    public func getMarkets(rewardAssetSymbol: String) -> [Market] {
        let borrowMarkets = getBorrowMarkets(rewardAssetSymbol: rewardAssetSymbol)
        let earnMarkets = getEarnMarkets(rewardAssetSymbol: rewardAssetSymbol)
        let allMarkets: [Market] =
            borrowMarkets.map { .borrowMarket($0) } + earnMarkets.map { .earnMarket($0) }

        return allMarkets
    }

    public func getAsset(token: EthAddress, chain: Network) -> Asset? {
        first { $0.chain == chain }?.assets.first { $0.address == token }
    }

    public func getAsset(symbol: String, chain: Network) -> Asset? {
        first { $0.chain == chain }?.assets.first { $0.symbol.equalIgnoringCase(symbol) }
    }

    public var latestBlockTimestamp: TimeInterval {
        map { TimeInterval($0.block.timestamp) }.max() ?? 0
    }
}
