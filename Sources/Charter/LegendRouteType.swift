import Atlas
import Eth
import Prelude
import SwiftNumber
import Tradewinds

// Fee type enum for annotated fees
public enum LegendFeeType: String, Hashable, Sendable {
    case bridge = "bridge"
    case quotePay = "quotePay"
}

// Main function accepting fees array
public func makeLegendRoute(
    type: LegendRouteType,
    source: TradewindsLegendNode,
    sink: TradewindsLegendNode,
    rate: Percentage,
    fees: [Tradewinds.Fee<LegendFeeType>] = [],
    minFlow: Number,
    maxFlow: Number,
    folio: Folio,
    logger: Charter.Logger? = nil
) -> Tradewinds.Route<TradewindsLegendNode, LegendRouteType> {
    // Start with provided fees
    var allFees = fees

    // Add QuotePay fees based on operation source.
    //
    // Operations FROM wallet (deposits, bridges): isInFee=true
    //   - Tradewinds adds fee to flow amounts during backward calculation
    //   - amountLessInFee subtracts it when constructing operations
    //   - User pays operation amount + fee from wallet
    //
    // Operations FROM markets (withdrawals): isInFee=false (outFee)
    //   - Fee NOT added to flows; market provides exact amount
    //   - Fee paid separately from wallet in subsequent quotePay
    //
    // Check source BEFORE sink (important for bridges where both are tokenBalance).
    // This ensures bridges correctly apply inFee at source.
    if case .tokenBalance = source {
        // Deposit/Bridge pattern: fee is paid from wallet along with operation
        if let sourceSymbol = source.symbol,
            let sourceNetwork = source.network,
            let sourceQuoteCost = folio.quoteCost(
                routeType: type,
                symbol: sourceSymbol,
                network: sourceNetwork
            ),
            sourceQuoteCost > .zero
        {
            allFees.append(Tradewinds.Fee(type: .quotePay, isInFee: true, amount: sourceQuoteCost))
        }
    } else if case .tokenBalance = sink {
        // Withdrawal pattern: fee is paid from wallet after withdrawal
        if let sinkSymbol = sink.symbol,
            let sinkNetwork = sink.network,
            let sinkQuoteCost = folio.quoteCost(
                routeType: type,
                symbol: sinkSymbol,
                network: sinkNetwork
            ),
            sinkQuoteCost > .zero
        {
            allFees.append(Tradewinds.Fee(type: .quotePay, isInFee: false, amount: sinkQuoteCost))
        }
    }

    return Tradewinds.Route<TradewindsLegendNode, LegendRouteType>(
        type: type,
        source: source,
        sink: sink,
        rate: rate,
        fees: allFees,
        minFlow: minFlow,
        maxFlow: maxFlow
    )
}

