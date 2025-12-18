import Atlas
import Eth
import Prelude
import SwiftNumber

extension Folio {
    public func quoteCost(routeType: LegendRouteType, symbol: String, network: Network) -> Number? {
        if let operationType = routeType.operationType {
            return getNetworkFeeAmount(
                symbol: symbol,
                network: network,
                operationType: operationType
            )?
            .underlying
        }

        return nil
    }
}
