import Atlas
import Eth
import Foundation

extension Folio {
    public var asJson: String {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(data: try! jsonEncoder.encode(self), encoding: .utf8)!
    }

    public func getMetaAsset(symbol: String) -> MetaAsset? {
        if let xchainAsset = Atlas.getCrossChainAsset(symbol: symbol) {
            var metaAsset = MetaAsset(
                name: xchainAsset.name,
                symbol: xchainAsset.symbol,
                decimals: Int(xchainAsset.decimals),
                underlyingAssetSymbol: xchainAsset.underlyingAssetSymbol
            )

            metaAsset.assets = getAssets(symbol: symbol)
            // let baseAssets: [BaseAsset] = Atlas.allNetworks.compactMap({ getBaseAsset(symbol: symbol, chain: $0.network) })
            // let collateralAssets: [CollateralAsset] = Atlas.allNetworks.compactMap({ getCollateralAsset(symbol: symbol, chain: $0.network) })
            // let rewardAssets: [RewardAsset] = Atlas.allNetworks.compactMap({ getRewardAsset(symbol: symbol, chain: $0.network) })

            return metaAsset
        }

        return nil
    }

    public func getAssets(symbol: String) -> [Asset] {
        Atlas.allNetworks.compactMap({ getAsset(symbol: symbol, chain: $0.network) })
    }

    public func getAsset(symbol: String, chain: Network) -> Asset? {
        if let atlasAsset = Atlas.getAssetBySymbol(network: chain, symbol: symbol),
            let price = getAssetPrice(symbol: symbol)
        {
            return Asset(
                address: atlasAsset.assetAddress,
                chain: chain,
                name: atlasAsset.name,
                symbol: atlasAsset.symbol,
                decimals: Int(atlasAsset.decimals),
                price: price,
                balances: getAssetBalances(network: chain, symbol: symbol),
                underlyingAsset: getUnderlyingAsset(symbol: symbol, chain: chain)
            )
        }

        return nil
    }

    public func getAssetPrice(symbol: String) -> Value? {
        return self.prices
            .compactMap({ type, price in
                if case .token(let tokenSymbol) = type,
                    tokenSymbol.equalIgnoringCase(symbol)
                {
                    return price
                }

                return nil
            })
            .first
    }

    public func getAssetBalances(network: Network, symbol: String) -> [Asset.Balance] {
        return self.balances.compactMap({ type, balance in
            if case .token(let tokenNetwork, let tokenSymbol, let wallet) = type,
                tokenNetwork == network && tokenSymbol.equalIgnoringCase(symbol)
            {
                return Asset.Balance(
                    wallet: wallet,
                    balance: balance,
                    underlyingAssetBalance: getUnderlyingAssetBalance(
                        network: network,
                        symbol: symbol,
                        balance: balance
                    )
                )
            }

            return nil
        })
    }

    public func getAssetBalance(network: Network, symbol: String, wallet: EthAddress) -> Amount? {
        return self.balances
            .compactMap({ type, balance in
                if case .token(let tokenNetwork, let tokenSymbol, let wallet_) = type,
                    wallet_ == wallet && tokenNetwork == network
                        && tokenSymbol.equalIgnoringCase(symbol)
                {
                    return balance
                } else {
                    return nil
                }
            })
            .first
    }

    public func getCometBorrowBalance(
        network: Network,
        comet: EthAddress,
        underlyingSymbol: String,
        wallet: EthAddress
    ) -> Amount? {
        return self.balances
            .compactMap({ type, balance in
                if case .borrowMarket(let borrowMarket, let wallet_) = type,
                    case .comet(let balanceNetwork, let balanceComet, let balanceSymbol) = borrowMarket,
                    wallet_ == wallet && balanceNetwork == network && balanceComet == comet
                        && balanceSymbol.equalIgnoringCase(underlyingSymbol)
                {
                    return balance
                } else {
                    return nil
                }
            })
            .first
    }

    public func getMorphoBorrowBalance(
        network: Network,
        collateralTokenSymbol: String,
        borrowTokenSymbol: String,
        wallet: EthAddress
    ) -> Amount? {
        return self.balances
            .compactMap({ type, balance in
                if case .borrowMarket(let borrowMarket, let wallet_) = type,
                    case .morpho(let balanceNetwork, let balanceCollateralSymbol, let balanceBorrowSymbol) = borrowMarket,
                    wallet_ == wallet && balanceNetwork == network
                        && balanceCollateralSymbol.equalIgnoringCase(collateralTokenSymbol)
                        && balanceBorrowSymbol.equalIgnoringCase(borrowTokenSymbol)
                {
                    return balance
                } else {
                    return nil
                }
            })
            .first
    }