public enum LegendRouteType: Hashable, Comparable, CustomStringConvertible, RouteIdentifiable, Sendable {
    case tokenTransfer
    case transferOut
    case bridge(isCappedMax: Bool)
    case wrap
    case unwrap
    case aaveSupply(isCappedMax: Bool)
    case aaveWithdraw(isMax: Bool)
    case cometSupply(isCappedMax: Bool)
    case cometWithdraw(isMax: Bool)
    case cometSupplyCollateral(isCappedMax: Bool)
    case cometBorrow(asset: EthAddress, amount: Number)
    case cometSupplyCollateralAndBorrow(borrowAsset: EthAddress, borrowAmount: Number, isCappedMaxSupply: Bool)
    case cometRepay(isMax: Bool)
    case cometWithdrawCollateral(isMax: Bool)
    case cometRepayAndWithdrawCollateral(collateralAsset: EthAddress, collateralAmount: Number, isMaxRepay: Bool)
    case morphoSupplyCollateral(isCappedMax: Bool)
    case morphoBorrow(asset: EthAddress, amount: Number)
    case morphoSupplyCollateralAndBorrow(borrowAsset: EthAddress, borrowAmount: Number, isCappedMaxSupply: Bool)
    case morphoRepay(isMax: Bool)
    case morphoWithdrawCollateral(isMax: Bool)
    case morphoRepayAndWithdrawCollateral(collateralAsset: EthAddress, collateralAmount: Number, isMaxRepay: Bool)
    case morphoVaultSupply(isCappedMax: Bool)
    case morphoVaultWithdraw(isMax: Bool)
    case swap(
        buyToken: EthAddress,
        buyAmount: Number,
        swapQuoteSellAmount: Number,
        swapQuoteBuyAmount: Number,
        feeToken: EthAddress,
        feeAmount: Number,
        isExactOut: Bool,
        isBuy: Bool,
        isCappedMax: Bool
    )
    case loopLong(
        marketId: Hex,
        exposureAsset: EthAddress,
        exposureAssetSymbol: String,
        exposureAmount: Number,
        maxSwapBackingAmount: Number,
        maxProvidedBackingAmount: Number,
        poolFee: UInt,
        isIncrease: Bool
    )
    case loopShort(
        marketId: Hex,
        exposureAsset: EthAddress,
        exposureAssetSymbol: String,
        exposureAmount: Number,
        minSwapBackingAmount: Number,
        providedBackingAmount: Number,
        poolFee: UInt,
        isIncrease: Bool
    )
    case unloopLong(
        marketId: Hex,
        exposureAsset: EthAddress,
        exposureAssetSymbol: String,
        exposureAmount: Number,
        backingAmountToExit: Number,
        minSwapBackingAmount: Number,
        poolFee: UInt
    )
    case unloopShort(
        marketId: Hex,
        exposureAsset: EthAddress,
        exposureAssetSymbol: String,
        exposureAmount: Number,
        backingAmountToExit: Number,
        maxSwapBackingAmount: Number,
        poolFee: UInt
    )
    case addBackingToken(
        marketId: Hex,
        exposureAsset: EthAddress,
        exposureAssetSymbol: String,
        amount: Number,
        isShort: Bool
    )
    case withdrawBackingToken(
        marketId: Hex,
        exposureAsset: EthAddress,
        exposureAssetSymbol: String,
        amount: Number,
        isShort: Bool
    )
    case morphoClaimRewards(
        distributors: [EthAddress],
        rewards: [EthAddress],
        claimables: [Number],
        claimableNows: [Number],
        proofs: [[Hex]],
        symbols: [String],
        prices: [Number]
    )
    case cometClaimRewards(
        cometRewards: [EthAddress],
        comets: [EthAddress],
        amounts: [Number],
        symbols: [String],
        prices: [Number],
        tokens: [EthAddress]
    )
    // Virtual route type for Tradewinds flow optimization.
    // Represents the no-op flow from TokenBalance nodes to the RewardSettlement aggregation point.
    // This enables multi-token reward claiming within Tradewinds' single-commodity constraints.
    case rewardSettlement

    public var description: String {
        switch self {
            case .tokenTransfer: return "ERC20 Transfer"
            case .transferOut: return "ERC20 Transfer [External]"
            case .bridge: return "Bridge"
            case .wrap: return "Wrap"
            case .unwrap: return "Unwrap"
            case .aaveSupply: return "Aave Supply"
            case .aaveWithdraw: return "Aave Withdraw"
            case .cometSupply: return "Comet Supply"
            case .cometWithdraw: return "Comet Withdraw"
            case .cometSupplyCollateral: return "Comet Supply Collateral"
            case .cometBorrow: return "Comet Borrow"
            case .cometSupplyCollateralAndBorrow: return "Comet Supply Collateral and Borrow"
            case .cometRepay: return "Comet Repay"
            case .cometWithdrawCollateral: return "Comet Withdraw Collateral"
            case .cometRepayAndWithdrawCollateral: return "Comet Repay and Withdraw Collateral"
            case .morphoSupplyCollateral: return "Morpho Supply Collateral"
            case .morphoBorrow: return "Morpho Borrow"
            case .morphoSupplyCollateralAndBorrow: return "Morpho Supply Collateral and Borrow"
            case .morphoRepay: return "Morpho Repay"
            case .morphoWithdrawCollateral: return "Morpho Withdraw Collateral"
            case .morphoRepayAndWithdrawCollateral: return "Morpho Repay and Withdraw Collateral"
            case .morphoVaultSupply: return "Morpho Vault Supply"
            case .morphoVaultWithdraw: return "Morpho Vault Withdraw"
            case .swap: return "Swap"
            case .loopLong: return "Loop Long"
            case .loopShort: return "Loop Short"
            case .unloopLong: return "Unloop Long"
            case .unloopShort: return "Unloop Short"
            case .addBackingToken: return "Add Backing Token"
            case .withdrawBackingToken: return "Withdraw Backing Token"
            case .morphoClaimRewards: return "Morpho Claim Rewards"
            case .cometClaimRewards: return "Comet Claim Rewards"
            case .rewardSettlement: return "Reward Settlement"
        }
    }

