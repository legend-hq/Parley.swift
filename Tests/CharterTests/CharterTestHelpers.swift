import Atlas
import Eth
import Foundation
import SwiftNumber

@testable import Charter

// Test helper for creating resources from Atlas EVM assets
extension Atlas.EvmAsset {
    func asResource(_ amount: Double, wallet: EthAddress) -> LegendResource {
        let amountWithDecimals = Number(amount, decimals: Int(self.decimals))
        let network = Network.base  // Default for now, should be passed or inferred
        let node = TradewindsLegendNode.tokenBalance(
            network: network,
            address: self.assetAddress.on(network),
            symbol: self.symbol,
            wallet: wallet.on(network)
        )
        return (amountWithDecimals, node)
    }
}

// Extension to help with network-aware resource creation
extension BaseNetwork.Assets {
    static func asResource(_ asset: Atlas.EvmAsset, amount: Double, wallet: EthAddress)
        -> LegendResource
    {
        let amountWithDecimals = Number(amount, decimals: Int(asset.decimals))
        let node = TradewindsLegendNode.tokenBalance(
            network: BaseNetwork.network,
            address: asset.assetAddress.on(BaseNetwork.network),
            symbol: asset.symbol,
            wallet: wallet.on(BaseNetwork.network)
        )
        return (amountWithDecimals, node)
    }
}
