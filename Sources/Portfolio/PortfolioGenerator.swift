import Eth
import Foundation
import Prelude
import SwiftNumber

public enum PortfolioGenerator {
    /// Generates a random portfolio JSON string with the given quark wallet address and all givens.
    /// - Parameters:
    ///   - quarkWalletAddress:
    ///   - allGivens:
    /// - Returns: Portfolio JSON string.
    public static func generatePortfolios(
        quarkWalletAddress: EthAddress = randomAddress(),
        given allGivens: [Given] = []
    ) -> String {
        var portfolios: [[String: Any]] = []

        // Break givens by chain to create a portfolio object for each chain
        var givensByChain: [Network: [Given]] = [:]
        for given in allGivens {
            givensByChain[given.network, default: []].append(given)
        }

        for (network, givens) in givensByChain {
            // MARK: Wallets

            let wallets: [[String: Any]] = [
                [
                    "wallet": quarkWalletAddress.hex,
                    "quark_version": "",
                    "is_quark": true,
                    "has_code": true,
                ]
            ]

            // MARK: Block

            let block: [String: Any] = [
                "timestamp": Int(Date().timeIntervalSince1970),
                "number": 22_627_222,
            ]

            // MARK: Tokens

            var tokenBalances: [MockToken: Amount] = [:]
            for given in givens {
                switch given {
                    case .tokenBalance(let token, let amount, _):
                        tokenBalances[token, default: .init(0, decimals: amount.decimals)] += amount
                    default:
                        continue
                }
            }

            let tokens: [[String: Any]] = tokenBalances.map { token, amount in
                [
                    // "address": token.address(network: network).description,
                    // "decimals": amount.decimals,
                    // "name": token.name,
                    // "price_decimals": 8,
                    // "symbol": token.symbol,
                    // "usd_price": token.defaultUsdPrice.underlying.description,
                    // "balances": [
                    //     [
                    //         "balance": amount.underlying.description,
                    //         "wallet": quarkWalletAddress.description,
                    //     ]
                    // ],
                    "address": token.address(network: network).hex,
                    "decimals": amount.decimals,
                    "name": token.name,
                    "symbol": token.symbol,
                    "usd_price": [
                        "type": "decimal",
                        "precision": Value.priceFeedDecimalsInt,
                        "uint_string": token.defaultUsdPrice.underlying.description,
                    ],
                    "balances": [
                        [
                            "balance": [
                                "type": "decimal",
                                "precision": amount.decimals,
                                "uint_string": amount.underlying.description,
                            ],
                            "wallet": quarkWalletAddress.hex,
                        ]
                    ],
                ]
            }

            // MARK: Aave Markets

            var givensByAave: [MockAave: [Given]] = [:]
            for given in givens {
                switch given {
                    case .aaveSupply(_, _, let aave, _):
                        givensByAave[aave, default: []] += [given]
                    default:
                        continue
                }
            }

            var aaveMarkets: [[String: Any]] = []
            for (aave, givens) in givensByAave {
                var assetPositions: [[String: Any]] = []

                for given in givens {
                    switch given {
                        case .aaveSupply(let token, let amount, _, let network):
                            let assetPosition: [String: Any] = [
                                "decimals": amount.decimals,
                                "address": token.address(network: network).hex,
                                "symbol": token.symbol,
                                "positions": [
                                    [
                                        "wallet": quarkWalletAddress.hex,
                                        "usage_as_collateral_enabled_on_user": false,
                                        "supplied": [
                                            "type": "decimal",
                                            "precision": amount.decimals,
                                            "uint_string": amount.underlying.description,
                                        ],
                                        "borrowed": [
                                            "type": "decimal",
                                            "precision": amount.decimals,
                                            "uint_string": "0",
                                        ],
                                    ]
                                ],
                                "total_supply": [
                                    "type": "decimal",
                                    "precision": amount.decimals,
                                    "uint_string": (amount.underlying * 1000).description,
                                ],
                                "supply_apr": [
                                    "type": "decimal",
                                    "precision": 27,
                                    "uint_string": aave.defaultSupplyApr.underlying.description,
                                ],
                                "borrow_apr": [
                                    "type": "decimal",
                                    "precision": 27,
                                    "uint_string": aave.defaultBorrowApr.underlying.description,
                                ],
                                "usd_price": [
                                    "type": "decimal",
                                    "precision": Value.priceFeedDecimalsInt,
                                    "uint_string": token.defaultUsdPrice.underlying.description,
                                ],
                                "usage_as_collateral_enabled": true,
                                "total_borrow": [
                                    "type": "decimal",
                                    "precision": amount.decimals,
                                    "uint_string": "0",
                                ],
                                "supply_cap": [
                                    "type": "decimal",
                                    "precision": amount.decimals,
                                    "uint_string": "130000",
                                ],
                                "liquidation_ltv": [
                                    "type": "decimal",
                                    "precision": 4,
                                    "uint_string": "8300",
                                ],
                                "is_siloed_borrowing": false,
                                "is_paused": false,
                                "is_frozen": false,
                                "is_active": true,
                                "collateral_ltv": [
                                    "type": "decimal",
                                    "precision": 4,
                                    "uint_string": "8000",
                                ],
                                "borrowing_enabled": true,
                                "borrow_cap": [
                                    "type": "decimal",
                                    "precision": amount.decimals,
                                    "uint_string": "110000",
                                ],
                                "base_price_decimals": Value.priceFeedDecimalsInt,
                                "base_price": [
                                    "type": "decimal",
                                    "precision": Value.priceFeedDecimalsInt,
                                    "uint_string": token.defaultUsdPrice.underlying.description,
                                ],
                                "is_borrowable_in_isolation": false,
                            ]
                            assetPositions.append(assetPosition)
                        default:
                            continue
                    }
                }

                let aaveMarket: [String: Any] = [
                    "name": aave.name,
                    "pool": aave.poolAddress(network: network).hex,
                    "positions": [
                        [
                            "wallet": quarkWalletAddress.hex,
                            "base_liquidation_point": [
                                "type": "decimal",
                                "precision": 8,
                                "uint_string": "0",
                            ],
                            "base_borrow_capacity": [
                                "type": "decimal",
                                "precision": 8,
                                "uint_string": "0",
                            ],
                            "usd_liquidation_point": [
                                "type": "decimal",
                                "precision": 8,
                                "uint_string": "0",
                            ],
                            "usd_borrow_capacity": [
                                "type": "decimal",
                                "precision": 8,
                                "uint_string": "0",
                            ],
                        ]
                    ],
                    "asset_positions": assetPositions,
                ]
                aaveMarkets.append(aaveMarket)
            }

            // Mark: Comets

            var givensByComet: [MockComet: [Given]] = [:]
            for given in givens {
                switch given {
                    case .cometSupply(_, _, let comet, _),
                        .cometBorrow(_, _, let comet, _),
                        .cometReward(_, _, let comet, _):
                        givensByComet[comet, default: []] += [given]
                    default:
                        continue
                }
            }

            var comets: [[String: Any]] = []
            for (comet, givens) in givensByComet {
                var baseSupply: Number = 0
                var baseBorrow: Number = 0
                var baseDecimals = comet.baseAsset.defaultDecimals
                var collateralSupplies: [String: (MockToken, MockComet, Amount, Network)] = [:]
                var rewardAmounts: [String: (MockToken, Amount, MockComet, Network)] = [:]

                for given in givens {
                    switch given {
                        case .cometSupply(let token, let amount, let comet, let network):
                            if token.symbol == comet.baseAsset.symbol {
                                baseSupply += amount.underlying
                                baseDecimals = amount.decimals
                            } else {
                                let currentSupply = collateralSupplies[
                                    token.symbol,
                                    default: (
                                        token, comet, .init(0, decimals: amount.decimals), network
                                    )
                                ]
                                let newSupply = currentSupply.2 + amount
                                collateralSupplies[token.symbol] = (
                                    token, comet, newSupply, network
                                )
                            }

                        case .cometBorrow(let token, let amount, let comet, _):
                            guard token.symbol == comet.baseAsset.symbol else {
                                fatalError(
                                    "Cannot create comet borrow for asset \(token.symbol) which is not the base asset for \(comet.symbol)"
                                )
                            }

                            baseBorrow += amount.underlying
                            baseDecimals = amount.decimals

                        case .cometReward(let token, let amount, let comet, let network):
                            let currentReward = rewardAmounts[
                                token.symbol,
                                default: (
                                    token, .init(0, decimals: amount.decimals), comet, network
                                )
                            ]
                            let newReward = currentReward.1 + amount
                            rewardAmounts[token.symbol] = (token, newReward, comet, network)

                        default:
                            continue
                    }
                }

                var collaterals: [[String: Any]] = []
                var baseBorrowCapacity: Number = .zero
                var baseLiquidationPoint: Number = .zero
                var usdBorrowCapacity: Number = .zero
                var usdLiquidationPoint: Number = .zero

                for (_, (token, comet, amount, network)) in collateralSupplies {
                    let basePrice =
                        token.defaultUsdPrice.underlying * .pow10(8)
                        / comet.baseAsset.defaultUsdPrice.underlying
                    let (borrowCollateralFactor, liquidateCollateralFactor, liquidationFactor) =
                        token.defaultCometBorrowParams

                    baseBorrowCapacity +=
                        (basePrice * amount.underlying * Number(borrowCollateralFactor.underlying))
                        * .pow10(baseDecimals) / (.pow10(8) * .pow10(amount.decimals) * .pow10(18))
                    baseLiquidationPoint +=
                        (basePrice * amount.underlying * Number(liquidationFactor.underlying))
                        * .pow10(baseDecimals) / (.pow10(8) * .pow10(amount.decimals) * .pow10(18))
                    usdBorrowCapacity +=
                        (token.defaultUsdPrice.underlying * amount.underlying
                            * Number(borrowCollateralFactor.underlying)) * .pow10(baseDecimals)
                        / (.pow10(8) * .pow10(amount.decimals) * .pow10(18))
                    usdLiquidationPoint +=
                        (token.defaultUsdPrice.underlying * amount.underlying
                            * Number(liquidationFactor.underlying)) * .pow10(baseDecimals)
                        / (.pow10(8) * .pow10(amount.decimals) * .pow10(18))

                    collaterals += [
                        [
                            "decimals": amount.decimals,
                            "name": token.name,
                            "address": token.address(network: network).hex,
                            "symbol": token.symbol,
                            "total_supply": [
                                "type": "decimal",
                                "precision": amount.decimals,
                                "uint_string": "4658194244337040198837251",
                            ],
                            "usd_price": [
                                "type": "decimal",
                                "precision": Value.priceFeedDecimalsInt,
                                "uint_string": token.defaultUsdPrice.underlying.description,
                            ],
                            "supply_cap": [
                                "type": "decimal",
                                "precision": amount.decimals,
                                "uint_string": "16000000000000000000000000",
                            ],
                            "base_price": [
                                "type": "decimal",
                                "precision": Value.priceFeedDecimalsInt,
                                "uint_string": basePrice.description,
                            ],
                            "balances": [
                                [
                                    "balance": [
                                        "type": "decimal",
                                        "precision": amount.decimals,
                                        "uint_string": amount.underlying.description,
                                    ],
                                    "wallet": quarkWalletAddress.hex,
                                ]
                            ],
                            "borrow_collateral_factor": [
                                "type": "decimal",
                                "precision": 18,
                                "uint_string": borrowCollateralFactor.underlying.description,
                            ],
                            "liquidate_collateral_factor": [
                                "type": "decimal",
                                "precision": 18,
                                "uint_string": liquidateCollateralFactor.underlying.description,
                            ],
                            "liquidation_factor": [
                                "type": "decimal",
                                "precision": 18,
                                "uint_string": liquidationFactor.underlying.description,
                            ],
                        ]
                    ]
                }

                if rewardAmounts.count > 1 {
                    fatalError("Comet only supports one reward token")
                }

                var reward: Any = NSNull()
                if let (token, amount, comet, network) = rewardAmounts.values.first {
                    reward = [
                        "address": token.address(network: network).hex,
                        "decimals": amount.decimals,
                        "name": token.name,
                        "symbol": token.symbol,
                        "positions": [
                            [
                                "wallet": quarkWalletAddress.hex,
                                "reward_owed": [
                                    "type": "decimal",
                                    "precision": amount.decimals,
                                    "uint_string": amount.underlying.description,
                                ],
                            ]
                        ],
                        "rewards_address": comet.rewardsAddress(network: network).hex,
                        "usd_price": [
                            "type": "decimal",
                            "precision": Value.priceFeedDecimalsInt,
                            "uint_string": token.defaultUsdPrice.underlying.description,
                        ],
                    ] as [String: Any]
                }

                if !baseSupply.isZero && !baseBorrow.isZero {
                    fatalError("Cannot have both a supply and a borrow of base asset")
                }

                if usdLiquidationPoint < baseBorrow {
                    fatalError("Insufficient collateral provided for the given borrow amount")
                }

                let cometBase: [String: Any] = [
                    "address": comet.baseAsset.address(network: network).hex,
                    "decimals": baseDecimals,
                    "name": comet.baseAsset.name,
                    "symbol": comet.baseAsset.symbol,
                    "positions": [
                        [
                            "supply": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": baseSupply.description,
                            ],
                            "borrow": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": baseBorrow.description,
                            ],
                            "wallet": quarkWalletAddress.hex,
                            "base_borrow_capacity": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": baseBorrowCapacity.description,
                            ],
                            "base_liquidation_point": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": baseLiquidationPoint.description,
                            ],
                            "usd_borrow_capacity": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": usdBorrowCapacity.description,
                            ],
                            "usd_liquidation_point": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": usdLiquidationPoint.description,
                            ],
                        ]
                    ],
                    "usd_price": [
                        "type": "decimal",
                        "precision": Value.priceFeedDecimalsInt,
                        "uint_string": comet.baseAsset.defaultUsdPrice.underlying
                            .description,
                    ],
                    "total_supply": [
                        "type": "decimal",
                        "precision": baseDecimals,
                        "uint_string": "33592810184362",
                    ],
                    "total_borrow": [
                        "type": "decimal",
                        "precision": baseDecimals,
                        "uint_string": "30392470712129",
                    ],
                    "total_balance": [
                        "type": "decimal",
                        "precision": baseDecimals,
                        "uint_string": "4083704601270",
                    ],
                    "base_borrow_min": [
                        "type": "decimal",
                        "precision": baseDecimals,
                        "uint_string": "0",
                    ],
                ]

                comets += [
                    [
                        "address": comet.address(network: network).hex,
                        "symbol": comet.symbol,
                        "name": comet.name,
                        "base": cometBase,
                        "collaterals": collaterals,
                        "reward": reward,
                        "borrow_apr": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": comet.defaultBorrowApr.underlying.description,
                        ],
                        "borrow_rewards_apr": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": comet.defaultBorrowRewardsApr.underlying.description,
                        ],
                        "supply_apr": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": comet.defaultSupplyApr.underlying.description,
                        ],
                        "supply_rewards_apr": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": comet.defaultSupplyRewardsApr.underlying.description,
                        ],
                        "factor_decimals": 18,
                    ]
                ]
            }

            // MARK: Morpho Markets

            var givensByMorpho: [MockMorpho: [Given]] = [:]
            for given in givens {
                switch given {
                    case .morphoBorrow(_, _, let morpho, _):
                        givensByMorpho[morpho, default: []] += [given]
                    default:
                        continue
                }
            }

            var morphoMarkets: [[String: Any]] = []
            for (morpho, givens) in givensByMorpho {
                var baseBorrow: Number = 0
                var baseDecimals = 0
                var collateralSupply: Number = 0
                var collateralDecimals = 0
                var baseLiquidationPoint: Number = 0
                var usdLiquidationPoint: Number = 0

                for given in givens {
                    switch given {
                        case .morphoBorrow(let borrow, let collateral, let morpho, _):
                            baseBorrow += borrow.underlying
                            baseDecimals = borrow.decimals
                            collateralSupply = collateral.underlying
                            collateralDecimals = collateral.decimals

                            let basePrice =
                                morpho.collateralAsset.defaultUsdPrice.underlying * .pow10(8)
                                / morpho.borrowAsset.defaultUsdPrice.underlying

                            baseLiquidationPoint +=
                                (basePrice * collateral.underlying
                                    * Number(morpho.defaultLiquidationLoanToValue.underlying)
                                    * .pow10(8))
                                / (.pow10(8) * .pow10(collateral.decimals) * .pow10(18))
                            usdLiquidationPoint +=
                                (morpho.collateralAsset.defaultUsdPrice.underlying
                                    * collateral.underlying
                                    * Number(morpho.defaultLiquidationLoanToValue.underlying)
                                    * .pow10(baseDecimals))
                                / (.pow10(8) * .pow10(collateral.decimals) * .pow10(18))
                        default:
                            continue
                    }
                }

                let basePrice =
                    morpho.collateralAsset.defaultUsdPrice.underlying * .pow10(8)
                    / morpho.borrowAsset.defaultUsdPrice.underlying

                morphoMarkets += [
                    [
                        "market_id": morpho.marketId,
                        "morpho": "0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb",
                        "borrow_apr": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": morpho.defaultBorrowApr.underlying.description,
                        ],
                        "borrow_rewards_apr": [
                            [
                                "name": morpho.collateralAsset.name,
                                "address": morpho.collateralAsset.address(network: network).hex,
                                "symbol": morpho.collateralAsset.symbol,
                                "reward_apr": [
                                    "type": "decimal",
                                    "precision": 18,
                                    "uint_string": morpho.defaultBorrowRewardsApr.underlying
                                        .description,
                                ],
                            ]
                        ],
                        "collateral_asset": [
                            "decimals": collateralDecimals,
                            "name": morpho.collateralAsset.name,
                            "address": morpho.collateralAsset.address(network: network).hex,
                            "symbol": morpho.collateralAsset.symbol,
                            "usd_price": [
                                "type": "decimal",
                                "precision": Value.priceFeedDecimalsInt,
                                "uint_string": morpho.collateralAsset.defaultUsdPrice.underlying
                                    .description,
                            ],
                            "base_price": [
                                "type": "decimal",
                                "precision": Value.priceFeedDecimalsInt,
                                "uint_string": basePrice.description,
                            ],
                            "balances": [
                                [
                                    "balance": [
                                        "type": "decimal",
                                        "precision": collateralDecimals,
                                        "uint_string": collateralSupply.description,
                                    ],
                                    "wallet": quarkWalletAddress.hex,
                                ]
                            ],
                        ],
                        "fixnum_decimals": 18,
                        "liquidation_loan_to_value": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": morpho.defaultLiquidationLoanToValue.underlying
                                .description,
                        ],
                        "loan_asset": [
                            "decimals": baseDecimals,
                            "name": morpho.borrowAsset.name,
                            "address": morpho.borrowAsset.address(network: network).hex,
                            "symbol": morpho.borrowAsset.symbol,
                            "positions": [
                                [
                                    "borrow": [
                                        "type": "decimal",
                                        "precision": baseDecimals,
                                        "uint_string": baseBorrow.description,
                                    ],
                                    "usd_liquidation_point": [
                                        "type": "decimal",
                                        "precision": baseDecimals,
                                        "uint_string": usdLiquidationPoint.description,
                                    ],
                                    "base_liquidation_point": [
                                        "type": "decimal",
                                        "precision": baseDecimals,
                                        "uint_string": baseLiquidationPoint.description,
                                    ],
                                    "wallet": quarkWalletAddress.hex,
                                ]
                            ],
                            "total_borrow": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": "6508915770239",
                            ],
                            "total_supply": [
                                "type": "decimal",
                                "precision": baseDecimals,
                                "uint_string": "7424166671421",
                            ],
                            "usd_price": [
                                "type": "decimal",
                                "precision": Value.priceFeedDecimalsInt,
                                "uint_string": morpho.borrowAsset.defaultUsdPrice.underlying
                                    .description,
                            ],
                        ],
                    ]
                ]
            }

            // MARK: Morpho Vaults

            var givensByMorphoVault: [MockMorphoVault: [Given]] = [:]
            for given in givens {
                switch given {
                    case .morphoVaultSupply(_, let morphoVault, _):
                        givensByMorphoVault[morphoVault, default: []] += [given]
                    default:
                        continue
                }
            }

            var morphoVaults: [[String: Any]] = []
            for (morphoVault, givens) in givensByMorphoVault {
                var loanAssetAmount: Number = 0
                var loanAssetDecimals = 0

                for given in givens {
                    switch given {
                        case .morphoVaultSupply(let amount, _, _):
                            loanAssetAmount = amount.underlying
                            loanAssetDecimals = amount.decimals
                        default:
                            continue
                    }
                }

                morphoVaults += [
                    [
                        "name": morphoVault.description,
                        "address": morphoVault.address(network: network).hex,
                        "symbol": morphoVault.token.symbol,
                        "fee": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": "0",
                        ],
                        "supply_apr": [
                            "type": "decimal",
                            "precision": 18,
                            "uint_string": morphoVault.defaultSupplyApr.underlying.description,
                        ],
                        "supply_rewards_apr": [
                            [
                                "name": morphoVault.token.name,
                                "address": morphoVault.token.address(network: network).hex,
                                "symbol": morphoVault.token.symbol,
                                "reward_apr": [
                                    "type": "decimal",
                                    "precision": 18,
                                    "uint_string":  morphoVault.defaultSupplyRewardsApr.underlying
                                        .description,
                                ],
                            ]
                        ],
                        "fixnum_decimals": 18,
                        "loan_asset": [
                            "decimals": loanAssetDecimals,
                            "name": morphoVault.token.name,
                            "address": morphoVault.token.address(network: network).hex,
                            "symbol": morphoVault.token.symbol,
                            "positions": [
                                [
                                    "supply": [
                                        "type": "decimal",
                                        "precision": loanAssetDecimals,
                                        "uint_string": loanAssetAmount.description,
                                    ],
                                    "wallet": quarkWalletAddress.hex,
                                ]
                            ],
                            "total_supply": [
                                "type": "decimal",
                                "precision": loanAssetDecimals,
                                "uint_string": "29223964648098",
                            ],
                            "usd_price": [
                                "type": "decimal",
                                "precision": Value.priceFeedDecimalsInt,
                                "uint_string": morphoVault.token.defaultUsdPrice.underlying
                                    .description,
                            ],
                        ],
                    ]
                ]
            }

            // MARK: Morpho Reward Positions
            let morphoRewardPositions: [[String: Any]] = []

            let quarkNonceStatuses: [[String: Any]] = []

            let acrossFillStatuses: [[String: Any]] = []

            let tokenWrapperQuotes: [[String: Any]] = []

            let queryVersion: [String: Any] = [
                "revision": 1,
                "schema": "2025-03-27",
            ]

            let portfolio: [String: Any] = [
                "block": block,
                "tokens": tokens,
                "chain_id": Int(network.chainId.description)!,
                "wallets": wallets,
                "aave_markets": aaveMarkets,
                "comets": comets,
                "morpho_markets": morphoMarkets,
                "morpho_vaults": morphoVaults,
                "morpho_reward_positions": morphoRewardPositions,
                "quark_nonce_statuses": quarkNonceStatuses,
                "across_fill_statuses": acrossFillStatuses,
                "query_version": queryVersion,
                "token_wrapper_quotes": tokenWrapperQuotes,
            ]
            portfolios += [portfolio]
        }

        let data: [String: Any] = ["portfolios": portfolios]
        let output: [String: Any] = ["data": data]

        let jsonData = try! JSONSerialization.data(
            withJSONObject: output,
            options: .prettyPrinted
        )

        return String(data: jsonData, encoding: .utf8)!
    }

    public static func randomAddress() -> EthAddress {
        let randomData = Data((0..<20).map { _ in UInt8.random(in: 0...255) })
        let hex = Hex(randomData)
        return EthAddress(hex)!
    }

    public enum Given {
        case tokenBalance(MockToken, Amount, Network)
        case cometSupply(MockToken, Amount, MockComet, Network)
        case cometBorrow(MockToken, Amount, MockComet, Network)
        case morphoBorrow(borrow: Amount, collateral: Amount, MockMorpho, Network)
        case morphoVaultSupply(Amount, MockMorphoVault, Network)
        case cometReward(MockToken, Amount, MockComet, Network)
        case morphoReward(MockToken, Amount, Network)
        case aaveSupply(MockToken, Amount, MockAave, Network)

        var network: Network {
            switch self {
                case .tokenBalance(_, _, let network),
                    .cometSupply(_, _, _, let network),
                    .cometBorrow(_, _, _, let network),
                    .morphoBorrow(_, _, _, let network),
                    .morphoVaultSupply(_, _, let network),
                    .cometReward(_, _, _, let network),
                    .morphoReward(_, _, let network),
                    .aaveSupply(_, _, _, let network):
                    network
            }
        }
    }

    public enum MockToken: Hashable, Equatable, Sendable {
        case usdc
        case eth
        case weth
        case link
        case usdt
        case wbtc
        case degen
        case cbeth
        case cbbtc
        case comp
        case morpho
        case hype
        case whype

        static let networkTokenAddress: [Network: [MockToken: EthAddress]] = [
            .ethereum: [
                .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
                .weth: EthAddress("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"),
                .usdc: EthAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
                .link: EthAddress("0x514910771af9ca656af840dff83e8264ecf986ca"),
                .usdt: EthAddress("0xdac17f958d2ee523a2206206994597c13d831ec7"),
                .wbtc: EthAddress("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"),
                .comp: EthAddress("0xc00e94Cb662C3520282E6f5717214004A7f26888"),
            ],
            .sepolia: [
                .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
                .weth: EthAddress("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"),
                .usdc: EthAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
                .link: EthAddress("0x514910771af9ca656af840dff83e8264ecf986ca"),
                .usdt: EthAddress("0xdac17f958d2ee523a2206206994597c13d831ec7"),
                .wbtc: EthAddress("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"),
                .comp: EthAddress("0xc00e94Cb662C3520282E6f5717214004A7f26888"),
            ],
            .base: [
                .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
                .weth: EthAddress("0x4200000000000000000000000000000000000006"),
                .usdc: EthAddress("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"),
                .usdt: EthAddress("0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2"),
                .wbtc: EthAddress("0x0555E30da8f98308EdB960aa94C0Db47230d2B9c"),
                .degen: EthAddress("0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed"),
                .cbeth: EthAddress("0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22"),
                .cbbtc: EthAddress("0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"),
                .comp: EthAddress("0x9e1028F5F1D5eDE59748FFceE5532509976840E0"),
                .morpho: EthAddress("0xBAa5CC21fd487B8Fcc2F632f3F4E8D37262a0842"),
            ],
            .arbitrum: [
                .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
                .weth: EthAddress("0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"),
                .usdc: EthAddress("0xaf88d065e77c8cC2239327C5EDb3A432268e5831"),
                .link: EthAddress("0xf97f4df75117a78c1A5a0DBb814Af92458539FB4"),
                .usdt: EthAddress("0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"),
                .wbtc: EthAddress("0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"),
                .comp: EthAddress("0x354A6dA3fcde098F8389cad84b0182725c6C91dE"),
            ],
            .hyperEVM: [
                .hype: EthAddress("0x000000000000000000000000000000000000B49E"),
                .whype: EthAddress("0x5555555555555555555555555555555555555555"),
                .usdc: EthAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
            ],
        ]

        func address(network: Network) -> EthAddress {
            guard let ret = MockToken.networkTokenAddress[network]?[self] else {
                fatalError("no token address found for \(self) on \(network)")
            }
            return ret
        }

        var name: String {
            switch self {
                case .usdc:
                    "USD Coin"
                case .eth:
                    "Ether"
                case .weth:
                    "Wrapped Ether"
                case .link:
                    "Link"
                case .usdt:
                    "Tether"
                case .wbtc:
                    "Wrapped Bitcoin"
                case .degen:
                    "Degen"
                case .cbeth:
                    "Coinbase Wrapped Staked Ether"
                case .cbbtc:
                    "Coinbase Wrapped BTC"
                case .comp:
                    "Compound"
                case .morpho:
                    "Morpho"
                case .hype:
                    "Hyperliquid"
                case .whype:
                    "Wrapped HYPE"
            }
        }

        var symbol: String {
            switch self {
                case .usdc:
                    "USDC"
                case .eth:
                    "ETH"
                case .weth:
                    "WETH"
                case .link:
                    "LINK"
                case .usdt:
                    "USDT"
                case .wbtc:
                    "WBTC"
                case .degen:
                    "DEGEN"
                case .cbeth:
                    "cbETH"
                case .cbbtc:
                    "cbBTC"
                case .comp:
                    "COMP"
                case .morpho:
                    "MORPHO"
                case .hype:
                    "HYPE"
                case .whype:
                    "WHYPE"
            }
        }

        var defaultDecimals: Int {
            switch self {
                case .usdc, .usdt:
                    6
                case .eth, .weth, .cbeth, .link, .degen, .comp, .morpho, .hype, .whype:
                    18
                case .wbtc, .cbbtc:
                    8
            }
        }

        var defaultUsdPrice: Value {
            switch self {
                case .usdc, .usdt:
                    return Value(double: 1.0)
                case .eth, .weth, .cbeth:
                    return Value(double: 4000.0)
                case .link:
                    return Value(double: 25.0)
                case .wbtc, .cbbtc:
                    return Value(double: 100000.0)
                case .degen, .morpho:
                    return Value(double: 2.0)
                case .comp:
                    return Value(double: 50.0)
                case .hype, .whype:
                    return Value(double: 25.0)
            }
        }

        var defaultCometBorrowParams:
            (
                borrowCollateralFactor: Percentage,
                liquidateCollateralFactor: Percentage,
                liquidationFactor: Percentage
            )
        {
            switch self {
                case .usdc, .usdt:
                    return (
                        borrowCollateralFactor: .init(double: 0.8),
                        liquidateCollateralFactor: .init(double: 0.85),
                        liquidationFactor: .init(double: 0.9)
                    )

                case .eth, .weth, .cbeth, .comp, .morpho, .hype, .whype:
                    return (
                        borrowCollateralFactor: .init(double: 0.83),
                        liquidateCollateralFactor: .init(double: 0.9),
                        liquidationFactor: .init(double: 0.93)
                    )

                case .link:
                    return (
                        borrowCollateralFactor: .init(double: 0.73),
                        liquidateCollateralFactor: .init(double: 0.79),
                        liquidationFactor: .init(double: 0.83)
                    )

                case .wbtc, .cbbtc:
                    return (
                        borrowCollateralFactor: .init(double: 0.8),
                        liquidateCollateralFactor: .init(double: 0.85),
                        liquidationFactor: .init(double: 0.90)
                    )

                case .degen:
                    return (
                        borrowCollateralFactor: .init(double: 0.83),
                        liquidateCollateralFactor: .init(double: 0.9),
                        liquidationFactor: .init(double: 0.93)
                    )
            }
        }
    }

    public enum MockComet {
        case cusdcv3
        case cwethv3

        enum Given {
            case supplied(MockToken, Amount)
            case borrowed(MockToken, Amount)
        }

        var baseAsset: MockToken {
            switch self {
                case .cusdcv3:
                    return .usdc
                case .cwethv3:
                    return .weth
            }
        }

        func address(network: Network) -> EthAddress {
            switch (network, self) {
                case (.ethereum, .cusdcv3):
                    return EthAddress("0xc3d688B66703497DAA19211EEdff47f25384cdc3")
                case (.ethereum, .cwethv3):
                    return EthAddress("0xA17581A9E3356d9A858b789D68B4d866e593aE94")
                case (.base, .cusdcv3):
                    return EthAddress("0xb125E6687d4313864e53df431d5425969c15Eb2F")
                case (.base, .cwethv3):
                    return EthAddress("0x46e6b214b524310239732D51387075E0e70970bf")
                case (.arbitrum, .cusdcv3):
                    return EthAddress("0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf")
                case (.sepolia, .cusdcv3):
                    return EthAddress("0xc3d688B66703497DAA19211EEdff47f25384cdc3")
                default:
                    fatalError("no market for comet \(self) on \(network.description) found")
            }
        }

        var symbol: String {
            switch self {
                case .cusdcv3:
                    return "cUSDCv3"
                case .cwethv3:
                    return "cWETHv3"
            }
        }

        var name: String {
            switch self {
                case .cusdcv3:
                    return "Compound USDC"
                case .cwethv3:
                    return "Compound WETH"
            }
        }

        var defaultBorrowApr: Percentage {
            switch self {
                case .cusdcv3:
                    .init("63895662356832000")
                case .cwethv3:
                    .init("22708902674880000")
            }
        }

        var defaultBorrowRewardsApr: Percentage {
            switch self {
                case .cusdcv3:
                    .init("6155403948984316")
                case .cwethv3:
                    .init("4881687984746013")
            }
        }

        var defaultSupplyApr: Percentage {
            switch self {
                case .cusdcv3:
                    .init("52133096137824000")
                case .cwethv3:
                    .init("14461854818688000")
            }
        }

        var defaultSupplyRewardsApr: Percentage {
            switch self {
                case .cusdcv3:
                    .init("11137974656774921")
                case .cwethv3:
                    .init("5134419133979482")
            }
        }

        func rewardsAddress(network: Network) -> EthAddress {
            switch network {
                case .ethereum:
                    return EthAddress("0xc3d688B66703497DAA19211EEdff47f25384cdc3")
                case .base:
                    return EthAddress("0x123964802e6ABabBE1Bc9547D72Ef1B69B00A6b1")
                case .arbitrum:
                    return EthAddress("0x443EA0340cb75a160F31A440722dec7b5bc3C2E9")
                default:
                    fatalError(
                        "no rewards contract for comet \(self) on \(network.description) found"
                    )
            }
        }
    }

    public enum MockAave: Hashable, Equatable {
        case baseMarket

        var name: String {
            switch self {
                case .baseMarket:
                    return "Aave V3 BASE Market"
            }
        }

        func poolAddress(network: Network) -> EthAddress {
            switch (network, self) {
                case (.base, .baseMarket):
                    return EthAddress("0xa238dd80c259a72e81d7e4664a9801593f98d1c5")
                default:
                    fatalError("no pool for aave \(self) on \(network.description) found")
            }
        }

        var defaultSupplyApr: Percentage {
            switch self {
                case .baseMarket:
                    // ~1.7% APR
                    .init("17034561770251324471232865")
            }
        }

        var defaultBorrowApr: Percentage {
            switch self {
                case .baseMarket:
                    // ~2.45% APR
                    .init("24519784560643707174154028")
            }
        }

        var defaultCollateralLtv: Percentage {
            switch self {
                case .baseMarket:
                    // 80%
                    .init(double: 0.8)
            }
        }

        var defaultLiquidationLtv: Percentage {
            switch self {
                case .baseMarket:
                    // 83%
                    .init(double: 0.83)
            }
        }
    }

    public enum MockMorpho: Hashable, Equatable {
        case wethUsdc
        case cbethUsdc
        case cbbtcUsdc

        var borrowAsset: MockToken {
            switch self {
                case .wethUsdc, .cbethUsdc, .cbbtcUsdc:
                    .usdc
            }
        }

        var collateralAsset: MockToken {
            switch self {
                case .wethUsdc:
                    .weth
                case .cbethUsdc:
                    .cbeth
                case .cbbtcUsdc:
                    .cbbtc
            }
        }

        public static func morpho(collateralToken: MockToken, borrowToken: MockToken) -> MockMorpho
        {
            switch (collateralToken, borrowToken) {
                case (.weth, .usdc): .wethUsdc
                case (.cbeth, .usdc): .cbethUsdc
                case (.cbbtc, .usdc): .cbbtcUsdc
                default:
                    fatalError(
                        "Morpho market not found for collateral token: \(collateralToken), borrow token: \(borrowToken)"
                    )
            }
        }

        var symbol: String {
            switch self {
                case .wethUsdc:
                    "WETH"
                case .cbethUsdc:
                    "cbETH"
                case .cbbtcUsdc:
                    "cbBTC"
            }
        }

        var description: String {
            switch self {
                case .wethUsdc:
                    "WETH"
                case .cbethUsdc:
                    "Coinbase Wrapped Staked ETH"
                case .cbbtcUsdc:
                    "Coinbase Wrapped BTC"
            }
        }

        var marketId: String {
            switch self {
                case .wethUsdc:
                    "0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda"
                case .cbethUsdc:
                    "0x1c21c59df9db44bf6f645d854ee710a8ca17b479451447e9f56758aee10a2fad"
                case .cbbtcUsdc:
                    "0x9103c3b4e834476c9a62ea009ba2c884ee42e94e6e314a26f04d312434191836"
            }
        }

        static func address(_ network: Network) -> EthAddress {
            switch network {
                case .ethereum, .base, .baseSepolia:
                    return EthAddress("0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb")
                case .sepolia:
                    return EthAddress("0xd011EE229E7459ba1ddd22631eF7bF528d424A14")
                default:
                    fatalError("Morpho not available on network: \(network.description)")
            }
        }

        var defaultBorrowApr: Percentage {
            switch self {
                case .wethUsdc:
                    Percentage("56496694236192000")
                case .cbethUsdc:
                    Percentage("46540457148240000")
                case .cbbtcUsdc:
                    Percentage("46540457148240000")
            }
        }

        var defaultBorrowRewardsApr: Percentage {
            switch self {
                case .wethUsdc:
                    Percentage("5649669423619200")
                case .cbethUsdc:
                    Percentage("4654045714824000")
                case .cbbtcUsdc:
                    Percentage("4654045714824000")
            }
        }

        var defaultLiquidationLoanToValue: Percentage {
            Percentage("860000000000000000")
        }
    }

    public enum MockMorphoVault: Hashable, Equatable {
        case usdc
        case usdt
        case weth
        case wbtc

        func address(network: Network) -> EthAddress {
            switch (network, self) {
                case (.ethereum, .usdc):
                    return EthAddress("0x8eB67A509616cd6A7c1B3c8C21D48FF57df3d458")
                case (.ethereum, .usdt):
                    return EthAddress("0x8CB3649114051cA5119141a34C200D65dc0Faa73")
                case (.ethereum, .weth):
                    return EthAddress("0x4881Ef0BF6d2365D3dd6499ccd7532bcdBCE0658")
                case (.ethereum, .wbtc):
                    return EthAddress("0x443df5eEE3196e9b2Dd77CaBd3eA76C3dee8f9b2")
                case (.base, .usdc):
                    return EthAddress("0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca")
                case (.base, .weth):
                    return EthAddress("0xa0E430870c4604CcfC7B38Ca7845B1FF653D0ff1")
                default:
                    fatalError("no vault for \(description) on network \(network.description)")
            }
        }

        var token: MockToken {
            switch self {
                case .usdc: .usdc
                case .usdt: .usdt
                case .weth: .weth
                case .wbtc: .wbtc
            }
        }

        var description: String {
            switch self {
                case .usdc:
                    return "USDC Vault"
                case .usdt:
                    return "USDT Vault"
                case .weth:
                    return "WETH Vault"
                case .wbtc:
                    return "WBTC Vault"
            }
        }

        var defaultSupplyApr: Percentage {
            switch self {
                case .usdc:
                    .init(double: 0.03)
                case .usdt:
                    .init(double: 0.04)
                case .weth:
                    .init(double: 0.02)
                case .wbtc:
                    .init(double: 0.02)
            }
        }

        var defaultSupplyRewardsApr: Percentage {
            .init(double: 0.01)
        }
    }
}
