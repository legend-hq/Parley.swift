import Eth
import Prelude
import SwiftNumber
import Tradewinds

/// Merges adjacent swap hint flows from the same venue into single operations.
enum SwapHints {

    typealias Flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>

    /// Groups adjacent swap flows by (chain, sellToken, buyToken, venue) and merges each group.
    /// Non-swap flows pass through unchanged. Internal routing flows are filtered out.
    static func aggregateFlows(_ flows: [Flow]) -> [Flow] {
        // Filter out internal routing flows
        let relevantFlows = flows.filter { flow in
            flow.route.type != .balancePassthrough && flow.route.type != .swapSettlement
        }

        // Group adjacent flows by swap key
        var groups: [[Flow]] = []
        for flow in relevantFlows {
            let key = swapKey(for: flow)
            if let lastGroup = groups.last,
               let lastKey = swapKey(for: lastGroup[0]),
               key == lastKey {
                groups[groups.count - 1].append(flow)
            } else {
                groups.append([flow])
            }
        }

        // Merge each group
        return groups.compactMap(merge)
    }

    // MARK: - Private

    /// Returns grouping key for swap hint flows. Nil for non-swap or V1 swaps.
    private static func swapKey(for flow: Flow) -> String? {
        guard case .swap(_, _, _, _, _, _, _, _, let venue) = flow.route.type,
              let venue, // Only SwapHint swaps have a venue
              let network = flow.route.source.network,
              let sellSymbol = flow.route.source.symbol,
              let buySymbol = flow.route.sink.symbol else {
            return nil
        }
        return "\(network.chainId):\(sellSymbol):\(buySymbol):\(venue)"
    }

    /// Merges flows into one. Returns first flow unchanged if only one, or nil if empty.
    private static func merge(_ flows: [Flow]) -> Flow? {
        guard let first = flows.first else { return nil }
        guard flows.count > 1 else { return first }
        guard case .swap(let buyToken, _, _, _, let feeToken, _, let isExactOut, let isCappedMax, let venue) = first.route.type else {
            return first
        }

        let totalSell = flows.reduce(Number(0)) { $0 + $1.amount }
        let totalBuy = flows.reduce(Number(0)) { $0 + $1.sinkAmount }

        return Flow(
            route: Tradewinds.Route(
                type: .swap(
                    buyToken: buyToken,
                    buyAmount: totalBuy,
                    swapQuoteSellAmount: totalSell,
                    swapQuoteBuyAmount: totalBuy,
                    feeToken: feeToken,
                    feeAmount: Number(0),
                    isExactOut: isExactOut,
                    isCappedMax: isCappedMax,
                    venue: venue
                ),
                source: first.route.source,
                sink: first.route.sink,
                rate: Percentage(fromRatio: totalBuy.asSNumber, over: totalSell.asSNumber),
                minFlow: Number(0),
                maxFlow: totalSell
            ),
            amount: totalSell
        )
    }
}
