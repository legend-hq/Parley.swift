import Eth
import Prelude
import SwiftNumber

/// MARK - Cleanup CharterError
extension Charter {
    public enum CharterError: Error, Codable, Equatable {
        case error(String)
        case assetBalanceNotFound(
            symbol: String,
            network: Network,
            address: EthAddress,
            wallet: EthAddress?
        )
        case assetQuoteNotFound(symbol: String)
        case invalidSwapQuoteSellAmountIsZero
        case nonceSecretNotFound(network: Network?, account: EthAddress?)
        case unknownAtlasNetwork(network: Network)
        case rewardProofNotFound(rewardType: String, network: Network, symbol: String)
        case notWrappable(symbol: String, network: Network, address: EthAddress, noScript: Bool)
        case notUnwrappable(symbol: String, network: Network, address: EthAddress, noScript: Bool)
        case swapAndSupplyMustHaveSameSender
        case swapBuyTokenMustMatchSupplyAsset(swapBuyToken: String, supplyAsset: String)
        case compounderSenderMismatch
        case compounderTokenMismatch(expected: String, actual: String)
        case unableToConstructBridge(
            srcNetwork: Network,
            srcSymbol: String,
            destNetwork: Network,
            destSymbol: String,
            bridgeAmount: Amount
        )
        case unknownAsset(symbol: String?, network: Network?, address: EthAddress?)
        case unpricedAsset(symbol: String)
        case insufficientBalance(symbol: String, required: Number, available: Number)
        case insufficientEarnMarketBalance(
            network: Network,
            market: EthAddress,
            symbol: String,
            required: Amount,
            available: Amount
        )
        case repayAmountExceedsDebt(
            network: Network,
            repayAsset: String,
            repayAmount: Amount,
            existingDebt: Amount
        )
        case morphoMarketNotFound(marketId: Hex, network: Network)
        case aaveMarketNotFound(pool: EthAddress, network: Network)
        case cometMarketNotFound(comet: EthAddress, network: Network)
        case noCollateralInBorrowMarket(network: Network)
        case noClaimableRewardsFound(symbol: String)
        case invalidNode
        case routeNotFound(symbol: String, routeType: String)
        case impossibleToConstructQuotePay(symbol: String)
        case noQuarkOperationActions
        case unknownError