    /// A space-free identifier for use in route IDs
    public var identifier: String {
        switch self {
            case .tokenTransfer: return "tokenTransfer"
            case .transferOut: return "transferOut"
            case .bridge: return "bridge"
            case .wrap: return "wrap"
            case .unwrap: return "unwrap"
            case .aaveSupply: return "aaveSupply"
            case .aaveWithdraw: return "aaveWithdraw"
            case .cometSupply: return "cometSupply"
            case .cometWithdraw: return "cometWithdraw"
            case .cometSupplyCollateral: return "cometSupplyCollateral"
            case .cometBorrow: return "cometBorrow"
            case .cometSupplyCollateralAndBorrow: return "cometSupplyCollateralAndBorrow"
            case .cometRepay: return "cometRepay"
            case .cometWithdrawCollateral: return "cometWithdrawCollateral"
            case .cometRepayAndWithdrawCollateral: return "cometRepayAndWithdrawCollateral"
            case .morphoSupplyCollateral: return "morphoSupplyCollateral"
            case .morphoBorrow: return "morphoBorrow"
            case .morphoSupplyCollateralAndBorrow: return "morphoSupplyCollateralAndBorrow"
            case .morphoRepay: return "morphoRepay"
            case .morphoWithdrawCollateral: return "morphoWithdrawCollateral"
            case .morphoRepayAndWithdrawCollateral: return "morphoRepayAndWithdrawCollateral"
            case .morphoVaultSupply: return "morphoVaultSupply"
            case .morphoVaultWithdraw: return "morphoVaultWithdraw"
            case .swap: return "swap"
            case .loopLong: return "loopLong"
            case .loopShort: return "loopShort"
            case .unloopLong: return "unloopLong"
            case .unloopShort: return "unloopShort"
            case .addBackingToken: return "addBackingToken"
            case .withdrawBackingToken: return "withdrawBackingToken"
            case .morphoClaimRewards: return "morphoClaimRewards"
            case .cometClaimRewards: return "cometClaimRewards"
            case .rewardSettlement: return "rewardSettlement"
        }
    }

    func label(source: TradewindsLegendNode, sink: TradewindsLegendNode) -> String {
        switch self {
            case .tokenTransfer: return "ERC20 Transfer \(source.label) -> \(sink.label)"
            case .transferOut: return "ERC20 Transfer \(source.label) -> \(sink.label) [External]"
            case .bridge: return "Bridge \(source.label) -> \(sink.label)"
            case .wrap: return "Wrap \(source.label) -> \(sink.label)"
            case .unwrap: return "Unwrap \(source.label) -> \(sink.label)"
            case .aaveSupply: return "Aave Supply \(source.label) -> \(sink.label)"
            case .aaveWithdraw: return "Aave Withdraw \(source.label) -> \(sink.label)"
            case .cometSupply: return "Comet Supply \(source.label) -> \(sink.label)"
            case .cometWithdraw: return "Comet Withdraw \(source.label) -> \(sink.label)"
            case .cometSupplyCollateral:
                return "Comet Supply Collateral \(source.label) -> \(sink.label)"
            case .cometBorrow: return "Comet Borrow \(source.label) -> \(sink.label)"
            case .cometSupplyCollateralAndBorrow:
                return "Comet Supply Collateral and Borrow \(source.label) -> \(sink.label)"
            case .cometRepay: return "Comet Repay \(source.label) -> \(sink.label)"
            case .cometWithdrawCollateral:
                return "Comet Withdraw Collateral \(source.label) -> \(sink.label)"
            case .cometRepayAndWithdrawCollateral:
                return "Comet Repay and Withdraw Collateral \(source.label) -> \(sink.label)"
            case .morphoSupplyCollateral:
                return "Morpho Supply Collateral \(source.label) -> \(sink.label)"
            case .morphoBorrow: return "Morpho Borrow \(source.label) -> \(sink.label)"
            case .morphoSupplyCollateralAndBorrow:
                return "Morpho Supply Collateral and Borrow \(source.label) -> \(sink.label)"
            case .morphoRepay: return "Morpho Repay \(source.label) -> \(sink.label)"
            case .morphoWithdrawCollateral:
                return "Morpho Withdraw Collateral \(source.label) -> \(sink.label)"
            case .morphoRepayAndWithdrawCollateral:
                return "Morpho Repay and Withdraw Collateral \(source.label) -> \(sink.label)"
            case .morphoVaultSupply: return "Morpho Vault Supply \(source.label) -> \(sink.label)"
            case .morphoVaultWithdraw:
                return "Morpho Vault Withdraw \(source.label) -> \(sink.label)"
            case .swap: return "Swap \(source.label) -> \(sink.label)"
            case .loopLong: return "Loop Long \(source.label) -> \(sink.label)"
            case .loopShort: return "Loop Short \(source.label) -> \(sink.label)"
            case .unloopLong: return "Unloop Long \(source.label) -> \(sink.label)"
            case .unloopShort: return "Unloop Short \(source.label) -> \(sink.label)"
            case .addBackingToken: return "Add Backing Token \(source.label) -> \(sink.label)"
            case .withdrawBackingToken:
                return "Withdraw Backing Token \(source.label) -> \(sink.label)"
            case .morphoClaimRewards: return "Morpho Claim Rewards \(source.label) -> \(sink.label)"
            case .cometClaimRewards: return "Comet Claim Rewards \(source.label) -> \(sink.label)"
            case .rewardSettlement: return "Reward Settlement \(source.label) -> \(sink.label)"
        }
    }

