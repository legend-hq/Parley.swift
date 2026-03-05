import Eth
import Foundation
import Portfolio
import Prelude
import SwiftNumber

@testable import Charter

public class PortfolioState {
    var tokenPositions: [Network: [Token: [Account: Number]]] = [:]
    var cometPositions:
        [Network: [Comet: [Account: (Number, Number, [Token: Number], [CometReward: Number])]]] =
            [:]
    var morphoPositions: [Network: [Morpho: [Account: (Number, Number)]]] = [:]
    var morphoVaultPositions: [Network: [MorphoVault: [Account: Number]]] = [:]
    var morphoRewardDistributions:
        [Network: [MorphoDistributor: [(Account, Token, Number, MorphoClaimProof)]]] = [:]
    var aavePositions: [Network: [AavePool: [Account: [Token: (Number, Number)]]]] = [:]

    let allNetworks: [Network] = [.ethereum, .base, .arbitrum, .optimism, .worldChain, .hyperEVM]

    public init() {}

    public func apply(_ given: Given) {
        switch given {
            case .tokenBalance(let account, let amount, let network):
                let currentPosition =
                    tokenPositions[network, default: [:]][amount.token, default: [:]][account] ?? 0
                tokenPositions[network, default: [:]][amount.token, default: [:]][account] =
                    currentPosition + amount.amount
            case .cometReward(let account, let rewardOwed, let comet, let cometReward, let network):
                if cometReward.rewardToken != rewardOwed.token {
                    fatalError("RewardOwed token does not match CometReward token")
                }
                let (currSupply, currBorrow, collaterals, cometRewardsOwed) =
                    cometPositions[network, default: [:]][comet, default: [:]][account] ?? (
                        0, 0, [:], [:]
                    )
                var updatedCometRewardsOwed = cometRewardsOwed
                updatedCometRewardsOwed[cometReward, default: 0] += rewardOwed.amount
                cometPositions[network, default: [:]][comet, default: [:]][account] = (
                    currSupply, currBorrow, collaterals, updatedCometRewardsOwed
                )
            case .cometSupply(let account, let amount, let comet, let network):
                guard amount.token == comet.baseAsset else {
                    fatalError(
                        "Cannot supply non-base asset to Comet. Use .cometCollateral for collateral supply."
                    )
                }
                let (currSupply, currBorrow, collaterals, cometRewardsOwed) =
                    cometPositions[network, default: [:]][comet, default: [:]][account] ?? (
                        0, 0, [:], [:]
                    )
                cometPositions[network, default: [:]][comet, default: [:]][account] = (
                    currSupply + amount.amount, currBorrow, collaterals, cometRewardsOwed
                )
            case .cometBorrow(let account, let amount, let comet, let network):
                guard amount.token == comet.baseAsset else {
                    fatalError("Cannot borrow non-base asset from Comet")
                }
                let (currSupply, currBorrow, collaterals, cometRewardsOwed) =
                    cometPositions[network, default: [:]][comet, default: [:]][account] ?? (
                        0, 0, [:], [:]
                    )
                cometPositions[network, default: [:]][comet, default: [:]][account] = (
                    currSupply, currBorrow + amount.amount, collaterals, cometRewardsOwed
                )
            case .cometCollateral(let account, let amount, let comet, let network):
                // Handle collateral supply specifically
                let (currSupply, currBorrow, collaterals, cometRewardsOwed) =
                    cometPositions[network, default: [:]][comet, default: [:]][account] ?? (
                        0, 0, [:], [:]
                    )
                var updatedCollaterals = collaterals
                updatedCollaterals[amount.token, default: 0] += amount.amount
                cometPositions[network, default: [:]][comet, default: [:]][account] = (
                    currSupply, currBorrow, updatedCollaterals, cometRewardsOwed
                )
            case .aaveSupply(let account, let amount, let pool, let network):
                let (currentSupply, currentBorrow) = aavePositions[network, default: [:]][
                    pool,
                    default: [:]
                ][account, default: [:]][amount.token, default: (Number(0), Number(0))]

                aavePositions[network, default: [:]][pool, default: [:]][account, default: [:]][
                    amount.token
                ] = (
                    currentSupply + amount.amount,
                    currentBorrow
                )
            case .aaveBorrow(let account, let amount, let pool, let network):
                let (currentSupply, currentBorrow) = aavePositions[network, default: [:]][
                    pool,
                    default: [:]
                ][account, default: [:]][amount.token, default: (Number(0), Number(0))]

                aavePositions[network, default: [:]][pool, default: [:]][account, default: [:]][
                    amount.token
                ] = (
                    currentSupply,
                    currentBorrow + amount.amount
                )
            case .morphoBorrow(
                let account,
                let morpho,
                let borrowAmount,
                let collateralAmount,
                let network
            ):
                let (currentBorrow, currentCollateralSupply) = morphoPositions[
                    network,
                    default: [:]
                ][
                    morpho,
                    default: [:]
                ][account, default: (Number(0), Number(0))]
                morphoPositions[network, default: [:]][morpho, default: [:]][account] = (
                    currentBorrow + borrowAmount.amount,
                    currentCollateralSupply + collateralAmount.amount
                )
            case .morphoCollateral(let account, let amount, let morpho, let network):
                // Handle collateral supply specifically
                let (currentBorrow, currentCollateralSupply) = morphoPositions[
                    network,
                    default: [:]
                ][
                    morpho,
                    default: [:]
                ][account, default: (Number(0), Number(0))]
                morphoPositions[network, default: [:]][morpho, default: [:]][account] = (
                    currentBorrow,
                    currentCollateralSupply + amount.amount
                )
            case .morphoReward(let account, let claimable, let distributor, let proof, let network):
                let newDistribution = (account, claimable.token, claimable.amount, proof)
                morphoRewardDistributions[network, default: [:]][distributor, default: []]
                    .append(
                        newDistribution
                    )
            case .morphoVaultSupply(let account, let amount, let vault, let network):
                let currentSupply = morphoVaultPositions[network, default: [:]][
                    vault,
                    default: [:]
                ][
                    account,
                    default: Number(0)
                ]

                morphoVaultPositions[network, default: [:]][vault, default: [:]][account] =
                    currentSupply + amount.amount
            // Cases that don't affect portfolio state are ignored
            case .quote, .prices, .acrossQuote, .acrossQuoteWithMin, .acrossQuoteWithMax, .cometBorrowCapacity, .morphoBorrowCapacity, .cctpV2Quote,
                .cctpV2QuoteWithMin, .swapHint:
                break
        }
    }