        enum CodingKeys: String, CodingKey {
            case type
            case errorMessage = "error_message"
            case symbol
            case network
            case address
            case balanceNeeded = "balance_needed"
            case balanceAvailable = "balance_available"
            case wallet
            case bridgeFees = "bridge_fees"
            case totalQuotePayAmount = "total_quote_pay_amount"
            case srcNetwork = "src_network"
            case srcSymbol = "src_symbol"
            case destNetwork = "dest_network"
            case destSymbol = "dest_symbol"
            case bridgeAmount = "bridge_amount"
            case maxAmount = "max_amount"
            case noScript = "no_script"
            case marketId = "market_id"
            case market
            case aavePool
            case comet
            case swapBuyToken = "swap_buy_token"
            case supplyAsset = "supply_asset"
            case expected
            case actual
            case distributorType = "distributor_type"
            case routeType = "route_type"
            case rewardType = "reward_type"
            case repayAmount = "repay_amount"
            case existingDebt = "existing_debt"
            case repayAsset = "repay_asset"
            case required
            case available
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
                case "error":
                    let errorMessage = try container.decode(String.self, forKey: .errorMessage)
                    self = .error(errorMessage)
                case "assetBalanceNotFound":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    let network = try container.decode(Network.self, forKey: .network)
                    let address = try container.decode(EthAddress.self, forKey: .address)
                    let wallet = try container.decode(EthAddress.self, forKey: .wallet)
                    self = .assetBalanceNotFound(
                        symbol: symbol,
                        network: network,
                        address: address,
                        wallet: wallet
                    )
                case "nonceSecretNotFound":
                    let network = try container.decode(Network.self, forKey: .network)
                    let account = try container.decode(EthAddress.self, forKey: .address)
                    self = .nonceSecretNotFound(network: network, account: account)
                case "unknownAtlasNetwork":
                    let network = try container.decode(Network.self, forKey: .network)
                    self = .unknownAtlasNetwork(network: network)
                case "rewardProofNotFound":
                    let rewardType = try container.decode(String.self, forKey: .rewardType)
                    let network = try container.decode(Network.self, forKey: .network)
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    self = .rewardProofNotFound(
                        rewardType: rewardType,
                        network: network,
                        symbol: symbol
                    )
                case "notWrappable":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    let network = try container.decode(Network.self, forKey: .network)
                    let address = try container.decode(EthAddress.self, forKey: .address)
                    let noScript = try container.decode(Bool.self, forKey: .noScript)
                    self = .notWrappable(
                        symbol: symbol,
                        network: network,
                        address: address,
                        noScript: noScript
                    )
                case "notUnwrappable":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    let network = try container.decode(Network.self, forKey: .network)
                    let address = try container.decode(EthAddress.self, forKey: .address)
                    let noScript = try container.decode(Bool.self, forKey: .noScript)
                    self = .notUnwrappable(
                        symbol: symbol,
                        network: network,
                        address: address,
                        noScript: noScript
                    )
                case "unknownAsset":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    let network = try container.decode(Network.self, forKey: .network)
                    let address = try container.decode(EthAddress.self, forKey: .address)
                    self = .unknownAsset(symbol: symbol, network: network, address: address)
                case "morphoMarketNotFound":
                    let marketId = try container.decode(Hex.self, forKey: .marketId)
                    let network = try container.decode(Network.self, forKey: .network)
                    self = .morphoMarketNotFound(marketId: marketId, network: network)
                case "aaveMarketNotFound":
                    let pool = try container.decode(EthAddress.self, forKey: .aavePool)
                    let network = try container.decode(Network.self, forKey: .network)
                    self = .aaveMarketNotFound(pool: pool, network: network)
                case "cometMarketNotFound":
                    let comet = try container.decode(EthAddress.self, forKey: .comet)
                    let network = try container.decode(Network.self, forKey: .network)
                    self = .cometMarketNotFound(comet: comet, network: network)
                case "noCollateralInBorrowMarket":
                    let network = try container.decode(Network.self, forKey: .network)
                    self = .noCollateralInBorrowMarket(network: network)
                case "unpricedAsset":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    self = .unpricedAsset(symbol: symbol)
                case "noClaimableRewardsFound":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    self = .noClaimableRewardsFound(symbol: symbol)
                case "invalidNode":
                    self = .invalidNode
                case "unableToConstructBridge":
                    let srcNetwork = try container.decode(Network.self, forKey: .srcNetwork)
                    let srcSymbol = try container.decode(String.self, forKey: .srcSymbol)
                    let destNetwork = try container.decode(Network.self, forKey: .destNetwork)
                    let destSymbol = try container.decode(String.self, forKey: .destSymbol)
                    let bridgeAmount = try container.decode(Amount.self, forKey: .bridgeAmount)
                    self = .unableToConstructBridge(
                        srcNetwork: srcNetwork,
                        srcSymbol: srcSymbol,
                        destNetwork: destNetwork,
                        destSymbol: destSymbol,
                        bridgeAmount: bridgeAmount
                    )
                case "insufficientEarnMarketBalance":
                    let network = try container.decode(Network.self, forKey: .network)
                    let market = try container.decode(EthAddress.self, forKey: .market)
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    let required = try container.decode(Amount.self, forKey: .balanceNeeded)
                    let available = try container.decode(Amount.self, forKey: .balanceAvailable)
                    self = .insufficientEarnMarketBalance(
                        network: network,
                        market: market,
                        symbol: symbol,
                        required: required,
                        available: available
                    )
                case "repayAmountExceedsDebt":
                    let network = try container.decode(Network.self, forKey: .network)
                    let repayAsset = try container.decode(String.self, forKey: .repayAsset)
                    let repayAmount = try container.decode(Amount.self, forKey: .repayAmount)
                    let existingDebt = try container.decode(Amount.self, forKey: .existingDebt)
                    self = .repayAmountExceedsDebt(
                        network: network,
                        repayAsset: repayAsset,
                        repayAmount: repayAmount,
                        existingDebt: existingDebt
                    )
                case "routeNotFound":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    let routeType = try container.decode(String.self, forKey: .routeType)
                    self = .routeNotFound(symbol: symbol, routeType: routeType)
                case "impossibleToConstructQuotePay":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    self = .impossibleToConstructQuotePay(symbol: symbol)
                case "noQuarkOperationActions":
                    self = .noQuarkOperationActions
                case "unknownError":
                    self = .unknownError
                case "insufficientBalance":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    let required = try container.decode(Number.self, forKey: .required)
                    let available = try container.decode(Number.self, forKey: .available)
                    self = .insufficientBalance(symbol: symbol, required: required, available: available)
                case "compounderSenderMismatch":
                    self = .compounderSenderMismatch
                case "compounderTokenMismatch":
                    let expected = try container.decode(String.self, forKey: .expected)
                    let actual = try container.decode(String.self, forKey: .actual)
                    self = .compounderTokenMismatch(expected: expected, actual: actual)
                case "assetQuoteNotFound":
                    let symbol = try container.decode(String.self, forKey: .symbol)
                    self = .assetQuoteNotFound(symbol: symbol)
                case "invalidSwapQuoteSellAmountIsZero":
                    self = .invalidSwapQuoteSellAmountIsZero
                case "swapAndSupplyMustHaveSameSender":
                    self = .swapAndSupplyMustHaveSameSender
                case "swapBuyTokenMustMatchSupplyAsset":
                    let swapBuyToken = try container.decode(String.self, forKey: .swapBuyToken)
                    let supplyAsset = try container.decode(String.self, forKey: .supplyAsset)
                    self = .swapBuyTokenMustMatchSupplyAsset(swapBuyToken: swapBuyToken, supplyAsset: supplyAsset)
                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .type,
                        in: container,
                        debugDescription: "Invalid type value"
                    )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
                case .error(let errorString):
                    try container.encode("error", forKey: .type)
                    try container.encode(errorString, forKey: .errorMessage)
                case .assetBalanceNotFound(let symbol, let network, let address, let wallet):
                    try container.encode("assetBalanceNotFound", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                    try container.encode(network, forKey: .network)
                    try container.encode(address, forKey: .address)
                    try container.encode(wallet, forKey: .wallet)
                case .assetQuoteNotFound(let symbol):
                    try container.encode("assetQuoteNotFound", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                case .nonceSecretNotFound(let network, let account):
                    try container.encode("nonceSecretNotFound", forKey: .type)
                    try container.encode(network, forKey: .network)
                    try container.encode(account, forKey: .address)
                case .unknownAtlasNetwork(let network):
                    try container.encode("unknownAtlasNetwork", forKey: .type)
                    try container.encode(network, forKey: .network)
                case .rewardProofNotFound(let rewardType, let network, let symbol):
                    try container.encode("rewardProofNotFound", forKey: .type)
                    try container.encode(rewardType, forKey: .rewardType)
                    try container.encode(network, forKey: .network)
                    try container.encode(symbol, forKey: .symbol)
                case .notWrappable(let symbol, let network, let address, let noScript):
                    try container.encode("notWrappable", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                    try container.encode(network, forKey: .network)
                    try container.encode(address, forKey: .address)
                    try container.encode(noScript, forKey: .noScript)
                case .notUnwrappable(let symbol, let network, let address, let noScript):
                    try container.encode("notUnwrappable", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                    try container.encode(network, forKey: .network)
                    try container.encode(address, forKey: .address)
                    try container.encode(noScript, forKey: .noScript)
                case .unknownAsset(let symbol, let network, let address):
                    try container.encode("unknownAsset", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                    try container.encode(network, forKey: .network)
                    try container.encode(address, forKey: .address)
                case .unpricedAsset(let symbol):
                    try container.encode("unpricedAsset", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                case .noClaimableRewardsFound(let symbol):
                    try container.encode("noClaimableRewardsFound", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                case .invalidNode:
                    try container.encode("invalidNode", forKey: .type)
                case .unableToConstructBridge(
                    let srcNetwork,
                    let srcSymbol,
                    let destNetwork,
                    let destSymbol,
                    let bridgeAmount
                ):
                    try container.encode("unableToConstructBridge", forKey: .type)
                    try container.encode(srcNetwork, forKey: .srcNetwork)
                    try container.encode(srcSymbol, forKey: .srcSymbol)
                    try container.encode(destNetwork, forKey: .destNetwork)
                    try container.encode(destSymbol, forKey: .destSymbol)
                    try container.encode(bridgeAmount, forKey: .bridgeAmount)
                case .insufficientEarnMarketBalance(
                    let network,
                    let market,
                    let symbol,
                    let required,
                    let available
                ):
                    try container.encode("insufficientEarnMarketBalance", forKey: .type)
                    try container.encode(network, forKey: .network)
                    try container.encode(market, forKey: .market)
                    try container.encode(symbol, forKey: .symbol)
                    try container.encode(required, forKey: .balanceNeeded)
                    try container.encode(available, forKey: .balanceAvailable)
                case .repayAmountExceedsDebt(
                    let network,
                    let repayAsset,
                    let repayAmount,
                    let existingDebt
                ):
                    try container.encode("repayAmountExceedsDebt", forKey: .type)
                    try container.encode(network, forKey: .network)
                    try container.encode(repayAsset, forKey: .repayAsset)
                    try container.encode(repayAmount, forKey: .repayAmount)
                    try container.encode(existingDebt, forKey: .existingDebt)
                case .morphoMarketNotFound(let marketId, let network):
                    try container.encode("morphoMarketNotFound", forKey: .type)
                    try container.encode(marketId, forKey: .marketId)
                    try container.encode(network, forKey: .network)
                case .aaveMarketNotFound(let pool, let network):
                    try container.encode("aaveMarketNotFound", forKey: .type)
                    try container.encode(pool, forKey: .aavePool)
                    try container.encode(network, forKey: .network)
                case .cometMarketNotFound(let comet, let network):
                    try container.encode("cometMarketNotFound", forKey: .type)
                    try container.encode(comet, forKey: .comet)
                    try container.encode(network, forKey: .network)
                case .noCollateralInBorrowMarket(let network):
                    try container.encode("noCollateralInBorrowMarket", forKey: .type)
                    try container.encode(network, forKey: .network)
                case .invalidSwapQuoteSellAmountIsZero:
                    try container.encode("invalidSwapQuoteSellAmountIsZero", forKey: .type)
                case .swapAndSupplyMustHaveSameSender:
                    try container.encode("swapAndSupplyMustHaveSameSender", forKey: .type)
                case .swapBuyTokenMustMatchSupplyAsset(let swapBuyToken, let supplyAsset):
                    try container.encode("swapBuyTokenMustMatchSupplyAsset", forKey: .type)
                    try container.encode(swapBuyToken, forKey: .swapBuyToken)
                    try container.encode(supplyAsset, forKey: .supplyAsset)
                case .routeNotFound(let symbol, let routeType):
                    try container.encode("routeNotFound", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                    try container.encode(routeType, forKey: .routeType)
                case .impossibleToConstructQuotePay(let symbol):
                    try container.encode("impossibleToConstructQuotePay", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                case .noQuarkOperationActions:
                    try container.encode("noQuarkOperationActions", forKey: .type)
                case .unknownError:
                    try container.encode("unknownError", forKey: .type)
                case .compounderSenderMismatch:
                    try container.encode("compounderSenderMismatch", forKey: .type)
                case .compounderTokenMismatch(let expected, let actual):
                    try container.encode("compounderTokenMismatch", forKey: .type)
                    try container.encode(expected, forKey: .expected)
                    try container.encode(actual, forKey: .actual)
                case .insufficientBalance(let symbol, let required, let available):
                    try container.encode("insufficientBalance", forKey: .type)
                    try container.encode(symbol, forKey: .symbol)
                    try container.encode(required, forKey: .required)
                    try container.encode(available, forKey: .available)
            }
        }
    }
}
