import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

struct TradewindsResourceFactory {
    let folio: Folio
    let primarySymbol: String
    let earnMarketPolicy: EarnMarketPolicy
    let actorWallet: EthAddress
    let network: Network?

    struct EarnMarketPolicyAmount: Hashable {
        let marketAddress: EthAddress
        let network: Network
        let amount: Tradewinds.FlowAmount
    }

    enum EarnMarketPolicy: Equatable {
        case none
        case all
        case specific(Set<EarnMarketPolicyAmount>)
    }

    func createAllResources() -> Result<
        [Tradewinds.Resource<TradewindsLegendNode>], Charter.CharterError
    > {
        var resources = createTokenResources()

        if earnMarketPolicy != .none {
            switch createEarnMarketResources() {
                case .success(let earnResources):
                    resources.append(contentsOf: earnResources)
                case .failure(let error):
                    return .failure(error)
            }
        }

        return .success(resources)
    }

    func createTokenResources() -> [Tradewinds.Resource<TradewindsLegendNode>] {
        var resources: [Tradewinds.Resource<TradewindsLegendNode>] = []

        // Iterate over all networks in Atlas
        for networkType in Atlas.allNetworks {
            let network = networkType.network

            // Skip if we're restricted to a specific network and this isn't it
            if let restrictedNetwork = self.network, restrictedNetwork != network {
                continue
            }

            // Get relevant symbols for this network
            let relevantSymbols = folio.getRelevantSymbols(
                network: network,
                assetSymbol: primarySymbol
            )

            // For each relevant symbol, check if we have a balance or create a zero balance
            for symbol in relevantSymbols {
                guard let atlasToken = Atlas.getAssetBySymbol(network: network, symbol: symbol)
                else {
                    continue
                }

                // Look up the balance in folio
                let balanceKey = Folio.BalanceType.token(
                    network: network,
                    symbol: symbol,
                    wallet: actorWallet
                )
                let balance = folio.balances[balanceKey]?.underlying ?? Number(0)

                resources.append(
                    Tradewinds.Resource(
                        amount: .exact(balance),
                        node: .tokenBalance(
                            network: network,
                            address: atlasToken.assetAddress,
                            symbol: symbol,
                            wallet: actorWallet
                        )
                    )
                )
            }
        }

        return resources
    }

    func matchesEarnMarketPolicy(
        earnMarketPolicy: EarnMarketPolicy,
        address: EthAddress,
        network: Network
    )
        -> EarnMarketPolicyAmount?
    {
        switch earnMarketPolicy {
            case .none:
                return nil
            case .all:
                return EarnMarketPolicyAmount(
                    marketAddress: address,
                    network: network,
                    amount: .max
                )
            case .specific(let allowedMarkets):
                return allowedMarkets.first { $0.marketAddress == address && $0.network == network }
        }
    }

