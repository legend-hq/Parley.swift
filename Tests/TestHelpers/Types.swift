import Atlas
import Eth
import Foundation
import Prelude
import SwiftNumber

@testable import Charter

public enum Account: Hashable, Equatable, Sendable {
    case alice
    case bob
    case carl
    case stax
    case unknownAccount(EthAddress)

    public static let knownCases: [Account] = [.alice, .bob, .carl, .stax]

    public var description: String {
        switch self {
            case .alice:
                return "Alice"
            case .bob:
                return "Bob"
            case .carl:
                return "Carl"
            case .stax:
                return "stax"
            case .unknownAccount(let address):
                return "UnknownAccount(\(address.description))"
        }
    }

    public var address: EthAddress {
        switch self {
            case .alice:
                return EthAddress("0x00000000000000000000000000000000000A11CE")
            case .bob:
                return EthAddress("0x00000000000000000000000000000000000B0B0B")
            case .carl:
                return EthAddress("0x000000000000000000000000000000000000CA51")
            case .stax:
                return EthAddress("0x7ea8d6119596016935543d90Ee8f5126285060A1")
            case .unknownAccount(let address):
                return address
        }
    }

    public static func from(address: EthAddress) -> Account {
        for knownCase in Account.knownCases {
            if address == knownCase.address {
                return knownCase
            }
        }
        return .unknownAccount(address)
    }

    public var nonceSecret: Hex {
        switch self {
            case .alice:
                return Hex(
                    stringLiteral:
                        "0x000000000000000000000000000000000000000000000000000000000000000c"
                )  // 12
            case .bob:
                return Hex(
                    stringLiteral:
                        "0x0000000000000000000000000000000000000000000000000000000000000002"
                )  // 2
            case .carl:
                return Hex(
                    stringLiteral:
                        "0x0000000000000000000000000000000000000000000000000000000000000005"
                )  // 5
            case .stax:
                return Hex(
                    stringLiteral:
                        "0x0000000000000000000000000000000000000000000000000000000000000007"
                )  // 7
            case .unknownAccount(_):
                return Hex(
                    stringLiteral:
                        "0x0000000000000000000000000000000000000000000000000000000000000001"
                )  // 1
        }
    }
}

public enum AavePool: Hashable, Equatable, Sendable {
    case baseV3
    case arbitrumV3
    case optimismV3
    case unknownPool(EthAddress)

    public enum Given {
        case supplied(Account, TokenAmount)
        case borrowed(Account, TokenAmount)
    }

    static let knownCases: [AavePool] = [.baseV3, .arbitrumV3, .optimismV3]

    public func address(network: Network) -> EthAddress {
        switch (network, self) {
            // TODO: needs to be on builderpack
            // this is base v3 address
            case (_, .unknownPool(let a)):
                return a
            case (_, .baseV3):
                return EthAddress("0xA238Dd80C259a72e81d7e4664a9801593F98d1c5")
            case (_, .arbitrumV3):
                return EthAddress("0x794a61358d6845594f94dc1db02a252b5b4814ad")
            case (_, .optimismV3):
                return EthAddress("0x794a61358d6845594f94dc1db02a252b5b4814ad")
        }
    }

    public var description: String {
        switch self {
            case .baseV3:
                return "Aave_V3_BASE_Market"
            case .arbitrumV3:
                return "Aave_V3_ARBITRUM_Market"
            case .optimismV3:
                return "Aave_V3_OPTIMISM_Market"
            case .unknownPool(let address):
                return "Aave at \(address.description)"
        }
    }

    public static func from(network: Network, address: EthAddress) -> AavePool {
        switch (network, address) {
            case (.base, "0xA238Dd80C259a72e81d7e4664a9801593F98d1c5"):
                return .baseV3
            case (.arbitrum, "0x794a61358d6845594f94dc1db02a252b5b4814ad"):
                return .arbitrumV3
            case (.optimism, "0x794a61358d6845594f94dc1db02a252b5b4814ad"):
                return .optimismV3
            case _:
                return .unknownPool(address)
        }
    }
}

public enum Comet: Hashable, Equatable, Sendable {
    case cusdcv3
    case cwethv3
    case unknownComet(EthAddress)

    public enum Given {
        case supplied(Account, TokenAmount)
        case borrowed(Account, TokenAmount)
    }