    public var portfolios: [Portfolio] {
        allNetworks.map { network in
            Portfolio(
                wallets: Account.knownCases.map { account in
                    Portfolio.Wallet(
                        hasCode: true,
                        isQuark: true,
                        quarkVersion: "1.0",
                        wallet: account.address
                    )
                },
                block: Portfolio.Block(
                    number: 111,
                    timestamp: 222
                ),
                chainId: try! network.chainId.toUInt(),
                aaves: reifyAavePositionsV2(network: network),
                comets: reifyCometPositionsV2(network: network),
                morphos: reifyMorphoPositionsV2(network: network),
                morphoVaults: reifyMorphoVaultPositionsV2(network: network),
                queryVersion: Portfolio.QueryVersion(
                    revision: 1,
                    schema: "scheme"
                ),
                tokens: reifyTokenPositionsV2(network: network),
                morphoRewardPositions: reifyMorphoRewardPositionsV2(network: network),
                quarkNonceStatuses: [],
                acrossFillStatuses: [],
                tokenWrapperQuotes: tokenWrapperQuotes(for: network)
            )
        }
    }

    private func tokenWrapperQuotes(for network: Network) -> [Portfolio.TokenWrapperQuote] {
        switch network {
        case .hyperEVM:
            return [
                .init(
                    underlying: .init(
                        address: Token.hype.address(network: network)!,
                        decimals: 18,
                        name: "Hyperliquid",
                        symbol: "HYPE"
                    ),
                    wrapped: .init(
                        address: Token.whype.address(network: network)!,
                        decimals: 18,
                        name: "Wrapped HYPE",
                        symbol: "WHYPE"
                    ),
                    underlyingHasToken: true,
                    unwrapQuote: .init(double: 1.00)
                )
            ]
        default:
            guard let ethAddress = Token.eth.address(network: network),
                  let wethAddress = Token.weth.address(network: network) else {
                return []
            }
            return [
                .init(
                    underlying: .init(
                        address: ethAddress,
                        decimals: 18,
                        name: "Ether",
                        symbol: "ETH"
                    ),
                    wrapped: .init(
                        address: wethAddress,
                        decimals: 18,
                        name: "Wrapped Ether",
                        symbol: "WETH"
                    ),
                    underlyingHasToken: true,
                    unwrapQuote: .init(double: 1.00)
                )
            ]
        }
    }

