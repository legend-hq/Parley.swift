import Foundation

/// A Solana address representing a 32-byte ed25519 public key, encoded as a Base58 string.
public struct SolanaAddress: Equatable, Hashable, Sendable {
    /// The raw 32-byte public key data.
    public let data: Data

    /// Creates a SolanaAddress from raw 32-byte data.
    /// Returns nil if the data is not exactly 32 bytes.
    public init?(fromData data: Data) {
        guard data.count == 32 else { return nil }
        self.data = data
    }

    /// Creates a SolanaAddress from a Base58-encoded string.
    /// Returns nil if the string is not valid Base58 or does not decode to exactly 32 bytes.
    public init?(fromBase58 base58String: String) {
        guard let decoded = Base58.decode(base58String),
              decoded.count == 32
        else {
            return nil
        }
        self.data = decoded
    }

    /// The Base58-encoded string representation of this address.
    public var base58: String {
        Base58.encode(data)
    }
}

// MARK: - CustomStringConvertible

extension SolanaAddress: CustomStringConvertible {
    public var description: String {
        base58
    }
}

// MARK: - ExpressibleByStringLiteral

extension SolanaAddress: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        guard let address = SolanaAddress(fromBase58: value) else {
            fatalError("Invalid Solana address: \(value)")
        }
        self = address
    }
}

// MARK: - Codable

extension SolanaAddress: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let base58String = try container.decode(String.self)
        guard let address = SolanaAddress(fromBase58: base58String) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid Solana address: \(base58String)"
            )
        }
        self = address
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(base58)
    }
}

// MARK: - Base58 Encoding/Decoding

/// Minimal Base58 codec for Solana address encoding.
enum Base58 {
    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
    private static let baseCount = UInt(alphabet.count)

    static func encode(_ data: Data) -> String {
        var bytes = Array(data)
        var result = [Character]()

        // Count leading zeros
        let leadingZeros = bytes.prefix(while: { $0 == 0 }).count

        // Convert to base58
        while !bytes.isEmpty {
            var carry = UInt(0)
            var newBytes = [UInt8]()
            for byte in bytes {
                carry = carry * 256 + UInt(byte)
                if !newBytes.isEmpty || carry >= baseCount {
                    newBytes.append(UInt8(carry / baseCount))
                    carry = carry % baseCount
                }
            }
            result.append(alphabet[Int(carry)])
            bytes = newBytes
        }

        // Add leading '1's for each leading zero byte
        let ones = Array(repeating: alphabet[0], count: leadingZeros)
        return String(ones + result.reversed())
    }

    static func decode(_ string: String) -> Data? {
        var result = [UInt8]()
        let chars = Array(string)

        // Count leading '1's
        let leadingOnes = chars.prefix(while: { $0 == "1" }).count

        for char in chars {
            guard let index = alphabet.firstIndex(of: char) else { return nil }
            var carry = UInt(index)
            for i in stride(from: result.count - 1, through: 0, by: -1) {
                carry += UInt(result[i]) * baseCount
                result[i] = UInt8(carry & 0xFF)
                carry >>= 8
            }
            while carry > 0 {
                result.insert(UInt8(carry & 0xFF), at: 0)
                carry >>= 8
            }
        }

        // Add leading zeros
        let zeros = Array(repeating: UInt8(0), count: leadingOnes)
        return Data(zeros + result)
    }
}
