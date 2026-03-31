import Atlas
import Eth
import Prelude
import SwiftNumber
import Tradewinds

public typealias LegendResource = (Number, TradewindsLegendNode)
public typealias TradewindsLegendNode = LegendNode

/// Common node type for Tradewinds tests
public enum LegendNode: TradewindsNode, CustomStringConvertible, Hashable {
    public typealias FeeType = LegendFeeType  // Use LegendFeeType enum for fee type annotations
    // Token balance on a chain
    case aaveSupplyBalance(
        network: Network,
        pool: EthAddress,
        baseAsset: EthAddress,
        wallet: EthAddress
    )
    case cometCollateralBalance(
        network: Network,
        comet: EthAddress,
        collateralAsset: EthAddress,
        wallet: EthAddress
    )
    case cometSupplyBalance(
        network: Network,
        comet: EthAddress,
        baseAsset: EthAddress,
        wallet: EthAddress
    )
    case cometBorrowPosition(
        network: Network,
        comet: EthAddress,
        borrowAsset: EthAddress,
        wallet: EthAddress
    )
    case cometBorrowCapacity(
        network: Network,
        comet: EthAddress,
        borrowAsset: EthAddress,
        wallet: EthAddress
    )
    case morphoCollateralBalance(
        network: Network,
        marketId: Hex,
        collateralAsset: EthAddress,
        wallet: EthAddress
    )
    case morphoBorrowPosition(
        network: Network,
        marketId: Hex,
        borrowAsset: EthAddress,
        wallet: EthAddress
    )
    case morphoBorrowCapacity(
        network: Network,
        marketId: Hex,
        borrowAsset: EthAddress,
        wallet: EthAddress
    )
    case morphoVaultSupplyBalance(
        network: Network,
        vault: EthAddress,
        baseAsset: EthAddress,
        wallet: EthAddress
    )
    case tokenBalance(network: Network, address: ChainAddress, symbol: String, wallet: ChainAddress)
    case loopVenue(
        network: Network,
        marketId: Hex,
        backingAsset: EthAddress,
        exposureAsset: EthAddress,
        wallet: EthAddress
    )
    // Reward sources per market (singular)
    case morphoReward(
        network: Network,
        distributor: EthAddress,
        token: EthAddress,
        wallet: EthAddress
    )
    case cometReward(network: Network, comet: EthAddress, token: EthAddress, wallet: EthAddress)
    // Virtual aggregation node for reward settlement in Tradewinds flow optimization.
    // This shadow node acts as a single target point where all claimed reward tokens converge,
    // solving Tradewinds' single-commodity limitation for multi-token reward claims.
    case rewardSettlement(wallet: EthAddress)
    // Virtual aggregation node for swap settlement in Tradewinds flow optimization.
    // This shadow node enables cross-chain swap target aggregation, allowing Tradewinds to
    // maximize total buyAsset received across all chains rather than targeting a single chain.
    case swapSettlement(wallet: EthAddress)
    // Virtual balance node for aggregating balances across chains with a global constraint.
    // This node holds the total amount to distribute as its resource.
    // Routes from this node to each chain's token balance have maxFlow = that chain's actual balance.
    // Token balances receive flow from this node and pass it to swaps/bridges.
    // For exact amounts: resource = amount constrains total flow globally
    // For max intent: resource = MAX_UINT_256 (no constraint)
    case virtualBalance(symbol: String, wallet: EthAddress)
    // Virtual node for operations that must execute regardless of token resources.
    // This shadow node acts as either a source or sink when an operation needs to execute but has no
    // token resources to flow (e.g., loop operations with zero backing amount, unloop operations
    // with zero backing exit). The node provides a "virtual resource" or "virtual target" to force
    // route selection in Tradewinds optimization.
    case virtualNode(network: Network, routeType: LegendRouteType, wallet: EthAddress)

