@preconcurrency import SwiftNumber
@preconcurrency import Eth
import Foundation

public enum Actions {
    public struct AaveSupplyActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let aavePool: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, aavePool: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.aavePool = aavePool
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(aavePool),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> AaveSupplyActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> AaveSupplyActionContext {
            switch value {
            case let .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(aavePool),
             .uint256(price),
             .address(token)):
                return AaveSupplyActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, aavePool: aavePool, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct AaveWithdrawActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let aavePool: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, aavePool: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.aavePool = aavePool
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(aavePool),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> AaveWithdrawActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> AaveWithdrawActionContext {
            switch value {
            case let .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(aavePool),
             .uint256(price),
             .address(token)):
                return AaveWithdrawActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, aavePool: aavePool, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct AddBackingTokenActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .string, .bytes32, .bool])

        public let amount: Number
        public let backingAssetSymbol: String
        public let backingToken: EthAddress
        public let backingTokenPrice: Number
        public let chainId: Number
        public let exposureAssetSymbol: String
        public let exposureToken: EthAddress
        public let exposureTokenPrice: Number
        public let borrowVenue: String
        public let borrowMarketId: Hex
        public let isShort: Bool

        public init(amount: Number, backingAssetSymbol: String, backingToken: EthAddress, backingTokenPrice: Number, chainId: Number, exposureAssetSymbol: String, exposureToken: EthAddress, exposureTokenPrice: Number, borrowVenue: String, borrowMarketId: Hex, isShort: Bool) {
          self.amount = amount
         self.backingAssetSymbol = backingAssetSymbol
         self.backingToken = backingToken
         self.backingTokenPrice = backingTokenPrice
         self.chainId = chainId
         self.exposureAssetSymbol = exposureAssetSymbol
         self.exposureToken = exposureToken
         self.exposureTokenPrice = exposureTokenPrice
         self.borrowVenue = borrowVenue
         self.borrowMarketId = borrowMarketId
         self.isShort = isShort
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple11(.uint256(amount),
             .string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(chainId),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .bool(isShort))
        }

