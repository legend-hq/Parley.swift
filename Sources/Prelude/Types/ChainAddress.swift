import Eth
import Foundation

public struct ChainAddress: Equatable, Hashable, Sendable {
    public let address: EthAddress
    public let chain: Network

    public init(address: EthAddress, chain: Network) {
        self.address = address
        self.chain = chain
    }

    public var onChain: String {
        "on \(chain.description)"
    }
}
