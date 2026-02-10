import Eth
import Foundation
import Prelude
import SwiftNumber

public struct Portfolio: Codable, Equatable, Sendable {
    public let wallets: [Wallet]
    public let block: Block
    public let chainId: UInt
    public let aaves: [Aave]
    public let comets: [Comet]
    public let morphos: [Morpho]
    public let morphoVaults: [MorphoVault]
    public let queryVersion: QueryVersion
    public let tokens: [Token]
    public let morphoRewardPositions: [MorphoRewardPosition]
    public let quarkNonceStatuses: [QuarkNonceStatus]
    public let acrossFillStatuses: [AcrossFillStatus]
    public let cctpV2FillStatuses: [CctpV2FillStatus]
    public let tokenWrapperQuotes: [TokenWrapperQuote]

    // Exposed Types
    public let chain: Network
    public let assets: [Asset]
    public let borrowMarkets: [BorrowMarket]
    public let earnMarkets: [EarnMarket]
    public let aaveMarkets: [AaveMarket]
    public let cometMarkets: [CometMarket]
    public let morphoMarkets: [MorphoMarket]
    public let morphoVaultMarkets: [MorphoVaultMarket]
    public let uniformRewards: [RewardAsset]
    public let airdropRewards: [RewardAsset]
    public let ethBalance: Amount

    public var blockTimestamp: UInt {
        block.timestamp
    }

    enum CodingKeys: String, CodingKey {
        case wallets
        case block
        case chainId = "chain_id"
        case aaves = "aave_markets"
        case comets
        case morphos = "morpho_markets"
        case morphoVaults = "morpho_vaults"
        case queryVersion = "query_version"
        case tokens
        case morphoRewardPositions = "morpho_reward_positions"
        case quarkNonceStatuses = "quark_nonce_statuses"
        case acrossFillStatuses = "across_fill_statuses"
        case cctpV2FillStatuses = "cctp_v2_fill_statuses"
        case tokenWrapperQuotes = "token_wrapper_quotes"
    }