        public static func decode(hex: Hex) throws -> AddBackingTokenActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> AddBackingTokenActionContext {
            switch value {
            case let .tuple11(.uint256(amount),
             .string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(chainId),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .bool(isShort)):
                return AddBackingTokenActionContext(amount: amount, backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, chainId: chainId, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, isShort: isShort)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct BorrowActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .array(.uint256), .array(.string), .array(.uint256), .array(.address), .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let collateralAmounts: [Number]
        public let collateralAssetSymbols: [String]
        public let collateralTokenPrices: [Number]
        public let collateralTokens: [EthAddress]
        public let comet: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, collateralAmounts: [Number], collateralAssetSymbols: [String], collateralTokenPrices: [Number], collateralTokens: [EthAddress], comet: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.collateralAmounts = collateralAmounts
         self.collateralAssetSymbols = collateralAssetSymbols
         self.collateralTokenPrices = collateralTokenPrices
         self.collateralTokens = collateralTokens
         self.comet = comet
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple10(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .array(.uint256, collateralAmounts.map {
                        .uint256($0)
                    }),
             .array(.string, collateralAssetSymbols.map {
                        .string($0)
                    }),
             .array(.uint256, collateralTokenPrices.map {
                        .uint256($0)
                    }),
             .array(.address, collateralTokens.map {
                        .address($0)
                    }),
             .address(comet),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> BorrowActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> BorrowActionContext {
            switch value {
            case let .tuple10(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .array(.uint256, collateralAmounts),
             .array(.string, collateralAssetSymbols),
             .array(.uint256, collateralTokenPrices),
             .array(.address, collateralTokens),
             .address(comet),
             .uint256(price),
             .address(token)):
                return BorrowActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmounts: collateralAmounts.map {
                        $0.asNumber!
                    }, collateralAssetSymbols: collateralAssetSymbols.map {
                        $0.asString!
                    }, collateralTokenPrices: collateralTokenPrices.map {
                        $0.asNumber!
                    }, collateralTokens: collateralTokens.map {
                        $0.asEthAddress!
                    }, comet: comet, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct BridgeActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.string, .string, .uint256, .uint256, .uint256, .uint256, .uint256, .address, .address])

        public let assetSymbol: String
        public let bridgeType: String
        public let chainId: Number
        public let destinationChainId: Number
        public let inputAmount: Number
        public let outputAmount: Number
        public let price: Number
        public let recipient: EthAddress
        public let token: EthAddress

        public init(assetSymbol: String, bridgeType: String, chainId: Number, destinationChainId: Number, inputAmount: Number, outputAmount: Number, price: Number, recipient: EthAddress, token: EthAddress) {
          self.assetSymbol = assetSymbol
         self.bridgeType = bridgeType
         self.chainId = chainId
         self.destinationChainId = destinationChainId
         self.inputAmount = inputAmount
         self.outputAmount = outputAmount
         self.price = price
         self.recipient = recipient
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple9(.string(assetSymbol),
             .string(bridgeType),
             .uint256(chainId),
             .uint256(destinationChainId),
             .uint256(inputAmount),
             .uint256(outputAmount),
             .uint256(price),
             .address(recipient),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> BridgeActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> BridgeActionContext {
            switch value {
            case let .tuple9(.string(assetSymbol),
             .string(bridgeType),
             .uint256(chainId),
             .uint256(destinationChainId),
             .uint256(inputAmount),
             .uint256(outputAmount),
             .uint256(price),
             .address(recipient),
             .address(token)):
                return BridgeActionContext(assetSymbol: assetSymbol, bridgeType: bridgeType, chainId: chainId, destinationChainId: destinationChainId, inputAmount: inputAmount, outputAmount: outputAmount, price: price, recipient: recipient, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct CometClaimRewardsActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.array(.uint256), .array(.string), .uint256, .array(.uint256), .array(.address)])

        public let amounts: [Number]
        public let assetSymbols: [String]
        public let chainId: Number
        public let prices: [Number]
        public let tokens: [EthAddress]

        public init(amounts: [Number], assetSymbols: [String], chainId: Number, prices: [Number], tokens: [EthAddress]) {
          self.amounts = amounts
         self.assetSymbols = assetSymbols
         self.chainId = chainId
         self.prices = prices
         self.tokens = tokens
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple5(.array(.uint256, amounts.map {
                        .uint256($0)
                    }),
             .array(.string, assetSymbols.map {
                        .string($0)
                    }),
             .uint256(chainId),
             .array(.uint256, prices.map {
                        .uint256($0)
                    }),
             .array(.address, tokens.map {
                        .address($0)
                    }))
        }

        public static func decode(hex: Hex) throws -> CometClaimRewardsActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> CometClaimRewardsActionContext {
            switch value {
            case let .tuple5(.array(.uint256, amounts),
             .array(.string, assetSymbols),
             .uint256(chainId),
             .array(.uint256, prices),
             .array(.address, tokens)):
                return CometClaimRewardsActionContext(amounts: amounts.map {
                        $0.asNumber!
                    }, assetSymbols: assetSymbols.map {
                        $0.asString!
                    }, chainId: chainId, prices: prices.map {
                        $0.asNumber!
                    }, tokens: tokens.map {
                        $0.asEthAddress!
                    })
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct CometSupplyActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let comet: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, comet: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.comet = comet
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(comet),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> CometSupplyActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> CometSupplyActionContext {
            switch value {
            case let .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(comet),
             .uint256(price),
             .address(token)):
                return CometSupplyActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, comet: comet, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct CometWithdrawActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let comet: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, comet: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.comet = comet
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(comet),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> CometWithdrawActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> CometWithdrawActionContext {
            switch value {
            case let .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(comet),
             .uint256(price),
             .address(token)):
                return CometWithdrawActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, comet: comet, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct DripTokensActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256])

        public let chainId: Number

        public init(chainId: Number) {
          self.chainId = chainId
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple1(.uint256(chainId))
        }

        public static func decode(hex: Hex) throws -> DripTokensActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> DripTokensActionContext {
            switch value {
            case let .tuple1(.uint256(chainId)):
                return DripTokensActionContext(chainId: chainId)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct LoopLongActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .bool, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])

        public let backingAssetSymbol: String
        public let backingToken: EthAddress
        public let backingTokenPrice: Number
        public let maxSwapBackingAmount: Number
        public let maxProvidedBackingAmount: Number
        public let chainId: Number
        public let isIncrease: Bool
        public let exposureAmount: Number
        public let exposureAssetSymbol: String
        public let exposureToken: EthAddress
        public let exposureTokenPrice: Number
        public let swapVenue: String
        public let borrowVenue: String
        public let borrowMarketId: Hex
        public let feeAmount: Number
        public let feeAssetSymbol: String
        public let feeToken: EthAddress
        public let feeTokenPrice: Number

        public init(backingAssetSymbol: String, backingToken: EthAddress, backingTokenPrice: Number, maxSwapBackingAmount: Number, maxProvidedBackingAmount: Number, chainId: Number, isIncrease: Bool, exposureAmount: Number, exposureAssetSymbol: String, exposureToken: EthAddress, exposureTokenPrice: Number, swapVenue: String, borrowVenue: String, borrowMarketId: Hex, feeAmount: Number, feeAssetSymbol: String, feeToken: EthAddress, feeTokenPrice: Number) {
          self.backingAssetSymbol = backingAssetSymbol
         self.backingToken = backingToken
         self.backingTokenPrice = backingTokenPrice
         self.maxSwapBackingAmount = maxSwapBackingAmount
         self.maxProvidedBackingAmount = maxProvidedBackingAmount
         self.chainId = chainId
         self.isIncrease = isIncrease
         self.exposureAmount = exposureAmount
         self.exposureAssetSymbol = exposureAssetSymbol
         self.exposureToken = exposureToken
         self.exposureTokenPrice = exposureTokenPrice
         self.swapVenue = swapVenue
         self.borrowVenue = borrowVenue
         self.borrowMarketId = borrowMarketId
         self.feeAmount = feeAmount
         self.feeAssetSymbol = feeAssetSymbol
         self.feeToken = feeToken
         self.feeTokenPrice = feeTokenPrice
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple18(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(maxSwapBackingAmount),
             .uint256(maxProvidedBackingAmount),
             .uint256(chainId),
             .bool(isIncrease),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice))
        }

        public static func decode(hex: Hex) throws -> LoopLongActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> LoopLongActionContext {
            switch value {
            case let .tuple18(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(maxSwapBackingAmount),
             .uint256(maxProvidedBackingAmount),
             .uint256(chainId),
             .bool(isIncrease),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice)):
                return LoopLongActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, maxSwapBackingAmount: maxSwapBackingAmount, maxProvidedBackingAmount: maxProvidedBackingAmount, chainId: chainId, isIncrease: isIncrease, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct LoopShortActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .bool, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])

        public let backingAssetSymbol: String
        public let backingToken: EthAddress
        public let backingTokenPrice: Number
        public let minSwapBackingAmount: Number
        public let providedBackingAmount: Number
        public let chainId: Number
        public let isIncrease: Bool
        public let exposureAmount: Number
        public let exposureAssetSymbol: String
        public let exposureToken: EthAddress
        public let exposureTokenPrice: Number
        public let swapVenue: String
        public let borrowVenue: String
        public let borrowMarketId: Hex
        public let feeAmount: Number
        public let feeAssetSymbol: String
        public let feeToken: EthAddress
        public let feeTokenPrice: Number

        public init(backingAssetSymbol: String, backingToken: EthAddress, backingTokenPrice: Number, minSwapBackingAmount: Number, providedBackingAmount: Number, chainId: Number, isIncrease: Bool, exposureAmount: Number, exposureAssetSymbol: String, exposureToken: EthAddress, exposureTokenPrice: Number, swapVenue: String, borrowVenue: String, borrowMarketId: Hex, feeAmount: Number, feeAssetSymbol: String, feeToken: EthAddress, feeTokenPrice: Number) {
          self.backingAssetSymbol = backingAssetSymbol
         self.backingToken = backingToken
         self.backingTokenPrice = backingTokenPrice
         self.minSwapBackingAmount = minSwapBackingAmount
         self.providedBackingAmount = providedBackingAmount
         self.chainId = chainId
         self.isIncrease = isIncrease
         self.exposureAmount = exposureAmount
         self.exposureAssetSymbol = exposureAssetSymbol
         self.exposureToken = exposureToken
         self.exposureTokenPrice = exposureTokenPrice
         self.swapVenue = swapVenue
         self.borrowVenue = borrowVenue
         self.borrowMarketId = borrowMarketId
         self.feeAmount = feeAmount
         self.feeAssetSymbol = feeAssetSymbol
         self.feeToken = feeToken
         self.feeTokenPrice = feeTokenPrice
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple18(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(minSwapBackingAmount),
             .uint256(providedBackingAmount),
             .uint256(chainId),
             .bool(isIncrease),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice))
        }

        public static func decode(hex: Hex) throws -> LoopShortActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> LoopShortActionContext {
            switch value {
            case let .tuple18(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(minSwapBackingAmount),
             .uint256(providedBackingAmount),
             .uint256(chainId),
             .bool(isIncrease),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice)):
                return LoopShortActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, minSwapBackingAmount: minSwapBackingAmount, providedBackingAmount: providedBackingAmount, chainId: chainId, isIncrease: isIncrease, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct MorphoBorrowActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .uint256, .string, .uint256, .address, .address, .bytes32, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let collateralAmount: Number
        public let collateralAssetSymbol: String
        public let collateralTokenPrice: Number
        public let collateralToken: EthAddress
        public let morpho: EthAddress
        public let morphoMarketId: Hex
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, collateralAmount: Number, collateralAssetSymbol: String, collateralTokenPrice: Number, collateralToken: EthAddress, morpho: EthAddress, morphoMarketId: Hex, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.collateralAmount = collateralAmount
         self.collateralAssetSymbol = collateralAssetSymbol
         self.collateralTokenPrice = collateralTokenPrice
         self.collateralToken = collateralToken
         self.morpho = morpho
         self.morphoMarketId = morphoMarketId
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple11(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(collateralAmount),
             .string(collateralAssetSymbol),
             .uint256(collateralTokenPrice),
             .address(collateralToken),
             .address(morpho),
             .bytes32(morphoMarketId),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> MorphoBorrowActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> MorphoBorrowActionContext {
            switch value {
            case let .tuple11(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(collateralAmount),
             .string(collateralAssetSymbol),
             .uint256(collateralTokenPrice),
             .address(collateralToken),
             .address(morpho),
             .bytes32(morphoMarketId),
             .uint256(price),
             .address(token)):
                return MorphoBorrowActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmount: collateralAmount, collateralAssetSymbol: collateralAssetSymbol, collateralTokenPrice: collateralTokenPrice, collateralToken: collateralToken, morpho: morpho, morphoMarketId: morphoMarketId, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct MorphoClaimRewardsActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.array(.uint256), .array(.string), .uint256, .array(.uint256), .array(.address)])

        public let amounts: [Number]
        public let assetSymbols: [String]
        public let chainId: Number
        public let prices: [Number]
        public let tokens: [EthAddress]

        public init(amounts: [Number], assetSymbols: [String], chainId: Number, prices: [Number], tokens: [EthAddress]) {
          self.amounts = amounts
         self.assetSymbols = assetSymbols
         self.chainId = chainId
         self.prices = prices
         self.tokens = tokens
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple5(.array(.uint256, amounts.map {
                        .uint256($0)
                    }),
             .array(.string, assetSymbols.map {
                        .string($0)
                    }),
             .uint256(chainId),
             .array(.uint256, prices.map {
                        .uint256($0)
                    }),
             .array(.address, tokens.map {
                        .address($0)
                    }))
        }

        public static func decode(hex: Hex) throws -> MorphoClaimRewardsActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> MorphoClaimRewardsActionContext {
            switch value {
            case let .tuple5(.array(.uint256, amounts),
             .array(.string, assetSymbols),
             .uint256(chainId),
             .array(.uint256, prices),
             .array(.address, tokens)):
                return MorphoClaimRewardsActionContext(amounts: amounts.map {
                        $0.asNumber!
                    }, assetSymbols: assetSymbols.map {
                        $0.asString!
                    }, chainId: chainId, prices: prices.map {
                        $0.asNumber!
                    }, tokens: tokens.map {
                        $0.asEthAddress!
                    })
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct MorphoRepayActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .uint256, .string, .uint256, .address, .address, .bytes32, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let collateralAmount: Number
        public let collateralAssetSymbol: String
        public let collateralTokenPrice: Number
        public let collateralToken: EthAddress
        public let morpho: EthAddress
        public let morphoMarketId: Hex
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, collateralAmount: Number, collateralAssetSymbol: String, collateralTokenPrice: Number, collateralToken: EthAddress, morpho: EthAddress, morphoMarketId: Hex, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.collateralAmount = collateralAmount
         self.collateralAssetSymbol = collateralAssetSymbol
         self.collateralTokenPrice = collateralTokenPrice
         self.collateralToken = collateralToken
         self.morpho = morpho
         self.morphoMarketId = morphoMarketId
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple11(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(collateralAmount),
             .string(collateralAssetSymbol),
             .uint256(collateralTokenPrice),
             .address(collateralToken),
             .address(morpho),
             .bytes32(morphoMarketId),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> MorphoRepayActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> MorphoRepayActionContext {
            switch value {
            case let .tuple11(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(collateralAmount),
             .string(collateralAssetSymbol),
             .uint256(collateralTokenPrice),
             .address(collateralToken),
             .address(morpho),
             .bytes32(morphoMarketId),
             .uint256(price),
             .address(token)):
                return MorphoRepayActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmount: collateralAmount, collateralAssetSymbol: collateralAssetSymbol, collateralTokenPrice: collateralTokenPrice, collateralToken: collateralToken, morpho: morpho, morphoMarketId: morphoMarketId, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct MorphoVaultSupplyActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let morphoVault: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, morphoVault: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.morphoVault = morphoVault
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(morphoVault),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> MorphoVaultSupplyActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> MorphoVaultSupplyActionContext {
            switch value {
            case let .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(morphoVault),
             .uint256(price),
             .address(token)):
                return MorphoVaultSupplyActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, morphoVault: morphoVault, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct MorphoVaultWithdrawActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let morphoVault: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, morphoVault: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.morphoVault = morphoVault
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(morphoVault),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> MorphoVaultWithdrawActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> MorphoVaultWithdrawActionContext {
            switch value {
            case let .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .address(morphoVault),
             .uint256(price),
             .address(token)):
                return MorphoVaultWithdrawActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, morphoVault: morphoVault, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct MultiActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.array(.string), .array(.bytes)])

        public let actionTypes: [String]
        public let actionContexts: [Hex]

        public init(actionTypes: [String], actionContexts: [Hex]) {
          self.actionTypes = actionTypes
         self.actionContexts = actionContexts
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple2(.array(.string, actionTypes.map {
                        .string($0)
                    }),
             .array(.bytes, actionContexts.map {
                        .bytes($0)
                    }))
        }

        public static func decode(hex: Hex) throws -> MultiActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> MultiActionContext {
            switch value {
            case let .tuple2(.array(.string, actionTypes),
             .array(.bytes, actionContexts)):
                return MultiActionContext(actionTypes: actionTypes.map {
                        $0.asString!
                    }, actionContexts: actionContexts.map {
                        $0.asHex!
                    })
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct QuotePayActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .uint256, .address, .bytes32, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let price: Number
        public let payee: EthAddress
        public let quoteId: Hex
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, price: Number, payee: EthAddress, quoteId: Hex, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.price = price
         self.payee = payee
         self.quoteId = quoteId
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple7(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(price),
             .address(payee),
             .bytes32(quoteId),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> QuotePayActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> QuotePayActionContext {
            switch value {
            case let .tuple7(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(price),
             .address(payee),
             .bytes32(quoteId),
             .address(token)):
                return QuotePayActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, price: price, payee: payee, quoteId: quoteId, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct RecurringSwapActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .uint256, .bool, .bool])

        public let chainId: Number
        public let inputAmount: Number
        public let inputAssetSymbol: String
        public let inputToken: EthAddress
        public let inputTokenPrice: Number
        public let outputAmount: Number
        public let outputAssetSymbol: String
        public let outputToken: EthAddress
        public let outputTokenPrice: Number
        public let interval: Number
        public let useChainlinkDataStream: Bool
        public let useFiller: Bool

        public init(chainId: Number, inputAmount: Number, inputAssetSymbol: String, inputToken: EthAddress, inputTokenPrice: Number, outputAmount: Number, outputAssetSymbol: String, outputToken: EthAddress, outputTokenPrice: Number, interval: Number, useChainlinkDataStream: Bool, useFiller: Bool) {
          self.chainId = chainId
         self.inputAmount = inputAmount
         self.inputAssetSymbol = inputAssetSymbol
         self.inputToken = inputToken
         self.inputTokenPrice = inputTokenPrice
         self.outputAmount = outputAmount
         self.outputAssetSymbol = outputAssetSymbol
         self.outputToken = outputToken
         self.outputTokenPrice = outputTokenPrice
         self.interval = interval
         self.useChainlinkDataStream = useChainlinkDataStream
         self.useFiller = useFiller
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple12(.uint256(chainId),
             .uint256(inputAmount),
             .string(inputAssetSymbol),
             .address(inputToken),
             .uint256(inputTokenPrice),
             .uint256(outputAmount),
             .string(outputAssetSymbol),
             .address(outputToken),
             .uint256(outputTokenPrice),
             .uint256(interval),
             .bool(useChainlinkDataStream),
             .bool(useFiller))
        }

        public static func decode(hex: Hex) throws -> RecurringSwapActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> RecurringSwapActionContext {
            switch value {
            case let .tuple12(.uint256(chainId),
             .uint256(inputAmount),
             .string(inputAssetSymbol),
             .address(inputToken),
             .uint256(inputTokenPrice),
             .uint256(outputAmount),
             .string(outputAssetSymbol),
             .address(outputToken),
             .uint256(outputTokenPrice),
             .uint256(interval),
             .bool(useChainlinkDataStream),
             .bool(useFiller)):
                return RecurringSwapActionContext(chainId: chainId, inputAmount: inputAmount, inputAssetSymbol: inputAssetSymbol, inputToken: inputToken, inputTokenPrice: inputTokenPrice, outputAmount: outputAmount, outputAssetSymbol: outputAssetSymbol, outputToken: outputToken, outputTokenPrice: outputTokenPrice, interval: interval, useChainlinkDataStream: useChainlinkDataStream, useFiller: useFiller)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct RepayActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .array(.uint256), .array(.string), .array(.uint256), .array(.address), .address, .uint256, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let collateralAmounts: [Number]
        public let collateralAssetSymbols: [String]
        public let collateralTokenPrices: [Number]
        public let collateralTokens: [EthAddress]
        public let comet: EthAddress
        public let price: Number
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, collateralAmounts: [Number], collateralAssetSymbols: [String], collateralTokenPrices: [Number], collateralTokens: [EthAddress], comet: EthAddress, price: Number, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.collateralAmounts = collateralAmounts
         self.collateralAssetSymbols = collateralAssetSymbols
         self.collateralTokenPrices = collateralTokenPrices
         self.collateralTokens = collateralTokens
         self.comet = comet
         self.price = price
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple10(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .array(.uint256, collateralAmounts.map {
                        .uint256($0)
                    }),
             .array(.string, collateralAssetSymbols.map {
                        .string($0)
                    }),
             .array(.uint256, collateralTokenPrices.map {
                        .uint256($0)
                    }),
             .array(.address, collateralTokens.map {
                        .address($0)
                    }),
             .address(comet),
             .uint256(price),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> RepayActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> RepayActionContext {
            switch value {
            case let .tuple10(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .array(.uint256, collateralAmounts),
             .array(.string, collateralAssetSymbols),
             .array(.uint256, collateralTokenPrices),
             .array(.address, collateralTokens),
             .address(comet),
             .uint256(price),
             .address(token)):
                return RepayActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmounts: collateralAmounts.map {
                        $0.asNumber!
                    }, collateralAssetSymbols: collateralAssetSymbols.map {
                        $0.asString!
                    }, collateralTokenPrices: collateralTokenPrices.map {
                        $0.asNumber!
                    }, collateralTokens: collateralTokens.map {
                        $0.asEthAddress!
                    }, comet: comet, price: price, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct SwapActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .array(.uint256), .array(.string), .array(.address), .array(.uint256), .array(.string), .uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .bool, .bool, .bool, .bool])

        public let chainId: Number
        public let feeAmounts: [Number]
        public let feeAssetSymbols: [String]
        public let feeTokens: [EthAddress]
        public let feeTokenPrices: [Number]
        public let feeDescriptions: [String]
        public let inputAmount: Number
        public let inputAssetSymbol: String
        public let inputToken: EthAddress
        public let inputTokenPrice: Number
        public let outputAmount: Number
        public let outputAssetSymbol: String
        public let outputToken: EthAddress
        public let outputTokenPrice: Number
        public let isExactOut: Bool
        public let isBuy: Bool
        public let isCappedMax: Bool
        public let useFiller: Bool

        public init(chainId: Number, feeAmounts: [Number], feeAssetSymbols: [String], feeTokens: [EthAddress], feeTokenPrices: [Number], feeDescriptions: [String], inputAmount: Number, inputAssetSymbol: String, inputToken: EthAddress, inputTokenPrice: Number, outputAmount: Number, outputAssetSymbol: String, outputToken: EthAddress, outputTokenPrice: Number, isExactOut: Bool, isBuy: Bool, isCappedMax: Bool, useFiller: Bool) {
          self.chainId = chainId
         self.feeAmounts = feeAmounts
         self.feeAssetSymbols = feeAssetSymbols
         self.feeTokens = feeTokens
         self.feeTokenPrices = feeTokenPrices
         self.feeDescriptions = feeDescriptions
         self.inputAmount = inputAmount
         self.inputAssetSymbol = inputAssetSymbol
         self.inputToken = inputToken
         self.inputTokenPrice = inputTokenPrice
         self.outputAmount = outputAmount
         self.outputAssetSymbol = outputAssetSymbol
         self.outputToken = outputToken
         self.outputTokenPrice = outputTokenPrice
         self.isExactOut = isExactOut
         self.isBuy = isBuy
         self.isCappedMax = isCappedMax
         self.useFiller = useFiller
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple18(.uint256(chainId),
             .array(.uint256, feeAmounts.map {
                        .uint256($0)
                    }),
             .array(.string, feeAssetSymbols.map {
                        .string($0)
                    }),
             .array(.address, feeTokens.map {
                        .address($0)
                    }),
             .array(.uint256, feeTokenPrices.map {
                        .uint256($0)
                    }),
             .array(.string, feeDescriptions.map {
                        .string($0)
                    }),
             .uint256(inputAmount),
             .string(inputAssetSymbol),
             .address(inputToken),
             .uint256(inputTokenPrice),
             .uint256(outputAmount),
             .string(outputAssetSymbol),
             .address(outputToken),
             .uint256(outputTokenPrice),
             .bool(isExactOut),
             .bool(isBuy),
             .bool(isCappedMax),
             .bool(useFiller))
        }

        public static func decode(hex: Hex) throws -> SwapActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> SwapActionContext {
            switch value {
            case let .tuple18(.uint256(chainId),
             .array(.uint256, feeAmounts),
             .array(.string, feeAssetSymbols),
             .array(.address, feeTokens),
             .array(.uint256, feeTokenPrices),
             .array(.string, feeDescriptions),
             .uint256(inputAmount),
             .string(inputAssetSymbol),
             .address(inputToken),
             .uint256(inputTokenPrice),
             .uint256(outputAmount),
             .string(outputAssetSymbol),
             .address(outputToken),
             .uint256(outputTokenPrice),
             .bool(isExactOut),
             .bool(isBuy),
             .bool(isCappedMax),
             .bool(useFiller)):
                return SwapActionContext(chainId: chainId, feeAmounts: feeAmounts.map {
                        $0.asNumber!
                    }, feeAssetSymbols: feeAssetSymbols.map {
                        $0.asString!
                    }, feeTokens: feeTokens.map {
                        $0.asEthAddress!
                    }, feeTokenPrices: feeTokenPrices.map {
                        $0.asNumber!
                    }, feeDescriptions: feeDescriptions.map {
                        $0.asString!
                    }, inputAmount: inputAmount, inputAssetSymbol: inputAssetSymbol, inputToken: inputToken, inputTokenPrice: inputTokenPrice, outputAmount: outputAmount, outputAssetSymbol: outputAssetSymbol, outputToken: outputToken, outputTokenPrice: outputTokenPrice, isExactOut: isExactOut, isBuy: isBuy, isCappedMax: isCappedMax, useFiller: useFiller)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct TransferActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .uint256, .uint256, .address, .address])

        public let amount: Number
        public let assetSymbol: String
        public let chainId: Number
        public let price: Number
        public let recipient: EthAddress
        public let token: EthAddress

        public init(amount: Number, assetSymbol: String, chainId: Number, price: Number, recipient: EthAddress, token: EthAddress) {
          self.amount = amount
         self.assetSymbol = assetSymbol
         self.chainId = chainId
         self.price = price
         self.recipient = recipient
         self.token = token
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(price),
             .address(recipient),
             .address(token))
        }

        public static func decode(hex: Hex) throws -> TransferActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> TransferActionContext {
            switch value {
            case let .tuple6(.uint256(amount),
             .string(assetSymbol),
             .uint256(chainId),
             .uint256(price),
             .address(recipient),
             .address(token)):
                return TransferActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, price: price, recipient: recipient, token: token)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct UnloopLongActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])

        public let backingAssetSymbol: String
        public let backingToken: EthAddress
        public let backingTokenPrice: Number
        public let minSwapBackingAmount: Number
        public let backingAmountToExit: Number
        public let chainId: Number
        public let exposureAmount: Number
        public let exposureAssetSymbol: String
        public let exposureToken: EthAddress
        public let exposureTokenPrice: Number
        public let swapVenue: String
        public let borrowVenue: String
        public let borrowMarketId: Hex
        public let feeAmount: Number
        public let feeAssetSymbol: String
        public let feeToken: EthAddress
        public let feeTokenPrice: Number

        public init(backingAssetSymbol: String, backingToken: EthAddress, backingTokenPrice: Number, minSwapBackingAmount: Number, backingAmountToExit: Number, chainId: Number, exposureAmount: Number, exposureAssetSymbol: String, exposureToken: EthAddress, exposureTokenPrice: Number, swapVenue: String, borrowVenue: String, borrowMarketId: Hex, feeAmount: Number, feeAssetSymbol: String, feeToken: EthAddress, feeTokenPrice: Number) {
          self.backingAssetSymbol = backingAssetSymbol
         self.backingToken = backingToken
         self.backingTokenPrice = backingTokenPrice
         self.minSwapBackingAmount = minSwapBackingAmount
         self.backingAmountToExit = backingAmountToExit
         self.chainId = chainId
         self.exposureAmount = exposureAmount
         self.exposureAssetSymbol = exposureAssetSymbol
         self.exposureToken = exposureToken
         self.exposureTokenPrice = exposureTokenPrice
         self.swapVenue = swapVenue
         self.borrowVenue = borrowVenue
         self.borrowMarketId = borrowMarketId
         self.feeAmount = feeAmount
         self.feeAssetSymbol = feeAssetSymbol
         self.feeToken = feeToken
         self.feeTokenPrice = feeTokenPrice
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple17(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(minSwapBackingAmount),
             .uint256(backingAmountToExit),
             .uint256(chainId),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice))
        }

        public static func decode(hex: Hex) throws -> UnloopLongActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> UnloopLongActionContext {
            switch value {
            case let .tuple17(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(minSwapBackingAmount),
             .uint256(backingAmountToExit),
             .uint256(chainId),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice)):
                return UnloopLongActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, minSwapBackingAmount: minSwapBackingAmount, backingAmountToExit: backingAmountToExit, chainId: chainId, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct UnloopShortActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])

        public let backingAssetSymbol: String
        public let backingToken: EthAddress
        public let backingTokenPrice: Number
        public let maxSwapBackingAmount: Number
        public let backingAmountToExit: Number
        public let chainId: Number
        public let exposureAmount: Number
        public let exposureAssetSymbol: String
        public let exposureToken: EthAddress
        public let exposureTokenPrice: Number
        public let swapVenue: String
        public let borrowVenue: String
        public let borrowMarketId: Hex
        public let feeAmount: Number
        public let feeAssetSymbol: String
        public let feeToken: EthAddress
        public let feeTokenPrice: Number

        public init(backingAssetSymbol: String, backingToken: EthAddress, backingTokenPrice: Number, maxSwapBackingAmount: Number, backingAmountToExit: Number, chainId: Number, exposureAmount: Number, exposureAssetSymbol: String, exposureToken: EthAddress, exposureTokenPrice: Number, swapVenue: String, borrowVenue: String, borrowMarketId: Hex, feeAmount: Number, feeAssetSymbol: String, feeToken: EthAddress, feeTokenPrice: Number) {
          self.backingAssetSymbol = backingAssetSymbol
         self.backingToken = backingToken
         self.backingTokenPrice = backingTokenPrice
         self.maxSwapBackingAmount = maxSwapBackingAmount
         self.backingAmountToExit = backingAmountToExit
         self.chainId = chainId
         self.exposureAmount = exposureAmount
         self.exposureAssetSymbol = exposureAssetSymbol
         self.exposureToken = exposureToken
         self.exposureTokenPrice = exposureTokenPrice
         self.swapVenue = swapVenue
         self.borrowVenue = borrowVenue
         self.borrowMarketId = borrowMarketId
         self.feeAmount = feeAmount
         self.feeAssetSymbol = feeAssetSymbol
         self.feeToken = feeToken
         self.feeTokenPrice = feeTokenPrice
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple17(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(maxSwapBackingAmount),
             .uint256(backingAmountToExit),
             .uint256(chainId),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice))
        }

        public static func decode(hex: Hex) throws -> UnloopShortActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> UnloopShortActionContext {
            switch value {
            case let .tuple17(.string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(maxSwapBackingAmount),
             .uint256(backingAmountToExit),
             .uint256(chainId),
             .uint256(exposureAmount),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(swapVenue),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .uint256(feeAmount),
             .string(feeAssetSymbol),
             .address(feeToken),
             .uint256(feeTokenPrice)):
                return UnloopShortActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, maxSwapBackingAmount: maxSwapBackingAmount, backingAmountToExit: backingAmountToExit, chainId: chainId, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct WithdrawAndBorrowActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .uint256, .array(.uint256), .array(.uint256), .array(.address), .address, .uint256, .address, .uint256])

        public let borrowAmount: Number
        public let chainId: Number
        public let collateralAmounts: [Number]
        public let collateralTokenPrices: [Number]
        public let collateralTokens: [EthAddress]
        public let comet: EthAddress
        public let price: Number
        public let token: EthAddress
        public let withdrawAmount: Number

        public init(borrowAmount: Number, chainId: Number, collateralAmounts: [Number], collateralTokenPrices: [Number], collateralTokens: [EthAddress], comet: EthAddress, price: Number, token: EthAddress, withdrawAmount: Number) {
          self.borrowAmount = borrowAmount
         self.chainId = chainId
         self.collateralAmounts = collateralAmounts
         self.collateralTokenPrices = collateralTokenPrices
         self.collateralTokens = collateralTokens
         self.comet = comet
         self.price = price
         self.token = token
         self.withdrawAmount = withdrawAmount
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple9(.uint256(borrowAmount),
             .uint256(chainId),
             .array(.uint256, collateralAmounts.map {
                        .uint256($0)
                    }),
             .array(.uint256, collateralTokenPrices.map {
                        .uint256($0)
                    }),
             .array(.address, collateralTokens.map {
                        .address($0)
                    }),
             .address(comet),
             .uint256(price),
             .address(token),
             .uint256(withdrawAmount))
        }

        public static func decode(hex: Hex) throws -> WithdrawAndBorrowActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> WithdrawAndBorrowActionContext {
            switch value {
            case let .tuple9(.uint256(borrowAmount),
             .uint256(chainId),
             .array(.uint256, collateralAmounts),
             .array(.uint256, collateralTokenPrices),
             .array(.address, collateralTokens),
             .address(comet),
             .uint256(price),
             .address(token),
             .uint256(withdrawAmount)):
                return WithdrawAndBorrowActionContext(borrowAmount: borrowAmount, chainId: chainId, collateralAmounts: collateralAmounts.map {
                        $0.asNumber!
                    }, collateralTokenPrices: collateralTokenPrices.map {
                        $0.asNumber!
                    }, collateralTokens: collateralTokens.map {
                        $0.asEthAddress!
                    }, comet: comet, price: price, token: token, withdrawAmount: withdrawAmount)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct WithdrawBackingTokenActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .string, .bytes32, .bool])

        public let amount: Number
        public let backingAssetSymbol: String
        public let backingToken: EthAddress
        public let backingTokenPrice: Number
        public let chainId: Number
        public let exposureAssetSymbol: String
        public let exposureToken: EthAddress
        public let exposureTokenPrice: Number
        public let borrowVenue: String
        public let borrowMarketId: Hex
        public let isShort: Bool

        public init(amount: Number, backingAssetSymbol: String, backingToken: EthAddress, backingTokenPrice: Number, chainId: Number, exposureAssetSymbol: String, exposureToken: EthAddress, exposureTokenPrice: Number, borrowVenue: String, borrowMarketId: Hex, isShort: Bool) {
          self.amount = amount
         self.backingAssetSymbol = backingAssetSymbol
         self.backingToken = backingToken
         self.backingTokenPrice = backingTokenPrice
         self.chainId = chainId
         self.exposureAssetSymbol = exposureAssetSymbol
         self.exposureToken = exposureToken
         self.exposureTokenPrice = exposureTokenPrice
         self.borrowVenue = borrowVenue
         self.borrowMarketId = borrowMarketId
         self.isShort = isShort
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple11(.uint256(amount),
             .string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(chainId),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .bool(isShort))
        }

        public static func decode(hex: Hex) throws -> WithdrawBackingTokenActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> WithdrawBackingTokenActionContext {
            switch value {
            case let .tuple11(.uint256(amount),
             .string(backingAssetSymbol),
             .address(backingToken),
             .uint256(backingTokenPrice),
             .uint256(chainId),
             .string(exposureAssetSymbol),
             .address(exposureToken),
             .uint256(exposureTokenPrice),
             .string(borrowVenue),
             .bytes32(borrowMarketId),
             .bool(isShort)):
                return WithdrawBackingTokenActionContext(amount: amount, backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, chainId: chainId, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, isShort: isShort)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public struct WrapOrUnwrapActionContext: Equatable, Sendable {
        public static let schema: ABI.Schema = ABI.Schema.tuple([.uint256, .uint256, .address, .string, .string])

        public let chainId: Number
        public let amount: Number
        public let token: EthAddress
        public let fromAssetSymbol: String
        public let toAssetSymbol: String

        public init(chainId: Number, amount: Number, token: EthAddress, fromAssetSymbol: String, toAssetSymbol: String) {
          self.chainId = chainId
         self.amount = amount
         self.token = token
         self.fromAssetSymbol = fromAssetSymbol
         self.toAssetSymbol = toAssetSymbol
        }

        public var encoded: Hex {
            asValue.encoded
        }

        public var asValue: ABI.Value {
            .tuple5(.uint256(chainId),
             .uint256(amount),
             .address(token),
             .string(fromAssetSymbol),
             .string(toAssetSymbol))
        }

        public static func decode(hex: Hex) throws -> WrapOrUnwrapActionContext {
            if let value = try? schema.decode(hex) {
                return try decodeValue(value)
            }
  // both versions are valid encodings of tuples with dynamic fields ( bytes or string ), so try both decodings
  if case let .tuple1(wrappedValue) = try? ABI.Schema.tuple([schema]).decode(hex) {
      return try decodeValue(wrappedValue)
  }
  // retry original to throw the error
  return try decodeValue(schema.decode(hex))


        }

        public static func decodeValue(_ value: ABI.Value) throws -> WrapOrUnwrapActionContext {
            switch value {
            case let .tuple5(.uint256(chainId),
             .uint256(amount),
             .address(token),
             .string(fromAssetSymbol),
             .string(toAssetSymbol)):
                return WrapOrUnwrapActionContext(chainId: chainId, amount: amount, token: token, fromAssetSymbol: fromAssetSymbol, toAssetSymbol: toAssetSymbol)
            default:
                throw ABI.DecodeError.mismatchedType(value.schema, schema)
            }
        }
    }
    public static let creationCode: Hex = "0x608060405234602057600e6024565b6147fa61002f8239308150506147fa90f35b602a565b60405190565b5f80fdfe60806040526004361015610013575b611f8a565b61001d5f356101cc565b80630543a804146101c7578063129d57b9146101c257806313a3c45b146101bd57806315745b1e146101b857806317d88853146101b357806322f30261146101ae5780632b30b3dd146101a95780633bdf833f146101a457806349d9db721461019f5780635434c6da1461019a57806355354eaf1461019557806357630a5d14610190578063638f48801461018b5780637b5ea6d8146101865780638258f98714610181578063831dc5f71461017c5780638a978a35146101775780638dadfaa11461017257806390208d3b1461016d5780639a953855146101685780639fca66f414610163578063aa8f056e1461015e578063b5e5bc1c14610159578063c48897ec14610154578063c9bec8711461014f578063cc7e92e81461014a5763e67e97350361000e57611f5f565b611eaf565b611d91565b611be1565b611ac6565b611a0e565b611956565b6117ba565b61168b565b611570565b611460565b6112b0565b6111f8565b61112e565b611076565b610fc6565b610e0f565b610d1c565b610c0c565b610b62565b610996565b6107fa565b610742565b61068a565b6105d2565b61057f565b610395565b60e01c90565b60405190565b5f80fd5b5f9103126101e657565b6101d8565b90565b6101f7906101eb565b9052565b5190565b60209181520190565b90825f9392825e0152565b601f801991011690565b61023c61024560209361024a93610233816101fb565b938480936101ff565b95869101610208565b610213565b0190565b73ffffffffffffffffffffffffffffffffffffffff1690565b6102709061024e565b90565b61027c90610267565b9052565b90565b61028c90610280565b9052565b151590565b61029e90610290565b9052565b9061037a906101408061035b6103236102db61016086016102c95f8a01515f8901906101ee565b6020890151878203602089015261021d565b6102ed60408901516040880190610273565b6102ff606089015160608801906101ee565b610311608089015160808801906101ee565b60a088015186820360a088015261021d565b61033560c088015160c0870190610273565b61034760e088015160e08701906101ee565b61010087015185820361010087015261021d565b94610370610120820151610120860190610283565b0151910190610295565b90565b6103929160208201915f8184039101526102a2565b90565b6103a03660046101dc565b6103bc6103ab6121d4565b6103b36101d2565b9182918261037d565b0390f35b5190565b60209181520190565b60200190565b906103e0816020936101ee565b0190565b60200190565b906104076104016103fa846103c0565b80936103c4565b926103cd565b905f5b8181106104175750505090565b90919261043061042a60019286516103d3565b946103e4565b910191909161040a565b5190565b60209181520190565b60200190565b9061045a81602093610273565b0190565b60200190565b9061048161047b6104748461043a565b809361043e565b92610447565b905f5b8181106104915750505090565b9091926104aa6104a4600192865161044d565b9461045e565b9101919091610484565b9061056490610100806105236105116104ff61012086016104db5f8a01515f8901906101ee565b6104ed60208a015160208901906101ee565b604089015187820360408901526103ea565b606088015186820360608801526103ea565b60808701518582036080870152610464565b9461053660a082015160a0860190610273565b61054860c082015160c08601906101ee565b61055a60e082015160e0860190610273565b01519101906101ee565b90565b61057c9160208201915f8184039101526104b4565b90565b61058a3660046101dc565b6105a661059561234f565b61059d6101d2565b91829182610567565b0390f35b905f806105bb9301519101906101ee565b565b91906105d0905f602085019401906105aa565b565b6105dd3660046101dc565b6105f96105e861245f565b6105f06101d2565b918291826105bd565b0390f35b9061066f9060a08061062e60c0840161061c5f8801515f8701906101ee565b6020870151858203602087015261021d565b94610641604082015160408601906101ee565b61065360608201516060860190610273565b610665608082015160808601906101ee565b0151910190610273565b90565b6106879160208201915f8184039101526105fd565b90565b6106953660046101dc565b6106b16106a06125ab565b6106a86101d2565b91829182610672565b0390f35b906107279060a0806106e660c084016106d45f8801515f8701906101ee565b6020870151858203602087015261021d565b946106f9604082015160408601906101ee565b61070b606082015160608601906101ee565b61071d60808201516080860190610273565b0151910190610273565b90565b61073f9160208201915f8184039101526106b5565b90565b61074d3660046101dc565b6107696107586126f7565b6107606101d2565b9182918261072a565b0390f35b906107df9060a08061079e60c0840161078c5f8801515f8701906101ee565b6020870151858203602087015261021d565b946107b1604082015160408601906101ee565b6107c360608201516060860190610273565b6107d5608082015160808601906101ee565b0151910190610273565b90565b6107f79160208201915f81840391015261076d565b90565b6108053660046101dc565b610821610810612843565b6108186101d2565b918291826107e2565b0390f35b9061097b906102008061095c61092061090c6108d061085261022088015f8b01518982035f8b015261021d565b61086460208b015160208a0190610273565b61087660408b015160408a01906101ee565b61088860608b015160608a01906101ee565b61089a60808b015160808a01906101ee565b6108ac60a08b015160a08a01906101ee565b6108be60c08b015160c08a01906101ee565b60e08a015188820360e08a015261021d565b6108e46101008a0151610100890190610273565b6108f86101208a01516101208901906101ee565b61014089015187820361014089015261021d565b61016088015186820361016088015261021d565b610934610180880151610180870190610283565b6109486101a08801516101a08701906101ee565b6101c08701518582036101c087015261021d565b946109716101e08201516101e0860190610273565b01519101906101ee565b90565b6109939160208201915f818403910152610825565b90565b6109a13660046101dc565b6109bd6109ac612a21565b6109b46101d2565b9182918261097e565b0390f35b5190565b60209181520190565b60200190565b906109de9161021d565b90565b60200190565b906109fb6109f4836109c1565b80926109c5565b9081610a0c602083028401946109ce565b925f915b838310610a1f57505050505090565b90919293946020610a41610a3b838560019503875289516109d4565b976109e1565b9301930191939290610a10565b5190565b60209181520190565b60200190565b5190565b60209181520190565b610a8d610a96602093610a9b93610a8481610a61565b93848093610a65565b95869101610208565b610213565b0190565b90610aa991610a6e565b90565b60200190565b90610ac6610abf83610a4e565b8092610a52565b9081610ad760208302840194610a5b565b925f915b838310610aea57505050505090565b90919293946020610b0c610b0683856001950387528951610a9f565b97610aac565b9301930191939290610adb565b610b47916020610b36604083015f8501518482035f8601526109e7565b920151906020818403910152610ab2565b90565b610b5f9160208201915f818403910152610b19565b90565b610b6d3660046101dc565b610b89610b78612b47565b610b806101d2565b91829182610b4a565b0390f35b610bf1916080610be060a08301610baa5f8601515f8601906101ee565b610bbc602086015160208601906101ee565b610bce60408601516040860190610273565b6060850151848203606086015261021d565b92015190608081840391015261021d565b90565b610c099160208201915f818403910152610b8d565b90565b610c173660046101dc565b610c33610c22612c87565b610c2a6101d2565b91829182610bf4565b0390f35b90610d019061012080610cd0610cbe610cac610c9a610c766101408801610c645f8c01515f8b01906101ee565b60208b015189820360208b015261021d565b610c8860408b015160408a01906101ee565b60608a015188820360608a01526103ea565b608089015187820360808901526109e7565b60a088015186820360a08801526103ea565b60c087015185820360c0870152610464565b94610ce360e082015160e0860190610273565b610cf76101008201516101008601906101ee565b0151910190610273565b90565b610d199160208201915f818403910152610c37565b90565b610d273660046101dc565b610d43610d32612e04565b610d3a6101d2565b91829182610d04565b0390f35b90610df49061010080610d7d610d6b61012085015f8801518682035f88015261021d565b6020870151858203602087015261021d565b94610d90604082015160408601906101ee565b610da2606082015160608601906101ee565b610db4608082015160808601906101ee565b610dc660a082015160a08601906101ee565b610dd860c082015160c08601906101ee565b610dea60e082015160e0860190610273565b0151910190610273565b90565b610e0c9160208201915f818403910152610d47565b90565b610e1a3660046101dc565b610e36610e25612f75565b610e2d6101d2565b91829182610df7565b0390f35b90610fab9061022080610f3c610eec610ec8610eb6610ea4610e92610e808b610e6e5f6102408d019201515f8d01906101ee565b60208d01518b820360208d01526103ea565b60408c01518a820360408c01526109e7565b60608b015189820360608b0152610464565b60808a015188820360808a01526103ea565b60a089015187820360a08901526109e7565b610eda60c089015160c08801906101ee565b60e088015186820360e088015261021d565b610f00610100880151610100870190610273565b610f146101208801516101208701906101ee565b610f286101408801516101408701906101ee565b61016087015185820361016087015261021d565b94610f51610180820151610180860190610273565b610f656101a08201516101a08601906101ee565b610f796101c08201516101c0860190610295565b610f8d6101e08201516101e0860190610295565b610fa1610200820151610200860190610295565b0151910190610295565b90565b610fc39160208201915f818403910152610e3a565b90565b610fd13660046101dc565b610fed610fdc613160565b610fe46101d2565b91829182610fae565b0390f35b61105b91608061104a61102661101460a085015f8701518682035f8801526103ea565b602086015185820360208701526109e7565b611038604086015160408601906101ee565b606085015184820360608601526103ea565b920151906080818403910152610464565b90565b6110739160208201915f818403910152610ff1565b90565b6110813660046101dc565b61109d61108c6132a0565b6110946101d2565b9182918261105e565b0390f35b906111139060a0806110d260c084016110c05f8801515f8701906101ee565b6020870151858203602087015261021d565b946110e5604082015160408601906101ee565b6110f760608201516060860190610273565b611109608082015160808601906101ee565b0151910190610273565b90565b61112b9160208201915f8184039101526110a1565b90565b6111393660046101dc565b6111556111446133ec565b61114c6101d2565b91829182611116565b0390f35b906111dd9060c08061118a60e084016111785f8801515f8701906101ee565b6020870151858203602087015261021d565b9461119d604082015160408601906101ee565b6111af606082015160608601906101ee565b6111c160808201516080860190610273565b6111d360a082015160a0860190610283565b0151910190610273565b90565b6111f59160208201915f818403910152611159565b90565b6112033660046101dc565b61121f61120e613544565b6112166101d2565b918291826111e0565b0390f35b906112959060a08061125460c084016112425f8801515f8701906101ee565b6020870151858203602087015261021d565b94611267604082015160408601906101ee565b61127960608201516060860190610273565b61128b608082015160808601906101ee565b0151910190610273565b90565b6112ad9160208201915f818403910152611223565b90565b6112bb3660046101dc565b6112d76112c6613690565b6112ce6101d2565b91829182611298565b0390f35b9061144590610220806114266113ea6113d661139a61130861024088015f8b01518982035f8b015261021d565b61131a60208b015160208a0190610273565b61132c60408b015160408a01906101ee565b61133e60608b015160608a01906101ee565b61135060808b015160808a01906101ee565b61136260a08b015160a08a01906101ee565b61137460c08b015160c08a0190610295565b61138660e08b015160e08a01906101ee565b6101008a01518882036101008a015261021d565b6113ae6101208a0151610120890190610273565b6113c26101408a01516101408901906101ee565b61016089015187820361016089015261021d565b61018088015186820361018088015261021d565b6113fe6101a08801516101a0870190610283565b6114126101c08801516101c08701906101ee565b6101e08701518582036101e087015261021d565b9461143b610200820151610200860190610273565b01519101906101ee565b90565b61145d9160208201915f8184039101526112db565b90565b61146b3660046101dc565b61148761147661387b565b61147e6101d2565b91829182611448565b0390f35b9061155590610120806115246115126115006114ee6114ca61014088016114b85f8c01515f8b01906101ee565b60208b015189820360208b015261021d565b6114dc60408b015160408a01906101ee565b60608a015188820360608a01526103ea565b608089015187820360808901526109e7565b60a088015186820360a08801526103ea565b60c087015185820360c0870152610464565b9461153760e082015160e0860190610273565b61154b6101008201516101008601906101ee565b0151910190610273565b90565b61156d9160208201915f81840391015261148b565b90565b61157b3660046101dc565b6115976115866139f8565b61158e6101d2565b91829182611558565b0390f35b9061167090610140806116076115d161016085016115bf5f8901515f8801906101ee565b6020880151868203602088015261021d565b6115e3604088015160408701906101ee565b6115f5606088015160608701906101ee565b6080870151858203608087015261021d565b9461161a60a082015160a08601906101ee565b61162c60c082015160c0860190610273565b61163e60e082015160e0860190610273565b611652610100820151610100860190610283565b6116666101208201516101208601906101ee565b0151910190610273565b90565b6116889160208201915f81840391015261159b565b90565b6116963660046101dc565b6116b26116a1613b81565b6116a96101d2565b91829182611673565b0390f35b9061179f90610160806117466116fe61018085016116da5f8901515f8801906101ee565b6116ec602089015160208801906101ee565b6040880151868203604088015261021d565b61171060608801516060870190610273565b611722608088015160808701906101ee565b61173460a088015160a08701906101ee565b60c087015185820360c087015261021d565b9461175960e082015160e0860190610273565b61176d6101008201516101008601906101ee565b6117816101208201516101208601906101ee565b611795610140820151610140860190610295565b0151910190610295565b90565b6117b79160208201915f8184039101526116b6565b90565b6117c53660046101dc565b6117e16117d0613d16565b6117d86101d2565b918291826117a2565b0390f35b9061193b906102008061191c6118e06118cc61189061181261022088015f8b01518982035f8b015261021d565b61182460208b015160208a0190610273565b61183660408b015160408a01906101ee565b61184860608b015160608a01906101ee565b61185a60808b015160808a01906101ee565b61186c60a08b015160a08a01906101ee565b61187e60c08b015160c08a01906101ee565b60e08a015188820360e08a015261021d565b6118a46101008a0151610100890190610273565b6118b86101208a01516101208901906101ee565b61014089015187820361014089015261021d565b61016088015186820361016088015261021d565b6118f4610180880151610180870190610283565b6119086101a08801516101a08701906101ee565b6101c08701518582036101c087015261021d565b946119316101e08201516101e0860190610273565b01519101906101ee565b90565b6119539160208201915f8184039101526117e5565b90565b6119613660046101dc565b61197d61196c613ef4565b6119746101d2565b9182918261193e565b0390f35b906119f39060a0806119b260c084016119a05f8801515f8701906101ee565b6020870151858203602087015261021d565b946119c5604082015160408601906101ee565b6119d760608201516060860190610273565b6119e9608082015160808601906101ee565b0151910190610273565b90565b611a0b9160208201915f818403910152611981565b90565b611a193660046101dc565b611a35611a24614040565b611a2c6101d2565b918291826119f6565b0390f35b90611aab9060a080611a6a60c08401611a585f8801515f8701906101ee565b6020870151858203602087015261021d565b94611a7d604082015160408601906101ee565b611a8f60608201516060860190610273565b611aa1608082015160808601906101ee565b0151910190610273565b90565b611ac39160208201915f818403910152611a39565b90565b611ad13660046101dc565b611aed611adc61418c565b611ae46101d2565b91829182611aae565b0390f35b90611bc69061014080611b5d611b276101608501611b155f8901515f8801906101ee565b6020880151868203602088015261021d565b611b39604088015160408701906101ee565b611b4b606088015160608701906101ee565b6080870151858203608087015261021d565b94611b7060a082015160a08601906101ee565b611b8260c082015160c0860190610273565b611b9460e082015160e0860190610273565b611ba8610100820151610100860190610283565b611bbc6101208201516101208601906101ee565b0151910190610273565b90565b611bde9160208201915f818403910152611af1565b90565b611bec3660046101dc565b611c08611bf7614315565b611bff6101d2565b91829182611bc9565b0390f35b90611d769061022080611d57611d1b611d07611ccb611c3961024088015f8b01518982035f8b015261021d565b611c4b60208b015160208a0190610273565b611c5d60408b015160408a01906101ee565b611c6f60608b015160608a01906101ee565b611c8160808b015160808a01906101ee565b611c9360a08b015160a08a01906101ee565b611ca560c08b015160c08a0190610295565b611cb760e08b015160e08a01906101ee565b6101008a01518882036101008a015261021d565b611cdf6101208a0151610120890190610273565b611cf36101408a01516101408901906101ee565b61016089015187820361016089015261021d565b61018088015186820361018088015261021d565b611d2f6101a08801516101a0870190610283565b611d436101c08801516101c08701906101ee565b6101e08701518582036101e087015261021d565b94611d6c610200820151610200860190610273565b01519101906101ee565b90565b611d8e9160208201915f818403910152611c0c565b90565b611d9c3660046101dc565b611db8611da7614500565b611daf6101d2565b91829182611d79565b0390f35b90611e949061014080611e75611e3d611df56101608601611de35f8a01515f8901906101ee565b6020890151878203602089015261021d565b611e0760408901516040880190610273565b611e19606089015160608801906101ee565b611e2b608089015160808801906101ee565b60a088015186820360a088015261021d565b611e4f60c088015160c0870190610273565b611e6160e088015160e08701906101ee565b61010087015185820361010087015261021d565b94611e8a610120820151610120860190610283565b0151910190610295565b90565b611eac9160208201915f818403910152611dbc565b90565b611eba3660046101dc565b611ed6611ec5614689565b611ecd6101d2565b91829182611e97565b0390f35b611f44916080611f33611f0f611efd60a085015f8701518682035f8801526103ea565b602086015185820360208701526109e7565b611f21604086015160408601906101ee565b606085015184820360608601526103ea565b920151906080818403910152610464565b90565b611f5c9160208201915f818403910152611eda565b90565b611f6a3660046101dc565b611f86611f756147c9565b611f7d6101d2565b91829182611f47565b0390f35b5f80fd5b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b90611fc590610213565b810190811067ffffffffffffffff821117611fdf57604052565b611f8e565b90611ff7611ff06101d2565b9283611fbb565b565b612004610160611fe4565b90565b5f90565b606090565b5f90565b5f90565b5f90565b612024611ff9565b906020808080808080808080808c61203a612007565b81520161204561200b565b815201612050612010565b81520161205b612007565b815201612066612007565b81520161207161200b565b81520161207c612010565b815201612087612007565b81520161209261200b565b81520161209d612014565b8152016120a8612018565b81525050565b6120b661201c565b90565b90565b90565b6120d36120ce6120d8926120b9565b6120bc565b6101eb565b90565b67ffffffffffffffff81116120f35760208091020190565b611f8e565b9061210a612105836120db565b611fe4565b918252565b61211761201c565b90565b5f5b82811061212857505050565b60209061213361210f565b818401520161211c565b9061216261214a836120f8565b9260208061215886936120db565b920191039061211a565b565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52603260045260245ffd5b5190565b9061219f82612191565b8110156121b0576020809102010190565b612164565b90565b6121cc6121c76121d1926121b5565b6120bc565b6101eb565b90565b6121dc6120ae565b506122016121f26121ed60016120bf565b61213d565b6121fb5f6121b8565b90612195565b5190565b612210610120611fe4565b90565b606090565b606090565b612225612205565b90602080808080808080808a612239612007565b815201612244612007565b81520161224f612213565b81520161225a612213565b815201612265612218565b815201612270612010565b81520161227b612007565b815201612286612010565b815201612291612007565b81525050565b61229f61221d565b90565b67ffffffffffffffff81116122ba5760208091020190565b611f8e565b906122d16122cc836122a2565b611fe4565b918252565b6122de61221d565b90565b5f5b8281106122ef57505050565b6020906122fa6122d6565b81840152016122e3565b90612329612311836122bf565b9260208061231f86936122a2565b92019103906122e1565b565b5190565b906123398261232b565b81101561234a576020809102010190565b612164565b612357612297565b5061237c61236d61236860016120bf565b612304565b6123765f6121b8565b9061232f565b5190565b61238a6020611fe4565b90565b612395612380565b906020826123a1612007565b81525050565b6123af61238d565b90565b67ffffffffffffffff81116123ca5760208091020190565b611f8e565b906123e16123dc836123b2565b611fe4565b918252565b6123ee61238d565b90565b5f5b8281106123ff57505050565b60209061240a6123e6565b81840152016123f3565b90612439612421836123cf565b9260208061242f86936123b2565b92019103906123f1565b565b5190565b906124498261243b565b81101561245a576020809102010190565b612164565b6124676123a7565b5061248c61247d61247860016120bf565b612414565b6124865f6121b8565b9061243f565b5190565b61249a60c0611fe4565b90565b6124a5612490565b9060208080808080876124b6612007565b8152016124c161200b565b8152016124cc612007565b8152016124d7612010565b8152016124e2612007565b8152016124ed612010565b81525050565b6124fb61249d565b90565b67ffffffffffffffff81116125165760208091020190565b611f8e565b9061252d612528836124fe565b611fe4565b918252565b61253a61249d565b90565b5f5b82811061254b57505050565b602090612556612532565b818401520161253f565b9061258561256d8361251b565b9260208061257b86936124fe565b920191039061253d565b565b5190565b9061259582612587565b8110156125a6576020809102010190565b612164565b6125b36124f3565b506125d86125c96125c460016120bf565b612560565b6125d25f6121b8565b9061258b565b5190565b6125e660c0611fe4565b90565b6125f16125dc565b906020808080808087612602612007565b81520161260d61200b565b815201612618612007565b815201612623612007565b81520161262e612010565b815201612639612010565b81525050565b6126476125e9565b90565b67ffffffffffffffff81116126625760208091020190565b611f8e565b906126796126748361264a565b611fe4565b918252565b6126866125e9565b90565b5f5b82811061269757505050565b6020906126a261267e565b818401520161268b565b906126d16126b983612667565b926020806126c7869361264a565b9201910390612689565b565b5190565b906126e1826126d3565b8110156126f2576020809102010190565b612164565b6126ff61263f565b5061272461271561271060016120bf565b6126ac565b61271e5f6121b8565b906126d7565b5190565b61273260c0611fe4565b90565b61273d612728565b90602080808080808761274e612007565b81520161275961200b565b815201612764612007565b81520161276f612010565b81520161277a612007565b815201612785612010565b81525050565b612793612735565b90565b67ffffffffffffffff81116127ae5760208091020190565b611f8e565b906127c56127c083612796565b611fe4565b918252565b6127d2612735565b90565b5f5b8281106127e357505050565b6020906127ee6127ca565b81840152016127d7565b9061281d612805836127b3565b926020806128138693612796565b92019103906127d5565b565b5190565b9061282d8261281f565b81101561283e576020809102010190565b612164565b61284b61278b565b5061287061286161285c60016120bf565b6127f8565b61286a5f6121b8565b90612823565b5190565b61287f610220611fe4565b90565b61288a612874565b908161289461200b565b81526020016128a1612010565b81526020016128ae612007565b81526020016128bb612007565b81526020016128c8612007565b81526020016128d5612007565b81526020016128e2612007565b81526020016128ef61200b565b81526020016128fc612010565b8152602001612909612007565b815260200161291661200b565b815260200161292361200b565b8152602001612930612014565b815260200161293d612007565b815260200161294a61200b565b8152602001612957612010565b8152602001612964612007565b815250565b612971612882565b90565b67ffffffffffffffff811161298c5760208091020190565b611f8e565b906129a361299e83612974565b611fe4565b918252565b6129b0612882565b90565b5f5b8281106129c157505050565b6020906129cc6129a8565b81840152016129b5565b906129fb6129e383612991565b926020806129f18693612974565b92019103906129b3565b565b5190565b90612a0b826129fd565b811015612a1c576020809102010190565b612164565b612a29612969565b50612a4e612a3f612a3a60016120bf565b6129d6565b612a485f6121b8565b90612a01565b5190565b612a5c6040611fe4565b90565b606090565b606090565b612a71612a52565b9060208083612a7e612a5f565b815201612a89612a64565b81525050565b612a97612a69565b90565b67ffffffffffffffff8111612ab25760208091020190565b611f8e565b90612ac9612ac483612a9a565b611fe4565b918252565b612ad6612a69565b90565b5f5b828110612ae757505050565b602090612af2612ace565b8184015201612adb565b90612b21612b0983612ab7565b92602080612b178693612a9a565b9201910390612ad9565b565b5190565b90612b3182612b23565b811015612b42576020809102010190565b612164565b612b4f612a8f565b50612b74612b65612b6060016120bf565b612afc565b612b6e5f6121b8565b90612b27565b5190565b612b8260a0611fe4565b90565b612b8d612b78565b9060208080808086612b9d612007565b815201612ba8612007565b815201612bb3612010565b815201612bbe61200b565b815201612bc961200b565b81525050565b612bd7612b85565b90565b67ffffffffffffffff8111612bf25760208091020190565b611f8e565b90612c09612c0483612bda565b611fe4565b918252565b612c16612b85565b90565b5f5b828110612c2757505050565b602090612c32612c0e565b8184015201612c1b565b90612c61612c4983612bf7565b92602080612c578693612bda565b9201910390612c19565b565b5190565b90612c7182612c63565b811015612c82576020809102010190565b612164565b612c8f612bcf565b50612cb4612ca5612ca060016120bf565b612c3c565b612cae5f6121b8565b90612c67565b5190565b612cc3610140611fe4565b90565b612cce612cb8565b9060208080808080808080808b612ce3612007565b815201612cee61200b565b815201612cf9612007565b815201612d04612213565b815201612d0f612a5f565b815201612d1a612213565b815201612d25612218565b815201612d30612010565b815201612d3b612007565b815201612d46612010565b81525050565b612d54612cc6565b90565b67ffffffffffffffff8111612d6f5760208091020190565b611f8e565b90612d86612d8183612d57565b611fe4565b918252565b612d93612cc6565b90565b5f5b828110612da457505050565b602090612daf612d8b565b8184015201612d98565b90612dde612dc683612d74565b92602080612dd48693612d57565b9201910390612d96565b565b5190565b90612dee82612de0565b811015612dff576020809102010190565b612164565b612e0c612d4c565b50612e31612e22612e1d60016120bf565b612db9565b612e2b5f6121b8565b90612de4565b5190565b612e40610120611fe4565b90565b612e4b612e35565b90602080808080808080808a612e5f61200b565b815201612e6a61200b565b815201612e75612007565b815201612e80612007565b815201612e8b612007565b815201612e96612007565b815201612ea1612007565b815201612eac612010565b815201612eb7612010565b81525050565b612ec5612e43565b90565b67ffffffffffffffff8111612ee05760208091020190565b611f8e565b90612ef7612ef283612ec8565b611fe4565b918252565b612f04612e43565b90565b5f5b828110612f1557505050565b602090612f20612efc565b8184015201612f09565b90612f4f612f3783612ee5565b92602080612f458693612ec8565b9201910390612f07565b565b5190565b90612f5f82612f51565b811015612f70576020809102010190565b612164565b612f7d612ebd565b50612fa2612f93612f8e60016120bf565b612f2a565b612f9c5f6121b8565b90612f55565b5190565b612fb1610240611fe4565b90565b612fbc612fa6565b9081612fc6612007565b8152602001612fd3612213565b8152602001612fe0612a5f565b8152602001612fed612218565b8152602001612ffa612213565b8152602001613007612a5f565b8152602001613014612007565b815260200161302161200b565b815260200161302e612010565b815260200161303b612007565b8152602001613048612007565b815260200161305561200b565b8152602001613062612010565b815260200161306f612007565b815260200161307c612018565b8152602001613089612018565b8152602001613096612018565b81526020016130a3612018565b815250565b6130b0612fb4565b90565b67ffffffffffffffff81116130cb5760208091020190565b611f8e565b906130e26130dd836130b3565b611fe4565b918252565b6130ef612fb4565b90565b5f5b82811061310057505050565b60209061310b6130e7565b81840152016130f4565b9061313a613122836130d0565b9260208061313086936130b3565b92019103906130f2565b565b5190565b9061314a8261313c565b81101561315b576020809102010190565b612164565b6131686130a8565b5061318d61317e61317960016120bf565b613115565b6131875f6121b8565b90613140565b5190565b61319b60a0611fe4565b90565b6131a6613191565b90602080808080866131b6612213565b8152016131c1612a5f565b8152016131cc612007565b8152016131d7612213565b8152016131e2612218565b81525050565b6131f061319e565b90565b67ffffffffffffffff811161320b5760208091020190565b611f8e565b9061322261321d836131f3565b611fe4565b918252565b61322f61319e565b90565b5f5b82811061324057505050565b60209061324b613227565b8184015201613234565b9061327a61326283613210565b9260208061327086936131f3565b9201910390613232565b565b5190565b9061328a8261327c565b81101561329b576020809102010190565b612164565b6132a86131e8565b506132cd6132be6132b960016120bf565b613255565b6132c75f6121b8565b90613280565b5190565b6132db60c0611fe4565b90565b6132e66132d1565b9060208080808080876132f7612007565b81520161330261200b565b81520161330d612007565b815201613318612010565b815201613323612007565b81520161332e612010565b81525050565b61333c6132de565b90565b67ffffffffffffffff81116133575760208091020190565b611f8e565b9061336e6133698361333f565b611fe4565b918252565b61337b6132de565b90565b5f5b82811061338c57505050565b602090613397613373565b8184015201613380565b906133c66133ae8361335c565b926020806133bc869361333f565b920191039061337e565b565b5190565b906133d6826133c8565b8110156133e7576020809102010190565b612164565b6133f4613334565b5061341961340a61340560016120bf565b6133a1565b6134135f6121b8565b906133cc565b5190565b61342760e0611fe4565b90565b61343261341d565b90602080808080808088613444612007565b81520161344f61200b565b81520161345a612007565b815201613465612007565b815201613470612010565b81520161347b612014565b815201613486612010565b81525050565b61349461342a565b90565b67ffffffffffffffff81116134af5760208091020190565b611f8e565b906134c66134c183613497565b611fe4565b918252565b6134d361342a565b90565b5f5b8281106134e457505050565b6020906134ef6134cb565b81840152016134d8565b9061351e613506836134b4565b926020806135148693613497565b92019103906134d6565b565b5190565b9061352e82613520565b81101561353f576020809102010190565b612164565b61354c61348c565b5061357161356261355d60016120bf565b6134f9565b61356b5f6121b8565b90613524565b5190565b61357f60c0611fe4565b90565b61358a613575565b90602080808080808761359b612007565b8152016135a661200b565b8152016135b1612007565b8152016135bc612010565b8152016135c7612007565b8152016135d2612010565b81525050565b6135e0613582565b90565b67ffffffffffffffff81116135fb5760208091020190565b611f8e565b9061361261360d836135e3565b611fe4565b918252565b61361f613582565b90565b5f5b82811061363057505050565b60209061363b613617565b8184015201613624565b9061366a61365283613600565b9260208061366086936135e3565b9201910390613622565b565b5190565b9061367a8261366c565b81101561368b576020809102010190565b612164565b6136986135d8565b506136bd6136ae6136a960016120bf565b613645565b6136b75f6121b8565b90613670565b5190565b6136cc610240611fe4565b90565b6136d76136c1565b90816136e161200b565b81526020016136ee612010565b81526020016136fb612007565b8152602001613708612007565b8152602001613715612007565b8152602001613722612007565b815260200161372f612018565b815260200161373c612007565b815260200161374961200b565b8152602001613756612010565b8152602001613763612007565b815260200161377061200b565b815260200161377d61200b565b815260200161378a612014565b8152602001613797612007565b81526020016137a461200b565b81526020016137b1612010565b81526020016137be612007565b815250565b6137cb6136cf565b90565b67ffffffffffffffff81116137e65760208091020190565b611f8e565b906137fd6137f8836137ce565b611fe4565b918252565b61380a6136cf565b90565b5f5b82811061381b57505050565b602090613826613802565b818401520161380f565b9061385561383d836137eb565b9260208061384b86936137ce565b920191039061380d565b565b5190565b9061386582613857565b811015613876576020809102010190565b612164565b6138836137c3565b506138a861389961389460016120bf565b613830565b6138a25f6121b8565b9061385b565b5190565b6138b7610140611fe4565b90565b6138c26138ac565b9060208080808080808080808b6138d7612007565b8152016138e261200b565b8152016138ed612007565b8152016138f8612213565b815201613903612a5f565b81520161390e612213565b815201613919612218565b815201613924612010565b81520161392f612007565b81520161393a612010565b81525050565b6139486138ba565b90565b67ffffffffffffffff81116139635760208091020190565b611f8e565b9061397a6139758361394b565b611fe4565b918252565b6139876138ba565b90565b5f5b82811061399857505050565b6020906139a361397f565b818401520161398c565b906139d26139ba83613968565b926020806139c8869361394b565b920191039061398a565b565b5190565b906139e2826139d4565b8110156139f3576020809102010190565b612164565b613a00613940565b50613a25613a16613a1160016120bf565b6139ad565b613a1f5f6121b8565b906139d8565b5190565b613a34610160611fe4565b90565b613a3f613a29565b906020808080808080808080808c613a55612007565b815201613a6061200b565b815201613a6b612007565b815201613a76612007565b815201613a8161200b565b815201613a8c612007565b815201613a97612010565b815201613aa2612010565b815201613aad612014565b815201613ab8612007565b815201613ac3612010565b81525050565b613ad1613a37565b90565b67ffffffffffffffff8111613aec5760208091020190565b611f8e565b90613b03613afe83613ad4565b611fe4565b918252565b613b10613a37565b90565b5f5b828110613b2157505050565b602090613b2c613b08565b8184015201613b15565b90613b5b613b4383613af1565b92602080613b518693613ad4565b9201910390613b13565b565b5190565b90613b6b82613b5d565b811015613b7c576020809102010190565b612164565b613b89613ac9565b50613bae613b9f613b9a60016120bf565b613b36565b613ba85f6121b8565b90613b61565b5190565b613bbd610180611fe4565b90565b613bc8613bb2565b90602080808080808080808080808d613bdf612007565b815201613bea612007565b815201613bf561200b565b815201613c00612010565b815201613c0b612007565b815201613c16612007565b815201613c2161200b565b815201613c2c612010565b815201613c37612007565b815201613c42612007565b815201613c4d612018565b815201613c58612018565b81525050565b613c66613bc0565b90565b67ffffffffffffffff8111613c815760208091020190565b611f8e565b90613c98613c9383613c69565b611fe4565b918252565b613ca5613bc0565b90565b5f5b828110613cb657505050565b602090613cc1613c9d565b8184015201613caa565b90613cf0613cd883613c86565b92602080613ce68693613c69565b9201910390613ca8565b565b5190565b90613d0082613cf2565b811015613d11576020809102010190565b612164565b613d1e613c5e565b50613d43613d34613d2f60016120bf565b613ccb565b613d3d5f6121b8565b90613cf6565b5190565b613d52610220611fe4565b90565b613d5d613d47565b9081613d6761200b565b8152602001613d74612010565b8152602001613d81612007565b8152602001613d8e612007565b8152602001613d9b612007565b8152602001613da8612007565b8152602001613db5612007565b8152602001613dc261200b565b8152602001613dcf612010565b8152602001613ddc612007565b8152602001613de961200b565b8152602001613df661200b565b8152602001613e03612014565b8152602001613e10612007565b8152602001613e1d61200b565b8152602001613e2a612010565b8152602001613e37612007565b815250565b613e44613d55565b90565b67ffffffffffffffff8111613e5f5760208091020190565b611f8e565b90613e76613e7183613e47565b611fe4565b918252565b613e83613d55565b90565b5f5b828110613e9457505050565b602090613e9f613e7b565b8184015201613e88565b90613ece613eb683613e64565b92602080613ec48693613e47565b9201910390613e86565b565b5190565b90613ede82613ed0565b811015613eef576020809102010190565b612164565b613efc613e3c565b50613f21613f12613f0d60016120bf565b613ea9565b613f1b5f6121b8565b90613ed4565b5190565b613f2f60c0611fe4565b90565b613f3a613f25565b906020808080808087613f4b612007565b815201613f5661200b565b815201613f61612007565b815201613f6c612010565b815201613f77612007565b815201613f82612010565b81525050565b613f90613f32565b90565b67ffffffffffffffff8111613fab5760208091020190565b611f8e565b90613fc2613fbd83613f93565b611fe4565b918252565b613fcf613f32565b90565b5f5b828110613fe057505050565b602090613feb613fc7565b8184015201613fd4565b9061401a61400283613fb0565b926020806140108693613f93565b9201910390613fd2565b565b5190565b9061402a8261401c565b81101561403b576020809102010190565b612164565b614048613f88565b5061406d61405e61405960016120bf565b613ff5565b6140675f6121b8565b90614020565b5190565b61407b60c0611fe4565b90565b614086614071565b906020808080808087614097612007565b8152016140a261200b565b8152016140ad612007565b8152016140b8612010565b8152016140c3612007565b8152016140ce612010565b81525050565b6140dc61407e565b90565b67ffffffffffffffff81116140f75760208091020190565b611f8e565b9061410e614109836140df565b611fe4565b918252565b61411b61407e565b90565b5f5b82811061412c57505050565b602090614137614113565b8184015201614120565b9061416661414e836140fc565b9260208061415c86936140df565b920191039061411e565b565b5190565b9061417682614168565b811015614187576020809102010190565b612164565b6141946140d4565b506141b96141aa6141a560016120bf565b614141565b6141b35f6121b8565b9061416c565b5190565b6141c8610160611fe4565b90565b6141d36141bd565b906020808080808080808080808c6141e9612007565b8152016141f461200b565b8152016141ff612007565b81520161420a612007565b81520161421561200b565b815201614220612007565b81520161422b612010565b815201614236612010565b815201614241612014565b81520161424c612007565b815201614257612010565b81525050565b6142656141cb565b90565b67ffffffffffffffff81116142805760208091020190565b611f8e565b9061429761429283614268565b611fe4565b918252565b6142a46141cb565b90565b5f5b8281106142b557505050565b6020906142c061429c565b81840152016142a9565b906142ef6142d783614285565b926020806142e58693614268565b92019103906142a7565b565b5190565b906142ff826142f1565b811015614310576020809102010190565b612164565b61431d61425d565b5061434261433361432e60016120bf565b6142ca565b61433c5f6121b8565b906142f5565b5190565b614351610240611fe4565b90565b61435c614346565b908161436661200b565b8152602001614373612010565b8152602001614380612007565b815260200161438d612007565b815260200161439a612007565b81526020016143a7612007565b81526020016143b4612018565b81526020016143c1612007565b81526020016143ce61200b565b81526020016143db612010565b81526020016143e8612007565b81526020016143f561200b565b815260200161440261200b565b815260200161440f612014565b815260200161441c612007565b815260200161442961200b565b8152602001614436612010565b8152602001614443612007565b815250565b614450614354565b90565b67ffffffffffffffff811161446b5760208091020190565b611f8e565b9061448261447d83614453565b611fe4565b918252565b61448f614354565b90565b5f5b8281106144a057505050565b6020906144ab614487565b8184015201614494565b906144da6144c283614470565b926020806144d08693614453565b9201910390614492565b565b5190565b906144ea826144dc565b8110156144fb576020809102010190565b612164565b614508614448565b5061452d61451e61451960016120bf565b6144b5565b6145275f6121b8565b906144e0565b5190565b61453c610160611fe4565b90565b614547614531565b906020808080808080808080808c61455d612007565b81520161456861200b565b815201614573612010565b81520161457e612007565b815201614589612007565b81520161459461200b565b81520161459f612010565b8152016145aa612007565b8152016145b561200b565b8152016145c0612014565b8152016145cb612018565b81525050565b6145d961453f565b90565b67ffffffffffffffff81116145f45760208091020190565b611f8e565b9061460b614606836145dc565b611fe4565b918252565b61461861453f565b90565b5f5b82811061462957505050565b602090614634614610565b818401520161461d565b9061466361464b836145f9565b9260208061465986936145dc565b920191039061461b565b565b5190565b9061467382614665565b811015614684576020809102010190565b612164565b6146916145d1565b506146b66146a76146a260016120bf565b61463e565b6146b05f6121b8565b90614669565b5190565b6146c460a0611fe4565b90565b6146cf6146ba565b90602080808080866146df612213565b8152016146ea612a5f565b8152016146f5612007565b815201614700612213565b81520161470b612218565b81525050565b6147196146c7565b90565b67ffffffffffffffff81116147345760208091020190565b611f8e565b9061474b6147468361471c565b611fe4565b918252565b6147586146c7565b90565b5f5b82811061476957505050565b602090614774614750565b818401520161475d565b906147a361478b83614739565b92602080614799869361471c565b920191039061475b565b565b5190565b906147b3826147a5565b8110156147c4576020809102010190565b612164565b6147d1614711565b506147f66147e76147e260016120bf565b61477e565b6147f05f6121b8565b906147a9565b519056"
    public static let runtimeCode: Hex = "0x60806040526004361015610013575b611f8a565b61001d5f356101cc565b80630543a804146101c7578063129d57b9146101c257806313a3c45b146101bd57806315745b1e146101b857806317d88853146101b357806322f30261146101ae5780632b30b3dd146101a95780633bdf833f146101a457806349d9db721461019f5780635434c6da1461019a57806355354eaf1461019557806357630a5d14610190578063638f48801461018b5780637b5ea6d8146101865780638258f98714610181578063831dc5f71461017c5780638a978a35146101775780638dadfaa11461017257806390208d3b1461016d5780639a953855146101685780639fca66f414610163578063aa8f056e1461015e578063b5e5bc1c14610159578063c48897ec14610154578063c9bec8711461014f578063cc7e92e81461014a5763e67e97350361000e57611f5f565b611eaf565b611d91565b611be1565b611ac6565b611a0e565b611956565b6117ba565b61168b565b611570565b611460565b6112b0565b6111f8565b61112e565b611076565b610fc6565b610e0f565b610d1c565b610c0c565b610b62565b610996565b6107fa565b610742565b61068a565b6105d2565b61057f565b610395565b60e01c90565b60405190565b5f80fd5b5f9103126101e657565b6101d8565b90565b6101f7906101eb565b9052565b5190565b60209181520190565b90825f9392825e0152565b601f801991011690565b61023c61024560209361024a93610233816101fb565b938480936101ff565b95869101610208565b610213565b0190565b73ffffffffffffffffffffffffffffffffffffffff1690565b6102709061024e565b90565b61027c90610267565b9052565b90565b61028c90610280565b9052565b151590565b61029e90610290565b9052565b9061037a906101408061035b6103236102db61016086016102c95f8a01515f8901906101ee565b6020890151878203602089015261021d565b6102ed60408901516040880190610273565b6102ff606089015160608801906101ee565b610311608089015160808801906101ee565b60a088015186820360a088015261021d565b61033560c088015160c0870190610273565b61034760e088015160e08701906101ee565b61010087015185820361010087015261021d565b94610370610120820151610120860190610283565b0151910190610295565b90565b6103929160208201915f8184039101526102a2565b90565b6103a03660046101dc565b6103bc6103ab6121d4565b6103b36101d2565b9182918261037d565b0390f35b5190565b60209181520190565b60200190565b906103e0816020936101ee565b0190565b60200190565b906104076104016103fa846103c0565b80936103c4565b926103cd565b905f5b8181106104175750505090565b90919261043061042a60019286516103d3565b946103e4565b910191909161040a565b5190565b60209181520190565b60200190565b9061045a81602093610273565b0190565b60200190565b9061048161047b6104748461043a565b809361043e565b92610447565b905f5b8181106104915750505090565b9091926104aa6104a4600192865161044d565b9461045e565b9101919091610484565b9061056490610100806105236105116104ff61012086016104db5f8a01515f8901906101ee565b6104ed60208a015160208901906101ee565b604089015187820360408901526103ea565b606088015186820360608801526103ea565b60808701518582036080870152610464565b9461053660a082015160a0860190610273565b61054860c082015160c08601906101ee565b61055a60e082015160e0860190610273565b01519101906101ee565b90565b61057c9160208201915f8184039101526104b4565b90565b61058a3660046101dc565b6105a661059561234f565b61059d6101d2565b91829182610567565b0390f35b905f806105bb9301519101906101ee565b565b91906105d0905f602085019401906105aa565b565b6105dd3660046101dc565b6105f96105e861245f565b6105f06101d2565b918291826105bd565b0390f35b9061066f9060a08061062e60c0840161061c5f8801515f8701906101ee565b6020870151858203602087015261021d565b94610641604082015160408601906101ee565b61065360608201516060860190610273565b610665608082015160808601906101ee565b0151910190610273565b90565b6106879160208201915f8184039101526105fd565b90565b6106953660046101dc565b6106b16106a06125ab565b6106a86101d2565b91829182610672565b0390f35b906107279060a0806106e660c084016106d45f8801515f8701906101ee565b6020870151858203602087015261021d565b946106f9604082015160408601906101ee565b61070b606082015160608601906101ee565b61071d60808201516080860190610273565b0151910190610273565b90565b61073f9160208201915f8184039101526106b5565b90565b61074d3660046101dc565b6107696107586126f7565b6107606101d2565b9182918261072a565b0390f35b906107df9060a08061079e60c0840161078c5f8801515f8701906101ee565b6020870151858203602087015261021d565b946107b1604082015160408601906101ee565b6107c360608201516060860190610273565b6107d5608082015160808601906101ee565b0151910190610273565b90565b6107f79160208201915f81840391015261076d565b90565b6108053660046101dc565b610821610810612843565b6108186101d2565b918291826107e2565b0390f35b9061097b906102008061095c61092061090c6108d061085261022088015f8b01518982035f8b015261021d565b61086460208b015160208a0190610273565b61087660408b015160408a01906101ee565b61088860608b015160608a01906101ee565b61089a60808b015160808a01906101ee565b6108ac60a08b015160a08a01906101ee565b6108be60c08b015160c08a01906101ee565b60e08a015188820360e08a015261021d565b6108e46101008a0151610100890190610273565b6108f86101208a01516101208901906101ee565b61014089015187820361014089015261021d565b61016088015186820361016088015261021d565b610934610180880151610180870190610283565b6109486101a08801516101a08701906101ee565b6101c08701518582036101c087015261021d565b946109716101e08201516101e0860190610273565b01519101906101ee565b90565b6109939160208201915f818403910152610825565b90565b6109a13660046101dc565b6109bd6109ac612a21565b6109b46101d2565b9182918261097e565b0390f35b5190565b60209181520190565b60200190565b906109de9161021d565b90565b60200190565b906109fb6109f4836109c1565b80926109c5565b9081610a0c602083028401946109ce565b925f915b838310610a1f57505050505090565b90919293946020610a41610a3b838560019503875289516109d4565b976109e1565b9301930191939290610a10565b5190565b60209181520190565b60200190565b5190565b60209181520190565b610a8d610a96602093610a9b93610a8481610a61565b93848093610a65565b95869101610208565b610213565b0190565b90610aa991610a6e565b90565b60200190565b90610ac6610abf83610a4e565b8092610a52565b9081610ad760208302840194610a5b565b925f915b838310610aea57505050505090565b90919293946020610b0c610b0683856001950387528951610a9f565b97610aac565b9301930191939290610adb565b610b47916020610b36604083015f8501518482035f8601526109e7565b920151906020818403910152610ab2565b90565b610b5f9160208201915f818403910152610b19565b90565b610b6d3660046101dc565b610b89610b78612b47565b610b806101d2565b91829182610b4a565b0390f35b610bf1916080610be060a08301610baa5f8601515f8601906101ee565b610bbc602086015160208601906101ee565b610bce60408601516040860190610273565b6060850151848203606086015261021d565b92015190608081840391015261021d565b90565b610c099160208201915f818403910152610b8d565b90565b610c173660046101dc565b610c33610c22612c87565b610c2a6101d2565b91829182610bf4565b0390f35b90610d019061012080610cd0610cbe610cac610c9a610c766101408801610c645f8c01515f8b01906101ee565b60208b015189820360208b015261021d565b610c8860408b015160408a01906101ee565b60608a015188820360608a01526103ea565b608089015187820360808901526109e7565b60a088015186820360a08801526103ea565b60c087015185820360c0870152610464565b94610ce360e082015160e0860190610273565b610cf76101008201516101008601906101ee565b0151910190610273565b90565b610d199160208201915f818403910152610c37565b90565b610d273660046101dc565b610d43610d32612e04565b610d3a6101d2565b91829182610d04565b0390f35b90610df49061010080610d7d610d6b61012085015f8801518682035f88015261021d565b6020870151858203602087015261021d565b94610d90604082015160408601906101ee565b610da2606082015160608601906101ee565b610db4608082015160808601906101ee565b610dc660a082015160a08601906101ee565b610dd860c082015160c08601906101ee565b610dea60e082015160e0860190610273565b0151910190610273565b90565b610e0c9160208201915f818403910152610d47565b90565b610e1a3660046101dc565b610e36610e25612f75565b610e2d6101d2565b91829182610df7565b0390f35b90610fab9061022080610f3c610eec610ec8610eb6610ea4610e92610e808b610e6e5f6102408d019201515f8d01906101ee565b60208d01518b820360208d01526103ea565b60408c01518a820360408c01526109e7565b60608b015189820360608b0152610464565b60808a015188820360808a01526103ea565b60a089015187820360a08901526109e7565b610eda60c089015160c08801906101ee565b60e088015186820360e088015261021d565b610f00610100880151610100870190610273565b610f146101208801516101208701906101ee565b610f286101408801516101408701906101ee565b61016087015185820361016087015261021d565b94610f51610180820151610180860190610273565b610f656101a08201516101a08601906101ee565b610f796101c08201516101c0860190610295565b610f8d6101e08201516101e0860190610295565b610fa1610200820151610200860190610295565b0151910190610295565b90565b610fc39160208201915f818403910152610e3a565b90565b610fd13660046101dc565b610fed610fdc613160565b610fe46101d2565b91829182610fae565b0390f35b61105b91608061104a61102661101460a085015f8701518682035f8801526103ea565b602086015185820360208701526109e7565b611038604086015160408601906101ee565b606085015184820360608601526103ea565b920151906080818403910152610464565b90565b6110739160208201915f818403910152610ff1565b90565b6110813660046101dc565b61109d61108c6132a0565b6110946101d2565b9182918261105e565b0390f35b906111139060a0806110d260c084016110c05f8801515f8701906101ee565b6020870151858203602087015261021d565b946110e5604082015160408601906101ee565b6110f760608201516060860190610273565b611109608082015160808601906101ee565b0151910190610273565b90565b61112b9160208201915f8184039101526110a1565b90565b6111393660046101dc565b6111556111446133ec565b61114c6101d2565b91829182611116565b0390f35b906111dd9060c08061118a60e084016111785f8801515f8701906101ee565b6020870151858203602087015261021d565b9461119d604082015160408601906101ee565b6111af606082015160608601906101ee565b6111c160808201516080860190610273565b6111d360a082015160a0860190610283565b0151910190610273565b90565b6111f59160208201915f818403910152611159565b90565b6112033660046101dc565b61121f61120e613544565b6112166101d2565b918291826111e0565b0390f35b906112959060a08061125460c084016112425f8801515f8701906101ee565b6020870151858203602087015261021d565b94611267604082015160408601906101ee565b61127960608201516060860190610273565b61128b608082015160808601906101ee565b0151910190610273565b90565b6112ad9160208201915f818403910152611223565b90565b6112bb3660046101dc565b6112d76112c6613690565b6112ce6101d2565b91829182611298565b0390f35b9061144590610220806114266113ea6113d661139a61130861024088015f8b01518982035f8b015261021d565b61131a60208b015160208a0190610273565b61132c60408b015160408a01906101ee565b61133e60608b015160608a01906101ee565b61135060808b015160808a01906101ee565b61136260a08b015160a08a01906101ee565b61137460c08b015160c08a0190610295565b61138660e08b015160e08a01906101ee565b6101008a01518882036101008a015261021d565b6113ae6101208a0151610120890190610273565b6113c26101408a01516101408901906101ee565b61016089015187820361016089015261021d565b61018088015186820361018088015261021d565b6113fe6101a08801516101a0870190610283565b6114126101c08801516101c08701906101ee565b6101e08701518582036101e087015261021d565b9461143b610200820151610200860190610273565b01519101906101ee565b90565b61145d9160208201915f8184039101526112db565b90565b61146b3660046101dc565b61148761147661387b565b61147e6101d2565b91829182611448565b0390f35b9061155590610120806115246115126115006114ee6114ca61014088016114b85f8c01515f8b01906101ee565b60208b015189820360208b015261021d565b6114dc60408b015160408a01906101ee565b60608a015188820360608a01526103ea565b608089015187820360808901526109e7565b60a088015186820360a08801526103ea565b60c087015185820360c0870152610464565b9461153760e082015160e0860190610273565b61154b6101008201516101008601906101ee565b0151910190610273565b90565b61156d9160208201915f81840391015261148b565b90565b61157b3660046101dc565b6115976115866139f8565b61158e6101d2565b91829182611558565b0390f35b9061167090610140806116076115d161016085016115bf5f8901515f8801906101ee565b6020880151868203602088015261021d565b6115e3604088015160408701906101ee565b6115f5606088015160608701906101ee565b6080870151858203608087015261021d565b9461161a60a082015160a08601906101ee565b61162c60c082015160c0860190610273565b61163e60e082015160e0860190610273565b611652610100820151610100860190610283565b6116666101208201516101208601906101ee565b0151910190610273565b90565b6116889160208201915f81840391015261159b565b90565b6116963660046101dc565b6116b26116a1613b81565b6116a96101d2565b91829182611673565b0390f35b9061179f90610160806117466116fe61018085016116da5f8901515f8801906101ee565b6116ec602089015160208801906101ee565b6040880151868203604088015261021d565b61171060608801516060870190610273565b611722608088015160808701906101ee565b61173460a088015160a08701906101ee565b60c087015185820360c087015261021d565b9461175960e082015160e0860190610273565b61176d6101008201516101008601906101ee565b6117816101208201516101208601906101ee565b611795610140820151610140860190610295565b0151910190610295565b90565b6117b79160208201915f8184039101526116b6565b90565b6117c53660046101dc565b6117e16117d0613d16565b6117d86101d2565b918291826117a2565b0390f35b9061193b906102008061191c6118e06118cc61189061181261022088015f8b01518982035f8b015261021d565b61182460208b015160208a0190610273565b61183660408b015160408a01906101ee565b61184860608b015160608a01906101ee565b61185a60808b015160808a01906101ee565b61186c60a08b015160a08a01906101ee565b61187e60c08b015160c08a01906101ee565b60e08a015188820360e08a015261021d565b6118a46101008a0151610100890190610273565b6118b86101208a01516101208901906101ee565b61014089015187820361014089015261021d565b61016088015186820361016088015261021d565b6118f4610180880151610180870190610283565b6119086101a08801516101a08701906101ee565b6101c08701518582036101c087015261021d565b946119316101e08201516101e0860190610273565b01519101906101ee565b90565b6119539160208201915f8184039101526117e5565b90565b6119613660046101dc565b61197d61196c613ef4565b6119746101d2565b9182918261193e565b0390f35b906119f39060a0806119b260c084016119a05f8801515f8701906101ee565b6020870151858203602087015261021d565b946119c5604082015160408601906101ee565b6119d760608201516060860190610273565b6119e9608082015160808601906101ee565b0151910190610273565b90565b611a0b9160208201915f818403910152611981565b90565b611a193660046101dc565b611a35611a24614040565b611a2c6101d2565b918291826119f6565b0390f35b90611aab9060a080611a6a60c08401611a585f8801515f8701906101ee565b6020870151858203602087015261021d565b94611a7d604082015160408601906101ee565b611a8f60608201516060860190610273565b611aa1608082015160808601906101ee565b0151910190610273565b90565b611ac39160208201915f818403910152611a39565b90565b611ad13660046101dc565b611aed611adc61418c565b611ae46101d2565b91829182611aae565b0390f35b90611bc69061014080611b5d611b276101608501611b155f8901515f8801906101ee565b6020880151868203602088015261021d565b611b39604088015160408701906101ee565b611b4b606088015160608701906101ee565b6080870151858203608087015261021d565b94611b7060a082015160a08601906101ee565b611b8260c082015160c0860190610273565b611b9460e082015160e0860190610273565b611ba8610100820151610100860190610283565b611bbc6101208201516101208601906101ee565b0151910190610273565b90565b611bde9160208201915f818403910152611af1565b90565b611bec3660046101dc565b611c08611bf7614315565b611bff6101d2565b91829182611bc9565b0390f35b90611d769061022080611d57611d1b611d07611ccb611c3961024088015f8b01518982035f8b015261021d565b611c4b60208b015160208a0190610273565b611c5d60408b015160408a01906101ee565b611c6f60608b015160608a01906101ee565b611c8160808b015160808a01906101ee565b611c9360a08b015160a08a01906101ee565b611ca560c08b015160c08a0190610295565b611cb760e08b015160e08a01906101ee565b6101008a01518882036101008a015261021d565b611cdf6101208a0151610120890190610273565b611cf36101408a01516101408901906101ee565b61016089015187820361016089015261021d565b61018088015186820361018088015261021d565b611d2f6101a08801516101a0870190610283565b611d436101c08801516101c08701906101ee565b6101e08701518582036101e087015261021d565b94611d6c610200820151610200860190610273565b01519101906101ee565b90565b611d8e9160208201915f818403910152611c0c565b90565b611d9c3660046101dc565b611db8611da7614500565b611daf6101d2565b91829182611d79565b0390f35b90611e949061014080611e75611e3d611df56101608601611de35f8a01515f8901906101ee565b6020890151878203602089015261021d565b611e0760408901516040880190610273565b611e19606089015160608801906101ee565b611e2b608089015160808801906101ee565b60a088015186820360a088015261021d565b611e4f60c088015160c0870190610273565b611e6160e088015160e08701906101ee565b61010087015185820361010087015261021d565b94611e8a610120820151610120860190610283565b0151910190610295565b90565b611eac9160208201915f818403910152611dbc565b90565b611eba3660046101dc565b611ed6611ec5614689565b611ecd6101d2565b91829182611e97565b0390f35b611f44916080611f33611f0f611efd60a085015f8701518682035f8801526103ea565b602086015185820360208701526109e7565b611f21604086015160408601906101ee565b606085015184820360608601526103ea565b920151906080818403910152610464565b90565b611f5c9160208201915f818403910152611eda565b90565b611f6a3660046101dc565b611f86611f756147c9565b611f7d6101d2565b91829182611f47565b0390f35b5f80fd5b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b90611fc590610213565b810190811067ffffffffffffffff821117611fdf57604052565b611f8e565b90611ff7611ff06101d2565b9283611fbb565b565b612004610160611fe4565b90565b5f90565b606090565b5f90565b5f90565b5f90565b612024611ff9565b906020808080808080808080808c61203a612007565b81520161204561200b565b815201612050612010565b81520161205b612007565b815201612066612007565b81520161207161200b565b81520161207c612010565b815201612087612007565b81520161209261200b565b81520161209d612014565b8152016120a8612018565b81525050565b6120b661201c565b90565b90565b90565b6120d36120ce6120d8926120b9565b6120bc565b6101eb565b90565b67ffffffffffffffff81116120f35760208091020190565b611f8e565b9061210a612105836120db565b611fe4565b918252565b61211761201c565b90565b5f5b82811061212857505050565b60209061213361210f565b818401520161211c565b9061216261214a836120f8565b9260208061215886936120db565b920191039061211a565b565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52603260045260245ffd5b5190565b9061219f82612191565b8110156121b0576020809102010190565b612164565b90565b6121cc6121c76121d1926121b5565b6120bc565b6101eb565b90565b6121dc6120ae565b506122016121f26121ed60016120bf565b61213d565b6121fb5f6121b8565b90612195565b5190565b612210610120611fe4565b90565b606090565b606090565b612225612205565b90602080808080808080808a612239612007565b815201612244612007565b81520161224f612213565b81520161225a612213565b815201612265612218565b815201612270612010565b81520161227b612007565b815201612286612010565b815201612291612007565b81525050565b61229f61221d565b90565b67ffffffffffffffff81116122ba5760208091020190565b611f8e565b906122d16122cc836122a2565b611fe4565b918252565b6122de61221d565b90565b5f5b8281106122ef57505050565b6020906122fa6122d6565b81840152016122e3565b90612329612311836122bf565b9260208061231f86936122a2565b92019103906122e1565b565b5190565b906123398261232b565b81101561234a576020809102010190565b612164565b612357612297565b5061237c61236d61236860016120bf565b612304565b6123765f6121b8565b9061232f565b5190565b61238a6020611fe4565b90565b612395612380565b906020826123a1612007565b81525050565b6123af61238d565b90565b67ffffffffffffffff81116123ca5760208091020190565b611f8e565b906123e16123dc836123b2565b611fe4565b918252565b6123ee61238d565b90565b5f5b8281106123ff57505050565b60209061240a6123e6565b81840152016123f3565b90612439612421836123cf565b9260208061242f86936123b2565b92019103906123f1565b565b5190565b906124498261243b565b81101561245a576020809102010190565b612164565b6124676123a7565b5061248c61247d61247860016120bf565b612414565b6124865f6121b8565b9061243f565b5190565b61249a60c0611fe4565b90565b6124a5612490565b9060208080808080876124b6612007565b8152016124c161200b565b8152016124cc612007565b8152016124d7612010565b8152016124e2612007565b8152016124ed612010565b81525050565b6124fb61249d565b90565b67ffffffffffffffff81116125165760208091020190565b611f8e565b9061252d612528836124fe565b611fe4565b918252565b61253a61249d565b90565b5f5b82811061254b57505050565b602090612556612532565b818401520161253f565b9061258561256d8361251b565b9260208061257b86936124fe565b920191039061253d565b565b5190565b9061259582612587565b8110156125a6576020809102010190565b612164565b6125b36124f3565b506125d86125c96125c460016120bf565b612560565b6125d25f6121b8565b9061258b565b5190565b6125e660c0611fe4565b90565b6125f16125dc565b906020808080808087612602612007565b81520161260d61200b565b815201612618612007565b815201612623612007565b81520161262e612010565b815201612639612010565b81525050565b6126476125e9565b90565b67ffffffffffffffff81116126625760208091020190565b611f8e565b906126796126748361264a565b611fe4565b918252565b6126866125e9565b90565b5f5b82811061269757505050565b6020906126a261267e565b818401520161268b565b906126d16126b983612667565b926020806126c7869361264a565b9201910390612689565b565b5190565b906126e1826126d3565b8110156126f2576020809102010190565b612164565b6126ff61263f565b5061272461271561271060016120bf565b6126ac565b61271e5f6121b8565b906126d7565b5190565b61273260c0611fe4565b90565b61273d612728565b90602080808080808761274e612007565b81520161275961200b565b815201612764612007565b81520161276f612010565b81520161277a612007565b815201612785612010565b81525050565b612793612735565b90565b67ffffffffffffffff81116127ae5760208091020190565b611f8e565b906127c56127c083612796565b611fe4565b918252565b6127d2612735565b90565b5f5b8281106127e357505050565b6020906127ee6127ca565b81840152016127d7565b9061281d612805836127b3565b926020806128138693612796565b92019103906127d5565b565b5190565b9061282d8261281f565b81101561283e576020809102010190565b612164565b61284b61278b565b5061287061286161285c60016120bf565b6127f8565b61286a5f6121b8565b90612823565b5190565b61287f610220611fe4565b90565b61288a612874565b908161289461200b565b81526020016128a1612010565b81526020016128ae612007565b81526020016128bb612007565b81526020016128c8612007565b81526020016128d5612007565b81526020016128e2612007565b81526020016128ef61200b565b81526020016128fc612010565b8152602001612909612007565b815260200161291661200b565b815260200161292361200b565b8152602001612930612014565b815260200161293d612007565b815260200161294a61200b565b8152602001612957612010565b8152602001612964612007565b815250565b612971612882565b90565b67ffffffffffffffff811161298c5760208091020190565b611f8e565b906129a361299e83612974565b611fe4565b918252565b6129b0612882565b90565b5f5b8281106129c157505050565b6020906129cc6129a8565b81840152016129b5565b906129fb6129e383612991565b926020806129f18693612974565b92019103906129b3565b565b5190565b90612a0b826129fd565b811015612a1c576020809102010190565b612164565b612a29612969565b50612a4e612a3f612a3a60016120bf565b6129d6565b612a485f6121b8565b90612a01565b5190565b612a5c6040611fe4565b90565b606090565b606090565b612a71612a52565b9060208083612a7e612a5f565b815201612a89612a64565b81525050565b612a97612a69565b90565b67ffffffffffffffff8111612ab25760208091020190565b611f8e565b90612ac9612ac483612a9a565b611fe4565b918252565b612ad6612a69565b90565b5f5b828110612ae757505050565b602090612af2612ace565b8184015201612adb565b90612b21612b0983612ab7565b92602080612b178693612a9a565b9201910390612ad9565b565b5190565b90612b3182612b23565b811015612b42576020809102010190565b612164565b612b4f612a8f565b50612b74612b65612b6060016120bf565b612afc565b612b6e5f6121b8565b90612b27565b5190565b612b8260a0611fe4565b90565b612b8d612b78565b9060208080808086612b9d612007565b815201612ba8612007565b815201612bb3612010565b815201612bbe61200b565b815201612bc961200b565b81525050565b612bd7612b85565b90565b67ffffffffffffffff8111612bf25760208091020190565b611f8e565b90612c09612c0483612bda565b611fe4565b918252565b612c16612b85565b90565b5f5b828110612c2757505050565b602090612c32612c0e565b8184015201612c1b565b90612c61612c4983612bf7565b92602080612c578693612bda565b9201910390612c19565b565b5190565b90612c7182612c63565b811015612c82576020809102010190565b612164565b612c8f612bcf565b50612cb4612ca5612ca060016120bf565b612c3c565b612cae5f6121b8565b90612c67565b5190565b612cc3610140611fe4565b90565b612cce612cb8565b9060208080808080808080808b612ce3612007565b815201612cee61200b565b815201612cf9612007565b815201612d04612213565b815201612d0f612a5f565b815201612d1a612213565b815201612d25612218565b815201612d30612010565b815201612d3b612007565b815201612d46612010565b81525050565b612d54612cc6565b90565b67ffffffffffffffff8111612d6f5760208091020190565b611f8e565b90612d86612d8183612d57565b611fe4565b918252565b612d93612cc6565b90565b5f5b828110612da457505050565b602090612daf612d8b565b8184015201612d98565b90612dde612dc683612d74565b92602080612dd48693612d57565b9201910390612d96565b565b5190565b90612dee82612de0565b811015612dff576020809102010190565b612164565b612e0c612d4c565b50612e31612e22612e1d60016120bf565b612db9565b612e2b5f6121b8565b90612de4565b5190565b612e40610120611fe4565b90565b612e4b612e35565b90602080808080808080808a612e5f61200b565b815201612e6a61200b565b815201612e75612007565b815201612e80612007565b815201612e8b612007565b815201612e96612007565b815201612ea1612007565b815201612eac612010565b815201612eb7612010565b81525050565b612ec5612e43565b90565b67ffffffffffffffff8111612ee05760208091020190565b611f8e565b90612ef7612ef283612ec8565b611fe4565b918252565b612f04612e43565b90565b5f5b828110612f1557505050565b602090612f20612efc565b8184015201612f09565b90612f4f612f3783612ee5565b92602080612f458693612ec8565b9201910390612f07565b565b5190565b90612f5f82612f51565b811015612f70576020809102010190565b612164565b612f7d612ebd565b50612fa2612f93612f8e60016120bf565b612f2a565b612f9c5f6121b8565b90612f55565b5190565b612fb1610240611fe4565b90565b612fbc612fa6565b9081612fc6612007565b8152602001612fd3612213565b8152602001612fe0612a5f565b8152602001612fed612218565b8152602001612ffa612213565b8152602001613007612a5f565b8152602001613014612007565b815260200161302161200b565b815260200161302e612010565b815260200161303b612007565b8152602001613048612007565b815260200161305561200b565b8152602001613062612010565b815260200161306f612007565b815260200161307c612018565b8152602001613089612018565b8152602001613096612018565b81526020016130a3612018565b815250565b6130b0612fb4565b90565b67ffffffffffffffff81116130cb5760208091020190565b611f8e565b906130e26130dd836130b3565b611fe4565b918252565b6130ef612fb4565b90565b5f5b82811061310057505050565b60209061310b6130e7565b81840152016130f4565b9061313a613122836130d0565b9260208061313086936130b3565b92019103906130f2565b565b5190565b9061314a8261313c565b81101561315b576020809102010190565b612164565b6131686130a8565b5061318d61317e61317960016120bf565b613115565b6131875f6121b8565b90613140565b5190565b61319b60a0611fe4565b90565b6131a6613191565b90602080808080866131b6612213565b8152016131c1612a5f565b8152016131cc612007565b8152016131d7612213565b8152016131e2612218565b81525050565b6131f061319e565b90565b67ffffffffffffffff811161320b5760208091020190565b611f8e565b9061322261321d836131f3565b611fe4565b918252565b61322f61319e565b90565b5f5b82811061324057505050565b60209061324b613227565b8184015201613234565b9061327a61326283613210565b9260208061327086936131f3565b9201910390613232565b565b5190565b9061328a8261327c565b81101561329b576020809102010190565b612164565b6132a86131e8565b506132cd6132be6132b960016120bf565b613255565b6132c75f6121b8565b90613280565b5190565b6132db60c0611fe4565b90565b6132e66132d1565b9060208080808080876132f7612007565b81520161330261200b565b81520161330d612007565b815201613318612010565b815201613323612007565b81520161332e612010565b81525050565b61333c6132de565b90565b67ffffffffffffffff81116133575760208091020190565b611f8e565b9061336e6133698361333f565b611fe4565b918252565b61337b6132de565b90565b5f5b82811061338c57505050565b602090613397613373565b8184015201613380565b906133c66133ae8361335c565b926020806133bc869361333f565b920191039061337e565b565b5190565b906133d6826133c8565b8110156133e7576020809102010190565b612164565b6133f4613334565b5061341961340a61340560016120bf565b6133a1565b6134135f6121b8565b906133cc565b5190565b61342760e0611fe4565b90565b61343261341d565b90602080808080808088613444612007565b81520161344f61200b565b81520161345a612007565b815201613465612007565b815201613470612010565b81520161347b612014565b815201613486612010565b81525050565b61349461342a565b90565b67ffffffffffffffff81116134af5760208091020190565b611f8e565b906134c66134c183613497565b611fe4565b918252565b6134d361342a565b90565b5f5b8281106134e457505050565b6020906134ef6134cb565b81840152016134d8565b9061351e613506836134b4565b926020806135148693613497565b92019103906134d6565b565b5190565b9061352e82613520565b81101561353f576020809102010190565b612164565b61354c61348c565b5061357161356261355d60016120bf565b6134f9565b61356b5f6121b8565b90613524565b5190565b61357f60c0611fe4565b90565b61358a613575565b90602080808080808761359b612007565b8152016135a661200b565b8152016135b1612007565b8152016135bc612010565b8152016135c7612007565b8152016135d2612010565b81525050565b6135e0613582565b90565b67ffffffffffffffff81116135fb5760208091020190565b611f8e565b9061361261360d836135e3565b611fe4565b918252565b61361f613582565b90565b5f5b82811061363057505050565b60209061363b613617565b8184015201613624565b9061366a61365283613600565b9260208061366086936135e3565b9201910390613622565b565b5190565b9061367a8261366c565b81101561368b576020809102010190565b612164565b6136986135d8565b506136bd6136ae6136a960016120bf565b613645565b6136b75f6121b8565b90613670565b5190565b6136cc610240611fe4565b90565b6136d76136c1565b90816136e161200b565b81526020016136ee612010565b81526020016136fb612007565b8152602001613708612007565b8152602001613715612007565b8152602001613722612007565b815260200161372f612018565b815260200161373c612007565b815260200161374961200b565b8152602001613756612010565b8152602001613763612007565b815260200161377061200b565b815260200161377d61200b565b815260200161378a612014565b8152602001613797612007565b81526020016137a461200b565b81526020016137b1612010565b81526020016137be612007565b815250565b6137cb6136cf565b90565b67ffffffffffffffff81116137e65760208091020190565b611f8e565b906137fd6137f8836137ce565b611fe4565b918252565b61380a6136cf565b90565b5f5b82811061381b57505050565b602090613826613802565b818401520161380f565b9061385561383d836137eb565b9260208061384b86936137ce565b920191039061380d565b565b5190565b9061386582613857565b811015613876576020809102010190565b612164565b6138836137c3565b506138a861389961389460016120bf565b613830565b6138a25f6121b8565b9061385b565b5190565b6138b7610140611fe4565b90565b6138c26138ac565b9060208080808080808080808b6138d7612007565b8152016138e261200b565b8152016138ed612007565b8152016138f8612213565b815201613903612a5f565b81520161390e612213565b815201613919612218565b815201613924612010565b81520161392f612007565b81520161393a612010565b81525050565b6139486138ba565b90565b67ffffffffffffffff81116139635760208091020190565b611f8e565b9061397a6139758361394b565b611fe4565b918252565b6139876138ba565b90565b5f5b82811061399857505050565b6020906139a361397f565b818401520161398c565b906139d26139ba83613968565b926020806139c8869361394b565b920191039061398a565b565b5190565b906139e2826139d4565b8110156139f3576020809102010190565b612164565b613a00613940565b50613a25613a16613a1160016120bf565b6139ad565b613a1f5f6121b8565b906139d8565b5190565b613a34610160611fe4565b90565b613a3f613a29565b906020808080808080808080808c613a55612007565b815201613a6061200b565b815201613a6b612007565b815201613a76612007565b815201613a8161200b565b815201613a8c612007565b815201613a97612010565b815201613aa2612010565b815201613aad612014565b815201613ab8612007565b815201613ac3612010565b81525050565b613ad1613a37565b90565b67ffffffffffffffff8111613aec5760208091020190565b611f8e565b90613b03613afe83613ad4565b611fe4565b918252565b613b10613a37565b90565b5f5b828110613b2157505050565b602090613b2c613b08565b8184015201613b15565b90613b5b613b4383613af1565b92602080613b518693613ad4565b9201910390613b13565b565b5190565b90613b6b82613b5d565b811015613b7c576020809102010190565b612164565b613b89613ac9565b50613bae613b9f613b9a60016120bf565b613b36565b613ba85f6121b8565b90613b61565b5190565b613bbd610180611fe4565b90565b613bc8613bb2565b90602080808080808080808080808d613bdf612007565b815201613bea612007565b815201613bf561200b565b815201613c00612010565b815201613c0b612007565b815201613c16612007565b815201613c2161200b565b815201613c2c612010565b815201613c37612007565b815201613c42612007565b815201613c4d612018565b815201613c58612018565b81525050565b613c66613bc0565b90565b67ffffffffffffffff8111613c815760208091020190565b611f8e565b90613c98613c9383613c69565b611fe4565b918252565b613ca5613bc0565b90565b5f5b828110613cb657505050565b602090613cc1613c9d565b8184015201613caa565b90613cf0613cd883613c86565b92602080613ce68693613c69565b9201910390613ca8565b565b5190565b90613d0082613cf2565b811015613d11576020809102010190565b612164565b613d1e613c5e565b50613d43613d34613d2f60016120bf565b613ccb565b613d3d5f6121b8565b90613cf6565b5190565b613d52610220611fe4565b90565b613d5d613d47565b9081613d6761200b565b8152602001613d74612010565b8152602001613d81612007565b8152602001613d8e612007565b8152602001613d9b612007565b8152602001613da8612007565b8152602001613db5612007565b8152602001613dc261200b565b8152602001613dcf612010565b8152602001613ddc612007565b8152602001613de961200b565b8152602001613df661200b565b8152602001613e03612014565b8152602001613e10612007565b8152602001613e1d61200b565b8152602001613e2a612010565b8152602001613e37612007565b815250565b613e44613d55565b90565b67ffffffffffffffff8111613e5f5760208091020190565b611f8e565b90613e76613e7183613e47565b611fe4565b918252565b613e83613d55565b90565b5f5b828110613e9457505050565b602090613e9f613e7b565b8184015201613e88565b90613ece613eb683613e64565b92602080613ec48693613e47565b9201910390613e86565b565b5190565b90613ede82613ed0565b811015613eef576020809102010190565b612164565b613efc613e3c565b50613f21613f12613f0d60016120bf565b613ea9565b613f1b5f6121b8565b90613ed4565b5190565b613f2f60c0611fe4565b90565b613f3a613f25565b906020808080808087613f4b612007565b815201613f5661200b565b815201613f61612007565b815201613f6c612010565b815201613f77612007565b815201613f82612010565b81525050565b613f90613f32565b90565b67ffffffffffffffff8111613fab5760208091020190565b611f8e565b90613fc2613fbd83613f93565b611fe4565b918252565b613fcf613f32565b90565b5f5b828110613fe057505050565b602090613feb613fc7565b8184015201613fd4565b9061401a61400283613fb0565b926020806140108693613f93565b9201910390613fd2565b565b5190565b9061402a8261401c565b81101561403b576020809102010190565b612164565b614048613f88565b5061406d61405e61405960016120bf565b613ff5565b6140675f6121b8565b90614020565b5190565b61407b60c0611fe4565b90565b614086614071565b906020808080808087614097612007565b8152016140a261200b565b8152016140ad612007565b8152016140b8612010565b8152016140c3612007565b8152016140ce612010565b81525050565b6140dc61407e565b90565b67ffffffffffffffff81116140f75760208091020190565b611f8e565b9061410e614109836140df565b611fe4565b918252565b61411b61407e565b90565b5f5b82811061412c57505050565b602090614137614113565b8184015201614120565b9061416661414e836140fc565b9260208061415c86936140df565b920191039061411e565b565b5190565b9061417682614168565b811015614187576020809102010190565b612164565b6141946140d4565b506141b96141aa6141a560016120bf565b614141565b6141b35f6121b8565b9061416c565b5190565b6141c8610160611fe4565b90565b6141d36141bd565b906020808080808080808080808c6141e9612007565b8152016141f461200b565b8152016141ff612007565b81520161420a612007565b81520161421561200b565b815201614220612007565b81520161422b612010565b815201614236612010565b815201614241612014565b81520161424c612007565b815201614257612010565b81525050565b6142656141cb565b90565b67ffffffffffffffff81116142805760208091020190565b611f8e565b9061429761429283614268565b611fe4565b918252565b6142a46141cb565b90565b5f5b8281106142b557505050565b6020906142c061429c565b81840152016142a9565b906142ef6142d783614285565b926020806142e58693614268565b92019103906142a7565b565b5190565b906142ff826142f1565b811015614310576020809102010190565b612164565b61431d61425d565b5061434261433361432e60016120bf565b6142ca565b61433c5f6121b8565b906142f5565b5190565b614351610240611fe4565b90565b61435c614346565b908161436661200b565b8152602001614373612010565b8152602001614380612007565b815260200161438d612007565b815260200161439a612007565b81526020016143a7612007565b81526020016143b4612018565b81526020016143c1612007565b81526020016143ce61200b565b81526020016143db612010565b81526020016143e8612007565b81526020016143f561200b565b815260200161440261200b565b815260200161440f612014565b815260200161441c612007565b815260200161442961200b565b8152602001614436612010565b8152602001614443612007565b815250565b614450614354565b90565b67ffffffffffffffff811161446b5760208091020190565b611f8e565b9061448261447d83614453565b611fe4565b918252565b61448f614354565b90565b5f5b8281106144a057505050565b6020906144ab614487565b8184015201614494565b906144da6144c283614470565b926020806144d08693614453565b9201910390614492565b565b5190565b906144ea826144dc565b8110156144fb576020809102010190565b612164565b614508614448565b5061452d61451e61451960016120bf565b6144b5565b6145275f6121b8565b906144e0565b5190565b61453c610160611fe4565b90565b614547614531565b906020808080808080808080808c61455d612007565b81520161456861200b565b815201614573612010565b81520161457e612007565b815201614589612007565b81520161459461200b565b81520161459f612010565b8152016145aa612007565b8152016145b561200b565b8152016145c0612014565b8152016145cb612018565b81525050565b6145d961453f565b90565b67ffffffffffffffff81116145f45760208091020190565b611f8e565b9061460b614606836145dc565b611fe4565b918252565b61461861453f565b90565b5f5b82811061462957505050565b602090614634614610565b818401520161461d565b9061466361464b836145f9565b9260208061465986936145dc565b920191039061461b565b565b5190565b9061467382614665565b811015614684576020809102010190565b612164565b6146916145d1565b506146b66146a76146a260016120bf565b61463e565b6146b05f6121b8565b90614669565b5190565b6146c460a0611fe4565b90565b6146cf6146ba565b90602080808080866146df612213565b8152016146ea612a5f565b8152016146f5612007565b815201614700612213565b81520161470b612218565b81525050565b6147196146c7565b90565b67ffffffffffffffff81116147345760208091020190565b611f8e565b9061474b6147468361471c565b611fe4565b918252565b6147586146c7565b90565b5f5b82811061476957505050565b602090614774614750565b818401520161475d565b906147a361478b83614739565b92602080614799869361471c565b920191039061475b565b565b5190565b906147b3826147a5565b8110156147c4576020809102010190565b612164565b6147d1614711565b506147f66147e76147e260016120bf565b61477e565b6147f05f6121b8565b906147a9565b519056"

    public static let BridgingUnsupportedForAssetError = ABI.Function(
            name: "BridgingUnsupportedForAsset",
            inputs: []
    )

    public static let InvalidAssetForBridgeError = ABI.Function(
            name: "InvalidAssetForBridge",
            inputs: []
    )

    public static let InvalidAssetForWrappingActionError = ABI.Function(
            name: "InvalidAssetForWrappingAction",
            inputs: []
    )

    public static let UnknownAaveMarketError = ABI.Function(
            name: "UnknownAaveMarket",
            inputs: [.address, .uint256]
    )

    public static let UnknownAssetError = ABI.Function(
            name: "UnknownAsset",
            inputs: [.string, .address, .uint256]
    )

    public static let UnknownCometError = ABI.Function(
            name: "UnknownComet",
            inputs: [.address, .uint256]
    )

    public static let UnknownCometRewardsError = ABI.Function(
            name: "UnknownCometRewards",
            inputs: [.address, .uint256]
    )

    public static let UnknownMorphoMarketError = ABI.Function(
            name: "UnknownMorphoMarket",
            inputs: [.bytes32, .uint256]
    )

    public static let UnknownMorphoVaultError = ABI.Function(
            name: "UnknownMorphoVault",
            inputs: [.address, .uint256]
    )


    public enum RevertReason : Equatable, Error {
        case bridgingUnsupportedForAsset
        case invalidAssetForBridge
        case invalidAssetForWrappingAction
        case unknownAaveMarket(EthAddress, Number)
        case unknownAsset(String, EthAddress, Number)
        case unknownComet(EthAddress, Number)
        case unknownCometRewards(EthAddress, Number)
        case unknownMorphoMarket(Hex, Number)
        case unknownMorphoVault(EthAddress, Number)
        case unknownRevert(String, String)
    }
    public static func rewrapError(_ error: ABI.Function, value: ABI.Value) -> RevertReason {
        switch (error, value) {
        case (BridgingUnsupportedForAssetError, _):
            return .bridgingUnsupportedForAsset
        case (InvalidAssetForBridgeError, _):
            return .invalidAssetForBridge
        case (InvalidAssetForWrappingActionError, _):
            return .invalidAssetForWrappingAction
        case (UnknownAaveMarketError, let .tuple2(.address(aavePool), .uint256(chainId))):
            return .unknownAaveMarket(aavePool, chainId)
        case (UnknownAssetError, let .tuple3(.string(assetSymbol), .address(assetAddress), .uint256(chainId))):
            return .unknownAsset(assetSymbol, assetAddress, chainId)
        case (UnknownCometError, let .tuple2(.address(comet), .uint256(chainId))):
            return .unknownComet(comet, chainId)
        case (UnknownCometRewardsError, let .tuple2(.address(cometReward), .uint256(chainId))):
            return .unknownCometRewards(cometReward, chainId)
        case (UnknownMorphoMarketError, let .tuple2(.bytes32(marketId), .uint256(chainId))):
            return .unknownMorphoMarket(marketId, chainId)
        case (UnknownMorphoVaultError, let .tuple2(.address(morphoVault), .uint256(chainId))):
            return .unknownMorphoVault(morphoVault, chainId)
        case let (e, v):
            return .unknownRevert(e.name, String(describing: v))
        }
    }
    public static let errors: [ABI.Function] = [BridgingUnsupportedForAssetError, InvalidAssetForBridgeError, InvalidAssetForWrappingActionError, UnknownAaveMarketError, UnknownAssetError, UnknownCometError, UnknownCometRewardsError, UnknownMorphoMarketError, UnknownMorphoVaultError]
    public static let functions: [ABI.Function] = [emptyAaveSupplyActionContextFn, emptyAaveWithdrawActionContextFn, emptyAddBackingTokenActionContextFn, emptyBorrowActionContextFn, emptyBridgeActionContextFn, emptyCometClaimRewardsActionContextFn, emptyCometSupplyActionContextFn, emptyCometWithdrawActionContextFn, emptyDripTokensActionContextFn, emptyLoopLongActionContextFn, emptyLoopShortActionContextFn, emptyMorphoBorrowActionContextFn, emptyMorphoClaimRewardsActionContextFn, emptyMorphoRepayActionContextFn, emptyMorphoVaultSupplyActionContextFn, emptyMorphoVaultWithdrawActionContextFn, emptyMultiActionContextFn, emptyQuotePayActionContextFn, emptyRecurringSwapActionContextFn, emptyRepayActionContextFn, emptySwapActionContextFn, emptyTransferActionContextFn, emptyUnloopLongActionContextFn, emptyUnloopShortActionContextFn, emptyWithdrawAndBorrowActionContextFn, emptyWithdrawBackingTokenActionContextFn, emptyWrapOrUnwrapActionContextFn]
    public static let emptyAaveSupplyActionContextFn = ABI.Function(
            name: "emptyAaveSupplyActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .address, .uint256, .address])]
    )

    public static func emptyAaveSupplyActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<AaveSupplyActionContext, RevertReason> {
            do {
                let query = try emptyAaveSupplyActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyAaveSupplyActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple6(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .address(aavePool),
     .uint256(price),
     .address(token))):
                    return .success(AaveSupplyActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, aavePool: aavePool, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyAaveSupplyActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyAaveSupplyActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyAaveSupplyActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyAaveSupplyActionContextFn.inputTuple)
        }
    }

    public static let emptyAaveWithdrawActionContextFn = ABI.Function(
            name: "emptyAaveWithdrawActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .address, .uint256, .address])]
    )

    public static func emptyAaveWithdrawActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<AaveWithdrawActionContext, RevertReason> {
            do {
                let query = try emptyAaveWithdrawActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyAaveWithdrawActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple6(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .address(aavePool),
     .uint256(price),
     .address(token))):
                    return .success(AaveWithdrawActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, aavePool: aavePool, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyAaveWithdrawActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyAaveWithdrawActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyAaveWithdrawActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyAaveWithdrawActionContextFn.inputTuple)
        }
    }

    public static let emptyAddBackingTokenActionContextFn = ABI.Function(
            name: "emptyAddBackingTokenActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .string, .bytes32, .bool])]
    )

    public static func emptyAddBackingTokenActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<AddBackingTokenActionContext, RevertReason> {
            do {
                let query = try emptyAddBackingTokenActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyAddBackingTokenActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple11(.uint256(amount),
     .string(backingAssetSymbol),
     .address(backingToken),
     .uint256(backingTokenPrice),
     .uint256(chainId),
     .string(exposureAssetSymbol),
     .address(exposureToken),
     .uint256(exposureTokenPrice),
     .string(borrowVenue),
     .bytes32(borrowMarketId),
     .bool(isShort))):
                    return .success(AddBackingTokenActionContext(amount: amount, backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, chainId: chainId, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, isShort: isShort))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyAddBackingTokenActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyAddBackingTokenActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyAddBackingTokenActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyAddBackingTokenActionContextFn.inputTuple)
        }
    }

    public static let emptyBorrowActionContextFn = ABI.Function(
            name: "emptyBorrowActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .array(.uint256), .array(.string), .array(.uint256), .array(.address), .address, .uint256, .address])]
    )

    public static func emptyBorrowActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<BorrowActionContext, RevertReason> {
            do {
                let query = try emptyBorrowActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyBorrowActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple10(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .array(.uint256, collateralAmounts),
     .array(.string, collateralAssetSymbols),
     .array(.uint256, collateralTokenPrices),
     .array(.address, collateralTokens),
     .address(comet),
     .uint256(price),
     .address(token))):
                    return .success(BorrowActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmounts: collateralAmounts.map {
                                    $0.asNumber!
                                }, collateralAssetSymbols: collateralAssetSymbols.map {
                                    $0.asString!
                                }, collateralTokenPrices: collateralTokenPrices.map {
                                    $0.asNumber!
                                }, collateralTokens: collateralTokens.map {
                                    $0.asEthAddress!
                                }, comet: comet, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyBorrowActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyBorrowActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyBorrowActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyBorrowActionContextFn.inputTuple)
        }
    }

    public static let emptyBridgeActionContextFn = ABI.Function(
            name: "emptyBridgeActionContext",
            inputs: [],
            outputs: [.tuple([.string, .string, .uint256, .uint256, .uint256, .uint256, .uint256, .address, .address])]
    )

    public static func emptyBridgeActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<BridgeActionContext, RevertReason> {
            do {
                let query = try emptyBridgeActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyBridgeActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple9(.string(assetSymbol),
     .string(bridgeType),
     .uint256(chainId),
     .uint256(destinationChainId),
     .uint256(inputAmount),
     .uint256(outputAmount),
     .uint256(price),
     .address(recipient),
     .address(token))):
                    return .success(BridgeActionContext(assetSymbol: assetSymbol, bridgeType: bridgeType, chainId: chainId, destinationChainId: destinationChainId, inputAmount: inputAmount, outputAmount: outputAmount, price: price, recipient: recipient, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyBridgeActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyBridgeActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyBridgeActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyBridgeActionContextFn.inputTuple)
        }
    }

    public static let emptyCometClaimRewardsActionContextFn = ABI.Function(
            name: "emptyCometClaimRewardsActionContext",
            inputs: [],
            outputs: [.tuple([.array(.uint256), .array(.string), .uint256, .array(.uint256), .array(.address)])]
    )

    public static func emptyCometClaimRewardsActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<CometClaimRewardsActionContext, RevertReason> {
            do {
                let query = try emptyCometClaimRewardsActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyCometClaimRewardsActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple5(.array(.uint256, amounts),
     .array(.string, assetSymbols),
     .uint256(chainId),
     .array(.uint256, prices),
     .array(.address, tokens))):
                    return .success(CometClaimRewardsActionContext(amounts: amounts.map {
                                    $0.asNumber!
                                }, assetSymbols: assetSymbols.map {
                                    $0.asString!
                                }, chainId: chainId, prices: prices.map {
                                    $0.asNumber!
                                }, tokens: tokens.map {
                                    $0.asEthAddress!
                                }))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyCometClaimRewardsActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyCometClaimRewardsActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyCometClaimRewardsActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyCometClaimRewardsActionContextFn.inputTuple)
        }
    }

    public static let emptyCometSupplyActionContextFn = ABI.Function(
            name: "emptyCometSupplyActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .address, .uint256, .address])]
    )

    public static func emptyCometSupplyActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<CometSupplyActionContext, RevertReason> {
            do {
                let query = try emptyCometSupplyActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyCometSupplyActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple6(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .address(comet),
     .uint256(price),
     .address(token))):
                    return .success(CometSupplyActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, comet: comet, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyCometSupplyActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyCometSupplyActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyCometSupplyActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyCometSupplyActionContextFn.inputTuple)
        }
    }

    public static let emptyCometWithdrawActionContextFn = ABI.Function(
            name: "emptyCometWithdrawActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .address, .uint256, .address])]
    )

    public static func emptyCometWithdrawActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<CometWithdrawActionContext, RevertReason> {
            do {
                let query = try emptyCometWithdrawActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyCometWithdrawActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple6(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .address(comet),
     .uint256(price),
     .address(token))):
                    return .success(CometWithdrawActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, comet: comet, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyCometWithdrawActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyCometWithdrawActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyCometWithdrawActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyCometWithdrawActionContextFn.inputTuple)
        }
    }

    public static let emptyDripTokensActionContextFn = ABI.Function(
            name: "emptyDripTokensActionContext",
            inputs: [],
            outputs: [.tuple([.uint256])]
    )

    public static func emptyDripTokensActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<DripTokensActionContext, RevertReason> {
            do {
                let query = try emptyDripTokensActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyDripTokensActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple1(.uint256(chainId))):
                    return .success(DripTokensActionContext(chainId: chainId))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyDripTokensActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyDripTokensActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyDripTokensActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyDripTokensActionContextFn.inputTuple)
        }
    }

    public static let emptyLoopLongActionContextFn = ABI.Function(
            name: "emptyLoopLongActionContext",
            inputs: [],
            outputs: [.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .bool, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])]
    )

    public static func emptyLoopLongActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<LoopLongActionContext, RevertReason> {
            do {
                let query = try emptyLoopLongActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyLoopLongActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple18(.string(backingAssetSymbol),
     .address(backingToken),
     .uint256(backingTokenPrice),
     .uint256(maxSwapBackingAmount),
     .uint256(maxProvidedBackingAmount),
     .uint256(chainId),
     .bool(isIncrease),
     .uint256(exposureAmount),
     .string(exposureAssetSymbol),
     .address(exposureToken),
     .uint256(exposureTokenPrice),
     .string(swapVenue),
     .string(borrowVenue),
     .bytes32(borrowMarketId),
     .uint256(feeAmount),
     .string(feeAssetSymbol),
     .address(feeToken),
     .uint256(feeTokenPrice))):
                    return .success(LoopLongActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, maxSwapBackingAmount: maxSwapBackingAmount, maxProvidedBackingAmount: maxProvidedBackingAmount, chainId: chainId, isIncrease: isIncrease, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyLoopLongActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyLoopLongActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyLoopLongActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyLoopLongActionContextFn.inputTuple)
        }
    }

    public static let emptyLoopShortActionContextFn = ABI.Function(
            name: "emptyLoopShortActionContext",
            inputs: [],
            outputs: [.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .bool, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])]
    )

    public static func emptyLoopShortActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<LoopShortActionContext, RevertReason> {
            do {
                let query = try emptyLoopShortActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyLoopShortActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple18(.string(backingAssetSymbol),
     .address(backingToken),
     .uint256(backingTokenPrice),
     .uint256(minSwapBackingAmount),
     .uint256(providedBackingAmount),
     .uint256(chainId),
     .bool(isIncrease),
     .uint256(exposureAmount),
     .string(exposureAssetSymbol),
     .address(exposureToken),
     .uint256(exposureTokenPrice),
     .string(swapVenue),
     .string(borrowVenue),
     .bytes32(borrowMarketId),
     .uint256(feeAmount),
     .string(feeAssetSymbol),
     .address(feeToken),
     .uint256(feeTokenPrice))):
                    return .success(LoopShortActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, minSwapBackingAmount: minSwapBackingAmount, providedBackingAmount: providedBackingAmount, chainId: chainId, isIncrease: isIncrease, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyLoopShortActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyLoopShortActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyLoopShortActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyLoopShortActionContextFn.inputTuple)
        }
    }

    public static let emptyMorphoBorrowActionContextFn = ABI.Function(
            name: "emptyMorphoBorrowActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .uint256, .string, .uint256, .address, .address, .bytes32, .uint256, .address])]
    )

    public static func emptyMorphoBorrowActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<MorphoBorrowActionContext, RevertReason> {
            do {
                let query = try emptyMorphoBorrowActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyMorphoBorrowActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple11(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .uint256(collateralAmount),
     .string(collateralAssetSymbol),
     .uint256(collateralTokenPrice),
     .address(collateralToken),
     .address(morpho),
     .bytes32(morphoMarketId),
     .uint256(price),
     .address(token))):
                    return .success(MorphoBorrowActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmount: collateralAmount, collateralAssetSymbol: collateralAssetSymbol, collateralTokenPrice: collateralTokenPrice, collateralToken: collateralToken, morpho: morpho, morphoMarketId: morphoMarketId, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyMorphoBorrowActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyMorphoBorrowActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyMorphoBorrowActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyMorphoBorrowActionContextFn.inputTuple)
        }
    }

    public static let emptyMorphoClaimRewardsActionContextFn = ABI.Function(
            name: "emptyMorphoClaimRewardsActionContext",
            inputs: [],
            outputs: [.tuple([.array(.uint256), .array(.string), .uint256, .array(.uint256), .array(.address)])]
    )

    public static func emptyMorphoClaimRewardsActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<MorphoClaimRewardsActionContext, RevertReason> {
            do {
                let query = try emptyMorphoClaimRewardsActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyMorphoClaimRewardsActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple5(.array(.uint256, amounts),
     .array(.string, assetSymbols),
     .uint256(chainId),
     .array(.uint256, prices),
     .array(.address, tokens))):
                    return .success(MorphoClaimRewardsActionContext(amounts: amounts.map {
                                    $0.asNumber!
                                }, assetSymbols: assetSymbols.map {
                                    $0.asString!
                                }, chainId: chainId, prices: prices.map {
                                    $0.asNumber!
                                }, tokens: tokens.map {
                                    $0.asEthAddress!
                                }))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyMorphoClaimRewardsActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyMorphoClaimRewardsActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyMorphoClaimRewardsActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyMorphoClaimRewardsActionContextFn.inputTuple)
        }
    }

    public static let emptyMorphoRepayActionContextFn = ABI.Function(
            name: "emptyMorphoRepayActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .uint256, .string, .uint256, .address, .address, .bytes32, .uint256, .address])]
    )

    public static func emptyMorphoRepayActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<MorphoRepayActionContext, RevertReason> {
            do {
                let query = try emptyMorphoRepayActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyMorphoRepayActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple11(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .uint256(collateralAmount),
     .string(collateralAssetSymbol),
     .uint256(collateralTokenPrice),
     .address(collateralToken),
     .address(morpho),
     .bytes32(morphoMarketId),
     .uint256(price),
     .address(token))):
                    return .success(MorphoRepayActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmount: collateralAmount, collateralAssetSymbol: collateralAssetSymbol, collateralTokenPrice: collateralTokenPrice, collateralToken: collateralToken, morpho: morpho, morphoMarketId: morphoMarketId, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyMorphoRepayActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyMorphoRepayActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyMorphoRepayActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyMorphoRepayActionContextFn.inputTuple)
        }
    }

    public static let emptyMorphoVaultSupplyActionContextFn = ABI.Function(
            name: "emptyMorphoVaultSupplyActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .address, .uint256, .address])]
    )

    public static func emptyMorphoVaultSupplyActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<MorphoVaultSupplyActionContext, RevertReason> {
            do {
                let query = try emptyMorphoVaultSupplyActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyMorphoVaultSupplyActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple6(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .address(morphoVault),
     .uint256(price),
     .address(token))):
                    return .success(MorphoVaultSupplyActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, morphoVault: morphoVault, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyMorphoVaultSupplyActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyMorphoVaultSupplyActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyMorphoVaultSupplyActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyMorphoVaultSupplyActionContextFn.inputTuple)
        }
    }

    public static let emptyMorphoVaultWithdrawActionContextFn = ABI.Function(
            name: "emptyMorphoVaultWithdrawActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .address, .uint256, .address])]
    )

    public static func emptyMorphoVaultWithdrawActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<MorphoVaultWithdrawActionContext, RevertReason> {
            do {
                let query = try emptyMorphoVaultWithdrawActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyMorphoVaultWithdrawActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple6(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .address(morphoVault),
     .uint256(price),
     .address(token))):
                    return .success(MorphoVaultWithdrawActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, morphoVault: morphoVault, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyMorphoVaultWithdrawActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyMorphoVaultWithdrawActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyMorphoVaultWithdrawActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyMorphoVaultWithdrawActionContextFn.inputTuple)
        }
    }

    public static let emptyMultiActionContextFn = ABI.Function(
            name: "emptyMultiActionContext",
            inputs: [],
            outputs: [.tuple([.array(.string), .array(.bytes)])]
    )

    public static func emptyMultiActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<MultiActionContext, RevertReason> {
            do {
                let query = try emptyMultiActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyMultiActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple2(.array(.string, actionTypes),
     .array(.bytes, actionContexts))):
                    return .success(MultiActionContext(actionTypes: actionTypes.map {
                                    $0.asString!
                                }, actionContexts: actionContexts.map {
                                    $0.asHex!
                                }))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyMultiActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyMultiActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyMultiActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyMultiActionContextFn.inputTuple)
        }
    }

    public static let emptyQuotePayActionContextFn = ABI.Function(
            name: "emptyQuotePayActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .uint256, .address, .bytes32, .address])]
    )

    public static func emptyQuotePayActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<QuotePayActionContext, RevertReason> {
            do {
                let query = try emptyQuotePayActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyQuotePayActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple7(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .uint256(price),
     .address(payee),
     .bytes32(quoteId),
     .address(token))):
                    return .success(QuotePayActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, price: price, payee: payee, quoteId: quoteId, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyQuotePayActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyQuotePayActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyQuotePayActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyQuotePayActionContextFn.inputTuple)
        }
    }

    public static let emptyRecurringSwapActionContextFn = ABI.Function(
            name: "emptyRecurringSwapActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .uint256, .bool, .bool])]
    )

    public static func emptyRecurringSwapActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<RecurringSwapActionContext, RevertReason> {
            do {
                let query = try emptyRecurringSwapActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyRecurringSwapActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple12(.uint256(chainId),
     .uint256(inputAmount),
     .string(inputAssetSymbol),
     .address(inputToken),
     .uint256(inputTokenPrice),
     .uint256(outputAmount),
     .string(outputAssetSymbol),
     .address(outputToken),
     .uint256(outputTokenPrice),
     .uint256(interval),
     .bool(useChainlinkDataStream),
     .bool(useFiller))):
                    return .success(RecurringSwapActionContext(chainId: chainId, inputAmount: inputAmount, inputAssetSymbol: inputAssetSymbol, inputToken: inputToken, inputTokenPrice: inputTokenPrice, outputAmount: outputAmount, outputAssetSymbol: outputAssetSymbol, outputToken: outputToken, outputTokenPrice: outputTokenPrice, interval: interval, useChainlinkDataStream: useChainlinkDataStream, useFiller: useFiller))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyRecurringSwapActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyRecurringSwapActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyRecurringSwapActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyRecurringSwapActionContextFn.inputTuple)
        }
    }

    public static let emptyRepayActionContextFn = ABI.Function(
            name: "emptyRepayActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .array(.uint256), .array(.string), .array(.uint256), .array(.address), .address, .uint256, .address])]
    )

    public static func emptyRepayActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<RepayActionContext, RevertReason> {
            do {
                let query = try emptyRepayActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyRepayActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple10(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .array(.uint256, collateralAmounts),
     .array(.string, collateralAssetSymbols),
     .array(.uint256, collateralTokenPrices),
     .array(.address, collateralTokens),
     .address(comet),
     .uint256(price),
     .address(token))):
                    return .success(RepayActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, collateralAmounts: collateralAmounts.map {
                                    $0.asNumber!
                                }, collateralAssetSymbols: collateralAssetSymbols.map {
                                    $0.asString!
                                }, collateralTokenPrices: collateralTokenPrices.map {
                                    $0.asNumber!
                                }, collateralTokens: collateralTokens.map {
                                    $0.asEthAddress!
                                }, comet: comet, price: price, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyRepayActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyRepayActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyRepayActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyRepayActionContextFn.inputTuple)
        }
    }

    public static let emptySwapActionContextFn = ABI.Function(
            name: "emptySwapActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .array(.uint256), .array(.string), .array(.address), .array(.uint256), .array(.string), .uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .bool, .bool, .bool, .bool])]
    )

    public static func emptySwapActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<SwapActionContext, RevertReason> {
            do {
                let query = try emptySwapActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptySwapActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple18(.uint256(chainId),
     .array(.uint256, feeAmounts),
     .array(.string, feeAssetSymbols),
     .array(.address, feeTokens),
     .array(.uint256, feeTokenPrices),
     .array(.string, feeDescriptions),
     .uint256(inputAmount),
     .string(inputAssetSymbol),
     .address(inputToken),
     .uint256(inputTokenPrice),
     .uint256(outputAmount),
     .string(outputAssetSymbol),
     .address(outputToken),
     .uint256(outputTokenPrice),
     .bool(isExactOut),
     .bool(isBuy),
     .bool(isCappedMax),
     .bool(useFiller))):
                    return .success(SwapActionContext(chainId: chainId, feeAmounts: feeAmounts.map {
                                    $0.asNumber!
                                }, feeAssetSymbols: feeAssetSymbols.map {
                                    $0.asString!
                                }, feeTokens: feeTokens.map {
                                    $0.asEthAddress!
                                }, feeTokenPrices: feeTokenPrices.map {
                                    $0.asNumber!
                                }, feeDescriptions: feeDescriptions.map {
                                    $0.asString!
                                }, inputAmount: inputAmount, inputAssetSymbol: inputAssetSymbol, inputToken: inputToken, inputTokenPrice: inputTokenPrice, outputAmount: outputAmount, outputAssetSymbol: outputAssetSymbol, outputToken: outputToken, outputTokenPrice: outputTokenPrice, isExactOut: isExactOut, isBuy: isBuy, isCappedMax: isCappedMax, useFiller: useFiller))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptySwapActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptySwapActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptySwapActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptySwapActionContextFn.inputTuple)
        }
    }

    public static let emptyTransferActionContextFn = ABI.Function(
            name: "emptyTransferActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .uint256, .uint256, .address, .address])]
    )

    public static func emptyTransferActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<TransferActionContext, RevertReason> {
            do {
                let query = try emptyTransferActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyTransferActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple6(.uint256(amount),
     .string(assetSymbol),
     .uint256(chainId),
     .uint256(price),
     .address(recipient),
     .address(token))):
                    return .success(TransferActionContext(amount: amount, assetSymbol: assetSymbol, chainId: chainId, price: price, recipient: recipient, token: token))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyTransferActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyTransferActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyTransferActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyTransferActionContextFn.inputTuple)
        }
    }

    public static let emptyUnloopLongActionContextFn = ABI.Function(
            name: "emptyUnloopLongActionContext",
            inputs: [],
            outputs: [.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])]
    )

    public static func emptyUnloopLongActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<UnloopLongActionContext, RevertReason> {
            do {
                let query = try emptyUnloopLongActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyUnloopLongActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple17(.string(backingAssetSymbol),
     .address(backingToken),
     .uint256(backingTokenPrice),
     .uint256(minSwapBackingAmount),
     .uint256(backingAmountToExit),
     .uint256(chainId),
     .uint256(exposureAmount),
     .string(exposureAssetSymbol),
     .address(exposureToken),
     .uint256(exposureTokenPrice),
     .string(swapVenue),
     .string(borrowVenue),
     .bytes32(borrowMarketId),
     .uint256(feeAmount),
     .string(feeAssetSymbol),
     .address(feeToken),
     .uint256(feeTokenPrice))):
                    return .success(UnloopLongActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, minSwapBackingAmount: minSwapBackingAmount, backingAmountToExit: backingAmountToExit, chainId: chainId, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyUnloopLongActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyUnloopLongActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyUnloopLongActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyUnloopLongActionContextFn.inputTuple)
        }
    }

    public static let emptyUnloopShortActionContextFn = ABI.Function(
            name: "emptyUnloopShortActionContext",
            inputs: [],
            outputs: [.tuple([.string, .address, .uint256, .uint256, .uint256, .uint256, .uint256, .string, .address, .uint256, .string, .string, .bytes32, .uint256, .string, .address, .uint256])]
    )

    public static func emptyUnloopShortActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<UnloopShortActionContext, RevertReason> {
            do {
                let query = try emptyUnloopShortActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyUnloopShortActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple17(.string(backingAssetSymbol),
     .address(backingToken),
     .uint256(backingTokenPrice),
     .uint256(maxSwapBackingAmount),
     .uint256(backingAmountToExit),
     .uint256(chainId),
     .uint256(exposureAmount),
     .string(exposureAssetSymbol),
     .address(exposureToken),
     .uint256(exposureTokenPrice),
     .string(swapVenue),
     .string(borrowVenue),
     .bytes32(borrowMarketId),
     .uint256(feeAmount),
     .string(feeAssetSymbol),
     .address(feeToken),
     .uint256(feeTokenPrice))):
                    return .success(UnloopShortActionContext(backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, maxSwapBackingAmount: maxSwapBackingAmount, backingAmountToExit: backingAmountToExit, chainId: chainId, exposureAmount: exposureAmount, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, swapVenue: swapVenue, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, feeAmount: feeAmount, feeAssetSymbol: feeAssetSymbol, feeToken: feeToken, feeTokenPrice: feeTokenPrice))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyUnloopShortActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyUnloopShortActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyUnloopShortActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyUnloopShortActionContextFn.inputTuple)
        }
    }

    public static let emptyWithdrawAndBorrowActionContextFn = ABI.Function(
            name: "emptyWithdrawAndBorrowActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .uint256, .array(.uint256), .array(.uint256), .array(.address), .address, .uint256, .address, .uint256])]
    )

    public static func emptyWithdrawAndBorrowActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<WithdrawAndBorrowActionContext, RevertReason> {
            do {
                let query = try emptyWithdrawAndBorrowActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyWithdrawAndBorrowActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple9(.uint256(borrowAmount),
     .uint256(chainId),
     .array(.uint256, collateralAmounts),
     .array(.uint256, collateralTokenPrices),
     .array(.address, collateralTokens),
     .address(comet),
     .uint256(price),
     .address(token),
     .uint256(withdrawAmount))):
                    return .success(WithdrawAndBorrowActionContext(borrowAmount: borrowAmount, chainId: chainId, collateralAmounts: collateralAmounts.map {
                                    $0.asNumber!
                                }, collateralTokenPrices: collateralTokenPrices.map {
                                    $0.asNumber!
                                }, collateralTokens: collateralTokens.map {
                                    $0.asEthAddress!
                                }, comet: comet, price: price, token: token, withdrawAmount: withdrawAmount))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyWithdrawAndBorrowActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyWithdrawAndBorrowActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyWithdrawAndBorrowActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyWithdrawAndBorrowActionContextFn.inputTuple)
        }
    }

    public static let emptyWithdrawBackingTokenActionContextFn = ABI.Function(
            name: "emptyWithdrawBackingTokenActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .string, .address, .uint256, .uint256, .string, .address, .uint256, .string, .bytes32, .bool])]
    )

    public static func emptyWithdrawBackingTokenActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<WithdrawBackingTokenActionContext, RevertReason> {
            do {
                let query = try emptyWithdrawBackingTokenActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyWithdrawBackingTokenActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple11(.uint256(amount),
     .string(backingAssetSymbol),
     .address(backingToken),
     .uint256(backingTokenPrice),
     .uint256(chainId),
     .string(exposureAssetSymbol),
     .address(exposureToken),
     .uint256(exposureTokenPrice),
     .string(borrowVenue),
     .bytes32(borrowMarketId),
     .bool(isShort))):
                    return .success(WithdrawBackingTokenActionContext(amount: amount, backingAssetSymbol: backingAssetSymbol, backingToken: backingToken, backingTokenPrice: backingTokenPrice, chainId: chainId, exposureAssetSymbol: exposureAssetSymbol, exposureToken: exposureToken, exposureTokenPrice: exposureTokenPrice, borrowVenue: borrowVenue, borrowMarketId: borrowMarketId, isShort: isShort))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyWithdrawBackingTokenActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyWithdrawBackingTokenActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyWithdrawBackingTokenActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyWithdrawBackingTokenActionContextFn.inputTuple)
        }
    }

    public static let emptyWrapOrUnwrapActionContextFn = ABI.Function(
            name: "emptyWrapOrUnwrapActionContext",
            inputs: [],
            outputs: [.tuple([.uint256, .uint256, .address, .string, .string])]
    )

    public static func emptyWrapOrUnwrapActionContext(withFunctions ffis: EVM.FFIMap = [:]) throws -> Result<WrapOrUnwrapActionContext, RevertReason> {
            do {
                let query = try emptyWrapOrUnwrapActionContextFn.encoded(with: [])
                let result = try EVM.runQuery(bytecode: runtimeCode, query: query, withErrors: errors, withFunctions: ffis)
                let decoded = try emptyWrapOrUnwrapActionContextFn.decode(output: result)

                switch decoded {
                case let .tuple1(.tuple5(.uint256(chainId),
     .uint256(amount),
     .address(token),
     .string(fromAssetSymbol),
     .string(toAssetSymbol))):
                    return .success(WrapOrUnwrapActionContext(chainId: chainId, amount: amount, token: token, fromAssetSymbol: fromAssetSymbol, toAssetSymbol: toAssetSymbol))
                default:
                    throw ABI.DecodeError.mismatchedType(decoded.schema, emptyWrapOrUnwrapActionContextFn.outputTuple)
                }
            } catch let EVM.QueryError.error(e, v) {
                return .failure(rewrapError(e, value: v))
            }
    }


    public static func emptyWrapOrUnwrapActionContextDecode(input: Hex) throws -> () {
        let decodedInput = try emptyWrapOrUnwrapActionContextFn.decodeInput(input: input)
        switch decodedInput {
        case  .tuple0:
            return  (())
        default:
            throw ABI.DecodeError.mismatchedType(decodedInput.schema, emptyWrapOrUnwrapActionContextFn.inputTuple)
        }
    }

}