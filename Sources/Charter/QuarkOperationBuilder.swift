import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber
import Tradewinds

extension Charter {
    public enum QuarkOperationBuilder {
        public struct ImmedatiateOperationDetails: Equatable {
            public let actionType: String
            public let actionContext: ActionContext
            public let scriptAddress: EthAddress
            public let scriptFunction: ABI.Function
            public let scriptCallValues: [ABI.Value]
            public let expiryBuffer: Number
            public let network: Network
        }

        private struct MorphoRewardEntry: Equatable {
            let distributor: EthAddress
            let reward: EthAddress
            let claimable: Number
            let proof: [Hex]
            let symbol: String
            let price: Number
        }

        private struct MorphoClaimsByProtocol {
            let morphoClaims: [MorphoRewardEntry]
            let merklClaims: [MorphoRewardEntry]
        }

        public static func handleImmediateOperation(
            operationDetails: ImmedatiateOperationDetails,
            network: Network,
            sender: EthAddress,
            nonceSecret: Hex,
            blockTimestamp: Number
        ) -> Result<Charter.QuarkOperationAction, Charter.CharterError> {
            let scriptCalldata: Hex
            do {
                scriptCalldata = try operationDetails.scriptFunction.encoded(
                    with: operationDetails.scriptCallValues
                )
            } catch {
                return .failure(.error(error.localizedDescription))
            }

            let operation = Charter.Chart.LegacyQuarkOperation(
                nonce: nonceSecret,
                isReplayable: false,
                scriptAddress: operationDetails.scriptAddress,
                scriptSources: [],
                scriptCalldata: scriptCalldata,
                expiry: blockTimestamp + operationDetails.expiryBuffer,
            )

            let action = Charter.Chart.EVMAction(
                chainId: network.chainId,
                quarkAccount: sender,
                actionType: operationDetails.actionType,
                actionContext: operationDetails.actionContext,
                nonceSecret: nonceSecret,
                totalPlays: 1,
                executionType: .immediate
            )

            return .success(.init(operation: operation, action: action))
        }