    func createEarnMarketResources() -> Result<
        [Tradewinds.Resource<TradewindsLegendNode>], Charter.CharterError
    > {
        var resources: [Tradewinds.Resource<TradewindsLegendNode>] = []

        // Iterate over all networks in Atlas
        for networkType in Atlas.allNetworks {
            let network = networkType.network

            // Skip if we're restricted to a specific network and this isn't it
            if let restrictedNetwork = self.network, restrictedNetwork != network {
                continue
            }

            // Get relevant symbols for this network
            let relevantSymbols = folio.getRelevantSymbols(
                network: network,
                assetSymbol: primarySymbol
            )

            for symbol in relevantSymbols {
                guard let underlyingAsset = Atlas.getAssetBySymbol(network: network, symbol: symbol)
                else {
                    continue
                }

                // Add Aave markets
                for aaveMarket in networkType.aaveMarkets {
                    guard
                        let earnMarketPolicyAmount = matchesEarnMarketPolicy(
                            earnMarketPolicy: earnMarketPolicy,
                            address: aaveMarket.pool,
                            network: network
                        )
                    else {
                        continue
                    }

                    // Check if this asset is supported in this Aave market
                    if aaveMarket.reserves.contains(where: {
                        $0.symbol.uppercased() == symbol.uppercased()
                    }) {
                        // Look up the balance in folio
                        let balanceKey = Folio.BalanceType.yieldMarket(
                            yieldMarket: .aave(
                                network: network,
                                pool: aaveMarket.pool,
                                underlyingSymbol: symbol
                            ),
                            wallet: actorWallet
                        )
                        let folioBalance = folio.balances[balanceKey]?.underlying ?? Number(0)

                        let resourceBalance: Tradewinds.FlowAmount
                        switch validateAndCreateFlowAmount(
                            folioBalance: folioBalance,
                            policyAmount: earnMarketPolicyAmount,
                            network: network,
                            marketAddress: aaveMarket.pool,
                            symbol: symbol,
                            decimals: Int(underlyingAsset.decimals)
                        ) {
                            case .success(let flowAmount):
                                resourceBalance = flowAmount
                            case .failure(let error):
                                return .failure(error)
                        }

                        resources.append(
                            Tradewinds.Resource(
                                amount: resourceBalance,
                                node: .aaveSupplyBalance(
                                    network: network,
                                    pool: aaveMarket.pool,
                                    baseAsset: underlyingAsset.assetAddress,
                                    wallet: actorWallet
                                )
                            )
                        )
                    }
                }

                // Add Morpho vaults
                for morphoVault in networkType.morphoVaults {
                    guard
                        let earnMarketPolicyAmount = matchesEarnMarketPolicy(
                            earnMarketPolicy: earnMarketPolicy,
                            address: morphoVault.vault,
                            network: network
                        ),
                        morphoVault.asset == underlyingAsset.assetAddress
                    else {
                        continue
                    }

                    // Look up the balance in folio
                    let balanceKey = Folio.BalanceType.yieldMarket(
                        yieldMarket: .morphoVault(
                            network: network,
                            vault: morphoVault.vault,
                            underlyingSymbol: symbol
                        ),
                        wallet: actorWallet
                    )
                    let folioBalance = folio.balances[balanceKey]?.underlying ?? Number(0)

                    let resourceBalance: Tradewinds.FlowAmount
                    switch validateAndCreateFlowAmount(
                        folioBalance: folioBalance,
                        policyAmount: earnMarketPolicyAmount,
                        network: network,
                        marketAddress: morphoVault.vault,
                        symbol: symbol,
                        decimals: Int(underlyingAsset.decimals)
                    ) {
                        case .success(let flowAmount):
                            resourceBalance = flowAmount
                        case .failure(let error):
                            return .failure(error)
                    }

                    resources.append(
                        Tradewinds.Resource(
                            amount: resourceBalance,
                            node: .morphoVaultSupplyBalance(
                                network: network,
                                vault: morphoVault.vault,
                                baseAsset: underlyingAsset.assetAddress,
                                wallet: actorWallet
                            )
                        )
                    )
                }

                // Add Comet markets
                for comet in networkType.comets {
                    guard
                        let earnMarketPolicyAmount = matchesEarnMarketPolicy(
                            earnMarketPolicy: earnMarketPolicy,
                            address: comet.cometAddress,
                            network: network
                        ),
                        comet.baseAsset == underlyingAsset.assetAddress
                    else {
                        continue
                    }

                    // Look up the balance in folio
                    let balanceKey = Folio.BalanceType.yieldMarket(
                        yieldMarket: .comet(
                            network: network,
                            comet: comet.cometAddress,
                            underlyingSymbol: symbol
                        ),
                        wallet: actorWallet
                    )
                    let folioBalance = folio.balances[balanceKey]?.underlying ?? Number(0)

                    let resourceBalance: Tradewinds.FlowAmount
                    switch validateAndCreateFlowAmount(
                        folioBalance: folioBalance,
                        policyAmount: earnMarketPolicyAmount,
                        network: network,
                        marketAddress: comet.cometAddress,
                        symbol: symbol,
                        decimals: Int(underlyingAsset.decimals)
                    ) {
                        case .success(let flowAmount):
                            resourceBalance = flowAmount
                        case .failure(let error):
                            return .failure(error)
                    }

                    resources.append(
                        Tradewinds.Resource(
                            amount: resourceBalance,
                            node: .cometSupplyBalance(
                                network: network,
                                comet: comet.cometAddress,
                                baseAsset: underlyingAsset.assetAddress,
                                wallet: actorWallet
                            )
                        )
                    )
                }
            }
        }

        return .success(resources)
    }

    private func validateAndCreateFlowAmount(
        folioBalance: Number,
        policyAmount: EarnMarketPolicyAmount,
        network: Network,
        marketAddress: EthAddress,
        symbol: String,
        decimals: Int
    ) -> Result<Tradewinds.FlowAmount, Charter.CharterError> {
        switch policyAmount.amount {
            case .max:
                return .success(.exact(folioBalance))
            case .exact(let amount):
                guard folioBalance >= amount else {
                    return .failure(
                        .insufficientEarnMarketBalance(
                            network: network,
                            market: marketAddress,
                            symbol: symbol,
                            required: Amount(amount, decimals: decimals),
                            available: Amount(folioBalance, decimals: decimals)
                        )
                    )
                }
                return .success(.exact(amount))
        }
    }
}