    public init(
        wallets: [Wallet],
        block: Block,
        chainId: UInt,
        aaves: [Aave],
        comets: [Comet],
        morphos: [Morpho],
        morphoVaults: [MorphoVault],
        queryVersion: QueryVersion,
        tokens: [Token],
        morphoRewardPositions: [MorphoRewardPosition],
        quarkNonceStatuses: [QuarkNonceStatus] = [],
        acrossFillStatuses: [AcrossFillStatus] = [],
        cctpV2FillStatuses: [CctpV2FillStatus] = [],
        tokenWrapperQuotes: [TokenWrapperQuote] = []
    ) {
        self.wallets = wallets
        self.block = block
        self.chainId = chainId
        self.aaves = aaves
        self.comets = comets
        self.morphos = morphos
        self.morphoVaults = morphoVaults
        self.queryVersion = queryVersion
        self.tokens = tokens
        self.morphoRewardPositions = morphoRewardPositions
        self.quarkNonceStatuses = quarkNonceStatuses
        self.acrossFillStatuses = acrossFillStatuses
        self.cctpV2FillStatuses = cctpV2FillStatuses
        self.tokenWrapperQuotes = tokenWrapperQuotes

        let chain = Network.fromChainId(UInt(chainId))
        self.chain = chain
        assets = Self.getAssets(
            chain: chain,
            tokens: tokens,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
        cometMarkets = Self.getCometMarkets(
            chain: chain,
            comets: comets,
            tokens: tokens,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
        morphoMarkets = Self.getMorphoMarkets(
            chain: chain,
            morphos: morphos,
            morphoRewardPositions: morphoRewardPositions,
            tokens: tokens,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
        morphoVaultMarkets = Self.getMorphoVaultMarkets(
            chain: chain,
            morphoVaults: morphoVaults,
            morphoRewardPositions: morphoRewardPositions,
            tokens: tokens,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
        aaveMarkets = Self.getAaveMarkets(
            chain: chain,
            aaves: aaves,
            tokens: tokens,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
        borrowMarkets =
            cometMarkets.map { .cometMarket($0) } + morphoMarkets.map { .morphoMarket($0) }
        earnMarkets =
            cometMarkets.map { .cometMarket($0) } + morphoVaultMarkets.map { .morphoVault($0) }
            + aaveMarkets.map { .aaveMarket($0) }
        uniformRewards = Self.getUniformRewards(
            chain: chain,
            morphoRewardPositions: morphoRewardPositions,
            tokens: tokens,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
        airdropRewards = Self.getAirdropRewards(
            chain: chain,
            morphoRewardPositions: morphoRewardPositions,
            tokens: tokens,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
        ethBalance = Self.getEthBalance(tokens: tokens)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let wallets = try container.decode([Wallet].self, forKey: .wallets)
        let block = try container.decode(Block.self, forKey: .block)
        let chainId = try container.decode(UInt.self, forKey: .chainId)
        let aaves = try container.decode([Aave].self, forKey: .aaves)
        let comets = try container.decode([Comet].self, forKey: .comets)
        let morphos = try container.decode([Morpho].self, forKey: .morphos)
        let morphoVaults = try container.decode([MorphoVault].self, forKey: .morphoVaults)
        let queryVersion = try container.decode(QueryVersion.self, forKey: .queryVersion)
        let tokens = try container.decode([Token].self, forKey: .tokens)
        let morphoRewardPositions = try container.decode(
            [MorphoRewardPosition].self,
            forKey: .morphoRewardPositions
        )
        let quarkNonceStatuses = try container.decode(
            [QuarkNonceStatus].self,
            forKey: .quarkNonceStatuses
        )
        let acrossFillStatuses = try container.decode(
            [AcrossFillStatus].self,
            forKey: .acrossFillStatuses
        )
        let cctpV2FillStatuses = try container.decodeIfPresent(
            [CctpV2FillStatus].self,
            forKey: .cctpV2FillStatuses
        ) ?? []
        let tokenWrapperQuotes = try container.decode(
            [TokenWrapperQuote].self,
            forKey: .tokenWrapperQuotes
        )

        self.init(
            wallets: wallets,
            block: block,
            chainId: chainId,
            aaves: aaves,
            comets: comets,
            morphos: morphos,
            morphoVaults: morphoVaults,
            queryVersion: queryVersion,
            tokens: tokens,
            morphoRewardPositions: morphoRewardPositions,
            quarkNonceStatuses: quarkNonceStatuses,
            acrossFillStatuses: acrossFillStatuses,
            cctpV2FillStatuses: cctpV2FillStatuses,
            tokenWrapperQuotes: tokenWrapperQuotes
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wallets, forKey: .wallets)
        try container.encode(block, forKey: .block)
        try container.encode(chainId, forKey: .chainId)
        try container.encode(aaves, forKey: .aaves)
        try container.encode(comets, forKey: .comets)
        try container.encode(morphos, forKey: .morphos)
        try container.encode(morphoVaults, forKey: .morphoVaults)
        try container.encode(queryVersion, forKey: .queryVersion)
        try container.encode(tokens, forKey: .tokens)
        try container.encode(morphoRewardPositions, forKey: .morphoRewardPositions)
        try container.encode(quarkNonceStatuses, forKey: .quarkNonceStatuses)
        try container.encode(acrossFillStatuses, forKey: .acrossFillStatuses)
        try container.encode(tokenWrapperQuotes, forKey: .tokenWrapperQuotes)
    }

    public struct Wallet: Codable, Equatable, Sendable {
        public let hasCode: Bool
        public let isQuark: Bool
        public let quarkVersion: String
        public let wallet: EthAddress

        enum CodingKeys: String, CodingKey {
            case hasCode = "has_code"
            case isQuark = "is_quark"
            case quarkVersion = "quark_version"
            case wallet
        }

        public init(hasCode: Bool, isQuark: Bool, quarkVersion: String, wallet: EthAddress) {
            self.hasCode = hasCode
            self.isQuark = isQuark
            self.quarkVersion = quarkVersion
            self.wallet = wallet
        }
    }

    public struct Balance: Codable, Equatable, Sendable {
        public let balance: Amount
        public let wallet: EthAddress

        public init(balance: Amount, wallet: EthAddress) {
            self.balance = balance
            self.wallet = wallet
        }
    }

    public struct Block: Codable, Equatable, Sendable {
        public let number: UInt
        public let timestamp: UInt

        public init(number: UInt, timestamp: UInt) {
            self.number = number
            self.timestamp = timestamp
        }
    }

    public struct Aave: Codable, Equatable, Sendable {
        public let assets: [Asset]
        public let borrowPositions: [BorrowPosition]
        public let name: String
        public let pool: EthAddress

        enum CodingKeys: String, CodingKey {
            case assets = "asset_positions"
            case borrowPositions = "positions"
            case name
            case pool
        }

        public init(
            assets: [Asset],
            borrowPositions: [BorrowPosition],
            name: String,
            pool: EthAddress
        ) {
            self.assets = assets
            self.borrowPositions = borrowPositions
            self.name = name
            self.pool = pool
        }

        public init(
            aave: Aave,
            assets: [Asset]? = nil,
            borrowPositions: [BorrowPosition]? = nil,
            name: String? = nil,
            pool: EthAddress? = nil
        ) {
            self.assets = assets ?? aave.assets
            self.borrowPositions = borrowPositions ?? aave.borrowPositions
            self.name = name ?? aave.name
            self.pool = pool ?? aave.pool
        }

        public struct Asset: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let decimals: Int
            public let basePriceDecimals: Int
            public let isActive: Bool
            public let isFrozen: Bool
            public let isPaused: Bool
            public let positions: [Position]
            public let supplyApr: Percentage
            public let borrowApr: Percentage
            public let supplyCap: Amount
            public let borrowCap: Amount
            public let basePrice: Amount
            public let borrowingEnabled: Bool
            public let usageAsCollateralEnabled: Bool
            public let symbol: String
            public let collateralLtv: Amount
            public let liquidationLtv: Amount
            public let isBorrowableInIsolation: Bool
            public let totalSupply: Amount
            public let totalBorrow: Amount
            public let usdPrice: Value
            public let isSiloedBorrowing: Bool

            enum CodingKeys: String, CodingKey {
                case address
                case decimals
                case basePriceDecimals = "base_price_decimals"
                case isActive = "is_active"
                case isFrozen = "is_frozen"
                case isPaused = "is_paused"
                case positions
                case supplyApr = "supply_apr"
                case borrowApr = "borrow_apr"
                case supplyCap = "supply_cap"
                case borrowCap = "borrow_cap"
                case basePrice = "base_price"
                case borrowingEnabled = "borrowing_enabled"
                case usageAsCollateralEnabled = "usage_as_collateral_enabled"
                case symbol
                case collateralLtv = "collateral_ltv"
                case liquidationLtv = "liquidation_ltv"
                case isBorrowableInIsolation = "is_borrowable_in_isolation"
                case totalSupply = "total_supply"
                case totalBorrow = "total_borrow"
                case usdPrice = "usd_price"
                case isSiloedBorrowing = "is_siloed_borrowing"
            }

            public init(
                address: EthAddress,
                decimals: Int,
                basePriceDecimals: Int,
                isActive: Bool,
                isFrozen: Bool,
                isPaused: Bool,
                positions: [Position],
                supplyApr: Percentage,
                borrowApr: Percentage,
                supplyCap: Amount,
                borrowCap: Amount,
                basePrice: Amount,
                borrowingEnabled: Bool,
                usageAsCollateralEnabled: Bool,
                symbol: String,
                collateralLtv: Amount,
                liquidationLtv: Amount,
                isBorrowableInIsolation: Bool,
                totalSupply: Amount,
                totalBorrow: Amount,
                usdPrice: Value,
                isSiloedBorrowing: Bool
            ) {
                self.address = address
                self.decimals = decimals
                self.basePriceDecimals = basePriceDecimals
                self.isActive = isActive
                self.isFrozen = isFrozen
                self.isPaused = isPaused
                self.positions = positions
                self.supplyApr = supplyApr
                self.borrowApr = borrowApr
                self.supplyCap = supplyCap
                self.borrowCap = borrowCap
                self.basePrice = basePrice
                self.borrowingEnabled = borrowingEnabled
                self.usageAsCollateralEnabled = usageAsCollateralEnabled
                self.symbol = symbol
                self.collateralLtv = collateralLtv
                self.liquidationLtv = liquidationLtv
                self.isBorrowableInIsolation = isBorrowableInIsolation
                self.totalSupply = totalSupply
                self.totalBorrow = totalBorrow
                self.usdPrice = usdPrice
                self.isSiloedBorrowing = isSiloedBorrowing
            }

            public init(
                _ asset: Asset,
                positions: [Position],
            ) {
                address = asset.address
                decimals = asset.decimals
                basePriceDecimals = asset.basePriceDecimals
                isActive = asset.isActive
                isFrozen = asset.isFrozen
                isPaused = asset.isPaused
                self.positions = positions
                supplyApr = asset.supplyApr
                borrowApr = asset.borrowApr
                supplyCap = asset.supplyCap
                borrowCap = asset.borrowCap
                basePrice = asset.basePrice
                borrowingEnabled = asset.borrowingEnabled
                usageAsCollateralEnabled = asset.usageAsCollateralEnabled
                symbol = asset.symbol
                collateralLtv = asset.collateralLtv
                liquidationLtv = asset.liquidationLtv
                isBorrowableInIsolation = asset.isBorrowableInIsolation
                totalSupply = asset.totalSupply
                totalBorrow = asset.totalBorrow
                usdPrice = asset.usdPrice
                isSiloedBorrowing = asset.isSiloedBorrowing
            }

            public struct Position: Codable, Equatable, Sendable {
                public let borrowed: Amount
                public let supplied: Amount
                public let wallet: EthAddress
                public let usageAsCollateralEnabledOnUser: Bool

                public init(
                    borrowed: Amount,
                    supplied: Amount,
                    wallet: EthAddress,
                    usageAsCollateralEnabledOnUser: Bool
                ) {
                    self.borrowed = borrowed
                    self.supplied = supplied
                    self.wallet = wallet
                    self.usageAsCollateralEnabledOnUser = usageAsCollateralEnabledOnUser
                }

                enum CodingKeys: String, CodingKey {
                    case borrowed
                    case supplied
                    case wallet
                    case usageAsCollateralEnabledOnUser = "usage_as_collateral_enabled_on_user"
                }
            }
        }

        public struct BorrowPosition: Codable, Equatable, Sendable {
            public let wallet: EthAddress
            public let baseBorrowCapacity: Amount
            public let baseLiquidationCapacity: Amount
            public let usdBorrowCapacity: Value
            public let usdLiquidationCapacity: Value

            public init(
                wallet: EthAddress,
                baseBorrowCapacity: Amount,
                baseLiquidationCapacity: Amount,
                usdBorrowCapacity: Value,
                usdLiquidationCapacity: Value
            ) {
                self.wallet = wallet
                self.baseBorrowCapacity = baseBorrowCapacity
                self.baseLiquidationCapacity = baseLiquidationCapacity
                self.usdBorrowCapacity = usdBorrowCapacity
                self.usdLiquidationCapacity = usdLiquidationCapacity
            }

            enum CodingKeys: String, CodingKey {
                case wallet
                case baseBorrowCapacity = "base_borrow_capacity"
                case baseLiquidationCapacity = "base_liquidation_point"
                case usdBorrowCapacity = "usd_borrow_capacity"
                case usdLiquidationCapacity = "usd_liquidation_point"
            }
        }
    }

    public struct Comet: Codable, Equatable, Sendable {
        public let address: EthAddress
        public let base: Base
        public let borrowApr: Percentage
        public let borrowRewardsApr: Percentage
        public let collaterals: [Collateral]
        public let name: String
        public let reward: Reward?
        public let supplyApr: Percentage
        public let supplyRewardsApr: Percentage
        public let symbol: String

        enum CodingKeys: String, CodingKey {
            case address
            case base
            case borrowApr = "borrow_apr"
            case borrowRewardsApr = "borrow_rewards_apr"
            case collaterals
            case name
            case reward
            case supplyApr = "supply_apr"
            case supplyRewardsApr = "supply_rewards_apr"
            case symbol
        }

        public init(
            address: EthAddress,
            base: Base,
            borrowApr: Percentage,
            borrowRewardsApr: Percentage,
            collaterals: [Collateral],
            name: String,
            reward: Reward?,
            supplyApr: Percentage,
            supplyRewardsApr: Percentage,
            symbol: String
        ) {
            self.address = address
            self.base = base
            self.borrowApr = borrowApr
            self.borrowRewardsApr = borrowRewardsApr
            self.collaterals = collaterals
            self.name = name
            self.reward = reward
            self.supplyApr = supplyApr
            self.supplyRewardsApr = supplyRewardsApr
            self.symbol = symbol
        }

        public init(
            comet: Comet,
            address: EthAddress? = nil,
            base: Base? = nil,
            borrowApr: Percentage? = nil,
            borrowRewardsApr: Percentage? = nil,
            collaterals: [Collateral]? = nil,
            name: String? = nil,
            reward: Reward?? = nil,
            supplyApr: Percentage? = nil,
            supplyRewardsApr: Percentage? = nil,
            symbol: String? = nil
        ) {
            self.address = address ?? comet.address
            self.base = base ?? comet.base
            self.borrowApr = borrowApr ?? comet.borrowApr
            self.borrowRewardsApr = borrowRewardsApr ?? comet.borrowRewardsApr
            self.collaterals = collaterals ?? comet.collaterals
            self.name = name ?? comet.name
            self.reward = reward ?? comet.reward
            self.supplyApr = supplyApr ?? comet.supplyApr
            self.supplyRewardsApr = supplyRewardsApr ?? comet.supplyRewardsApr
            self.symbol = symbol ?? comet.symbol
        }

        public struct Base: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let decimals: Int
            public let name: String
            public let positions: [Position]
            public let symbol: String
            public let totalBalance: Amount
            public let totalBorrow: Amount
            public let totalSupply: Amount
            public let usdPrice: Value

            enum CodingKeys: String, CodingKey {
                case address
                case decimals
                case name
                case positions
                case symbol
                case totalBalance = "total_balance"
                case totalBorrow = "total_borrow"
                case totalSupply = "total_supply"
                case usdPrice = "usd_price"
            }

            public init(
                address: EthAddress,
                decimals: Int,
                name: String,
                positions: [Position],
                symbol: String,
                totalBalance: Amount,
                totalBorrow: Amount,
                totalSupply: Amount,
                usdPrice: Value
            ) {
                self.address = address
                self.decimals = decimals
                self.name = name
                self.positions = positions
                self.symbol = Portfolio.validSymbol(symbol)
                self.totalBalance = totalBalance
                self.totalBorrow = totalBorrow
                self.totalSupply = totalSupply
                self.usdPrice = usdPrice
            }

            public init(
                base: Base,
                address: EthAddress? = nil,
                decimals: Int? = nil,
                name: String? = nil,
                positions: [Position]? = nil,
                symbol: String? = nil,
                totalBalance: Amount? = nil,
                totalBorrow: Amount? = nil,
                totalSupply: Amount? = nil,
                usdPrice: Value? = nil
            ) {
                self.address = address ?? base.address
                self.decimals = decimals ?? base.decimals
                self.name = name ?? base.name
                self.positions = positions ?? base.positions
                self.symbol = Portfolio.validSymbol(symbol ?? base.symbol)
                self.totalBalance = totalBalance ?? base.totalBalance
                self.totalBorrow = totalBorrow ?? base.totalBorrow
                self.totalSupply = totalSupply ?? base.totalSupply
                self.usdPrice = usdPrice ?? base.usdPrice
            }

            /// The total user borrow for this base asset across quark wallets
            public var userBorrow: Amount {
                positions
                    .map { $0.borrow }
                    .sum(decimals: decimals)
            }

            /// The total user borrow for this base asset across wallets in USD
            public var userBorrowValue: Value {
                positions
                    .map { $0.borrow * usdPrice }
                    .sum()
            }

            /// The total borrow capacity for this market in terms of base token
            public var userBorrowCapacity: Amount {
                guard let position = positions.first else {
                    print("No positions found for comet position userBorrowCapacity")
                    return Amount(0, decimals: decimals)
                }
                return position.baseBorrowCapacity
            }

            /// The liquidation capacity for this market in terms of base token
            public var userLiquidationCapacity: Amount {
                guard let position = positions.first else {
                    print("No positions found for comet position userLiquidationCapacity")
                    return Amount(0, decimals: decimals)
                }

                return position.baseLiquidationCapacity
            }
        }

        public struct Collateral: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let decimals: Int
            public let cometBalances: [Balance]
            public let borrowCollateralFactor: Percentage
            public let liquidateCollateralFactor: Percentage
            public let liquidationFactor: Percentage
            public let name: String
            public let supplyCap: Amount
            public let symbol: String
            public let totalSupply: Amount
            public let usdPrice: Value
            public let basePrice: Amount

            enum CodingKeys: String, CodingKey {
                case address
                case decimals
                case cometBalances = "balances"
                case borrowCollateralFactor = "borrow_collateral_factor"
                case liquidateCollateralFactor = "liquidate_collateral_factor"
                case liquidationFactor = "liquidation_factor"
                case name
                case supplyCap = "supply_cap"
                case symbol
                case totalSupply = "total_supply"
                case usdPrice = "usd_price"
                case basePrice = "base_price"
            }

            public init(
                address: EthAddress,
                decimals: Int,
                cometBalances: [Balance],
                borrowCollateralFactor: Percentage,
                liquidateCollateralFactor: Percentage,
                liquidationFactor: Percentage,
                name: String,
                supplyCap: Amount,
                symbol: String,
                totalSupply: Amount,
                usdPrice: Value,
                basePrice: Amount
            ) {
                self.address = address
                self.decimals = decimals
                self.cometBalances = cometBalances
                self.borrowCollateralFactor = borrowCollateralFactor
                self.liquidateCollateralFactor = liquidateCollateralFactor
                self.liquidationFactor = liquidationFactor
                self.name = name
                self.supplyCap = supplyCap
                self.symbol = Portfolio.validSymbol(symbol)
                self.totalSupply = totalSupply
                self.usdPrice = usdPrice
                self.basePrice = basePrice
            }

            public init(
                collateral: Collateral,
                address: EthAddress? = nil,
                decimals: Int? = nil,
                cometBalances: [Balance]? = nil,
                borrowCollateralFactor: Percentage? = nil,
                liquidateCollateralFactor: Percentage? = nil,
                liquidationFactor: Percentage? = nil,
                name: String? = nil,
                supplyCap: Amount? = nil,
                symbol: String? = nil,
                totalSupply: Amount? = nil,
                usdPrice: Value? = nil,
                basePrice: Amount? = nil
            ) {
                self.address = address ?? collateral.address
                self.decimals = decimals ?? collateral.decimals
                self.cometBalances = cometBalances ?? collateral.cometBalances
                self.borrowCollateralFactor =
                    borrowCollateralFactor ?? collateral.borrowCollateralFactor
                self.liquidateCollateralFactor =
                    liquidateCollateralFactor ?? collateral.liquidateCollateralFactor
                self.liquidationFactor = liquidationFactor ?? collateral.liquidationFactor
                self.name = name ?? collateral.name
                self.supplyCap = supplyCap ?? collateral.supplyCap
                self.symbol = Portfolio.validSymbol(symbol ?? collateral.symbol)
                self.totalSupply = totalSupply ?? collateral.totalSupply
                self.usdPrice = usdPrice ?? collateral.usdPrice
                self.basePrice = basePrice ?? collateral.basePrice
            }
        }

        public struct Reward: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let decimals: Int
            public let name: String
            public let positions: [Position]
            public let rewardsAddress: EthAddress
            public let symbol: String
            public let usdPrice: Value

            enum CodingKeys: String, CodingKey {
                case address
                case decimals
                case name
                case positions
                case rewardsAddress = "rewards_address"
                case symbol
                case usdPrice = "usd_price"
            }

            public struct Position: Codable, Equatable, Sendable {
                public let rewardOwed: Amount
                public let wallet: EthAddress

                public init(rewardOwed: Amount, wallet: EthAddress) {
                    self.rewardOwed = rewardOwed
                    self.wallet = wallet
                }

                enum CodingKeys: String, CodingKey {
                    case rewardOwed = "reward_owed"
                    case wallet
                }
            }

            public init(
                address: EthAddress,
                decimals: Int,
                name: String,
                positions: [Position],
                rewardsAddress: EthAddress,
                symbol: String,
                usdPrice: Value
            ) {
                self.address = address
                self.decimals = decimals
                self.name = name
                self.positions = positions
                self.rewardsAddress = rewardsAddress
                self.symbol = symbol
                self.usdPrice = usdPrice
            }

            public init(
                reward: Reward,
                address: EthAddress? = nil,
                decimals: Int? = nil,
                name: String? = nil,
                positions: [Position]? = nil,
                rewardsAddress: EthAddress? = nil,
                symbol: String? = nil,
                usdPrice: Value? = nil
            ) {
                self.address = address ?? reward.address
                self.decimals = decimals ?? reward.decimals
                self.name = name ?? reward.name
                self.positions = positions ?? reward.positions
                self.rewardsAddress = rewardsAddress ?? reward.rewardsAddress
                self.symbol = symbol ?? reward.symbol
                self.usdPrice = usdPrice ?? reward.usdPrice
            }

            public var rewardOwed: Amount {
                positions
                    .map { $0.rewardOwed }
                    .sum(decimals: decimals)
            }

            /// Total reward owed across quark wallets in USD
            public var rewardOwedValue: Value {
                positions
                    .map { $0.rewardOwed * usdPrice }
                    .sum()
            }
        }

        public struct Position: Codable, Equatable, Sendable {
            public let baseBorrowCapacity: Amount
            public let baseLiquidationCapacity: Amount
            public let borrow: Amount
            public let supply: Amount
            public let usdBorrowCapacity: Value
            public let usdLiquidationCapacity: Value
            public let wallet: EthAddress

            enum CodingKeys: String, CodingKey {
                case baseBorrowCapacity = "base_borrow_capacity"
                case baseLiquidationCapacity = "base_liquidation_point"
                case borrow
                case supply
                case usdBorrowCapacity = "usd_borrow_capacity"
                case usdLiquidationCapacity = "usd_liquidation_point"
                case wallet
            }

            public init(
                baseBorrowCapacity: Amount,
                baseLiquidationCapacity: Amount,
                borrow: Amount,
                supply: Amount,
                usdBorrowCapacity: Value,
                usdLiquidationCapacity: Value,
                wallet: EthAddress
            ) {
                self.baseBorrowCapacity = baseBorrowCapacity
                self.baseLiquidationCapacity = baseLiquidationCapacity
                self.borrow = borrow
                self.supply = supply
                self.usdBorrowCapacity = usdBorrowCapacity
                self.usdLiquidationCapacity = usdLiquidationCapacity
                self.wallet = wallet
            }

            public init(
                position: Position,
                baseBorrowCapacity: Amount? = nil,
                baseLiquidationCapacity: Amount? = nil,
                borrow: Amount? = nil,
                supply: Amount? = nil,
                usdBorrowCapacity: Value? = nil,
                usdLiquidationCapacity: Value? = nil,
                wallet: EthAddress? = nil
            ) {
                self.baseBorrowCapacity = baseBorrowCapacity ?? position.baseBorrowCapacity
                self.baseLiquidationCapacity =
                    baseLiquidationCapacity ?? position.baseLiquidationCapacity
                self.borrow = borrow ?? position.borrow
                self.supply = supply ?? position.supply
                self.usdBorrowCapacity = usdBorrowCapacity ?? position.usdBorrowCapacity
                self.usdLiquidationCapacity =
                    usdLiquidationCapacity ?? position.usdLiquidationCapacity
                self.wallet = wallet ?? position.wallet
            }
        }
    }

    public struct Morpho: Codable, Equatable, Sendable {
        public let marketId: Hex
        public let morpho: EthAddress
        public let loanAsset: LoanAsset
        public let collateralAsset: CollateralAsset
        public let borrowApr: Percentage
        public let fixnumDecimals: Int
        public let liquidationLoanToValue: Percentage
        public let borrowRewards: [BorrowReward]

        enum CodingKeys: String, CodingKey {
            case marketId = "market_id"
            case morpho
            case loanAsset = "loan_asset"
            case collateralAsset = "collateral_asset"
            case borrowApr = "borrow_apr"
            case fixnumDecimals = "fixnum_decimals"
            case liquidationLoanToValue = "liquidation_loan_to_value"
            case borrowRewards = "borrow_rewards_apr"
        }

        public init(
            marketId: Hex,
            morpho: EthAddress,
            loanAsset: LoanAsset,
            collateralAsset: CollateralAsset,
            borrowApr: Percentage,
            fixnumDecimals: Int,
            liquidationLoanToValue: Percentage,
            borrowRewards: [BorrowReward]
        ) {
            self.marketId = marketId
            self.morpho = morpho
            self.loanAsset = loanAsset
            self.collateralAsset = collateralAsset
            self.borrowApr = borrowApr
            self.fixnumDecimals = fixnumDecimals
            self.liquidationLoanToValue = liquidationLoanToValue
            self.borrowRewards = borrowRewards
        }

        public init(
            morpho: Morpho,
            marketId: Hex? = nil,
            address: EthAddress? = nil,
            loanAsset: LoanAsset? = nil,
            collateralAsset: CollateralAsset? = nil,
            borrowApr: Percentage? = nil,
            fixnumDecimals: Int? = nil,
            liquidationLoanToValue: Percentage? = nil,
            borrowRewards: [BorrowReward]? = nil
        ) {
            self.marketId = marketId ?? morpho.marketId
            self.morpho = address ?? morpho.morpho
            self.loanAsset = loanAsset ?? morpho.loanAsset
            self.collateralAsset = collateralAsset ?? morpho.collateralAsset
            self.borrowApr = borrowApr ?? morpho.borrowApr
            self.fixnumDecimals = fixnumDecimals ?? morpho.fixnumDecimals
            self.liquidationLoanToValue = liquidationLoanToValue ?? morpho.liquidationLoanToValue
            self.borrowRewards = borrowRewards ?? morpho.borrowRewards
        }

        public struct LoanAsset: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let decimals: Int
            public let name: String
            public let positions: [Position]
            public let symbol: String
            public let totalBorrow: Amount
            public let totalSupply: Amount
            public let usdPrice: Value

            enum CodingKeys: String, CodingKey {
                case address
                case decimals
                case name
                case positions
                case symbol
                case totalBorrow = "total_borrow"
                case totalSupply = "total_supply"
                case usdPrice = "usd_price"
            }

            public init(
                address: EthAddress,
                decimals: Int,
                name: String,
                positions: [Position],
                symbol: String,
                totalBorrow: Amount,
                totalSupply: Amount,
                usdPrice: Value
            ) {
                self.address = address
                self.decimals = decimals
                self.name = name
                self.positions = positions
                self.symbol = symbol
                self.totalBorrow = totalBorrow
                self.totalSupply = totalSupply
                self.usdPrice = usdPrice
            }

            public init(
                loanAsset: LoanAsset,
                address: EthAddress? = nil,
                decimals: Int? = nil,
                name: String? = nil,
                positions: [Position]? = nil,
                symbol: String? = nil,
                totalBorrow: Amount? = nil,
                totalSupply: Amount? = nil,
                usdPrice: Value? = nil
            ) {
                self.address = address ?? loanAsset.address
                self.decimals = decimals ?? loanAsset.decimals
                self.name = name ?? loanAsset.name
                self.positions = positions ?? loanAsset.positions
                self.symbol = symbol ?? loanAsset.symbol
                self.totalBorrow = totalBorrow ?? loanAsset.totalBorrow
                self.totalSupply = totalSupply ?? loanAsset.totalSupply
                self.usdPrice = usdPrice ?? loanAsset.usdPrice
            }

            /// The total user borrow for this loan asset across quark wallets
            public var userBorrow: Amount {
                positions
                    .map { $0.borrow }
                    .sum(decimals: decimals)
            }

            /// The total user borrow for this base asset across wallets in USD
            public var userBorrowValue: Value {
                positions
                    .map { $0.borrow * usdPrice }
                    .sum()
            }

            /// The liquidation capacity for this market in terms of base token
            public var userLiquidationCapacity: Amount {
                positions
                    .map { $0.baseLiquidationCapacity }
                    .sum(decimals: decimals)
            }
        }

        public struct CollateralAsset: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let balances: [Balance]
            public let basePrice: Value
            public let decimals: Int
            public let name: String
            public let symbol: String
            public let usdPrice: Value

            enum CodingKeys: String, CodingKey {
                case address
                case balances
                case basePrice = "base_price"
                case decimals
                case name
                case symbol
                case usdPrice = "usd_price"
            }

            public init(
                address: EthAddress,
                balances: [Balance],
                basePrice: Value,
                decimals: Int,
                name: String,
                symbol: String,
                usdPrice: Value
            ) {
                self.address = address
                self.balances = balances
                self.basePrice = basePrice
                self.decimals = decimals
                self.name = name
                self.symbol = symbol
                self.usdPrice = usdPrice
            }

            public init(
                collateralAsset: CollateralAsset,
                address: EthAddress? = nil,
                balances: [Balance]? = nil,
                basePrice: Value? = nil,
                decimals: Int? = nil,
                name: String? = nil,
                symbol: String? = nil,
                usdPrice: Value? = nil
            ) {
                self.address = address ?? collateralAsset.address
                self.balances = balances ?? collateralAsset.balances
                self.basePrice = basePrice ?? collateralAsset.basePrice
                self.decimals = decimals ?? collateralAsset.decimals
                self.name = name ?? collateralAsset.name
                self.symbol = symbol ?? collateralAsset.symbol
                self.usdPrice = usdPrice ?? collateralAsset.usdPrice
            }

            /// The full balance of this asset that has been supplied as collateral across all the quark wallets
            public var marketBalance: Amount {
                balances.map { $0.balance }.sum(decimals: decimals)
            }

            public var marketBalanceValue: Value {
                marketBalance * usdPrice
            }
        }

        public struct Position: Codable, Equatable, Sendable {
            public let baseLiquidationCapacity: Amount
            public let borrow: Amount
            public let usdLiquidationCapacity: Value
            public let wallet: EthAddress

            enum CodingKeys: String, CodingKey {
                case baseLiquidationCapacity = "base_liquidation_point"
                case borrow
                case usdLiquidationCapacity = "usd_liquidation_point"
                case wallet
            }

            public init(
                baseLiquidationCapacity: Amount,
                borrow: Amount,
                usdLiquidationCapacity: Value,
                wallet: EthAddress
            ) {
                self.baseLiquidationCapacity = baseLiquidationCapacity
                self.borrow = borrow
                self.usdLiquidationCapacity = usdLiquidationCapacity
                self.wallet = wallet
            }

            public init(
                position: Position,
                baseLiquidationCapacity: Amount? = nil,
                borrow: Amount? = nil,
                usdLiquidationCapacity: Value? = nil,
                wallet: EthAddress? = nil
            ) {
                self.baseLiquidationCapacity =
                    baseLiquidationCapacity ?? position.baseLiquidationCapacity
                self.borrow = borrow ?? position.borrow
                self.usdLiquidationCapacity =
                    usdLiquidationCapacity ?? position.usdLiquidationCapacity
                self.wallet = wallet ?? position.wallet
            }
        }

        public struct BorrowReward: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let name: String
            public let rewardApr: Percentage
            public let symbol: String

            public init(address: EthAddress, name: String, rewardApr: Percentage, symbol: String) {
                self.address = address
                self.name = name
                self.rewardApr = rewardApr
                self.symbol = symbol
            }

            enum CodingKeys: String, CodingKey {
                case address
                case name
                case rewardApr = "reward_apr"
                case symbol
            }
        }
    }

