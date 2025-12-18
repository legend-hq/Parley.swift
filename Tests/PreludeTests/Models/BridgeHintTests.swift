import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

let codedBridgeHints =
    "[{\"type\":\"across\",\"symbol_in\":\"USDC\",\"symbol_out\":\"USDC\",\"network_in\":\"mainnet\",\"network_out\":\"optimism\",\"fixed_cost\":\"0.000000e6\",\"max_amount\":null,\"min_amount\":\"0.000000e6\",\"rate\":\"0.000000000000000000\"},{\"type\":\"across\",\"symbol_in\":\"WETH\",\"symbol_out\":\"WETH\",\"network_in\":\"mainnet\",\"network_out\":\"optimism\",\"fixed_cost\":\"0.000000000000000000e18\",\"max_amount\":null,\"min_amount\":\"0.000000000000000000e18\",\"rate\":\"0.000000000000000000\"}]"

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
                        maxAmount: nil,
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
                        maxAmount: nil,
                        fixedCost: Amount(0, decimals: 18),
                        rate: .zero
                    ),
                ]
        )
    }
}