    var label: String {
        switch self {
            case .aaveSupplyBalance(let network, let pool, _, let wallet):
                return "\(pool)(\(network))(\(wallet))"
            case .cometCollateralBalance(let network, let comet, _, let wallet):
                return "\(comet)(\(network))(\(wallet))"
            case .cometSupplyBalance(let network, let comet, _, let wallet):
                return "\(comet)(\(network))(\(wallet))"
            case .cometBorrowPosition(let network, let comet, _, let wallet):
                return "\(comet)(\(network))(\(wallet))"
            case .cometBorrowCapacity(let network, let comet, _, let wallet):
                return "BorrowCap(\(comet))(\(network))(\(wallet))"
            case .morphoCollateralBalance(let network, let marketId, _, let wallet):
                return "\(marketId)(\(network))(\(wallet))"
            case .morphoBorrowPosition(let network, let marketId, _, let wallet):
                return "\(marketId)(\(network))(\(wallet))"
            case .morphoBorrowCapacity(let network, let marketId, _, let wallet):
                return "BorrowCap(\(marketId))(\(network))(\(wallet))"
            case .tokenBalance(let network, _, let symbol, let wallet):
                return "\(symbol)(\(network))(\(wallet))"
            case .morphoVaultSupplyBalance(let network, let vault, _, let wallet):
                return "\(vault)(\(network))(\(wallet))"
            case .loopVenue(let network, let marketId, _, _, let wallet):
                return "Loop(\(marketId))(\(network))(\(wallet))"
            case .morphoReward(let network, let distributor, let token, let wallet):
                return "MorphoReward(\(distributor))(\(network))(\(token))(\(wallet)))"
            case .cometReward(let network, let comet, let token, let wallet):
                return "CometReward(\(comet))(\(network))(\(token))(\(wallet))"
            case .rewardSettlement(let wallet):
                return "RewardSettlement(\(wallet))"
            case .swapSettlement(let wallet):
                return "SwapSettlement(\(wallet))"
            case .virtualBalance(let symbol, let wallet):
                return "VirtualBalance(\(symbol))(\(wallet))"
            case .virtualNode(let network, let routeType, let wallet):
                return "VirtualNode[\(routeType.identifier)](\(network))(\(wallet))"
        }
    }

