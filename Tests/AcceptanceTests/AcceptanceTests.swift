import Eth
import Foundation
import Prelude
import SwiftKeccak
import SwiftNumber
import TestHelpers
import Testing
import Tradewinds

@testable import Charter

let useColor: Bool = ProcessInfo.processInfo.environment["NO_COLOR"] == nil

enum Call: CustomStringConvertible, Equatable {
    case bridge(
        bridge: String,
        srcNetwork: Network,
        destinationNetwork: Network,
        inputTokenAmount: TokenAmount,
        outputTokenAmount: TokenAmount,
        cappedMax: Bool,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case claimCometRewards(
        cometRewards: [CometReward],
        comets: [Comet],
        accounts: [TestHelpers.Account],
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case claimMorphoRewards(
        distributors: [MorphoDistributor],
        accounts: [TestHelpers.Account],
        rewardsClaimable: [TokenAmount],
        proofs: [MorphoClaimProof],
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case claimMerklRewards(
        distributor: MorphoDistributor,
        accounts: [TestHelpers.Account],
        rewardsClaimable: [TokenAmount],
        proofs: [MorphoClaimProof],
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case transferErc20(
        tokenAmount: TokenAmount,
        recipient: TestHelpers.Account,
        cappedMax: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case transferNativeToken(
        tokenAmount: TokenAmount,
        recipient: TestHelpers.Account,
        cappedMax: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case supplyToAave(
        tokenAmount: TokenAmount,
        pool: AavePool,
        cappedMax: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case withdrawFromAave(
        tokenAmount: TokenAmount,
        pool: AavePool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case supplyToComet(
        tokenAmount: TokenAmount,
        market: Comet,
        cappedMax: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case supplyMultipleAssetsAndBorrowFromComet(
        borrowAmount: TokenAmount,
        collateralAmounts: [TokenAmount],
        cappedMaxes: [Bool],
        market: Comet,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case repayAndWithdrawMultipleAssetsFromComet(
        repayAmount: TokenAmount,
        collateralAmounts: [TokenAmount],
        market: Comet,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case supplyToMorphoVault(
        tokenAmount: TokenAmount,
        vault: MorphoVault,
        cappedMax: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case withdrawFromMorphoVault(
        tokenAmount: TokenAmount,
        vault: MorphoVault,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case swap(
        filler: Filler,
        sellAmount: TokenAmount,
        buyAmount: TokenAmount,
        feeAmount: TokenAmount,
        feeRecipient: TestHelpers.Account,
        cappedMax: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case quotePay(
        payment: TokenAmount,
        payee: TestHelpers.Account,
        quote: TestHelpers.QuotePay,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case repayAndWithdrawCollateralFromMorpho(
        repayAmount: TokenAmount,
        collateralAmount: TokenAmount,
        market: Morpho,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case supplyCollateralAndBorrowFromMorpho(
        borrowAmount: TokenAmount,
        collateralAmount: TokenAmount,
        cappedMax: Bool,
        market: Morpho,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case loopLong(
        exposureAmount: TokenAmount,
        providedBackingAmount: TokenAmount,
        cappedMax: Bool,
        maxSwapBackingAmount: TokenAmount,
        feeAmount: TokenAmount,
        feeRecipient: TestHelpers.Account,
        market: Morpho,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case loopShort(
        exposureAmount: TokenAmount,
        providedBackingAmount: TokenAmount,
        cappedMax: Bool,
        minSwapBackingAmount: TokenAmount,
        feeAmount: TokenAmount,
        feeRecipient: TestHelpers.Account,
        market: Morpho,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case unloopLong(
        exposureAmount: TokenAmount,
        backingAmountToExit: TokenAmount,
        minSwapBackingAmount: TokenAmount,
        feeAmount: TokenAmount,
        feeRecipient: TestHelpers.Account,
        market: Morpho,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case unloopShort(
        exposureAmount: TokenAmount,
        backingAmountToExit: TokenAmount,
        maxSwapBackingAmount: TokenAmount,
        feeAmount: TokenAmount,
        feeRecipient: TestHelpers.Account,
        market: Morpho,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case addBackingToken(
        backingAmount: TokenAmount,
        cappedMax: Bool,
        market: Morpho,
        isShort: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case withdrawBackingToken(
        backingAmount: TokenAmount,
        market: Morpho,
        isShort: Bool,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case multicall(_ calls: [Call], executionType: Charter.Chart.Action.ExecutionType? = nil)
    case withdrawFromComet(
        tokenAmount: TokenAmount,
        market: Comet,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case wrapAsset(
        _ token: TestHelpers.Token,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case wrapUpTo(
        tokenAmount: TokenAmount,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case unwrapWETHUpTo(
        tokenAmount: TokenAmount,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case bridgeMint(
        network: Network,
        bridgeType: DApp,
        executionType: Charter.Chart.Action.ExecutionType? = nil
    )
    case unknownFunctionCall(String, String, ABI.Value)
    case unknownScriptCall(EthAddress, Hex)

    static let allFunctions: [(String, Hex, [ABI.Function])] = [
        ("AaveActions", AaveActions.creationCode, AaveActions.functions),
        ("AcrossActions", AcrossActions.creationCode, AcrossActions.functions),
        ("TransferActions", TransferActions.creationCode, TransferActions.functions),
        ("Multicall", Multicall.creationCode, Multicall.functions),
        ("QuotePay", QuotePay.creationCode, QuotePay.functions),
        ("WrapperActions", WrapperActions.creationCode, WrapperActions.functions),
        ("MorphoVaultActions", MorphoVaultActions.creationCode, MorphoVaultActions.functions),
        ("ApproveAndSwap", ApproveAndSwap.creationCode, ApproveAndSwap.functions),
        ("CCTPv2Actions", CCTPv2Actions.creationCode, CCTPv2Actions.functions),
    ]

    static func tryDecodeCall(
        scriptAddress: EthAddress,
        calldata: Hex,
        network: Network,
        executionType: Charter.Chart.Action.ExecutionType,
        isNestedCall: Bool = false
    ) -> Call {
        // We only attach execution type to the outermost call on each chain
        let executionTypeForCall = isNestedCall ? nil : executionType

        if scriptAddress == Create2.getScriptAddress(AcrossActions.creationCode) {
            if let (
                _,
                depositV3Params,
                _,
                useNativeToken,
                cappedMax
            ) = try? AcrossActions.depositV3Decode(input: calldata) {
                let dstNetwork = Network.fromChainId(depositV3Params.destinationChainId)
                let useEthSrcNetwork =
                    useNativeToken
                    && depositV3Params.inputToken == Token.weth.address(network: network)!
                let useEthDstNetwork =
                    useNativeToken
                    && depositV3Params.outputToken == Token.weth.address(network: dstNetwork)!
                let inputTokenAddress =
                    useEthSrcNetwork
                    ? Token.eth.address(network: network)! : depositV3Params.inputToken
                let outputTokenAddress =
                    useEthDstNetwork
                    ? Token.eth.address(network: dstNetwork)! : depositV3Params.outputToken

                return .bridge(
                    bridge: "Across",
                    srcNetwork: network,
                    destinationNetwork: Network.fromChainId(depositV3Params.destinationChainId),
                    inputTokenAmount: Token.getTokenAmount(
                        amount: depositV3Params.inputAmount,
                        network: network,
                        address: inputTokenAddress
                    ),
                    outputTokenAmount: Token.getTokenAmount(
                        amount: depositV3Params.outputAmount,
                        network: Network.fromChainId(depositV3Params.destinationChainId),
                        address: outputTokenAddress
                    ),
                    cappedMax: cappedMax,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(TransferActions.creationCode) {
            if let (token, recipient, amount, cappedMax) =
                try? TransferActions.transferERC20TokenDecode(
                    input: calldata
                )
            {
                return .transferErc20(
                    tokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: token
                    ),
                    recipient: TestHelpers.Account.from(address: recipient),
                    cappedMax: cappedMax,
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (recipient, amount, cappedMax) =
                try? TransferActions.transferNativeTokenDecode(input: calldata)
            {
                let nativeToken: TestHelpers.Token = network == .hyperEVM ? .hype : network == .polygon ? .pol : .eth
                return .transferNativeToken(
                    tokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: nativeToken.address(network: network)!
                    ),
                    recipient: TestHelpers.Account.from(address: recipient),
                    cappedMax: cappedMax,
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(QuotePay.creationCode) {
            if let (payee, paymentToken, quotedAmount, quoteId) = try? QuotePay.payDecode(
                input: calldata
            ) {
                return .quotePay(
                    payment: Token.getTokenAmount(
                        amount: quotedAmount,
                        network: network,
                        address: paymentToken
                    ),
                    payee: TestHelpers.Account.from(address: payee),
                    quote: TestHelpers.QuotePay.findQuote(quoteId: quoteId, prices: [:], fees: [:]),
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(Multicall.creationCode) {
            if let (callContracts, callDatas) = try? Multicall.runDecode(input: calldata) {
                let calls = zip(callContracts, callDatas)
                    .map {
                        Call.tryDecodeCall(
                            scriptAddress: $0,
                            calldata: $1,
                            network: network,
                            executionType: executionType,
                            isNestedCall: true
                        )
                    }
                return .multicall(calls, executionType: executionTypeForCall)
            }
        }

        if scriptAddress == Create2.getScriptAddress(CometClaimRewards.creationCode) {
            if let (cometRewards, comets, accounts) = try? CometClaimRewards.claimDecode(
                input: calldata
            ) {
                let comets = comets.map { Comet.from(network: network, address: $0) }

                return .claimCometRewards(
                    cometRewards: cometRewards.enumerated()
                        .map { index, cometRewardAddress in
                            CometReward.from(
                                network: network,
                                address: cometRewardAddress,
                                comet: comets[index]
                            )
                        },
                    comets: comets,
                    accounts: accounts.map { account in
                        TestHelpers.Account.from(address: account)
                    },
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(AaveActions.creationCode) {
            if let (poolAddress, asset, amount, cappedMax) = try? AaveActions.supplyDecode(
                input: calldata
            ) {
                return .supplyToAave(
                    tokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: asset
                    ),
                    pool: AavePool.from(network: network, address: poolAddress),
                    cappedMax: cappedMax,
                    network: network,
                    executionType: executionTypeForCall
                )
            }

            if let (poolAddress, asset, amount) = try? AaveActions.withdrawDecode(input: calldata) {
                return .withdrawFromAave(
                    tokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: asset
                    ),
                    pool: AavePool.from(network: network, address: poolAddress),
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(CometSupplyActions.creationCode) {
            if let (comet, asset, amount, cappedMax) = try? CometSupplyActions.supplyDecode(
                input: calldata
            ) {
                return .supplyToComet(
                    tokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: asset
                    ),
                    market: Comet.from(network: network, address: comet),
                    cappedMax: cappedMax,
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (comet, to, asset, amount, cappedMax) =
                try? CometSupplyActions.supplyToDecode(
                    input: calldata
                )
            {
                print("supplyTo(\(comet) to: \(to) \(asset) \(amount))")
            } else if let (comet, from, to, asset, amount, cappedMax) =
                try? CometSupplyActions.supplyFromDecode(input: calldata)
            {
                print("supplyFrom(\(comet) from: \(from) to: \(to) \(asset) \(amount))")
            } else if let (comet, assets, amounts, cappedMaxes) =
                try? CometSupplyActions.supplyMultipleAssetsDecode(input: calldata)
            {
                print("supplyMultipleAssets(\(comet) \(assets) \(amounts))")
            }
        }

        if scriptAddress == Create2.getScriptAddress(CometWithdrawActions.creationCode) {
            if let (comet, asset, amount) = try? CometWithdrawActions.withdrawDecode(
                input: calldata
            ) {
                return .withdrawFromComet(
                    tokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: asset
                    ),
                    market: Comet.from(network: network, address: comet),
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress
            == Create2.getScriptAddress(CometRepayAndWithdrawMultipleAssets.creationCode)
        {
            if let (comet, assets, amounts, baseAsset, repayAmount) =
                try? CometRepayAndWithdrawMultipleAssets.runDecode(input: calldata)
            {
                let collateralAmounts = zip(amounts, assets)
                    .map {
                        Token.getTokenAmount(amount: $0, network: network, address: $1)
                    }

                return repayAndWithdrawMultipleAssetsFromComet(
                    repayAmount: Token.getTokenAmount(
                        amount: repayAmount,
                        network: network,
                        address: baseAsset
                    ),
                    collateralAmounts: collateralAmounts,
                    market: Comet.from(network: network, address: comet),
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress
            == Create2.getScriptAddress(CometSupplyMultipleAssetsAndBorrow.creationCode)
        {
            if let (comet, assets, amounts, baseAsset, borrowAmount, cappedMaxes) =
                try? CometSupplyMultipleAssetsAndBorrow.runDecode(input: calldata)
            {
                let collateralAmounts = zip(amounts, assets)
                    .map {
                        Token.getTokenAmount(amount: $0, network: network, address: $1)
                    }
                return supplyMultipleAssetsAndBorrowFromComet(
                    borrowAmount: Token.getTokenAmount(
                        amount: borrowAmount,
                        network: network,
                        address: baseAsset
                    ),
                    collateralAmounts: collateralAmounts,
                    cappedMaxes: cappedMaxes,
                    market: Comet.from(network: network, address: comet),
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(MorphoActions.creationCode) {
            if let (_, marketParams, collateralTokenAmount, borrowTokenAmount, cappedMax) =
                try? MorphoActions.supplyCollateralAndBorrowDecode(input: calldata)
            {
                let borrowToken = Token.from(network: network, address: marketParams.loanToken)
                let collateralToken = Token.from(
                    network: network,
                    address: marketParams.collateralToken
                )

                return .supplyCollateralAndBorrowFromMorpho(
                    borrowAmount: TokenAmount(fromWei: borrowTokenAmount, ofToken: borrowToken),
                    collateralAmount: TokenAmount(
                        fromWei: collateralTokenAmount,
                        ofToken: collateralToken
                    ),
                    cappedMax: cappedMax,
                    market: Morpho(collateralToken: collateralToken, borrowToken: borrowToken),
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (_, marketParams, repayAmount, withdrawAmount) =
                try? MorphoActions.repayAndWithdrawCollateralDecode(input: calldata)
            {
                let repayToken = Token.from(network: network, address: marketParams.loanToken)
                let collateralToken = Token.from(
                    network: network,
                    address: marketParams.collateralToken
                )

                return .repayAndWithdrawCollateralFromMorpho(
                    repayAmount: TokenAmount(fromWei: repayAmount, ofToken: repayToken),
                    collateralAmount: TokenAmount(
                        fromWei: withdrawAmount,
                        ofToken: collateralToken
                    ),
                    market: Morpho(collateralToken: collateralToken, borrowToken: repayToken),
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(MorphoRewardsActions.creationCode) {
            if let (distributors, accounts, rewards, claimables, proofs) =
                try? MorphoRewardsActions.claimAllDecode(input: calldata)
            {
                return .claimMorphoRewards(
                    distributors: distributors.map { distributorAddress in
                        MorphoDistributor.from(network: network, address: distributorAddress)
                    },
                    accounts: accounts.map { account in
                        Account.from(address: account)
                    },
                    rewardsClaimable: zip(rewards, claimables)
                        .map { rewardAddress, claimable in
                            Token.getTokenAmount(
                                amount: claimable,
                                network: network,
                                address: rewardAddress
                            )
                        },
                    proofs: proofs.map { proof in
                        MorphoClaimProof.from(proof: proof)
                    },
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(MerklRewardsActions.creationCode) {
            if let (distributor, accounts, rewards, claimables, proofs) =
                try? MerklRewardsActions.claimDecode(input: calldata)
            {
                return .claimMerklRewards(
                    distributor: MorphoDistributor.from(network: network, address: distributor),
                    accounts: accounts.map { account in
                        TestHelpers.Account.from(address: account)
                    },
                    rewardsClaimable: zip(rewards, claimables)
                        .map { rewardAddress, claimable in
                            Token.getTokenAmount(
                                amount: claimable,
                                network: network,
                                address: rewardAddress
                            )
                        },
                    proofs: proofs.map { proof in
                        MorphoClaimProof.from(proof: proof)
                    },
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(MorphoVaultActions.creationCode) {
            if let (vault, asset, amount, cappedMax) = try? MorphoVaultActions.depositDecode(
                input: calldata
            ) {
                return .supplyToMorphoVault(
                    tokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: asset
                    ),
                    vault: MorphoVault.from(network: network, address: vault),
                    cappedMax: cappedMax,
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (vaultAddress, amount) = try? MorphoVaultActions.withdrawDecode(
                input: calldata
            ) {
                let vault = MorphoVault.from(network: network, address: vaultAddress)
                guard let tokenAddress = vault.asset(network: network).address(network: network)
                else {
                    fatalError(
                        "No asset for \(vault.description) on network \(network.description)"
                    )
                }
                let token = Token.from(
                    network: network,
                    address: tokenAddress
                )

                return .withdrawFromMorphoVault(
                    tokenAmount: TokenAmount(fromWei: amount, ofToken: token),
                    vault: vault,
                    network: network
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(ApproveAndSwap.creationCode) {
            if let (
                filler,
                sellToken,
                sellAmount,
                buyToken,
                minBuyAmount,
                feeToken,
                feeAmount,
                feeRecipient,
                cappedMax
            ) = try? ApproveAndSwap.swapExactInDecode(input: calldata) {
                return .swap(
                    filler: Filler.from(network: network, address: filler),
                    sellAmount: Token.getTokenAmount(
                        amount: sellAmount,
                        network: network,
                        address: sellToken
                    ),
                    buyAmount: Token.getTokenAmount(
                        amount: minBuyAmount,
                        network: network,
                        address: buyToken
                    ),
                    feeAmount: Token.getTokenAmount(
                        amount: feeAmount,
                        network: network,
                        address: feeToken
                    ),
                    feeRecipient: TestHelpers.Account.from(address: feeRecipient),
                    cappedMax: cappedMax,
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(LoopLong.creationCode) {
            if let (
                _,
                _,
                loopInfo
            ) = try? LoopLong.loopDecode(input: calldata) {
                let exposureToken = Token.from(network: network, address: loopInfo.exposureToken)
                let backingToken = Token.from(
                    network: network,
                    address: loopInfo.backingToken
                )

                return .loopLong(
                    exposureAmount: TokenAmount(
                        fromWei: loopInfo.exposureAmount,
                        ofToken: exposureToken
                    ),
                    providedBackingAmount: TokenAmount(
                        fromWei: loopInfo.maxProvidedBackingAmount,
                        ofToken: backingToken
                    ),
                    cappedMax: loopInfo.cappedMaxForProvidedBackingAmount,
                    maxSwapBackingAmount: TokenAmount(
                        fromWei: loopInfo.maxSwapBackingAmount,
                        ofToken: backingToken
                    ),
                    feeAmount: TokenAmount(
                        fromWei: loopInfo.feeAmount,
                        ofToken: exposureToken
                    ),
                    feeRecipient: TestHelpers.Account.from(address: loopInfo.feeRecipient),
                    market: Morpho(collateralToken: exposureToken, borrowToken: backingToken),
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (_, marketParams, amount) = try? LoopLong.withdrawBackingTokenDecode(
                input: calldata
            ) {
                let exposureToken = Token.from(
                    network: network,
                    address: marketParams.collateralToken
                )
                let backingToken = Token.from(
                    network: network,
                    address: marketParams.loanToken
                )

                return .withdrawBackingToken(
                    backingAmount: TokenAmount(fromWei: amount, ofToken: backingToken),
                    market: Morpho(collateralToken: exposureToken, borrowToken: backingToken),
                    isShort: false,
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(LoopShort.creationCode) {
            if let (
                _,
                _,
                loopInfo
            ) = try? LoopShort.loopDecode(input: calldata) {
                let exposureToken = Token.from(network: network, address: loopInfo.exposureToken)
                let backingToken = Token.from(
                    network: network,
                    address: loopInfo.backingToken
                )

                return .loopShort(
                    exposureAmount: TokenAmount(
                        fromWei: loopInfo.exposureAmount,
                        ofToken: exposureToken
                    ),
                    providedBackingAmount: TokenAmount(
                        fromWei: loopInfo.providedBackingAmount,
                        ofToken: backingToken
                    ),
                    cappedMax: loopInfo.cappedMaxForProvidedBackingAmount,
                    minSwapBackingAmount: TokenAmount(
                        fromWei: loopInfo.minSwapBackingAmount,
                        ofToken: backingToken
                    ),
                    feeAmount: TokenAmount(
                        fromWei: loopInfo.feeAmount,
                        ofToken: backingToken
                    ),
                    feeRecipient: TestHelpers.Account.from(address: loopInfo.feeRecipient),
                    market: Morpho(collateralToken: backingToken, borrowToken: exposureToken),
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (_, marketParams, amount) = try? LoopShort.withdrawBackingTokenDecode(
                input: calldata
            ) {
                let exposureToken = Token.from(network: network, address: marketParams.loanToken)
                let backingToken = Token.from(
                    network: network,
                    address: marketParams.collateralToken
                )

                return .withdrawBackingToken(
                    backingAmount: TokenAmount(fromWei: amount, ofToken: backingToken),
                    market: Morpho(collateralToken: backingToken, borrowToken: exposureToken),
                    isShort: true,
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(UnloopLong.creationCode) {
            if let (
                _,
                _,
                unloopInfo
            ) = try? UnloopLong.unloopDecode(input: calldata) {
                let exposureToken = Token.from(network: network, address: unloopInfo.exposureToken)
                let backingToken = Token.from(
                    network: network,
                    address: unloopInfo.backingToken
                )

                return .unloopLong(
                    exposureAmount: TokenAmount(
                        fromWei: unloopInfo.exposureAmount,
                        ofToken: exposureToken
                    ),
                    backingAmountToExit: TokenAmount(
                        fromWei: unloopInfo.backingAmountToExit,
                        ofToken: backingToken
                    ),
                    minSwapBackingAmount: TokenAmount(
                        fromWei: unloopInfo.minSwapBackingAmount,
                        ofToken: backingToken
                    ),
                    feeAmount: TokenAmount(
                        fromWei: unloopInfo.feeAmount,
                        ofToken: backingToken
                    ),
                    feeRecipient: TestHelpers.Account.from(address: unloopInfo.feeRecipient),
                    market: Morpho(collateralToken: exposureToken, borrowToken: backingToken),
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (_, marketParams, amount, cappedMax) =
                try? UnloopLong.addBackingTokenDecode(input: calldata)
            {
                let exposureToken = Token.from(
                    network: network,
                    address: marketParams.collateralToken
                )
                let backingToken = Token.from(
                    network: network,
                    address: marketParams.loanToken
                )

                return .addBackingToken(
                    backingAmount: TokenAmount(fromWei: amount, ofToken: backingToken),
                    cappedMax: cappedMax,
                    market: Morpho(collateralToken: exposureToken, borrowToken: backingToken),
                    isShort: false,
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(UnloopShort.creationCode) {
            if let (
                _,
                _,
                unloopInfo
            ) = try? UnloopShort.unloopDecode(input: calldata) {
                let exposureToken = Token.from(network: network, address: unloopInfo.exposureToken)
                let backingToken = Token.from(
                    network: network,
                    address: unloopInfo.backingToken
                )

                return .unloopShort(
                    exposureAmount: TokenAmount(
                        fromWei: unloopInfo.exposureAmount,
                        ofToken: exposureToken
                    ),
                    backingAmountToExit: TokenAmount(
                        fromWei: unloopInfo.backingAmountToExit,
                        ofToken: backingToken
                    ),
                    maxSwapBackingAmount: TokenAmount(
                        fromWei: unloopInfo.maxSwapBackingAmount,
                        ofToken: backingToken
                    ),
                    feeAmount: TokenAmount(
                        fromWei: unloopInfo.feeAmount,
                        ofToken: exposureToken
                    ),
                    feeRecipient: TestHelpers.Account.from(address: unloopInfo.feeRecipient),
                    market: Morpho(collateralToken: backingToken, borrowToken: exposureToken),
                    network: network,
                    executionType: executionTypeForCall
                )
            } else if let (_, marketParams, amount, cappedMax) =
                try? UnloopShort.addBackingTokenDecode(input: calldata)
            {
                let exposureToken = Token.from(network: network, address: marketParams.loanToken)
                let backingToken = Token.from(
                    network: network,
                    address: marketParams.collateralToken
                )

                return .addBackingToken(
                    backingAmount: TokenAmount(fromWei: amount, ofToken: backingToken),
                    cappedMax: cappedMax,
                    market: Morpho(collateralToken: backingToken, borrowToken: exposureToken),
                    isShort: true,
                    network: network,
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(WrapperActions.creationCode) {
            if let _ = try? WrapperActions.wrapAllETHDecode(input: calldata) {
                return .wrapAsset(.eth, executionType: executionTypeForCall)
            } else if let _ = try? WrapperActions.wrapETHDecode(input: calldata) {
                return .wrapAsset(.eth, executionType: executionTypeForCall)
            } else if let (_, amount) = try? WrapperActions.wrapETHUpToDecode(input: calldata) {
                let nativeToken: TestHelpers.Token = network == .hyperEVM ? .hype : network == .polygon ? .pol : .eth
                return .wrapUpTo(
                    tokenAmount: TokenAmount(fromWei: amount, ofToken: nativeToken),
                    executionType: executionTypeForCall
                )
            } else if let (_, amount) = try? WrapperActions.unwrapWETHUpToDecode(input: calldata) {
                let wrappedToken: TestHelpers.Token = network == .hyperEVM ? .whype : network == .polygon ? .wpol : .weth
                return .unwrapWETHUpTo(
                    tokenAmount: TokenAmount(fromWei: amount, ofToken: wrappedToken),
                    executionType: executionTypeForCall
                )
            }
        }

        if scriptAddress == Create2.getScriptAddress(CCTPv2Actions.creationCode) {
            if let (
                _,  // tokenMessenger
                amount,
                destinationDomain,
                _,  // mintRecipient
                burnToken,
                maxFee,
                _,  // minFinalityThreshold
                cappedMax
            ) = try? CCTPv2Actions.bridgeUSDCDecode(input: calldata) {
                // Map CCTP v2 domain ID to network
                // Reference: https://developers.circle.com/stablecoins/docs/cctp-protocol-contract
                let destinationNetwork: Network = {
                    switch destinationDomain {
                        case 0: return .ethereum  // Ethereum
                        case 1: return .avalanche  // Avalanche
                        case 2: return .optimism  // OP (Optimism)
                        case 3: return .arbitrum  // Arbitrum
                        case 6: return .base  // Base
                        case 7: return .polygon  // Polygon PoS
                        case 10: return .unichain  // Unichain
                        case 11: return .linea  // Linea
                        case 13: return .sonic  // Sonic
                        case 14: return .worldChain  // World Chain
                        case 17: return .bnbSmartChain  // BNB Smart Chain
                        case 19: return .hyperEVM  // HyperEVM
                        default: return network  // Fallback to current network if domain not recognized
                    }
                }()

                return .bridge(
                    bridge: "CCTPv2",
                    srcNetwork: network,
                    destinationNetwork: destinationNetwork,
                    inputTokenAmount: Token.getTokenAmount(
                        amount: amount,
                        network: network,
                        address: burnToken
                    ),
                    outputTokenAmount: Token.getTokenAmount(
                        amount: amount - maxFee,
                        network: network,
                        address: burnToken
                    ),
                    cappedMax: cappedMax,
                    executionType: executionTypeForCall
                )
            } else if let (
                _,  // tStoracle
                _,  // messageTransmitter
                _,  // recipient
                _,  // sourceChainId
                _,  // destinationChainId
                _,  // inputAmount
                _   // maxFee
            ) = try? CCTPv2Actions.mintUSDCDecode(input: calldata) {
                return .bridgeMint(
                    network: network,
                    bridgeType: .CircleBridge,
                    executionType: executionTypeForCall
                )
            }
        }

        for (name, creationCode, functions) in Call.allFunctions {
            if scriptAddress == Create2.getScriptAddress(creationCode) {
                for function in functions {
                    if let value = try? function.decodeInput(input: calldata) {
                        print("unknownFunctionCall: \(name), \(function), \(value)")
                        return .unknownFunctionCall(name, function.name, value)
                    }
                }
            }
        }
        return .unknownScriptCall(scriptAddress, calldata)
    }

    var description: String {
        switch self {
            case .bridge(
                let
                    bridge,
                let chainId,
                let destinationChainId,
                let inputTokenAmount,
                let outputTokenAmount,
                let cappedMax,
                let
                    executionType
            ):
                return
                    "bridge(\(bridge), \(inputTokenAmount.amount) \(inputTokenAmount.token.symbol) to receive \(outputTokenAmount.amount) \(outputTokenAmount.token.symbol) from \(chainId.description) to \(destinationChainId.description) \(cappedMax ? "with" : "without") max)\(executionTypeDescription(executionType))"
            case .claimCometRewards(
                let cometRewards,
                let comets,
                let accounts,
                let network,
                let executionType
            ):
                return
                    "claimCometRewards(claiming from \(cometRewards.map { $0.description }.joined(separator: ", ")) for \(comets.map { $0.description }.joined(separator: ", ")) for \(accounts.map { $0.description }.joined(separator: ", ")) on \(network.description))\(executionTypeDescription(executionType))"
            case .claimMorphoRewards(
                let
                    distributors,
                let accounts,
                let rewardsClaimable,
                let proofs,
                let network,
                let executionType
            ):
                return
                    "claimMorphoRewards(claiming \(rewardsClaimable.map { $0.token.symbol }.joined(separator: ", ")) from \(distributors.map { $0.description }.joined(separator: ", ")) for \(accounts.map { $0.description }.joined(separator: ", ")) with proofs \(proofs.map { $0.description }.joined(separator: ", ")) on \(network.description))\(executionTypeDescription(executionType))"
            case .claimMerklRewards(
                let
                    distributor,
                let accounts,
                let rewardsClaimable,
                let proofs,
                let network,
                let executionType
            ):
                return
                    "claimMerklRewards(claiming \(rewardsClaimable.map { $0.token.symbol }.joined(separator: ", ")) from \(distributor.description) for \(accounts.map { $0.description }.joined(separator: ", ")) with proofs \(proofs.map { $0.description }.joined(separator: ", ")) on \(network.description))\(executionTypeDescription(executionType))"
            case .transferErc20(
                let tokenAmount,
                let recipient,
                let cappedMax,
                let network,
                let executionType
            ):
                return
                    "transferErc20(\(tokenAmount.amount) \(tokenAmount.token.symbol) to \(recipient.description) \(cappedMax ? "with" : "without") max on \(network.description))\(executionTypeDescription(executionType))"
            case .transferNativeToken(
                let tokenAmount,
                let recipient,
                let cappedMax,
                let network,
                let executionType
            ):
                return
                    "transferNativeToken(\(tokenAmount) to \(recipient.description) \(cappedMax ? "with" : "without") max on \(network.description))\(executionTypeDescription(executionType))"
            case .quotePay(let payment, let payee, let quoteId, let executionType):
                return
                    "quotePay(\(payment.amount) \(payment.token.symbol) to \(payee.description), quoteId: \(quoteId))\(executionTypeDescription(executionType))"
            case .supplyToAave(
                let tokenAmount,
                let pool,
                let cappedMax,
                let network,
                let executionType
            ):
                return
                    "supplyToAave(\(tokenAmount.amount) \(tokenAmount.token.symbol) to \(pool.description) on \(network.description), cappedMax: \(cappedMax))\(executionTypeDescription(executionType))"
            case .withdrawFromAave(let tokenAmount, let pool, let network, let executionType):
                return
                    "withdrawFromAave(\(tokenAmount.amount) \(tokenAmount.token.symbol) to \(pool.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .supplyToComet(
                let tokenAmount,
                let market,
                let cappedMax,
                let network,
                let executionType
            ):
                return
                    "supplyToComet(\(tokenAmount.amount) \(tokenAmount.token.symbol) to \(market.description) on \(network.description), cappedMax: \(cappedMax))\(executionTypeDescription(executionType))"
            case .supplyMultipleAssetsAndBorrowFromComet(
                let
                    borrowAmount,
                let collateralAmounts,
                let cappedMaxes,
                let market,
                let network,
                let executionType
            ):
                let collateralsString =
                    collateralAmounts.map { collateralAmount in
                        "\(collateralAmount.amount) \(collateralAmount.token.symbol)"
                    }
                    .joined(separator: ",")
                return
                    "supplyMultipleAssetsAndBorrowFromComet(supply [\(collateralsString)] and borrow \(borrowAmount.amount) \(borrowAmount.token.symbol) from \(market.description) on \(network.description), cappedMaxes: \(cappedMaxes))\(executionTypeDescription(executionType))"
            case .repayAndWithdrawMultipleAssetsFromComet(
                let
                    repayAmount,
                let
                    collateralAmounts,
                let
                    market,
                let
                    network,
                let
                    executionType
            ):
                let withdrawString =
                    collateralAmounts.map { collateralAmount in
                        "\(collateralAmount.amount) \(collateralAmount.token.symbol)"
                    }
                    .joined(separator: ",")
                return
                    "repayAndWithdrawMultipleAssetsFromComet(repay \(repayAmount.amount) \(repayAmount.token.symbol), and withdraw [\(withdrawString)] from \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .withdrawFromComet(let tokenAmount, let market, let network, let executionType):
                return
                    "withdrawFromComet(\(tokenAmount.amount) \(tokenAmount.token.symbol) from \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .supplyToMorphoVault(
                let tokenAmount,
                let vault,
                let cappedMax,
                let network,
                let executionType
            ):
                return
                    "supplyToMorphoVault(\(tokenAmount.amount) \(tokenAmount.token.symbol) to \(vault.description) on \(network.description), cappedMax: \(cappedMax))\(executionTypeDescription(executionType))"
            case .withdrawFromMorphoVault(
                let tokenAmount,
                let vault,
                let network,
                let executionType
            ):
                return
                    "withdrawFromMorphoVault(\(tokenAmount.amount) \(tokenAmount.token.symbol) to \(vault.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .swap(
                let filler,
                let sellAmount,
                let buyAmount,
                let feeAmount,
                let feeRecipient,
                let cappedMax,
                let network,
                let executionType
            ):
                return
                    "swap(\(sellAmount.amount) \(sellAmount.token.symbol) for \(buyAmount.amount) \(buyAmount.token.symbol) via \(filler.description) with fee \(feeAmount.amount) \(feeAmount.token.symbol) to \(feeRecipient.description) on \(network.description) \(cappedMax ? "with" : "without") max)\(executionTypeDescription(executionType))"
            case .multicall(let calls, let executionType):
                return
                    "multicall(\(calls.map { $0.description }.joined(separator: ", ")))\(executionTypeDescription(executionType))"
            case .wrapAsset(let token, let executionType):
                return "wrapAsset(\(token.symbol))\(executionTypeDescription(executionType))"
            case .wrapUpTo(let tokenAmount, let executionType):
                return
                    "wrapUpTo(\(tokenAmount.amount) \(tokenAmount.token.symbol))\(executionTypeDescription(executionType))"
            case .unwrapWETHUpTo(let tokenAmount, let executionType):
                return
                    "unwrapWETHUpTo(\(tokenAmount.amount) \(tokenAmount.token.symbol))\(executionTypeDescription(executionType))"
            case .repayAndWithdrawCollateralFromMorpho(
                let
                    repayAmount,
                let collateralAmount,
                let market,
                let network,
                let executionType
            ):
                return
                    "repayAndWithdrawCollateralFromMorpho(repay \(repayAmount.amount) \(repayAmount.token.symbol), withdraw \(collateralAmount.amount) \(collateralAmount.token.symbol) from \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .supplyCollateralAndBorrowFromMorpho(
                let
                    borrowAmount,
                let collateralAmount,
                let cappedMax,
                let market,
                let network,
                let executionType
            ):
                return
                    "supplyCollateralAndBorrowFromMorpho(borrow \(borrowAmount.amount) \(borrowAmount.token.symbol), supply \(collateralAmount.amount) \(collateralAmount.token.symbol) from \(market.description) on \(network.description), cappedMax: \(cappedMax))\(executionTypeDescription(executionType))"
            case .loopLong(
                let
                    exposureAmount,
                let providedBackingAmount,
                let cappedMax,
                let maxSwapBackingAmount,
                let feeAmount,
                let feeRecipient,
                let market,
                let network,
                let
                    executionType
            ):
                return
                    "loopLong(loop \(exposureAmount.amount) \(exposureAmount.token.symbol) of exposure with \(providedBackingAmount.amount) \(providedBackingAmount.token.symbol) (at a max swap price of \(maxSwapBackingAmount.amount)) of backing token \(cappedMax ? "with" : "without") max, fee: \(feeAmount.amount) \(feeAmount.token.symbol) to \(feeRecipient.description), using \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .loopShort(
                let
                    exposureAmount,
                let providedBackingAmount,
                let cappedMax,
                let minSwapBackingAmount,
                let feeAmount,
                let feeRecipient,
                let market,
                let network,
                let
                    executionType
            ):
                return
                    "loopShort(loop \(exposureAmount.amount) \(exposureAmount.token.symbol) of exposure with \(providedBackingAmount.amount) \(providedBackingAmount.token.symbol) (at a min swap price of \(minSwapBackingAmount.amount)) of backing token \(cappedMax ? "with" : "without") max, fee: \(feeAmount.amount) \(feeAmount.token.symbol) to \(feeRecipient.description), using \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .unloopLong(
                let
                    exposureAmount,
                let backingAmountToExit,
                let minSwapBackingAmount,
                let feeAmount,
                let feeRecipient,
                let market,
                let network,
                let
                    executionType
            ):
                return
                    "unloopLong(unloop \(exposureAmount.amount) \(exposureAmount.token.symbol) of exposure and exit \(backingAmountToExit.amount) \(backingAmountToExit.token.symbol) of backing at a min swap price of \(minSwapBackingAmount.amount) \(minSwapBackingAmount.token.symbol) of backing token, fee: \(feeAmount.amount) \(feeAmount.token.symbol) to \(feeRecipient.description), using \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .unloopShort(
                let
                    exposureAmount,
                let backingAmountToExit,
                let maxSwapBackingAmount,
                let feeAmount,
                let feeRecipient,
                let market,
                let network,
                let
                    executionType
            ):
                return
                    "unloopShort(unloop \(exposureAmount.amount) \(exposureAmount.token.symbol) of exposure and exit \(backingAmountToExit.amount) \(backingAmountToExit.token.symbol) of backing at a max swap price of \(maxSwapBackingAmount.amount) \(maxSwapBackingAmount.token.symbol) of backing token, fee: \(feeAmount.amount) \(feeAmount.token.symbol) to \(feeRecipient.description), using \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .addBackingToken(
                let backingAmount,
                let cappedMax,
                let market,
                let isShort,
                let network,
                let executionType
            ):
                return
                    "addBackingToken(add \(backingAmount.amount) \(backingAmount.token.symbol) of backing token \(cappedMax ? "with" : "without") max to \(isShort ? "short" : "long") position on \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .withdrawBackingToken(
                let backingAmount,
                let market,
                let isShort,
                let network,
                let executionType
            ):
                return
                    "withdrawBackingToken(withdraw \(backingAmount.amount) \(backingAmount.token.symbol) of backing token from \(isShort ? "short" : "long") position on \(market.description) on \(network.description))\(executionTypeDescription(executionType))"
            case .bridgeMint(
                let network,
                let bridgeType,
                let executionType
            ):
                return
                    "bridgeMint(mint on \(network.description) via \(bridgeType.displayName))\(executionTypeDescription(executionType))"
            case .unknownFunctionCall(let name, let function, let value):
                return "unknownFunctionCall(\(name), \(function), \(value))"
            case .unknownScriptCall(let scriptSource, let calldata):
                return "unknownScriptCall(\(scriptSource.description), \(calldata.description))"
        }
    }

    var descriptionExt: String {
        switch self {
            case .multicall(let calls, let executionType):
                let executionTypeDescription = executionTypeDescription(executionType)
                let callsDescription = calls.map { "\n\t\t\t- \($0.descriptionExt)" }
                    .joined(
                        separator: "\n"
                    )
                return
                    """
                    multicall\(executionTypeDescription):\n\(callsDescription)\n
                    """
            default:
                return description
        }
    }

    func executionTypeDescription(_ executionType: Charter.Chart.Action.ExecutionType?) -> String {
        return executionType != nil ? " [Execution type: \(executionType!.description)]" : ""
    }
}

extension Array where Element == Call {
    var descriptionExt: String {
        if count == 1 {
            return self[0].descriptionExt
        } else {
            return
                "multi operation:\n\(map { "\n\t\t- \($0.descriptionExt)" }.joined(separator: "\n"))\n"
        }
    }
}

enum Exchange: Hashable, Equatable {
    case zeroEx
    case updatedZeroEx
    case unknownExchange(EthAddress, Hex)

    static let knownCases: [Exchange] = [.zeroEx]

    static let ZERO_EX_ENTRYPOINT = EthAddress("0xDef1C0ded9bec7F1a1670819833240f027b25EfF")
    static let ZERO_EX_SWAP_DATA: Hex = .init(stringLiteral: "0xabcdef")
    static let UPDATED_ZERO_EX_SWAP_DATA: Hex = .init(stringLiteral: "0xdef1")

    var description: String {
        switch self {
            case .zeroEx:
                return "0x"
            case .updatedZeroEx:
                return "Updated 0x"
            case .unknownExchange(let address, let calldata):
                return "Exchange at \(address.description) with calldata \(calldata.description)"
        }
    }

    var entryPoint: EthAddress {
        switch self {
            case .zeroEx, .updatedZeroEx:
                return Exchange.ZERO_EX_ENTRYPOINT
            case .unknownExchange(let address, _):
                return address
        }
    }

    var swapData: Hex {
        switch self {
            case .zeroEx:
                return Exchange.ZERO_EX_SWAP_DATA
            case .updatedZeroEx:
                return Exchange.UPDATED_ZERO_EX_SWAP_DATA
            case .unknownExchange(_, let data):
                return data
        }
    }

    static func from(network: Network, address: EthAddress, data: Hex) -> Exchange {
        switch (network, address, data) {
            case (_, ZERO_EX_ENTRYPOINT, ZERO_EX_SWAP_DATA):
                return .zeroEx
            case (_, ZERO_EX_ENTRYPOINT, UPDATED_ZERO_EX_SWAP_DATA):
                return .updatedZeroEx
            case _:
                return .unknownExchange(address, data)
        }
    }
}

enum Filler: Hashable, Equatable {
    case filler
    case unknownFiller(EthAddress)

    static let FILLER_ADDRESS = EthAddress("0x1c1049ab5ff1b8b5d9f3cbc5320c21c150bfb8b9")

    var description: String {
        switch self {
            case .filler:
                return "Filler"
            case .unknownFiller(let address):
                return "Filler at \(address.description)"
        }
    }

    static func address(network: Network) -> EthAddress {
        switch network {
            case .ethereum, .base, .worldChain, .optimism, .arbitrum, .baseSepolia, .sepolia:
                return FILLER_ADDRESS
            default:
                fatalError("Filler not available on network: \(network.description)")
        }
    }

    static func from(network: Network, address: EthAddress) -> Filler {
        if address == self.address(network: network) {
            return .filler
        } else {
            return .unknownFiller(address)
        }
    }
}

enum LendingMarket: Hashable, Equatable {
    case comet(Comet)
    case morpho(MorphoVault)
    case aave(AavePool)

    var marketType: String {
        switch self {
            case .comet:
                return "COMET"
            case .morpho:
                return "MORPHO"
            case .aave:
                return "AAVE"
        }
    }
}

extension Charter.Chart.Action.ExecutionType {
    var description: String {
        self.rawValue
    }
}

indirect enum When: Sendable {
    case transfer(
        from: TestHelpers.Account,
        to: TestHelpers.Account,
        amount: TokenAmount,
        on: Network
    )
    case aaveSupply(
        from: TestHelpers.Account,
        market: TestHelpers.AavePool,
        amount: TokenAmount,
        on: Network
    )
    case aaveWithdraw(
        from: TestHelpers.Account,
        market: TestHelpers.AavePool,
        amount: TokenAmount,
        on: Network
    )
    case cometBorrow(
        from: TestHelpers.Account,
        market: TestHelpers.Comet,
        borrowAmount: TokenAmount,
        collateralAmounts: [TokenAmount],
        on: Network
    )
    case claimRewards(from: TestHelpers.Account, assetSymbol: String)
    case cometRepay(
        from: TestHelpers.Account,
        market: TestHelpers.Comet,
        repayAmount: TokenAmount,
        collateralAmounts: [TokenAmount],
        on: Network
    )
    case cometSupply(
        from: TestHelpers.Account,
        market: TestHelpers.Comet,
        amount: TokenAmount,
        on: Network
    )
    case cometWithdraw(
        from: TestHelpers.Account,
        market: TestHelpers.Comet,
        amount: TokenAmount,
        on: Network
    )
    case morphoBorrow(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        borrowAmount: TokenAmount,
        collateralAmount: TokenAmount,
        on: Network
    )
    case morphoRepay(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        repayAmount: TokenAmount,
        collateralAmount: TokenAmount,
        on: Network
    )
    case morphoVaultSupply(
        from: TestHelpers.Account,
        vault: TestHelpers.MorphoVault,
        amount: TokenAmount,
        on: Network
    )
    case morphoVaultWithdraw(
        from: TestHelpers.Account,
        vault: TestHelpers.MorphoVault,
        amount: TokenAmount,
        on: Network
    )
    case swap(
        from: TestHelpers.Account,
        sellAmount: TokenAmount,
        buyAmount: TokenAmount,
        swapQuoteSellAmount: TokenAmount,
        swapQuoteBuyAmount: TokenAmount,
        on: Network
    )
    case swapAndSupply(
        swap: (
            from: TestHelpers.Account, sellAmount: TokenAmount, buyAmount: TokenAmount,
            swapQuoteSellAmount: TokenAmount, swapQuoteBuyAmount: TokenAmount, on: Network
        ),
        supply: (from: TestHelpers.Account, market: LendingMarket, amount: TokenAmount, on: Network)
    )
    case compounder(
        claims: [(from: TestHelpers.Account, assetSymbol: String)],
        swaps: [(
            from: TestHelpers.Account, sellAmount: TokenAmount, buyAmount: TokenAmount,
            swapQuoteSellAmount: TokenAmount, swapQuoteBuyAmount: TokenAmount, on: Network
        )],
        supply: (from: TestHelpers.Account, market: LendingMarket, amount: TokenAmount, on: Network)
    )
    case migrateSupplies(
        withdraw: [(
            from: TestHelpers.Account, market: LendingMarket, amount: TokenAmount, on: Network
        )],
        supply: (
            from: TestHelpers.Account, market: LendingMarket, amount: TokenAmount, on: Network
        ),
        migrateOnlySupplyBalances: Bool
    )
    case loopLong(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        exposureAmount: TokenAmount,
        providedBackingAmount: TokenAmount,
        maxSwapBackingAmount: TokenAmount,
        on: Network
    )
    case loopShort(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        exposureAmount: TokenAmount,
        providedBackingAmount: TokenAmount,
        minSwapBackingAmount: TokenAmount,
        on: Network
    )
    case unloopLong(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        exposureAmount: TokenAmount,
        backingAmountToExit: TokenAmount,
        minSwapBackingAmount: TokenAmount,
        on: Network
    )
    case unloopShort(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        exposureAmount: TokenAmount,
        backingAmountToExit: TokenAmount,
        maxSwapBackingAmount: TokenAmount,
        on: Network
    )
    case addBackingToken(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        exposureToken: TestHelpers.Token,
        backingAmount: TokenAmount,
        isShort: Bool,
        on: Network
    )
    case withdrawBackingToken(
        from: TestHelpers.Account,
        morpho: TestHelpers.Morpho,
        exposureToken: TestHelpers.Token,
        backingAmount: TokenAmount,
        isShort: Bool,
        on: Network
    )
    case swapV2(
        from: TestHelpers.Account,
        sellAssetSymbol: String,
        buyAssetSymbol: String,
        sellAmount: Number,
        isBuy: Bool = true
    )
    case payWith(currency: TestHelpers.Token, When)

    var sender: TestHelpers.Account {
        switch self {
            case .transfer(let from, _, _, _):
                return from
            case .aaveSupply(let from, _, _, _):
                return from
            case .aaveWithdraw(let from, _, _, _):
                return from
            case .cometSupply(let from, _, _, _):
                return from
            case .cometBorrow(let from, _, _, _, _):
                return from
            case .claimRewards(let from, _):
                return from
            case .cometRepay(let from, _, _, _, _):
                return from
            case .cometWithdraw(let from, _, _, _):
                return from
            case .morphoBorrow(let from, _, _, _, _):
                return from
            case .morphoRepay(let from, _, _, _, _):
                return from
            case .morphoVaultSupply(let from, _, _, _):
                return from
            case .morphoVaultWithdraw(let from, _, _, _):
                return from
            case .swap(let from, _, _, _, _, _):
                return from
            case .swapAndSupply(let swapIntent, _):
                return swapIntent.from
            case .compounder(let claims, let swaps, let supply):
                return claims.first?.from ?? swaps.first?.from ?? supply.from
            case .migrateSupplies(_, let supplyIntent, _):
                return supplyIntent.from
            case .loopLong(let from, _, _, _, _, _):
                return from
            case .loopShort(let from, _, _, _, _, _):
                return from
            case .unloopLong(let from, _, _, _, _, _):
                return from
            case .unloopShort(let from, _, _, _, _, _):
                return from
            case .addBackingToken(let from, _, _, _, _, _):
                return from
            case .withdrawBackingToken(let from, _, _, _, _, _):
                return from
            case .swapV2(let from, _, _, _, _):
                return from
            case .payWith(_, let action):
                return action.sender
        }
    }
}

enum CallExpect {
    case single(Call)
    case multi([Call])

    var expectedCalls: [Call] {
        switch self {
            case .single(let expectedCall):
                [expectedCall]
            case .multi(let expectedCalls):
                expectedCalls
        }
    }
}

enum Expect {
    case failure(Charter.CharterError)
    case success(CallExpect)
    case successWithActions(CallExpect, [Charter.ActionContext]?)
}

final class AcceptanceTest: Sendable {
    let given: [Given]
    let when: When
    let expect: Expect

    init(
        given: [Given],
        when: When,
        expect: Expect
    ) {
        self.given = given
        self.when = when
        self.expect = expect
    }
}

class Context {
    let sender: TestHelpers.Account
    let given: [Given]
    var paymentToken: TestHelpers.Token?

    // Store Tradewinds data for visualization
    var lastFlowResult: Tradewinds.FlowResult<TradewindsLegendNode, LegendRouteType>?
    var lastRoutes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]?
    var lastResources: [Tradewinds.Resource<TradewindsLegendNode>]?
    var lastTarget: Tradewinds.Target<TradewindsLegendNode>?

    init(sender: TestHelpers.Account, given: [Given]) {
        self.sender = sender
        self.given = given
        paymentToken = .none
    }

    func when(_ when: When) async throws -> Result<
        ([Call], [Charter.ActionContext]), Charter.CharterError
    > {
        func runMercatorIntent(_ intent: Charter.QuarkIntent) throws -> Result<
            ([Call], [Charter.ActionContext]), Charter.CharterError
        > {
            // Add default prices first, then user-provided givens (which can override)
            let defaultPrices = Given.prices(
                Dictionary(
                    uniqueKeysWithValues: Token.knownCases.map { token in
                        (token, token.defaultUsdPrice)
                    }
                )
            )
            let allGivens = [defaultPrices] + given
            let folio = generateFolio(from: allGivens)

            let chartResult = Charter.chartExtended(
                intent: intent,
                folio: folio,
                logger: nil
            )

            // Store Tradewinds data for visualization (available whether success or failure)
            self.lastFlowResult = chartResult.flowResult
            self.lastRoutes = chartResult.routes
            self.lastResources = chartResult.resources
            self.lastTarget = chartResult.target

            if ProcessInfo.processInfo.environment["VIZ"] == "1" {
                print("[VIZ] Storing Tradewinds data from chartExtended")
                print("[VIZ] Routes count: \(chartResult.routes?.count ?? 0)")
                print("[VIZ] Resources count: \(chartResult.resources?.count ?? 0)")
                print("[VIZ] Has flowResult: \(chartResult.flowResult != nil)")
            }

            let result = chartResultToCallsAndActions(chartResult)

            // Return just the calls and action contexts for compatibility
            switch result {
                case .success((let calls, let actionContexts, _, _, _, _)):
                    return .success((calls, actionContexts))
                case .failure(let error):
                    if ProcessInfo.processInfo.environment["VIZ"] == "1" {
                        print("[VIZ] Charter failed with error: \(error)")
                    }
                    return .failure(error)
            }
        }

        switch when {
            case .payWith(let token, let intent):
                paymentToken = token
                return try await self.when(intent)
            case .aaveSupply(let from, let pool, let amount, let network):
                return try runMercatorIntent(
                    .init(
                        type: .aaveSupply(
                            .init(
                                amount: Number(amount.amount),
                                assetSymbol: amount.token.symbol,
                                chainId: Number(network.chainId),
                                aavePool: pool.address(network: network),
                                sender: from.address,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .aaveWithdraw(let from, let pool, let amount, let network):
                return try runMercatorIntent(
                    .init(
                        type: .aaveWithdraw(
                            .init(
                                amount: Number(amount.amount),
                                assetSymbol: amount.token.symbol,
                                chainId: Number(network.chainId),
                                aavePool: pool.address(network: network),
                                withdrawer: from.address,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .cometBorrow(
                let from,
                let market,
                let borrowAmount,
                let collateralAmounts,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .cometBorrow(
                            .init(
                                amount: Number(borrowAmount.amount),
                                assetSymbol: borrowAmount.token.symbol,
                                borrower: from.address,
                                chainId: Number(network.chainId),
                                collateralAmount: collateralAmounts.first.map { Number($0.amount) } ?? .zero,
                                collateralAssetSymbol: collateralAmounts.first?.token.symbol ?? "",
                                comet: market.address(network: network),
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .claimRewards(let from, let assetSymbol):
                return try runMercatorIntent(
                    .init(
                        type: .claimRewards(
                            .init(
                                claimer: from.address,
                                assetSymbol: assetSymbol
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .cometRepay(
                let from,
                let market,
                let repayAmount,
                let collateralAmounts,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .cometRepay(
                            .init(
                                amount: repayAmount.amount,
                                assetSymbol: repayAmount.token.symbol,
                                chainId: Number(network.chainId),
                                collateralAmount: collateralAmounts.first?.amount ?? .zero,
                                collateralAssetSymbol: collateralAmounts.first?.token.symbol ?? "",
                                comet: market.address(network: network),
                                repayer: from.address,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .cometSupply(let from, let market, let amount, let network):
                return try runMercatorIntent(
                    .init(
                        type: .cometSupply(
                            .init(
                                amount: Number(amount.amount),
                                assetSymbol: amount.token.symbol,
                                chainId: Number(network.chainId),
                                comet: market.address(network: network),
                                sender: from.address,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .cometWithdraw(let from, let market, let amount, let network):
                return try runMercatorIntent(
                    .init(
                        type: .cometWithdraw(
                            .init(
                                amount: Number(amount.amount),
                                assetSymbol: amount.token.symbol,
                                chainId: Number(network.chainId),
                                comet: market.address(network: network),
                                withdrawer: from.address,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .morphoBorrow(
                let from,
                let morpho,
                let borrowAmount,
                let collateralAmount,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .morphoBorrow(
                            .init(
                                amount: borrowAmount.amount,
                                assetSymbol: borrowAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                borrower: from.address,
                                chainId: network.chainId,
                                collateralAmount: collateralAmount.amount,
                                collateralAssetSymbol: collateralAmount.token.symbol,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .morphoRepay(
                let from,
                let morpho,
                let repayAmount,
                let collateralAmount,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .morphoRepay(
                            .init(
                                amount: repayAmount.amount,
                                assetSymbol: repayAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                repayer: from.address,
                                chainId: network.chainId,
                                collateralAmount: collateralAmount.amount,
                                collateralAssetSymbol: collateralAmount.token.symbol,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .morphoVaultSupply(let from, let vault, let amount, let network):
                return try runMercatorIntent(
                    .init(
                        type: .morphoVaultSupply(
                            .init(
                                amount: amount.amount,
                                assetSymbol: amount.token.symbol,
                                morphoVault: vault.address(network: network),
                                sender: from.address,
                                chainId: network.chainId,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .morphoVaultWithdraw(let from, let vault, let amount, let network):
                return try runMercatorIntent(
                    .init(
                        type: .morphoVaultWithdraw(
                            .init(
                                amount: Number(amount.amount),
                                assetSymbol: amount.token.symbol,
                                morphoVault: vault.address(network: network),
                                chainId: Number(network.chainId),
                                withdrawer: from.address,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .transfer(let from, let to, let amount, let network):
                return try runMercatorIntent(
                    .init(
                        type: .transfer(
                            .init(
                                chainId: Number(network.chainId),
                                assetSymbol: amount.token.symbol,
                                amount: Number(amount.amount),
                                sender: from.address,
                                recipient: to.address,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .swap(
                let
                    from,
                let sellAmount,
                let buyAmount,
                let swapQuoteSellAmount,
                let swapQuoteBuyAmount,
                let network
            ):
                guard let sellToken = sellAmount.token.address(network: network),
                    let buyToken = buyAmount.token.address(network: network)
                else {
                    fatalError("Cannot swap unknown token")
                }

                return try runMercatorIntent(
                    .init(
                        type: .swap(
                            .init(
                                chainId: network.chainId,
                                sellToken: sellToken,
                                sellAmount: sellAmount.amount,
                                buyToken: buyToken,
                                buyAmount: buyAmount.amount,
                                swapQuoteSellAmount: swapQuoteSellAmount.amount,
                                swapQuoteBuyAmount: swapQuoteBuyAmount.amount,
                                feeToken: buyToken,
                                feeAmount: buyAmount.amount / Number(100),
                                sender: from.address,
                                isExactOut: false,
                                isBuy: true,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .swapV2(let from, let sellAssetSymbol, let buyAssetSymbol, let sellAmount, let isBuy):
                return try runMercatorIntent(
                    .init(
                        type: .swapV2(
                            Charter.SwapIntentV2(
                                sellAssetSymbol: sellAssetSymbol,
                                buyAssetSymbol: buyAssetSymbol,
                                sellAmount: sellAmount,
                                sender: from.address,
                                isBuy: isBuy
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .swapAndSupply(let swap, let supply):
                guard let sellToken = swap.sellAmount.token.address(network: swap.on),
                    let buyToken = swap.buyAmount.token.address(network: swap.on)
                else {
                    fatalError("Cannot swap unknown token")
                }

                let swapIntent: Charter.SwapIntent = .init(
                    chainId: Number(swap.on.chainId),
                    sellToken: sellToken,
                    sellAmount: Number(swap.sellAmount.amount),
                    buyToken: buyToken,
                    buyAmount: Number(swap.buyAmount.amount),
                    swapQuoteSellAmount: Number(swap.swapQuoteSellAmount.amount),
                    swapQuoteBuyAmount: Number(swap.swapQuoteBuyAmount.amount),
                    feeToken: buyToken,
                    feeAmount: Number(swap.buyAmount.amount / Number(100)),
                    sender: swap.from.address,
                    isExactOut: false,
                    isBuy: true
                )

                let supplyIntent: Charter.SupplyIntent
                switch supply.market {
                    case .comet(let cometMarket):
                        supplyIntent = .comet(
                            Charter.CometSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                chainId: Number(supply.on.chainId),
                                comet: cometMarket.address(network: supply.on),
                                sender: supply.from.address
                            )
                        )

                    case .morpho(let morphoVault):
                        supplyIntent = .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                morphoVault: morphoVault.address(network: supply.on),
                                sender: supply.from.address,
                                chainId: Number(supply.on.chainId)
                            )
                        )

                    case .aave(let aavePool):
                        supplyIntent = .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                chainId: Number(supply.on.chainId),
                                aavePool: aavePool.address(network: supply.on),
                                sender: supply.from.address
                            )
                        )
                }

                return try runMercatorIntent(
                    .init(
                        type: .swapAndSupply(
                            .init(
                                swapIntent: swapIntent,
                                supplyIntent: supplyIntent
                            ),
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .compounder(let claims, let swaps, let supply):
                let claimIntents = claims.map { claim in
                    Charter.ClaimRewardsIntent(
                        claimer: claim.from.address,
                        assetSymbol: claim.assetSymbol
                    )
                }

                let swapIntents = swaps.map { swap -> Charter.SwapIntent in
                    guard let sellToken = swap.sellAmount.token.address(network: swap.on),
                        let buyToken = swap.buyAmount.token.address(network: swap.on)
                    else {
                        fatalError("Cannot swap unknown token")
                    }

                    return Charter.SwapIntent(
                        chainId: Number(swap.on.chainId),
                        sellToken: sellToken,
                        sellAmount: Number(swap.sellAmount.amount),
                        buyToken: buyToken,
                        buyAmount: Number(swap.buyAmount.amount),
                        swapQuoteSellAmount: Number(swap.swapQuoteSellAmount.amount),
                        swapQuoteBuyAmount: Number(swap.swapQuoteBuyAmount.amount),
                        feeToken: buyToken,
                        feeAmount: Number(swap.buyAmount.amount / Number(100)),
                        sender: swap.from.address,
                        isExactOut: false,
                        isBuy: true
                    )
                }

                let supplyIntent: Charter.SupplyIntent
                switch supply.market {
                    case .comet(let cometMarket):
                        supplyIntent = .comet(
                            Charter.CometSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                chainId: Number(supply.on.chainId),
                                comet: cometMarket.address(network: supply.on),
                                sender: supply.from.address
                            )
                        )

                    case .morpho(let morphoVault):
                        supplyIntent = .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                morphoVault: morphoVault.address(network: supply.on),
                                sender: supply.from.address,
                                chainId: Number(supply.on.chainId)
                            )
                        )

                    case .aave(let aavePool):
                        supplyIntent = .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                chainId: Number(supply.on.chainId),
                                aavePool: aavePool.address(network: supply.on),
                                sender: supply.from.address
                            )
                        )
                }

                return try runMercatorIntent(
                    .init(
                        type: .compounder(
                            .init(
                                claimRewardsIntents: claimIntents,
                                swapIntents: swapIntents,
                                supplyIntent: supplyIntent
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .migrateSupplies(let withdraws, let supply, let migrateOnlySupplyBalances):
                let withdrawIntents = withdraws.map {
                    (
                        from: TestHelpers.Account,
                        market: LendingMarket,
                        amount: TestHelpers.TokenAmount,
                        on: Network
                    ) in
                    switch market {
                        case .comet(let cometMarket):
                            return Charter.WithdrawIntent.comet(
                                Charter.CometWithdrawIntent(
                                    amount: Number(amount.amount),
                                    assetSymbol: amount.token.symbol,
                                    chainId: Number(on.chainId),
                                    comet: cometMarket.address(network: on),
                                    withdrawer: from.address
                                )
                            )

                        case .morpho(let morphoVault):
                            return Charter.WithdrawIntent.morpho(
                                Charter.MorphoVaultWithdrawIntent(
                                    amount: Number(amount.amount),
                                    assetSymbol: amount.token.symbol,
                                    morphoVault: morphoVault.address(network: on),
                                    chainId: Number(on.chainId),
                                    withdrawer: from.address
                                )
                            )

                        case .aave(let aavePool):
                            return Charter.WithdrawIntent.aave(
                                Charter.AaveWithdrawIntent(
                                    amount: Number(amount.amount),
                                    assetSymbol: amount.token.symbol,
                                    chainId: Number(on.chainId),
                                    aavePool: aavePool.address(network: on),
                                    withdrawer: from.address
                                )
                            )
                    }
                }

                let supplyIntent: Charter.SupplyIntent
                switch supply.market {
                    case .comet(let cometMarket):
                        supplyIntent = .comet(
                            Charter.CometSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                chainId: Number(supply.on.chainId),
                                comet: cometMarket.address(network: supply.on),
                                sender: supply.from.address
                            )
                        )

                    case .morpho(let morphovault):
                        supplyIntent = .morpho(
                            Charter.MorphoVaultSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                morphoVault: morphovault.address(network: supply.on),
                                sender: supply.from.address,
                                chainId: Number(supply.on.chainId)
                            )
                        )

                    case .aave(let aavePool):
                        supplyIntent = .aave(
                            Charter.AaveSupplyIntent(
                                amount: Number(supply.amount.amount),
                                assetSymbol: supply.amount.token.symbol,
                                chainId: Number(supply.on.chainId),
                                aavePool: aavePool.address(network: supply.on),
                                sender: supply.from.address
                            )
                        )
                }

                return try runMercatorIntent(
                    .init(
                        type: .migrateSupplies(
                            .init(
                                withdrawIntents: withdrawIntents,
                                supplyIntent: supplyIntent,
                                migrateOnlySupplyBalances: migrateOnlySupplyBalances
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .loopLong(
                let
                    from,
                let morpho,
                let exposureAmount,
                let providedBackingAmount,
                let maxSwapBackingAmount,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .loopLong(
                            .init(
                                exposureAssetSymbol: exposureAmount.token.symbol,
                                backingAssetSymbol: providedBackingAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                isIncrease: false,
                                exposureAmount: Number(exposureAmount.amount),
                                maxSwapBackingAmount: Number(maxSwapBackingAmount.amount),
                                maxProvidedBackingAmount: Number(providedBackingAmount.amount),
                                poolFee: 500,
                                sender: from.address,
                                chainId: network.chainId,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .loopShort(
                let
                    from,
                let morpho,
                let exposureAmount,
                let providedBackingAmount,
                let minSwapBackingAmount,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .loopShort(
                            .init(
                                exposureAssetSymbol: exposureAmount.token.symbol,
                                backingAssetSymbol: providedBackingAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                isIncrease: false,
                                exposureAmount: exposureAmount.amount,
                                minSwapBackingAmount: minSwapBackingAmount.amount,
                                providedBackingAmount: providedBackingAmount.amount,
                                poolFee: 500,
                                sender: from.address,
                                chainId: network.chainId,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .unloopLong(
                let
                    from,
                let morpho,
                let exposureAmount,
                let backingAmountToExit,
                let minSwapBackingAmount,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .unloopLong(
                            .init(
                                exposureAssetSymbol: exposureAmount.token.symbol,
                                backingAssetSymbol: minSwapBackingAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                exposureAmount: exposureAmount.amount,
                                backingAmountToExit: backingAmountToExit.amount,
                                minSwapBackingAmount: minSwapBackingAmount.amount,
                                poolFee: 500,
                                sender: from.address,
                                chainId: network.chainId,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .unloopShort(
                let
                    from,
                let morpho,
                let exposureAmount,
                let backingAmountToExit,
                let maxSwapBackingAmount,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .unloopShort(
                            .init(
                                exposureAssetSymbol: exposureAmount.token.symbol,
                                backingAssetSymbol: maxSwapBackingAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                exposureAmount: exposureAmount.amount,
                                backingAmountToExit: backingAmountToExit.amount,
                                maxSwapBackingAmount: maxSwapBackingAmount.amount,
                                poolFee: 500,
                                sender: from.address,
                                chainId: network.chainId,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .addBackingToken(
                let from,
                let morpho,
                let exposureToken,
                let backingAmount,
                let isShort,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .addBackingToken(
                            .init(
                                exposureAssetSymbol: exposureToken.symbol,
                                backingAssetSymbol: backingAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                amount: backingAmount.amount,
                                isShort: isShort,
                                sender: from.address,
                                chainId: network.chainId,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
            case .withdrawBackingToken(
                let from,
                let morpho,
                let exposureToken,
                let backingAmount,
                let isShort,
                let network
            ):
                return try runMercatorIntent(
                    .init(
                        type: .withdrawBackingToken(
                            .init(
                                exposureAssetSymbol: exposureToken.symbol,
                                backingAssetSymbol: backingAmount.token.symbol,
                                marketId: morpho.marketId(network),
                                amount: backingAmount.amount,
                                isShort: isShort,
                                sender: from.address,
                                chainId: network.chainId,
                            )
                        ),
                        blockTimestamp: Number(1_000_000)
                    )
                )
        }
    }
}

enum ANSIColor: String {
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case reset = "\u{001B}[0m"
}

func colorize(_ text: String, with color: ANSIColor) -> String {
    if useColor {
        return "\(color.rawValue)\(text)\(ANSIColor.reset.rawValue)"
    } else {
        return text
    }
}

func customFatalError(_ message: String, file: String = #file, line: Int = #line) -> Never {
    print("Error: \(message)")
    print("Location: \(file):\(line)")
    print("Stack trace:")
    Thread.callStackSymbols.forEach { print($0) }
    fatalError(message)
}

func chartResultToCallsAndActions(
    _ chartResult: (
        result: Result<Charter.Chart, Charter.CharterError>,
        flowResult: Tradewinds.FlowResult<TradewindsLegendNode, LegendRouteType>?,
        routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]?,
        resources: [Tradewinds.Resource<TradewindsLegendNode>]?,
        target: Tradewinds.Target<TradewindsLegendNode>?
    )
)
    -> Result<
        (
            calls: [Call],
            actionContexts: [Charter.ActionContext],
            flowResult: Tradewinds.FlowResult<TradewindsLegendNode, LegendRouteType>?,
            routes: [Tradewinds.Route<TradewindsLegendNode, LegendRouteType>]?,
            resources: [Tradewinds.Resource<TradewindsLegendNode>]?,
            target: Tradewinds.Target<TradewindsLegendNode>?
        ), Charter.CharterError
    >
{
    switch chartResult.result {
        case .success(let chart):
            let (calls, actionContexts) = chartToCallsAndActions(chart)
            return .success(
                (
                    calls: calls,
                    actionContexts: actionContexts,
                    flowResult: chartResult.flowResult,
                    routes: chartResult.routes,
                    resources: chartResult.resources,
                    target: chartResult.target
                )
            )
        case .failure(let charterError):
            return .failure(charterError)
    }
}

func chartToCallsAndActions(_ chart: Charter.Chart) -> ([Call], [Charter.ActionContext]) {
    let calls: [Call] = chart.quarkOperationActions.map { quarkOperationAction in
        Call.tryDecodeCall(
            scriptAddress: quarkOperationAction.operation.scriptAddress,
            calldata: quarkOperationAction.operation.scriptCalldata,
            network: Network.fromChainId(quarkOperationAction.action.chainId),
            executionType: quarkOperationAction.action.executionType
        )
    }

    let actionContexts = chart.quarkOperationActions.map { $0.action.actionContext }

    return (calls, actionContexts)
}

extension EthAddress: CustomDebugStringConvertible {
    public var debugDescription: String { "EthAddress(\"\(address.description)\")" }
}

extension Hex: CustomDebugStringConvertible {
    public var debugDescription: String { "Hex(\"\(description)\")" }
}

func showActionContexts(_ actionContexts: [Charter.ActionContext]?) -> String {
    if let actionContexts = actionContexts {
        actionContexts.map { String(describing: $0) }.joined(separator: "\n")
            .replacingOccurrences(
                of: "Mercator.Mercator",
                with: "Mercator"
            )
    } else {
        "nil actionContexts"
    }
}

// MARK: - Visualization Support

private func generateAcceptanceTestVisualization(
    test: AcceptanceTest,
    context: Context,
    result: Result<([Call], [Charter.ActionContext]), Charter.CharterError>? = nil,
    suffix: String
) {
    guard let routes = context.lastRoutes,
        let resources = context.lastResources,
        let target = context.lastTarget
    else {
        return
    }

    let flows: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>]? =
        result != nil ? context.lastFlowResult?.flows : nil

    generateAcceptanceTestVisualization(
        routes: routes,
        resources: resources,
        flows: flows,
        target: target,
        suffix: suffix
    )
}

private func generateCombinedVisualization(
    test: AcceptanceTest,
    context: Context,
    expectedFlows: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>],
    actualFlows: [Tradewinds.Flow<TradewindsLegendNode, LegendRouteType>]
) {
    guard let routes = context.lastRoutes,
        let resources = context.lastResources,
        let target = context.lastTarget
    else {
        return
    }

    generateAcceptanceTestCombinedVisualization(
        routes: routes,
        resources: resources,
        expectedFlows: expectedFlows,
        actualFlows: actualFlows,
        target: target
    )
}

func testAcceptanceTests(test: AcceptanceTest) async throws {
    // Check if VIZ=1 is set for visualization
    let shouldVisualize = ProcessInfo.processInfo.environment["VIZ"] == "1"

    let context = Context(sender: test.when.sender, given: test.given)

    let result: Result<([Call], [Charter.ActionContext]), Charter.CharterError>
    do {
        result = try await context.when(test.when)

        // Generate visualizations if enabled
        if shouldVisualize {
            print("[VIZ] shouldVisualize = true")
            print("[VIZ] context.lastRoutes = \(context.lastRoutes != nil ? "present" : "nil")")
            print(
                "[VIZ] context.lastResources = \(context.lastResources != nil ? "present" : "nil")"
            )
            print("[VIZ] context.lastTarget = \(context.lastTarget != nil ? "present" : "nil")")

            if context.lastRoutes != nil {
                // 1. Setup visualization (no flows)
                generateAcceptanceTestVisualization(
                    test: test,
                    context: context,
                    result: nil,
                    suffix: "1_setup"
                )

                // 2. Solution visualization (with flows if successful)
                switch result {
                    case .success:
                        generateAcceptanceTestVisualization(
                            test: test,
                            context: context,
                            result: result,
                            suffix: "2_solution"
                        )
                    case .failure:
                        // For failures, still show the setup but no solution
                        print("[VIZ] Result was failure, showing setup only")
                        break
                }
            } else {
                print("[VIZ] No routes available for visualization")
            }
        }
    }

    let expect: Result<([Call], [Charter.ActionContext]?), Charter.CharterError> =
        switch test.expect {
            case .success(let callExpect):
                .success((callExpect.expectedCalls, nil))
            case .successWithActions(let callExpect, let actionContexts):
                .success((callExpect.expectedCalls, actionContexts))
            case .failure(let charterError):
                .failure(charterError)
        }

    switch (expect, result) {
        case (.failure(let expectedError), .failure(let actualError)):
            #expect(
                actualError == expectedError,
                "\n\(colorize("Expected Revert:", with: .yellow))\n\t\(colorize(String(describing: expectedError), with: .reset))\n\n\n\(colorize("Mercator Result:", with: .yellow))\n\t\(colorize(String(describing: actualError), with: .reset))\n\n"
            )
        case (.failure(let expectedRevertReason), .success((let calls, let actionContexts))):
            #expect(
                Bool(false),
                "\n\(colorize("Expected Revert:", with: .yellow))\n\t\(colorize(String(describing: expectedRevertReason), with: .reset))\n\n\n\(colorize("Mercator Result:", with: .yellow))\n\t\(calls.descriptionExt)\n\n\t\(showActionContexts(actionContexts))\n\n"
            )
        case (.success((let expectedCalls, let actionContexts)), .failure(let revertReason)):
            #expect(
                Bool(false),
                "\n\(colorize("Expected Result:", with: .yellow))\n\t\(expectedCalls.description)\n\n\t\(showActionContexts(actionContexts))\n\n\n\(colorize("Mercator Result:", with: .yellow))\n\t\(colorize(String(describing: revertReason), with: .reset))\n\n"
            )
        case (
            .success((let expectedCalls, let expectedActionContexts)),
            .success((let calls, let actionContexts))
        ):
            // #expect(builderResult.eip712Data.domainSeparator == EIP712Helper.DomainSeparator(name: "Quark", version: "1")) // TODO: Check domain separator?
            // #expect(builderResult.paymentCurrency == "USDC") // TODO: Check payment currency?
            #expect(
                expectedCalls == calls,
                "\n\(colorize("Expected Calls:", with: .yellow))\n\t\(expectedCalls.descriptionExt)\n\n\n\(colorize("Mercator Calls:", with: .yellow))\n\t\(calls.descriptionExt)\n\n"
            )

            if let expectedActionContexts {
                #expect(
                    expectedActionContexts == actionContexts,
                    "\n\(colorize("Expected Action Contexts:", with: .yellow))\n\t\(showActionContexts(expectedActionContexts))\n\n\n\(colorize("Mercator Action Contexts:", with: .yellow))\n\t\(showActionContexts(actionContexts))\n\n"
                )
            }
        case _:
            fatalError("Unexpected case")
    }
}
