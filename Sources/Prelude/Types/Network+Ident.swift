import Eth
import Foundation
import SwiftNumber

extension Network {
    /// Returns a string identifier for the network (e.g., "base", "ethereum", "unknown_12345")
    public var networkIdent: String {
        switch self {
            case .alephZero:
                return "aleph_zero"
            case .arbitrum:
                return "arbitrum"
            case .arbitrumSepolia:
                return "arbitrum_sepolia"
            case .avalanche:
                return "avalanche"
            case .base:
                return "base"
            case .baseSepolia:
                return "base_sepolia"
            case .blast:
                return "blast"
            case .bnbSmartChain:
                return "bnb_smart_chain"
            case .celo:
                return "celo"
            case .ethereum:
                return "ethereum"
            case .gnosis:
                return "gnosis"
            case .hyperEVM:
                return "hyper_evm"
            case .ink:
                return "ink"
            case .lens:
                return "lens"
            case .linea:
                return "linea"
            case .lineaSepolia:
                return "linea_sepolia"
            case .lisk:
                return "lisk"
            case .mantle:
                return "mantle"
            case .mode:
                return "mode"
            case .optimism:
                return "optimism"
            case .plume:
                return "plume"
            case .polygon:
                return "polygon"
            case .redstone:
                return "redstone"
            case .scroll:
                return "scroll"
            case .scrollSepolia:
                return "scroll_sepolia"
            case .sepolia:
                return "sepolia"
            case .soneium:
                return "soneium"
            case .sonic:
                return "sonic"
            case .unichain:
                return "unichain"
            case .worldChain:
                return "world_chain"
            case .zkSync:
                return "zksync"
            case .zora:
                return "zora"
            case .unknown(let chainId):
                return "unknown_\(chainId)"
        }
    }

    /// Creates a Network from a string identifier
    public init(fromIdent ident: String) throws {
        switch ident {
            case "aleph_zero":
                self = .alephZero
            case "arbitrum":
                self = .arbitrum
            case "arbitrum_sepolia":
                self = .arbitrumSepolia
            case "avalanche":
                self = .avalanche
            case "base":
                self = .base
            case "base_sepolia":
                self = .baseSepolia
            case "blast":
                self = .blast
            case "bnb_smart_chain":
                self = .bnbSmartChain
            case "celo":
                self = .celo
            case "ethereum", "mainnet":
                // Note: we accept either
                self = .ethereum
            case "gnosis":
                self = .gnosis
            case "hyper_evm":
                self = .hyperEVM
            case "ink":
                self = .ink
            case "lens":
                self = .lens
            case "linea":
                self = .linea
            case "linea_sepolia":
                self = .lineaSepolia
            case "lisk":
                self = .lisk
            case "mantle":
                self = .mantle
            case "mode":
                self = .mode
            case "optimism":
                self = .optimism
            case "plume":
                self = .plume
            case "polygon":
                self = .polygon
            case "redstone":
                self = .redstone
            case "scroll":
                self = .scroll
            case "scroll_sepolia":
                self = .scrollSepolia
            case "sepolia":
                self = .sepolia
            case "soneium":
                self = .soneium
            case "sonic":
                self = .sonic
            case "unichain":
                self = .unichain
            case "world_chain":
                self = .worldChain
            case "zksync":
                self = .zkSync
            case "zora":
                self = .zora
            default:
                // Check if it's an unknown network
                if ident.hasPrefix("unknown_") {
                    let chainIdStr = String(ident.dropFirst("unknown_".count))
                    guard let chainId = Number(chainIdStr) else {
                        throw NetworkIdentError.unknownNetwork(ident)
                    }
                    self = .unknown(chainId)
                } else {
                    throw NetworkIdentError.unknownNetwork(ident)
                }
        }
    }
}

public enum NetworkIdentError: Error, CustomStringConvertible {
    case unknownNetwork(String)

    public var description: String {
        switch self {
            case .unknownNetwork(let ident):
                return "Unknown network identifier: \(ident)"
        }
    }
}