    public struct MorphoVault: Codable, Equatable, Sendable {
        public let address: EthAddress
        public let loanAsset: LoanAsset
        public let fixnumDecimals: Int
        public let name: String
        public let supplyApr: Percentage
        public let symbol: String
        public let supplyRewards: [SupplyReward]
        public let fee: Amount

        enum CodingKeys: String, CodingKey {
            case address
            case loanAsset = "loan_asset"
            case fixnumDecimals = "fixnum_decimals"
            case name
            case supplyApr = "supply_apr"
            case symbol
            case supplyRewards = "supply_rewards_apr"
            case fee
        }

        public init(
            address: EthAddress,
            loanAsset: LoanAsset,
            fixnumDecimals: Int,
            name: String,
            supplyApr: Percentage,
            symbol: String,
            supplyRewards: [SupplyReward],
            fee: Amount
        ) {
            self.address = address
            self.loanAsset = loanAsset
            self.name = name
            self.fixnumDecimals = fixnumDecimals
            self.supplyApr = supplyApr
            self.symbol = symbol
            self.supplyRewards = supplyRewards
            self.fee = fee
        }

        public init(
            morphoVault: MorphoVault,
            address: EthAddress? = nil,
            loanAsset: LoanAsset? = nil,
            name: String? = nil,
            fixnumDecimals: Int? = nil,
            supplyApr: Percentage? = nil,
            symbol: String? = nil,
            supplyRewards: [SupplyReward]? = nil,
            fee: Amount? = nil
        ) {
            self.address = address ?? morphoVault.address
            self.loanAsset = loanAsset ?? morphoVault.loanAsset
            self.name = name ?? morphoVault.name
            self.fixnumDecimals = fixnumDecimals ?? morphoVault.fixnumDecimals
            self.supplyApr = supplyApr ?? morphoVault.supplyApr
            self.symbol = symbol ?? morphoVault.symbol
            self.supplyRewards = supplyRewards ?? morphoVault.supplyRewards
            self.fee = fee ?? morphoVault.fee
        }