    public func getCometCollateralBalances(
        network: Network,
        comet: EthAddress,
        wallet: EthAddress
    ) -> [(tokenSymbol: String, balance: Amount)] {
        return self.balances.compactMap({ type, balance in
            if case .borrowMarketCollateral(let borrowMarket, let tokenSymbol, let wallet_) = type,
                case .comet(let balanceNetwork, let balanceComet, _) = borrowMarket,
                wallet_ == wallet && balanceNetwork == network && balanceComet == comet
            {
                return (tokenSymbol: tokenSymbol, balance: balance)
            } else {
                return nil
            }
        })
    }

    public func getUnderlyingAssetBalance(network: Network, symbol: String, balance: Amount)
        -> Amount?
    {
        return self.swapHints
            .compactMap({ type, swapHint in
                if case .wrapper(_, _, let wrappedNetwork, let wrappedSymbol) = type,
                    wrappedNetwork == network && wrappedSymbol.equalIgnoringCase(symbol)
                {
                    return balance * swapHint.exchangeRate
                }

                return nil
            })
            .first
    }

    public func getUnderlyingAsset(symbol: String, chain: Network) -> Asset.UnderlyingAsset? {
        return self.swapHints
            .compactMap({ type, swapHint in
                if case .wrapper(
                    let underlyingNetwork,
                    let underlyingSymbol,
                    let wrappedNetwork,
                    let wrappedSymbol
                ) =
                    type,
                    wrappedNetwork == chain && wrappedSymbol.equalIgnoringCase(symbol),
                    let underlyingAsset = getAsset(
                        symbol: underlyingSymbol,
                        chain: underlyingNetwork
                    )
                {
                    return Asset.UnderlyingAsset(
                        address: underlyingAsset.address,
                        name: underlyingAsset.name,
                        symbol: underlyingAsset.symbol,
                        decimals: underlyingAsset.decimals,
                        unwrapQuote: swapHint.exchangeRate
                    )
                }

                return nil
            })
            .first
    }

    public var nonceSecrets: [NonceSecret] {
        return self.hexData.compactMap { type, hexData in
            switch type {
                case .nonceSecret(let network, let wallet):
                    return NonceSecret(
                        chainId: network.chainId.asUInt,
                        account: wallet,
                        nonceSecret: hexData
                    )
            }
        }
    }

    public func getNonceSecret(network: Network, wallet: EthAddress) -> Hex? {
        return self.nonceSecrets.first(where: {
            $0.chainId == network.chainId.asUInt && $0.account == wallet
        })?
        .nonceSecret
    }

    public func getAssetQuote(symbol: String) -> Quote.AssetQuote? {
        return self.prices
            .compactMap({ type, price in
                switch type {
                    case .assetQuote(_, let tokenSymbol):
                        if tokenSymbol.equalIgnoringCase(symbol) {
                            // TODO: quoteId?
                            return Quote.AssetQuote(
                                tokenSymbol: tokenSymbol,
                                marketPriceUsd: price,
                                adjustedPriceUsd: price
                            )
                        }

                        return nil
                    default:
                        return nil
                }
            })
            .first
    }

    public func getNetworkOperationFee(network: Network, operationType: String) -> Quote
        .NetworkOperationFee?
    {
        return self.prices
            .compactMap({ type, price in
                switch type {
                    case .networkOperationQuote(_, let quoteNetwork, let quoteOperationType):
                        if quoteNetwork == network && operationType == quoteOperationType {
                            // TODO: quoteId?
                            return Quote.NetworkOperationFee(
                                chainId: network.chainId.asUInt,
                                operationType: operationType,
                                usdPrice: price
                            )
                        }

                        return nil
                    default:
                        return nil
                }
            })
            .first
    }

    public func getNetworkFeeAmount(
        symbol: String,
        network: Network,
        operationType: String
    ) -> Amount? {
        if let atlasAsset = Atlas.getAssetBySymbol(network: network, symbol: symbol),
            let assetQuote = getAssetQuote(symbol: symbol),
            let getNetworkOperationFee = getNetworkOperationFee(
                network: network,
                operationType: operationType
            )
        {
            return Amount(
                .pow10(Int(atlasAsset.decimals)) * getNetworkOperationFee.usdPrice.underlying
                    / assetQuote.adjustedPriceUsd.underlying,
                decimals: Int(atlasAsset.decimals)
            )
        }

        return nil
    }

