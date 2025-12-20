import Eth
import Foundation
import SwiftNumber

/// An ``ActionContext`` wraps ``Action`` contexts returned from ``Charter``. These can be serialized and de-serialized to send to the backend.
extension Charter.ActionContext: ActionProtocol {
    public var isBridge: Bool {
        switch self {
            case .bridge: true
            case .multiAction(let actionContexts):
                actionContexts.contains(where: \.isBridge)
            default: false
        }
    }

    public var isMultiAction: Bool {
        switch self {
            case .multiAction: true
            default: false
        }
    }

    public var isQuotePay: Bool {
        switch self {
            case .quotePay: true
            default: false
        }
    }

    public var isRecurring: Bool {
        switch self {
            case .recurringSwap: true
            default: false
        }
    }

    public var isSupply: Bool {
        switch self {
            case .cometSupply, .morphoVaultSupply: true
            default: false
        }
    }

    public var isWithdraw: Bool {
        switch self {
            case .cometWithdraw, .morphoVaultWithdraw: true
            default: false
        }
    }

    public var isLoopLong: Bool {
        hasAction {
            if case .loopLong = $0 { true } else { false }
        }
    }

    public var isUnloopLong: Bool {
        hasAction {
            if case .unloopLong = $0 { true } else { false }
        }
    }

    public var isAddBackingToken: Bool {
        hasAction {
            if case .addBackingToken = $0 { true } else { false }
        }
    }

    public var isWithdrawBackingToken: Bool {
        hasAction {
            if case .withdrawBackingToken = $0 { true } else { false }
        }
    }

    private func hasAction(matching condition: (Self) -> Bool) -> Bool {
        switch self {
            case .multiAction(let actions):
                return actions.contains(where: condition)
            default:
                return condition(self)
        }
    }

    public var multis: [ActionProtocol] {
        switch self {
            case .multiAction(let actionContexts): actionContexts
            default: []
        }
    }

    // TODO: This logic should be shared. We do this kind of thing in `Asset`
    private func friendlyAssetSymbol(_ symbol: String) -> String {
        if symbol == "WETH" {
            "ETH"
        } else {
            symbol
        }
    }

    public var underlying: any Encodable {
        switch self {
            case .transfer(let context):
                context
            case .bridge(let context):
                context
            case .bridgeMint(let context):
                context
            case .aaveSupply(let context):
                context
            case .aaveWithdraw(let context):
                context
            case .cometSupply(let context):
                context
            case .morphoVaultSupply(let context):
                context
            case .cometBorrow(let context):
                context
            case .morphoBorrow(let context):
                context
            case .cometRepay(let context):
                context
            case .morphoRepay(let context):
                context
            case .swap(let context):
                context
            case .cometClaimRewards(let context):
                context
            case .morphoClaimRewards(let context):
                context
            case .cometWithdraw(let context):
                context
            case .morphoVaultWithdraw(let context):
                context
            case .recurringSwap(let context):
                context
            case .quotePay(let context):
                context
            case .wrap(let context):
                context
            case .loopLong(let context):
                context
            case .loopShort(let context):
                context
            case .unloopLong(let context):
                context
            case .unloopShort(let context):
                context
            case .addBackingToken(let context):
                context
            case .withdrawBackingToken(let context):
                context
            case .multiAction(let context):
                context
            case .withdrawAndBorrow(let context):
                context
            case .unwrap(let context):
                context
        }
    }

    public var chainId: Number {
        switch self {
            case .transfer(let actionContext):
                actionContext.chainId
            case .bridge(let actionContext):
                actionContext.chainId
            case .bridgeMint(let actionContext):
                actionContext.chainId
            case .aaveSupply(let actionContext):
                actionContext.chainId
            case .aaveWithdraw(let actionContext):
                actionContext.chainId
            case .cometSupply(let actionContext):
                actionContext.chainId
            case .morphoVaultSupply(let actionContext):
                actionContext.chainId
            case .cometBorrow(let actionContext):
                actionContext.chainId
            case .morphoBorrow(let actionContext):
                actionContext.chainId
            case .cometRepay(let actionContext):
                actionContext.chainId
            case .morphoRepay(let actionContext):
                actionContext.chainId
            case .swap(let actionContext):
                actionContext.chainId
            case .cometClaimRewards(let actionContext):
                actionContext.chainId
            case .morphoClaimRewards(let actionContext):
                actionContext.chainId
            case .cometWithdraw(let actionContext):
                actionContext.chainId
            case .morphoVaultWithdraw(let actionContext):
                actionContext.chainId
            case .recurringSwap(let actionContext):
                actionContext.chainId
            case .quotePay(let actionContext):
                actionContext.chainId
            case .wrap(let actionContext):
                actionContext.chainId
            case .loopLong(let actionContext):
                actionContext.chainId
            case .loopShort(let actionContext):
                actionContext.chainId
            case .unloopLong(let actionContext):
                actionContext.chainId
            case .unloopShort(let actionContext):
                actionContext.chainId
            case .addBackingToken(let actionContext):
                actionContext.chainId
            case .withdrawBackingToken(let actionContext):
                actionContext.chainId
            case .unwrap(let actionContext):
                actionContext.chainId
            case .multiAction(let actionContexts):
                actionContexts.first!.chainId
            case .withdrawAndBorrow(let actionContext):
                actionContext.chainId
        }
    }