    static let knownCases: [Comet] = [.cusdcv3, .cwethv3]

    public func address(network: Network) -> EthAddress {
        switch (network, self) {
            // TODO?: add cases for some more (network, market) pairs?
            // eventually this should be migrated to use builderpack instead.
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
            case (.optimism, .cusdcv3):
                return EthAddress("0x2e44e174f7D53F0212823acC11C01A11d58c5bCB")
            case (.optimism, .cwethv3):
                return EthAddress("0xE36A30D249f7761327fd973001A32010b521b6Fd")
            case (.unichain, .cusdcv3):
                return EthAddress("0x2c7118c4c88b9841fcf839074c26ae8f035f2921")
            case (_, .cusdcv3):
                fatalError("no market .cusdcv3 for network \(network.description)")
            case (_, .cwethv3):
                fatalError("no market .cwethv3 for network \(network.description)")
            case (_, .unknownComet(let address)):
                return address
        }
    }

    public var baseAsset: Token {
        switch self {
            case .cusdcv3: return .usdc
            case .cwethv3: return .weth
            case .unknownComet: return .unknownToken("0x0000000000000000000000000000000000000000")
        }
    }

    public struct CollateralFactors: Sendable {
        public let borrowCollateralFactor: Double
        public let liquidateCollateralFactor: Double
        public let liquidationFactor: Double
    }

    public static let defaultCollateralFactors = CollateralFactors(
        borrowCollateralFactor: 0.80,
        liquidateCollateralFactor: 0.85,
        liquidationFactor: 0.90
    )

    public var description: String {
        switch self {
            case .cusdcv3:
                return "cUSDCv3"
            case .cwethv3:
                return "cWETHv3"
            case .unknownComet(let address):
                return "Comet at \(address.description)"
        }
    }

    public static func from(network: Network, address: EthAddress) -> Comet {
        switch (network, address) {
            case (.ethereum, "0xc3d688B66703497DAA19211EEdff47f25384cdc3"):
                return .cusdcv3
            case (.ethereum, "0xA17581A9E3356d9A858b789D68B4d866e593aE94"):
                return .cwethv3
            case (.base, "0xb125E6687d4313864e53df431d5425969c15Eb2F"):
                return .cusdcv3
            case (.base, "0x46e6b214b524310239732D51387075E0e70970bf"):
                return .cwethv3
            case (.arbitrum, "0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf"):
                return .cusdcv3
            case (.optimism, "0x2e44e174f7D53F0212823acC11C01A11d58c5bCB"):
                return .cusdcv3
            case (.optimism, "0xE36A30D249f7761327fd973001A32010b521b6Fd"):
                return .cwethv3
            case (.unichain, "0x2c7118c4c88b9841fcf839074c26ae8f035f2921"):
                return .cusdcv3
            case _:
                return .unknownComet(address)
        }
    }
}

public enum CometReward: Hashable, Equatable, Sendable {
    case wethReward
    case usdcReward
    case unknownCometReward(EthAddress)

    public var rewardToken: Token {
        switch self {
            case .usdcReward:
                return .usdc
            case .wethReward:
                return .weth
            case .unknownCometReward(let address):
                return .unknownToken(address)
        }
    }

    // TODO: These are just Comet addresses for now, but should be fine
    public func address(network: Network) -> EthAddress {
        switch (network, self) {
            case (.ethereum, .usdcReward):
                return EthAddress("0x1B0e765F6224C21223AeA2af16c1C46E38885a40")
            case (.ethereum, .wethReward):
                return EthAddress("0x1B0e765F6224C21223AeA2af16c1C46E38885a40")
            case (.base, .usdcReward):
                return EthAddress("0x123964802e6ABabBE1Bc9547D72Ef1B69B00A6b1")
            case (.base, .wethReward):
                return EthAddress("0x46e6b214b524310239732D51387075E0e70970bf")
            case (.arbitrum, .usdcReward):
                return EthAddress("0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf")
            case (.arbitrum, .wethReward):
                return EthAddress("0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf")
            case (.optimism, .usdcReward):
                return EthAddress("0x2e44e174f7D53F0212823acC11C01A11d58c5bCB")
            case (.optimism, .wethReward):
                return EthAddress("0xE36A30D249f7761327fd973001A32010b521b6Fd")
            case (_, .usdcReward):
                fatalError("no CometReward for .usdc for network \(network.description)")
            case (_, .wethReward):
                fatalError("no CometReward for .weth for network \(network.description)")
            case (_, .unknownCometReward(let address)):
                return address
        }
    }

