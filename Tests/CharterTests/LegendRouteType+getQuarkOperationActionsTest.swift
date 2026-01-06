import Atlas
import Charter
import Eth
import Foundation
import Prelude
import SwiftNumber
import Testing
import Tradewinds

@testable import Charter

@Suite("LegendRouteType+getQuarkOperationActions Tests", .serialized)
struct LegendRouteType_getQuarkOperationActionsTests {

    let alice: EthAddress = "0x00000000000000000000000000000000000a11ce"
    let bob: EthAddress = "0x0000000000000000000000000000000000000b0b"

    @Test("Simple token transfer action - direct call")
    func testDirectCallTokenTransfer() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("10.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .tokenTransfer,
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: bob
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("10.0e6").underlying
        )

        let actual = flow.getQuarkOperationActions(
            folio: folio,
            nonceSecret: "0x112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00",
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil
        )

        let expected: Result<[Charter.QuarkOperationAction], Charter.CharterError> = .success(
            [
                .init(
                    operation: Charter.Chart.QuarkOperation(
                        nonce: "0x112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00",
                        isReplayable: false,
                        scriptAddress: Create2.getScriptAddress(TransferActions.creationCode),
                        scriptSources: [],
                        scriptCalldata: try! TransferActions.transferERC20TokenFn.encoded(with: [
                            .address(BaseNetwork.Assets.USDC.assetAddress),
                            .address(bob),
                            .uint256(Amount("10.0e6").underlying),
                            .bool(false),
                        ]),
                        expiry: 100_000 + Charter.TRANSFER_EXPIRY_BUFFER
                    ),
                    action: Charter.Chart.Action(
                        chainId: 8453,
                        quarkAccount: alice,
                        actionType: Charter.ActionContext.TransferActionContext.actionType,
                        actionContext: .transfer(
                            Charter.ActionContext.TransferActionContext(
                                amount: Amount("10.0e6").underlying,
                                assetSymbol: "USDC",
                                chainId: 8453,
                                price: Number("1.0e8"),
                                recipient: bob,
                                token: BaseNetwork.Assets.USDC.assetAddress
                            )
                        ),
                        nonceSecret:
                            "0x112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00",
                        totalPlays: 1,
                        executionType: .immediate
                    )
                )
            ])

