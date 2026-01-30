import Eth
import Foundation
import Prelude
import SwiftNumber

extension Portfolio: Identifiable {
    public var id: Network {
        chain
    }

    public static func patchPortfolio(
        portfolio: Portfolio,
        wallets: [Portfolio.Wallet]? = nil,
        block: Portfolio.Block? = nil,
        chainId: UInt? = nil,
        aaves: [Portfolio.Aave]? = nil,
        comets: [Portfolio.Comet]? = nil,
        morphos: [Portfolio.Morpho]? = nil,
        morphoVaults: [Portfolio.MorphoVault]? = nil,
        queryVersion: Portfolio.QueryVersion? = nil,
        tokens: [Portfolio.Token]? = nil,
        morphoRewardPositions: [Portfolio.MorphoRewardPosition]? = nil,
        quarkNonceStatuses: [Portfolio.QuarkNonceStatus]? = nil,
        acrossFillStatuses: [Portfolio.AcrossFillStatus]? = nil,
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]? = nil
    ) -> Portfolio {
        Portfolio(
            wallets: wallets ?? portfolio.wallets,
            block: block ?? portfolio.block,
            chainId: chainId ?? portfolio.chainId,
            aaves: aaves ?? portfolio.aaves,
            comets: comets ?? portfolio.comets,
            morphos: morphos ?? portfolio.morphos,
            morphoVaults: morphoVaults ?? portfolio.morphoVaults,
            queryVersion: queryVersion ?? portfolio.queryVersion,
            tokens: tokens ?? portfolio.tokens,
            morphoRewardPositions: morphoRewardPositions ?? portfolio.morphoRewardPositions,
            quarkNonceStatuses: quarkNonceStatuses ?? portfolio.quarkNonceStatuses,
            acrossFillStatuses: acrossFillStatuses ?? portfolio.acrossFillStatuses,
            tokenWrapperQuotes: tokenWrapperQuotes ?? portfolio.tokenWrapperQuotes
        )
    }

    // MARK: Helpers

    internal static func tokenToAsset(
        chain: Network,
        token: Portfolio.Token,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> Asset {
        var underlyingAsset: Asset.UnderlyingAsset? = nil
        if let tokenWrapperQuote = tokenWrapperQuotes.first(where: {
            $0.wrapped.address == token.address
        }), let underlyingName = tokenWrapperQuote.underlying.name,
            let underlyingDecimals = tokenWrapperQuote.underlying.decimals
        {
            underlyingAsset = Asset.UnderlyingAsset(
                address: tokenWrapperQuote.underlying.address,
                name: underlyingName,
                symbol: tokenWrapperQuote.underlying.symbol,
                decimals: underlyingDecimals,
                unwrapQuote: tokenWrapperQuote.unwrapQuote
            )
        }

        return Asset(
            address: token.address,
            chain: chain,
            name: token.name,
            symbol: token.symbol,
            decimals: token.decimals,
            price: token.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            underlyingAsset: underlyingAsset
        )
    }

    /// Handle wrapped asset balances
    private static func getAssetBalances(
        token: Portfolio.Token,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [Asset.Balance] {
        func getBalances(token: Portfolio.Token, underlyingToken: Portfolio.Token) -> [Asset
            .Balance]
        {
            token.balances.map { balance in
                let underlyingBalance =
                    underlyingToken.balances.first { $0.wallet == balance.wallet }?.balance
                    ?? Amount(0, decimals: token.decimals)

                return .init(
                    wallet: balance.wallet,
                    balance: balance.balance,
                    underlyingAssetBalance: underlyingBalance
                )
            }
        }

        // TODO: This will be updated to utilize Atlas
        if let tokenWrapperQuote = getTokenWrapperQuote(
            token: token,
            tokenWrapperQuotes: tokenWrapperQuotes
        ) {
            if let underlyingToken = tokens.first(where: {
                $0.symbol == tokenWrapperQuote.underlying.symbol
            }) {
                return token.balances.map { balance in
                    let underlyingBalance =
                        underlyingToken.balances.first { $0.wallet == balance.wallet }?.balance
                        ?? Amount(0, decimals: token.decimals)

                    return .init(
                        wallet: balance.wallet,
                        balance: balance.balance,
                        underlyingAssetBalance: underlyingBalance
                    )
                }
            }
        } else if token.symbol == "WETH" {
            if let underlyingToken = tokens.first(where: { $0.symbol == "ETH" }) {
                return getBalances(token: token, underlyingToken: underlyingToken)
            }
        } else if token.symbol == "WPOL" {
            if let underlyingToken = tokens.first(where: { $0.symbol == "POL" }) {
                return getBalances(token: token, underlyingToken: underlyingToken)
            }
        } else if token.symbol == "WHYPE" {
            if let underlyingToken = tokens.first(where: { $0.symbol == "HYPE" }) {
                return getBalances(token: token, underlyingToken: underlyingToken)
            }
        }

        return token.balances.map {
            .init(
                wallet: $0.wallet,
                balance: $0.balance
            )
        }
    }

    private static func getTokenWrapperQuote(
        token: Portfolio.Token,
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> Portfolio.TokenWrapperQuote? {
        tokenWrapperQuotes.first {
            $0.wrapped.symbol == token.symbol
        }
    }

    internal static func cometToBaseAsset(
        chain: Network,
        comet: Portfolio.Comet,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> BaseAsset? {
        let base = comet.base

        guard let token = tokens.first(where: { $0.symbol == base.symbol }) else {
            Logger.error("Could not find the associated token for base \(base.symbol)")
            return nil
        }

        return BaseAsset(
            address: base.address,
            chain: chain,
            dApp: .Compound,
            name: base.name,
            symbol: base.symbol,
            decimals: base.decimals,
            price: base.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            marketBalances: base.positions.map {
                .init(
                    wallet: $0.wallet,
                    balance: $0.supply
                )
            },
            earnApr: comet.supplyApr,
            earnRewardsApr: comet.supplyRewardsApr
        )
    }

    internal static func cometCollateralToCollateralAsset(
        chain: Network,
        collateral: Portfolio.Comet.Collateral,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> CollateralAsset? {
        guard let token = tokens.first(where: { $0.symbol == collateral.symbol }) else {
            Logger.error("Could not find the associated token for collateral \(collateral.symbol)")
            return nil
        }

        return CollateralAsset(
            address: collateral.address,
            chain: chain,
            dApp: .Compound,
            name: collateral.name,
            symbol: collateral.symbol,
            decimals: collateral.decimals,
            price: collateral.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            marketBalances: collateral.cometBalances.map {
                .init(
                    wallet: $0.wallet,
                    balance: $0.balance
                )
            },
            borrowCollateralFactor: collateral.borrowCollateralFactor,
            liquidateCollateralFactor: collateral.liquidateCollateralFactor,
            supplyCap: collateral.supplyCap
        )
    }

    internal static func cometToRewardAsset(
        chain: Network,
        comet: Portfolio.Comet,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> RewardAsset? {
        guard let reward = comet.reward else {
            return nil
        }

        guard let token = tokens.first(where: { $0.symbol == reward.symbol }) else {
            Logger.error("Could not find the associated token for reward \(reward.symbol)")
            return nil
        }

        return RewardAsset(
            address: reward.address,
            chain: chain,
            dApp: .Compound,
            name: reward.name,
            symbol: reward.symbol,
            decimals: reward.decimals,
            price: reward.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            rewardAddress: reward.rewardsAddress,
            rewardOwed: reward.rewardOwed,
            claimableRewardOwed: reward.rewardOwed,
            borrowRewardsApr: comet.borrowRewardsApr,
            supplyRewardsApr: comet.supplyRewardsApr
        )
    }

    internal static func morphoMarketLoanAssetToBaseAsset(
        chain: Network,
        loanAsset: Portfolio.Morpho.LoanAsset,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> BaseAsset? {
        guard let token = tokens.first(where: { $0.symbol == loanAsset.symbol }) else {
            Logger.error("Could not find the associated token for \(loanAsset.symbol)")
            return nil
        }

        return BaseAsset(
            address: loanAsset.address,
            chain: chain,
            dApp: .Morpho,
            name: loanAsset.name,
            symbol: loanAsset.symbol,
            decimals: loanAsset.decimals,
            price: loanAsset.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            // The user never supplies loan asset into a morpho market
            marketBalances: token.balances.map {
                .init(
                    wallet: $0.wallet,
                    balance: Amount(0, decimals: loanAsset.decimals)
                )
            },
            earnApr: .zero,
            earnRewardsApr: .zero
        )
    }

    internal static func morphoMarketToCollateralAsset(
        chain: Network,
        morpho: Portfolio.Morpho,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> CollateralAsset? {
        let collateral = morpho.collateralAsset
        guard let token = tokens.first(where: { $0.symbol == collateral.symbol }) else {
            Logger.error("Could not find the associated token for collateral \(collateral.symbol)")
            return nil
        }

        return CollateralAsset(
            address: collateral.address,
            chain: chain,
            dApp: .Morpho,
            name: collateral.name,
            symbol: collateral.symbol,
            decimals: collateral.decimals,
            price: collateral.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            marketBalances: collateral.balances.map {
                .init(
                    wallet: $0.wallet,
                    balance: $0.balance
                )
            },
            borrowCollateralFactor: morpho.liquidationLoanToValue,
            liquidateCollateralFactor: morpho.liquidationLoanToValue,
            supplyCap: .init(Number.MAX_UINT_256, decimals: collateral.decimals)
        )
    }

    internal static func morphoRewardToRewardAsset(
        chain: Network,
        marketId: Hex,
        reward: Portfolio.Morpho.BorrowReward,
        morphoRewardPositions: [Portfolio.MorphoRewardPosition],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> RewardAsset? {
        guard let token = tokens.first(where: { $0.symbol == reward.symbol }) else {
            Logger.error("Could not find the associated token for morpho reward \(reward.symbol)")
            return nil
        }

        func reduceRewards(
            reducer: (Amount, Portfolio.MorphoRewardPosition.MarketReward) -> Amount
        ) -> Amount {
            morphoRewardPositions.compactMap { rewardPosition -> Amount? in
                guard rewardPosition.asset.address == token.address else {
                    return nil
                }

                return rewardPosition
                    .marketRewards
                    .filter { $0.marketId == marketId }
                    .reduce(Amount(0, decimals: token.decimals), reducer)
            }
            .sum(decimals: token.decimals)
        }

        let rewardOwed = reduceRewards { acc, curr in
            acc + curr.total - curr.claimed
        }
        let claimableRewardOwed = reduceRewards { acc, curr in
            acc + curr.claimableNow
        }

        return RewardAsset(
            address: token.address,
            chain: chain,
            dApp: .Morpho,
            name: token.name,
            symbol: token.symbol,
            decimals: token.decimals,
            price: token.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            rewardAddress: reward.address,
            rewardOwed: rewardOwed,
            claimableRewardOwed: claimableRewardOwed,
            borrowRewardsApr: reward.rewardApr,
            supplyRewardsApr: .zero
        )
    }

    internal static func morphoVaultToBaseAsset(
        chain: Network,
        morphoVault: Portfolio.MorphoVault,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> BaseAsset? {
        let loanAsset = morphoVault.loanAsset
        guard let token = tokens.first(where: { $0.symbol == loanAsset.symbol }) else {
            Logger.error("Could not find the associated token for \(loanAsset.symbol)")
            return nil
        }

        return BaseAsset(
            address: loanAsset.address,
            chain: chain,
            dApp: .Morpho,
            name: loanAsset.name,
            symbol: loanAsset.symbol,
            decimals: loanAsset.decimals,
            price: loanAsset.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            marketBalances: loanAsset.positions.map {
                .init(
                    wallet: $0.wallet,
                    balance: $0.supply
                )
            },
            earnApr: morphoVault.supplyApr,
            earnRewardsApr: morphoVault.supplyRewards.map { $0.rewardApr }.sum()
        )
    }

    internal static func morphoVaultRewardToRewardAsset(
        chain: Network,
        vault: EthAddress,
        reward: Portfolio.MorphoVault.SupplyReward,
        morphoRewardPositions: [Portfolio.MorphoRewardPosition],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> RewardAsset? {
        guard let token = tokens.first(where: { $0.symbol == reward.symbol }) else {
            Logger.error(
                "Could not find the associated token for morpho vault reward \(reward.symbol)"
            )
            return nil
        }

        func reduceRewards(
            reducer: (Amount, Portfolio.MorphoRewardPosition.VaultReward) -> Amount
        ) -> Amount {
            morphoRewardPositions.compactMap { rewardPosition -> Amount? in
                guard rewardPosition.asset.address == token.address else {
                    return nil
                }

                return rewardPosition
                    .vaultRewards
                    .filter { $0.vault == vault }
                    .reduce(Amount(0, decimals: token.decimals), reducer)
            }
            .sum(decimals: token.decimals)
        }

        let rewardOwed = reduceRewards { acc, curr in
            acc + curr.total - curr.claimed
        }
        let claimableRewardOwed = reduceRewards { acc, curr in
            acc + curr.claimableNow
        }

        return RewardAsset(
            address: token.address,
            chain: chain,
            dApp: .Morpho,
            name: token.name,
            symbol: token.symbol,
            decimals: token.decimals,
            price: token.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            rewardAddress: reward.address,
            rewardOwed: rewardOwed,
            claimableRewardOwed: claimableRewardOwed,
            borrowRewardsApr: .zero,
            supplyRewardsApr: reward.rewardApr
        )
    }
}