    public var description: String {
        switch self {
            case .usdcReward:
                return "USDCCometReward"
            case .wethReward:
                return "WETHCometReward"
            case .unknownCometReward(let address):
                return "CometReward at \(address.description)"
        }
    }

    public static func from(network: Network, address: EthAddress, comet: Comet) -> CometReward {
        switch (network, address, comet) {
            case (.ethereum, "0x1B0e765F6224C21223AeA2af16c1C46E38885a40", .cusdcv3):
                return .usdcReward
            case (.ethereum, "0x1B0e765F6224C21223AeA2af16c1C46E38885a40", .cwethv3):
                return .wethReward
            case (.base, "0x123964802e6ABabBE1Bc9547D72Ef1B69B00A6b1", .cusdcv3):
                return .usdcReward
            case (.base, "0x46e6b214b524310239732D51387075E0e70970bf", .cwethv3):
                return .wethReward
            case (.arbitrum, "0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf", .cusdcv3):
                return .usdcReward
            case (.optimism, "0x2e44e174f7D53F0212823acC11C01A11d58c5bCB", .cusdcv3):
                return .usdcReward
            case (.optimism, "0xE36A30D249f7761327fd973001A32010b521b6Fd", .cwethv3):
                return .wethReward
            case _:
                return .unknownCometReward(address)
        }
    }
}

public struct Morpho: Hashable, Equatable, Sendable {
    public let collateralToken: Token
    public let borrowToken: Token

    public init(collateralToken ct: Token, borrowToken bt: Token) {
        collateralToken = ct
        borrowToken = bt
    }

    public static func == (lhs: Morpho, rhs: Morpho) -> Bool {
        return lhs.collateralToken == rhs.collateralToken && lhs.borrowToken == rhs.borrowToken
    }

    public static func morpho(_ collateralToken: Token, _ borrowToken: Token) -> Morpho {
        return Morpho(
            collateralToken: collateralToken,
            borrowToken: borrowToken
        )
    }

    public var description: String {
        return "Morpho(\(collateralToken.symbol)/\(borrowToken.symbol))"
    }

    public func marketId(_ network: Network) -> Hex {
        switch (network, borrowToken, collateralToken) {
            case (.ethereum, .usdc, .cbbtc):
                return Hex("0x64d65c9a2d91c36d56fbc42d69e979335320169b3df63bf92789e2c8883fcc64")
            case (.base, .usdc, .cbbtc):
                return Hex("0x9103c3b4e834476c9a62ea009ba2c884ee42e94e6e314a26f04d312434191836")
            case (.base, .usdc, .cbeth):
                return Hex("0x1c21c59df9db44bf6f645d854ee710a8ca17b479451447e9f56758aee10a2fad")
            case (.base, .usdc, .weth):
                return Hex("0x8793cf302b8ffd655ab97bd1c695dbd967807e8367a65cb2f4edaf1380ba1bda")
            case (.worldChain, .weth, .wbtc):
                return Hex("0x19c682c3a37025075074cefea866fbe54656abc0fb6a7355b62a53f45b959abf")
            default:
                // Allows for a generic key that will cause a revert for .unkownMorphoMarket
                return Hex("0x0000000000000000000000000000000000000000000000000000000000000000")
        }
    }

    public static func address(_ network: Network) -> EthAddress {
        switch network {
            case .ethereum, .base, .baseSepolia:
                return EthAddress("0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb")
            case .sepolia:
                return EthAddress("0xd011EE229E7459ba1ddd22631eF7bF528d424A14")
            default:
                fatalError("Morpho not available on network: \(network.description)")
        }
    }
}

public enum MorphoVault: Hashable, Equatable, Sendable {
    case usdc
    case usdt
    case weth
    case wbtc
    case unknownVault(EthAddress)

    static let knownCases: [MorphoVault] = [.usdc, .usdt, .weth, .wbtc]