        public static func bridgeAcrossAsset(
            srcNetwork: Network,
            srcAsset: Atlas.Asset,
            destNetwork: Network,
            destAsset: Atlas.Asset,
            rate: Percentage,
            assetPrice: Value,
            inputAmount: Amount,
            outputAmount: Amount,
            sender: EthAddress,
            recipient: EthAddress,
            isMaxBridge: Bool,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            guard let atlasSrcNetwork = Atlas.getNetwork(network: srcNetwork) else {
                return .failure(.unknownAtlasNetwork(network: srcNetwork))
            }

            // We need to use the wrapped token address for native tokens
            let destAssetAddress: EthAddress
            if destAsset.isNativeAsset {
                if let wrappedTokenSymbol = destAsset.crossChainAsset?.wrappedAssetSymbol,
                    let wrappedOutputAsset = Atlas.getAssetBySymbol(
                        network: destNetwork,
                        symbol: wrappedTokenSymbol
                    )
                {
                    destAssetAddress = wrappedOutputAsset.assetAddress
                } else {
                    return .failure(.error("Unknown wrapped asset for native token"))
                }
            } else {
                destAssetAddress = destAsset.assetAddress
            }

            let scriptFunction: ABI.Function = AcrossActions.depositV3Fn
            let scriptAddress = Create2.getScriptAddress(AcrossActions.creationCode)
            guard let blockTimestampUInt = try? blockTimestamp.toUInt() else {
                return .failure(.error("Block timestamp is not a valid uint"))
            }
            let acrossQuoteTimestamp = blockTimestampUInt - Charter.ACROSS_QUOTE_TIMESTAMP_BUFFER
            let acrossFillDeadline = blockTimestampUInt + Charter.ACROSS_FILL_DEADLINE_BUFFER

            let scriptCallValues: [ABI.Value] = [
                .address(atlasSrcNetwork.acrossSpokePool),
                .tuple12(
                    .address(sender),
                    .address(recipient),
                    .address(srcAsset.assetAddress),
                    .address(destAssetAddress),
                    .uint256(inputAmount.underlying),
                    .uint256(outputAmount.underlying),
                    .uint256(destNetwork.chainId),
                    .address(EthAddress("0x0000000000000000000000000000000000000000")),
                    .uint32(acrossQuoteTimestamp),
                    .uint32(acrossFillDeadline),
                    .uint32(0),
                    .bytes(Hex(""))
                ),
                .bytes(Charter.ACROSS_UNIQUE_IDENTIFIER),
                .bool(srcAsset.isNativeAsset),
                .bool(isMaxBridge),
            ]

            // This is due to the comlexities of Across ambiguously sending either WETH or ETH
            // If ETH exists as an asset and we're sending "WETH", then we use `ETH` here.
            let destinationAssetSymbol =
                Atlas.getAssetBySymbol(network: destNetwork, symbol: "ETH") != nil
                    && srcAsset.symbol == "WETH" ? "ETH" : destAsset.symbol

            return .success([
                .init(
                    actionType: ActionContext.BridgeActionContext.actionType,
                    actionContext: .bridge(
                        Charter.ActionContext.BridgeActionContext(
                            assetSymbol: srcAsset.symbol,
                            bridgeType: .across,
                            chainId: srcNetwork.chainId,
                            destinationChainId: destNetwork.chainId,
                            destinationAssetSymbol: destinationAssetSymbol,
                            inputAmount: inputAmount.underlying,
                            outputAmount: outputAmount.underlying,
                            price: assetPrice.underlying,
                            recipient: recipient,
                            token: srcAsset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.BRIDGE_EXPIRY_BUFFER,
                    network: srcNetwork
                )
            ])
        }

        public static func transfer(
            network: Network,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            isCappedMax: Bool,
            sender: EthAddress,
            recipient: EthAddress
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            var operations: [ImmedatiateOperationDetails] = []
            let isNativeAsset = asset.isNativeAsset

            let scriptFunction: ABI.Function
            let scriptCallValues: [ABI.Value]
            let scriptAddress = Create2.getScriptAddress(TransferActions.creationCode)

            if isNativeAsset {
                // Optimistically unwrap WETH before native ETH transfers
                if let wrappedSymbol = asset.crossChainAsset?.wrappedAssetSymbol,
                    let wrappedAsset = Atlas.getAssetBySymbol(network: network, symbol: wrappedSymbol)
                {
                    switch unwrapSimple(
                        network: network,
                        sourceAsset: wrappedAsset,
                        destAsset: asset,
                        price: price,
                        amount: amount,
                        sender: sender
                    ) {
                        case .success(let unwrapOps):
                            operations.append(contentsOf: unwrapOps)
                        case .failure(let err):
                            return .failure(err)
                    }
                }
                scriptFunction = TransferActions.transferNativeTokenFn
                scriptCallValues = [
                    .address(recipient),
                    .uint256(amount.underlying),
                    .bool(isCappedMax)
                ]
            } else {
                scriptFunction = TransferActions.transferERC20TokenFn
                scriptCallValues = [
                    .address(asset.assetAddress),
                    .address(recipient),
                    .uint256(amount.underlying),
                    .bool(isCappedMax)
                ]
            }

            let actionType = ActionContext.TransferActionContext.actionType
            let actionContext: ActionContext = .transfer(
                ActionContext.TransferActionContext(
                    amount: amount.underlying,
                    assetSymbol: asset.symbol,
                    chainId: network.chainId,
                    price: price,
                    recipient: recipient,
                    token: asset.assetAddress
                )
            )

            operations.append(
                .init(
                    actionType: actionType,
                    actionContext: actionContext,
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.TRANSFER_EXPIRY_BUFFER,
                    network: network
                )
            )

            return .success(operations)
        }

        public static func swap(
            network: Network,
            sellAsset: Atlas.Asset,
            sellAmount: Amount,
            buyAsset: Atlas.Asset,
            buyAmount: Amount,
            sellPrice: Number,
            buyPrice: Number,
            feeToken: EthAddress,
            feeAmount: Amount,
            isExactOut: Bool,
            isBuy: Bool,
            isCappedMax: Bool = false,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            // Get filler address from Atlas
            guard let atlasNetwork = Atlas.getNetwork(network: network) else {
                return .failure(.error("Network not found in Atlas: \(network)"))
            }
            let fillerAddress = atlasNetwork.filler

            // Calculate Legend fee (0.15% of buy amount)
            let legendFeeAmount =
                (buyAmount.underlying * Charter.SWAP_FEE_PERCENT) / Charter.FEE_PERCENT_SCALE
            let legendFeeToken = buyAsset.assetAddress
            let legendFeeRecipient = Charter.SWAP_FEE_RECIPIENT

            // Use ApproveAndSwap contract with correct function
            let scriptAddress = Create2.getScriptAddress(ApproveAndSwap.creationCode)
            let scriptFunction = ApproveAndSwap.swapExactInFn

            // ApproveAndSwap.swapExactIn parameters:
            // filler, sellToken, sellAmount, buyToken, minBuyAmount, feeToken, feeAmount, feeRecipient, cappedMax
            let scriptCallValues: [ABI.Value] = [
                .address(fillerAddress),
                .address(sellAsset.assetAddress),
                .uint256(sellAmount.underlying),
                .address(buyAsset.assetAddress),
                .uint256(buyAmount.underlying),  // minBuyAmount
                .address(legendFeeToken),
                .uint256(legendFeeAmount),
                .address(legendFeeRecipient),
                .bool(isCappedMax),
            ]

            // Note: The Legend fee is explicitly passed to the filler
            // The 0x fee is handled implicitly when executing swap calldata

            let actionType = Charter.ACTION_TYPE_SWAP
            // Match original QuarkBuilder with dual fee arrays
            let feeAsset =
                Atlas.getAssetByAddress(network: network, token: feeToken) ?? buyAsset
            let feePrice = (feeToken == buyAsset.assetAddress) ? buyPrice : sellPrice

            var feeAmounts = [legendFeeAmount]
            var feeAssetSymbols = [buyAsset.symbol]
            var feeTokens = [legendFeeToken]
            var feeTokenPrices = [buyPrice]
            var feeDescriptions = [Charter.FEE_DESCRIPTION_LEGEND]

            if !feeAmount.isZero {
                feeAmounts.append(feeAmount.underlying)
                feeAssetSymbols.append(feeAsset.symbol)
                feeTokens.append(feeToken)
                feeTokenPrices.append(feePrice)
                feeDescriptions.append(Charter.FEE_DESCRIPTION_ZERO_EX)
            }

            let actionContext: ActionContext = .swap(
                ActionContext.SwapActionContext(
                    chainId: network.chainId,
                    feeAmounts: feeAmounts,
                    feeAssetSymbols: feeAssetSymbols,
                    feeTokens: feeTokens,
                    feeTokenPrices: feeTokenPrices,
                    feeDescriptions: feeDescriptions,
                    inputAmount: sellAmount.underlying,
                    inputAssetSymbol: sellAsset.symbol,
                    inputToken: sellAsset.assetAddress,
                    inputTokenPrice: sellPrice,
                    outputAmount: buyAmount.underlying,
                    outputAssetSymbol: buyAsset.symbol,
                    outputToken: buyAsset.assetAddress,
                    outputTokenPrice: buyPrice,
                    isExactOut: isExactOut,
                    isBuy: isBuy,
                    isCappedMax: isCappedMax,
                    useFiller: true
                )
            )

            return .success([
                .init(
                    actionType: actionType,
                    actionContext: actionContext,
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.SWAP_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        // MARK: - Wrap/Unwrap Functions

        public static func wrapSimple(
            network: Network,
            sourceAsset: Atlas.Asset,
            destAsset: Atlas.Asset,
            price: Number,
            amount: Amount,
            sender: EthAddress
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(WrapperActions.creationCode)
            let scriptFunction: ABI.Function
            let scriptCallValues: [ABI.Value]

            if sourceAsset.symbol == "ETH" && destAsset.symbol == "WETH" {
                scriptFunction = WrapperActions.wrapAllETHFn
                scriptCallValues = [
                    .address(destAsset.assetAddress)
                ]
            } else if sourceAsset.symbol == "POL" && destAsset.symbol == "WPOL" {
                scriptFunction = WrapperActions.wrapAllETHFn
                scriptCallValues = [
                    .address(destAsset.assetAddress)
                ]
            } else if sourceAsset.symbol == "HYPE" && destAsset.symbol == "WHYPE" {
                scriptFunction = WrapperActions.wrapAllETHFn
                scriptCallValues = [
                    .address(destAsset.assetAddress)
                ]
            } else if sourceAsset.symbol == "stETH" && destAsset.symbol == "wstETH" {
                scriptFunction = WrapperActions.wrapAllLidoStETHFn
                scriptCallValues = [
                    .address(destAsset.assetAddress),
                    .address(sourceAsset.assetAddress),
                ]
            } else {
                return .failure(
                    .notWrappable(
                        symbol: sourceAsset.symbol,
                        network: network,
                        address: sourceAsset.assetAddress,
                        noScript: true
                    )
                )
            }

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_WRAP,
                    actionContext: .wrap(
                        ActionContext.WrapActionContext(
                            chainId: network.chainId,
                            // Note: we wrap all here, so amount is unused
                            amount: amount.underlying,
                            token: sourceAsset.assetAddress,
                            fromAssetSymbol: sourceAsset.symbol,
                            toAssetSymbol: destAsset.symbol
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func wrapAssetUpTo(
            network: Network,
            underlyingAsset: Atlas.Asset,
            targetAmount: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(WrapperActions.creationCode)
            let scriptFunction: ABI.Function
            let scriptCallValues: [ABI.Value]

            guard let crossChainUnderlyingAsset = underlyingAsset.crossChainAsset,
                let wrappedAssetSymbol = crossChainUnderlyingAsset.wrappedAssetSymbol,
                let wrappedAsset = Atlas.getAssetBySymbol(
                    network: network,
                    symbol: wrappedAssetSymbol
                )
            else {
                return .failure(
                    .notWrappable(
                        symbol: underlyingAsset.symbol,
                        network: network,
                        address: underlyingAsset.assetAddress,
                        noScript: false
                    )
                )
            }

            if underlyingAsset.symbol == "ETH" || underlyingAsset.symbol == "HYPE" || underlyingAsset.symbol == "POL" {
                scriptFunction = WrapperActions.wrapETHUpToFn
                scriptCallValues = [
                    .address(wrappedAsset.assetAddress),
                    .uint256(targetAmount),
                ]
            } else {
                return .failure(
                    .notWrappable(
                        symbol: underlyingAsset.symbol,
                        network: network,
                        address: underlyingAsset.assetAddress,
                        noScript: true
                    )
                )
            }

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_WRAP,
                    actionContext: .wrap(
                        ActionContext.WrapActionContext(
                            chainId: network.chainId,
                            amount: targetAmount,
                            token: underlyingAsset.assetAddress,
                            fromAssetSymbol: underlyingAsset.symbol,
                            toAssetSymbol: wrappedAssetSymbol
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func unwrapSimple(
            network: Network,
            sourceAsset: Atlas.Asset,
            destAsset: Atlas.Asset,
            price: Number,
            amount: Amount,
            sender: EthAddress
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(WrapperActions.creationCode)
            let scriptFunction: ABI.Function
            let scriptCallValues: [ABI.Value]

            if sourceAsset.symbol == "WETH" && destAsset.symbol == "ETH" {
                scriptFunction = WrapperActions.unwrapWETHUpToFn
                scriptCallValues = [
                    .address(sourceAsset.assetAddress),
                    .uint256(amount.underlying),
                ]
            } else if sourceAsset.symbol == "WHYPE" && destAsset.symbol == "HYPE" {
                scriptFunction = WrapperActions.unwrapWETHUpToFn
                scriptCallValues = [
                    .address(sourceAsset.assetAddress),
                    .uint256(amount.underlying),
                ]
            } else if sourceAsset.symbol == "WPOL" && destAsset.symbol == "POL" {
                scriptFunction = WrapperActions.unwrapWETHUpToFn
                scriptCallValues = [
                    .address(sourceAsset.assetAddress),
                    .uint256(amount.underlying),
                ]
            } else if sourceAsset.symbol == "wstETH" && destAsset.symbol == "stETH" {
                scriptFunction = WrapperActions.unwrapLidoWstETHFn
                scriptCallValues = [
                    .address(sourceAsset.assetAddress),
                    .uint256(amount.underlying),
                ]
            } else {
                return .failure(
                    .notUnwrappable(
                        symbol: sourceAsset.symbol,
                        network: network,
                        address: sourceAsset.assetAddress,
                        noScript: true
                    )
                )
            }

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_UNWRAP,
                    actionContext: .unwrap(
                        ActionContext.UnwrapActionContext(
                            chainId: network.chainId,
                            amount: amount.underlying,
                            token: sourceAsset.assetAddress,
                            fromAssetSymbol: sourceAsset.symbol,
                            toAssetSymbol: destAsset.symbol
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        // MARK: - Comet Functions

        public static func cometSupply(
            network: Network,
            comet: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            isCappedMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(CometSupplyActions.creationCode)
            let scriptFunction = CometSupplyActions.supplyFn
            let scriptCallValues: [ABI.Value] = [
                .address(comet),
                .address(asset.assetAddress),
                .uint256(amount.underlying),
                .bool(isCappedMax),
            ]
            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_COMET_SUPPLY,
                    actionContext: .cometSupply(
                        ActionContext.CometSupplyActionContext(
                            amount: amount.underlying,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            comet: comet,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func cometWithdraw(
            network: Network,
            comet: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            isMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let withdrawAmount = isMax ? Number.MAX_UINT_256 : amount.underlying
            let scriptAddress = Create2.getScriptAddress(CometWithdrawActions.creationCode)
            let scriptFunction = CometWithdrawActions.withdrawFn
            let scriptCallValues: [ABI.Value] = [
                .address(comet),
                .address(asset.assetAddress),
                .uint256(withdrawAmount),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_COMET_WITHDRAW,
                    actionContext: .cometWithdraw(
                        ActionContext.CometWithdrawActionContext(
                            amount: withdrawAmount,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            comet: comet,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func cometBorrow(
            network: Network,
            comet: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            collateralAssets: [Atlas.Asset],
            collateralAmounts: [Amount],
            collateralPrices: [Number],
            isCappedMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            // Validate arrays have same length
            guard collateralAssets.count == collateralAmounts.count,
                collateralAssets.count == collateralPrices.count
            else {
                return .failure(.error("Collateral arrays must have same length"))
            }

            let scriptAddress: EthAddress
            let scriptFunction: ABI.Function
            let scriptCallValues: [ABI.Value]

            if collateralAssets.isEmpty {
                // Simple borrow without collateral
                scriptAddress = Create2.getScriptAddress(CometWithdrawActions.creationCode)
                scriptFunction = CometWithdrawActions.withdrawFn
                scriptCallValues = [
                    .address(comet),
                    .address(asset.assetAddress),
                    .uint256(amount.underlying),
                ]
            } else {
                // Borrow with collateral supply
                scriptAddress = Create2.getScriptAddress(
                    CometSupplyMultipleAssetsAndBorrow.creationCode
                )
                scriptFunction = CometSupplyMultipleAssetsAndBorrow.runFn

                // Create separate arrays for collateral tokens and amounts to match original QuarkBuilder
                let collateralTokens = collateralAssets.map { $0.assetAddress }
                let collateralAmountsForScript = collateralAmounts.map { $0.underlying }
                // TODO: We currently only supply one collateral at a time, but this will break when we support multiple collateral assets
                let cappedMaxes = Array(repeating: isCappedMax, count: collateralAssets.count)

                scriptCallValues = [
                    .address(comet),
                    .array(.address, collateralTokens.map { .address($0) }),
                    .array(.uint256, collateralAmountsForScript.map { .uint256($0) }),
                    .address(asset.assetAddress),
                    .uint256(amount.underlying),
                    .array(.bool, cappedMaxes.map { ABI.Value.bool($0) }),
                ]
            }

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_COMET_BORROW,
                    actionContext: .cometBorrow(
                        ActionContext.CometBorrowActionContext(
                            amount: amount.underlying,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            collateralAmounts: collateralAmounts.map { $0.underlying },
                            collateralAssetSymbols: collateralAssets.map { $0.symbol },
                            collateralTokenPrices: collateralPrices,
                            collateralTokens: collateralAssets.map { $0.assetAddress },
                            comet: comet,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func cometRepay(
            network: Network,
            comet: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            collateralAsset: Atlas.Asset?,
            collateralAmount: Amount?,
            collateralPrice: Number?,
            isMaxRepay: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            // Always use CometRepayAndWithdrawMultipleAssets for consistency with original QuarkBuilder
            let scriptAddress = Create2.getScriptAddress(
                CometRepayAndWithdrawMultipleAssets.creationCode
            )
            let scriptFunction = CometRepayAndWithdrawMultipleAssets.runFn

            let collateralTokens: [EthAddress]
            let collateralAmountsUnderlying: [Number]
            let collateralAmounts: [Amount]
            let collateralPrices: [Number]
            let collateralAssets: [Atlas.Asset]

            if let collateralAsset = collateralAsset,
               let collateralAmount = collateralAmount,
               let collateralPrice = collateralPrice,
               collateralAmount.underlying > .zero {
                collateralTokens = [collateralAsset.assetAddress]
                collateralAmountsUnderlying = [collateralAmount.underlying]
                collateralAmounts = [collateralAmount]
                collateralPrices = [collateralPrice]
                collateralAssets = [collateralAsset]
            } else {
                collateralTokens = []
                collateralAmountsUnderlying = []
                collateralAmounts = []
                collateralPrices = []
                collateralAssets = []
            }

            // Use uint256.max when isMaxRepay is true, otherwise use the calculated amount
            // For calldata only - ActionContext should always show the actual debt amount
            let calldataRepayAmount = isMaxRepay ? Number.MAX_UINT_256 : amount.underlying

            // Note: Original QuarkBuilder uses parameter order:
            // run(comet, collateralTokens[], collateralAmounts[], repayAsset, repayAmount)
            let scriptCallValues: [ABI.Value] = [
                .address(comet),
                .array(.address, collateralTokens.map { .address($0) }),
                .array(.uint256, collateralAmountsUnderlying.map { .uint256($0) }),
                .address(asset.assetAddress),
                .uint256(calldataRepayAmount)
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_COMET_REPAY,
                    actionContext: .cometRepay(
                        ActionContext.CometRepayActionContext(
                            amount: amount.underlying,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            collateralAmounts: collateralAmounts.map { $0.underlying },
                            collateralAssetSymbols: collateralAssets.map { $0.symbol },
                            collateralTokenPrices: collateralPrices,
                            collateralTokens: collateralAssets.map { $0.assetAddress },
                            comet: comet,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        // MARK: - Morpho Functions

        public static func morphoSupplyCollateralAndBorrow(
            network: Network,
            marketId: Hex,
            collateralAsset: Atlas.Asset,
            collateralAmount: Amount,
            collateralPrice: Number,
            borrowAsset: Atlas.Asset,
            borrowAmount: Amount,
            borrowPrice: Number,
            isCappedMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(MorphoActions.creationCode)
            let scriptFunction = MorphoActions.supplyCollateralAndBorrowFn

            // Get Morpho market details from Atlas
            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }
            let morphoAddress = morphoMarket.morpho

            // Create MarketParams tuple to match original QuarkBuilder
            let marketParams = MorphoActions.MarketParams(
                loanToken: borrowAsset.assetAddress,
                collateralToken: collateralAsset.assetAddress,
                oracle: morphoMarket.oracle,
                irm: morphoMarket.irm,
                lltv: morphoMarket.lltv
            )

            let scriptCallValues: [ABI.Value] = [
                .address(morphoAddress),
                marketParams.asValue,
                .uint256(collateralAmount.underlying),
                .uint256(borrowAmount.underlying),
                .bool(isCappedMax)
            ]

            return .success([
                .init(
                    // TODO: Consider changing action type and action context to be MORPHO_SUPPLY_COLLATERAL specific
                    actionType: Charter.ACTION_TYPE_MORPHO_BORROW,
                    actionContext: .morphoBorrow(
                        ActionContext.MorphoBorrowActionContext(
                            amount: borrowAmount.underlying,
                            assetSymbol: borrowAsset.symbol,
                            chainId: network.chainId,
                            collateralAmount: collateralAmount.underlying,
                            collateralAssetSymbol: collateralAsset.symbol,
                            collateralTokenPrice: collateralPrice,
                            collateralToken: collateralAsset.assetAddress,
                            morpho: morphoAddress,
                            morphoMarketId: marketId,
                            price: borrowPrice,
                            token: borrowAsset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func morphoRepayAndWithdrawCollateral(
            network: Network,
            marketId: Hex,
            repayAsset: Atlas.Asset,
            repayAmount: Amount,
            repayPrice: Number,
            collateralAsset: Atlas.Asset,
            collateralAmount: Amount,
            collateralPrice: Number,
            isMaxRepay: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(MorphoActions.creationCode)
            let scriptFunction = MorphoActions.repayAndWithdrawCollateralFn

            // Get Morpho market details from Atlas
            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }
            let morphoAddress = morphoMarket.morpho

            // Create MarketParams tuple to match original QuarkBuilder
            let marketParams = MorphoActions.MarketParams(
                loanToken: repayAsset.assetAddress,
                collateralToken: collateralAsset.assetAddress,
                oracle: morphoMarket.oracle,
                irm: morphoMarket.irm,
                lltv: morphoMarket.lltv
            )

            // Use uint256.max when isMaxRepay is true, otherwise use the calculated amount
            // For calldata only - ActionContext should always show the actual debt amount
            let calldataRepayAmount = isMaxRepay ? Number.MAX_UINT_256 : repayAmount.underlying
            let calldataCollateralAmount = collateralAmount.underlying

            let scriptCallValues: [ABI.Value] = [
                .address(morphoAddress),
                marketParams.asValue,
                .uint256(calldataRepayAmount),
                .uint256(calldataCollateralAmount),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_MORPHO_REPAY,
                    actionContext: .morphoRepay(
                        ActionContext.MorphoRepayActionContext(
                            amount: repayAmount.underlying,
                            assetSymbol: repayAsset.symbol,
                            chainId: network.chainId,
                            collateralAmount: collateralAmount.underlying,
                            collateralAssetSymbol: collateralAsset.symbol,
                            collateralTokenPrice: collateralPrice,
                            collateralToken: collateralAsset.assetAddress,
                            morpho: morphoAddress,
                            morphoMarketId: marketId,
                            price: repayPrice,
                            token: repayAsset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func morphoVaultSupply(
            network: Network,
            vault: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            isCappedMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(MorphoVaultActions.creationCode)
            let scriptFunction = MorphoVaultActions.depositFn
            let scriptCallValues: [ABI.Value] = [
                .address(vault),
                .address(asset.assetAddress),
                .uint256(amount.underlying),
                .bool(isCappedMax),
            ]
            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_MORPHO_VAULT_SUPPLY,
                    actionContext: .morphoVaultSupply(
                        ActionContext.MorphoVaultSupplyActionContext(
                            amount: amount.underlying,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            morphoVault: vault,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func morphoVaultWithdraw(
            network: Network,
            vault: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            isMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let withdrawAmount = isMax ? Number.MAX_UINT_256 : amount.underlying
            let scriptAddress = Create2.getScriptAddress(MorphoVaultActions.creationCode)
            let scriptFunction = MorphoVaultActions.withdrawFn
            let scriptCallValues: [ABI.Value] = [
                .address(vault),
                .uint256(withdrawAmount),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_MORPHO_VAULT_WITHDRAW,
                    actionContext: .morphoVaultWithdraw(
                        ActionContext.MorphoVaultWithdrawActionContext(
                            amount: withdrawAmount,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            morphoVault: vault,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        // MARK: - Aave Functions

        public static func aaveSupply(
            network: Network,
            pool: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            isCappedMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let scriptAddress = Create2.getScriptAddress(AaveActions.creationCode)
            let scriptFunction = AaveActions.supplyFn
            let scriptCallValues: [ABI.Value] = [
                .address(pool),
                .address(asset.assetAddress),
                .uint256(amount.underlying),
                .bool(isCappedMax),
            ]
            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_AAVE_SUPPLY,
                    actionContext: .aaveSupply(
                        ActionContext.AaveSupplyActionContext(
                            amount: amount.underlying,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            aavePool: pool,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func aaveWithdraw(
            network: Network,
            pool: EthAddress,
            asset: Atlas.Asset,
            price: Number,
            amount: Amount,
            isMax: Bool,
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            let withdrawAmount = isMax ? Number.MAX_UINT_256 : amount.underlying
            let scriptAddress = Create2.getScriptAddress(AaveActions.creationCode)
            let scriptFunction = AaveActions.withdrawFn
            let scriptCallValues: [ABI.Value] = [
                .address(pool),
                .address(asset.assetAddress),
                .uint256(withdrawAmount),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_AAVE_WITHDRAW,
                    actionContext: .aaveWithdraw(
                        ActionContext.AaveWithdrawActionContext(
                            amount: withdrawAmount,
                            assetSymbol: asset.symbol,
                            chainId: network.chainId,
                            aavePool: pool,
                            price: price,
                            token: asset.assetAddress
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        // MARK: - Rewards Functions

        public static func cometClaimRewards(
            network: Network,
            cometRewards: [EthAddress],
            comets: [EthAddress],
            amounts: [Number],
            symbols: [String],
            prices: [Number],
            tokens: [EthAddress],
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            // Validate arrays have same length
            guard cometRewards.count == comets.count else {
                return .failure(.error("Comet rewards and comets arrays must have same length"))
            }

            let scriptAddress = Create2.getScriptAddress(CometClaimRewards.creationCode)
            let scriptFunction = CometClaimRewards.claimFn

            let scriptCallValues: [ABI.Value] = [
                .array(.address, cometRewards.map { .address($0) }),
                .array(.address, comets.map { .address($0) }),
                .array(.address, [.address(sender)]),  // Single account claiming
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_COMET_CLAIM_REWARDS,
                    actionContext: .cometClaimRewards(
                        ActionContext.CometClaimRewardsActionContext(
                            amounts: amounts,
                            assetSymbols: symbols,
                            chainId: network.chainId,
                            prices: prices,
                            tokens: tokens
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        /// Claims rewards from Morpho and/or Merkl distributors
        /// Separates rewards by distributor and uses appropriate contract for each:
        /// - Morpho distributor: Uses MorphoRewardsActions.claimAll
        /// - Merkl distributor: Uses MerklRewardsActions.claim
        /// Returns an array of operations, one for each distributor type with rewards.
        public static func morphoClaimRewards(
            network: Network,
            distributors: [EthAddress],
            rewards: [EthAddress],
            claimables: [Number],
            claimableNows: [Number],
            proofs: [[Hex]],
            symbols: [String],
            prices: [Number],
            sender: EthAddress,
            blockTimestamp: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            // Validate arrays have same length
            guard distributors.count == rewards.count,
                distributors.count == claimables.count,
                distributors.count == claimableNows.count,
                distributors.count == proofs.count,
                distributors.count == symbols.count,
                distributors.count == prices.count
            else {
                return .failure(.error("Morpho rewards arrays must have same length"))
            }

            // Create claims from parallel arrays
            let indexedClaims: [(entry: MorphoRewardEntry, index: Int)] = distributors.indices.map {
                i in
                (
                    MorphoRewardEntry(
                        distributor: distributors[i],
                        reward: rewards[i],
                        claimable: claimables[i],
                        proof: proofs[i],
                        symbol: symbols[i],
                        price: prices[i]
                    ),
                    i
                )
            }

            // Get distributor addresses from Atlas for the network
            let atlasNetwork = Atlas.getNetwork(network: network)
            let merklDistributor = atlasNetwork?.merklDistributor
            let morphoDistributors =
                atlasNetwork?.morphoRewardDistributors.map { $0.distributor } ?? []

            // Group claims using functional approach
            let groupedClaims = (
                morpho: indexedClaims.filter { morphoDistributors.contains($0.entry.distributor) },
                merkl: indexedClaims.filter { $0.entry.distributor == merklDistributor }
            )

            var operations: [ImmedatiateOperationDetails] = []

            // Handle Morpho rewards if any
            if !groupedClaims.morpho.isEmpty {
                operations.append(
                    buildMorphoClaimOperation(
                        network: network,
                        claims: groupedClaims.morpho.map { $0.entry },
                        claimableNows: groupedClaims.morpho.map { claimableNows[$0.index] },
                        sender: sender
                    )
                )
            }

            // Handle Merkl rewards if any
            if !groupedClaims.merkl.isEmpty {
                // Ensure merklDistributor exists (should always be true if we have merkl claims)
                guard let merklDistributor = merklDistributor else {
                    return .failure(.error("Merkl distributor not found for network"))
                }
                operations.append(
                    buildMerklClaimOperation(
                        network: network,
                        claims: groupedClaims.merkl.map { $0.entry },
                        claimableNows: groupedClaims.merkl.map { claimableNows[$0.index] },
                        merklDistributor: merklDistributor,
                        sender: sender
                    )
                )
            }

            return .success(operations)
        }

        private static func buildMorphoClaimOperation(
            network: Network,
            claims: [MorphoRewardEntry],
            claimableNows: [Number],
            sender: EthAddress
        ) -> ImmedatiateOperationDetails {
            let scriptAddress = Create2.getScriptAddress(MorphoRewardsActions.creationCode)
            let scriptFunction = MorphoRewardsActions.claimAllFn

            let scriptCallValues: [ABI.Value] = [
                .array(.address, claims.map { .address($0.distributor) }),
                .array(.address, Array(repeating: .address(sender), count: claims.count)),
                .array(.address, claims.map { .address($0.reward) }),
                .array(.uint256, claims.map { .uint256($0.claimable) }),
                .array(
                    .array(.bytes32),
                    claims.map { claim in
                        .array(.bytes32, claim.proof.map { .bytes32($0) })
                    }
                ),
            ]

            return ImmedatiateOperationDetails(
                actionType: Charter.ACTION_TYPE_MORPHO_CLAIM_REWARDS,
                actionContext: .morphoClaimRewards(
                    ActionContext.MorphoClaimRewardsActionContext(
                        amounts: claimableNows,
                        assetSymbols: claims.map { $0.symbol },
                        chainId: network.chainId,
                        prices: claims.map { $0.price },
                        tokens: claims.map { $0.reward }
                    )
                ),
                scriptAddress: scriptAddress,
                scriptFunction: scriptFunction,
                scriptCallValues: scriptCallValues,
                expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                network: network
            )
        }

        private static func buildMerklClaimOperation(
            network: Network,
            claims: [MorphoRewardEntry],
            claimableNows: [Number],
            merklDistributor: EthAddress,
            sender: EthAddress
        ) -> ImmedatiateOperationDetails {
            let scriptAddress = Create2.getScriptAddress(MerklRewardsActions.creationCode)
            let scriptFunction = MerklRewardsActions.claimFn

            // MerklRewardsActions.claim expects:
            // distributor (single address), accounts[], rewards[], claimables[], proofs[][]
            let scriptCallValues: [ABI.Value] = [
                .address(merklDistributor),
                .array(.address, Array(repeating: .address(sender), count: claims.count)),
                .array(.address, claims.map { .address($0.reward) }),
                .array(.uint256, claims.map { .uint256($0.claimable) }),
                .array(
                    .array(.bytes32),
                    claims.map { claim in
                        .array(.bytes32, claim.proof.map { .bytes32($0) })
                    }
                ),
            ]

            return ImmedatiateOperationDetails(
                actionType: Charter.ACTION_TYPE_MORPHO_CLAIM_REWARDS,
                actionContext: .morphoClaimRewards(
                    ActionContext.MorphoClaimRewardsActionContext(
                        amounts: claimableNows,
                        assetSymbols: claims.map { $0.symbol },
                        chainId: network.chainId,
                        prices: claims.map { $0.price },
                        tokens: claims.map { $0.reward }
                    )
                ),
                scriptAddress: scriptAddress,
                scriptFunction: scriptFunction,
                scriptCallValues: scriptCallValues,
                expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                network: network
            )
        }

        public static func loopLong(
            network: Network,
            marketId: Hex,
            backingAsset: Atlas.Asset,
            backingAssetPrice: Number,
            exposureAsset: Atlas.Asset,
            exposureAmount: Number,
            exposureAssetPrice: Number,
            maxSwapBackingAmount: Number,
            maxProvidedBackingAmount: Number,
            isCappedMax: Bool,
            poolFee: UInt,
            isIncrease: Bool
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            if exposureAmount.isMaxUint256 {
                return .failure(.error("Loop long does not support max exposure amount"))
            }

            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }

            guard backingAsset.assetAddress == morphoMarket.loanToken else {
                return .failure(
                    .error("Backing asset does not match morpho market loan token")
                )
            }

            guard exposureAsset.assetAddress == morphoMarket.collateralToken else {
                return .failure(
                    .error("Exposure asset does not match morpho market collateral token")
                )
            }

            let scriptAddress = Create2.getScriptAddress(LoopLong.creationCode)
            let scriptFunction = LoopLong.loopFn

            // Fee calculation for LoopLong: fee = (exposureAmount * p) / (1 - p)
            // This formula ensures the fee is p% of the total (including the fee itself),
            // not just p% of the exposure amount. Example: with p=0.04%, if we want the fee to be
            // 0.04% of the final total, we calculate: fee = exposureAmount * 0.0004 / 0.9996
            let feeAmount =
                (exposureAmount * Charter.LOOP_FEE_PERCENT)
                / (Charter.FEE_PERCENT_SCALE - Charter.LOOP_FEE_PERCENT)
            let feeRecipient = Charter.LOOP_FEE_RECIPIENT
            let feeToken = exposureAsset.assetAddress
            let feeAssetSymbol = exposureAsset.symbol
            let feeTokenPrice = exposureAssetPrice

            let scriptCallValues: [ABI.Value] = [
                .address(morphoMarket.morpho),
                .tuple5(
                    .address(morphoMarket.loanToken),
                    .address(morphoMarket.collateralToken),
                    .address(morphoMarket.oracle),
                    .address(morphoMarket.irm),
                    .uint256(morphoMarket.lltv)
                ),
                .tuple9(
                    .address(exposureAsset.assetAddress),
                    .address(backingAsset.assetAddress),
                    .uint24(poolFee),
                    .uint256(exposureAmount),
                    .uint256(maxSwapBackingAmount),
                    .uint256(maxProvidedBackingAmount),
                    .bool(isCappedMax),
                    .uint256(feeAmount),
                    .address(feeRecipient)
                ),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_LOOP_LONG,
                    actionContext: .loopLong(
                        ActionContext.LoopLongActionContext(
                            backingAssetSymbol: backingAsset.symbol,
                            backingToken: backingAsset.assetAddress,
                            backingTokenPrice: backingAssetPrice,
                            maxSwapBackingAmount: maxSwapBackingAmount,
                            maxProvidedBackingAmount: maxProvidedBackingAmount,
                            chainId: network.chainId,
                            isIncrease: isIncrease,
                            exposureAmount: exposureAmount,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureToken: exposureAsset.assetAddress,
                            exposureTokenPrice: exposureAssetPrice,
                            swapVenue: Charter.SWAP_VENUE_UNISWAP_V3,
                            borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                            borrowMarketId: marketId,
                            feeAmount: feeAmount,
                            feeAssetSymbol: feeAssetSymbol,
                            feeToken: feeToken,
                            feeTokenPrice: feeTokenPrice
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func loopShort(
            network: Network,
            marketId: Hex,
            backingAsset: Atlas.Asset,
            backingAssetPrice: Number,
            exposureAsset: Atlas.Asset,
            exposureAmount: Number,
            exposureAssetPrice: Number,
            minSwapBackingAmount: Number,
            providedBackingAmount: Number,
            isCappedMax: Bool,
            poolFee: UInt,
            isIncrease: Bool
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            if exposureAmount.isMaxUint256 {
                return .failure(.error("Loop short does not support max exposure amount"))
            }

            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }

            guard backingAsset.assetAddress == morphoMarket.collateralToken else {
                return .failure(
                    .error("Backing asset does not match morpho market collateral token")
                )
            }

            guard exposureAsset.assetAddress == morphoMarket.loanToken else {
                return .failure(
                    .error("Exposure asset does not match morpho market loan token")
                )
            }

            let scriptAddress = Create2.getScriptAddress(LoopShort.creationCode)
            let scriptFunction = LoopShort.loopFn

            // Fee calculation for LoopShort: fee = minSwapBackingAmount * p
            // Simple percentage calculation where fee is p% of the backing amount to be swapped
            let feeAmount =
                (minSwapBackingAmount * Charter.LOOP_FEE_PERCENT) / Charter.FEE_PERCENT_SCALE
            let feeRecipient = Charter.LOOP_FEE_RECIPIENT
            let feeToken = backingAsset.assetAddress
            let feeAssetSymbol = backingAsset.symbol
            let feeTokenPrice = backingAssetPrice

            let scriptCallValues: [ABI.Value] = [
                .address(morphoMarket.morpho),
                .tuple5(
                    .address(morphoMarket.loanToken),
                    .address(morphoMarket.collateralToken),
                    .address(morphoMarket.oracle),
                    .address(morphoMarket.irm),
                    .uint256(morphoMarket.lltv)
                ),
                .tuple9(
                    .address(exposureAsset.assetAddress),
                    .address(backingAsset.assetAddress),
                    .uint24(poolFee),
                    .uint256(exposureAmount),
                    .uint256(minSwapBackingAmount),
                    .uint256(providedBackingAmount),
                    .bool(isCappedMax),
                    .uint256(feeAmount),
                    .address(feeRecipient)
                ),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_LOOP_SHORT,
                    actionContext: .loopShort(
                        ActionContext.LoopShortActionContext(
                            backingAssetSymbol: backingAsset.symbol,
                            backingToken: backingAsset.assetAddress,
                            backingTokenPrice: backingAssetPrice,
                            minSwapBackingAmount: minSwapBackingAmount,
                            providedBackingAmount: providedBackingAmount,
                            chainId: network.chainId,
                            isIncrease: isIncrease,
                            exposureAmount: exposureAmount,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureToken: exposureAsset.assetAddress,
                            exposureTokenPrice: exposureAssetPrice,
                            swapVenue: Charter.SWAP_VENUE_UNISWAP_V3,
                            borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                            borrowMarketId: marketId,
                            feeAmount: feeAmount,
                            feeAssetSymbol: feeAssetSymbol,
                            feeToken: feeToken,
                            feeTokenPrice: feeTokenPrice
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func unloopLong(
            network: Network,
            marketId: Hex,
            backingAsset: Atlas.Asset,
            backingAssetPrice: Number,
            exposureAsset: Atlas.Asset,
            exposureAmount: Number,
            exposureAssetPrice: Number,
            backingAmountToExit: Number,
            minSwapBackingAmount: Number,
            poolFee: UInt
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }

            guard backingAsset.assetAddress == morphoMarket.loanToken else {
                return .failure(
                    .error("Backing asset does not match morpho market loan token")
                )
            }

            guard exposureAsset.assetAddress == morphoMarket.collateralToken else {
                return .failure(
                    .error("Exposure asset does not match morpho market collateral token")
                )
            }

            let scriptAddress = Create2.getScriptAddress(UnloopLong.creationCode)
            let scriptFunction = UnloopLong.unloopFn

            // Fee calculation for UnloopLong: fee = minSwapBackingAmount * p
            // Simple percentage calculation where fee is p% of the backing amount to be swapped
            let feeAmount =
                (minSwapBackingAmount * Charter.LOOP_FEE_PERCENT) / Charter.FEE_PERCENT_SCALE
            let feeRecipient = Charter.LOOP_FEE_RECIPIENT
            let feeToken = backingAsset.assetAddress
            let feeAssetSymbol = backingAsset.symbol
            let feeTokenPrice = backingAssetPrice

            let scriptCallValues: [ABI.Value] = [
                .address(morphoMarket.morpho),
                .tuple5(
                    .address(morphoMarket.loanToken),
                    .address(morphoMarket.collateralToken),
                    .address(morphoMarket.oracle),
                    .address(morphoMarket.irm),
                    .uint256(morphoMarket.lltv)
                ),
                .tuple8(
                    .address(exposureAsset.assetAddress),
                    .address(backingAsset.assetAddress),
                    .uint24(poolFee),
                    .uint256(exposureAmount),
                    .uint256(backingAmountToExit),
                    .uint256(minSwapBackingAmount),
                    .uint256(feeAmount),
                    .address(feeRecipient)
                ),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_UNLOOP_LONG,
                    actionContext: .unloopLong(
                        ActionContext.UnloopLongActionContext(
                            backingAssetSymbol: backingAsset.symbol,
                            backingToken: backingAsset.assetAddress,
                            backingTokenPrice: backingAssetPrice,
                            minSwapBackingAmount: minSwapBackingAmount,
                            backingAmountToExit: backingAmountToExit,
                            chainId: network.chainId,
                            exposureAmount: exposureAmount,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureToken: exposureAsset.assetAddress,
                            exposureTokenPrice: exposureAssetPrice,
                            swapVenue: Charter.SWAP_VENUE_UNISWAP_V3,
                            borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                            borrowMarketId: marketId,
                            feeAmount: feeAmount,
                            feeAssetSymbol: feeAssetSymbol,
                            feeToken: feeToken,
                            feeTokenPrice: feeTokenPrice
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func unloopShort(
            network: Network,
            marketId: Hex,
            backingAsset: Atlas.Asset,
            backingAssetPrice: Number,
            exposureAsset: Atlas.Asset,
            exposureAmount: Number,
            exposureAssetPrice: Number,
            backingAmountToExit: Number,
            maxSwapBackingAmount: Number,
            poolFee: UInt,
            maxExposureAmount: Number
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }

            guard backingAsset.assetAddress == morphoMarket.collateralToken else {
                return .failure(
                    .error("Backing asset does not match morpho market collateral token")
                )
            }

            guard exposureAsset.assetAddress == morphoMarket.loanToken else {
                return .failure(
                    .error("Exposure asset does not match morpho market loan token")
                )
            }

            let scriptAddress = Create2.getScriptAddress(UnloopShort.creationCode)
            let scriptFunction = UnloopShort.unloopFn

            // Fee calculation for UnloopShort: fee = (exposureAmount * p) / (1 - p)
            // This formula ensures the fee is p% of the total (including the fee itself),
            // not just p% of the exposure amount. Example: with p=0.04%, if we want the fee to be
            // 0.04% of the final total, we calculate: fee = exposureAmount * 0.0004 / 0.9996
            let amountForFeeCalc: Number =
                exposureAmount.isMaxUint256 ? maxExposureAmount : exposureAmount
            let feeAmount =
                (amountForFeeCalc * Charter.LOOP_FEE_PERCENT)
                / (Charter.FEE_PERCENT_SCALE - Charter.LOOP_FEE_PERCENT)
            let feeRecipient = Charter.LOOP_FEE_RECIPIENT
            let feeToken = exposureAsset.assetAddress
            let feeAssetSymbol = exposureAsset.symbol
            let feeTokenPrice = exposureAssetPrice

            let scriptCallValues: [ABI.Value] = [
                .address(morphoMarket.morpho),
                .tuple5(
                    .address(morphoMarket.loanToken),
                    .address(morphoMarket.collateralToken),
                    .address(morphoMarket.oracle),
                    .address(morphoMarket.irm),
                    .uint256(morphoMarket.lltv)
                ),
                .tuple8(
                    .address(exposureAsset.assetAddress),
                    .address(backingAsset.assetAddress),
                    .uint24(poolFee),
                    .uint256(exposureAmount),
                    .uint256(backingAmountToExit),
                    .uint256(maxSwapBackingAmount),
                    .uint256(feeAmount),
                    .address(feeRecipient)
                ),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_UNLOOP_SHORT,
                    actionContext: .unloopShort(
                        ActionContext.UnloopShortActionContext(
                            backingAssetSymbol: backingAsset.symbol,
                            backingToken: backingAsset.assetAddress,
                            backingTokenPrice: backingAssetPrice,
                            maxSwapBackingAmount: maxSwapBackingAmount,
                            chainId: network.chainId,
                            exposureAmount: exposureAmount,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureToken: exposureAsset.assetAddress,
                            exposureTokenPrice: exposureAssetPrice,
                            swapVenue: Charter.SWAP_VENUE_UNISWAP_V3,
                            borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                            borrowMarketId: marketId,
                            feeAmount: feeAmount,
                            feeAssetSymbol: feeAssetSymbol,
                            feeToken: feeToken,
                            feeTokenPrice: feeTokenPrice
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func addBackingToken(
            network: Network,
            marketId: Hex,
            backingAsset: Atlas.Asset,
            backingAssetPrice: Number,
            exposureAsset: Atlas.Asset,
            exposureAssetPrice: Number,
            amount: Number,
            isCappedMax: Bool,
            isShort: Bool
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }

            let scriptAddress: Hex
            let scriptFunction: ABI.Function

            if isShort {
                guard backingAsset.assetAddress == morphoMarket.collateralToken else {
                    return .failure(
                        .error("Backing asset does not match morpho market collateral token")
                    )
                }
                guard exposureAsset.assetAddress == morphoMarket.loanToken else {
                    return .failure(
                        .error("Exposure asset does not match morpho market loan token")
                    )
                }
                scriptAddress = Hex(Create2.getScriptAddress(UnloopShort.creationCode).address.data)
                scriptFunction = UnloopShort.addBackingTokenFn
            } else {
                guard backingAsset.assetAddress == morphoMarket.loanToken else {
                    return .failure(
                        .error("Backing asset does not match morpho market loan token")
                    )
                }
                guard exposureAsset.assetAddress == morphoMarket.collateralToken else {
                    return .failure(
                        .error("Exposure asset does not match morpho market collateral token")
                    )
                }
                scriptAddress = Hex(Create2.getScriptAddress(UnloopLong.creationCode).address.data)
                scriptFunction = UnloopLong.addBackingTokenFn
            }

            let scriptCallValues: [ABI.Value] = [
                .address(morphoMarket.morpho),
                .tuple5(
                    .address(morphoMarket.loanToken),
                    .address(morphoMarket.collateralToken),
                    .address(morphoMarket.oracle),
                    .address(morphoMarket.irm),
                    .uint256(morphoMarket.lltv)
                ),
                .uint256(amount),
                .bool(isCappedMax),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_ADD_BACKING_TOKEN,
                    actionContext: .addBackingToken(
                        ActionContext.AddBackingTokenActionContext(
                            amount: amount,
                            backingAssetSymbol: backingAsset.symbol,
                            backingToken: backingAsset.assetAddress,
                            backingTokenPrice: backingAssetPrice,
                            chainId: network.chainId,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureToken: exposureAsset.assetAddress,
                            exposureTokenPrice: exposureAssetPrice,
                            borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                            borrowMarketId: marketId,
                            isShort: isShort
                        )
                    ),
                    scriptAddress: EthAddress(fromData: scriptAddress.data)!,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func withdrawBackingToken(
            network: Network,
            marketId: Hex,
            backingAsset: Atlas.Asset,
            backingAssetPrice: Number,
            exposureAsset: Atlas.Asset,
            exposureAssetPrice: Number,
            amount: Number,
            isShort: Bool
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            guard let morphoMarket = Atlas.getMorphoMarket(network: network, marketId: marketId)
            else {
                return .failure(.morphoMarketNotFound(marketId: marketId, network: network))
            }

            if isShort {
                // For short positions, backing is collateral token
                guard backingAsset.assetAddress == morphoMarket.collateralToken else {
                    return .failure(
                        .error("Backing asset does not match morpho market collateral token")
                    )
                }

                guard exposureAsset.assetAddress == morphoMarket.loanToken else {
                    return .failure(
                        .error("Exposure asset does not match morpho market loan token")
                    )
                }
            } else {
                // For long positions, backing is loan token
                guard backingAsset.assetAddress == morphoMarket.loanToken else {
                    return .failure(
                        .error("Backing asset does not match morpho market loan token")
                    )
                }

                guard exposureAsset.assetAddress == morphoMarket.collateralToken else {
                    return .failure(
                        .error("Exposure asset does not match morpho market collateral token")
                    )
                }
            }

            let scriptAddress = Create2.getScriptAddress(
                isShort ? LoopShort.creationCode : LoopLong.creationCode
            )
            let scriptFunction =
                isShort
                ? LoopShort.withdrawBackingTokenFn : LoopLong.withdrawBackingTokenFn

            let scriptCallValues: [ABI.Value] = [
                .address(morphoMarket.morpho),
                .tuple5(
                    .address(morphoMarket.loanToken),
                    .address(morphoMarket.collateralToken),
                    .address(morphoMarket.oracle),
                    .address(morphoMarket.irm),
                    .uint256(morphoMarket.lltv)
                ),
                .uint256(amount),
            ]

            return .success([
                .init(
                    actionType: Charter.ACTION_TYPE_WITHDRAW_BACKING_TOKEN,
                    actionContext: .withdrawBackingToken(
                        ActionContext.WithdrawBackingTokenActionContext(
                            amount: amount,
                            backingAssetSymbol: backingAsset.symbol,
                            backingToken: backingAsset.assetAddress,
                            backingTokenPrice: backingAssetPrice,
                            chainId: network.chainId,
                            exposureAssetSymbol: exposureAsset.symbol,
                            exposureToken: exposureAsset.assetAddress,
                            exposureTokenPrice: exposureAssetPrice,
                            borrowVenue: Charter.BORROW_VENUE_MORPHO_BLUE,
                            borrowMarketId: marketId,
                            isShort: isShort
                        )
                    ),
                    scriptAddress: scriptAddress,
                    scriptFunction: scriptFunction,
                    scriptCallValues: scriptCallValues,
                    expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                    network: network
                )
            ])
        }

        public static func quotePay(
            network: Network,
            asset: Atlas.Asset,
            assetPrice: Number,
            quotePayAmount: Amount,
            quoteId: Hex
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            var operations: [ImmedatiateOperationDetails] = []
            let paymentAsset: Atlas.Asset

            if asset.isNativeAsset {
                guard let wrappedAssetSymbol = asset.crossChainAsset?.wrappedAssetSymbol,
                    let wethAsset = Atlas.getAssetBySymbol(
                        network: network,
                        symbol: wrappedAssetSymbol
                    )
                else {
                    return .failure(
                        .unknownAsset(
                            symbol: asset.crossChainAsset?.wrappedAssetSymbol,
                            network: network,
                            address: nil
                        )
                    )
                }

                switch wrapAssetUpTo(
                    network: network,
                    underlyingAsset: asset,
                    targetAmount: quotePayAmount.underlying
                ) {
                    case .success(let wrapOps):
                        operations.append(contentsOf: wrapOps)
                        paymentAsset = wethAsset
                    case .failure(let err):
                        return .failure(err)
                }
            } else {
                paymentAsset = asset
            }

            let quotePayOp = ImmedatiateOperationDetails(
                actionType: ActionContext.QuotePayActionContext.actionType,
                actionContext: .quotePay(
                    Charter.ActionContext.QuotePayActionContext(
                        amount: quotePayAmount.underlying,
                        assetSymbol: paymentAsset.symbol,
                        chainId: network.chainId,
                        price: assetPrice,
                        payee: Charter.QUOTE_PAY_RECIPIENT,
                        quoteId: quoteId,
                        token: paymentAsset.assetAddress
                    )
                ),
                scriptAddress: Create2.getScriptAddress(QuotePay.creationCode),
                scriptFunction: QuotePay.payFn,
                scriptCallValues: [
                    .address(Charter.QUOTE_PAY_RECIPIENT),
                    .address(paymentAsset.assetAddress),
                    .uint256(quotePayAmount.underlying),
                    .bytes32(quoteId),
                ],
                expiryBuffer: Charter.STANDARD_EXPIRY_BUFFER,
                network: network
            )
            operations.append(quotePayOp)

            return .success(operations)
        }

        // CCTPv2

        /// Maps Network to CCTP v2 domain IDs
        /// Reference: https://developers.circle.com/stablecoins/docs/cctp-protocol-contract
        private static func getCCTPv2DomainId(for network: Network) -> UInt? {
            switch network {
                case .ethereum:
                    return 0  // Ethereum
                case .avalanche:
                    return 1  // Avalanche
                case .optimism:
                    return 2  // OP (Optimism)
                case .arbitrum:
                    return 3  // Arbitrum
                case .base:
                    return 6  // Base
                case .polygon:
                    return 7  // Polygon PoS
                case .unichain:
                    return 10  // Unichain
                case .linea:
                    return 11  // Linea
                case .sonic:
                    return 13  // Sonic
                case .worldChain:
                    return 14  // World Chain
                case .bnbSmartChain:
                    return 17  // BNB Smart Chain
                case .hyperEVM:
                    return 19  // HyperEVM
                default:
                    return nil  // Network not supported by CCTP v2
            }
        }

        /// Converts an Ethereum address (20 bytes) to a bytes32 format by padding with leading zeros
        private static func ethAddressToWord(_ address: EthAddress) -> Hex {
            let addressData = address.data
            let padding = Data(repeating: 0, count: 12)
            return Hex(padding + addressData)
        }

        public static func bridgeCCTPv2(
            srcNetwork: Network,
            srcAsset: Atlas.Asset,
            destNetwork: Network,
            destAsset: Atlas.Asset,
            rate: Percentage,
            assetPrice: Value,
            inputAmount: Amount,
            outputAmount: Amount,
            sender: EthAddress,
            recipient: EthAddress,
            isMaxBridge: Bool
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            // This now only generates the burn operation
            // The mint operation is handled separately via bridgeMint

            let tokenMessenger = Charter.CCTP_V2_TOKEN_MESSENGER

            guard let destinationDomain = getCCTPv2DomainId(for: destNetwork) else {
                return .failure(
                    .error("Destination network \(destNetwork) is not supported by CCTP v2")
                )
            }

            let burnScriptAddress = Create2.getScriptAddress(CCTPv2Actions.creationCode)
            let burnScriptFunction: ABI.Function = CCTPv2Actions.bridgeUSDCFn

            let burnScriptCallValues: [ABI.Value] = [
                .address(tokenMessenger),
                .uint256(inputAmount.underlying),
                .uint32(destinationDomain),
                .bytes32(ethAddressToWord(sender)),
                .address(srcAsset.assetAddress),
                // Calculate max fee by subtracting outputAmount from inputAmount
                .uint256(inputAmount.underlying - outputAmount.underlying),
                .uint32(UInt(1000)),  // Set slippage to 0.1% (1000 basis points)
                .bool(isMaxBridge),
            ]

            return .success([
                .init(
                    actionType: ActionContext.BridgeActionContext.actionType,
                    actionContext: .bridge(
                        Charter.ActionContext.BridgeActionContext(
                            assetSymbol: srcAsset.symbol,
                            bridgeType: .cctpV2,
                            chainId: srcNetwork.chainId,
                            destinationChainId: destNetwork.chainId,
                            destinationAssetSymbol: destAsset.symbol,
                            inputAmount: inputAmount.underlying,
                            outputAmount: outputAmount.underlying,
                            price: assetPrice.underlying,
                            recipient: recipient,
                            token: srcAsset.assetAddress
                        )
                    ),
                    scriptAddress: burnScriptAddress,
                    scriptFunction: burnScriptFunction,
                    scriptCallValues: burnScriptCallValues,
                    expiryBuffer: Charter.BRIDGE_EXPIRY_BUFFER,
                    network: srcNetwork
                )
            ])
        }

        public static func bridgeMint(
            srcNetwork: Network,
            destNetwork: Network,
            destAsset: Atlas.Asset,
            inputAmount: Amount,
            outputAmount: Amount,
            recipient: EthAddress,
            bridgeType: Charter.ActionContext.BridgeActionContext.BridgeType
        ) -> Result<[ImmedatiateOperationDetails], CharterError> {
            // This generates the mint operation for cross-chain bridges

            let messageTransmitter = Charter.CCTP_V2_MESSAGE_TRANSMITTER

            guard let atlasMintNetwork = Atlas.getNetwork(network: destNetwork) else {
                return .failure(.unknownAtlasNetwork(network: destNetwork))
            }

            let mintScriptAddress = Create2.getScriptAddress(CCTPv2Actions.creationCode)
            let mintScriptFunction: ABI.Function = CCTPv2Actions.mintUSDCFn
            // Calculate maxFee for TStoracle key generation
            let maxFee = inputAmount.underlying - outputAmount.underlying
            let mintScriptCallValues: [ABI.Value] = [
                .address(atlasMintNetwork.tStoracle),  // tStoracle address on destination network
                .address(messageTransmitter),
                .address(recipient),                   // recipient address for TStoracle key
                .uint256(srcNetwork.chainId),          // sourceChainId for TStoracle key
                .uint256(destNetwork.chainId),         // destinationChainId for TStoracle key
                .uint256(inputAmount.underlying),      // inputAmount for TStoracle key
                .uint256(maxFee),                      // maxFee for TStoracle key
            ]

            return .success([
                .init(
                    actionType: ActionContext.BridgeMintActionContext.actionType,
                    actionContext: .bridgeMint(
                        Charter.ActionContext.BridgeMintActionContext(
                            assetSymbol: destAsset.symbol,
                            bridgeType: bridgeType,
                            chainId: destNetwork.chainId,
                            sourceChainId: srcNetwork.chainId,
                            inputAmount: inputAmount.underlying,
                            outputAmount: outputAmount.underlying,
                            maxFee: inputAmount.underlying - outputAmount.underlying,
                            recipient: recipient,
                            token: destAsset.assetAddress
                        )
                    ),
                    scriptAddress: mintScriptAddress,
                    scriptFunction: mintScriptFunction,
                    scriptCallValues: mintScriptCallValues,
                    expiryBuffer: Charter.BRIDGE_EXPIRY_BUFFER,
                    network: destNetwork
                )
            ])
        }

        // MARK: - Missing Operations

        // The following operations are present in the original QuarkBuilder (legend-scripts)
        // but have not yet been implemented in Mercator:

        // 1. Recurring Swap Operations
        //    - recurringSwap: Executes periodic token swaps at specified intervals
        //    QuarkBuilder ref: SwapActionsBuilder.sol

        // 2. Composed Operations
        //    - swapAndSupply: Combines a token swap with a supply to a lending protocol
        //    - migrateSupplies: Migrates positions between different protocols
        //    QuarkBuilder ref: ComposedActionsBuilder.sol

    }
}