        public struct LoanAsset: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let decimals: Int
            public let name: String
            public let positions: [Position]
            public let symbol: String
            public let totalSupply: Amount
            public let usdPrice: Value

            enum CodingKeys: String, CodingKey {
                case address
                case decimals
                case name
                case positions
                case symbol
                case totalSupply = "total_supply"
                case usdPrice = "usd_price"
            }

            public init(
                address: EthAddress,
                decimals: Int,
                name: String,
                positions: [Position],
                symbol: String,
                totalSupply: Amount,
                usdPrice: Value
            ) {
                self.address = address
                self.decimals = decimals
                self.name = name
                self.positions = positions
                self.symbol = symbol
                self.totalSupply = totalSupply
                self.usdPrice = usdPrice
            }

            public init(
                loanAsset: LoanAsset,
                address: EthAddress? = nil,
                decimals: Int? = nil,
                name: String? = nil,
                positions: [Position]? = nil,
                symbol: String? = nil,
                totalSupply: Amount? = nil,
                usdPrice: Value? = nil
            ) {
                self.address = address ?? loanAsset.address
                self.decimals = decimals ?? loanAsset.decimals
                self.name = name ?? loanAsset.name
                self.positions = positions ?? loanAsset.positions
                self.symbol = symbol ?? loanAsset.symbol
                self.totalSupply = totalSupply ?? loanAsset.totalSupply
                self.usdPrice = usdPrice ?? loanAsset.usdPrice
            }
        }

