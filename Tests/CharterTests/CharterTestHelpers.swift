import Atlas
import Eth
import Foundation
import SwiftNumber

@testable import Charter

// Test helper for creating resources from Atlas assets
extension Atlas.Asset {
    func asResource(_ amount: Double, wallet: EthAddress) -> LegendResource {
        let amountWithDecimals = Number(amount, decimals: Int(self.decimals))
        // Determine network from the asset - this is a bit of a hack since Asset doesn't have network info
        // We'll need to infer it from context or pass it separately
        let network = Network.base  // Default for now, should be passed or inferred
        let node = TradewindsLegendNode.tokenBalance(
            network: network,
            address: self.assetAddress,
            symbol: self.symbol,
            wallet: wallet
        )
        return (amountWithDecimals, node)
    }
}

// Extension to help with network-aware resource creation
extension BaseNetwork.Assets {
    static func asResource(_ asset: Atlas.Asset, amount: Double, wallet: EthAddress)
        -> LegendResource
    {
        let amountWithDecimals = Number(amount, decimals: Int(asset.decimals))
        let node = TradewindsLegendNode.tokenBalance(
            network: BaseNetwork.network,
            address: asset.assetAddress,
            symbol: asset.symbol,
            wallet: wallet
        )
        return (amountWithDecimals, node)
    }
}