    public func getWrapQuote(
        underlyingNetwork: Network,
        underlyingSymbol: String,
        wrappedNetwork: Network,
        wrappedSymbol: String
    ) -> Percentage? {
        return self.swapHints
            .compactMap({ type, swapHint in
                if case .wrapper(
                    let hintUnderlyingNetwork,
                    let hintUnderlyingSymbol,
                    let hintWrappedNetwork,
                    let hintWrappedSymbol
                ) =
                    type,
                    hintUnderlyingNetwork == underlyingNetwork
                        && hintUnderlyingSymbol.equalIgnoringCase(underlyingSymbol)
                        && hintWrappedNetwork == wrappedNetwork
                        && hintWrappedSymbol.equalIgnoringCase(wrappedSymbol)
                {
                    return swapHint.exchangeRate
                }

                return nil
            })
            .first
    }

    public func getUnwrapQuote(
        underlyingNetwork: Network,
        underlyingSymbol: String,
        wrappedNetwork: Network,
        wrappedSymbol: String
    ) -> Percentage? {
        return self.swapHints
            .compactMap({ type, swapHint in
                if case .wrapper(
                    let hintUnderlyingNetwork,
                    let hintUnderlyingSymbol,
                    let hintWrappedNetwork,
                    let hintWrappedSymbol
                ) =
                    type,
                    hintUnderlyingNetwork == wrappedNetwork
                        && hintUnderlyingSymbol.equalIgnoringCase(wrappedSymbol)
                        && hintWrappedNetwork == underlyingNetwork
                        && hintWrappedSymbol.equalIgnoringCase(underlyingSymbol)
                {
                    return swapHint.exchangeRate
                }

                return nil
            })
            .first
    }

    public func getRelevantSymbols(network: Network, assetSymbol: String) -> Set<String> {
        let relatedSymbols = self.swapHints.compactMap { type, swapHint in
            if case .wrapper(
                let underlyingNetwork,
                let underlyingSymbol,
                let wrappedNetwork,
                let wrappedSymbol
            ) =
                type
            {
                if underlyingNetwork == network && underlyingSymbol.equalIgnoringCase(assetSymbol) {
                    return wrappedSymbol
                }

                if wrappedNetwork == network && wrappedSymbol.equalIgnoringCase(assetSymbol) {
                    return underlyingSymbol
                }
            }

            return nil
        }
        return Set([assetSymbol] + relatedSymbols)
    }

    public func getRelevantWallets() -> Set<EthAddress> {
        return Set(
            self.balances.compactMap { type, balance in
                switch type {
                    case .token(_, _, let wallet):
                        return wallet
                    case .yieldMarket(_, let wallet):
                        return wallet
                    case .borrowMarket(_, let wallet):
                        return wallet
                    case .borrowMarketCollateral(_, _, let wallet):
                        return wallet
                    case .reward(let rewardType):
                        switch rewardType {
                            case .cometReward(_, _, _, _, let wallet):
                                return wallet
                            case .morphoReward(_, _, _, let wallet):
                                return wallet
                        }
                    case .lockedReward(let rewardType):
                        switch rewardType {
                            case .cometReward(_, _, _, _, let wallet):
                                return wallet
                            case .morphoReward(_, _, _, let wallet):
                                return wallet
                        }
                }
            }
        )
    }

    public func getQuoteId(symbol: String) -> Hex? {
        return self.prices
            .compactMap({ type, price in
                if case .assetQuote(let quoteId, let tokenSymbol) = type,
                    tokenSymbol.equalIgnoringCase(symbol)
                {
                    return quoteId
                }

                return nil
            })
            .first
    }

    public func getAcrossQuote(
        sourceNetwork: Network,
        sinkNetwork: Network,
        sourceSymbol: String,
        sinkSymbol: String
    ) -> Folio.BridgeHint? {
        let ethExists = Atlas.getAssetBySymbol(network: sinkNetwork, symbol: "ETH") != nil
        let isSinkETH = sinkSymbol == "ETH"
        let isSinkWETH = sinkSymbol == "WETH"

        // Default: prefer ETH arrival — if ETH exists on sink, disallow WETH sink.
        if isSinkWETH && ethExists { return nil }

        // Normalize: Across is ERC-20 based, query WETH for ETH.
        let querySinkSymbol = isSinkETH ? "WETH" : sinkSymbol

        return self.bridgeHints
            .compactMap({ type, bridgeHint in
                if case .across(
                    let networkIn,
                    let symbolIn,
                    let networkOut,
                    let symbolOut
                ) = type,
                    networkIn == sourceNetwork && symbolIn.equalIgnoringCase(sourceSymbol)
                        && networkOut == sinkNetwork
                        && symbolOut.equalIgnoringCase(querySinkSymbol)
                {
                    return bridgeHint
                }

                return nil
            })
            .first
    }