    private func reifyTokenPositionsV2(network: Network) -> [Portfolio.Token] {
        Token.knownCases.compactMap { token -> Portfolio.Token? in
            guard let asset = token.address(network: network) else {
                return nil
            }

            return Portfolio.Token(
                address: asset,
                balances: Account.knownCases.map { account in
                    let amount =
                        tokenPositions[network, default: [:]][token, default: [:]][account] ?? 0
                    return Portfolio.Balance(
                        balance: Amount(amount, decimals: token.decimals),
                        wallet: account.address
                    )
                },
                decimals: token.decimals,
                name: token.symbol,
                symbol: token.symbol,
                usdPrice: Value(Number(token.defaultUsdPrice))
            )
        }
    }

    private func reifyCometPositionsV2(network: Network) -> [Portfolio.Comet] {
        let networkCometPositions:
            [Comet: [Account: (Number, Number, [Token: Number], [CometReward: Number])]] =
                (cometPositions[network] ?? [:])
        return networkCometPositions.compactMap { comet, accountPositions -> Portfolio.Comet? in
            var collateralPositions: [Token: [Account: Number]] = [:]
            var cometRewardsOwed: [CometReward: [Account: Number]] = [:]
            for (account, position) in accountPositions {
                for (token, amount) in position.2 {
                    collateralPositions[token, default: [:]][account] = amount
                }
                for (cometReward, rewardOwed) in position.3 {
                    cometRewardsOwed[cometReward, default: [:]][account] = rewardOwed
                }
            }

            guard let baseAsset = comet.baseAsset.address(network: network) else {
                return nil
            }

            return Portfolio.Comet(
                address: comet.address(network: network),
                base: Portfolio.Comet.Base(
                    address: baseAsset,
                    baseBorrowMin: Amount(0, decimals: comet.baseAsset.decimals),
                    decimals: comet.baseAsset.decimals,
                    name: comet.baseAsset.symbol,
                    positions: accountPositions.map { account, position in
                        Portfolio.Comet.Position(
                            baseBorrowCapacity: Amount(0, decimals: comet.baseAsset.decimals),
                            baseLiquidationCapacity: Amount(0, decimals: comet.baseAsset.decimals),
                            borrow: Amount(position.1, decimals: comet.baseAsset.decimals),
                            supply: Amount(position.0, decimals: comet.baseAsset.decimals),
                            usdBorrowCapacity: Value(0),
                            usdLiquidationCapacity: Value(0),
                            wallet: account.address
                        )
                    },
                    symbol: comet.baseAsset.symbol,
                    totalBalance: Amount(0, decimals: comet.baseAsset.decimals),
                    totalBorrow: Amount(0, decimals: comet.baseAsset.decimals),
                    totalSupply: Amount(0, decimals: comet.baseAsset.decimals),
                    usdPrice: Value(0)
                ),
                borrowApr: Percentage(0),
                borrowRewardsApr: Percentage(0),
                collaterals: collateralPositions.compactMap {
                    token,
                    accountAmounts -> Portfolio.Comet.Collateral? in
                    guard let asset = token.address(network: network) else {
                        return nil
                    }

                    return Portfolio.Comet.Collateral(
                        address: asset,
                        decimals: token.decimals,
                        cometBalances: accountAmounts.map { account, balance in
                            Portfolio.Balance(
                                balance: Amount(balance, decimals: token.decimals),
                                wallet: account.address
                            )
                        },
                        borrowCollateralFactor: Percentage(0),
                        liquidateCollateralFactor: Percentage(0),
                        liquidationFactor: Percentage(0),
                        name: token.symbol,
                        supplyCap: Amount(0, decimals: token.decimals),
                        symbol: token.symbol,
                        totalSupply: Amount(0, decimals: token.decimals),
                        usdPrice: Value(0),
                        basePrice: Amount(0, decimals: token.decimals)
                    )
                },
                name: comet.description,
                reward:
                    cometRewardsOwed.compactMap {
                        cometReward,
                        accountAmounts -> Portfolio.Comet.Reward? in
                        guard let asset = cometReward.rewardToken.address(network: network) else {
                            return nil
                        }

                        return Portfolio.Comet.Reward(
                            address: asset,
                            decimals: cometReward.rewardToken.decimals,
                            name: cometReward.rewardToken.symbol,
                            positions: accountAmounts.map { account, rewardOwed in
                                Portfolio.Comet.Reward.Position(
                                    rewardOwed: Amount(
                                        rewardOwed,
                                        decimals: cometReward.rewardToken.decimals
                                    ),
                                    wallet: account.address
                                )
                            },
                            rewardsAddress: cometReward.address(network: network),
                            symbol: cometReward.rewardToken.symbol,
                            usdPrice: Value(0)
                        )
                    }
                    .first,
                supplyApr: Percentage(0),
                supplyRewardsApr: Percentage(0),
                symbol: comet.description
            )
        }
    }

