import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

/// Tests that Charter.maxFlow completes in a reasonable time for multi-chain transfer scenarios.
/// Reproduces a bug where maxFlow hangs (takes 100+ seconds) for non-Unichain destinations
/// when USDC balances exist on multiple chains with both Across and CCTP bridge hints.
struct CharterMaxFlowPerformanceTests {

    /// Helper to time a synchronous Charter.maxFlow call
    private static func timedMaxFlow(
        intent: Charter.QuarkIntent.Type_,
        folio: Folio
    ) -> (result: Result<Number, Charter.CharterError>, elapsed: TimeInterval) {
        let start = Date().timeIntervalSince1970
        let result = Charter.maxFlow(intent: intent, folio: folio, logger: nil)
        let elapsed = Date().timeIntervalSince1970 - start
        return (result, elapsed)
    }

    // MARK: - Multi-chain USDC transfer with Across bridge hints

    @Test("Max transfer USDC to Base with multi-chain balances and Across hints completes quickly")
    func testMaxTransferToBaseWithAcrossHints() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(200, .usdc), .base),
            .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
            .tokenBalance(.alice, .amt(50, .usdc), .optimism),
            .acrossQuote(.amt(1, .usdc), 0.01),
        ])

        let (result, elapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(BaseNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Account.alice.address,
                    recipient: Account.bob.address
                )
            ),
            folio: folio
        )

        #expect(elapsed < 5.0, "maxFlow took \(String(format: "%.2f", elapsed))s — should be under 5s")
        if case .success(let amount) = result {
            #expect(amount > Number(0), "maxFlow should return a positive amount")
        } else {
            Issue.record("maxFlow failed: \(result)")
        }
    }

    @Test("Max transfer USDC to Optimism with multi-chain balances and Across hints completes quickly")
    func testMaxTransferToOptimismWithAcrossHints() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(200, .usdc), .base),
            .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
            .tokenBalance(.alice, .amt(50, .usdc), .optimism),
            .acrossQuote(.amt(1, .usdc), 0.01),
        ])

        let (result, elapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(OptimismNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Account.alice.address,
                    recipient: Account.bob.address
                )
            ),
            folio: folio
        )

        #expect(elapsed < 5.0, "maxFlow took \(String(format: "%.2f", elapsed))s — should be under 5s")
        if case .success(let amount) = result {
            #expect(amount > Number(0), "maxFlow should return a positive amount")
        } else {
            Issue.record("maxFlow failed: \(result)")
        }
    }

    // MARK: - Multi-chain USDC transfer with CCTP bridge hints

    @Test("Max transfer USDC to Base with multi-chain balances and CCTP hints completes quickly")
    func testMaxTransferToBaseWithCctpHints() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(200, .usdc), .base),
            .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
            .tokenBalance(.alice, .amt(50, .usdc), .optimism),
            .cctpV2Quote(.amt(0, .usdc), 0.0),
        ])

        let (result, elapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(BaseNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Account.alice.address,
                    recipient: Account.bob.address
                )
            ),
            folio: folio
        )

        #expect(elapsed < 5.0, "maxFlow took \(String(format: "%.2f", elapsed))s — should be under 5s")
        if case .success(let amount) = result {
            #expect(amount > Number(0), "maxFlow should return a positive amount")
        } else {
            Issue.record("maxFlow failed: \(result)")
        }
    }

    // MARK: - Both Across + CCTP (realistic production scenario)

    @Test("Max transfer USDC to Base with both Across and CCTP hints completes quickly")
    func testMaxTransferToBaseWithBothBridgeHints() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(200, .usdc), .base),
            .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
            .tokenBalance(.alice, .amt(50, .usdc), .optimism),
            .tokenBalance(.alice, .amt(50, .usdc), .worldChain),
            .acrossQuote(.amt(1, .usdc), 0.01),
            .cctpV2Quote(.amt(0, .usdc), 0.0),
        ])

        let (result, elapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(BaseNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Account.alice.address,
                    recipient: Account.bob.address
                )
            ),
            folio: folio
        )

        #expect(elapsed < 5.0, "maxFlow took \(String(format: "%.2f", elapsed))s — should be under 5s")
        if case .success(let amount) = result {
            #expect(amount > Number(0), "maxFlow should return a positive amount")
        } else {
            Issue.record("maxFlow failed: \(result)")
        }
    }

    @Test("Max transfer USDC to WorldChain with both Across and CCTP hints completes quickly")
    func testMaxTransferToWorldChainWithBothBridgeHints() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(200, .usdc), .base),
            .tokenBalance(.alice, .amt(50, .usdc), .arbitrum),
            .tokenBalance(.alice, .amt(50, .usdc), .optimism),
            .tokenBalance(.alice, .amt(50, .usdc), .worldChain),
            .acrossQuote(.amt(1, .usdc), 0.01),
            .cctpV2Quote(.amt(0, .usdc), 0.0),
        ])

        let (result, elapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(WorldChainNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Account.alice.address,
                    recipient: Account.bob.address
                )
            ),
            folio: folio
        )

        #expect(elapsed < 5.0, "maxFlow took \(String(format: "%.2f", elapsed))s — should be under 5s")
        if case .success(let amount) = result {
            #expect(amount > Number(0), "maxFlow should return a positive amount")
        } else {
            Issue.record("maxFlow failed: \(result)")
        }
    }

    // MARK: - Production folio tests (reproduce real-world performance regression)

    private static let productionSender = EthAddress("0x6d90e1eee903e3e6a4352d1da352547dde587964")
    private static let productionRecipient = EthAddress("0x4f9e06ef8911035734e2ac6e7cc2ca428bdc01c9")

    private static func loadProductionFolio() throws -> Folio {
        let json = try String(contentsOf: URL(fileURLWithPath: "./Tests/Fixtures/production_folio.json"))
        return try JSONDecoder().decode(Folio.self, from: json.data(using: .utf8)!)
    }

    private static func filterEthereum(from folio: Folio) -> Folio {
        Folio(
            balances: folio.balances.filter { !$0.key.involvesEthereum },
            prices: folio.prices.filter { !$0.key.involvesEthereum },
            yieldMarkets: folio.yieldMarkets.filter { !$0.key.involvesEthereum },
            borrowMarkets: folio.borrowMarkets.filter { !$0.key.involvesEthereum },
            rewards: folio.rewards.filter { !$0.key.involvesEthereum },
            swapHints: folio.swapHints.filter { !$0.key.involvesEthereum },
            bridgeHints: folio.bridgeHints.filter { !$0.key.involvesEthereum },
            hexData: folio.hexData.filter { !$0.key.involvesEthereum },
            completionStatuses: folio.completionStatuses,
            patches: folio.patches
        )
    }

    @Test("Production folio benchmark: full vs no-mainnet (serial)")
    func testProductionFolioBenchmarkSerial() throws {
        let fullFolio = try Self.loadProductionFolio()
        let noMainnetFolio = Self.filterEthereum(from: fullFolio)

        // Run serially: full folio first, then no-mainnet
        let (baseFullResult, baseFullElapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(BaseNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Self.productionSender,
                    recipient: Self.productionRecipient
                )
            ),
            folio: fullFolio
        )

        let (worldFullResult, worldFullElapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(WorldChainNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Self.productionSender,
                    recipient: Self.productionRecipient
                )
            ),
            folio: fullFolio
        )

        let (baseNoEthResult, baseNoEthElapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(BaseNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Self.productionSender,
                    recipient: Self.productionRecipient
                )
            ),
            folio: noMainnetFolio
        )

        let (worldNoEthResult, worldNoEthElapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(WorldChainNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Self.productionSender,
                    recipient: Self.productionRecipient
                )
            ),
            folio: noMainnetFolio
        )

        print("=== Serial benchmark ===")
        print("Base    (full):       \(String(format: "%.3f", baseFullElapsed))s")
        print("Base    (no mainnet): \(String(format: "%.3f", baseNoEthElapsed))s")
        print("World   (full):       \(String(format: "%.3f", worldFullElapsed))s")
        print("World   (no mainnet): \(String(format: "%.3f", worldNoEthElapsed))s")

        for (label, result) in [
            ("Base full", baseFullResult),
            ("Base no-eth", baseNoEthResult),
            ("World full", worldFullResult),
            ("World no-eth", worldNoEthResult),
        ] {
            if case .success(let amount) = result {
                #expect(amount > Number(0), "\(label) should return a positive amount")
            } else {
                Issue.record("\(label) maxFlow failed: \(result)")
            }
        }
    }

    @Test("Production folio: HyperEVM max USDC transfer equals Base max USDC transfer")
    func testProductionFolioHyperEvmMatchesBase() throws {
        let folio = try Self.loadProductionFolio()

        let baseIntent: Charter.QuarkIntent.Type_ = .transfer(
            Charter.TransferIntent(
                chainId: Number(BaseNetwork.chainId),
                assetSymbol: "USDC",
                amount: .MAX_UINT_256,
                sender: Self.productionSender,
                recipient: Self.productionRecipient
            )
        )
        let hyperEvmIntent: Charter.QuarkIntent.Type_ = .transfer(
            Charter.TransferIntent(
                chainId: Number(HyperEVMNetwork.chainId),
                assetSymbol: "USDC",
                amount: .MAX_UINT_256,
                sender: Self.productionSender,
                recipient: Self.productionRecipient
            )
        )

        let baseExtended = Charter.maxFlowExtended(intent: baseIntent, folio: folio, logger: nil)
        let hyperEvmExtended = Charter.maxFlowExtended(intent: hyperEvmIntent, folio: folio, logger: nil)

        guard case .success(let baseResult) = baseExtended else {
            Issue.record("Base maxFlow failed: \(baseExtended)")
            return
        }
        guard case .success(let hyperEvmResult) = hyperEvmExtended else {
            Issue.record("HyperEVM maxFlow failed: \(hyperEvmExtended)")
            return
        }

        // Before the staging loop fix, HyperEVM would return ~0 due to an infinite loop.
        // Both destinations draw from the same source balances; small difference from bridge fees.
        #expect(baseResult.maxFlow == Number(244807053))
        #expect(hyperEvmResult.maxFlow == Number(244792267))
        #expect(baseResult.maxFlow - hyperEvmResult.maxFlow == Number(14786))
    }

    // MARK: - Unichain baseline (known to work fast)

    @Test("Max transfer USDC to Unichain completes quickly (baseline)")
    func testMaxTransferToUnichainBaseline() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(200, .usdc), .base),
            .tokenBalance(.alice, .amt(50, .usdc), .unichain),
            .acrossQuote(.amt(1, .usdc), 0.01),
            .cctpV2Quote(.amt(0, .usdc), 0.0),
        ])

        let (result, elapsed) = Self.timedMaxFlow(
            intent: .transfer(
                Charter.TransferIntent(
                    chainId: Number(UnichainNetwork.chainId),
                    assetSymbol: "USDC",
                    amount: .MAX_UINT_256,
                    sender: Account.alice.address,
                    recipient: Account.bob.address
                )
            ),
            folio: folio
        )

        #expect(elapsed < 5.0, "maxFlow took \(String(format: "%.2f", elapsed))s — should be under 5s")
        if case .success(let amount) = result {
            #expect(amount > Number(0), "maxFlow should return a positive amount")
        } else {
            Issue.record("maxFlow failed: \(result)")
        }
    }
}