    public func address(network: Network) -> EthAddress {
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
            case (.unichain, .usdc):
                return EthAddress("0x38f4f3b6533de0023b9dcd04b02f93d36ad1f9f9")
            case (.worldChain, .weth):
                return EthAddress("0x0Db7E405278c2674F462aC9D9eb8b8346D1c1571")
            case (.worldChain, .usdc):
                return EthAddress("0xb1e80387ebe53ff75a89736097d34dc8d9e9045b")
            case (_, .unknownVault(let address)):
                return address
            default:
                fatalError("no vault for \(description) on network \(network.description)")
        }
    }

    public func asset(network: Network) -> Token {
        switch self {
            case .usdc:
                return Token.usdc
            case .usdt:
                return Token.usdt
            case .weth:
                return Token.weth
            case .wbtc:
                return Token.wbtc
            default:
                fatalError("no asset for \(description) on network \(network.description)")
        }
    }

    public var description: String {
        switch self {
            case .usdc:
                return "USDC Vault"
            case .usdt:
                return "USDT Vault"
            case .weth:
                return "WETH Vault"
            case .wbtc:
                return "WBTC Vault"
            case .unknownVault(let address):
                return "Vault at \(address.description)"
        }
    }

    public static func from(network: Network, address: EthAddress) -> MorphoVault {
        switch (network, address) {
            case (.ethereum, "0x8eB67A509616cd6A7c1B3c8C21D48FF57df3d458"):
                return .usdc
            case (.ethereum, "0x8CB3649114051cA5119141a34C200D65dc0Faa73"):
                return .usdt
            case (.ethereum, "0x4881Ef0BF6d2365D3dd6499ccd7532bcdBCE0658"):
                return .weth
            case (.ethereum, "0x443df5eEE3196e9b2Dd77CaBd3eA76C3dee8f9b2"):
                return .wbtc
            case (.base, "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"):
                return .usdc
            case (.base, "0xa0E430870c4604CcfC7B38Ca7845B1FF653D0ff1"):
                return .weth
            case (.unichain, "0x38f4f3b6533de0023b9dcd04b02f93d36ad1f9f9"):
                return .usdc
            case (.worldChain, "0x0Db7E405278c2674F462aC9D9eb8b8346D1c1571"):
                return .weth
            case (.worldChain, "0xb1e80387ebe53ff75a89736097d34dc8d9e9045b"):
                return .usdc
            case _:
                return .unknownVault(address)
        }
    }
}

public enum MorphoDistributor: Hashable, Equatable, Sendable {
    case distributor
    case merklDistributor
    case unknownDistributor(EthAddress)

    // Network-specific Morpho distributor addresses (from Atlas)
    public static let ETHEREUM_DISTRIBUTOR = EthAddress(
        "0x2efd4625d0c149ebadf118ec5446c6de24d916a4"
    )
    public static let BASE_DISTRIBUTOR = EthAddress("0x5400dbb270c956e8985184335a1c62aca6ce1333")
    public static let MERKL_DISTRIBUTOR_ADDRESS = EthAddress(
        "0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae"
    )

    public var description: String {
        switch self {
            case .distributor:
                return "Morpho Distributor"
            case .merklDistributor:
                return "Merkl Distributor"
            case .unknownDistributor(let address):
                return "Morpho Distributor at \(address.description)"
        }
    }

    public func address(network: Network) -> EthAddress {
        switch self {
            case .distributor:
                return MorphoDistributor.address(network: network)
            case .merklDistributor:
                return MorphoDistributor.merklDistributorAddress(for: network)
            case .unknownDistributor(let address):
                return address
        }
    }

    static func merklDistributorAddress(for network: Network) -> EthAddress {
        if let atlasNetwork = Atlas.getEvmNetwork(network: network) {
            return atlasNetwork.merklDistributor
        }
        return MERKL_DISTRIBUTOR_ADDRESS
    }

    static func address(network: Network) -> EthAddress {
        // Try Atlas first
        if let atlasNetwork = Atlas.getEvmNetwork(network: network),
            let firstDistributor = atlasNetwork.morphoRewardDistributors.first?.distributor
        {
            return firstDistributor
        }

        // Fallback to hardcoded values
        switch network {
            case .ethereum, .sepolia:
                return ETHEREUM_DISTRIBUTOR
            case .base, .baseSepolia:
                return BASE_DISTRIBUTOR
            default:
                fatalError("Morpho distributor not found for network: \(network.description)")
        }
    }

