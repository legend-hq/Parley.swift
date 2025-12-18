import Atlas
import Eth
import Prelude
import SwiftNumber

public func generateFolio(from givens: [Given]) -> Folio {
    var folio = Folio()
    for given in givens {
        applyGiven(folio: &folio, given: given)
    }

    for account in Account.knownCases {
        for network in allNetworks {
            folio.hexData.updateValue(
                account.nonceSecret,
                forKey: .nonceSecret(network: network, wallet: account.address)
            )
        }
    }

    // Add default prices for all known tokens
    for token in Token.knownCases {
        folio.prices.updateValue(
            Value(double: token.defaultUsdPrice),
            forKey: .token(symbol: token.symbol)
        )
    }

    // Add default ETH/WETH wrapper hints for all networks
    for atlasNetwork in Atlas.allNetworks {
        let network = atlasNetwork.network
        // ETH -> WETH wrap
        folio.swapHints.updateValue(
            .init(
                minAmount: Amount(0, decimals: 18),
                maxAmount: nil,
                exchangeRate: Percentage(fromDouble: 1.0)  // 1:1 exchange rate
            ),
            forKey: .wrapper(
                underlyingNetwork: network,
                underlyingSymbol: "ETH",
                wrappedNetwork: network,
                wrappedSymbol: "WETH"
            )
        )
    }

    // print("folio: \(folio)")

    return folio
}

// Use networks from Atlas to ensure consistency
var allNetworks: [Network] {
    Atlas.allNetworks.map { $0.network }
}

