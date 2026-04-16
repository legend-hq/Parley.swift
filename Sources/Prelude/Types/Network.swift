import Eth
import Foundation
import SwiftNumber

extension Network {
    public var imageName: String {
        switch self {
            case .arbitrum, .arbitrumSepolia:
                "Arbitrum"
            case .base, .baseSepolia:
                "Base"
            case .ethereum, .sepolia:
                "Ethereum"
            case .hyperEVM:
                "HyperEVM"
            case .optimism:
                "Optimism"
            case .polygon:
                "Polygon"
            case .solana:
                "Solana"
            case .sonic:
                "Sonic"
            case .tempo:
                "Tempo"
            case .worldChain:
                "WorldChain"
            case .unichain:
                "Unichain"
            default:
                "UnknownNetwork"
        }
    }

    public var swapNetworkName: String? {
        switch self {
            case .arbitrum:
                "arbitrum"
            case .avalanche:
                "avalanche"
            case .base:
                "base"
            case .ethereum:
                "mainnet"
            case .optimism:
                "optimism"
            case .polygon:
                "polygon"
            case .sepolia:
                "sepolia"
            case .worldChain:
                "world_chain"
            case .unichain:
                "unichain"
            case .hyperEVM:
                "hyper_evm"
            default:
                nil
        }
    }

    /// A [CAIP-2](https://chainagnostic.org/CAIPs/caip-2) network identifier.
    public var caip2Identifier: String {
        switch self {
            case .solana:
                SolanaConstants.CAIP2_IDENTIFIER
            default:
                "eip155:\(chainId.description)"
        }
    }

    public func explorerUrl(address ethereumAddress: EthAddress) -> URL? {
        guard let baseUrl = explorerUrl else {
            return nil
        }

        return baseUrl.appendingPathComponent("/address/\(ethereumAddress.description)")
    }

    public func explorerUrl(tx: Hex) -> URL? {
        guard let baseUrl = explorerUrl else {
            return nil
        }

        return baseUrl.appendingPathComponent("/tx/\(tx.hex)")
    }

    public var sortPriority: Int {
        switch self {
            case .ethereum:
                return 0
            case .base:
                return 1
            case .arbitrum:
                return 2
            case .optimism:
                return 3
            case .worldChain:
                return 4
            default:
                return .max
        }
    }
}

extension Array where Element == Network {
    /// Return a descriptor for a list of networks. For 1 network, just the
    /// name of the network. For n networks, "n Networks"
    public func formatted() -> String {
        switch count {
            case 1:
                self[0].description
            default:
                "\(count) Networks"
        }
    }

    /// Sorts the networks by the priority expected in Legend
    public func sortedByPriority() -> [Network] {
        sorted(by: \.sortPriority, using: <)
    }
}