    public static func from(network: Network, address: EthAddress) -> MorphoDistributor {
        // Check Merkl distributor
        if let atlasNetwork = Atlas.getEvmNetwork(network: network),
            address == atlasNetwork.merklDistributor
        {
            return .merklDistributor
        } else if address == MERKL_DISTRIBUTOR_ADDRESS {
            return .merklDistributor
        }

        // Check Morpho distributors
        if let atlasNetwork = Atlas.getEvmNetwork(network: network),
            atlasNetwork.morphoRewardDistributors.contains(where: { $0.distributor == address })
        {
            return .distributor
        } else if address == self.address(network: network) {
            return .distributor
        }

        return .unknownDistributor(address)
    }
}

public enum MorphoClaimProof: Hashable, Equatable, Sendable {
    case validProof1
    case validProof2
    case validProof3
    case validProof4
    case unknownProof([Hex])

    public var description: String {
        switch self {
            case .validProof1:
                return "Proof 1"
            case .validProof2:
                return "Proof 2"
            case .validProof3:
                return "Proof 3"
            case .validProof4:
                return "Proof 4"
            case .unknownProof(let proof):
                return "Unknown Proof \(proof)"
        }
    }

    public var data: [Hex] {
        switch self {
            case .validProof1:
                return [Hex("0x0000000000000000000000000000000000000000000000000000000000000001")]
            case .validProof2:
                return [Hex("0x0000000000000000000000000000000000000000000000000000000000000002")]
            case .validProof3:
                return [Hex("0x0000000000000000000000000000000000000000000000000000000000000003")]
            case .validProof4:
                return [Hex("0x0000000000000000000000000000000000000000000000000000000000000004")]
            case .unknownProof(let proof):
                return proof
        }
    }

    public static func from(proof: [Hex]) -> MorphoClaimProof {
        switch proof {
            case [Hex("0x0000000000000000000000000000000000000000000000000000000000000001")]:
                return .validProof1
            case [Hex("0x0000000000000000000000000000000000000000000000000000000000000002")]:
                return .validProof2
            case [Hex("0x0000000000000000000000000000000000000000000000000000000000000003")]:
                return .validProof3
            case [Hex("0x0000000000000000000000000000000000000000000000000000000000000004")]:
                return .validProof4
            case _:
                return .unknownProof(proof)
        }
    }
}

public struct TokenAmount: Equatable, Hashable, Sendable {
    public let amount: Number
    public let token: Token

    public init(fromAmount amount: Double, ofToken token: Token) {
        self.amount = Number(amount * pow(10, Double(token.decimals)))
        self.token = token
    }

    public init(fromWei amount: Number, ofToken token: Token) {
        self.amount = amount
        self.token = token
    }

    public static func == (lhs: TokenAmount, rhs: TokenAmount) -> Bool {
        return lhs.amount == rhs.amount && lhs.token == rhs.token
    }

    public static func amt(_ amount: Double, _ token: Token) -> TokenAmount {
        return TokenAmount(
            fromAmount: amount,
            ofToken: token
        )
    }

    public static func max(_ token: Token) -> TokenAmount {
        return TokenAmount(
            fromWei: Number.max,
            ofToken: token
        )
    }

    public var toAmount: Amount {
        Amount(amount, decimals: token.decimals)
    }
}

extension Number {
    public static let max = Number.MAX_UINT_256
}

public enum Token: Hashable, Equatable, Sendable {
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
    case hype
    case whype
    case pol
    case wpol
    case unknownToken(EthAddress)

    public static let knownCases: [Token] = [
        .usdc, .eth, .weth, .link, .usdt, .wbtc, .degen, .cbeth, .cbbtc, .comp, .hype, .whype,
        .pol, .wpol,
    ]