    public var description: String {
        switch self {
            case .cometCollateralBalance(let network, let comet, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let cometAddress = comet.address.description
                let cometPrefix = String(cometAddress.prefix(6))
                let cometSuffix = String(cometAddress.suffix(4))
                return "CometCol[\(network)][\(cometPrefix)...\(cometSuffix)][0x\(walletSuffix)]"
            case .cometSupplyBalance(let network, let comet, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let cometAddress = comet.address.description
                let cometPrefix = String(cometAddress.prefix(6))
                let cometSuffix = String(cometAddress.suffix(4))
                return "Comet[\(network)][\(cometPrefix)...\(cometSuffix)][0x\(walletSuffix)]"
            case .cometBorrowPosition(let network, let comet, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let cometAddress = comet.address.description
                let cometPrefix = String(cometAddress.prefix(6))
                let cometSuffix = String(cometAddress.suffix(4))
                return "CometDebt[\(network)][\(cometPrefix)...\(cometSuffix)][0x\(walletSuffix)]"
            case .cometBorrowCapacity(let network, let comet, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let cometAddress = comet.address.description
                let cometPrefix = String(cometAddress.prefix(6))
                let cometSuffix = String(cometAddress.suffix(4))
                return "CometBorrowCap[\(network)][\(cometPrefix)...\(cometSuffix)][0x\(walletSuffix)]"
            case .aaveSupplyBalance(let network, let pool, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let poolAddress = pool.address.description
                let poolPrefix = String(poolAddress.prefix(6))
                let poolSuffix = String(poolAddress.suffix(4))
                return "Aave[\(network)][\(poolPrefix)...\(poolSuffix)][0x\(walletSuffix)]"
            case .morphoCollateralBalance(let network, let marketId, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let marketIdString = marketId.description
                let marketPrefix = String(marketIdString.prefix(6))
                let marketSuffix = String(marketIdString.suffix(4))
                return "MorphoCol[\(network)][\(marketPrefix)...\(marketSuffix)][0x\(walletSuffix)]"
            case .morphoBorrowPosition(let network, let marketId, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let marketIdString = marketId.description
                let marketPrefix = String(marketIdString.prefix(6))
                let marketSuffix = String(marketIdString.suffix(4))
                return
                    "MorphoDebt[\(network)][\(marketPrefix)...\(marketSuffix)][0x\(walletSuffix)]"
            case .morphoBorrowCapacity(let network, let marketId, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let marketIdString = marketId.description
                let marketPrefix = String(marketIdString.prefix(6))
                let marketSuffix = String(marketIdString.suffix(4))
                return
                    "MorphoBorrowCap[\(network)][\(marketPrefix)...\(marketSuffix)][0x\(walletSuffix)]"
            case .morphoVaultSupplyBalance(let network, let vault, _, let wallet):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let vaultAddress = vault.address.description
                let vaultPrefix = String(vaultAddress.prefix(6))  // First 6 chars including "0x"
                let vaultSuffix = String(vaultAddress.suffix(4))  // Last 4 chars
                return "Morpho[\(network)][\(vaultPrefix)...\(vaultSuffix)][0x\(walletSuffix)]"
            case .tokenBalance(let network, _, let symbol, let wallet):
                let walletSuffix = String(wallet.displayString.suffix(6))
                return "\(symbol)[\(network)][\(walletSuffix)]"
            case .loopVenue(
                let network,
                let marketId,
                let backingAsset,
                let exposureAsset,
                let wallet
            ):
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                let marketIdString = marketId.description
                let marketPrefix = String(marketIdString.prefix(6))
                let marketSuffix = String(marketIdString.suffix(4))
                let backingAddress = backingAsset.address.description
                let backingSuffix = String(backingAddress.suffix(4))
                let exposureAddress = exposureAsset.address.description
                let exposureSuffix = String(exposureAddress.suffix(4))
                return
                    "Loop[\(network)][\(marketPrefix)...\(marketSuffix)][0x\(backingSuffix)->0x\(exposureSuffix)][0x\(walletSuffix)]"
            case .morphoReward(let network, let distributor, let token, let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                let distPrefix = String(distributor.address.description.prefix(6))
                let distSuffix = String(distributor.address.description.suffix(4))
                let tokenSuffix = String(token.address.description.suffix(4))
                return
                    "MorphoReward[\(network)][\(distPrefix)...\(distSuffix)][0x\(tokenSuffix)][0x\(walletSuffix)]"
            case .cometReward(let network, let comet, let token, let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                let cometPrefix = String(comet.address.description.prefix(6))
                let cometSuffix = String(comet.address.description.suffix(4))
                let tokenSuffix = String(token.address.description.suffix(4))
                return
                    "CometReward[\(network)][\(cometPrefix)...\(cometSuffix)][0x\(tokenSuffix)][0x\(walletSuffix)]"
            case .rewardSettlement(let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                return "RewardSettlement[0x\(walletSuffix)]"
            case .swapSettlement(let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                return "SwapSettlement[0x\(walletSuffix)]"
            case .virtualBalance(let symbol, let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                return "VirtualBalance[\(symbol)][0x\(walletSuffix)]"
            case .virtualNode(let network, let routeType, let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                return "VirtualNode[\(routeType.identifier)][\(network)][0x\(walletSuffix)]"
        }
    }

    var wallet: ChainAddress {
        switch self {
            case .cometCollateralBalance(let network, _, _, let wallet): wallet.on(network)
            case .cometSupplyBalance(let network, _, _, let wallet): wallet.on(network)
            case .cometBorrowPosition(let network, _, _, let wallet): wallet.on(network)
            case .cometBorrowCapacity(let network, _, _, let wallet): wallet.on(network)
            case .morphoCollateralBalance(let network, _, _, let wallet): wallet.on(network)
            case .morphoBorrowPosition(let network, _, _, let wallet): wallet.on(network)
            case .morphoBorrowCapacity(let network, _, _, let wallet): wallet.on(network)
            case .tokenBalance(_, _, _, let wallet): wallet
            case .aaveSupplyBalance(let network, _, _, let wallet): wallet.on(network)
            case .morphoVaultSupplyBalance(let network, _, _, let wallet): wallet.on(network)
            case .morphoReward(let network, _, _, let wallet): wallet.on(network)
            case .cometReward(let network, _, _, let wallet): wallet.on(network)
            case .rewardSettlement(let wallet): .ethereum(wallet)
            case .swapSettlement(let wallet): .ethereum(wallet)
            case .virtualBalance(_, let wallet): .ethereum(wallet)
            case .loopVenue(let network, _, _, _, let wallet): wallet.on(network)
            case .virtualNode(let network, _, let wallet): wallet.on(network)
        }
    }

    var network: Network? {
        switch self {
            case .cometCollateralBalance(let network, _, _, _): network
            case .cometSupplyBalance(let network, _, _, _): network
            case .cometBorrowPosition(let network, _, _, _): network
            case .cometBorrowCapacity(let network, _, _, _): network
            case .morphoCollateralBalance(let network, _, _, _): network
            case .morphoBorrowPosition(let network, _, _, _): network
            case .morphoBorrowCapacity(let network, _, _, _): network
            case .tokenBalance(let network, _, _, _): network
            case .aaveSupplyBalance(let network, _, _, _): network
            case .morphoVaultSupplyBalance(let network, _, _, _): network
            case .loopVenue(let network, _, _, _, _):
                network
            case .morphoReward(let network, _, _, _): network
            case .cometReward(let network, _, _, _): network
            case .rewardSettlement: nil
            case .swapSettlement: nil
            case .virtualBalance: nil  // Virtual node, no network
            case .virtualNode(let network, _, _): network
        }
    }

    var assetAddress: ChainAddress? {
        switch self {
            case .aaveSupplyBalance(let network, _, let baseAsset, _): baseAsset.on(network)
            case .cometCollateralBalance(let network, _, let collateralAsset, _): collateralAsset.on(network)
            case .cometSupplyBalance(let network, _, let baseAsset, _): baseAsset.on(network)
            case .cometBorrowPosition(let network, _, let borrowAsset, _): borrowAsset.on(network)
            case .cometBorrowCapacity(let network, _, let borrowAsset, _): borrowAsset.on(network)
            case .morphoCollateralBalance(let network, _, let collateralAsset, _): collateralAsset.on(network)
            case .morphoBorrowPosition(let network, _, let borrowAsset, _): borrowAsset.on(network)
            case .morphoBorrowCapacity(let network, _, let borrowAsset, _): borrowAsset.on(network)
            case .morphoVaultSupplyBalance(let network, _, let baseAsset, _): baseAsset.on(network)
            case .tokenBalance(_, let address, _, _): address
            case .loopVenue(let network, _, let backingAsset, _, _): backingAsset.on(network)
            case .morphoReward(let network, _, let token, _): token.on(network)
            case .cometReward(let network, _, let token, _): token.on(network)
            case .rewardSettlement(_): nil
            case .swapSettlement(_): nil
            case .virtualBalance: nil
            case .virtualNode(_, _, _): nil
        }
    }

    /// The EVM asset address, or nil for Solana/virtual nodes.
    /// Use this in the EVM operation pipeline where EthAddress is required.
    var evmAssetAddress: EthAddress? {
        guard let addr = assetAddress, addr.isEVM else { return nil }
        return addr.ethAddress
    }

    var symbol: String? {
        // tokenBalance nodes store their symbol directly (works for all chains)
        if case .tokenBalance(_, _, let symbol, _) = self {
            return symbol
        }
        // EVM earn market nodes: look up symbol from Atlas via asset address
        switch asAtlasAsset {
            case .success(let atlasAsset):
                return atlasAsset.symbol
            case .failure(_):
                return nil
        }
    }

    public var decimals: Int? {
        // tokenBalance nodes: resolve decimals via Atlas (EVM or Solana)
        if case .tokenBalance(_, let address, _, _) = self {
            if let atlasAsset = Atlas.getAssetByAddress(address) {
                return Int(atlasAsset.decimals)
            }
            return nil
        }
        // EVM earn market nodes
        if case .success(let atlasAsset) = asAtlasAsset {
            return Int(atlasAsset.decimals)
        } else {
            return nil
        }
    }

    var asAtlasAsset: Result<Atlas.EvmAsset, Charter.CharterError> {
        if let network,
            let evmAssetAddress,
            let atlasAsset = Atlas.getEvmAssetByAddress(network: network, token: evmAssetAddress)
        {
            return .success(atlasAsset)
        }

        return .failure(.unknownAsset(symbol: nil, network: network, address: evmAssetAddress))
    }
}