    private func reifyMorphoVaultPositionsV2(network: Network) -> [Portfolio.MorphoVault] {
        let networkMorphoVaultPositions: [MorphoVault: [Account: Number]] =
            (morphoVaultPositions[network] ?? [:])

        return networkMorphoVaultPositions.compactMap {
            vault,
            accountPositions -> Portfolio.MorphoVault? in
            let asset = vault.asset(network: network)
            guard let assetAddress = asset.address(network: network)
            else {
                return nil
            }

            return Portfolio.MorphoVault(
                address: vault.address(network: network),
                loanAsset: Portfolio.MorphoVault.LoanAsset(
                    address: assetAddress,
                    decimals: asset.decimals,
                    name: asset.description,
                    positions: accountPositions.map { account, position in
                        Portfolio.MorphoVault.Position(
                            supply: Amount(position, decimals: asset.decimals),
                            wallet: account.address
                        )
                    },
                    symbol: asset.symbol,
                    totalSupply: Amount(0, decimals: asset.decimals),
                    usdPrice: Value(0)
                ),
                fixnumDecimals: 0,
                name: vault.description,
                supplyApr: Percentage(0),
                symbol: asset.symbol,
                supplyRewards: [],
                fee: Amount(0, decimals: asset.decimals)
            )
        }
    }

    private func reifyMorphoPositionsV2(network: Network) -> [Portfolio.Morpho] {
        (morphoPositions[network] ?? [:])
            .compactMap {
                morpho,
                morphoPositions -> Portfolio.Morpho? in
                guard let borrowTokenAddress = morpho.borrowToken.address(network: network),
                    let collateralTokenAddress = morpho.collateralToken.address(network: network)
                else {
                    return nil
                }

                return Portfolio.Morpho(
                    marketId: morpho.marketId(network),
                    morpho: Morpho.address(network),
                    loanAsset: Portfolio.Morpho.LoanAsset(
                        address: borrowTokenAddress,
                        decimals: morpho.borrowToken.decimals,
                        name: morpho.borrowToken.description,
                        positions: morphoPositions.map { account, morphoPosition in
                            Portfolio.Morpho.Position(
                                baseLiquidationCapacity: Amount(
                                    0,
                                    decimals: morpho.borrowToken.decimals
                                ),
                                borrow: Amount(
                                    morphoPosition.0,
                                    decimals: morpho.borrowToken.decimals
                                ),
                                usdLiquidationCapacity: Value(0),
                                wallet: account.address
                            )
                        },
                        symbol: morpho.borrowToken.symbol,
                        totalBorrow: Amount(0, decimals: morpho.borrowToken.decimals),
                        totalSupply: Amount(0, decimals: morpho.borrowToken.decimals),
                        usdPrice: Value(0)
                    ),
                    collateralAsset: Portfolio.Morpho.CollateralAsset(
                        address: collateralTokenAddress,
                        balances: morphoPositions.map { account, morphoPosition in
                            Portfolio.Balance(
                                balance: Amount(
                                    morphoPosition.1,
                                    decimals: morpho.collateralToken.decimals
                                ),
                                wallet: account.address
                            )
                        },
                        basePrice: Value(0),
                        decimals: morpho.collateralToken.decimals,
                        name: morpho.collateralToken.description,
                        symbol: morpho.collateralToken.symbol,
                        usdPrice: Value(0)
                    ),
                    borrowApr: Percentage(0),
                    fixnumDecimals: 0,
                    liquidationLoanToValue: Percentage(0),
                    borrowRewards: []
                )
            }
    }

    private func reifyMorphoRewardPositionsV2(network: Network) -> [Portfolio.MorphoRewardPosition]
    {
        let networkMorphoRewardDistributions:
            [MorphoDistributor: [(Account, Token, Number, MorphoClaimProof)]] =
                (morphoRewardDistributions[network] ?? [:])
        return networkMorphoRewardDistributions.flatMap {
            distributor,
            distributions -> [Portfolio.MorphoRewardPosition] in
            distributions.compactMap {
                distribution -> Portfolio.MorphoRewardPosition? in
                let (account, asset, claimable, proof) = distribution

                guard let rewardTokenAddress = asset.address(network: network) else {
                    return nil
                }

                return Portfolio.MorphoRewardPosition(
                    chainId: try! network.chainId.toUInt(),
                    asset: Portfolio.MorphoRewardPosition.MorphoRewardAsset(
                        address: rewardTokenAddress,
                        name: asset.description,
                        symbol: asset.symbol,
                        decimals: asset.decimals
                    ),
                    airdropRewards: [],
                    distributions: [
                        Portfolio.MorphoRewardPosition.Distribution(
                            account: account.address,
                            distributor: distributor.address(network: network),
                            claimable: Amount(claimable, decimals: asset.decimals),
                            proof: proof.data
                        )
                    ],
                    marketRewards: [],
                    uniformRewards: [],
                    vaultRewards: [
                        Portfolio.MorphoRewardPosition.VaultReward(
                            total: Amount(claimable, decimals: asset.decimals),
                            account: account.address,
                            vault: distributor.address(network: network),
                            claimableNext: Amount(claimable, decimals: asset.decimals),
                            claimableNow: Amount(claimable, decimals: asset.decimals),
                            claimed: Amount(claimable, decimals: asset.decimals)
                        )
                    ]
                )
            }
        }
    }