    public static let networkTokenAddress: [Network: [Token: EthAddress]] = [
        .ethereum: [
            .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
            .weth: EthAddress("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"),
            .usdc: EthAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
            .link: EthAddress("0x514910771af9ca656af840dff83e8264ecf986ca"),
            .usdt: EthAddress("0xdac17f958d2ee523a2206206994597c13d831ec7"),
            .wbtc: EthAddress("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"),
            .cbbtc: EthAddress("0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"),
            .comp: EthAddress("0xc00e94cb662c3520282e6f5717214004a7f26888"),
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
        ],
        .arbitrum: [
            .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
            .weth: EthAddress("0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"),
            .usdc: EthAddress("0xaf88d065e77c8cC2239327C5EDb3A432268e5831"),
            .link: EthAddress("0xf97f4df75117a78c1A5a0DBb814Af92458539FB4"),
            .usdt: EthAddress("0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"),
            .wbtc: EthAddress("0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"),
        ],
        .optimism: [
            .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
            .weth: EthAddress("0x4200000000000000000000000000000000000006"),
            .usdc: EthAddress("0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"),
            .usdt: EthAddress("0x94b008aA00579c1307B0EF2c499aD98a8ce58e58"),
            .wbtc: EthAddress("0x68f180fcCe6836688e9084f035309E29Bf0A2095"),
        ],
        .worldChain: [
            .eth: EthAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"),
            .weth: EthAddress("0x4200000000000000000000000000000000000006"),
            .wbtc: EthAddress("0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3"),
            .usdc: EthAddress("0x79A02482A880bCE3F13e09Da970dC34db4CD24d1"),
        ],
        .unichain: [
            .usdc: EthAddress("0x078d782b760474a361dda0af3839290b0ef57ad6"),
        ],
        .hyperEVM: [
            .usdc: EthAddress("0xb88339cb7199b77e23db6e890353e22632ba630f"),
            .hype: EthAddress("0x000000000000000000000000000000000000b49e"),
            .whype: EthAddress("0x5555555555555555555555555555555555555555"),
        ],
        .polygon: [
            .pol: EthAddress("0x0000000000000000000000000000000000001010"),
            .wpol: EthAddress("0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270"),
            .weth: EthAddress("0x7ceb23fd6bc0add59e62ac25578270cff1b9f619"),
            .usdc: EthAddress("0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"),
        ],
        .unknown(7777): [
            .usdc: EthAddress("0x7777000000000000000000000000000000000001"),
            .weth: EthAddress("0x7777000000000000000000000000000000000002"),
        ],
    ]

    public static var networkAddressToken: [Network: [EthAddress: Token]] {
        networkTokenAddress.mapValues { tokenMap in
            Dictionary(uniqueKeysWithValues: tokenMap.map { ($0.value, $0.key) })
        }
    }

    public static func from(network: Network, address: EthAddress) -> Token {
        if let token = Token.networkAddressToken[network]?[address] {
            return token
        } else {
            return .unknownToken(address)
        }
    }

    public static func getTokenAmount(amount: Number, network: Network, address: EthAddress)
        -> TokenAmount
    {
        let token = Token.from(network: network, address: address)
        return TokenAmount(fromWei: amount, ofToken: token)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    public var symbol: String {
        switch self {
            case .usdc:
                return "USDC"
            case .usdt:
                return "USDT"
            case .eth:
                return "ETH"
            case .weth:
                return "WETH"
            case .link:
                return "LINK"
            case .wbtc:
                return "WBTC"
            case .degen:
                return "DEGEN"
            case .cbeth:
                return "cbETH"
            case .cbbtc:
                return "cbBTC"
            case .comp:
                return "COMP"
            case .hype:
                return "HYPE"
            case .whype:
                return "WHYPE"
            case .pol:
                return "POL"
            case .wpol:
                return "WPOL"
            case .unknownToken(let address):
                return "UnknownToken(\(address.description))"
        }
    }

    public var decimals: Int {
        switch self {
            case .usdc, .usdt:
                return 6
            case .wbtc, .cbbtc:
                return 8
            case .eth, .weth, .link, .degen, .cbeth, .comp, .hype, .whype, .pol, .wpol:
                return 18
            case .unknownToken:
                return 0
        }
    }

    public var defaultUsdPrice: Double {
        switch self {
            case .usdc, .usdt:
                return 1.0
            case .eth, .weth, .cbeth:
                return 4000.0
            case .link:
                return 25.0
            case .wbtc, .cbbtc:
                return 100_000.0
            case .degen:
                return 2.0
            case .comp:
                return 40.0
            case .hype, .whype:
                return 25.0
            case .pol, .wpol:
                return 0.5
            case .unknownToken:
                return 0
        }
    }

    public var description: String {
        return symbol
    }

    public func address(network: Network) -> EthAddress? {
        Token.networkTokenAddress[network]?[self]
    }

    public func amount(_ amount: Double) -> Amount {
        Amount(Number(amount * pow(10, Double(decimals))), decimals: decimals)
    }
}

public enum QuotePay: Hashable, Equatable, Sendable {
    case basic
    case custom(quoteId: Hex, prices: [Token: Double], fees: [Network: Double])

