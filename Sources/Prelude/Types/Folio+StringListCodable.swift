import Eth
import Foundation
import SwiftNumber

// MARK: - Helper Functions
extension EthAddress {
    fileprivate static func fromString(_ value: String) throws -> EthAddress {
        guard let address = EthAddress(fromHexString: value) else {
            throw StringListCodableError.invalidFormat("Invalid address: \(value)")
        }
        return address
    }
}

// MARK: - PriceType
extension Folio.PriceType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .token(let symbol):
                return ["token", symbol]
            case .assetQuote(let quoteId, let tokenSymbol):
                return ["asset_quote", quoteId.hex, tokenSymbol]
            case .networkOperationQuote(let quoteId, let network, let operationType):
                return [
                    "network_operation_quote", quoteId.hex, network.networkIdent, operationType,
                ]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (Folio.PriceType, [String]) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "token":
                guard values.count >= 2 else {
                    throw StringListCodableError.insufficientValues(expected: 2, got: values.count)
                }
                return (.token(symbol: values[1]), Array(values.dropFirst(2)))

            case "asset_quote":
                guard values.count >= 3 else {
                    throw StringListCodableError.insufficientValues(expected: 3, got: values.count)
                }
                let quoteId = Hex(stringLiteral: values[1])
                return (
                    .assetQuote(quoteId: quoteId, tokenSymbol: values[2]),
                    Array(values.dropFirst(3))
                )

            case "network_operation_quote":
                guard values.count >= 4 else {
                    throw StringListCodableError.insufficientValues(expected: 4, got: values.count)
                }
                let quoteId = Hex(stringLiteral: values[1])
                let network = try Network(fromIdent: values[2])
                return (
                    .networkOperationQuote(
                        quoteId: quoteId,
                        network: network,
                        operationType: values[3]
                    ),
                    Array(values.dropFirst(4))
                )

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - YieldMarketType
extension Folio.YieldMarketType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .aave(let network, let pool, let underlyingSymbol):
                return ["aave", network.networkIdent, pool.hex, underlyingSymbol]
            case .comet(let network, let comet, let underlyingSymbol):
                return ["comet", network.networkIdent, comet.hex, underlyingSymbol]
            case .morphoVault(let network, let vault, let underlyingSymbol):
                return ["morpho_vault", network.networkIdent, vault.hex, underlyingSymbol]
            case .stakingToken(let network, let symbol):
                return ["staking_token", network.networkIdent, symbol]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (
        Folio.YieldMarketType, [String]
    ) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "aave", "comet", "morpho_vault":
                guard values.count >= 4 else {
                    throw StringListCodableError.insufficientValues(expected: 4, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                let address = try EthAddress.fromString(values[2])

                let result: Folio.YieldMarketType
                switch values[0] {
                    case "aave":
                        result = .aave(network: network, pool: address, underlyingSymbol: values[3])
                    case "comet":
                        result = .comet(
                            network: network,
                            comet: address,
                            underlyingSymbol: values[3]
                        )
                    case "morpho_vault":
                        result = .morphoVault(
                            network: network,
                            vault: address,
                            underlyingSymbol: values[3]
                        )
                    default:
                        fatalError("Unreachable")
                }
                return (result, Array(values.dropFirst(4)))

            case "staking_token":
                guard values.count >= 3 else {
                    throw StringListCodableError.insufficientValues(expected: 3, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                return (
                    .stakingToken(network: network, symbol: values[2]), Array(values.dropFirst(3))
                )

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - BorrowMarketType
extension Folio.BorrowMarketType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .aave(let network, let pool, let underlyingSymbol):
                return ["aave", network.networkIdent, pool.hex, underlyingSymbol]
            case .comet(let network, let comet, let underlyingSymbol):
                return ["comet", network.networkIdent, comet.hex, underlyingSymbol]
            case .morpho(let network, let collateralTokenSymbol, let borrowTokenSymbol):
                return ["morpho", network.networkIdent, collateralTokenSymbol, borrowTokenSymbol]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (
        Folio.BorrowMarketType, [String]
    ) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "aave", "comet":
                guard values.count >= 4 else {
                    throw StringListCodableError.insufficientValues(expected: 4, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                let address = try EthAddress.fromString(values[2])

                let result: Folio.BorrowMarketType
                switch values[0] {
                    case "aave":
                        result = .aave(network: network, pool: address, underlyingSymbol: values[3])
                    case "comet":
                        result = .comet(
                            network: network,
                            comet: address,
                            underlyingSymbol: values[3]
                        )
                    default:
                        fatalError("Unreachable")
                }
                return (result, Array(values.dropFirst(4)))

            case "morpho":
                guard values.count >= 4 else {
                    throw StringListCodableError.insufficientValues(expected: 4, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                return (
                    .morpho(
                        network: network,
                        collateralTokenSymbol: values[2],
                        borrowTokenSymbol: values[3]
                    ),
                    Array(values.dropFirst(4))
                )

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - BalanceType
extension Folio.BalanceType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .token(let network, let symbol, let wallet):
                return ["token", network.networkIdent, symbol, wallet.hex]

            case .yieldMarket(let yieldMarket, let wallet):
                return ["yield_market"] + yieldMarket.toStringList() + [wallet.hex]

            case .borrowMarket(let borrowMarket, let wallet):
                return ["borrow_market"] + borrowMarket.toStringList() + [wallet.hex]

            case .borrowMarketCollateral(let borrowMarket, let tokenSymbol, let wallet):
                return ["borrow_market_collateral"] + borrowMarket.toStringList() + [
                    tokenSymbol, wallet.hex,
                ]

            case .reward(let rewardType):
                return ["reward"] + rewardType.toStringList()

            case .lockedReward(let rewardType):
                return ["locked_reward"] + rewardType.toStringList()
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (Folio.BalanceType, [String]) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "token":
                guard values.count >= 4 else {
                    throw StringListCodableError.insufficientValues(expected: 4, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                let wallet = try EthAddress.fromString(values[3])
                return (
                    .token(network: network, symbol: values[2], wallet: wallet),
                    Array(values.dropFirst(4))
                )

            case "yield_market":
                let remaining = Array(values.dropFirst(1))
                let (yieldMarket, afterYield) = try Folio.YieldMarketType.fromStringList(remaining)
                guard afterYield.count >= 1 else {
                    throw StringListCodableError.insufficientValues(
                        expected: 1,
                        got: afterYield.count
                    )
                }
                let wallet = try EthAddress.fromString(afterYield[0])
                return (
                    .yieldMarket(yieldMarket: yieldMarket, wallet: wallet),
                    Array(afterYield.dropFirst(1))
                )

            case "borrow_market":
                let remaining = Array(values.dropFirst(1))
                let (borrowMarket, afterBorrow) = try Folio.BorrowMarketType.fromStringList(
                    remaining
                )
                guard afterBorrow.count >= 1 else {
                    throw StringListCodableError.insufficientValues(
                        expected: 1,
                        got: afterBorrow.count
                    )
                }
                let wallet = try EthAddress.fromString(afterBorrow[0])
                return (
                    .borrowMarket(borrowMarket: borrowMarket, wallet: wallet),
                    Array(afterBorrow.dropFirst(1))
                )

            case "borrow_market_collateral":
                let remaining = Array(values.dropFirst(1))
                let (borrowMarket, afterBorrow) = try Folio.BorrowMarketType.fromStringList(
                    remaining
                )
                guard afterBorrow.count >= 2 else {
                    throw StringListCodableError.insufficientValues(
                        expected: 2,
                        got: afterBorrow.count
                    )
                }
                let tokenSymbol = afterBorrow[0]
                let wallet = try EthAddress.fromString(afterBorrow[1])
                return (
                    .borrowMarketCollateral(
                        borrowMarket: borrowMarket,
                        tokenSymbol: tokenSymbol,
                        wallet: wallet
                    ),
                    Array(afterBorrow.dropFirst(2))
                )

            case "reward":
                let remaining = Array(values.dropFirst(1))
                let (rewardType, afterReward) = try Folio.RewardType.fromStringList(remaining)
                return (.reward(rewardType: rewardType), afterReward)

            case "locked_reward":
                let remaining = Array(values.dropFirst(1))
                let (rewardType, afterReward) = try Folio.RewardType.fromStringList(remaining)
                return (.lockedReward(rewardType: rewardType), afterReward)

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - RewardType
extension Folio.RewardType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .cometReward(
                let network,
                let comet,
                let underlyingSymbol,
                let rewardsContract,
                let wallet
            ):
                return [
                    "comet_reward", network.networkIdent, comet.hex, underlyingSymbol,
                    rewardsContract.hex, wallet.hex,
                ]
            case .morphoReward(let network, let underlyingSymbol, let distributor, let wallet):
                return [
                    "morpho_reward", network.networkIdent, underlyingSymbol, distributor.hex,
                    wallet.hex,
                ]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (Folio.RewardType, [String]) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "comet_reward":
                guard values.count >= 6 else {
                    throw StringListCodableError.insufficientValues(expected: 6, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                let comet = try EthAddress.fromString(values[2])
                let cometRewards = try EthAddress.fromString(values[4])
                let wallet = try EthAddress.fromString(values[5])
                return (
                    .cometReward(
                        network: network,
                        comet: comet,
                        underlyingSymbol: values[3],
                        cometRewards: cometRewards,
                        wallet: wallet
                    ),
                    Array(values.dropFirst(6))
                )

            case "morpho_reward":
                guard values.count >= 5 else {
                    throw StringListCodableError.insufficientValues(expected: 5, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                let distributor = try EthAddress.fromString(values[3])
                let wallet = try EthAddress.fromString(values[4])
                return (
                    .morphoReward(
                        network: network,
                        underlyingSymbol: values[2],
                        distributor: distributor,
                        wallet: wallet
                    ),
                    Array(values.dropFirst(5))
                )

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - SwapHintType
extension Folio.SwapHintType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .wrapper(
                let underlyingNetwork,
                let underlyingSymbol,
                let wrappedNetwork,
                let wrappedSymbol
            ):
                return [
                    "wrapper", underlyingNetwork.networkIdent, underlyingSymbol,
                    wrappedNetwork.networkIdent, wrappedSymbol,
                ]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (Folio.SwapHintType, [String]) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "wrapper":
                guard values.count >= 5 else {
                    throw StringListCodableError.insufficientValues(expected: 5, got: values.count)
                }
                let underlyingNetwork = try Network(fromIdent: values[1])
                let wrappedNetwork = try Network(fromIdent: values[3])
                return (
                    .wrapper(
                        underlyingNetwork: underlyingNetwork,
                        underlyingSymbol: values[2],
                        wrappedNetwork: wrappedNetwork,
                        wrappedSymbol: values[4]
                    ),
                    Array(values.dropFirst(5))
                )

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - BridgeHintType
extension Folio.BridgeHintType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .across(let networkIn, let symbolIn, let networkOut, let symbolOut):
                return [
                    "across", networkIn.networkIdent, symbolIn, networkOut.networkIdent, symbolOut,
                ]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (Folio.BridgeHintType, [String])
    {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "across":
                guard values.count >= 5 else {
                    throw StringListCodableError.insufficientValues(expected: 5, got: values.count)
                }
                let networkIn = try Network(fromIdent: values[1])
                let networkOut = try Network(fromIdent: values[3])
                return (
                    .across(
                        networkIn: networkIn,
                        symbolIn: values[2],
                        networkOut: networkOut,
                        symbolOut: values[4]
                    ),
                    Array(values.dropFirst(5))
                )

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - HexDataType
extension Folio.HexDataType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .nonceSecret(let network, let wallet):
                return ["nonce_secret", network.networkIdent, wallet.hex]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (Folio.HexDataType, [String]) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "nonce_secret":
                guard values.count >= 3 else {
                    throw StringListCodableError.insufficientValues(expected: 3, got: values.count)
                }
                let network = try Network(fromIdent: values[1])
                let wallet = try EthAddress.fromString(values[2])
                return (.nonceSecret(network: network, wallet: wallet), Array(values.dropFirst(3)))

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}

// MARK: - CompletionStatusType
extension Folio.CompletionStatusType: StringListCodable {
    public func toStringList() -> [String] {
        switch self {
            case .quarkNonce(let wallet, let nonce):
                return ["quark_nonce", wallet.hex, nonce.hex]
            case .acrossFill(let wallet, let relayHash):
                return ["across_fill", wallet.hex, relayHash.hex]
        }
    }

    public static func fromStringList(_ values: [String]) throws -> (
        Folio.CompletionStatusType, [String]
    ) {
        guard values.count >= 1 else {
            throw StringListCodableError.insufficientValues(expected: 1, got: values.count)
        }

        switch values[0] {
            case "quark_nonce":
                guard values.count >= 3 else {
                    throw StringListCodableError.insufficientValues(expected: 3, got: values.count)
                }
                let wallet = try EthAddress.fromString(values[1])
                let nonce = Hex(stringLiteral: values[2])
                return (.quarkNonce(wallet: wallet, nonce: nonce), Array(values.dropFirst(3)))

            case "across_fill":
                guard values.count >= 3 else {
                    throw StringListCodableError.insufficientValues(expected: 3, got: values.count)
                }
                let wallet = try EthAddress.fromString(values[1])
                let relayHash = Hex(stringLiteral: values[2])
                return (
                    .acrossFill(wallet: wallet, relayHash: relayHash), Array(values.dropFirst(3))
                )

            default:
                throw StringListCodableError.unknownDiscriminator(values[0])
        }
    }
}