    public var network: Network {
        Network.fromChainId(chainId)
    }

    public var actionCount: Int {
        switch self {
            case .cometBorrow(let actionContext):
                actionContext.amount > Number.zero
                    ? actionContext.collateralAmounts.count + 1
                    : actionContext.collateralAmounts.count
            case .cometRepay(let actionContext):
                actionContext.amount > Number.zero
                    ? actionContext.collateralAmounts.count + 1
                    : actionContext.collateralAmounts.count
            case .quotePay, .wrap:
                0
            default:
                1
        }
    }

    public var bridgeActionContext: Charter.ActionContext.BridgeActionContext? {
        switch self {
            case .bridge(let bridgeActionContext):
                bridgeActionContext

            case .multiAction(let actionContexts):
                actionContexts
                    .first(where: {
                        if case .bridge = $0 {
                            return true
                        } else {
                            return false
                        }
                    })
                    .flatMap {
                        $0.underlying as? Charter.ActionContext.BridgeActionContext
                    }

            default:
                nil
        }
    }

    /// Returns true if self is for an action that involves the assetSymbol
    public func isRelatedTo(assetSymbol: String) -> Bool {
        switch self {
            case .transfer(let actionContext):
                actionContext.assetSymbol == assetSymbol
            case .aaveSupply(let actionContext):
                actionContext.assetSymbol == assetSymbol
            case .aaveWithdraw(let actionContext):
                actionContext.assetSymbol == assetSymbol
            case .cometSupply(let actionContext):
                actionContext.assetSymbol == assetSymbol
            case .morphoVaultSupply(let actionContext):
                actionContext.assetSymbol == assetSymbol
            case .cometBorrow(let actionContext):
                actionContext.assetSymbol == assetSymbol
                    || actionContext.collateralAssetSymbols.contains(assetSymbol)
            case .morphoBorrow(let actionContext):
                actionContext.assetSymbol == assetSymbol
                    || actionContext.collateralAssetSymbol == assetSymbol
            case .cometRepay(let actionContext):
                actionContext.assetSymbol == assetSymbol
                    || actionContext.collateralAssetSymbols.contains(assetSymbol)
            case .morphoRepay(let actionContext):
                actionContext.assetSymbol == assetSymbol
                    || actionContext.collateralAssetSymbol == assetSymbol
            case .swap(let actionContext):
                // USDC is the base asset for Legend swaps and an activity is not
                // considered to be related to it on swaps
                if assetSymbol == "USDC" {
                    false
                } else {
                    actionContext.inputAssetSymbol == assetSymbol
                        || actionContext.outputAssetSymbol == assetSymbol
                }
            case .cometClaimRewards(let actionContext):
                actionContext.assetSymbols.contains(assetSymbol)
            case .morphoClaimRewards(let actionContext):
                actionContext.assetSymbols.contains(assetSymbol)
            case .cometWithdraw(let actionContext):
                actionContext.assetSymbol == assetSymbol
            case .morphoVaultWithdraw(let actionContext):
                actionContext.assetSymbol == assetSymbol
            case .recurringSwap(let actionContext):
                actionContext.inputAssetSymbol == assetSymbol
                    || actionContext.outputAssetSymbol == assetSymbol
            case .loopLong(let actionContext):
                actionContext.backingAssetSymbol == assetSymbol
                    || actionContext.exposureAssetSymbol == assetSymbol
            case .loopShort(let actionContext):
                actionContext.backingAssetSymbol == assetSymbol
                    || actionContext.exposureAssetSymbol == assetSymbol
            case .unloopLong(let actionContext):
                actionContext.backingAssetSymbol == assetSymbol
                    || actionContext.exposureAssetSymbol == assetSymbol
            case .unloopShort(let actionContext):
                actionContext.backingAssetSymbol == assetSymbol
                    || actionContext.exposureAssetSymbol == assetSymbol
            case .multiAction(let actionContexts):
                actionContexts.contains(where: {
                    $0.isRelatedTo(assetSymbol: assetSymbol)
                })
            case .quotePay, .bridge, .wrap, .withdrawAndBorrow, .unwrap, .addBackingToken,
                .withdrawBackingToken, .bridgeMint:
                false
        }
    }
}
