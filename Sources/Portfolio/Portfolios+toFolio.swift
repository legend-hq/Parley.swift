import Atlas
import Eth
import Prelude
import SwiftNumber

extension Array where Element == Portfolio {
    public func toFolio(
        quote: Quote,
        bridgeHints: [LegendModel.BridgeHint],
        prices: [String: Value],
        nonceSecrets: [NonceSecret]
    ) -> Folio {
        var folio = Folio()

        for (symbol, price) in prices {
            folio.prices.updateValue(price, forKey: .token(symbol: symbol))
        }

        for portfolio in self {
            let network = Network.fromChainId(portfolio.chainId)

            for token in portfolio.tokens {
                // Token Balances
                for balance in token.balances {
                    if !balance.balance.isZero {
                        folio.balances.updateValue(
                            balance.balance,
                            forKey: .token(
                                network: network,
                                symbol: token.symbol,
                                wallet: balance.wallet
                            )
                        )
                    }
                }

                // Aave Supply Balances
                for aave in portfolio.aaves {
                    for asset in aave.assets {
                        for position in asset.positions {
                            if !position.supplied.isZero {
                                folio.balances.updateValue(
                                    position.supplied,
                                    forKey: .yieldMarket(
                                        yieldMarket: .aave(
                                            network: network,
                                            pool: aave.pool,
                                            underlyingSymbol: asset.symbol
                                        ),
                                        wallet: position.wallet
                                    )
                                )
                            }
                        }
                    }
                }

                // Comet Supply, Borrow and Collateral Balances
                for comet in portfolio.comets {
                    for position in comet.base.positions {
                        if !position.supply.isZero {
                            folio.balances.updateValue(
                                position.supply,
                                forKey: .yieldMarket(
                                    yieldMarket: .comet(
                                        network: network,
                                        comet: comet.address,
                                        underlyingSymbol: comet.base.symbol
                                    ),
                                    wallet: position.wallet
                                )
                            )
                        }

                        if !position.borrow.isZero {
                            folio.balances.updateValue(
                                position.borrow,
                                forKey: .borrowMarket(
                                    borrowMarket: .comet(
                                        network: network,
                                        comet: comet.address,
                                        underlyingSymbol: comet.base.symbol
                                    ),
                                    wallet: position.wallet
                                )
                            )
                        }
                    }

                    for collateral in comet.collaterals {
                        for balance in collateral.cometBalances {
                            if !balance.balance.isZero {
                                folio.balances.updateValue(
                                    balance.balance,
                                    forKey: .borrowMarketCollateral(
                                        borrowMarket: .comet(
                                            network: network,
                                            comet: comet.address,
                                            underlyingSymbol: collateral.symbol
                                        ),
                                        tokenSymbol: collateral.symbol,
                                        wallet: balance.wallet
                                    )
                                )
                            }
                        }
                    }

                    var collateralsDict: [String: Folio.BorrowMarket.Collateral] = [:]
                    for collateral in comet.collaterals {
                        collateralsDict[collateral.symbol] = .init(
                            borrowCollateralFactor: collateral.borrowCollateralFactor,
                            liquidateCollateralFactor: collateral.liquidateCollateralFactor,
                            liquidationFactor: collateral.liquidationFactor,
                            supplyCap: collateral.supplyCap,
                            totalSupply: collateral.totalSupply,
                            usdPrice: collateral.usdPrice
                        )
                    }

                    folio.borrowMarkets.updateValue(
                        .init(
                            baseBorrowMin: comet.base.baseBorrowMin,
                            borrowApr: comet.borrowApr,
                            borrowRewardsApr: comet.borrowRewardsApr,
                            borrowCap: nil,
                            totalBorrow: comet.base.totalBorrow,
                            collaterals: collateralsDict
                        ),
                        forKey: .comet(
                            network: network,
                            comet: comet.address,
                            underlyingSymbol: comet.base.symbol
                        )
                    )

                    if let reward = comet.reward {
                        for position in reward.positions {
                            if !position.rewardOwed.isZero {
                                let rewardKey = Folio.RewardType.cometReward(
                                    network: network,
                                    comet: comet.address,
                                    underlyingSymbol: reward.symbol,
                                    cometRewards: reward.rewardsAddress,
                                    wallet: position.wallet
                                )

                                // Add total reward amount as a balance
                                folio.balances.updateValue(
                                    position.rewardOwed,
                                    forKey: .reward(rewardType: rewardKey)
                                )

                                // Add reward metadata
                                folio.rewards.updateValue(
                                    .init(
                                        proof: .none
                                    ),
                                    forKey: rewardKey
                                )
                            }
                        }
                    }
                }

                for morpho in portfolio.morphos {
                    for position in morpho.loanAsset.positions {
                        if !position.borrow.isZero {
                            folio.balances.updateValue(
                                position.borrow,
                                forKey: .borrowMarket(
                                    borrowMarket: .morpho(
                                        network: network,
                                        collateralTokenSymbol: morpho.collateralAsset.symbol,
                                        borrowTokenSymbol: morpho.loanAsset.symbol
                                    ),
                                    wallet: position.wallet
                                )
                            )
                        }
                    }

                    for balance in morpho.collateralAsset.balances {
                        if !balance.balance.isZero {
                            folio.balances.updateValue(
                                balance.balance,
                                forKey: .borrowMarketCollateral(
                                    borrowMarket: .morpho(
                                        network: network,
                                        collateralTokenSymbol: morpho.collateralAsset.symbol,
                                        borrowTokenSymbol: morpho.loanAsset.symbol
                                    ),
                                    tokenSymbol: morpho.collateralAsset.symbol,
                                    wallet: balance.wallet
                                )
                            )
                        }
                    }

                    let borrowRewardsApr = morpho.borrowRewards.map { $0.rewardApr }
                        .reduce(
                            Percentage.zero,
                            +
                        )

                    folio.borrowMarkets.updateValue(
                        .init(
                            borrowApr: morpho.borrowApr,
                            borrowRewardsApr: borrowRewardsApr,
                            borrowCap: nil,
                            totalBorrow: morpho.loanAsset.totalBorrow,
                            collaterals: [
                                morpho.collateralAsset.symbol: .init(
                                    borrowCollateralFactor: morpho.liquidationLoanToValue,
                                    liquidateCollateralFactor: morpho.liquidationLoanToValue,
                                    liquidationFactor: nil,
                                    supplyCap: nil,
                                    totalSupply: nil,
                                    usdPrice: morpho.collateralAsset.usdPrice
                                )
                            ]
                        ),
                        forKey: .morpho(
                            network: network,
                            collateralTokenSymbol: morpho.collateralAsset.symbol,
                            borrowTokenSymbol: morpho.loanAsset.symbol
                        )
                    )
                }

                for morphoVault in portfolio.morphoVaults {
                    for position in morphoVault.loanAsset.positions {
                        if !position.supply.isZero {
                            folio.balances.updateValue(
                                position.supply,
                                forKey: .yieldMarket(
                                    yieldMarket: .morphoVault(
                                        network: network,
                                        vault: morphoVault.address,
                                        underlyingSymbol: morphoVault.loanAsset.symbol
                                    ),
                                    wallet: position.wallet
                                )
                            )
                        }
                    }

                    let supplyRewardsApr = morphoVault.supplyRewards.map { $0.rewardApr }
                        .reduce(
                            Percentage.zero,
                            +
                        )

                    folio.yieldMarkets.updateValue(
                        .init(
                            supplyApr: morphoVault.supplyApr,
                            supplyRewardsApr: supplyRewardsApr,
                            supplyCap: nil,
                            totalSupply: morphoVault.loanAsset.totalSupply
                        ),
                        forKey: .morphoVault(
                            network: network,
                            vault: morphoVault.address,
                            underlyingSymbol: morphoVault.loanAsset.symbol
                        )
                    )
                }

                // Process Morpho and Merkl rewards
                // Following LegendApp's model:
                // 1. Calculate total claimableNow from all reward types
                // 2. Use this total for each distribution's claimable amount
                // 3. Keep distributions separate with their own proofs
                for morphoRewardPosition in portfolio.morphoRewardPositions {
                    let network = Network.fromChainId(morphoRewardPosition.chainId)
                    let assetDecimals = morphoRewardPosition.asset.decimals

                    // Calculate total claimableNow across ALL reward types (following LegendApp model)
                    let airdropClaimableNow = morphoRewardPosition.airdropRewards
                        .map { $0.claimableNow }
                        .reduce(Amount(Number.zero, decimals: assetDecimals), +)
                    let marketClaimableNow = morphoRewardPosition.marketRewards
                        .map { $0.claimableNow }
                        .reduce(Amount(Number.zero, decimals: assetDecimals), +)
                    let vaultClaimableNow = morphoRewardPosition.vaultRewards
                        .map { $0.claimableNow }
                        .reduce(Amount(Number.zero, decimals: assetDecimals), +)
                    let uniformClaimableNow = morphoRewardPosition.uniformRewards
                        .map { $0.claimableNow }
                        .reduce(Amount(Number.zero, decimals: assetDecimals), +)

                    // Total claimableNow is the sum of all reward types
                    let totalClaimableNow =
                        airdropClaimableNow + marketClaimableNow + vaultClaimableNow
                        + uniformClaimableNow

                    // Calculate total locked (future rewards not yet claimable)
                    let marketClaimableNext = morphoRewardPosition.marketRewards
                        .map { $0.claimableNext }
                        .reduce(Amount(Number.zero, decimals: assetDecimals), +)
                    let vaultClaimableNext = morphoRewardPosition.vaultRewards
                        .map { $0.claimableNext }
                        .reduce(Amount(Number.zero, decimals: assetDecimals), +)
                    let totalLocked = marketClaimableNext + vaultClaimableNext

                    // Process each distribution separately, but use totalClaimableNow for the amount
                    for distribution in morphoRewardPosition.distributions {
                        // Skip if distribution has no claimable amount
                        guard !distribution.claimable.isZero else { continue }

                        let rewardKey = Folio.RewardType.morphoReward(
                            network: network,
                            underlyingSymbol: morphoRewardPosition.asset.symbol,
                            distributor: distribution.distributor,
                            wallet: distribution.account
                        )

                        // Currently claimable amount
                        folio.balances.updateValue(
                            totalClaimableNow,
                            forKey: .reward(rewardType: rewardKey)
                        )

                        // Currently locked amount
                        folio.balances.updateValue(
                            totalLocked,
                            forKey: .lockedReward(rewardType: rewardKey)
                        )

                        // Add reward metadata needed for claiming the rewards
                        folio.rewards.updateValue(
                            .init(
                                proof: .morphoReward(
                                    proof: distribution.proof,
                                    proofAmount: distribution.claimable
                                )
                            ),
                            forKey: rewardKey
                        )
                    }
                }

                for acrossFillStatus in portfolio.acrossFillStatuses {
                    folio.completionStatuses.updateValue(
                        true,
                        forKey: .acrossFill(
                            wallet: acrossFillStatus.quarkWallet,
                            relayHash: acrossFillStatus.relayHash
                        )
                    )
                }

                for cctpV2FillStatus in portfolio.cctpV2FillStatuses {
                    folio.completionStatuses.updateValue(
                        true,
                        forKey: .cctpV2Fill(
                            wallet: cctpV2FillStatus.quarkWallet,
                            nonce: cctpV2FillStatus.nonce
                        )
                    )
                }

                for quarkNonceStatus in portfolio.quarkNonceStatuses {
                    folio.completionStatuses.updateValue(
                        true,
                        forKey: .quarkNonce(
                            wallet: quarkNonceStatus.quarkWallet,
                            nonce: quarkNonceStatus.nonce
                        )
                    )
                }

                for nonceSecret in nonceSecrets {
                    folio.hexData.updateValue(
                        nonceSecret.nonceSecret,
                        forKey: .nonceSecret(
                            network: Network.fromChainId(nonceSecret.chainId),
                            wallet: nonceSecret.account
                        )
                    )
                }

                for tokenWrapperQuote in portfolio.tokenWrapperQuotes {
                    folio.swapHints.updateValue(
                        .init(
                            minAmount: nil,
                            maxAmount: nil,
                            exchangeRate: tokenWrapperQuote.unwrapQuote
                        ),
                        forKey: .wrapper(
                            underlyingNetwork: network,
                            underlyingSymbol: tokenWrapperQuote.underlying.symbol,
                            wrappedNetwork: network,
                            wrappedSymbol: tokenWrapperQuote.wrapped.symbol
                        )
                    )
                }

                for assetQuote in quote.assetQuotes {
                    folio.prices.updateValue(
                        assetQuote.marketPriceUsd,
                        forKey: .assetQuote(
                            quoteId: quote.quoteId,
                            tokenSymbol: assetQuote.tokenSymbol
                        )
                    )
                }

                for networkOperationFee in quote.networkOperationFees {
                    folio.prices.updateValue(
                        networkOperationFee.usdPrice,
                        forKey: .networkOperationQuote(
                            quoteId: quote.quoteId,
                            network: Network.fromChainId(networkOperationFee.chainId),
                            operationType: networkOperationFee.operationType
                        )
                    )
                }

                for bridgeHint in bridgeHints {
                    // TODO: We previously inverted these rates, do we still need that?
                    let key: Folio.BridgeHintType = switch bridgeHint.bridgeType {
                    case .across:
                        .across(
                            networkIn: bridgeHint.networkIn,
                            symbolIn: bridgeHint.symbolIn,
                            networkOut: bridgeHint.networkOut,
                            symbolOut: bridgeHint.symbolOut
                        )
                    case .cctpV2:
                        .cctpV2(
                            networkIn: bridgeHint.networkIn,
                            symbolIn: bridgeHint.symbolIn,
                            networkOut: bridgeHint.networkOut,
                            symbolOut: bridgeHint.symbolOut
                        )
                    }
                    folio.bridgeHints.updateValue(
                        .init(
                            minAmount: bridgeHint.minAmount,
                            maxAmount: bridgeHint.maxAmount,
                            maxAmountInstant: bridgeHint.maxAmountInstant,
                            estimatedFillTimeSec: bridgeHint.estimatedFillTimeSec,
                            fixedCost: bridgeHint.fixedCost,
                            rate: bridgeHint.rate
                        ),
                        forKey: key
                    )
                }
            }
        }

        // Add native token wrapping
        for network in Atlas.allEvmNetworks {
            for asset in network.assets {
                if asset.isNativeAsset,
                    let crossChainAsset = asset.crossChainAsset,
                    let wrappedAssetSymbol = crossChainAsset.wrappedAssetSymbol
                {

                    folio.swapHints.updateValue(
                        .init(
                            minAmount: nil,
                            maxAmount: nil,
                            exchangeRate: .oneHundred
                        ),
                        forKey: .wrapper(
                            underlyingNetwork: Network.fromChainId(network.chainId),
                            underlyingSymbol: crossChainAsset.symbol,
                            wrappedNetwork: Network.fromChainId(network.chainId),
                            wrappedSymbol: wrappedAssetSymbol
                        )
                    )
                }
            }
        }

        return folio
    }
}