    var order: Int {
        switch self {
            case .tokenTransfer: 0
            case .transferOut: 1
            case .bridge: 2
            case .wrap: 3
            case .unwrap: 4
            case .aaveSupply: 5
            case .aaveWithdraw: 6
            case .cometSupply: 7
            case .cometWithdraw: 8
            case .cometSupplyCollateral: 9
            case .cometBorrow: 10
            case .cometSupplyCollateralAndBorrow: 11
            case .cometRepay: 12
            case .cometWithdrawCollateral: 13
            case .cometRepayAndWithdrawCollateral: 14
            case .morphoSupplyCollateral: 15
            case .morphoBorrow: 16
            case .morphoSupplyCollateralAndBorrow: 17
            case .morphoVaultSupply: 18
            case .morphoVaultWithdraw: 19
            case .morphoRepay: 20
            case .morphoWithdrawCollateral: 21
            case .morphoRepayAndWithdrawCollateral: 22
            case .swap: 23
            case .loopLong: 24
            case .loopShort: 25
            case .unloopLong: 26
            case .unloopShort: 27
            case .addBackingToken: 28
            case .withdrawBackingToken: 29
            case .morphoClaimRewards: 30
            case .cometClaimRewards: 31
            case .rewardSettlement: 32
        }
    }

    // Implement Comparable for deterministic ordering
    public static func < (lhs: LegendRouteType, rhs: LegendRouteType) -> Bool {
        lhs.order < rhs.order
    }

    public var operationType: String? {
        switch self {
            case .tokenTransfer: return "baseline"
            case .transferOut: return "baseline"
            case .bridge: return "baseline"
            case .wrap: return nil
            case .unwrap: return nil
            case .aaveSupply: return "baseline"
            case .aaveWithdraw: return "baseline"
            case .cometSupply: return "baseline"
            case .cometWithdraw: return "baseline"
            case .cometSupplyCollateral: return "baseline"
            case .cometBorrow: return "baseline"
            case .cometSupplyCollateralAndBorrow: return "baseline"
            case .cometRepay: return "baseline"
            case .cometWithdrawCollateral: return "baseline"
            case .cometRepayAndWithdrawCollateral: return "baseline"
            case .morphoSupplyCollateral: return "baseline"
            case .morphoBorrow: return "baseline"
            case .morphoSupplyCollateralAndBorrow: return "baseline"
            case .morphoRepay: return "baseline"
            case .morphoWithdrawCollateral: return "baseline"
            case .morphoRepayAndWithdrawCollateral: return "baseline"
            case .morphoVaultSupply: return "baseline"
            case .morphoVaultWithdraw: return "baseline"
            case .swap: return nil
            case .loopLong: return nil
            case .loopShort: return nil
            case .unloopLong: return nil
            case .unloopShort: return nil
            case .addBackingToken: return "baseline"
            case .withdrawBackingToken: return "baseline"
            case .morphoClaimRewards: return "baseline"
            case .cometClaimRewards: return "baseline"
            case .rewardSettlement: return nil
        }
    }
}
