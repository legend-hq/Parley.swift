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
    case tokenBalance(network: Network, address: EthAddress, symbol: String, wallet: EthAddress)
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
    // Virtual intermediate node for CCTPv2 bridge operation
    // - sourceNetwork: The network where the burn operation occurs (needed for graph uniqueness)
    // - destNetwork: The network where the mint operation executes (this becomes the node's network property)
    // - destAsset: The asset address on the destination network (needed for burn operation construction)
    case cctpBridge(sourceNetwork: Network, destNetwork: Network, destAsset: EthAddress, wallet: EthAddress)
    // Virtual node for operations that must execute regardless of token resources.
    // This shadow node acts as either a source or sink when an operation needs to execute but has no
    // token resources to flow (e.g., loop operations with zero backing amount, unloop operations
    // with zero backing exit). The node provides a "virtual resource" or "virtual target" to force
    // route selection in Tradewinds optimization.
    case virtualNode(network: Network, routeType: LegendRouteType, wallet: EthAddress)
    case never

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
            case .cctpBridge(let sourceNetwork, let destNetwork, _, let wallet):
                return "CCTP Bridge(\(sourceNetwork)->(\(destNetwork))(\(wallet))"
            case .virtualNode(let network, let routeType, let wallet):
                return "VirtualNode[\(routeType.identifier)](\(network))(\(wallet))"
            case .never: return "Never [unexpected error]"
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
                // Show last 5 chars of wallet address (to include the last 4 hex digits plus one more)
                let fullAddress = wallet.address.description
                let walletSuffix = String(fullAddress.suffix(6))
                return "\(symbol)[\(network)][0x\(walletSuffix)]"
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
            case .cctpBridge(let sourceNetwork, let destNetwork, _, let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                return "CCTP Bridge[\(sourceNetwork)->(\(destNetwork))][0x\(walletSuffix)]"
            case .virtualNode(let network, let routeType, let wallet):
                let walletSuffix = String(wallet.address.description.suffix(6))
                return "VirtualNode[\(routeType.identifier)][\(network)][0x\(walletSuffix)]"
            case .never:
                return "Never"
        }
    }

    var wallet: EthAddress? {
        switch self {
            case .cometCollateralBalance(_, _, _, let wallet): wallet
            case .cometSupplyBalance(_, _, _, let wallet): wallet
            case .cometBorrowPosition(_, _, _, let wallet): wallet
            case .cometBorrowCapacity(_, _, _, let wallet): wallet
            case .morphoCollateralBalance(_, _, _, let wallet): wallet
            case .morphoBorrowPosition(_, _, _, let wallet): wallet
            case .morphoBorrowCapacity(_, _, _, let wallet): wallet
            case .tokenBalance(_, _, _, let wallet): wallet
            case .aaveSupplyBalance(_, _, _, let wallet): wallet
            case .morphoVaultSupplyBalance(_, _, _, let wallet): wallet
            case .morphoReward(_, _, _, let wallet): wallet
            case .cometReward(_, _, _, let wallet): wallet
            case .rewardSettlement(let wallet): wallet
            case .loopVenue(_, _, _, _, let wallet): wallet
            case .cctpBridge(_, _, _, let wallet): wallet
            case .virtualNode(_, _, let wallet): wallet
            case .never: nil
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
            case .cctpBridge(_, let destNetwork, _, _): destNetwork
            case .virtualNode(let network, _, _): network
            case .never: nil
        }
    }

    var assetAddress: EthAddress? {
        switch self {
            case .aaveSupplyBalance(_, _, let baseAsset, _): baseAsset
            case .cometCollateralBalance(_, _, let collateralAsset, _): collateralAsset
            case .cometSupplyBalance(_, _, let baseAsset, _): baseAsset
            case .cometBorrowPosition(_, _, let borrowAsset, _): borrowAsset
            case .cometBorrowCapacity(_, _, let borrowAsset, _): borrowAsset
            case .morphoCollateralBalance(_, _, let collateralAsset, _): collateralAsset
            case .morphoBorrowPosition(_, _, let borrowAsset, _): borrowAsset
            case .morphoBorrowCapacity(_, _, let borrowAsset, _): borrowAsset
            case .morphoVaultSupplyBalance(_, _, let baseAsset, _): baseAsset
            case .tokenBalance(_, let address, _, _): address
            case .loopVenue(_, _, let backingAsset, _, _): backingAsset
            case .morphoReward(_, _, let token, _): token
            case .cometReward(_, _, let token, _): token
            case .rewardSettlement(_): nil
            case .cctpBridge(_, _, let destAsset, _): destAsset
            case .virtualNode(_, _, _): nil
            case .never: nil
        }
    }

    var symbol: String? {
        switch asAtlasAsset {
            case .success(let atlasAsset):
                return atlasAsset.symbol
            case .failure(_):
                return nil
        }
    }

    public var decimals: Int? {
        if case .success(let atlasAsset) = asAtlasAsset {
            return Int(atlasAsset.decimals)
        } else {
            return nil
        }
    }

    var asAtlasAsset: Result<Atlas.Asset, Charter.CharterError> {
        if let network,
            let assetAddress,
            let atlasAsset = Atlas.getAssetByAddress(network: network, token: assetAddress)
        {
            return .success(atlasAsset)
        }

        return .failure(.unknownAsset(symbol: nil, network: network, address: assetAddress))
    }
}