    public static let knownCases: [QuotePay] = [.basic]

    public var params: (quoteId: Hex, prices: [Token: Double], fees: [Network: Double]) {
        switch self {
            case .custom(let quoteId, let prices, let fees):
                return (quoteId, prices, fees)
            case .basic:
                return (
                    Hex("0x00000000000000000000000000000000000000000000000000000000000000CC"),
                    Dictionary(
                        uniqueKeysWithValues: Token.knownCases.map { token in
                            (token, token.defaultUsdPrice)
                        }
                    ),
                    [
                        .unichain: 0.02,
                        .ethereum: 0.10,
                        .base: 0.02,
                        .arbitrum: 0.04,
                        .optimism: 0.06,
                        .worldChain: 0.10,
                        .hyperEVM: 0.04,
                        .polygon: 0.0008,
                    ]
                )
        }
    }

    public var prices: [Token: Double] {
        params.prices
    }

    public var fees: [Network: Double] {
        params.fees
    }

    public var quoteId: Hex {
        params.quoteId
    }

    public static func findQuote(quoteId: Hex, prices: [Token: Double], fees: [Network: Double])
        -> QuotePay
    {
        for knownCase in QuotePay.knownCases {
            if knownCase.params.quoteId == quoteId {
                return knownCase
            }
        }
        return .custom(quoteId: quoteId, prices: prices, fees: fees)
    }
}

public enum Given: Hashable, Equatable, Sendable {
    case tokenBalance(Account, TokenAmount, Network)
    case quote(QuotePay)
    case prices([Token: Double])
    case cometSupply(Account, TokenAmount, Comet, Network)
    case cometBorrow(Account, TokenAmount, Comet, Network)
    case cometCollateral(Account, TokenAmount, Comet, Network)  // New case for collateral balances
    case cometBorrowCapacity(Account, TokenAmount, Comet, Network)  // Remaining borrow capacity
    case cometReward(Account, TokenAmount, Comet, CometReward, Network)
    case aaveSupply(Account, TokenAmount, AavePool, Network)
    case aaveBorrow(Account, TokenAmount, AavePool, Network)
    case morphoVaultSupply(Account, TokenAmount, MorphoVault, Network)
    case morphoBorrow(Account, Morpho, TokenAmount, TokenAmount, Network)
    case morphoCollateral(Account, TokenAmount, Morpho, Network)  // New case for collateral balances
    case morphoBorrowCapacity(Account, TokenAmount, Morpho, Network)  // Remaining borrow capacity
    case morphoReward(Account, TokenAmount, MorphoDistributor, MorphoClaimProof, Network)
    case acrossQuote(TokenAmount, Double)
    case acrossQuoteWithMin(TokenAmount, Double, TokenAmount)
    case acrossQuoteWithMax(TokenAmount, Double, TokenAmount)
    case cctpV2Quote(TokenAmount, Double)  // Fixed cost, rate
    case cctpV2QuoteWithMin(TokenAmount, Double, TokenAmount)  // Fixed cost, rate, min amount
    case swapHint(Network, Token, Token, String, Number, TokenAmount, Double)  // network, sellToken, buyToken, venue, tierAmount, capacity, rate

    /// Creates a swap hint. Rate is in human-readable terms (e.g., 0.0003 means 1 USDC = 0.0003 WETH).
    public static func swapHint(
        on network: Network,
        sell sellToken: Token,
        buy buyToken: Token,
        venue: String = "0x",
        capacity: TokenAmount,
        rate: Double
    ) -> Given {
        // Convert human-readable rate to wei-based rate for Percentage.
        // Rate represents buyWei/sellWei, so we adjust for decimal difference.
        // Percentage(fromDouble:) will multiply by 10^18 to get the underlying value.
        let decimalAdjustment = pow(10, Double(buyToken.decimals - sellToken.decimals))
        return .swapHint(
            network,
            sellToken,
            buyToken,
            venue,
            capacity.toAmount.underlying,
            capacity,
            rate * decimalAdjustment
        )
    }
}