    private func reifyAavePositionsV2(network: Network) -> [Portfolio.Aave] {
        (aavePositions[network] ?? [:])
            .compactMap { aave, accountPositions in
                var tokenAssets: [Token: Portfolio.Aave.Asset] = [:]

                for (account, position) in accountPositions {
                    for (token, (suppliedAmount, borrowedAmount)) in position {
                        guard let tokenAddress = token.address(network: network) else {
                            continue
                        }

                        let asset = tokenAssets[
                            token,
                            default: Portfolio.Aave.Asset(
                                address: tokenAddress,
                                decimals: token.decimals,
                                basePriceDecimals: 0,
                                isActive: true,
                                isFrozen: false,
                                isPaused: false,
                                positions: [],
                                supplyApr: Percentage(0),
                                borrowApr: Percentage(0),
                                supplyCap: Amount(0, decimals: token.decimals),
                                borrowCap: Amount(0, decimals: token.decimals),
                                basePrice: Amount(0, decimals: token.decimals),
                                borrowingEnabled: false,
                                usageAsCollateralEnabled: false,
                                symbol: token.symbol,
                                collateralLtv: Amount(0, decimals: token.decimals),
                                liquidationLtv: Amount(0, decimals: token.decimals),
                                isBorrowableInIsolation: false,
                                totalSupply: Amount(0, decimals: token.decimals),
                                totalBorrow: Amount(0, decimals: token.decimals),
                                usdPrice: Value(0),
                                isSiloedBorrowing: false
                            )
                        ]

                        var positions = asset.positions

                        positions.append(
                            Portfolio.Aave.Asset.Position(
                                borrowed: Amount(borrowedAmount, decimals: token.decimals),
                                supplied: Amount(suppliedAmount, decimals: token.decimals),
                                wallet: account.address,
                                usageAsCollateralEnabledOnUser: false
                            )
                        )

                        tokenAssets[token] = Portfolio.Aave.Asset(
                            address: asset.address,
                            decimals: asset.decimals,
                            basePriceDecimals: asset.basePriceDecimals,
                            isActive: asset.isActive,
                            isFrozen: asset.isFrozen,
                            isPaused: asset.isPaused,
                            positions: positions,
                            supplyApr: asset.supplyApr,
                            borrowApr: asset.borrowApr,
                            supplyCap: asset.supplyCap,
                            borrowCap: asset.borrowCap,
                            basePrice: asset.basePrice,
                            borrowingEnabled: asset.borrowingEnabled,
                            usageAsCollateralEnabled: asset.usageAsCollateralEnabled,
                            symbol: asset.symbol,
                            collateralLtv: asset.collateralLtv,
                            liquidationLtv: asset.liquidationLtv,
                            isBorrowableInIsolation: asset.isBorrowableInIsolation,
                            totalSupply: asset.totalSupply,
                            totalBorrow: asset.totalBorrow,
                            usdPrice: asset.usdPrice,
                            isSiloedBorrowing: asset.isSiloedBorrowing
                        )
                    }
                }
                let borrowPositions: [Portfolio.Aave.BorrowPosition] = []

                return Portfolio.Aave(
                    assets: Array(tokenAssets.values),
                    borrowPositions: borrowPositions,
                    name: aave.description,
                    pool: aave.address(network: network)
                )
            }
    }
}

/// Generates an array of `Portfolio` objects based on a given array of `Given` cases.
///
/// This function simplifies the process of creating complex portfolio states for testing purposes.
/// It abstracts away the internal state management, allowing you to focus on the inputs (`Given` cases)
/// and the output (`[Portfolio]`).
///
/// - Parameter givens: An array of `Given` enums that describe the desired state.
/// - Returns: An array of `Portfolio` objects representing the state across all supported networks.
public func generatePortfolios(from givens: [Given]) -> [Portfolio] {
    let state = PortfolioState()
    for given in givens {
        state.apply(given)
    }
    return state.portfolios
}
