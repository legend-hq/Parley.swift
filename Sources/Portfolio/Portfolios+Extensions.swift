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
        if let asset = first(where: { $0.chain == chain })?.assets.first(where: { $0.address == token }) {
            return asset
        }

        // Native ETH (0xEeee...EEeE) is not stored directly in portfolio assets because it's
        // an underlying asset of WETH. Fall back to WETH lookup for native ETH addresses.
        if token.hex.lowercased() == "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee" {
            return getAsset(symbol: "WETH", chain: chain)
        }

        // Native POL is an underlying asset of WPOL. Fall back to WPOL lookup.
        if token.hex.lowercased() == "0x0000000000000000000000000000000000001010" {
            return getAsset(symbol: "WPOL", chain: chain)
        }

        // Native HYPE is an underlying asset of WHYPE. Fall back to WHYPE lookup.
        if token.hex.lowercased() == "0x000000000000000000000000000000000000b49e" {
            return getAsset(symbol: "WHYPE", chain: chain)
        }

        return nil
    }

    public func getAsset(symbol: String, chain: Network) -> Asset? {
        first { $0.chain == chain }?.assets.first { $0.symbol.equalIgnoringCase(symbol) }
    }

    public var latestBlockTimestamp: TimeInterval {
        map { TimeInterval($0.block.timestamp) }.max() ?? 0
    }

    // MARK: - Claimable Rewards

    /// A key for deduplicating rewards by (symbol, chain).
    /// ClaimRewardsIntent claims by symbol globally on a chain, so we deduplicate to avoid double-counting.
    private struct RewardKey: Hashable {
        let symbol: String
        let chain: Network
    }

    /// Gathers all claimable rewards across portfolios, deduplicating by (symbol, chain).
    ///
    /// This aggregates rewards from:
    /// - Earn markets (Comet, Morpho vaults)
    /// - Borrow markets (Comet, Morpho)
    /// - Morpho URD uniform rewards (e.g. MORPHO)
    /// - Morpho airdrop rewards (e.g. WLD)
    ///
    /// Use `symbolFilter` to only include rewards for specific symbols (e.g. symbols from USDC earn markets).
    /// When `symbolFilter` is nil, all claimable rewards are returned.
    ///
    /// - Parameter symbolFilter: Optional set of symbols to filter by. If nil, returns all rewards.
    /// - Returns: Array of claimable `RewardAsset` items, deduplicated by (symbol, chain).
    public func getClaimableRewards(symbolFilter: Set<String>? = nil) -> [RewardAsset] {
        var seenRewards: Set<RewardKey> = []
        var rewards: [RewardAsset] = []

        let symbols = symbolFilter ?? Set(
            earnMarkets.flatMap { $0.rewardAssets }.map { $0.symbol }
            + borrowMarkets.flatMap { $0.rewardAssets }.map { $0.symbol }
            + flatMap { $0.uniformRewards }.map { $0.symbol }
            + flatMap { $0.airdropRewards }.map { $0.symbol }
        )

        for symbol in symbols {
            let markets = getMarkets(rewardAssetSymbol: symbol)
            for market in markets {
                switch market {
                case .earnMarket(let earnMarket):
                    for rewardAsset in earnMarket.rewardAssets where rewardAsset.symbol == symbol && !rewardAsset.claimableRewardOwed.isZero {
                        let key = RewardKey(symbol: symbol, chain: earnMarket.chain)
                        guard !seenRewards.contains(key) else { continue }
                        seenRewards.insert(key)
                        rewards.append(rewardAsset)
                    }
                case .borrowMarket(let borrowMarket):
                    for rewardAsset in borrowMarket.rewardAssets where rewardAsset.symbol == symbol && !rewardAsset.claimableRewardOwed.isZero {
                        let key = RewardKey(symbol: symbol, chain: borrowMarket.chain)
                        guard !seenRewards.contains(key) else { continue }
                        seenRewards.insert(key)
                        rewards.append(rewardAsset)
                    }
                }
            }
        }

        for portfolio in self {
            for uniformReward in portfolio.uniformRewards where symbols.contains(uniformReward.symbol) && !uniformReward.claimableRewardOwed.isZero {
                let key = RewardKey(symbol: uniformReward.symbol, chain: portfolio.chain)
                guard !seenRewards.contains(key) else { continue }
                seenRewards.insert(key)
                rewards.append(uniformReward)
            }

            for airdropReward in portfolio.airdropRewards where symbols.contains(airdropReward.symbol) && !airdropReward.claimableRewardOwed.isZero {
                let key = RewardKey(symbol: airdropReward.symbol, chain: portfolio.chain)
                guard !seenRewards.contains(key) else { continue }
                seenRewards.insert(key)
                rewards.append(airdropReward)
            }
        }

        return rewards
    }

    /// Returns the total claimable reward value across all portfolios for the given symbols.
    ///
    /// - Parameter symbolFilter: Optional set of symbols to filter by. If nil, returns total for all rewards.
    /// - Returns: The sum of all claimable reward values.
    public func getTotalClaimableRewardValue(symbolFilter: Set<String>? = nil) -> Value {
        getClaimableRewards(symbolFilter: symbolFilter)
            .reduce(Value.zero) { $0 + $1.claimableRewardOwedValue }
    }
}
