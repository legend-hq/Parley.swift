import Atlas
import Eth
import Foundation

public struct NonceSecret: Codable, Equatable, Sendable {
    public let chainId: UInt
    public let account: EthAddress
    public let nonceSecret: Hex

    enum CodingKeys: String, CodingKey {
        case chainId = "chain_id"
        case account
        case nonceSecret = "nonce_secret"
    }

    public init(chainId: UInt, account: EthAddress, nonceSecret: Hex) {
        self.chainId = chainId
        self.account = account
        self.nonceSecret = nonceSecret
    }

    public var network: Network {
        Network.fromChainId(chainId)
    }

    public static func generateNonceSecrets(accounts: [EthAddress]) -> [NonceSecret] {
        var nonceSecrets: [NonceSecret] = []

        for account in accounts {
            for network in Atlas.allNetworks {
                nonceSecrets.append(
                    NonceSecret(
                        chainId: network.chainId,
                        account: account,
                        nonceSecret: Hex(generateSecureRandomData(bytes: 32))
                    )
                )
            }
        }

        return nonceSecrets
    }
}