        public struct Position: Codable, Equatable, Sendable {
            public let supply: Amount
            public let wallet: EthAddress

            public init(supply: Amount, wallet: EthAddress) {
                self.supply = supply
                self.wallet = wallet
            }

            public init(
                position: Position,
                supply: Amount? = nil,
                wallet: EthAddress? = nil
            ) {
                self.supply = supply ?? position.supply
                self.wallet = wallet ?? position.wallet
            }
        }

        public struct SupplyReward: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let name: String
            public let rewardApr: Percentage
            public let symbol: String

            public init(address: EthAddress, name: String, rewardApr: Percentage, symbol: String) {
                self.address = address
                self.name = name
                self.rewardApr = rewardApr
                self.symbol = symbol
            }

            enum CodingKeys: String, CodingKey {
                case address
                case name
                case rewardApr = "reward_apr"
                case symbol
            }
        }
    }

    public struct MorphoRewardPosition: Codable, Equatable, Sendable {
        public let chainId: UInt
        public let asset: MorphoRewardAsset
        public let airdropRewards: [AirdropReward]
        public let distributions: [Distribution]
        public let marketRewards: [MarketReward]
        public let uniformRewards: [UniformReward]
        public let vaultRewards: [VaultReward]

        public init(
            chainId: UInt,
            asset: MorphoRewardAsset,
            airdropRewards: [AirdropReward],
            distributions: [Distribution],
            marketRewards: [MarketReward],
            uniformRewards: [UniformReward],
            vaultRewards: [VaultReward]
        ) {
            self.chainId = chainId
            self.asset = asset
            self.airdropRewards = airdropRewards
            self.distributions = distributions
            self.marketRewards = marketRewards
            self.uniformRewards = uniformRewards
            self.vaultRewards = vaultRewards
        }

        enum CodingKeys: String, CodingKey {
            case chainId = "chain_id"
            case asset
            case airdropRewards = "airdrop_rewards"
            case distributions
            case marketRewards = "market_rewards"
            case uniformRewards = "uniform_rewards"
            case vaultRewards = "vault_rewards"
        }

        public struct MorphoRewardAsset: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let name: String
            public let symbol: String
            public let decimals: Int

            public init(address: EthAddress, name: String, symbol: String, decimals: Int) {
                self.address = address
                self.name = name
                self.symbol = symbol
                self.decimals = decimals
            }
        }

        public struct AirdropReward: Codable, Equatable, Sendable {
            public let total: Amount
            public let account: EthAddress
            public let claimableNext: Amount
            public let claimableNow: Amount
            public let claimed: Amount

            public init(
                total: Amount,
                account: EthAddress,
                claimableNext: Amount,
                claimableNow: Amount,
                claimed: Amount
            ) {
                self.total = total
                self.account = account
                self.claimableNext = claimableNext
                self.claimableNow = claimableNow
                self.claimed = claimed
            }

            enum CodingKeys: String, CodingKey {
                case total
                case account
                case claimed
                case claimableNext = "claimable_next"
                case claimableNow = "claimable_now"
            }
        }

        public struct Distribution: Codable, Equatable, Sendable {
            public let account: EthAddress
            public let distributor: EthAddress
            public let claimable: Amount
            public let proof: [Hex]

            public init(
                account: EthAddress,
                distributor: EthAddress,
                claimable: Amount,
                proof: [Hex]
            ) {
                self.account = account
                self.distributor = distributor
                self.claimable = claimable
                self.proof = proof
            }
        }

        public struct MarketReward: Codable, Equatable, Sendable {
            public let total: Amount
            public let account: EthAddress
            public let marketId: Hex
            public let claimableNext: Amount
            public let claimableNow: Amount
            public let claimed: Amount
            public let reallocatedFrom: EthAddress?

            public init(
                total: Amount,
                account: EthAddress,
                marketId: Hex,
                claimableNext: Amount,
                claimableNow: Amount,
                claimed: Amount,
                reallocatedFrom: EthAddress?
            ) {
                self.total = total
                self.account = account
                self.marketId = marketId
                self.claimableNext = claimableNext
                self.claimableNow = claimableNow
                self.claimed = claimed
                self.reallocatedFrom = reallocatedFrom
            }

            enum CodingKeys: String, CodingKey {
                case total
                case account
                case marketId = "market_id"
                case claimableNext = "claimable_next"
                case claimableNow = "claimable_now"
                case claimed
                case reallocatedFrom = "reallocated_from"
            }
        }

        public struct UniformReward: Codable, Equatable, Sendable {
            public let total: Amount
            public let account: EthAddress
            public let claimableNext: Amount
            public let claimableNow: Amount
            public let claimed: Amount

            public init(
                total: Amount,
                account: EthAddress,
                claimableNext: Amount,
                claimableNow: Amount,
                claimed: Amount
            ) {
                self.total = total
                self.account = account
                self.claimableNext = claimableNext
                self.claimableNow = claimableNow
                self.claimed = claimed
            }

            enum CodingKeys: String, CodingKey {
                case account
                case claimableNow = "claimable_now"
                case claimed
                case claimableNext = "claimable_next"
                case total
            }
        }

        public struct VaultReward: Codable, Equatable, Sendable {
            public let total: Amount
            public let account: EthAddress
            public let vault: EthAddress
            public let claimableNext: Amount
            public let claimableNow: Amount
            public let claimed: Amount

            public init(
                total: Amount,
                account: EthAddress,
                vault: EthAddress,
                claimableNext: Amount,
                claimableNow: Amount,
                claimed: Amount
            ) {
                self.total = total
                self.account = account
                self.vault = vault
                self.claimableNext = claimableNext
                self.claimableNow = claimableNow
                self.claimed = claimed
            }

            enum CodingKeys: String, CodingKey {
                case total
                case account
                case vault
                case claimableNext = "claimable_next"
                case claimableNow = "claimable_now"
                case claimed
            }
        }
    }

    public struct QueryVersion: Codable, Equatable, Sendable {
        public let revision: Int
        public let schema: String

        public init(revision: Int, schema: String) {
            self.revision = revision
            self.schema = schema
        }
    }

    public struct Token: Codable, Equatable, Sendable {
        public let address: EthAddress
        public let balances: [Balance]
        public let decimals: Int
        public let name: String
        public let symbol: String
        public let usdPrice: Value

        enum CodingKeys: String, CodingKey {
            case address
            case balances
            case decimals
            case name
            case symbol
            case usdPrice = "usd_price"
        }

        public init(
            address: EthAddress,
            balances: [Balance],
            decimals: Int,
            name: String,
            symbol: String,
            usdPrice: Value
        ) {
            self.address = address
            self.balances = balances
            self.decimals = decimals
            self.name = name
            self.usdPrice = usdPrice
            self.symbol = Portfolio.validSymbol(symbol)
        }

        public init(
            token: Token,
            address: EthAddress? = nil,
            balances: [Balance]? = nil,
            decimals: Int? = nil,
            name: String? = nil,
            symbol: String? = nil,
            usdPrice: Value? = nil
        ) {
            self.address = address ?? token.address
            self.balances = balances ?? token.balances
            self.decimals = decimals ?? token.decimals
            self.name = name ?? token.name
            self.symbol = Portfolio.validSymbol(symbol ?? token.symbol)
            self.usdPrice = usdPrice ?? token.usdPrice
        }

        /// The full balance of this asset across all the quark wallets
        public var fullBalance: Amount {
            balances.map { $0.balance }.sum(decimals: decimals)
        }

        /// The full balance value in USD of this asset across all the quark wallets
        public var fullBalanceValue: Value {
            balances
                .map { $0.balance * usdPrice }
                .sum()
        }
    }

    public struct QuarkNonceStatus: Codable, Equatable, Sendable {
        public let quarkWallet: EthAddress
        public let nonce: Hex
        public let submitted: Bool

        public init(quarkWallet: EthAddress, nonce: Hex, submitted: Bool) {
            self.quarkWallet = quarkWallet
            self.nonce = nonce
            self.submitted = submitted
        }

        enum CodingKeys: String, CodingKey {
            case quarkWallet = "quark_wallet"
            case nonce
            case submitted
        }
    }

    public struct AcrossFillStatus: Codable, Equatable, Sendable {
        public let quarkWallet: EthAddress
        public let relayHash: Hex
        public let filled: Bool

        public init(quarkWallet: EthAddress, relayHash: Hex, filled: Bool) {
            self.quarkWallet = quarkWallet
            self.relayHash = relayHash
            self.filled = filled
        }

        enum CodingKeys: String, CodingKey {
            case quarkWallet = "quark_wallet"
            case relayHash = "relay_hash"
            case filled
        }
    }

    public struct CctpV2FillStatus: Codable, Equatable, Sendable {
        public let quarkWallet: EthAddress
        public let burnTransactionHash: Hex
        public let filled: Bool

        public init(quarkWallet: EthAddress, burnTransactionHash: Hex, filled: Bool) {
            self.quarkWallet = quarkWallet
            self.burnTransactionHash = burnTransactionHash
            self.filled = filled
        }

        enum CodingKeys: String, CodingKey {
            case quarkWallet = "quark_wallet"
            case burnTransactionHash = "burn_transaction_hash"
            case filled
        }
    }

    public struct TokenWrapperQuote: Codable, Equatable, Sendable {
        public let underlying: Token
        public let wrapped: Token
        public let underlyingHasToken: Bool
        public let unwrapQuote: Percentage

        public init(
            underlying: Token,
            wrapped: Token,
            underlyingHasToken: Bool,
            unwrapQuote: Percentage
        ) {
            self.underlying = underlying
            self.wrapped = wrapped
            self.underlyingHasToken = underlyingHasToken
            self.unwrapQuote = unwrapQuote
        }

        enum CodingKeys: String, CodingKey {
            case underlying
            case wrapped
            case underlyingHasToken = "underlying_has_token"
            case unwrapQuote = "unwrap_quote"
        }

        public struct Token: Codable, Equatable, Sendable {
            public let address: EthAddress
            public let decimals: Int?
            public let name: String?
            public let symbol: String

            public init(address: EthAddress, decimals: Int, name: String, symbol: String) {
                self.address = address
                self.decimals = decimals
                self.name = name
                self.symbol = symbol
            }
        }
    }

    func getChainAccounts(withNonceSecrets nonceSecrets: [NonceSecret])
        -> QuarkBuilder.Accounts.ChainAccounts
    {
        let quarkSecrets: [QuarkBuilder.Accounts.QuarkSecret] = wallets.map { wallet in
            .init(
                account: wallet.wallet,
                nonceSecret: nonceSecrets.first(
                    where: { $0.account == wallet.wallet && $0.chainId == chainId }
                )?
                .nonceSecret ?? EthWord(fromData: generateSecureRandomData(bytes: 32))!.hex
            )
        }

        let assetPositionsList: [QuarkBuilder.Accounts.AssetPositions] =
            tokens.map { token in
                .init(
                    asset: token.address,
                    symbol: token.symbol,
                    decimals: Number(token.decimals),
                    usdPrice: token.usdPrice.underlying,
                    accountBalances: token.balances.map { balance in
                        .init(account: balance.wallet, balance: balance.balance.underlying)
                    }
                )
            }

        let cometPositions: [QuarkBuilder.Accounts.CometPositions] =
            comets.map { comet in
                let cometRewards: [QuarkBuilder.Accounts.CometReward] =
                    comet.reward.map { reward in
                        [
                            .init(
                                asset: reward.address,
                                rewardContract: reward.rewardsAddress,
                                accounts: reward.positions.map { $0.wallet },
                                rewardsOwed: reward.positions.map { $0.rewardOwed.underlying }
                            )
                        ]
                    } ?? []

                return QuarkBuilder.Accounts.CometPositions(
                    comet: comet.address,
                    basePosition: .init(
                        asset: comet.base.address,
                        accounts: comet.base.positions.map { $0.wallet },
                        borrowed: comet.base.positions.map { $0.borrow.underlying },
                        supplied: comet.base.positions.map { $0.supply.underlying }
                    ),
                    collateralPositions: comet.collaterals.map { collateral in
                        .init(
                            asset: collateral.address,
                            accounts: collateral.cometBalances.map { $0.wallet },
                            balances: collateral.cometBalances.map { $0.balance.underlying }
                        )
                    },
                    cometRewards: cometRewards
                )
            }

        let morphoPositions: [QuarkBuilder.Accounts.MorphoPositions] =
            morphos.map { morphoMarket in
                .init(
                    marketId: morphoMarket.marketId,
                    morpho: morphoMarket.morpho,
                    loanToken: morphoMarket.loanAsset.address,
                    collateralToken: morphoMarket.collateralAsset.address,
                    borrowPosition: QuarkBuilder.Accounts.MorphoBorrowPosition(
                        accounts: morphoMarket.loanAsset.positions.map { $0.wallet },
                        borrowed: morphoMarket.loanAsset.positions.map { $0.borrow.underlying }
                    ),
                    collateralPosition: QuarkBuilder.Accounts.MorphoCollateralPosition(
                        accounts: morphoMarket.collateralAsset.balances.map { $0.wallet },
                        balances: morphoMarket.collateralAsset.balances.map {
                            $0.balance.underlying
                        }
                    )
                )
            }

        let morphoVaultPositions: [QuarkBuilder.Accounts.MorphoVaultPositions] =
            morphoVaults.map { morphoVault in
                .init(
                    asset: morphoVault.loanAsset.address,
                    accounts: morphoVault.loanAsset.positions.map { $0.wallet },
                    balances: morphoVault.loanAsset.positions.map { $0.supply.underlying },
                    vault: morphoVault.address
                )
            }

        let morphoRewardDistributions: [QuarkBuilder.Accounts.MorphoRewardDistribution] =
            morphoRewardPositions.flatMap { rewardPosition in
                let airdropClaimableNow = rewardPosition.airdropRewards.map(\.claimableNow)
                    .sum(
                        decimals: rewardPosition.asset.decimals
                    )
                let marketClaimableNow = rewardPosition.marketRewards.map(\.claimableNow)
                    .sum(
                        decimals: rewardPosition.asset.decimals
                    )
                let vaultClaimableNow = rewardPosition.vaultRewards.map(\.claimableNow)
                    .sum(
                        decimals: rewardPosition.asset.decimals
                    )
                let uniformClaimableNow = rewardPosition.uniformRewards.map(\.claimableNow)
                    .sum(
                        decimals: rewardPosition.asset.decimals
                    )
                let claimableNow =
                    airdropClaimableNow + marketClaimableNow + vaultClaimableNow
                    + uniformClaimableNow

                return rewardPosition.distributions.map { distribution in
                    QuarkBuilder.Accounts.MorphoRewardDistribution(
                        account: distribution.account,
                        asset: rewardPosition.asset.address,
                        claimable: distribution.claimable.underlying,
                        claimableNow: claimableNow.underlying,
                        distributor: distribution.distributor,
                        proof: distribution.proof
                    )
                }
            }

        let aavePositions: [QuarkBuilder.Accounts.AavePositions] =
            aaves.map { aaveMarket in
                QuarkBuilder.Accounts.AavePositions(
                    pool: aaveMarket.pool,
                    aaveAssetPositions: aaveMarket.assets.map { assetPosition in
                        let (wallets, borrowed, supplied) = assetPosition.positions.reduce(
                            into: ([EthAddress](), [Number](), [Number]())
                        ) { result, p in
                            result.0.append(p.wallet)
                            result.1.append(p.borrowed.underlying)
                            result.2.append(p.supplied.underlying)
                        }

                        return .init(
                            asset: assetPosition.address,
                            accounts: wallets,
                            borrowed: borrowed,
                            supplied: supplied
                        )
                    }
                )
            }

        return .init(
            chainId: Number(chainId),
            quarkSecrets: quarkSecrets,
            assetPositionsList: assetPositionsList,
            cometPositions: cometPositions,
            morphoPositions: morphoPositions,
            morphoVaultPositions: morphoVaultPositions,
            morphoRewardDistributions: morphoRewardDistributions,
            aavePositions: aavePositions
        )
    }

    private static func getAssets(
        chain: Network,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [Asset] {
        tokens.compactMap { token in
            tokenToAsset(
                chain: chain,
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            )
        }
    }

    private static func getEthBalance(tokens: [Portfolio.Token]) -> Amount {
        guard let ethToken = tokens.first(where: { $0.symbol == "ETH" }) else {
            return Amount(0, decimals: 18)
        }
        return ethToken.fullBalance
    }

    private static func getAaveMarkets(
        chain: Network,
        aaves: [Portfolio.Aave],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [AaveMarket] {
        let supportedBaseAssets: Set<String> = ["USDC", "WETH", "ETH", "USDT"]
        return aaves.flatMap { market in
            market.assets.compactMap { asset -> AaveMarket? in
                guard supportedBaseAssets.contains(asset.symbol) else {
                    return nil
                }

                guard let token = tokens.first(where: { $0.address == asset.address }) else {
                    Logger.error("Could not find the associated token for base \(asset.symbol)")
                    return nil
                }

                let baseAsset = BaseAsset(
                    address: token.address,
                    chain: chain,
                    dApp: .Aave,
                    name: token.symbol,
                    symbol: token.symbol,
                    decimals: token.decimals,
                    price: token.usdPrice,
                    balances: getAssetBalances(
                        token: token,
                        tokens: tokens,
                        tokenWrapperQuotes: tokenWrapperQuotes
                    ),
                    marketBalances: asset.positions.map {
                        .init(
                            wallet: $0.wallet,
                            balance: $0.supplied
                        )
                    },
                    earnApr: asset.supplyApr,
                    earnRewardsApr: .zero
                )

                let rewardAssets: [RewardAsset] = []

                return AaveMarket(
                    chain: chain,
                    address: market.pool,
                    name: market.name,
                    baseAsset: baseAsset,
                    rewardAssets: rewardAssets,
                    earnApr: asset.supplyApr,
                    earnRewardsApr: baseAsset.earnRewardsApr,
                    totalSupply: asset.totalSupply
                )
            }
        }
    }

    private static func getCometMarkets(
        chain: Network,
        comets: [Portfolio.Comet],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [CometMarket] {
        comets.compactMap { comet -> CometMarket? in
            guard
                let baseAsset = cometToBaseAsset(
                    chain: chain,
                    comet: comet,
                    tokens: tokens,
                    tokenWrapperQuotes: tokenWrapperQuotes
                )
            else {
                return nil
            }

            let collateralAssets = comet.collaterals.compactMap { collateral in
                cometCollateralToCollateralAsset(
                    chain: chain,
                    collateral: collateral,
                    tokens: tokens,
                    tokenWrapperQuotes: tokenWrapperQuotes
                )
            }

            var rewardAssets: [RewardAsset]
            if comet.reward != nil {
                guard
                    let rewardAsset = cometToRewardAsset(
                        chain: chain,
                        comet: comet,
                        tokens: tokens,
                        tokenWrapperQuotes: tokenWrapperQuotes
                    )
                else {
                    return nil
                }

                rewardAssets = [rewardAsset]
            } else {
                rewardAssets = []
            }

            return CometMarket(
                chain: chain,
                address: comet.address,
                name: comet.name,
                totalSupply: comet.base.totalSupply,
                totalBorrow: comet.base.totalBorrow,
                userBorrow: comet.base.userBorrow,
                borrowCapacity: comet.base.userBorrowCapacity,
                liquidationCapacity: comet.base.userLiquidationCapacity,
                earnApr: comet.supplyApr,
                earnRewardsApr: comet.supplyRewardsApr,
                borrowApr: comet.borrowApr,
                borrowRewardsApr: comet.borrowRewardsApr,
                baseAsset: baseAsset,
                collateralAssets: collateralAssets,
                rewardAssets: rewardAssets
            )
        }
    }

    private static func getMorphoMarkets(
        chain: Network,
        morphos: [Portfolio.Morpho],
        morphoRewardPositions: [Portfolio.MorphoRewardPosition],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [MorphoMarket] {
        morphos.compactMap { morpho -> MorphoMarket? in
            guard
                let baseAsset = morphoMarketLoanAssetToBaseAsset(
                    chain: chain,
                    loanAsset: morpho.loanAsset,
                    tokens: tokens,
                    tokenWrapperQuotes: tokenWrapperQuotes
                )
            else {
                return nil
            }

            guard
                let collateralAsset = morphoMarketToCollateralAsset(
                    chain: chain,
                    morpho: morpho,
                    tokens: tokens,
                    tokenWrapperQuotes: tokenWrapperQuotes
                )
            else {
                return nil
            }

            return MorphoMarket(
                chain: chain,
                address: morpho.morpho,
                marketId: morpho.marketId,
                name: "",
                totalSupply: morpho.loanAsset.totalSupply,
                totalBorrow: morpho.loanAsset.totalBorrow,
                userBorrow: morpho.loanAsset.userBorrow,
                borrowCapacity: morpho.loanAsset.userLiquidationCapacity,
                liquidationCapacity: morpho.loanAsset.userLiquidationCapacity,
                borrowApr: morpho.borrowApr,
                borrowRewardsApr: .zero,
                baseAsset: baseAsset,
                collateralAsset: collateralAsset,
                rewardAssets: morpho.borrowRewards.compactMap { reward in
                    morphoRewardToRewardAsset(
                        chain: chain,
                        marketId: morpho.marketId,
                        reward: reward,
                        morphoRewardPositions: morphoRewardPositions,
                        tokens: tokens,
                        tokenWrapperQuotes: tokenWrapperQuotes
                    )
                }
            )
        }
    }

    private static func getMorphoVaultMarkets(
        chain: Network,
        morphoVaults: [Portfolio.MorphoVault],
        morphoRewardPositions: [Portfolio.MorphoRewardPosition],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [MorphoVaultMarket] {
        morphoVaults.compactMap { morphoVault -> MorphoVaultMarket? in
            guard
                let baseAsset = morphoVaultToBaseAsset(
                    chain: chain,
                    morphoVault: morphoVault,
                    tokens: tokens,
                    tokenWrapperQuotes: tokenWrapperQuotes
                )
            else {
                return nil
            }

            return MorphoVaultMarket(
                chain: chain,
                address: morphoVault.address,
                name: morphoVault.name,
                baseAsset: baseAsset,
                rewardAssets: morphoVault.supplyRewards.compactMap { reward in
                    morphoVaultRewardToRewardAsset(
                        chain: chain,
                        vault: morphoVault.address,
                        reward: reward,
                        morphoRewardPositions: morphoRewardPositions,
                        tokens: tokens,
                        tokenWrapperQuotes: tokenWrapperQuotes
                    )
                },
                earnApr: morphoVault.supplyApr,
                earnRewardsApr: .zero,
                totalSupply: morphoVault.loanAsset.totalSupply
            )
        }
    }

    private static func getUniformRewards(
        chain: Network,
        morphoRewardPositions: [Portfolio.MorphoRewardPosition],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [RewardAsset] {
        morphoRewardPositions.compactMap { morphoRewardPosition -> RewardAsset? in
            guard
                let token = tokens.first(where: { $0.symbol == morphoRewardPosition.asset.symbol })
            else {
                Logger.error(
                    "Could not find the associated token for morpho uniform reward \(morphoRewardPosition.asset.symbol)"
                )
                return nil
            }

            let rewardOwed = morphoRewardPosition.uniformRewards
                .map { $0.total - $0.claimed }
                .sum(decimals: morphoRewardPosition.asset.decimals)

            let claimableRewardOwed = morphoRewardPosition.uniformRewards
                .map(\.claimableNow)
                .sum(decimals: morphoRewardPosition.asset.decimals)

            return RewardAsset(
                address: token.address,
                chain: chain,
                dApp: .Morpho,
                name: token.name,
                symbol: token.symbol,
                decimals: token.decimals,
                price: token.usdPrice,
                balances: getAssetBalances(
                    token: token,
                    tokens: tokens,
                    tokenWrapperQuotes: tokenWrapperQuotes
                ),
                rewardAddress: token.address,
                rewardOwed: rewardOwed,
                claimableRewardOwed: claimableRewardOwed,
                borrowRewardsApr: .zero,
                supplyRewardsApr: .zero
            )
        }
    }

    private static func getAirdropRewards(
        chain: Network,
        morphoRewardPositions: [Portfolio.MorphoRewardPosition],
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [RewardAsset] {
        morphoRewardPositions.compactMap { morphoRewardPosition -> RewardAsset? in
            guard
                let token = tokens.first(where: { $0.symbol == morphoRewardPosition.asset.symbol })
            else {
                Logger.error(
                    "Could not find the associated token for morpho airdrop reward \(morphoRewardPosition.asset.symbol)"
                )
                return nil
            }

            let rewardOwed = morphoRewardPosition.airdropRewards
                .map { $0.total - $0.claimed }
                .sum(decimals: morphoRewardPosition.asset.decimals)

            let claimableRewardOwed = morphoRewardPosition.airdropRewards
                .map(\.claimableNow)
                .sum(decimals: morphoRewardPosition.asset.decimals)

            return RewardAsset(
                address: token.address,
                chain: chain,
                dApp: .Morpho,
                name: token.name,
                symbol: token.symbol,
                decimals: token.decimals,
                price: token.usdPrice,
                balances: getAssetBalances(
                    token: token,
                    tokens: tokens,
                    tokenWrapperQuotes: tokenWrapperQuotes
                ),
                rewardAddress: token.address,
                rewardOwed: rewardOwed,
                claimableRewardOwed: claimableRewardOwed,
                borrowRewardsApr: .zero,
                supplyRewardsApr: .zero
            )
        }
    }

    // MARK: Helpers

    private static func tokenToAsset(
        chain: Network,
        token: Portfolio.Token,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> Asset? {
        // Underlying assets are not treated as Legend assets directly. They are rolled into the
        if isUnderlyingAsset(token: token, tokenWrapperQuotes: tokenWrapperQuotes) {
            return nil
        }

        return Asset(
            address: token.address,
            chain: chain,
            name: token.name,
            symbol: Portfolio.validSymbol(token.symbol),
            decimals: token.decimals,
            price: token.usdPrice,
            balances: getAssetBalances(
                token: token,
                tokens: tokens,
                tokenWrapperQuotes: tokenWrapperQuotes
            ),
            underlyingAsset: getUnderlyingAsset(
                token: token,
                tokenWrapperQuotes: tokenWrapperQuotes
            )
        )
    }

    /// Handle wrapped asset balances
    private static func getAssetBalances(
        token: Portfolio.Token,
        tokens: [Portfolio.Token],
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> [Asset.Balance] {
        func getBalances(token: Portfolio.Token, underlyingToken: Portfolio.Token) -> [Asset
            .Balance]
        {
            token.balances.map { balance in
                let underlyingBalance =
                    underlyingToken.balances.first { $0.wallet == balance.wallet }?.balance
                    ?? Amount(0, decimals: token.decimals)

                return .init(
                    wallet: balance.wallet,
                    balance: balance.balance,
                    underlyingAssetBalance: underlyingBalance
                )
            }
        }

        // TODO: This will be updated to utilize Atlas
        if let tokenWrapperQuote = getTokenWrapperQuote(
            token: token,
            tokenWrapperQuotes: tokenWrapperQuotes
        ) {
            if let underlyingToken = tokens.first(where: {
                $0.symbol == tokenWrapperQuote.underlying.symbol
            }) {
                return token.balances.map { balance in
                    let underlyingBalance =
                        underlyingToken.balances.first { $0.wallet == balance.wallet }?.balance
                        ?? Amount(0, decimals: token.decimals)

                    return .init(
                        wallet: balance.wallet,
                        balance: balance.balance,
                        underlyingAssetBalance: underlyingBalance
                    )
                }
            }
        } else if token.symbol == "WETH" {
            if let underlyingToken = tokens.first(where: { $0.symbol == "ETH" }) {
                return getBalances(token: token, underlyingToken: underlyingToken)
            }
        } else if token.symbol == "WPOL" {
            if let underlyingToken = tokens.first(where: { $0.symbol == "POL" }) {
                return getBalances(token: token, underlyingToken: underlyingToken)
            }
        } else if token.symbol == "WHYPE" {
            if let underlyingToken = tokens.first(where: { $0.symbol == "HYPE" }) {
                return getBalances(token: token, underlyingToken: underlyingToken)
            }
        }

        return token.balances.map {
            .init(wallet: $0.wallet, balance: $0.balance)
        }
    }

    private static func getTokenWrapperQuote(
        token: Portfolio.Token,
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> Portfolio.TokenWrapperQuote? {
        tokenWrapperQuotes.first {
            $0.wrapped.symbol == token.symbol
        }
    }

    private static func getUnderlyingAsset(
        token: Portfolio.Token,
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> Asset.UnderlyingAsset? {
        getTokenWrapperQuote(token: token, tokenWrapperQuotes: tokenWrapperQuotes)
            .map {
                .init(
                    address: $0.underlying.address,
                    name: $0.underlying.name ?? token.name,
                    symbol: $0.underlying.symbol,
                    decimals: $0.underlying.decimals ?? token.decimals,
                    unwrapQuote: $0.unwrapQuote
                )
            }
    }

    private static func isUnderlyingAsset(
        token: Portfolio.Token,
        tokenWrapperQuotes: [Portfolio.TokenWrapperQuote]
    ) -> Bool {
        tokenWrapperQuotes.contains { $0.underlying.symbol == token.symbol }
    }
}

extension Portfolio {
    // MARK: Meta Assets

    /// Gets the MetaAssets for the user, augmenting them with LoopPositions
    public nonisolated static func getMetaAssets(
        portfolios: [Portfolio],
        loopPositions: [LoopPosition]
    ) -> [MetaAsset] {
        portfolios.reduce(into: [String: MetaAsset]()) { assetsDict, portfolio in

            // Add Assets
            for asset in portfolio.assets {
                // The app doesn't care about USD, ignore
                if asset.symbol == "USD" {
                    continue
                }

                // Ignore native tokens. These balances will get bundled into their ERC20 wrapper
                if asset.symbol == "ETH" || asset.symbol == "POL" {
                    continue
                }

                var currentMetaAsset: MetaAsset = assetsDict[
                    asset.symbol,
                    default: .init(
                        name: asset.name,
                        symbol: asset.symbol,
                        decimals: asset.decimals
                    )
                ]

                currentMetaAsset.assets += [asset]
                assetsDict[asset.symbol] = currentMetaAsset

                if asset.symbol == "wrsETH" {
                    print("Added wrsETH from assets")
                }
            }

            // Add BaseAssets
            for market in portfolio.earnMarkets {
                let baseAsset = market.baseAsset
                var currentMetaAsset: MetaAsset = assetsDict[
                    baseAsset.symbol,
                    default: .init(
                        name: baseAsset.name,
                        symbol: baseAsset.symbol,
                        decimals: baseAsset.decimals,
                    )
                ]

                currentMetaAsset.baseAssets += [baseAsset]
                assetsDict[baseAsset.symbol] = currentMetaAsset

                if baseAsset.symbol == "wrsETH" {
                    print("Added wrsETH from baseAssets")
                }
            }

            // Add CollateralAssets
            for market in portfolio.borrowMarkets {
                let existingLoop =
                    loopPositions
                    .first {
                        MarketIdentifier.morphoMarket(market.chain, $0.morphoMarket.marketId)
                            == market.id
                    }

                let collateralAssets = market.collateralAssets
                for collateralAsset in collateralAssets {
                    var currentMetaAsset: MetaAsset = assetsDict[
                        collateralAsset.symbol,
                        default: .init(
                            name: collateralAsset.name,
                            symbol: collateralAsset.symbol,
                            decimals: collateralAsset.decimals
                        )
                    ]

                    // For loop longs, set the collateral asset balance to zero
                    var modifiedCollateralAsset = collateralAsset
                    if let existingLoop,
                        case .long = existingLoop.side
                    {
                        modifiedCollateralAsset = CollateralAsset(
                            address: collateralAsset.address,
                            chain: collateralAsset.chain,
                            dApp: collateralAsset.dApp,
                            name: collateralAsset.name,
                            symbol: collateralAsset.symbol,
                            decimals: collateralAsset.decimals,
                            price: collateralAsset.price,
                            balances: collateralAsset.balances,
                            marketBalances: collateralAsset.marketBalances.map {
                                .init(
                                    wallet: $0.wallet,
                                    balance: Amount(0, decimals: collateralAsset.decimals)
                                )
                            },
                            borrowCollateralFactor: collateralAsset.borrowCollateralFactor,
                            liquidateCollateralFactor: collateralAsset.liquidateCollateralFactor,
                            supplyCap: collateralAsset.supplyCap
                        )
                    }

                    currentMetaAsset.collateralAssets += [modifiedCollateralAsset]
                    assetsDict[collateralAsset.symbol] = currentMetaAsset
                }
            }

            // Add RewardAssets
            for cometMarket in portfolio.cometMarkets {
                for rewardAsset in cometMarket.rewardAssets {
                    var currentMetaAsset: MetaAsset = assetsDict[
                        rewardAsset.symbol,
                        default: .init(
                            name: rewardAsset.name,
                            symbol: rewardAsset.symbol,
                            decimals: rewardAsset.decimals
                        )
                    ]

                    currentMetaAsset.rewardAssets += [rewardAsset]
                    assetsDict[rewardAsset.symbol] = currentMetaAsset
                }
            }

            for morphoMarket in portfolio.morphoMarkets {
                for rewardAsset in morphoMarket.rewardAssets {
                    var currentMetaAsset: MetaAsset = assetsDict[
                        rewardAsset.symbol,
                        default: .init(
                            name: rewardAsset.name,
                            symbol: rewardAsset.symbol,
                            decimals: rewardAsset.decimals
                        )
                    ]

                    currentMetaAsset.rewardAssets += [rewardAsset]
                    assetsDict[rewardAsset.symbol] = currentMetaAsset
                }
            }

            for morphoVaultMarket in portfolio.morphoVaultMarkets {
                for rewardAsset in morphoVaultMarket.rewardAssets {
                    var currentMetaAsset: MetaAsset = assetsDict[
                        rewardAsset.symbol,
                        default: .init(
                            name: rewardAsset.name,
                            symbol: rewardAsset.symbol,
                            decimals: rewardAsset.decimals
                        )
                    ]

                    currentMetaAsset.rewardAssets += [rewardAsset]
                    assetsDict[rewardAsset.symbol] = currentMetaAsset
                }
            }

            // Morpho rewards outside of market and vault
            // Uniform Rewards
            for uniformReward in portfolio.uniformRewards {
                var currentMetaAsset: MetaAsset = assetsDict[
                    uniformReward.symbol,
                    default: .init(
                        name: uniformReward.name,
                        symbol: uniformReward.symbol,
                        decimals: uniformReward.decimals
                    )
                ]

                currentMetaAsset.rewardAssets += [uniformReward]
                assetsDict[uniformReward.symbol] = currentMetaAsset
            }

            // Airdrop Rewards
            for airdropReward in portfolio.airdropRewards {
                var currentMetaAsset: MetaAsset = assetsDict[
                    airdropReward.symbol,
                    default: .init(
                        name: airdropReward.name,
                        symbol: airdropReward.symbol,
                        decimals: airdropReward.decimals
                    )
                ]

                currentMetaAsset.rewardAssets += [airdropReward]
                assetsDict[airdropReward.symbol] = currentMetaAsset
            }
        }
        .map { $0.value }
    }
}

extension Array where Element == Portfolio {
    public func getChainAccountsList(
        withNonceSecrets nonceSecrets: [NonceSecret]
    ) -> [QuarkBuilder.Accounts.ChainAccounts] {
        map { $0.getChainAccounts(withNonceSecrets: nonceSecrets) }
    }
}
