import Eth
import Foundation
import Prelude
import SwiftNumber
import Testing

@testable import Portfolio

let portfolioFixture =
    Portfolio(
        wallets: [
            Portfolio.Wallet(
                hasCode: true,
                isQuark: true,
                quarkVersion: "1",
                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
            ),
            Portfolio.Wallet(
                hasCode: false,
                isQuark: false,
                quarkVersion: "",
                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
            ),
        ],
        block: Portfolio.Block(
            number: 5_783_614,
            timestamp: 1_714_159_572
        ),
        chainId: 11_155_111,
        aaves: [
            Portfolio.Aave(
                assets: [
                    // USDC Asset
                    Portfolio.Aave.Asset(
                        address: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                        decimals: 6,
                        basePriceDecimals: 8,
                        isActive: true,
                        isFrozen: false,
                        isPaused: false,
                        positions: [
                            Portfolio.Aave.Asset.Position(
                                borrowed: Amount("0//6"),
                                supplied: Amount("500000000//6"),
                                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                usageAsCollateralEnabledOnUser: true
                            ),
                            Portfolio.Aave.Asset.Position(
                                borrowed: Amount("0//6"),
                                supplied: Amount("0//6"),
                                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                                usageAsCollateralEnabledOnUser: false
                            ),
                        ],
                        supplyApr: Percentage(double: 0.25),
                        borrowApr: Percentage(double: 0.25),
                        supplyCap: Amount("2000000000//6"),
                        borrowCap: Amount("1000000000//6"),
                        basePrice: Amount("99999999//8"),
                        borrowingEnabled: true,
                        usageAsCollateralEnabled: true,
                        symbol: "USDC",
                        collateralLtv: Amount("7500//5"),
                        liquidationLtv: Amount("8000//5"),
                        isBorrowableInIsolation: true,
                        totalSupply: Amount("500000000//6"),
                        totalBorrow: Amount("300000000//6"),
                        usdPrice: Value("99999999"),
                        isSiloedBorrowing: false
                    ),
                    // WETH Asset
                    Portfolio.Aave.Asset(
                        address: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                        decimals: 18,
                        basePriceDecimals: 8,
                        isActive: true,
                        isFrozen: false,
                        isPaused: false,
                        positions: [
                            Portfolio.Aave.Asset.Position(
                                borrowed: Amount("0//18"),
                                supplied: Amount("500000000000000000//18"),
                                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                usageAsCollateralEnabledOnUser: true,
                            ),
                            Portfolio.Aave.Asset.Position(
                                borrowed: Amount("0//18"),
                                supplied: Amount("0//18"),
                                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                                usageAsCollateralEnabledOnUser: false
                            ),
                        ],
                        supplyApr: Percentage(double: 0.15),
                        borrowApr: Percentage(double: 0.25),
                        supplyCap: Amount("2000000000000000000000//18"),
                        borrowCap: Amount("1000000000000000000000//18"),
                        basePrice: Amount("300000000000//8"),
                        borrowingEnabled: true,
                        usageAsCollateralEnabled: true,
                        symbol: "WETH",
                        collateralLtv: Amount("7500//5"),
                        liquidationLtv: Amount("8000//5"),
                        isBorrowableInIsolation: true,
                        totalSupply: Amount("700000000000000000000//18"),
                        totalBorrow: Amount("300000000000000000000//18"),
                        usdPrice: Value("300000000000"),
                        isSiloedBorrowing: false
                    ),
                ],
                borrowPositions: [
                    Portfolio.Aave.BorrowPosition(
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        baseBorrowCapacity: Amount("333//8"),
                        baseLiquidationCapacity: Amount("444//8"),
                        usdBorrowCapacity: Value("111"),
                        usdLiquidationCapacity: Value("222"),
                    ),
                    Portfolio.Aave.BorrowPosition(
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        baseBorrowCapacity: Amount("0//8"),
                        baseLiquidationCapacity: Amount("0//8"),
                        usdBorrowCapacity: Value("0"),
                        usdLiquidationCapacity: Value("0"),
                    ),
                ],
                name: "Aave Base V3 Market",
                pool: EthAddress("0xa238dd80c259a72e81d7e4664a9801593f98d1c5")
            )
        ],
        comets: [
            // Comet 1: Compound WETH
            Portfolio.Comet(
                address: EthAddress("0x2943ac1216979ad8db76d9147f64e61adc126e96"),
                base: Portfolio.Comet.Base(
                    address: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                    baseBorrowMin: Amount("0//18"),
                    decimals: 18,
                    name: "Wrapped Ether",
                    positions: [
                        Portfolio.Comet.Position(
                            baseBorrowCapacity: Amount("0//18"),
                            baseLiquidationCapacity: Amount("0//18"),
                            borrow: Amount("0//18"),
                            supply: Amount("0//18"),
                            usdBorrowCapacity: Value("0"),
                            usdLiquidationCapacity: Value("0"),
                            wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        ),
                        Portfolio.Comet.Position(
                            baseBorrowCapacity: Amount("0//18"),
                            baseLiquidationCapacity: Amount("0//18"),
                            borrow: Amount("0//18"),
                            supply: Amount("0//18"),
                            usdBorrowCapacity: Value("0"),
                            usdLiquidationCapacity: Value("0"),
                            wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ),
                    ],
                    symbol: "WETH",
                    totalBalance: Amount("3405643280745890843//18"),
                    totalBorrow: Amount("969017000499//18"),
                    totalSupply: Amount("3405644257260925148//18"),
                    usdPrice: Value("315288151686")
                ),
                borrowApr: Percentage("9945224338320000"),
                borrowRewardsApr: Percentage("0"),
                collaterals: [
                    Portfolio.Comet.Collateral(
                        address: EthAddress("0xb9fa8f5ec3da13b508f462243ad0555b46e028df"),
                        decimals: 18,
                        cometBalances: [
                            Portfolio.Balance(
                                balance: Amount("0//18"),
                                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                            ),
                            Portfolio.Balance(
                                balance: Amount("0//18"),
                                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                            ),
                        ],
                        borrowCollateralFactor: Percentage("900000000000000000"),
                        liquidateCollateralFactor: Percentage("930000000000000000"),
                        liquidationFactor: Percentage("950000000000000000"),
                        name: "Coinbase Wrapped Staked ETH",
                        supplyCap: Amount("9000000000000000000000//18"),
                        symbol: "cbETH",
                        totalSupply: Amount("2000134115105271783//18"),
                        usdPrice: Value("305829507135"),
                        basePrice: Amount("97000000//8"),

                    ),
                    Portfolio.Comet.Collateral(
                        address: EthAddress("0xb82381a3fbd3fafa77b3a7be693342618240067b"),
                        decimals: 18,
                        cometBalances: [
                            Portfolio.Balance(
                                balance: Amount("0//18"),
                                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                            ),
                            Portfolio.Balance(
                                balance: Amount("0//18"),
                                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                            ),
                        ],
                        borrowCollateralFactor: Percentage("900000000000000000"),
                        liquidateCollateralFactor: Percentage("930000000000000000"),
                        liquidationFactor: Percentage("950000000000000000"),
                        name: "Wrapped liquid staked Ether 2.0",
                        supplyCap: Amount("80000000000000000000000//18"),
                        symbol: "wstETH",
                        totalSupply: Amount("0//18"),
                        usdPrice: Value("311764491302"),
                        basePrice: Amount("98882400//8"),
                    ),
                ],
                name: "Compound WETH",
                reward: Portfolio.Comet.Reward(
                    address: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                    decimals: 18,
                    name: "Compound",
                    positions: [
                        Portfolio.Comet.Reward.Position(
                            rewardOwed: Amount("0//18"),
                            wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        ),
                        Portfolio.Comet.Reward.Position(
                            rewardOwed: Amount("0//18"),
                            wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ),
                    ],
                    rewardsAddress: EthAddress("0x8bf5b658bdf0388e8b482ed51b14aef58f90abfd"),
                    symbol: "COMP",
                    usdPrice: Value("5000000000"),

                ),
                supplyApr: Percentage("4793472000"),
                supplyRewardsApr: Percentage("1699636062375893083"),
                symbol: "cWETHv3",
            ),
            // Comet 2: Compound USDC
            Portfolio.Comet(
                address: EthAddress("0xaec1f48e02cfb822be958b68c7957156eb3f0b6e"),
                base: Portfolio.Comet.Base(
                    address: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    baseBorrowMin: Amount("0//6"),
                    decimals: 6,
                    name: "USD Coin",
                    positions: [
                        Portfolio.Comet.Position(
                            baseBorrowCapacity: Amount("1466480//6"),
                            baseLiquidationCapacity: Amount("1520131//6"),
                            borrow: Amount("1011914//6"),
                            supply: Amount("0//6"),
                            usdBorrowCapacity: Value("146638600"),
                            usdLiquidationCapacity: Value("152003400"),
                            wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        ),
                        Portfolio.Comet.Position(
                            baseBorrowCapacity: Amount("0//6"),
                            baseLiquidationCapacity: Amount("0//6"),
                            borrow: Amount("0//6"),
                            supply: Amount("0//6"),
                            usdBorrowCapacity: Value("0"),
                            usdLiquidationCapacity: Value("0"),
                            wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ),
                    ],
                    symbol: "USDC",
                    totalBalance: Amount("3236924183//6"),
                    totalBorrow: Amount("48939439660//6"),
                    totalSupply: Amount("52131384489//6"),
                    usdPrice: Value("100006375"),

                ),
                borrowApr: Percentage("210960831828384000"),
                borrowRewardsApr: Percentage("36915723587783280905"),
                collaterals: [
                    Portfolio.Comet.Collateral(
                        address: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                        decimals: 18,
                        cometBalances: [
                            Portfolio.Balance(
                                balance: Amount("0//18"),
                                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                            ),
                            Portfolio.Balance(
                                balance: Amount("0//18"),
                                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                            ),
                        ],
                        borrowCollateralFactor: Percentage("650000000000000000"),
                        liquidateCollateralFactor: Percentage("700000000000000000"),
                        liquidationFactor: Percentage("920000000000000000"),
                        name: "Compound",
                        supplyCap: Amount("500000000000000000000000//18"),
                        symbol: "COMP",
                        totalSupply: Amount("344820000100000000000//18"),
                        usdPrice: Value("5000000000"),
                        basePrice: Amount("5000000000//8"),
                    ),
                    Portfolio.Comet.Collateral(
                        address: EthAddress("0xa035b9e130f2b1aedc733eefb1c67ba4c503491f"),
                        decimals: 8,
                        cometBalances: [
                            Portfolio.Balance(
                                balance: Amount("0//8"),
                                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                            ),
                            Portfolio.Balance(
                                balance: Amount("0//8"),
                                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                            ),
                        ],
                        borrowCollateralFactor: Percentage("700000000000000000"),
                        liquidateCollateralFactor: Percentage("750000000000000000"),
                        liquidationFactor: Percentage("930000000000000000"),
                        name: "Wrapped BTC",
                        supplyCap: Amount("3500000000000//8"),
                        symbol: "WBTC",
                        totalSupply: Amount("1489//8"),
                        usdPrice: Value("6404351700000"),
                        basePrice: Amount("6404351700000//8"),
                    ),
                    Portfolio.Comet.Collateral(
                        address: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                        decimals: 18,
                        cometBalances: [
                            Portfolio.Balance(
                                balance: Amount("567224078051780//18"),
                                wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                            ),
                            Portfolio.Balance(
                                balance: Amount("0//18"),
                                wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                            ),
                        ],
                        borrowCollateralFactor: Percentage("820000000000000000"),
                        liquidateCollateralFactor: Percentage("850000000000000000"),
                        liquidationFactor: Percentage("930000000000000000"),
                        name: "Wrapped Ether",
                        supplyCap: Amount("1000000000000000000000000//18"),
                        symbol: "WETH",
                        totalSupply: Amount("23507831900917937798//18"),
                        usdPrice: Value("315288151686"),
                        basePrice: Amount("315288151686//8"),
                    ),
                ],
                name: "Compound USDC",
                reward: Portfolio.Comet.Reward(
                    address: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                    decimals: 18,
                    name: "Compound",
                    positions: [
                        Portfolio.Comet.Reward.Position(
                            rewardOwed: Amount("82462000000000000//18"),
                            wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        ),
                        Portfolio.Comet.Reward.Position(
                            rewardOwed: Amount("0//18"),
                            wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ),
                    ],
                    rewardsAddress: EthAddress("0x8bf5b658bdf0388e8b482ed51b14aef58f90abfd"),
                    symbol: "COMP",
                    usdPrice: Value("5000000000")
                ),
                supplyApr: Percentage("182833724073888000"),
                supplyRewardsApr: Percentage("350054709181925385"),
                symbol: "cUSDCv3",
            ),
        ],
        morphos: [
            Portfolio.Morpho(
                marketId: "0xb323495f7e4148be5643a4ea4a8221eef163e4bccfdedc2a6f4696baacbc86cc",
                morpho: EthAddress("0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb"),
                loanAsset: Portfolio.Morpho.LoanAsset(
                    address: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    decimals: 6,
                    name: "USD Coin",
                    positions: [
                        Portfolio.Morpho.Position(
                            baseLiquidationCapacity: Amount("860000//6"),
                            borrow: Amount("1000000//6"),
                            usdLiquidationCapacity: Value("85990400"),
                            wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        ),
                        Portfolio.Morpho.Position(
                            baseLiquidationCapacity: Amount("0//6"),
                            borrow: Amount("0//6"),
                            usdLiquidationCapacity: Value("0"),
                            wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ),
                    ],
                    symbol: "USDC",
                    totalBorrow: Amount("48821079718212//6"),
                    totalSupply: Amount("57733643171879//6"),
                    usdPrice: Value("99988833"),

                ),
                collateralAsset: Portfolio.Morpho.CollateralAsset(
                    address: EthAddress("0xb82381a3fbd3fafa77b3a7be693342618240067b"),
                    balances: [
                        Portfolio.Balance(
                            balance: Amount("500000000000000000//18"),
                            wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        ),
                        Portfolio.Balance(
                            balance: Amount("0//18"),
                            wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ),
                    ],
                    basePrice: Value("375778877364"),
                    decimals: 18,
                    name: "Wrapped liquid staked Ether 2.0",
                    symbol: "wstETH",
                    usdPrice: Value("375736914136"),
                ),
                borrowApr: Percentage("58515117410736000"),
                fixnumDecimals: 18,
                liquidationLoanToValue: Percentage("860000000000000000"),
                borrowRewards: [
                    Portfolio.Morpho.BorrowReward(
                        address: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                        name: "Compound",
                        rewardApr: Percentage(double: 0.01),
                        symbol: "COMP",
                    ),
                    Portfolio.Morpho.BorrowReward(
                        address: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                        name: "Wrapped Ether",
                        rewardApr: Percentage(double: 0.02),
                        symbol: "WETH",
                    ),
                ]
            )
        ],
        morphoVaults: [
            Portfolio.MorphoVault(
                address: EthAddress("0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"),
                loanAsset: Portfolio.MorphoVault.LoanAsset(
                    address: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    decimals: 6,
                    name: "USD Coin",
                    positions: [
                        Portfolio.MorphoVault.Position(
                            supply: Amount("748010038//6"),
                            wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        ),
                        Portfolio.MorphoVault.Position(
                            supply: Amount("0//6"),
                            wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ),
                    ],
                    symbol: "USDC",
                    totalSupply: Amount("28235616809105//6"),
                    usdPrice: Value("99988833"),
                ),
                fixnumDecimals: 18,
                name: "Gauntlet USDC Core",
                supplyApr: Percentage("60784632133538372"),
                symbol: "gtUSDCcore",
                supplyRewards: [
                    Portfolio.MorphoVault.SupplyReward(
                        address: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                        name: "Compound",
                        rewardApr: Percentage(double: 0.03),
                        symbol: "COMP",
                    ),
                    Portfolio.MorphoVault.SupplyReward(
                        address: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                        name: "Wrapped Ether",
                        rewardApr: Percentage(double: 0.01),
                        symbol: "WETH",
                    ),
                ],
                fee: Amount("0//18"),
            )
        ],
        queryVersion: Portfolio.QueryVersion(revision: 1, schema: "2025-03-27"),
        tokens: [
            // WETH
            Portfolio.Token(
                address: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                balances: [
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    ),
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                    ),
                ],
                decimals: 18,
                name: "Wrapped Ether",
                symbol: "WETH",
                usdPrice: Value("315288151686")
            ),
            // COMP
            Portfolio.Token(
                address: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                balances: [
                    Portfolio.Balance(
                        balance: Amount("249151405001160504216//18"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    ),
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                    ),
                ],
                decimals: 18,
                name: "Compound",
                symbol: "COMP",
                usdPrice: Value("5000000000")
            ),
            // cbETH
            Portfolio.Token(
                address: EthAddress("0xb9fa8f5ec3da13b508f462243ad0555b46e028df"),
                balances: [
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    ),
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                    ),
                ],
                decimals: 18,
                name: "Coinbase Wrapped Staked ETH",
                symbol: "cbETH",
                usdPrice: Value("305829507135")
            ),
            // wstETH
            Portfolio.Token(
                address: EthAddress("0xb82381a3fbd3fafa77b3a7be693342618240067b"),
                balances: [
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    ),
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                    ),
                ],
                decimals: 18,
                name: "Wrapped liquid staked Ether 2.0",
                symbol: "wstETH",
                usdPrice: Value("311764491302")
            ),
            // USDC
            Portfolio.Token(
                address: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                balances: [
                    Portfolio.Balance(
                        balance: Amount("12443468//6"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    ),
                    Portfolio.Balance(
                        balance: Amount("0//6"),
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                    ),
                ],
                decimals: 6,
                name: "USD Coin",
                symbol: "USDC",
                usdPrice: Value("100006375")
            ),
            // WBTC
            Portfolio.Token(
                address: EthAddress("0xa035b9e130f2b1aedc733eefb1c67ba4c503491f"),
                balances: [
                    Portfolio.Balance(
                        balance: Amount("0//8"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    ),
                    Portfolio.Balance(
                        balance: Amount("0//8"),
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                    ),
                ],
                decimals: 8,
                name: "Wrapped BTC",
                symbol: "WBTC",
                usdPrice: Value("6404351700000")
            ),
            // ETH
            Portfolio.Token(
                address: EthAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"),
                balances: [
                    Portfolio.Balance(
                        balance: Amount("49432775921948220//18"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    ),
                    Portfolio.Balance(
                        balance: Amount("0//18"),
                        wallet: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e")
                    ),
                ],
                decimals: 18,
                name: "Ether",
                symbol: "ETH",
                usdPrice: Value("315288151686")
            ),
        ],
        morphoRewardPositions: [
            Portfolio.MorphoRewardPosition(
                chainId: 11_155_111,
                asset: .init(
                    address: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    name: "USD Coin",
                    symbol: "USDC",
                    decimals: 6
                ),
                airdropRewards: [],
                distributions: [
                    Portfolio.MorphoRewardPosition.Distribution(
                        account: "0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d",
                        distributor: EthAddress("0x2efd4625d0c149ebadf118ec5446c6de24d916a4"),
                        claimable: Amount("2000000//6"),
                        proof: [
                            Hex(
                                "0x15e274cc4da3ce6471acd8b53346b892fd6033ded7da069785317958a50cf99c"
                            ),
                            Hex(
                                "0x4c37ead3cc3ef4a8954d173b515aa47bc13032fb107f009a5abc98bbffd41d65"
                            ),
                            Hex(
                                "0x6509c9e67eca8c2618671e7cb0b11dae79af09e621e0e1f2d025f1a9aae1d5a0"
                            ),
                            Hex(
                                "0x5e4b52dd31834f133c5f3deb5a7eb38f6661e7ba9b1928f1f3ce90ff8064b2ee"
                            ),
                            Hex(
                                "0xd14774b6852c785e5b064139d48b4249f7619ff6911de0e838b47e2337ad6e9e"
                            ),
                            Hex(
                                "0xa06c4c906c093a42f417f43ca103ab0234a11668c0601e08b6bbdd32616a7fab"
                            ),
                            Hex(
                                "0xd53802e4eb82c3cb7906f089bf33956132b6cd9f7ef36fd776586991ec4fded8"
                            ),
                            Hex(
                                "0xda5d9901fd3d79f4ccb1f0f755e7c004c3c85d1f5faa8a229eaa482a7c3c5932"
                            ),
                            Hex(
                                "0xedf7f4482e47eae45e20890902f58b2b7191d5e278bc96e38a2d692269470e1f"
                            ),
                            Hex(
                                "0x0dba4ec43302044ecd83718003a2724333105a4165651fb04c30a026b12cd0bb"
                            ),
                            Hex(
                                "0xfb92150816651b32f54b4edeaa9ed26c2516d1f800ed0811623294f8547b8ff5"
                            ),
                            Hex(
                                "0xcfdd30e5149457fd1e4d0874afc98f862d9753fbb5db738df207c38178d83d39"
                            ),
                            Hex(
                                "0x0b919c5793331006f9b8df52b2f164954f3f132f3461c0c72d8fdd0fdd1bd298"
                            ),
                            Hex(
                                "0x355d9b122d6c903dc5ef3eff52392a8ce322d78d049f7d5c81d2039ee8e468a0"
                            ),
                            Hex(
                                "0x0ff9c6479308b581430ac82b391d5d742a531386a50254ec811ab5698fc7fa26"
                            ),
                        ]
                    )
                ],
                marketRewards: [
                    Portfolio.MorphoRewardPosition.MarketReward(
                        total: Amount("1000000//6"),
                        account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        marketId: Hex(
                            "0xa60e9b888f343351dece4df8251abe5858fc5db96e8624d614a6500c3a3085ea"
                        ),
                        claimableNext: Amount("0//6"),
                        claimableNow: Amount("1000000//6"),
                        claimed: Amount("0//6"),
                        reallocatedFrom: nil
                    ),
                    Portfolio.MorphoRewardPosition.MarketReward(
                        total: Amount("3500000//6"),
                        account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        marketId: Hex(
                            "0x214c2bf3c899c913efda9c4a49adff23f77bbc2dc525af7c05be7ec93f32d561"
                        ),
                        claimableNext: Amount("0//6"),
                        claimableNow: Amount("1500000//6"),
                        claimed: Amount("2000000//6"),
                        reallocatedFrom: EthAddress("0x6b13c060f13af1fdb319f52315bbbf3fb1d88844")
                    ),
                ],
                uniformRewards: [],
                vaultRewards: [
                    Portfolio.MorphoRewardPosition.VaultReward(
                        total: Amount("7000000//6"),
                        account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        vault: EthAddress("0x6b13c060f13af1fdb319f52315bbbf3fb1d88844"),
                        claimableNext: Amount("1000000//6"),
                        claimableNow: Amount("1000000//6"),
                        claimed: Amount("5000000//6"),
                    )
                ]
            ),
            Portfolio.MorphoRewardPosition(
                chainId: 11_155_111,
                asset: .init(
                    address: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    name: "USD Coin",
                    symbol: "USDC",
                    decimals: 6
                ),
                airdropRewards: [],
                distributions: [],
                marketRewards: [],
                uniformRewards: [],
                vaultRewards: [
                    Portfolio.MorphoRewardPosition.VaultReward(
                        total: Amount("17100000//7"),
                        account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        vault: EthAddress("0x6b13c060f13af1fdb319f52315bbbf3fb1d88844"),
                        claimableNext: Amount("400000//6"),
                        claimableNow: Amount("600000//6"),
                        claimed: Amount("710000//6"),
                    )
                ]
            ),
        ],
        quarkNonceStatuses: [
            Portfolio.QuarkNonceStatus(
                quarkWallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                nonce: "0x3300000000000000000000000000000000000000000000000000000000000033",
                submitted: true
            )
        ],
        acrossFillStatuses: [
            Portfolio.AcrossFillStatus(
                quarkWallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                relayHash: "0x5500000000000000000000000000000000000000000000000000000000000055",
                filled: true
            )
        ],
        tokenWrapperQuotes: [
            Portfolio.TokenWrapperQuote(
                underlying: Portfolio.TokenWrapperQuote.Token(
                    address: EthAddress("0x0000000000000000000000000000000000000000"),
                    decimals: 18,
                    name: "Liquid staked Ether 2.0",
                    symbol: "stETH"
                ),
                wrapped: Portfolio.TokenWrapperQuote.Token(
                    address: EthAddress("0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452"),
                    decimals: 18,
                    name: "Wrapped liquid staked Ether 2.0",
                    symbol: "wstETH"
                ),
                underlyingHasToken: false,
                unwrapQuote: Percentage(fromNumber: Number(1_205_197_532_041_884_459))
            )
        ]
    )

@Suite("Portfolio Tests")
struct PortfolioTests {
    @Test("Test Simple Portfolio")
    func testPortfolio() async throws {
        let portfolioJSON = try String(
            contentsOf: URL(fileURLWithPath: "./Tests/Fixtures/portfolio.json")
        )
        let portfolio = try JSONDecoder()
            .decode(
                Portfolio.self,
                from: portfolioJSON.data(using: .utf8)!
            )

        #expect(portfolio == portfolioFixture)
    }

    @Test("Test chainAccounts")
    func testChainAccounts() async throws {
        let expectedChainAccounts: QuarkBuilder.Accounts.ChainAccounts = .init(
            chainId: 11_155_111,
            quarkSecrets: [
                QuarkBuilder.Accounts.QuarkSecret(
                    account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                    nonceSecret: Hex(
                        "0xca02102788f57e4e6526ac8b02ae9362dbbe093632187114854c3d0824b6b2d2"
                    )
                ),
                QuarkBuilder.Accounts.QuarkSecret(
                    account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                    nonceSecret: Hex(
                        "0x864209cbe6b3b39309c879adc4cb93b18bc2ec5d55275850628beae620eaa6c0"
                    )
                ),
            ],
            assetPositionsList: [
                QuarkBuilder.Accounts.AssetPositions(
                    asset: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                    symbol: "WETH",
                    decimals: Number(18),
                    usdPrice: Number("3152.88151686e8"),
                    accountBalances: [
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            balance: Number("0")
                        ),
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            balance: Number("0")
                        ),
                    ]
                ),
                QuarkBuilder.Accounts.AssetPositions(
                    asset: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                    symbol: "COMP",
                    decimals: Number("18"),
                    usdPrice: Number("50e8"),
                    accountBalances: [
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            balance: Number("249.151405001160504216e18")
                        ),
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            balance: Number("0")
                        ),
                    ]
                ),
                QuarkBuilder.Accounts.AssetPositions(
                    asset: EthAddress("0xb9fa8f5ec3da13b508f462243ad0555b46e028df"),
                    symbol: "cbETH",
                    decimals: Number("18"),
                    usdPrice: Number("3058.29507135e8"),
                    accountBalances: [
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            balance: Number("0")
                        ),
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            balance: Number("0")
                        ),
                    ]
                ),
                QuarkBuilder.Accounts.AssetPositions(
                    asset: EthAddress("0xb82381a3fbd3fafa77b3a7be693342618240067b"),
                    symbol: "wstETH",
                    decimals: Number("18"),
                    usdPrice: Number("3117.64491302e8"),
                    accountBalances: [
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            balance: Number("0")
                        ),
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            balance: Number("0")
                        ),
                    ]
                ),
                QuarkBuilder.Accounts.AssetPositions(
                    asset: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    symbol: "USDC",
                    decimals: Number("6"),
                    usdPrice: Number("1.00006375e8"),
                    accountBalances: [
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            balance: Number("12.443468e6")
                        ),
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            balance: Number("0")
                        ),
                    ]
                ),
                QuarkBuilder.Accounts.AssetPositions(
                    asset: EthAddress("0xa035b9e130f2b1aedc733eefb1c67ba4c503491f"),
                    symbol: "WBTC",
                    decimals: Number("8"),
                    usdPrice: Number("64043.517e8"),
                    accountBalances: [
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            balance: Number("0")
                        ),
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            balance: Number("0")
                        ),
                    ]
                ),
                QuarkBuilder.Accounts.AssetPositions(
                    asset: EthAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"),
                    symbol: "ETH",
                    decimals: Number("18"),
                    usdPrice: Number("3152.88151686e8"),
                    accountBalances: [
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            balance: Number("0.049432775921948220e18")
                        ),
                        QuarkBuilder.Accounts.AccountBalance(
                            account: EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            balance: Number("0")
                        ),
                    ]
                ),
            ],
            cometPositions: [
                QuarkBuilder.Accounts.CometPositions(
                    comet: EthAddress("0x2943ac1216979ad8db76d9147f64e61adc126e96"),
                    basePosition: QuarkBuilder.Accounts.CometBasePosition(
                        asset: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                        accounts: [
                            EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ],
                        borrowed: [
                            Number("0"),
                            Number("0"),
                        ],
                        supplied: [
                            Number("0"),
                            Number("0"),
                        ]
                    ),
                    collateralPositions: [
                        QuarkBuilder.Accounts.CometCollateralPosition(
                            asset: EthAddress("0xb9fa8f5ec3da13b508f462243ad0555b46e028df"),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            balances: [
                                Number("0"),
                                Number("0"),
                            ]
                        ),
                        QuarkBuilder.Accounts.CometCollateralPosition(
                            asset: EthAddress("0xb82381a3fbd3fafa77b3a7be693342618240067b"),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            balances: [
                                Number("0"),
                                Number("0"),
                            ]
                        ),
                    ],
                    cometRewards: [
                        QuarkBuilder.Accounts.CometReward(
                            asset: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                            rewardContract: EthAddress(
                                "0x8bf5b658bdf0388e8b482ed51b14aef58f90abfd"
                            ),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            rewardsOwed: [
                                Number("0"),
                                Number("0"),
                            ]
                        )
                    ]
                ),
                QuarkBuilder.Accounts.CometPositions(
                    comet: EthAddress("0xaec1f48e02cfb822be958b68c7957156eb3f0b6e"),
                    basePosition: QuarkBuilder.Accounts.CometBasePosition(
                        asset: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                        accounts: [
                            EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ],
                        borrowed: [
                            Number("1.011914e6"),
                            Number("0"),
                        ],
                        supplied: [
                            Number("0"),
                            Number("0"),
                        ]
                    ),
                    collateralPositions: [
                        QuarkBuilder.Accounts.CometCollateralPosition(
                            asset: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            balances: [
                                Number("0"),
                                Number("0"),
                            ]
                        ),
                        QuarkBuilder.Accounts.CometCollateralPosition(
                            asset: EthAddress("0xa035b9e130f2b1aedc733eefb1c67ba4c503491f"),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            balances: [
                                Number("0"),
                                Number("0"),
                            ]
                        ),
                        QuarkBuilder.Accounts.CometCollateralPosition(
                            asset: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            balances: [
                                Number("0.00056722407805178e18"),
                                Number("0"),
                            ]
                        ),
                    ],
                    cometRewards: [
                        QuarkBuilder.Accounts.CometReward(
                            asset: EthAddress("0xa6c8d1c55951e8ac44a0eaa959be5fd21cc07531"),
                            rewardContract: EthAddress(
                                "0x8bf5b658bdf0388e8b482ed51b14aef58f90abfd"
                            ),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            rewardsOwed: [
                                Number("0.082462e18"),
                                Number("0"),
                            ]
                        )
                    ]
                ),
            ],
            morphoPositions: [
                QuarkBuilder.Accounts.MorphoPositions(
                    marketId: Hex(
                        "0xb323495f7e4148be5643a4ea4a8221eef163e4bccfdedc2a6f4696baacbc86cc"
                    ),
                    morpho: EthAddress("0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb"),
                    loanToken: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    collateralToken: EthAddress("0xb82381a3fbd3fafa77b3a7be693342618240067b"),
                    borrowPosition: QuarkBuilder.Accounts.MorphoBorrowPosition(
                        accounts: [
                            EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ],
                        borrowed: [
                            Number("1e6"),
                            Number("0"),
                        ]
                    ),
                    collateralPosition: QuarkBuilder.Accounts.MorphoCollateralPosition(
                        accounts: [
                            EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                            EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                        ],
                        balances: [
                            Number("0.5e18"),
                            Number("0"),
                        ]
                    )
                )
            ],
            morphoVaultPositions: [
                QuarkBuilder.Accounts.MorphoVaultPositions(
                    asset: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                    accounts: [
                        EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                        EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                    ],
                    balances: [
                        Number("748.010038e6"),
                        Number("0"),
                    ],
                    vault: EthAddress("0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458")
                )
            ],
            morphoRewardDistributions: [],
            aavePositions: [
                QuarkBuilder.Accounts.AavePositions(
                    pool: EthAddress("0xa238dd80c259a72e81d7e4664a9801593f98d1c5"),
                    aaveAssetPositions: [
                        QuarkBuilder.Accounts.AaveAssetPositions(
                            asset: EthAddress("0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            borrowed: [
                                Number("0"),
                                Number("0"),
                            ],
                            supplied: [
                                Number("5e8"),
                                Number("0"),
                            ]
                        ),
                        QuarkBuilder.Accounts.AaveAssetPositions(
                            asset: EthAddress("0x2d5ee574e710219a521449679a4a7f2b43f046ad"),
                            accounts: [
                                EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                                EthAddress("0xe276bc378a527a8792b353cdca5b5e53263dfb9e"),
                            ],
                            borrowed: [
                                Number("0"),
                                Number("0"),
                            ],
                            supplied: [
                                Number("0.5e18"), Number("0"),
                            ]
                        ),
                    ]
                )
            ]
        )

        #expect(
            stripNonceSecrets(portfolioFixture.getChainAccounts(withNonceSecrets: []))
                == stripNonceSecrets(expectedChainAccounts)
        )
    }

    @Test("Test portfolio decoding")
    func testPortfolioDecoding() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("MockPortfolio.json")

        let portfolioJSON = try String(contentsOf: url, encoding: .utf8)

        let portfoliosContainer = try JSONDecoder()
            .decode(
                PortfolioResponse.self,
                from: Data(portfolioJSON.utf8)
            )

        let portfolios = portfoliosContainer.data.portfolios

        #expect(portfolios.count == 6)
    }

    /// Replace every `nonceSecret` in the `quarkSecrets` array with an all-zero
    /// 32-byte word so two `ChainAccounts` values that differ only in their random
    /// nonces can be compared in tests.
    private func stripNonceSecrets(
        _ accounts: QuarkBuilder.Accounts.ChainAccounts
    ) -> QuarkBuilder.Accounts.ChainAccounts {
        // 32-byte zero – matches the width the back-end returns.
        let zeroNonce = Hex("0x0000000000000000000000000000000000000000000000000000000000000000")

        // Re-create each QuarkSecret with the nonce replaced.
        let scrubbedSecrets = accounts.quarkSecrets.map { secret in
            QuarkBuilder.Accounts.QuarkSecret(
                account: secret.account,
                nonceSecret: zeroNonce
            )
        }

        // Re-assemble the full struct, preserving everything else verbatim.
        return .init(
            chainId: accounts.chainId,
            quarkSecrets: scrubbedSecrets,
            assetPositionsList: accounts.assetPositionsList,
            cometPositions: accounts.cometPositions,
            morphoPositions: accounts.morphoPositions,
            morphoVaultPositions: accounts.morphoVaultPositions,
            // TODO: Add morphoRewardDistributions
            morphoRewardDistributions: [],
            aavePositions: accounts.aavePositions
        )
    }

    @Test("toFolio")
    func testPortfoliosToFolio() throws {
        let quote = Quote(
            quoteId: Hex("0x123"),
            issuedAt: Date(),
            expiresAt: Date(),
            assetQuotes: [],
            networkOperationFees: []
        )

        let folio = [portfolioFixture]
            .toFolio(
                quote: quote,
                bridgeHints: [],
                prices: [
                    "ETH": Value(Number("3152.88151686e8")),
                    "cbETH": Value(Number("3058.29507135e8")),
                    "wstETH": Value(Number("3117.64491302e8")),
                    "COMP": Value(Number("50e8")),
                    "USDC": Value(Number("1.00006375e8")),
                    "WETH": Value(Number("3152.88151686e8")),
                    "WBTC": Value(Number("64043.517e8")),
                ],
                nonceSecrets: []
            )

        let expectedFolio = Folio(
            balances: [
                Prelude.Folio.BalanceType.yieldMarket(
                    yieldMarket: Prelude.Folio.YieldMarketType.aave(
                        network: Eth.Network.sepolia,
                        pool: EthAddress("0xa238dd80c259a72e81d7e4664a9801593f98d1c5"),
                        underlyingSymbol: "USDC"
                    ),
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ):
                    Prelude.Amount(underlying: Number("500e6"), decimals: 6),
                Prelude.Folio.BalanceType.token(
                    network: Eth.Network.sepolia,
                    symbol: "COMP",
                    wallet: .sepolia(EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"))
                ):
                    Prelude.Amount(underlying: Number("249.151405001160504216e18"), decimals: 18),
                Prelude.Folio.BalanceType.borrowMarketCollateral(
                    borrowMarket: Prelude.Folio.BorrowMarketType.morpho(
                        network: Eth.Network.sepolia,
                        collateralTokenSymbol: "wstETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    tokenSymbol: "wstETH",
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ):
                    Prelude.Amount(underlying: Number("0.5e18"), decimals: 18),
                Prelude.Folio.BalanceType.borrowMarket(
                    borrowMarket: Prelude.Folio.BorrowMarketType.comet(
                        network: Eth.Network.sepolia,
                        comet: EthAddress("0xaec1f48e02cfb822be958b68c7957156eb3f0b6e"),
                        underlyingSymbol: "USDC"
                    ),
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ):
                    Prelude.Amount(underlying: Number("1.011914e6"), decimals: 6),
                Prelude.Folio.BalanceType.yieldMarket(
                    yieldMarket: Prelude.Folio.YieldMarketType.aave(
                        network: Eth.Network.sepolia,
                        pool: EthAddress("0xa238dd80c259a72e81d7e4664a9801593f98d1c5"),
                        underlyingSymbol: "WETH"
                    ),
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ):
                    Prelude.Amount(underlying: Number("0.5e18"), decimals: 18),
                Prelude.Folio.BalanceType.borrowMarketCollateral(
                    borrowMarket: Prelude.Folio.BorrowMarketType.comet(
                        network: Eth.Network.sepolia,
                        comet: EthAddress("0xaec1f48e02cfb822be958b68c7957156eb3f0b6e"),
                        underlyingSymbol: "WETH"
                    ),
                    tokenSymbol: "WETH",
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ):
                    Prelude.Amount(underlying: Number("0.00056722407805178e18"), decimals: 18),
                Prelude.Folio.BalanceType.token(
                    network: Eth.Network.sepolia,
                    symbol: "ETH",
                    wallet: .sepolia(EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"))
                ):
                    Prelude.Amount(underlying: Number("0.049432775921948220e18"), decimals: 18),
                Prelude.Folio.BalanceType.reward(
                    rewardType: Prelude.Folio.RewardType.cometReward(
                        network: Eth.Network.sepolia,
                        comet: EthAddress("0xaec1f48e02cfb822be958b68c7957156eb3f0b6e"),
                        underlyingSymbol: "COMP",
                        cometRewards: EthAddress("0x8bf5b658bdf0388e8b482ed51b14aef58f90abfd"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    )
                ):
                    Prelude.Amount(underlying: Number("0.082462e18"), decimals: 18),
                Prelude.Folio.BalanceType.reward(
                    rewardType: Prelude.Folio.RewardType.morphoReward(
                        network: Eth.Network.sepolia,
                        underlyingSymbol: "USDC",
                        distributor: EthAddress("0x2efd4625d0c149ebadf118ec5446c6de24d916a4"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    )
                ):
                    Prelude.Amount(underlying: Number("3.5e6"), decimals: 6),
                Prelude.Folio.BalanceType.lockedReward(
                    rewardType: Prelude.Folio.RewardType.morphoReward(
                        network: Eth.Network.sepolia,
                        underlyingSymbol: "USDC",
                        distributor: EthAddress("0x2efd4625d0c149ebadf118ec5446c6de24d916a4"),
                        wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                    )
                ):
                    Prelude.Amount(underlying: Number("1e6"), decimals: 6),
                Prelude.Folio.BalanceType.borrowMarket(
                    borrowMarket: Prelude.Folio.BorrowMarketType.morpho(
                        network: Eth.Network.sepolia,
                        collateralTokenSymbol: "wstETH",
                        borrowTokenSymbol: "USDC"
                    ),
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ):
                    Prelude.Amount(underlying: Number("1e6"), decimals: 6),
                Prelude.Folio.BalanceType.yieldMarket(
                    yieldMarket: Prelude.Folio.YieldMarketType.morphoVault(
                        network: Eth.Network.sepolia,
                        vault: EthAddress("0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"),
                        underlyingSymbol: "USDC"
                    ),
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ):
                    Prelude.Amount(underlying: Number("748.010038e6"), decimals: 6),
                Prelude.Folio.BalanceType.token(
                    network: Eth.Network.sepolia,
                    symbol: "USDC",
                    wallet: .sepolia(EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"))
                ):
                    Prelude.Amount(underlying: Number("12.443468e6"), decimals: 6),
            ],
            prices: [
                Prelude.Folio.PriceType.token(symbol: "ETH"): Prelude.Value(
                    underlying: Number("3152.88151686e8")
                ),
                Prelude.Folio.PriceType.token(symbol: "cbETH"): Prelude.Value(
                    underlying: Number("3058.29507135e8")
                ),
                Prelude.Folio.PriceType.token(symbol: "wstETH"): Prelude.Value(
                    underlying: Number("3117.64491302e8")
                ),
                Prelude.Folio.PriceType.token(symbol: "COMP"): Prelude.Value(
                    underlying: Number("50e8")
                ),
                Prelude.Folio.PriceType.token(symbol: "USDC"): Prelude.Value(
                    underlying: Number("1.00006375e8")
                ),
                Prelude.Folio.PriceType.token(symbol: "WETH"): Prelude.Value(
                    underlying: Number("3152.88151686e8")
                ),
                Prelude.Folio.PriceType.token(symbol: "WBTC"): Prelude.Value(
                    underlying: Number("64043.517e8")
                ),
            ],
            yieldMarkets: [
                Prelude.Folio.YieldMarketType.morphoVault(
                    network: Eth.Network.sepolia,
                    vault: EthAddress("0x8eb67a509616cd6a7c1b3c8c21d48ff57df3d458"),
                    underlyingSymbol: "USDC"
                ): Prelude.Folio.YieldMarket(
                    supplyApr: Prelude.Percentage(
                        underlying: SNumber("0.060784632133538372e18"),
                        factorScale: 18
                    ),
                    supplyRewardsApr: Prelude.Percentage(
                        underlying: SNumber("0.04e18"),
                        factorScale: 18
                    ),
                    supplyCap: nil,
                    totalSupply: Prelude.Amount(
                        underlying: Number("28235616.809105e6"),
                        decimals: 6
                    )
                )
            ],
            borrowMarkets: [
                Prelude.Folio.BorrowMarketType.comet(
                    network: Eth.Network.sepolia,
                    comet: EthAddress("0xaec1f48e02cfb822be958b68c7957156eb3f0b6e"),
                    underlyingSymbol: "USDC"
                ): Prelude.Folio.BorrowMarket(
                    baseBorrowMin: Prelude.Amount(underlying: Number("0"), decimals: 6),
                    borrowApr: Prelude.Percentage(
                        underlying: SNumber("0.210960831828384e18"),
                        factorScale: 18
                    ),
                    borrowRewardsApr: Prelude.Percentage(
                        underlying: SNumber("36.915723587783280905e18"),
                        factorScale: 18
                    ),
                    borrowCap: nil,
                    totalBorrow: Prelude.Amount(underlying: Number("48939.43966e6"), decimals: 6),
                    collaterals: [
                        "COMP": Prelude.Folio.BorrowMarket.Collateral(
                            borrowCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.65e18"),
                                factorScale: 18
                            ),
                            liquidateCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.7e18"),
                                factorScale: 18
                            ),
                            liquidationFactor: Optional(
                                Prelude.Percentage(
                                    underlying: SNumber("0.92e18"),
                                    factorScale: 18
                                )
                            ),
                            supplyCap: Optional(
                                Prelude.Amount(
                                    underlying: Number("500000e18"),
                                    decimals: 18
                                )
                            ),
                            totalSupply: Optional(
                                Prelude.Amount(
                                    underlying: Number("344.8200001e18"),
                                    decimals: 18
                                )
                            ),
                            usdPrice: Prelude.Value(underlying: Number("50e8"))
                        ),
                        "WBTC": Prelude.Folio.BorrowMarket.Collateral(
                            borrowCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.7e18"),
                                factorScale: 18
                            ),
                            liquidateCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.75e18"),
                                factorScale: 18
                            ),
                            liquidationFactor: Optional(
                                Prelude.Percentage(
                                    underlying: SNumber("0.93e18"),
                                    factorScale: 18
                                )
                            ),
                            supplyCap: Optional(
                                Prelude.Amount(underlying: Number("35000e8"), decimals: 8)
                            ),
                            totalSupply: Optional(
                                Prelude.Amount(underlying: Number("0.00001489e8"), decimals: 8)
                            ),
                            usdPrice: Prelude.Value(underlying: Number("64043.517e8"))
                        ),
                        "WETH": Prelude.Folio.BorrowMarket.Collateral(
                            borrowCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.82e18"),
                                factorScale: 18
                            ),
                            liquidateCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.85e18"),
                                factorScale: 18
                            ),
                            liquidationFactor: Optional(
                                Prelude.Percentage(
                                    underlying: SNumber("0.93e18"),
                                    factorScale: 18
                                )
                            ),
                            supplyCap: Optional(
                                Prelude.Amount(
                                    underlying: Number("1000000e18"),
                                    decimals: 18
                                )
                            ),
                            totalSupply: Optional(
                                Prelude.Amount(
                                    underlying: Number("23.507831900917937798e18"),
                                    decimals: 18
                                )
                            ),
                            usdPrice: Prelude.Value(underlying: Number("3152.88151686e8"))
                        ),
                    ]
                ),
                Prelude.Folio.BorrowMarketType.morpho(
                    network: Eth.Network.sepolia,
                    collateralTokenSymbol: "wstETH",
                    borrowTokenSymbol: "USDC"
                ): Prelude.Folio.BorrowMarket(
                    borrowApr: Prelude.Percentage(
                        underlying: SNumber("0.058515117410736e18"),
                        factorScale: 18
                    ),
                    borrowRewardsApr: Prelude.Percentage(
                        underlying: SNumber("0.03e18"),
                        factorScale: 18
                    ),
                    borrowCap: nil,
                    totalBorrow: Prelude.Amount(
                        underlying: Number("48821079.718212e6"),
                        decimals: 6
                    ),
                    collaterals: [
                        "wstETH": Prelude.Folio.BorrowMarket.Collateral(
                            borrowCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.86e18"),
                                factorScale: 18
                            ),
                            liquidateCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.86e18"),
                                factorScale: 18
                            ),
                            liquidationFactor: nil,
                            supplyCap: nil,
                            totalSupply: nil,
                            usdPrice: Prelude.Value(underlying: Number("3757.36914136e8"))
                        )
                    ]
                ),
                Prelude.Folio.BorrowMarketType.comet(
                    network: Eth.Network.sepolia,
                    comet: EthAddress("0x2943ac1216979ad8db76d9147f64e61adc126e96"),
                    underlyingSymbol: "WETH"
                ): Prelude.Folio.BorrowMarket(
                    baseBorrowMin: Prelude.Amount(underlying: Number("0"), decimals: 18),
                    borrowApr: Prelude.Percentage(
                        underlying: SNumber("0.00994522433832e18"),
                        factorScale: 18
                    ),
                    borrowRewardsApr: Prelude.Percentage(
                        underlying: SNumber("0"),
                        factorScale: 18
                    ),
                    borrowCap: nil,
                    totalBorrow: Prelude.Amount(
                        underlying: Number("0.000000969017000499e18"),
                        decimals: 18
                    ),
                    collaterals: [
                        "cbETH": Prelude.Folio.BorrowMarket.Collateral(
                            borrowCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.9e18"),
                                factorScale: 18
                            ),
                            liquidateCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.93e18"),
                                factorScale: 18
                            ),
                            liquidationFactor: Optional(
                                Prelude.Percentage(
                                    underlying: SNumber("0.95e18"),
                                    factorScale: 18
                                )
                            ),
                            supplyCap: Optional(
                                Prelude.Amount(
                                    underlying: Number("9000e18"),
                                    decimals: 18
                                )
                            ),
                            totalSupply: Optional(
                                Prelude.Amount(
                                    underlying: Number("2.000134115105271783e18"),
                                    decimals: 18
                                )
                            ),
                            usdPrice: Prelude.Value(underlying: Number("3058.29507135e8"))
                        ),
                        "wstETH": Prelude.Folio.BorrowMarket.Collateral(
                            borrowCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.9e18"),
                                factorScale: 18
                            ),
                            liquidateCollateralFactor: Prelude.Percentage(
                                underlying: SNumber("0.93e18"),
                                factorScale: 18
                            ),
                            liquidationFactor: Optional(
                                Prelude.Percentage(
                                    underlying: SNumber("0.95e18"),
                                    factorScale: 18
                                )
                            ),
                            supplyCap: Optional(
                                Prelude.Amount(
                                    underlying: Number("80000e18"),
                                    decimals: 18
                                )
                            ),
                            totalSupply: Optional(
                                Prelude.Amount(underlying: Number("0"), decimals: 18)
                            ),
                            usdPrice: Prelude.Value(underlying: Number("3117.64491302e8"))
                        ),
                    ]
                ),
            ],
            rewards: [
                Prelude.Folio.RewardType.cometReward(
                    network: Eth.Network.sepolia,
                    comet: EthAddress("0xaec1f48e02cfb822be958b68c7957156eb3f0b6e"),
                    underlyingSymbol: "COMP",
                    cometRewards: EthAddress("0x8bf5b658bdf0388e8b482ed51b14aef58f90abfd"),
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ): Prelude.Folio
                    .Reward(
                        proof: Prelude.Folio.Reward.Proof.none
                    ),
                Prelude.Folio.RewardType.morphoReward(
                    network: Eth.Network.sepolia,
                    underlyingSymbol: "USDC",
                    distributor: EthAddress("0x2efd4625d0c149ebadf118ec5446c6de24d916a4"),
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d")
                ): Prelude.Folio
                    .Reward(
                        proof: Prelude.Folio.Reward.Proof.morphoReward(
                            proof: [
                                Hex(
                                    "0x15e274cc4da3ce6471acd8b53346b892fd6033ded7da069785317958a50cf99c"
                                ),
                                Hex(
                                    "0x4c37ead3cc3ef4a8954d173b515aa47bc13032fb107f009a5abc98bbffd41d65"
                                ),
                                Hex(
                                    "0x6509c9e67eca8c2618671e7cb0b11dae79af09e621e0e1f2d025f1a9aae1d5a0"
                                ),
                                Hex(
                                    "0x5e4b52dd31834f133c5f3deb5a7eb38f6661e7ba9b1928f1f3ce90ff8064b2ee"
                                ),
                                Hex(
                                    "0xd14774b6852c785e5b064139d48b4249f7619ff6911de0e838b47e2337ad6e9e"
                                ),
                                Hex(
                                    "0xa06c4c906c093a42f417f43ca103ab0234a11668c0601e08b6bbdd32616a7fab"
                                ),
                                Hex(
                                    "0xd53802e4eb82c3cb7906f089bf33956132b6cd9f7ef36fd776586991ec4fded8"
                                ),
                                Hex(
                                    "0xda5d9901fd3d79f4ccb1f0f755e7c004c3c85d1f5faa8a229eaa482a7c3c5932"
                                ),
                                Hex(
                                    "0xedf7f4482e47eae45e20890902f58b2b7191d5e278bc96e38a2d692269470e1f"
                                ),
                                Hex(
                                    "0x0dba4ec43302044ecd83718003a2724333105a4165651fb04c30a026b12cd0bb"
                                ),
                                Hex(
                                    "0xfb92150816651b32f54b4edeaa9ed26c2516d1f800ed0811623294f8547b8ff5"
                                ),
                                Hex(
                                    "0xcfdd30e5149457fd1e4d0874afc98f862d9753fbb5db738df207c38178d83d39"
                                ),
                                Hex(
                                    "0x0b919c5793331006f9b8df52b2f164954f3f132f3461c0c72d8fdd0fdd1bd298"
                                ),
                                Hex(
                                    "0x355d9b122d6c903dc5ef3eff52392a8ce322d78d049f7d5c81d2039ee8e468a0"
                                ),
                                Hex(
                                    "0x0ff9c6479308b581430ac82b391d5d742a531386a50254ec811ab5698fc7fa26"
                                ),
                            ],
                            proofAmount: Prelude.Amount(underlying: Number("2e6"), decimals: 6)
                        )
                    ),
            ],
            swapHints: [
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.sepolia,
                    underlyingSymbol: "stETH",
                    wrappedNetwork: Eth.Network.sepolia,
                    wrappedSymbol: "wstETH"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: Prelude.Percentage(
                            underlying: SNumber("1.205197532041884459e18"),
                            factorScale: 18
                        )
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.base,
                    underlyingSymbol: "ETH",
                    wrappedNetwork: Eth.Network.base,
                    wrappedSymbol: "WETH"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.unichain,
                    underlyingSymbol: "ETH",
                    wrappedNetwork: Eth.Network.unichain,
                    wrappedSymbol: "WETH"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.optimism,
                    underlyingSymbol: "ETH",
                    wrappedNetwork: Eth.Network.optimism,
                    wrappedSymbol: "WETH"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.arbitrum,
                    underlyingSymbol: "ETH",
                    wrappedNetwork: Eth.Network.arbitrum,
                    wrappedSymbol: "WETH"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.ethereum,
                    underlyingSymbol: "ETH",
                    wrappedNetwork: Eth.Network.ethereum,
                    wrappedSymbol: "WETH"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.worldChain,
                    underlyingSymbol: "ETH",
                    wrappedNetwork: Eth.Network.worldChain,
                    wrappedSymbol: "WETH"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.hyperEVM,
                    underlyingSymbol: "HYPE",
                    wrappedNetwork: Eth.Network.hyperEVM,
                    wrappedSymbol: "WHYPE"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
                Prelude.Folio.SwapHintType.wrapper(
                    underlyingNetwork: Eth.Network.polygon,
                    underlyingSymbol: "POL",
                    wrappedNetwork: Eth.Network.polygon,
                    wrappedSymbol: "WPOL"
                ): Prelude.Folio
                    .SwapHint(
                        minAmount: nil,
                        maxAmount: nil,
                        exchangeRate: .one
                    ),
            ],
            bridgeHints: [:],
            hexData: [:],
            completionStatuses: [
                Prelude.Folio.CompletionStatusType.acrossFill(
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                    relayHash: Hex(
                        "0x5500000000000000000000000000000000000000000000000000000000000055"
                    )
                ):
                    true,
                Prelude.Folio.CompletionStatusType.quarkNonce(
                    wallet: EthAddress("0xf6f148cfb92dd3baf399b0ecd1a8561b7f16487d"),
                    nonce: Hex("0x3300000000000000000000000000000000000000000000000000000000000033")
                ): true,
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try encoder.encode(folio)
        let expectedJson = try encoder.encode(expectedFolio)
        #expect(
            String(data: json, encoding: .utf8)! == String(data: expectedJson, encoding: .utf8)!
        )
    }
}