public func applyGiven(folio: inout Folio, given: Given) {
    switch given {
        case .tokenBalance(let account, let amount, let network):
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .token(
                    network: network,
                    symbol: amount.token.symbol,
                    wallet: account.address
                )
            )
        case .prices(let prices):
            for price in prices {
                folio.prices.updateValue(
                    Value(double: price.value),
                    forKey: .token(symbol: price.key.symbol)
                )
            }
        case .quote(let quote):
            let (quoteId, prices, fees) = quote.params
            for price in prices {
                folio.prices.updateValue(
                    Value(double: price.value),
                    forKey: .assetQuote(quoteId: quoteId, tokenSymbol: price.key.symbol)
                )
            }
            for fee in fees {
                folio.prices.updateValue(
                    Value(double: fee.value),
                    forKey: .networkOperationQuote(
                        quoteId: quoteId,
                        network: fee.key,
                        operationType: "baseline"
                    )
                )
            }
        case .cometSupply(let account, let amount, let comet, let network):
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .yieldMarket(
                    yieldMarket: .comet(
                        network: network,
                        comet: comet.address(network: network),
                        underlyingSymbol: amount.token.symbol
                    ),
                    wallet: account.address
                )
            )
        case .cometBorrow(let account, let amount, let comet, let network):
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .borrowMarket(
                    borrowMarket: .comet(
                        network: network,
                        comet: comet.address(network: network),
                        underlyingSymbol: amount.token.symbol
                    ),
                    wallet: account.address
                )
            )
        case .cometReward(let account, let amount, let comet, let cometRewards, let network):
            let rewardKey = Folio.RewardType.cometReward(
                network: network,
                comet: comet.address(network: network),
                underlyingSymbol: amount.token.symbol,
                cometRewards: cometRewards.address(network: network),
                wallet: account.address
            )
            folio.balances.updateValue(amount.toAmount, forKey: .reward(rewardType: rewardKey))
            folio.rewards.updateValue(
                .init(proof: .none),
                forKey: rewardKey
            )
        case .aaveSupply(let account, let amount, let aavePool, let network):
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .yieldMarket(
                    yieldMarket: .aave(
                        network: network,
                        pool: aavePool.address(network: network),
                        underlyingSymbol: amount.token.symbol
                    ),
                    wallet: account.address
                )
            )
        case .aaveBorrow(let account, let amount, let aavePool, let network):
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .borrowMarket(
                    borrowMarket: .aave(
                        network: network,
                        pool: aavePool.address(network: network),
                        underlyingSymbol: amount.token.symbol
                    ),
                    wallet: account.address
                )
            )
        case .morphoVaultSupply(let account, let amount, let morphoVault, let network):
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .yieldMarket(
                    yieldMarket: .morphoVault(
                        network: network,
                        vault: morphoVault.address(network: network),
                        underlyingSymbol: amount.token.symbol
                    ),
                    wallet: account.address
                )
            )
        case .morphoBorrow(
            let account,
            let morpho,
            let borrowAmount,
            let collateralAmount,
            let network
        ):
            // Set the borrow amount
            folio.balances.updateValue(
                borrowAmount.toAmount,
                forKey: .borrowMarket(
                    borrowMarket: .morpho(
                        network: network,
                        collateralTokenSymbol: morpho.collateralToken.symbol,
                        borrowTokenSymbol: morpho.borrowToken.symbol
                    ),
                    wallet: account.address
                )
            )
            // Also set the collateral amount if provided
            if collateralAmount.amount > Number(0) {
                folio.balances.updateValue(
                    collateralAmount.toAmount,
                    forKey: .borrowMarketCollateral(
                        borrowMarket: .morpho(
                            network: network,
                            collateralTokenSymbol: morpho.collateralToken.symbol,
                            borrowTokenSymbol: morpho.borrowToken.symbol
                        ),
                        tokenSymbol: morpho.collateralToken.symbol,
                        wallet: account.address
                    )
                )
            }
        case .morphoReward(
            let account,
            let amount,
            let distributor,
            let morphoClaimProof,
            let network
        ):
            // All rewards now use morphoReward type with distributor
            let distributorAddress: EthAddress
            switch distributor {
                case .merklDistributor:
                    distributorAddress = MorphoDistributor.merklDistributorAddress(for: network)
                case .distributor:
                    distributorAddress = MorphoDistributor.address(network: network)
                case .unknownDistributor(let address):
                    distributorAddress = address
            }

            let rewardKey = Folio.RewardType.morphoReward(
                network: network,
                underlyingSymbol: amount.token.symbol,
                distributor: distributorAddress,
                wallet: account.address
            )
            let proof = Folio.Reward.Proof.morphoReward(
                proof: morphoClaimProof.data,
                proofAmount: amount.toAmount
            )

            // Add claimable amount to balances (following Comet pattern)
            folio.balances.updateValue(amount.toAmount, forKey: .reward(rewardType: rewardKey))
            // Add to rewards with locked = 0 (all is claimable)
            folio.rewards.updateValue(
                .init(proof: proof),
                forKey: rewardKey
            )
        case .acrossQuote(let fixedCost, let fee):
            for srcNetwork in allNetworks {
                for dstNetwork in allNetworks {
                    if srcNetwork == dstNetwork {
                        continue
                    }

                    folio.bridgeHints.updateValue(
                        .init(
                            minAmount: Amount(0, decimals: fixedCost.token.decimals),
                            maxAmount: nil,
                            fixedCost: fixedCost.toAmount,
                            rate: Percentage(fromDouble: 1.0 - fee)  // Convert fee to rate
                        ),
                        forKey: .across(
                            networkIn: srcNetwork,
                            symbolIn: fixedCost.token.symbol,
                            networkOut: dstNetwork,
                            symbolOut: fixedCost.token.symbol
                        )
                    )
                }
            }
        case .acrossQuoteWithMin(let fixedCost, let fee, let minAmount):
            for srcNetwork in allNetworks {
                for dstNetwork in allNetworks {
                    if srcNetwork == dstNetwork {
                        continue
                    }
                    folio.bridgeHints.updateValue(
                        .init(
                            minAmount: minAmount.toAmount,
                            maxAmount: nil,
                            fixedCost: fixedCost.toAmount,
                            rate: Percentage(fromDouble: 1.0 - fee)  // Convert fee to rate
                        ),
                        forKey: .across(
                            networkIn: srcNetwork,
                            symbolIn: fixedCost.token.symbol,
                            networkOut: dstNetwork,
                            symbolOut: fixedCost.token.symbol
                        )
                    )
                }
            }
        case .cometCollateral(let account, let amount, let comet, let network):
            // Handle Comet collateral balances
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .borrowMarketCollateral(
                    borrowMarket: .comet(
                        network: network,
                        comet: comet.address(network: network),
                        underlyingSymbol: amount.token.symbol
                    ),
                    tokenSymbol: amount.token.symbol,
                    wallet: account.address
                )
            )

            let borrowMarketKey = Folio.BorrowMarketType.comet(
                network: network,
                comet: comet.address(network: network),
                underlyingSymbol: comet.baseAsset.symbol
            )
            var existingBorrowMarket = folio.borrowMarkets[borrowMarketKey] ?? Folio.BorrowMarket(
                borrowApr: Percentage(fromDouble: 0.05),
                borrowRewardsApr: Percentage(fromDouble: 0.0),
                borrowCap: nil,
                totalBorrow: Amount(0, decimals: comet.baseAsset.decimals),
                collaterals: [:]
            )
            let factors = Comet.defaultCollateralFactors
            existingBorrowMarket.collaterals[amount.token.symbol] = Folio.BorrowMarket.Collateral(
                borrowCollateralFactor: Percentage(fromDouble: factors.borrowCollateralFactor),
                liquidateCollateralFactor: Percentage(
                    fromDouble: factors.liquidateCollateralFactor
                ),
                liquidationFactor: Percentage(fromDouble: factors.liquidationFactor),
                supplyCap: nil,
                totalSupply: nil,
                usdPrice: Value(double: amount.token.defaultUsdPrice)
            )
            folio.borrowMarkets[borrowMarketKey] = existingBorrowMarket
        case .cometBorrowCapacity:
            break
        case .morphoCollateral(let account, let amount, let morpho, let network):
            // Handle Morpho collateral balances
            folio.balances.updateValue(
                amount.toAmount,
                forKey: .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: network,
                        collateralTokenSymbol: amount.token.symbol,
                        borrowTokenSymbol: morpho.borrowToken.symbol
                    ),
                    tokenSymbol: amount.token.symbol,
                    wallet: account.address
                )
            )
        case .morphoBorrowCapacity:
            break
    }
}