        #expect(actual == expected)
    }

    @Test("Simple token transfer action")
    func testTokenTransfer() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("10.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .tokenTransfer,
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: bob
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("10.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ActionContext.TransferActionContext.actionType,
                            actionContext: .transfer(
                                Charter.ActionContext.TransferActionContext(
                                    amount: Amount("10.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    price: Number("1.0e8"),
                                    recipient: bob,
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(TransferActions.creationCode),
                            scriptFunction: TransferActions.transferERC20TokenFn,
                            scriptCallValues: [
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .address(bob),
                                .uint256(Amount("10.0e6").underlying),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.TRANSFER_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Transfer Out (External Transfer)")
    func testTransferOut() {
        let externalAddress: EthAddress = "0x1234567890123456789012345678901234567890"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("100.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .transferOut,
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: externalAddress
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("50.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        // transferOut uses the same implementation as tokenTransfer
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ActionContext.TransferActionContext.actionType,
                            actionContext: .transfer(
                                Charter.ActionContext.TransferActionContext(
                                    amount: Amount("50.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    price: Number("1.0e8"),
                                    recipient: externalAddress,
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(TransferActions.creationCode),
                            scriptFunction: TransferActions.transferERC20TokenFn,
                            scriptCallValues: [
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .address(externalAddress),
                                .uint256(Amount("50.0e6").underlying),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.TRANSFER_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Simple native token transfer action")
    func testNativeTokenTransfer() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "ETH", wallet: alice): Amount("1.0e18")
            ],
            prices: [
                .token(symbol: "ETH"): Value("4000e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .tokenTransfer,
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.ETH.assetAddress,
                symbol: "ETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.ETH.assetAddress,
                symbol: "ETH",
                wallet: bob
            ),
            rate: .one,
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_UNWRAP,
                            actionContext: .unwrap(
                                Charter.ActionContext.UnwrapActionContext(
                                    chainId: 8453,
                                    amount: Amount("0.5e18").underlying,
                                    token: BaseNetwork.Assets.WETH.assetAddress,
                                    fromAssetSymbol: "WETH",
                                    toAssetSymbol: "ETH"
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(WrapperActions.creationCode),
                            scriptFunction: WrapperActions.unwrapWETHUpToFn,
                            scriptCallValues: [
                                .address(BaseNetwork.Assets.WETH.assetAddress),
                                .uint256(Amount("0.5e18").underlying)
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER, 
                            network: .base
                        ),
                        .init(
                            actionType: Charter.ActionContext.TransferActionContext.actionType,
                            actionContext: .transfer(
                                Charter.ActionContext.TransferActionContext(
                                    amount: Amount("0.5e18").underlying,
                                    assetSymbol: "ETH",
                                    chainId: 8453,
                                    price: Number("4000.0e8"),
                                    recipient: bob,
                                    token: BaseNetwork.Assets.ETH.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(TransferActions.creationCode),
                            scriptFunction: TransferActions.transferNativeTokenFn,
                            scriptCallValues: [
                                .address(bob),
                                .uint256(Amount("0.5e18").underlying),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.TRANSFER_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Simple bridge action")
    func testSimpleBridgeAction() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("100.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ],
            bridgeHints: [
                .across(
                    networkIn: .base,
                    symbolIn: "USDC",
                    networkOut: .arbitrum,
                    symbolOut: "USDC"
                ): Folio.BridgeHint(
                    minAmount: Amount("5.0e6"),
                    maxAmount: Amount("100.0e6"),
                    maxAmountInstant: Amount("50.0e6"),
                    estimatedFillTimeSec: 5,
                    fixedCost: Amount("10.0e6"),
                    rate: Percentage(fromDouble: 0.01)  // 1% fee rate
                )
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .bridge(bridgeType: .across, isCappedMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .arbitrum,
                address: ArbitrumNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: bob
            ),
            rate: Percentage(fromDouble: 0.9),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("10.0e6").underlying
        )

        let inputAmount = Amount("10.0e6")
        let outputAmount = Amount("9.0e6")

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ActionContext.BridgeActionContext.actionType,
                            actionContext: .bridge(
                                Charter.ActionContext.BridgeActionContext(
                                    assetSymbol: "USDC",
                                    bridgeType: .across,
                                    chainId: 8453,
                                    destinationChainId: Number(ArbitrumNetwork.chainId),
                                    destinationAssetSymbol: "USDC",
                                    inputAmount: inputAmount.underlying,
                                    outputAmount: outputAmount.underlying,
                                    price: Number("1.0e8"),
                                    recipient: bob,
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(AcrossActions.creationCode),
                            scriptFunction: AcrossActions.depositV3Fn,
                            scriptCallValues: [
                                .address(BaseNetwork.acrossSpokePool),
                                .tuple12(
                                    .address(alice),
                                    .address(bob),
                                    .address(BaseNetwork.Assets.USDC.assetAddress),
                                    .address(ArbitrumNetwork.Assets.USDC.assetAddress),
                                    .uint256(inputAmount.underlying),
                                    .uint256(outputAmount.underlying),
                                    .uint256(Number(ArbitrumNetwork.chainId)),
                                    .address(
                                        EthAddress("0x0000000000000000000000000000000000000000")
                                    ),
                                    .uint32(UInt(99970)),
                                    .uint32(UInt(100600)),
                                    .uint32(0),
                                    .bytes(Hex(""))
                                ),
                                .bytes(Charter.ACROSS_UNIQUE_IDENTIFIER),
                                .bool(false),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.BRIDGE_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Wrap ETH to WETH")
    func testWrapETHToWETH() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "ETH", wallet: alice): Amount("1.0e18")
            ],
            prices: [
                .token(symbol: "ETH"): Value("3000e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .wrap,
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.ETH.assetAddress,
                symbol: "ETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ActionContext.WrapActionContext.actionType,
                            actionContext: .wrap(
                                Charter.ActionContext.WrapActionContext(
                                    chainId: 8453,
                                    amount: Amount("0.5e18").underlying,
                                    token: BaseNetwork.Assets.ETH.assetAddress,
                                    fromAssetSymbol: "ETH",
                                    toAssetSymbol: "WETH"
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(WrapperActions.creationCode),
                            scriptFunction: WrapperActions.wrapAllETHFn,
                            scriptCallValues: [
                                .address(BaseNetwork.Assets.WETH.assetAddress)
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Unwrap WETH to ETH")
    func testUnwrapWETHToETH() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("2.0e18")
            ],
            prices: [
                .token(symbol: "WETH"): Value("3000e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .unwrap,
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.ETH.assetAddress,
                symbol: "ETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("1.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ActionContext.UnwrapActionContext.actionType,
                            actionContext: .unwrap(
                                Charter.ActionContext.UnwrapActionContext(
                                    chainId: 8453,
                                    amount: Amount("1.5e18").underlying,
                                    token: BaseNetwork.Assets.WETH.assetAddress,
                                    fromAssetSymbol: "WETH",
                                    toAssetSymbol: "ETH"
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(WrapperActions.creationCode),
                            scriptFunction: WrapperActions.unwrapWETHUpToFn,
                            scriptCallValues: [
                                .address(BaseNetwork.Assets.WETH.assetAddress),
                                .uint256(Amount("1.5e18").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Wrap stETH to wstETH")
    func testWrapStETHToWstETH() {
        let folio = Folio(
            balances: [
                .token(network: .ethereum, symbol: "stETH", wallet: alice): Amount("1.0e18")
            ],
            prices: [
                .token(symbol: "stETH"): Value("3000e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .wrap,
            source: TradewindsLegendNode.tokenBalance(
                network: .ethereum,
                address: EthereumNetwork.Assets.stETH.assetAddress,
                symbol: "stETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .ethereum,
                address: EthereumNetwork.Assets.wstETH.assetAddress,
                symbol: "wstETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 0.5),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ActionContext.WrapActionContext.actionType,
                            actionContext: .wrap(
                                Charter.ActionContext.WrapActionContext(
                                    chainId: 1,
                                    amount: Amount("0.5e18").underlying,
                                    token: EthereumNetwork.Assets.stETH.assetAddress,
                                    fromAssetSymbol: "stETH",
                                    toAssetSymbol: "wstETH"
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(WrapperActions.creationCode),
                            scriptFunction: WrapperActions.wrapAllLidoStETHFn,
                            scriptCallValues: [
                                .address(EthereumNetwork.Assets.wstETH.assetAddress),
                                .address(EthereumNetwork.Assets.stETH.assetAddress)
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER, 
                            network: .ethereum
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Swap USDC to ETH")
    func testSwapUSDCToETH() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "ETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .swap(
                buyToken: BaseNetwork.Assets.ETH.assetAddress,
                buyAmount: Number("0.163333333333333333e18"),  // ~0.163 ETH
                swapQuoteSellAmount: Amount("500e6").underlying,
                swapQuoteBuyAmount: Number("0.163333333333333333e18"),
                feeToken: BaseNetwork.Assets.USDC.assetAddress,  // Use USDC as fee token
                feeAmount: Number(0),
                isExactOut: false,
                isBuy: false,
                isCappedMax: false
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.ETH.assetAddress,
                symbol: "ETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 0.98),  // 2% slippage
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let outputAmount = Number("0.163333333333333333e18")  // ~0.163 ETH (500 USDC * 0.98 / 3000)

        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ActionContext.SwapActionContext.actionType,
                            actionContext: .swap(
                                Charter.ActionContext.SwapActionContext(
                                    chainId: 8453,
                                    feeAmounts: [Number("0.000244999999999999e18")],
                                    feeAssetSymbols: ["ETH"],
                                    feeTokens: [
                                        BaseNetwork.Assets.ETH.assetAddress
                                    ],
                                    feeTokenPrices: [Number("3000e8")],
                                    feeDescriptions: ["LEGEND"],
                                    inputAmount: Amount("500e6").underlying,
                                    inputAssetSymbol: "USDC",
                                    inputToken: BaseNetwork.Assets.USDC.assetAddress,
                                    inputTokenPrice: Number("1e8"),
                                    outputAmount: outputAmount,
                                    outputAssetSymbol: "ETH",
                                    outputToken: BaseNetwork.Assets.ETH.assetAddress,
                                    outputTokenPrice: Number("3000e8"),
                                    isExactOut: false,
                                    isBuy: false,
                                    isCappedMax: false,
                                    useFiller: true
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(ApproveAndSwap.creationCode),
                            scriptFunction: ApproveAndSwap.swapExactInFn,
                            scriptCallValues: [
                                .address(EthAddress("0xbf68331ae59b923694120bc3b9aa90943a591b3e")),  // Filler address
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500e6").underlying),
                                .address(BaseNetwork.Assets.ETH.assetAddress),
                                .uint256(outputAmount),
                                .address(BaseNetwork.Assets.ETH.assetAddress),  // Fee token
                                .uint256(Number("0.000244999999999999e18")),  // Fee amount
                                .address(EthAddress("0x7ea8d6119596016935543d90ee8f5126285060a1")),  // Fee recipient
                                .bool(false),
                            ],
                            expiryBuffer: Charter.SWAP_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Supply")
    func testCometSupply() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometSupply(isCappedMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.cometSupplyBalance(
                network: .base,
                comet: cometAddress,
                baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_SUPPLY,
                            actionContext: .cometSupply(
                                Charter.ActionContext.CometSupplyActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometSupplyActions.creationCode
                            ),
                            scriptFunction: CometSupplyActions.supplyFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500.0e6").underlying),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Withdraw")
    func testCometWithdraw() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [
                .borrowMarket(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometWithdraw(isMax: false),
            source: TradewindsLegendNode.cometSupplyBalance(
                network: .base,
                comet: cometAddress,
                baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("300.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_WITHDRAW,
                            actionContext: .cometWithdraw(
                                Charter.ActionContext.CometWithdrawActionContext(
                                    amount: Amount("300.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometWithdrawActions.creationCode
                            ),
                            scriptFunction: CometWithdrawActions.withdrawFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("300.0e6").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Supply Collateral")
    func testCometSupplyCollateral() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1.0e18")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometSupplyCollateral(isCappedMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.cometCollateralBalance(
                network: .base,
                comet: cometAddress,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_BORROW,
                            actionContext: .cometBorrow(
                                Charter.ActionContext.CometBorrowActionContext(
                                    amount: Number("0"),
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [Amount("0.5e18").underlying],
                                    collateralAssetSymbols: ["WETH"],
                                    collateralTokenPrices: [Number("3000.0e8")],
                                    collateralTokens: [BaseNetwork.Assets.WETH.assetAddress],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometSupplyMultipleAssetsAndBorrow.creationCode
                            ),
                            scriptFunction: CometSupplyMultipleAssetsAndBorrow.runFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .array(.address, [.address(BaseNetwork.Assets.WETH.assetAddress)]),
                                .array(.uint256, [.uint256(Amount("0.5e18").underlying)]),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Number("0")),
                                .array(.bool, [.bool(false)]),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Borrow")
    func testCometBorrow() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [
                .borrowMarketCollateral(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): Amount("1.0e18")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometBorrow(
                asset: BaseNetwork.Assets.USDC.assetAddress,
                amount: Amount("500.0e6").underlying
            ),
            source: TradewindsLegendNode.cometCollateralBalance(
                network: .base,
                comet: cometAddress,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_BORROW,
                            actionContext: .cometBorrow(
                                Charter.ActionContext.CometBorrowActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [],
                                    collateralAssetSymbols: [],
                                    collateralTokenPrices: [],
                                    collateralTokens: [],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometWithdrawActions.creationCode
                            ),
                            scriptFunction: CometWithdrawActions.withdrawFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500.0e6").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Repay")
    func testCometRepay() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6"),
                .borrowMarket(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("500.0e6"),  // Borrow position
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometRepay(isMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.cometBorrowPosition(
                network: .base,
                comet: cometAddress,
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("300.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_REPAY,
                            actionContext: .cometRepay(
                                Charter.ActionContext.CometRepayActionContext(
                                    amount: Amount("300.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [],
                                    collateralAssetSymbols: [],
                                    collateralTokenPrices: [],
                                    collateralTokens: [],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometRepayAndWithdrawMultipleAssets.creationCode
                            ),
                            scriptFunction: CometRepayAndWithdrawMultipleAssets.runFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .array(.address, []),
                                .array(.uint256, []),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("300.0e6").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Supply Collateral")
    func testMorphoSupplyCollateral() {
        // Using Base USDC/WETH market from Atlas
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("2.0e18")
            ],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoSupplyCollateral(isCappedMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.morphoCollateralBalance(
                network: .base,
                marketId: marketId,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("1.0e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_BORROW,
                            actionContext: .morphoBorrow(
                                Charter.ActionContext.MorphoBorrowActionContext(
                                    amount: Number(0),
                                    assetSymbol: "USDC",  // This would be determined from the market
                                    chainId: 8453,
                                    collateralAmount: Amount("1.0e18").underlying,
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number("3000.0e8"),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress  // This would be determined from the market
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.supplyCollateralAndBorrowFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Amount("1.0e18").underlying),  // collateral amount
                                .uint256(Number(0)),  // No borrow
                                .bool(false),  // isCappedMax
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Vault Supply")
    func testMorphoVaultSupply() {
        let vaultAddress = BaseNetwork.MorphoVaults.mwUSDC.vault

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoVaultSupply(isCappedMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.morphoVaultSupplyBalance(
                network: .base,
                vault: vaultAddress,
                baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_VAULT_SUPPLY,
                            actionContext: .morphoVaultSupply(
                                Charter.ActionContext.MorphoVaultSupplyActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    morphoVault: vaultAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                MorphoVaultActions.creationCode
                            ),
                            scriptFunction: MorphoVaultActions.depositFn,
                            scriptCallValues: [
                                .address(vaultAddress),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500.0e6").underlying),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Vault Withdraw")
    func testMorphoVaultWithdraw() {
        let vaultAddress = BaseNetwork.MorphoVaults.mwUSDC.vault

        let folio = Folio(
            balances: [
                .yieldMarket(
                    yieldMarket: .morphoVault(
                        network: .base,
                        vault: vaultAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoVaultWithdraw(isMax: false),
            source: TradewindsLegendNode.morphoVaultSupplyBalance(
                network: .base,
                vault: vaultAddress,
                baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("300.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_VAULT_WITHDRAW,
                            actionContext: .morphoVaultWithdraw(
                                Charter.ActionContext.MorphoVaultWithdrawActionContext(
                                    amount: Amount("300.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    morphoVault: vaultAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                MorphoVaultActions.creationCode
                            ),
                            scriptFunction: MorphoVaultActions.withdrawFn,
                            scriptCallValues: [
                                .address(vaultAddress),
                                .uint256(Amount("300.0e6").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Aave Supply")
    func testAaveSupply() {
        let aavePoolAddress = BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .aaveSupply(isCappedMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.aaveSupplyBalance(
                network: .base,
                pool: aavePoolAddress,
                baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_AAVE_SUPPLY,
                            actionContext: .aaveSupply(
                                Charter.ActionContext.AaveSupplyActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    aavePool: aavePoolAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(AaveActions.creationCode),
                            scriptFunction: AaveActions.supplyFn,
                            scriptCallValues: [
                                .address(aavePoolAddress),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500.0e6").underlying),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Aave Withdraw")
    func testAaveWithdraw() {
        let aavePoolAddress = BaseNetwork.AaveMarkets.AaveV3BASEMarket.pool

        let folio = Folio(
            balances: [
                .yieldMarket(
                    yieldMarket: .aave(
                        network: .base,
                        pool: aavePoolAddress,
                        underlyingSymbol: "USDC"
                    ),
                    wallet: alice
                ): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .aaveWithdraw(isMax: false),
            source: TradewindsLegendNode.aaveSupplyBalance(
                network: .base,
                pool: aavePoolAddress,
                baseAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("300.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_AAVE_WITHDRAW,
                            actionContext: .aaveWithdraw(
                                Charter.ActionContext.AaveWithdrawActionContext(
                                    amount: Amount("300.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    aavePool: aavePoolAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(AaveActions.creationCode),
                            scriptFunction: AaveActions.withdrawFn,
                            scriptCallValues: [
                                .address(aavePoolAddress),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("300.0e6").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Supply Collateral And Borrow")
    func testCometSupplyCollateralAndBorrow() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1.0e18")
            ],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometSupplyCollateralAndBorrow(
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                borrowAmount: Amount("500.0e6").underlying,
                isCappedMaxSupply: false
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.cometCollateralBalance(
                network: .base,
                comet: cometAddress,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        // cometSupplyCollateralAndBorrow uses cometBorrow with collateral arrays
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_BORROW,
                            actionContext: .cometBorrow(
                                Charter.ActionContext.CometBorrowActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [Amount("0.5e18").underlying],
                                    collateralAssetSymbols: ["WETH"],
                                    collateralTokenPrices: [Number("3000.0e8")],
                                    collateralTokens: [BaseNetwork.Assets.WETH.assetAddress],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometSupplyMultipleAssetsAndBorrow.creationCode
                            ),
                            scriptFunction: CometSupplyMultipleAssetsAndBorrow.runFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .array(.address, [.address(BaseNetwork.Assets.WETH.assetAddress)]),
                                .array(.uint256, [.uint256(Amount("0.5e18").underlying)]),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500.0e6").underlying),
                                .array(.bool, [.bool(false)]),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Repay And Withdraw Collateral")
    func testCometRepayAndWithdrawCollateral() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometRepayAndWithdrawCollateral(
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                collateralAmount: Amount("0.5e18").underlying,
                isMaxRepay: false
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.cometBorrowPosition(
                network: .base,
                comet: cometAddress,
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        // cometRepayAndWithdrawCollateral uses cometRepay with collateral arrays
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_REPAY,
                            actionContext: .cometRepay(
                                Charter.ActionContext.CometRepayActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [Amount("0.5e18").underlying],
                                    collateralAssetSymbols: ["WETH"],
                                    collateralTokenPrices: [Number("3000.0e8")],
                                    collateralTokens: [BaseNetwork.Assets.WETH.assetAddress],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometRepayAndWithdrawMultipleAssets.creationCode
                            ),
                            scriptFunction: CometRepayAndWithdrawMultipleAssets.runFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .array(.address, [.address(BaseNetwork.Assets.WETH.assetAddress)]),
                                .array(.uint256, [.uint256(Amount("0.5e18").underlying)]),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500.0e6").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Withdraw Collateral")
    func testCometWithdrawCollateral() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometWithdrawCollateral(isMax: false),
            source: TradewindsLegendNode.cometCollateralBalance(
                network: .base,
                comet: cometAddress,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        // cometWithdrawCollateral uses cometRepay with zero repay amount
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_REPAY,
                            actionContext: .cometRepay(
                                Charter.ActionContext.CometRepayActionContext(
                                    amount: Number(0),
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [Amount("0.5e18").underlying],
                                    collateralAssetSymbols: ["WETH"],
                                    collateralTokenPrices: [Number("3000.0e8")],
                                    collateralTokens: [BaseNetwork.Assets.WETH.assetAddress],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometRepayAndWithdrawMultipleAssets.creationCode
                            ),
                            scriptFunction: CometRepayAndWithdrawMultipleAssets.runFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .array(.address, [.address(BaseNetwork.Assets.WETH.assetAddress)]),
                                .array(.uint256, [.uint256(Amount("0.5e18").underlying)]),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Number(0)),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Borrow USDC")
    func testMorphoBorrow() {
        // Using Base USDC/WETH market from Atlas
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoBorrow(
                asset: BaseNetwork.Assets.USDC.assetAddress,
                amount: Amount("500.0e6").underlying
            ),
            source: TradewindsLegendNode.morphoCollateralBalance(
                network: .base,
                marketId: marketId,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        // Note: morphoBorrowAsset uses standard morphoBorrow context
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_BORROW,
                            actionContext: .morphoBorrow(
                                Charter.ActionContext.MorphoBorrowActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmount: Number(0),
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number(0),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.supplyCollateralAndBorrowFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Number(0)),  // No collateral
                                .uint256(Amount("500.0e6").underlying),
                                .bool(false),  // isCappedMax
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Repay USDC")
    func testMorphoRepay() {
        // Using Base USDC/WETH market from Atlas
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6")
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoRepay(isMax: false),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.morphoBorrowPosition(
                network: .base,
                marketId: marketId,
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        // Note: morphoRepayAsset uses standard morphoRepay context
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_REPAY,
                            actionContext: .morphoRepay(
                                Charter.ActionContext.MorphoRepayActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmount: Number(0),
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number(0),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.repayAndWithdrawCollateralFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Amount("500.0e6").underlying),
                                .uint256(Number(0)),  // No withdrawal
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Withdraw Collateral")
    func testMorphoWithdrawCollateral() {
        // Using Base USDC/WETH market from Atlas
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoWithdrawCollateral(isMax: false),
            source: TradewindsLegendNode.morphoCollateralBalance(
                network: .base,
                marketId: marketId,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        // morphoWithdrawCollateralAsset uses MORPHO_REPAY with 0 repay amount
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_REPAY,
                            actionContext: .morphoRepay(
                                Charter.ActionContext.MorphoRepayActionContext(
                                    amount: Number(0),  // No repay, just withdrawing collateral
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmount: Amount("0.5e18").underlying,
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number("3000.0e8"),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.repayAndWithdrawCollateralFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Number(0)),  // No repay
                                .uint256(Amount("0.5e18").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Supply Collateral And Borrow")
    func testMorphoSupplyCollateralAndBorrow() {
        // Using Base USDC/WETH market from Atlas
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "WETH", wallet: alice): Amount("1.0e18")
            ],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoSupplyCollateralAndBorrow(
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                borrowAmount: Amount("500.0e6").underlying,
                isCappedMaxSupply: false
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.morphoCollateralBalance(
                network: .base,
                marketId: marketId,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("0.5e18").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_BORROW,
                            actionContext: .morphoBorrow(
                                Charter.ActionContext.MorphoBorrowActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmount: Amount("0.5e18").underlying,
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number("3000.0e8"),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.supplyCollateralAndBorrowFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Amount("0.5e18").underlying),  // collateral amount
                                .uint256(Amount("500.0e6").underlying),  // borrow amount
                                .bool(false),  // isCappedMax
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Repay And Withdraw Collateral")
    func testMorphoRepayAndWithdrawCollateral() {
        // Using Base USDC/WETH market from Atlas
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoRepayAndWithdrawCollateral(
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                collateralAmount: Amount("0.5e18").underlying,
                isMaxRepay: false
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.morphoBorrowPosition(
                network: .base,
                marketId: marketId,
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_REPAY,
                            actionContext: .morphoRepay(
                                Charter.ActionContext.MorphoRepayActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmount: Amount("0.5e18").underlying,
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number("3000.0e8"),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.repayAndWithdrawCollateralFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Amount("500.0e6").underlying),  // repay amount
                                .uint256(Amount("0.5e18").underlying),  // collateral withdrawal amount
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Loop Short")
    func testLoopShort() {
        // Using Base market
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .loopShort(
                marketId: marketId,
                exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                exposureAssetSymbol: "USDC",
                exposureAmount: Number("10000e6"),
                minSwapBackingAmount: Number("3e18"),
                providedBackingAmount: Number("5e18"),
                poolFee: 3000,
                isIncrease: true
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            sink: TradewindsLegendNode.loopVenue(
                network: .base,
                marketId: marketId,
                backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Number("5e18")
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_LOOP_SHORT,
                            actionContext: .loopShort(
                                Charter.ActionContext.LoopShortActionContext(
                                    backingAssetSymbol: "WETH",
                                    backingToken: BaseNetwork.Assets.WETH.assetAddress,
                                    backingTokenPrice: Number("3000e8"),
                                    minSwapBackingAmount: Number("3e18"),
                                    providedBackingAmount: Number("5e18"),
                                    chainId: 8453,
                                    isIncrease: true,
                                    exposureAmount: Number("10000e6"),
                                    exposureAssetSymbol: "USDC",
                                    exposureToken: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureTokenPrice: Number("1e8"),
                                    swapVenue: Charter.SWAP_VENUE_UNISWAP_V3,
                                    borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                                    borrowMarketId: marketId,
                                    feeAmount: Number("0.0012e18"),
                                    feeAssetSymbol: "WETH",
                                    feeToken: BaseNetwork.Assets.WETH.assetAddress,
                                    feeTokenPrice: Number("3000e8")
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(LoopShort.creationCode),
                            scriptFunction: LoopShort.loopFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .tuple9(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // exposureToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // backingToken
                                    .uint24(3000),
                                    .uint256(Number("10000e6")),
                                    .uint256(Number("3e18")),
                                    .uint256(Number("5e18")),
                                    .bool(false),
                                    .uint256(Number("0.0012e18")),  // feeAmount
                                    .address(Charter.LOOP_FEE_RECIPIENT)  // feeRecipient
                                ),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Unloop Long")
    func testUnloopLong() {
        // Using Base market
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .unloopLong(
                marketId: marketId,
                exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                exposureAssetSymbol: "WETH",
                exposureAmount: Number("2e18"),
                backingAmountToExit: Number("1000e6"),
                minSwapBackingAmount: Number("5000e6"),
                poolFee: 3000
            ),
            source: TradewindsLegendNode.loopVenue(
                network: .base,
                marketId: marketId,
                backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Number("1000e6")
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_UNLOOP_LONG,
                            actionContext: .unloopLong(
                                Charter.ActionContext.UnloopLongActionContext(
                                    backingAssetSymbol: "USDC",
                                    backingToken: BaseNetwork.Assets.USDC.assetAddress,
                                    backingTokenPrice: Number("1e8"),
                                    minSwapBackingAmount: Number("5000e6"),
                                    backingAmountToExit: Number("1000e6"),
                                    chainId: 8453,
                                    exposureAmount: Number("2e18"),
                                    exposureAssetSymbol: "WETH",
                                    exposureToken: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureTokenPrice: Number("3000e8"),
                                    swapVenue: Charter.SWAP_VENUE_UNISWAP_V3,
                                    borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                                    borrowMarketId: marketId,
                                    feeAmount: Number("2e6"),
                                    feeAssetSymbol: "USDC",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeTokenPrice: Number("1e8")
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(UnloopLong.creationCode),
                            scriptFunction: UnloopLong.unloopFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .tuple8(
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // exposureToken
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // backingToken
                                    .uint24(3000),
                                    .uint256(Number("2e18")),  // exposureAmount
                                    .uint256(Number("1000e6")),  // backingAmountToExit
                                    .uint256(Number("5000e6")),  // minSwapBackingAmount
                                    .uint256(Number("2e6")),  // feeAmount
                                    .address(Charter.LOOP_FEE_RECIPIENT)  // feeRecipient
                                ),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Unloop Short")
    func testUnloopShort() {
        // Using Base market
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .unloopShort(
                marketId: marketId,
                exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                exposureAssetSymbol: "USDC",
                exposureAmount: Number("10000e6"),
                backingAmountToExit: Number("3e18"),  // Amount of WETH collateral to withdraw
                maxSwapBackingAmount: Number("5e18"),
                poolFee: 3000
            ),
            source: TradewindsLegendNode.loopVenue(
                network: .base,
                marketId: marketId,
                backingAsset: BaseNetwork.Assets.WETH.assetAddress,
                exposureAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Number("3e18")  // The backing amount exiting (WETH)
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_UNLOOP_SHORT,
                            actionContext: .unloopShort(
                                Charter.ActionContext.UnloopShortActionContext(
                                    backingAssetSymbol: "WETH",
                                    backingToken: BaseNetwork.Assets.WETH.assetAddress,
                                    backingTokenPrice: Number("3000e8"),
                                    maxSwapBackingAmount: Number("5e18"),
                                    chainId: 8453,
                                    exposureAmount: Number("10000e6"),
                                    exposureAssetSymbol: "USDC",
                                    exposureToken: BaseNetwork.Assets.USDC.assetAddress,
                                    exposureTokenPrice: Number("1e8"),
                                    swapVenue: Charter.SWAP_VENUE_UNISWAP_V3,
                                    borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                                    borrowMarketId: marketId,
                                    feeAmount: Number("4.0016e6"),
                                    feeAssetSymbol: "USDC",
                                    feeToken: BaseNetwork.Assets.USDC.assetAddress,
                                    feeTokenPrice: Number("1e8")
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(UnloopShort.creationCode),
                            scriptFunction: UnloopShort.unloopFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .tuple8(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // exposureToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // backingToken
                                    .uint24(3000),
                                    .uint256(Number("10000e6")),  // exposureAmount
                                    .uint256(Number("3e18")),  // backingAmountToExit
                                    .uint256(Number("5e18")),  // maxSwapBackingAmount
                                    .uint256(Number("4.0016e6")),  // feeAmount
                                    .address(Charter.LOOP_FEE_RECIPIENT)  // feeRecipient
                                ),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Add Backing Token for Long Position")
    func testAddBackingTokenLong() {
        // Using Base market
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .addBackingToken(
                marketId: marketId,
                exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                exposureAssetSymbol: "WETH",
                amount: Number("1000e6"),
                isShort: false  // Long position
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.loopVenue(
                network: .base,
                marketId: marketId,
                backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Number("1000e6")
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_ADD_BACKING_TOKEN,
                            actionContext: .addBackingToken(
                                Charter.ActionContext.AddBackingTokenActionContext(
                                    amount: Number("1000e6"),
                                    backingAssetSymbol: "USDC",
                                    backingToken: BaseNetwork.Assets.USDC.assetAddress,
                                    backingTokenPrice: Number("1e8"),
                                    chainId: 8453,
                                    exposureAssetSymbol: "WETH",
                                    exposureToken: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureTokenPrice: Number("3000e8"),
                                    borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                                    borrowMarketId: marketId,
                                    isShort: false
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(UnloopLong.creationCode),
                            scriptFunction: UnloopLong.addBackingTokenFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Number("1000e6")),
                                .bool(false),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Withdraw Backing Token")
    func testWithdrawBackingToken() {
        // Using Base market
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2  // USDC/WETH market
        let marketId = morphoMarket.marketId

        let folio = Folio(
            balances: [:],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .withdrawBackingToken(
                marketId: marketId,
                exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                exposureAssetSymbol: "WETH",
                amount: Number("500e6"),
                isShort: false  // Long position
            ),
            source: TradewindsLegendNode.loopVenue(
                network: .base,
                marketId: marketId,
                backingAsset: BaseNetwork.Assets.USDC.assetAddress,
                exposureAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Number("500e6")
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )
        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_WITHDRAW_BACKING_TOKEN,
                            actionContext: .withdrawBackingToken(
                                Charter.ActionContext.WithdrawBackingTokenActionContext(
                                    amount: Number("500e6"),
                                    backingAssetSymbol: "USDC",
                                    backingToken: BaseNetwork.Assets.USDC.assetAddress,
                                    backingTokenPrice: Number("1e8"),
                                    chainId: 8453,
                                    exposureAssetSymbol: "WETH",
                                    exposureToken: BaseNetwork.Assets.WETH.assetAddress,
                                    exposureTokenPrice: Number("3000e8"),
                                    borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                                    borrowMarketId: marketId,
                                    isShort: false
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(LoopLong.creationCode),
                            scriptFunction: LoopLong.withdrawBackingTokenFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),  // loanToken
                                    .address(BaseNetwork.Assets.WETH.assetAddress),  // collateralToken
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Number("500e6")),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Withdraw Collateral Max - resolves actual balance from folio")
    func testCometWithdrawCollateralMaxResolvesActualBalance() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress
        let collateralBalance = Amount("1.5e18")

        let folio = Folio(
            balances: [
                .borrowMarketCollateral(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "WETH"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): collateralBalance
            ],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8")
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometWithdrawCollateral(isMax: true),
            source: TradewindsLegendNode.cometCollateralBalance(
                network: .base,
                comet: cometAddress,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Number.MAX_UINT_256
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )

        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_REPAY,
                            actionContext: .cometRepay(
                                Charter.ActionContext.CometRepayActionContext(
                                    amount: Number(0),
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [collateralBalance.underlying],
                                    collateralAssetSymbols: ["WETH"],
                                    collateralTokenPrices: [Number("3000.0e8")],
                                    collateralTokens: [BaseNetwork.Assets.WETH.assetAddress],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometRepayAndWithdrawMultipleAssets.creationCode
                            ),
                            scriptFunction: CometRepayAndWithdrawMultipleAssets.runFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .array(.address, [.address(BaseNetwork.Assets.WETH.assetAddress)]),
                                .array(.uint256, [.uint256(collateralBalance.underlying)]),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Number(0)),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER, 
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Comet Repay And Withdraw Collateral Max - resolves actual balance from folio")
    func testCometRepayAndWithdrawCollateralMaxResolvesActualBalance() {
        let cometAddress = BaseNetwork.Comets.cUSDCv3.cometAddress
        let collateralBalance = Amount("2.0e18")

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6"),
                .borrowMarketCollateral(
                    borrowMarket: .comet(
                        network: .base,
                        comet: cometAddress,
                        underlyingSymbol: "WETH"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): collateralBalance
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .cometRepayAndWithdrawCollateral(
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                collateralAmount: Number.MAX_UINT_256,
                isMaxRepay: false
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.cometBorrowPosition(
                network: .base,
                comet: cometAddress,
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )

        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_COMET_REPAY,
                            actionContext: .cometRepay(
                                Charter.ActionContext.CometRepayActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmounts: [collateralBalance.underlying],
                                    collateralAssetSymbols: ["WETH"],
                                    collateralTokenPrices: [Number("3000.0e8")],
                                    collateralTokens: [BaseNetwork.Assets.WETH.assetAddress],
                                    comet: cometAddress,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(
                                CometRepayAndWithdrawMultipleAssets.creationCode
                            ),
                            scriptFunction: CometRepayAndWithdrawMultipleAssets.runFn,
                            scriptCallValues: [
                                .address(cometAddress),
                                .array(.address, [.address(BaseNetwork.Assets.WETH.assetAddress)]),
                                .array(.uint256, [.uint256(collateralBalance.underlying)]),
                                .address(BaseNetwork.Assets.USDC.assetAddress),
                                .uint256(Amount("500.0e6").underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER, 
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Withdraw Collateral Max - resolves actual balance from folio")
    func testMorphoWithdrawCollateralMaxResolvesActualBalance() {
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2
        let marketId = morphoMarket.marketId
        let collateralBalance = Amount("3.0e18")

        let folio = Folio(
            balances: [
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): collateralBalance
            ],
            prices: [
                .token(symbol: "WETH"): Value("3000e8"),
                .token(symbol: "USDC"): Value("1e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoWithdrawCollateral(isMax: true),
            source: TradewindsLegendNode.morphoCollateralBalance(
                network: .base,
                marketId: marketId,
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                wallet: alice
            ),
            sink: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.WETH.assetAddress,
                symbol: "WETH",
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Number.MAX_UINT_256
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )

        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_REPAY,
                            actionContext: .morphoRepay(
                                Charter.ActionContext.MorphoRepayActionContext(
                                    amount: .zero,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmount: collateralBalance.underlying,
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number("3000.0e8"),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.repayAndWithdrawCollateralFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),
                                    .address(BaseNetwork.Assets.WETH.assetAddress),
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(.zero),
                                .uint256(collateralBalance.underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER, 
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }

    @Test("Morpho Repay And Withdraw Collateral Max - resolves actual balance from folio")
    func testMorphoRepayAndWithdrawCollateralMaxResolvesActualBalance() {
        let morphoMarket = BaseNetwork.MorphoMarkets.market_2
        let marketId = morphoMarket.marketId
        let collateralBalance = Amount("4.0e18")

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: alice): Amount("1000.0e6"),
                .borrowMarketCollateral(
                    borrowMarket: .morpho(
                        network: .base,
                        collateralTokenSymbol: "WETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "WETH",
                    wallet: alice
                ): collateralBalance
            ],
            prices: [
                .token(symbol: "USDC"): Value("1e8"),
                .token(symbol: "WETH"): Value("3000e8"),
            ]
        )

        let route = Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
            type: .morphoRepayAndWithdrawCollateral(
                collateralAsset: BaseNetwork.Assets.WETH.assetAddress,
                collateralAmount: Number.MAX_UINT_256,
                isMaxRepay: false
            ),
            source: TradewindsLegendNode.tokenBalance(
                network: .base,
                address: BaseNetwork.Assets.USDC.assetAddress,
                symbol: "USDC",
                wallet: alice
            ),
            sink: TradewindsLegendNode.morphoBorrowPosition(
                network: .base,
                marketId: marketId,
                borrowAsset: BaseNetwork.Assets.USDC.assetAddress,
                wallet: alice
            ),
            rate: Percentage(fromDouble: 1.0),
            minFlow: Number(0),
            maxFlow: Number.MAX_UINT_256
        )

        let flow = Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>(
            route: route,
            amount: Amount("500.0e6").underlying
        )

        let actual = flow.getQuarkOperationDetails(
            folio: folio,
            blockTimestamp: Number(100_000),
            isCappedMax: false,
            logger: nil as Charter.Logger?
        )

        let expected:
            Result<
                [Charter.QuarkOperationBuilder.ImmedatiateOperationDetails], Charter.CharterError
            > =
                .success(
                    [
                        .init(
                            actionType: Charter.ACTION_TYPE_MORPHO_REPAY,
                            actionContext: .morphoRepay(
                                Charter.ActionContext.MorphoRepayActionContext(
                                    amount: Amount("500.0e6").underlying,
                                    assetSymbol: "USDC",
                                    chainId: 8453,
                                    collateralAmount: collateralBalance.underlying,
                                    collateralAssetSymbol: "WETH",
                                    collateralTokenPrice: Number("3000.0e8"),
                                    collateralToken: BaseNetwork.Assets.WETH.assetAddress,
                                    morpho: morphoMarket.morpho,
                                    morphoMarketId: marketId,
                                    price: Number("1.0e8"),
                                    token: BaseNetwork.Assets.USDC.assetAddress
                                )
                            ),
                            scriptAddress: Create2.getScriptAddress(MorphoActions.creationCode),
                            scriptFunction: MorphoActions.repayAndWithdrawCollateralFn,
                            scriptCallValues: [
                                .address(morphoMarket.morpho),
                                .tuple5(
                                    .address(BaseNetwork.Assets.USDC.assetAddress),
                                    .address(BaseNetwork.Assets.WETH.assetAddress),
                                    .address(morphoMarket.oracle),
                                    .address(morphoMarket.irm),
                                    .uint256(morphoMarket.lltv)
                                ),
                                .uint256(Amount("500.0e6").underlying),
                                .uint256(collateralBalance.underlying),
                            ],
                            expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER, 
                            network: .base
                        )
                    ])

        #expect(actual == expected)
    }
}
