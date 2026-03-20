import Eth
import Foundation
import SwiftNumber

public enum ChainAddress: Equatable, Hashable, Sendable {
    // Atlas-supported EVM networks
    case arbitrum(EthAddress)
    case base(EthAddress)
    case ethereum(EthAddress)
    case hyperEVM(EthAddress)
    case optimism(EthAddress)
    case polygon(EthAddress)
    case unichain(EthAddress)
    case worldChain(EthAddress)
    // Testnets
    case sepolia(EthAddress)
    case baseSepolia(EthAddress)
    // Solana
    case solana(SolanaAddress)

    /// Constructs a ChainAddress from a runtime Network value and an EthAddress.
    /// Traps if the network is not supported.
    public init(_ address: EthAddress, chain: Network) {
        switch chain {
        case .arbitrum: self = .arbitrum(address)
        case .base: self = .base(address)
        case .ethereum: self = .ethereum(address)
        case .hyperEVM: self = .hyperEVM(address)
        case .optimism: self = .optimism(address)
        case .polygon: self = .polygon(address)
        case .unichain: self = .unichain(address)
        case .worldChain: self = .worldChain(address)
        case .sepolia: self = .sepolia(address)
        case .baseSepolia: self = .baseSepolia(address)
        default: preconditionFailure("Unsupported network for ChainAddress: \(chain)")
        }
    }

    /// Returns true if the given network is supported by ChainAddress.
    public static func supports(_ chain: Network) -> Bool {
        switch chain {
        case .arbitrum, .base, .ethereum, .hyperEVM, .optimism, .polygon, .unichain, .worldChain,
             .sepolia, .baseSepolia:
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Accessors

extension ChainAddress {
    /// The EVM address. Traps if this is a Solana address.
    public var ethAddress: EthAddress {
        switch self {
        case .arbitrum(let a), .base(let a), .ethereum(let a), .hyperEVM(let a),
             .optimism(let a), .polygon(let a), .unichain(let a), .worldChain(let a),
             .sepolia(let a), .baseSepolia(let a):
            return a
        case .solana:
            preconditionFailure("Cannot access EthAddress from a Solana ChainAddress")
        }
    }

    /// The Solana address. Traps if this is an EVM address.
    public var solanaAddress: SolanaAddress {
        switch self {
        case .solana(let a):
            return a
        default:
            preconditionFailure("Cannot access SolanaAddress from an EVM ChainAddress")
        }
    }

    /// The chain this address is on.
    public var chain: Network {
        switch self {
        case .arbitrum: return .arbitrum
        case .base: return .base
        case .ethereum: return .ethereum
        case .hyperEVM: return .hyperEVM
        case .optimism: return .optimism
        case .polygon: return .polygon
        case .unichain: return .unichain
        case .worldChain: return .worldChain
        case .sepolia: return .sepolia
        case .baseSepolia: return .baseSepolia
        // TODO: Add .solana case to Network enum in Eth.swift (chain_id = 501424)
        case .solana: return .unknown(Number("501424"))
        }
    }

    /// A human-readable string representation of the address.
    public var displayString: String {
        switch self {
        case .arbitrum(let a), .base(let a), .ethereum(let a), .hyperEVM(let a),
             .optimism(let a), .polygon(let a), .unichain(let a), .worldChain(let a),
             .sepolia(let a), .baseSepolia(let a):
            return a.hex
        case .solana(let a):
            return a.base58
        }
    }

    /// A shortened human-readable representation of the address (e.g. "0xd8dA...6045").
    public var shortened: String {
        displayString.shortened(withPrefix: 6, andSuffix: 4)
    }

    /// A formatted string like "on Base".
    public var onChain: String {
        "on \(chain.description)"
    }
}

// MARK: - CustomStringConvertible

extension ChainAddress: CustomStringConvertible {
    public var description: String {
        displayString
    }
}

// MARK: - Codable

extension ChainAddress: Codable {
    enum CodingKeys: String, CodingKey {
        case address
        case chain
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let chain = try container.decode(Network.self, forKey: .chain)
        let addressString = try container.decode(String.self, forKey: .address)

        if addressString.hasPrefix("0x") {
            guard let ethAddr = EthAddress(fromHexString: addressString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .address, in: container,
                    debugDescription: "Invalid EVM address: \(addressString)"
                )
            }
            guard ChainAddress.supports(chain) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .chain, in: container,
                    debugDescription: "Unsupported network: \(chain)"
                )
            }
            self = ChainAddress(ethAddr, chain: chain)
        } else {
            guard let solAddr = SolanaAddress(fromBase58: addressString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .address, in: container,
                    debugDescription: "Invalid Solana address: \(addressString)"
                )
            }
            self = .solana(solAddr)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayString, forKey: .address)
        try container.encode(chain, forKey: .chain)
    }
}
