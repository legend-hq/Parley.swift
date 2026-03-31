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
            folio: folio,
            actorWallet: Account.alice.address.on(.base),
            earnMarketPolicy: .none
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
            folio: folio,
            actorWallet: Account.alice.address.on(.base),
            earnMarketPolicy: .none
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
            folio: folio,
            actorWallet: Account.alice.address.on(.base),
            earnMarketPolicy: .none
        )

        #expect(available == "98.5e6")
    }

    @Test("No balance - returns zero")
    func testNoBalance() {
        let folio = generateFolio(from: [])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            folio: folio,
            actorWallet: Account.alice.address.on(.base),
            earnMarketPolicy: .none
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
            folio: folio,
            actorWallet: Account.alice.address.on(.base),
            earnMarketPolicy: .all
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
            folio: folio,
            actorWallet: Account.alice.address.on(.base),
            earnMarketPolicy: .none
        )

        #expect(available == "50e6")
    }

    @Test("Unknown asset - returns zero")
    func testUnknownAsset() {
        let folio = generateFolio(from: [])

        let available = Charter.totalAvailableBalance(
            assetSymbol: "NONEXISTENT",
            folio: folio,
            actorWallet: Account.alice.address.on(.base),
            earnMarketPolicy: .none
        )

        #expect(available == Number(0))
    }

    @Test("Solana balance only uses the actor wallet")
    func testSolanaUsesActorWalletOnly() {
        let aliceSolana: SolanaAddress = "7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV"
        let bobSolana: SolanaAddress = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"

        let folio = Folio(
            balances: [
                .token(
                    network: .solana,
                    symbol: "USDC",
                    wallet: .solana(aliceSolana)
                ): Amount("1000000", decimals: 6),
                .token(
                    network: .solana,
                    symbol: "USDC",
                    wallet: .solana(bobSolana)
                ): Amount("2000000", decimals: 6),
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let available = Charter.totalAvailableBalance(
            assetSymbol: "USDC",
            folio: folio,
            actorWallet: .solana(aliceSolana),
            earnMarketPolicy: .none
        )

        #expect(available == "1e6")
    }
}
