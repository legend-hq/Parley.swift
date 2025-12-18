import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import TestHelpers
import Testing

@testable import Charter

struct CharterTotalAvailableBalanceTests {

    @Test("Single chain balance - direct availability")
    func testSingleChainDirect() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(100, .usdc), .base)
        ])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            destinationChain: .base,
            folio: folio,
            actorWallet: Account.alice.address,
            allowUsingEarningBalances: false
        )

        #expect(available == "100e6")
    }

    @Test("Cross-chain with bridge - accounts for fees")
    func testCrossChainWithBridge() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(100, .usdc), .ethereum),
            .acrossQuote(.amt(1, .usdc), 0.01)
        ])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            destinationChain: .base,
            folio: folio,
            actorWallet: Account.alice.address,
            allowUsingEarningBalances: false
        )

        #expect(available == "98e6")
    }

    @Test("Multiple chains - aggregates cross-chain balances")
    func testMultipleChains() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(50, .usdc), .base),
            .tokenBalance(.alice, .amt(50, .usdc), .ethereum),
            .acrossQuote(.amt(1, .usdc), 0.01)
        ])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            destinationChain: .base,
            folio: folio,
            actorWallet: Account.alice.address,
            allowUsingEarningBalances: false
        )

        #expect(available == "98.5e6")
    }

    @Test("No balance - returns zero")
    func testNoBalance() {
        let folio = generateFolio(from: [])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            destinationChain: .base,
            folio: folio,
            actorWallet: Account.alice.address,
            allowUsingEarningBalances: false
        )

        #expect(available == Number(0))
    }

    @Test("Includes earning balances from yield markets when enabled")
    func testIncludesEarningBalances() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(50, .usdc), .base),
            .cometSupply(.alice, .amt(50, .usdc), .cusdcv3, .base)
        ])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            destinationChain: .base,
            folio: folio,
            actorWallet: Account.alice.address,
            allowUsingEarningBalances: true
        )

        // Returns 100.0005 USDC due to MAX_WITHDRAW_BUFFER (1.00001x) applied to max withdrawals
        // from earning markets. This buffer accounts for interest accrual between calculation and execution.
        #expect(available == "100.0005e6")
    }

    @Test("Excludes earning balances from yield markets when disabled")
    func testExcludesEarningBalances() {
        let folio = generateFolio(from: [
            .tokenBalance(.alice, .amt(50, .usdc), .base),
            .cometSupply(.alice, .amt(50, .usdc), .cusdcv3, .base)
        ])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            destinationChain: .base,
            folio: folio,
            actorWallet: Account.alice.address,
            allowUsingEarningBalances: false
        )

        #expect(available == "50e6")
    }

    @Test("Unknown asset - returns zero")
    func testUnknownAsset() {
        let folio = generateFolio(from: [])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "NONEXISTENT",
            destinationChain: .base,
            folio: folio,
            actorWallet: Account.alice.address,
            allowUsingEarningBalances: false
        )

        #expect(available == Number(0))
    }
}
