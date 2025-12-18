import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

let codedBridgeHints =
    "[{\"type\":\"across\",\"symbol_in\":\"USDC\",\"symbol_out\":\"USDC\",\"network_in\":\"mainnet\",\"network_out\":\"optimism\",\"fixed_cost\":\"0.000000e6\",\"max_amount\":\"1000e6\",\"max_amount_instant\":\"500e6\",\"estimated_fill_time_sec\":5,\"min_amount\":\"0.000000e6\",\"rate\":\"0.000000000000000000\"},{\"type\":\"across\",\"symbol_in\":\"WETH\",\"symbol_out\":\"WETH\",\"network_in\":\"mainnet\",\"network_out\":\"optimism\",\"fixed_cost\":\"0.000000000000000000e18\",\"max_amount\":\"10e18\",\"max_amount_instant\":\"5e18\",\"estimated_fill_time_sec\":5,\"min_amount\":\"0.000000000000000000e18\",\"rate\":\"0.000000000000000000\"}]"

@Suite("Bridge Hint Tests")
struct BridgeHintTests {
    @Test("Test Decoding")
    func testQuotes() async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let bridgeHints: [LegendModel.BridgeHint] = try decoder.decode(
            [LegendModel.BridgeHint].self,
            from: codedBridgeHints.data(using: .utf8)!
        )

        #expect(
            bridgeHints
                == [
                    LegendModel.BridgeHint(
                        bridgeType: .across,
                        networkIn: .ethereum,
                        symbolIn: "USDC",
                        networkOut: .optimism,
                        symbolOut: "USDC",
                        minAmount: Amount(0, decimals: 6),
                        maxAmount: Amount("1000000000", decimals: 6),
                        maxAmountInstant: Amount("500000000", decimals: 6),
                        estimatedFillTimeSec: 5,
                        fixedCost: Amount(0, decimals: 6),
                        rate: .zero
                    ),
                    LegendModel.BridgeHint(
                        bridgeType: .across,
                        networkIn: .ethereum,
                        symbolIn: "WETH",
                        networkOut: .optimism,
                        symbolOut: "WETH",
                        minAmount: Amount(0, decimals: 18),
                        maxAmount: Amount("10000000000000000000", decimals: 18),
                        maxAmountInstant: Amount("5000000000000000000", decimals: 18),
                        estimatedFillTimeSec: 5,
                        fixedCost: Amount(0, decimals: 18),
                        rate: .zero
                    ),
                ]
        )
    }
}