    public func getRewardBalances(
        symbol: String,
        wallet: EthAddress
    ) -> [(rewardType: RewardType, amount: Amount)] {
        return self.balances.compactMap({ type, balance in
            if case .reward(let rewardType) = type {
                let (rewardSymbol, _) = rewardType.underlyingSymbolAndNetwork
                if rewardType.wallet == wallet
                    && rewardSymbol.equalIgnoringCase(symbol)
                    && !balance.underlying.isZero
                {
                    return (rewardType: rewardType, amount: balance)
                }
            }
            return nil
        })
    }
    
    public func getCCTPv2Quote(
        sourceNetwork: Network,
        sinkNetwork: Network,
        sourceSymbol: String,
        sinkSymbol: String
    ) -> Folio.BridgeHint? {
        return self.bridgeHints
            .compactMap({ type, bridgeHint in
                if case .cctpV2(
                    let networkIn,
                    let symbolIn,
                    let networkOut,
                    let symbolOut
                ) = type,
                    networkIn == sourceNetwork && symbolIn.equalIgnoringCase(sourceSymbol)
                        && networkOut == sinkNetwork && symbolOut.equalIgnoringCase(sinkSymbol)
                {
                    return bridgeHint
                }

                return nil
            })
            .first
    }
}

extension Folio.YieldMarketType {
    public var underlyingSymbolAndNetwork: (String, Network) {
        let underlyingSymbol: String
        let network: Network

        switch self {
            case .aave(let network_, _, let underlyingSymbol_):
                network = network_
                underlyingSymbol = underlyingSymbol_
            case .comet(let network_, _, let underlyingSymbol_):
                network = network_
                underlyingSymbol = underlyingSymbol_
            case .morphoVault(let network_, _, let underlyingSymbol_):
                network = network_
                underlyingSymbol = underlyingSymbol_
            case .stakingToken(let network_, let symbol):
                network = network_
                underlyingSymbol = symbol
        }

        return (underlyingSymbol, network)
    }
}

extension Folio.BorrowMarketType {
    public var underlyingSymbolAndNetwork: (String, Network) {
        let underlyingSymbol: String
        let network: Network

        switch self {
            case .aave(let network_, _, let underlyingSymbol_):
                network = network_
                underlyingSymbol = underlyingSymbol_
            case .comet(let network_, _, let underlyingSymbol_):
                network = network_
                underlyingSymbol = underlyingSymbol_
            case .morpho(let network_, _, let borrowMarketSymbol_):
                network = network_
                underlyingSymbol = borrowMarketSymbol_
        }

        return (underlyingSymbol, network)
    }
}

extension Folio.RewardType {
    public var underlyingSymbolAndNetwork: (String, Network) {
        let underlyingSymbol: String
        let network: Network

        switch self {
            case .cometReward(let network_, _, let underlyingSymbol_, _, _):
                network = network_
                underlyingSymbol = underlyingSymbol_
            case .morphoReward(let network_, let underlyingSymbol_, _, _):
                network = network_
                underlyingSymbol = underlyingSymbol_
        }

        return (underlyingSymbol, network)
    }

    public var wallet: EthAddress {
        switch self {
            case .cometReward(_, _, _, _, let wallet):
                return wallet
            case .morphoReward(_, _, _, let wallet):
                return wallet
        }
    }
}

extension Folio.BalanceType {
    public var atlasAsset: Atlas.Asset? {
        switch self {
            case .token(let network, let symbol, _):
                return Atlas.getAssetBySymbol(network: network, symbol: symbol)
            case .yieldMarket(let yieldMarket, _):
                let (underlyingSymbol, network) = yieldMarket.underlyingSymbolAndNetwork
                return Atlas.getAssetBySymbol(network: network, symbol: underlyingSymbol)
            case .borrowMarket(let borrowMarket, _):
                let (underlyingSymbol, network) = borrowMarket.underlyingSymbolAndNetwork
                return Atlas.getAssetBySymbol(network: network, symbol: underlyingSymbol)
            case .borrowMarketCollateral(let borrowMarket, let tokenSymbol, _):
                let (_, network) = borrowMarket.underlyingSymbolAndNetwork
                return Atlas.getAssetBySymbol(network: network, symbol: tokenSymbol)
            case .reward(let rewardType):
                let (underlyingSymbol, network) = rewardType.underlyingSymbolAndNetwork
                return Atlas.getAssetBySymbol(network: network, symbol: underlyingSymbol)
            case .lockedReward(let rewardType):
                let (underlyingSymbol, network) = rewardType.underlyingSymbolAndNetwork
                return Atlas.getAssetBySymbol(network: network, symbol: underlyingSymbol)
        }
    }
}