// MARK: - Ethereum network filtering helpers

extension Folio.BalanceType {
    var involvesEthereum: Bool {
        switch self {
        case .token(let network, _, _):
            return network == .ethereum
        case .yieldMarket(let yieldMarket, _):
            return yieldMarket.involvesEthereum
        case .borrowMarket(let borrowMarket, _):
            return borrowMarket.involvesEthereum
        case .borrowMarketCollateral(let borrowMarket, _, _):
            return borrowMarket.involvesEthereum
        case .reward(let rewardType):
            return rewardType.involvesEthereum
        case .lockedReward(let rewardType):
            return rewardType.involvesEthereum
        }
    }
}

extension Folio.PriceType {
    var involvesEthereum: Bool {
        switch self {
        case .token:
            return false
        case .assetQuote:
            return false
        case .networkOperationQuote(_, let network, _):
            return network == .ethereum
        }
    }
}

extension Folio.YieldMarketType {
    var involvesEthereum: Bool {
        switch self {
        case .aave(let network, _, _),
             .comet(let network, _, _),
             .morphoVault(let network, _, _),
             .stakingToken(let network, _):
            return network == .ethereum
        }
    }
}

extension Folio.BorrowMarketType {
    var involvesEthereum: Bool {
        switch self {
        case .aave(let network, _, _),
             .comet(let network, _, _),
             .morpho(let network, _, _):
            return network == .ethereum
        }
    }
}

extension Folio.RewardType {
    var involvesEthereum: Bool {
        switch self {
        case .cometReward(let network, _, _, _, _),
             .morphoReward(let network, _, _, _):
            return network == .ethereum
        }
    }
}

extension Folio.SwapHintType {
    var involvesEthereum: Bool {
        switch self {
        case .wrapper(let underlyingNetwork, _, let wrappedNetwork, _):
            return underlyingNetwork == .ethereum || wrappedNetwork == .ethereum
        case .swap(let network, _, _, _, _):
            return network == .ethereum
        }
    }
}

extension Folio.BridgeHintType {
    var involvesEthereum: Bool {
        switch self {
        case .across(let networkIn, _, let networkOut, _),
             .cctpV2(let networkIn, _, let networkOut, _):
            return networkIn == .ethereum || networkOut == .ethereum
        }
    }
}

extension Folio.HexDataType {
    var involvesEthereum: Bool {
        switch self {
        case .nonceSecret(let network, _):
            return network == .ethereum
        }
    }
}
