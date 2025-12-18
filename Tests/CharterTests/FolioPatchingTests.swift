import Atlas
import Charter
import Eth
import Foundation
import Prelude
import SwiftNumber
import Testing

@testable import Charter

@Suite("Folio Patching Tests")
struct FolioPatchingTests {

    // Test wallet addresses
    let alice: EthAddress = "0x00000000000000000000000000000000000a11ce"
    let bob: EthAddress = "0x0000000000000000000000000000000000000b0b"

    // Test token addresses
    let usdcToken: EthAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
    let wethToken: EthAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
    let daiToken: EthAddress = "0x6b175474e89094c44da98b954eedeac495271d0f"
    let wstETHToken: EthAddress = "0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0"

    // Test protocol addresses
    let aavePool: EthAddress = "0x1234567890abcdef1234567890abcdef12345678"
    let cometAddress: EthAddress = "0xabcdef1234567890abcdef1234567890abcdef12"
    let morphoVault: EthAddress = "0x5678901234567890abcdef1234567890abcdef12"

    // MARK: - Token Transfer Tests

    @Test("Simple token transfer patching")
    func testTokenTransfer() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .token(network: .base, symbol: "USDC", wallet: bob): Amount("500e6"),
        ]

        let transferContext = Charter.ActionContext.transfer(
            .init(
                amount: Number("100e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),  // Base chain
                price: Number("1e8"),
                recipient: bob,
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: transferContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("900e6"),
                .token(network: .base, symbol: "USDC", wallet: bob): Amount("600e6"),
            ]
        )
    }

    @Test("Handles missing recipient")
    func testMissingRecipient() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6")
        ]

        let transferContext = Charter.ActionContext.transfer(
            .init(
                amount: Number("100e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),  // Base chain
                price: Number("1e8"),
                recipient: bob,
                token: usdcToken
            )
        )

        // New behavior: missing recipient balances are auto-created
        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: transferContext,
            andQuarkWalletAddress: alice
        )

        // Verify Alice's balance was reduced
        #expect(
            balances[.token(network: .base, symbol: "USDC", wallet: alice)]
                == Amount("900e6")
        )

        // Verify Bob's balance was auto-created and credited
        #expect(
            balances[.token(network: .base, symbol: "USDC", wallet: bob)]
                == Amount("100e6")
        )
    }

    @Test("Transfer with insufficient balance")
    func testTransferInsufficientBalance() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("100e6"),
            .token(network: .base, symbol: "USDC", wallet: bob): Amount("0e6"),
        ]

        let transferContext = Charter.ActionContext.transfer(
            .init(
                amount: Number("200e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                price: Number("1e8"),
                recipient: bob,
                token: usdcToken
            )
        )

        // New behavior: insufficient balance is capped at 0
        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: transferContext,
            andQuarkWalletAddress: alice
        )

        // Verify Alice's balance was capped at 0 (had 100, tried to send 200)
        #expect(
            balances[.token(network: .base, symbol: "USDC", wallet: alice)]
                == Amount("0e6")
        )

        // Verify Bob received the full requested amount (200 USDC)
        #expect(
            balances[.token(network: .base, symbol: "USDC", wallet: bob)]
                == Amount("200e6")
        )
    }

    // MARK: - Swap Tests

    @Test("Token swap patching")
    func testTokenSwap() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .ethereum, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .token(network: .ethereum, symbol: "WETH", wallet: alice): Amount("1e18"),
        ]

        let swapContext = Charter.ActionContext.swap(
            .init(
                chainId: Number("1"),  // Ethereum
                feeAmounts: [Number("0")],
                feeAssetSymbols: ["USDC"],
                feeTokens: [usdcToken],
                feeTokenPrices: [Number("1e8")],
                feeDescriptions: ["Legend Fee"],
                inputAmount: Number("500e6"),
                inputAssetSymbol: "USDC",
                inputToken: usdcToken,
                inputTokenPrice: Number("1e8"),
                outputAmount: Number("0.2e18"),
                outputAssetSymbol: "WETH",
                outputToken: wethToken,
                outputTokenPrice: Number("2500e8"),
                isExactOut: false,
                isBuy: false,
                isCappedMax: false,
                useFiller: false
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: swapContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .ethereum, symbol: "USDC", wallet: alice): Amount("500e6"),
                .token(network: .ethereum, symbol: "WETH", wallet: alice): Amount("1.2e18"),
            ]
        )
    }

    // MARK: - Bridge Tests

    @Test("Bridge operation patching")
    func testBridge() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .token(network: .arbitrum, symbol: "USDC", wallet: alice): Amount("500e6"),
        ]

        let bridgeContext = Charter.ActionContext.bridge(
            .init(
                assetSymbol: "USDC",
                bridgeType: .across,
                chainId: Number("8453"),  // Base (source)
                destinationChainId: Number("42161"),  // Arbitrum (destination)
                destinationAssetSymbol: "USDC",
                inputAmount: Number("200e6"),
                outputAmount: Number("199e6"),  // After fees
                price: Number("1e8"),
                recipient: alice,
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: bridgeContext,
            andQuarkWalletAddress: alice
        )

        // Both source and destination balances should be affected
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("800e6"),
                .token(network: .arbitrum, symbol: "USDC", wallet: alice): Amount("699e6"),
            ]
        )
    }

    // MARK: - Lending Supply Tests

    @Test("Aave supply patching")
    func testAaveSupply() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .yieldMarket(
                yieldMarket: .aave(network: .base, pool: aavePool, underlyingSymbol: "USDC"),
                wallet: alice
            ): Amount("0e6"),
        ]

        let supplyContext = Charter.ActionContext.aaveSupply(
            .init(
                amount: Number("300e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                aavePool: aavePool,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: supplyContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("700e6"),
                .yieldMarket(
                    yieldMarket: Folio.YieldMarketType.aave(
                        network: .base,
                        pool: aavePool,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("300e6"),
            ]
        )
    }

    @Test("Comet supply patching")
    func testCometSupply() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .yieldMarket(
                yieldMarket: Folio.YieldMarketType.comet(
                    network: .base,
                    comet: cometAddress,
                    underlyingSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("0e6"),
        ]

        let supplyContext = Charter.ActionContext.cometSupply(
            .init(
                amount: Number("400e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                comet: cometAddress,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: supplyContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("600e6"),
                .yieldMarket(
                    yieldMarket: Folio.YieldMarketType.comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("400e6"),
            ]
        )
    }

    // MARK: - Lending Withdraw Tests

    @Test("Aave withdraw patching")
    func testAaveWithdraw() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("100e6"),
            .yieldMarket(
                yieldMarket: .aave(network: .base, pool: aavePool, underlyingSymbol: "USDC"),
                wallet: alice
            ): Amount("500e6"),
        ]

        let withdrawContext = Charter.ActionContext.aaveWithdraw(
            .init(
                amount: Number("200e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                aavePool: aavePool,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: withdrawContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("300e6"),
                .yieldMarket(
                    yieldMarket: Folio.YieldMarketType.aave(
                        network: .base,
                        pool: aavePool,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("300e6"),
            ]
        )
    }

    @Test("Aave withdraw max amount")
    func testAaveWithdrawMax() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("100e6"),
            .yieldMarket(
                yieldMarket: .aave(network: .base, pool: aavePool, underlyingSymbol: "USDC"),
                wallet: alice
            ): Amount("500e6"),
        ]

        let withdrawContext = Charter.ActionContext.aaveWithdraw(
            .init(
                amount: Number.max,
                assetSymbol: "USDC",
                chainId: Number("8453"),
                aavePool: aavePool,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: withdrawContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("600e6"),
                .yieldMarket(
                    yieldMarket: Folio.YieldMarketType.aave(
                        network: .base,
                        pool: aavePool,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("0e6"),
            ]
        )
    }

    // MARK: - Borrowing Tests

    @Test("Comet borrow patching")
    func testCometBorrow() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("10e18"),
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("100e6"),
            .borrowMarketCollateral(
                borrowMarket: .comet(network: .base, comet: cometAddress, underlyingSymbol: "USDC"),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("0e18"),
            .borrowMarket(
                borrowMarket: .comet(network: .base, comet: cometAddress, underlyingSymbol: "USDC"),
                wallet: alice
            ): Amount("0e6"),
        ]

        let borrowContext = Charter.ActionContext.cometBorrow(
            .init(
                amount: Number("1000e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                collateralAmounts: [Number("1e18")],
                collateralAssetSymbols: ["WETH"],
                collateralTokenPrices: [Number("2500e8")],
                collateralTokens: [wethToken],
                comet: cometAddress,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: borrowContext,
            andQuarkWalletAddress: alice
        )

        // Should receive borrowed USDC, borrow balance, less collateral, plus collateral positions
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1100e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("9e18"),
                .borrowMarketCollateral(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("1e18"),
                .borrowMarket(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("1000e6"),
            ]
        )
    }

    @Test("Comet repay patching")
    func testCometRepayNormal() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1500e6"),
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("2e18"),
            .borrowMarketCollateral(
                borrowMarket: .comet(network: .base, comet: cometAddress, underlyingSymbol: "USDC"),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("1e18"),
            .borrowMarket(
                borrowMarket: .comet(network: .base, comet: cometAddress, underlyingSymbol: "USDC"),
                wallet: alice
            ): Amount("1000e6"),
        ]

        let repayContext = Charter.ActionContext.cometRepay(
            .init(
                amount: Number("250e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                collateralAmounts: [Number("0.3e18")],
                collateralAssetSymbols: ["WETH"],
                collateralTokenPrices: [Number("2500e8")],
                collateralTokens: [wethToken],
                comet: cometAddress,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: repayContext,
            andQuarkWalletAddress: alice
        )

        // USDC should be reduced by repay amount
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1250e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("2.3e18"),
                .borrowMarketCollateral(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("0.7e18"),
                .borrowMarket(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("750e6"),
            ]
        )
    }

    @Test("Comet repay max amount")
    func testCometRepayMax() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1500e6"),
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
            .borrowMarket(
                borrowMarket: .comet(network: .base, comet: cometAddress, underlyingSymbol: "USDC"),
                wallet: alice
            ): Amount("1000e6"),
            .borrowMarketCollateral(
                borrowMarket: .comet(network: .base, comet: cometAddress, underlyingSymbol: "USDC"),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("1e18"),
        ]

        let repayContext = Charter.ActionContext.cometRepay(
            .init(
                amount: Number.max,
                assetSymbol: "USDC",
                chainId: Number("8453"),
                collateralAmounts: [Number("0.9e18")],
                collateralAssetSymbols: ["WETH"],
                collateralTokenPrices: [Number("2500e8")],
                collateralTokens: [wethToken],
                comet: cometAddress,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: repayContext,
            andQuarkWalletAddress: alice
        )

        // Should repay full borrow amount (1000e6)
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("500e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1.9e18"),
                .borrowMarket(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("0e6"),
                .borrowMarketCollateral(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("0.1e18"),
            ]
        )
    }

    // MARK: - Claim Rewards Tests

    @Test("Comet claim rewards patching")
    func testCometClaimRewards() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "COMP", wallet: alice): Amount("10e18", decimals: 18)
        ]

        let claimContext = Charter.ActionContext.cometClaimRewards(
            .init(
                amounts: [Number("5e18")],
                assetSymbols: ["COMP"],
                chainId: Number("8453"),
                prices: [Number("50e8")],
                tokens: [EthAddress("0xc00e94cb662c3520282e6f5717214004a7f26888")]
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: claimContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "COMP", wallet: alice): Amount("15e18")
            ]
        )
    }

    // MARK: - Multi-Action Tests

    @Test("Multi-action patching")
    func testMultiAction() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .token(network: .base, symbol: "DAI", wallet: alice): Amount("500e18"),
            .token(network: .base, symbol: "USDC", wallet: bob): Amount("0e6"),
            .token(network: .base, symbol: "DAI", wallet: bob): Amount("0e18"),
        ]

        // Create multiple sub-actions
        let transfer1 = Charter.ActionContext.transfer(
            .init(
                amount: Number("100e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                price: Number("1e8"),
                recipient: bob,
                token: usdcToken
            )
        )

        let transfer2 = Charter.ActionContext.transfer(
            .init(
                amount: Number("50e18"),
                assetSymbol: "DAI",
                chainId: Number("8453"),
                price: Number("1e8"),
                recipient: bob,
                token: daiToken
            )
        )

        let multiContext = Charter.ActionContext.multiAction(
            [transfer1, transfer2]
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: multiContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("900e6"),
                .token(network: .base, symbol: "DAI", wallet: alice): Amount("450e18"),
                .token(network: .base, symbol: "USDC", wallet: bob): Amount("100e6"),
                .token(network: .base, symbol: "DAI", wallet: bob): Amount("50e18"),
            ]
        )
    }

    // MARK: - Wrap/Unwrap Tests

    @Test("Wrap ETH to WETH 1:1")
    func testWrapEthToWeth() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .ethereum, symbol: "ETH", wallet: alice): Amount("5e18"),
            .token(network: .ethereum, symbol: "WETH", wallet: alice): Amount("1e18"),
        ]

        let swapHints: [Folio.SwapHintType: Folio.SwapHint] = [
            .wrapper(
                underlyingNetwork: .ethereum,
                underlyingSymbol: "ETH",
                wrappedNetwork: .ethereum,
                wrappedSymbol: "WETH"
            ): Folio.SwapHint(
                minAmount: Amount("0e18"),
                maxAmount: nil,
                exchangeRate: try Percentage(scientificString: "1.00")
            )
        ]

        let wrapContext = Charter.ActionContext.wrap(
            .init(
                chainId: Number("1"),
                amount: Number("2e18"),
                token: wethToken,
                fromAssetSymbol: "ETH",
                toAssetSymbol: "WETH"
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: swapHints,
            withActionContext: wrapContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .ethereum, symbol: "ETH", wallet: alice): Amount("3e18"),
                .token(network: .ethereum, symbol: "WETH", wallet: alice): Amount("3e18"),
            ]
        )
    }

    @Test("Unwrap WETH to ETH 1:1")
    func testUnwrapWethToEth() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .ethereum, symbol: "ETH", wallet: alice): Amount("1e18"),
            .token(network: .ethereum, symbol: "WETH", wallet: alice): Amount("3e18"),
        ]
        let swapHints: [Folio.SwapHintType: Folio.SwapHint] = [
            .wrapper(
                underlyingNetwork: .ethereum,
                underlyingSymbol: "ETH",
                wrappedNetwork: .ethereum,
                wrappedSymbol: "WETH"
            ): Folio.SwapHint(
                minAmount: Amount("0e18"),
                maxAmount: nil,
                exchangeRate: try Percentage(scientificString: "1.00")
            )
        ]

        let unwrapContext = Charter.ActionContext.unwrap(
            .init(
                chainId: Number("1"),
                amount: Number("2e18"),
                token: wethToken,
                fromAssetSymbol: "WETH",
                toAssetSymbol: "ETH"
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: swapHints,
            withActionContext: unwrapContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .ethereum, symbol: "ETH", wallet: alice): Amount("3e18"),
                .token(network: .ethereum, symbol: "WETH", wallet: alice): Amount("1e18"),
            ]
        )
    }

    @Test("Unwrap wstETH to stETH 10:1")
    func testUnwrapWstETHToStETH() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .ethereum, symbol: "stETH", wallet: alice): Amount("1e18"),
            .token(network: .ethereum, symbol: "wstETH", wallet: alice): Amount("3e18"),
        ]

        let swapHints: [Folio.SwapHintType: Folio.SwapHint] = [
            .wrapper(
                underlyingNetwork: .ethereum,
                underlyingSymbol: "stETH",
                wrappedNetwork: .ethereum,
                wrappedSymbol: "wstETH"
            ): Folio.SwapHint(
                minAmount: Amount("0e18"),
                maxAmount: nil,
                exchangeRate: try Percentage(scientificString: "10.00")
            )
        ]

        let unwrapContext = Charter.ActionContext.unwrap(
            .init(
                chainId: Number("1"),
                amount: Number("2e18"),
                token: wstETHToken,
                fromAssetSymbol: "wstETH",
                toAssetSymbol: "stETH"
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: swapHints,
            withActionContext: unwrapContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .ethereum, symbol: "stETH", wallet: alice): Amount("21e18"),
                .token(network: .ethereum, symbol: "wstETH", wallet: alice): Amount("1e18"),
            ]
        )
    }

    @Test("Wrap stETH to wstETH 10:1")
    func testWrapStETHToWstETH() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .ethereum, symbol: "stETH", wallet: alice): Amount("21e18"),
            .token(network: .ethereum, symbol: "wstETH", wallet: alice): Amount("1e18"),
        ]
        let swapHints: [Folio.SwapHintType: Folio.SwapHint] = [
            .wrapper(
                underlyingNetwork: .ethereum,
                underlyingSymbol: "stETH",
                wrappedNetwork: .ethereum,
                wrappedSymbol: "wstETH"
            ): Folio.SwapHint(
                minAmount: Amount("0e18"),
                maxAmount: nil,
                exchangeRate: try Percentage(scientificString: "10.00")
            )
        ]

        let wrapContext = Charter.ActionContext.wrap(
            .init(
                chainId: Number("1"),
                amount: Number("20e18"),
                token: wstETHToken,
                fromAssetSymbol: "stETH",
                toAssetSymbol: "wstETH"
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: swapHints,
            withActionContext: wrapContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .ethereum, symbol: "stETH", wallet: alice): Amount("1e18"),
                .token(network: .ethereum, symbol: "wstETH", wallet: alice): Amount("3e18"),
            ]
        )
    }

    @Test("Wrapping with missing swap hint")
    func testWrapMissingSwapHint() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .ethereum, symbol: "ETH", wallet: alice): Amount("5e18"),
            .token(network: .ethereum, symbol: "WETH", wallet: alice): Amount("1e18"),
        ]

        let wrapContext = Charter.ActionContext.wrap(
            .init(
                chainId: Number("1"),
                amount: Number("2e18"),
                token: wethToken,
                fromAssetSymbol: "ETH",
                toAssetSymbol: "WETH"
            )
        )

        do {
            try Folio.patchBalances(
                balances: &balances,
                swapHints: [:],
                withActionContext: wrapContext,
                andQuarkWalletAddress: alice
            )
            #expect(Bool(false))
        } catch {
            #expect(
                error as? PatchError
                    == PatchError.swapHintNotFound(
                        underlyingNetwork: .ethereum,
                        underlyingSymbol: "ETH",
                        wrappedNetwork: .ethereum,
                        wrappedSymbol: "WETH"
                    )
            )
        }
    }

    // MARK: - Edge Cases

    @Test("Quote pay patching")
    func testQuotePay() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6")
        ]

        let quotePayContext = Charter.ActionContext.quotePay(
            .init(
                amount: Number("250e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                price: Number("1e8"),
                payee: bob,
                quoteId: Hex("0x1234"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: quotePayContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("750e6")
            ]
        )
    }

    // MARK: - Morpho Tests

    @Test("Morpho vault supply patching")
    func testMorphoVaultSupply() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .yieldMarket(
                yieldMarket: .morphoVault(
                    network: .base,
                    vault: morphoVault,
                    underlyingSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("500e6"),
        ]

        let supplyContext = Charter.ActionContext.morphoVaultSupply(
            .init(
                amount: Number("200e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                morphoVault: morphoVault,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: supplyContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("800e6"),
                .yieldMarket(
                    yieldMarket: .morphoVault(
                        network: .base,
                        vault: morphoVault,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("700e6"),
            ]
        )
    }

    @Test("Morpho vault withdraw patching")
    func testMorphoVaultWithdraw() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("100e6"),
            .yieldMarket(
                yieldMarket: .morphoVault(
                    network: .base,
                    vault: morphoVault,
                    underlyingSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("500e6"),
        ]

        let withdrawContext = Charter.ActionContext.morphoVaultWithdraw(
            .init(
                amount: Number("150e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                morphoVault: morphoVault,
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: withdrawContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("250e6"),
                .yieldMarket(
                    yieldMarket: .morphoVault(
                        network: .base,
                        vault: morphoVault,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("350e6"),
            ]
        )
    }

    @Test("Morpho borrow patching")
    func testMorphoBorrow() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("10e18"),
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("100e6"),
            .borrowMarketCollateral(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("0e18"),
            .borrowMarket(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("0e6"),
        ]

        let borrowContext = Charter.ActionContext.morphoBorrow(
            .init(
                amount: Number("1000e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                collateralAmount: Number("2e18"),
                collateralAssetSymbol: "WETH",
                collateralTokenPrice: Number("2500e8"),
                collateralToken: wethToken,
                morpho: EthAddress("0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"),
                morphoMarketId: Hex("0x5678"),
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: borrowContext,
            andQuarkWalletAddress: alice
        )

        // Should receive borrowed USDC
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1100e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("8e18"),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("2e18"),
                .borrowMarket(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("1000e6"),
            ]
        )
    }

    @Test("Morpho repay patching")
    func testMorphoRepay() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1500e6"),
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("0e18"),
            .borrowMarketCollateral(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("2e18"),
            .borrowMarket(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("1000e6"),
        ]

        let repayContext = Charter.ActionContext.morphoRepay(
            .init(
                amount: Number("500e6"),
                assetSymbol: "USDC",
                chainId: Number("8453"),
                collateralAmount: Number("1e18"),
                collateralAssetSymbol: "WETH",
                collateralTokenPrice: Number("2500e8"),
                collateralToken: wethToken,
                morpho: EthAddress("0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"),
                morphoMarketId: Hex("0x5678"),
                price: Number("1e8"),
                token: usdcToken
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: repayContext,
            andQuarkWalletAddress: alice
        )

        // USDC should be reduced by repay amount
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("1e18"),
                .borrowMarket(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("500e6"),
            ]
        )
    }

    @Test("Morpho claim rewards patching")
    func testMorphoClaimRewards() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "MORPHO", wallet: alice): Amount("100e18")
        ]

        let claimContext = Charter.ActionContext.morphoClaimRewards(
            .init(
                amounts: [Number("25e18")],
                assetSymbols: ["MORPHO"],
                chainId: Number("8453"),
                prices: [Number("10e8")],
                tokens: [EthAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")]
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: claimContext,
            andQuarkWalletAddress: alice
        )

        #expect(
            balances == [
                .token(network: .base, symbol: "MORPHO", wallet: alice): Amount("125e18")
            ]
        )
    }

    // MARK: - Loop Tests

    @Test("Add backing token patching")
    func testAddBackingToken() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("5000e6"),
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
            .borrowMarket(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("2500e6"),
            .borrowMarketCollateral(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("1e18"),
        ]

        let addBackingContext = Charter.ActionContext.addBackingToken(
            .init(
                amount: Number("1000e6"),
                backingAssetSymbol: "USDC",
                backingToken: usdcToken,
                backingTokenPrice: Number("1e8"),
                chainId: Number("8453"),
                exposureAssetSymbol: "WETH",
                exposureToken: wethToken,
                exposureTokenPrice: Number("2500e8"),
                borrowVenue: "morpho",
                borrowMarketId: Hex("0x1234"),
                isShort: false
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: addBackingContext,
            andQuarkWalletAddress: alice
        )

        // Token should be reduced
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("4000e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
                .borrowMarket(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("1500e6"),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("1e18"),
            ]
        )
    }

    @Test("Withdraw backing token patching")
    func testWithdrawBackingToken() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6"),
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
            .borrowMarket(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("2000e6"),
            .borrowMarketCollateral(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("1e18"),
        ]

        let withdrawBackingContext = Charter.ActionContext.withdrawBackingToken(
            .init(
                amount: Number("500e6"),
                backingAssetSymbol: "USDC",
                backingToken: usdcToken,
                backingTokenPrice: Number("1e8"),
                chainId: Number("8453"),
                exposureAssetSymbol: "WETH",
                exposureToken: wethToken,
                exposureTokenPrice: Number("2500e8"),
                borrowVenue: "morpho",
                borrowMarketId: Hex("0x1234"),
                isShort: false
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: withdrawBackingContext,
            andQuarkWalletAddress: alice
        )

        // Token should be increased
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1500e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
                .borrowMarket(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("2500e6"),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("1e18"),
            ]
        )
    }

    @Test("Loop long patching")
    func testLoopLong() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("8000e6"),
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
            .borrowMarket(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("0e6"),
            .borrowMarketCollateral(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("0e18"),
        ]

        let loopLongContext = Charter.ActionContext.loopLong(
            .init(
                backingAssetSymbol: "USDC",
                backingToken: usdcToken,
                backingTokenPrice: Number("1e8"),
                maxSwapBackingAmount: Number("2500e6"),
                maxProvidedBackingAmount: Number("2000e6"),
                chainId: Number("8453"),
                isIncrease: true,
                exposureAmount: Number("0.5e18"),
                exposureAssetSymbol: "WETH",
                exposureToken: wethToken,
                exposureTokenPrice: Number("2500e8"),
                swapVenue: "morpho",
                borrowVenue: "morpho",
                borrowMarketId: Hex("0x5678"),
                feeAmount: Number("0.8e6"),
                feeAssetSymbol: "USDC",
                feeToken: usdcToken,
                feeTokenPrice: Number("1e8")
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: loopLongContext,
            andQuarkWalletAddress: alice
        )

        // Token should be reduced
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("6000e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
                .borrowMarket(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("500e6"),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("0.5e18"),
            ]
        )
    }

    @Test("Unloop long patching")
    func testUnloopLong() throws {
        var balances: [Folio.BalanceType: Amount] = [
            .token(network: .base, symbol: "USDC", wallet: alice): Amount("6000e6"),
            .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
            .borrowMarket(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                wallet: alice
            ): Amount("500e6"),
            .borrowMarketCollateral(
                borrowMarket: .morpho(
                    network: .base,
                    collateralTokenSymbol: "WETH",
                    borrowTokenSymbol: "USDC"
                ),
                tokenSymbol: "WETH",
                wallet: alice
            ): Amount("0.5e18"),
        ]

        let unloopLongContext = Charter.ActionContext.unloopLong(
            .init(
                backingAssetSymbol: "USDC",
                backingToken: usdcToken,
                backingTokenPrice: Number("1e8"),
                minSwapBackingAmount: Number("2500e6"),
                backingAmountToExit: Number("2000e6"),
                chainId: Number("8453"),
                exposureAmount: Number("0.5e18"),
                exposureAssetSymbol: "WETH",
                exposureToken: wethToken,
                exposureTokenPrice: Number("2500e8"),
                swapVenue: "morpho",
                borrowVenue: "morpho",
                borrowMarketId: Hex("0x5678"),
                feeAmount: Number("0.8e6"),
                feeAssetSymbol: "USDC",
                feeToken: usdcToken,
                feeTokenPrice: Number("1e8")
            )
        )

        try Folio.patchBalances(
            balances: &balances,
            swapHints: [:],
            withActionContext: unloopLongContext,
            andQuarkWalletAddress: alice
        )

        // Token should be reduced
        #expect(
            balances == [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("8000e6"),
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1e18"),
                .borrowMarket(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("0e6"),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("0e18"),
            ]
        )
    }
}
