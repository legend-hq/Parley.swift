import Atlas
import Eth
import Foundation
import SwiftNumber

/// Solana network constants and utility functions.
public enum SolanaConstants {
    /// Solana mainnet CAIP-2 identifier.
    public static let CAIP2_IDENTIFIER = "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp"

    /// The Solana System Program address.
    public static let SYSTEM_PROGRAM: SolanaAddress = "11111111111111111111111111111111"

    /// The SPL Token Program address.
    public static let TOKEN_PROGRAM: SolanaAddress = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"

    /// The Associated Token Program address.
    public static let ASSOCIATED_TOKEN_PROGRAM: SolanaAddress =
        "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"

    /// The SysvarRecentBlockhashes address (required by AdvanceNonceAccount).
    public static let SYSVAR_RECENT_BLOCKHASHES: SolanaAddress =
        "SysvarRecentB1ockHashes11111111111111111111"

    /// The Sysvar Rent address (required for ATA creation instructions).
    public static let SYSVAR_RENT: SolanaAddress = "SysvarRent111111111111111111111111111111111"

    /// Derives the Associated Token Account (ATA) address for a wallet and mint.
    ///
    /// The ATA is a Program Derived Address (PDA) computed as:
    /// `findProgramAddress([wallet, TOKEN_PROGRAM, mint], ASSOCIATED_TOKEN_PROGRAM)`
    public static func getAssociatedTokenAddress(
        wallet: SolanaAddress,
        mint: SolanaAddress
    ) -> SolanaAddress {
        let seeds: [Data] = [
            wallet.data,
            TOKEN_PROGRAM.data,
            mint.data,
        ]
        guard
            let (address, _) = findProgramAddress(seeds: seeds, programId: ASSOCIATED_TOKEN_PROGRAM)
        else {
            preconditionFailure(
                "Failed to derive ATA for wallet=\(wallet.base58) mint=\(mint.base58)"
            )
        }
        return address
    }

    /// Solana `findProgramAddress` — finds a valid PDA by iterating bump seeds from 255 down to 0.
    /// Returns the derived address and bump seed, or nil if no valid PDA found.
    public static func findProgramAddress(
        seeds: [Data],
        programId: SolanaAddress
    ) -> (SolanaAddress, UInt8)? {
        for bump in stride(from: UInt8(255), through: 0, by: -1) {
            if let address = createProgramAddress(
                seeds: seeds + [Data([bump])],
                programId: programId
            ) {
                return (address, bump)
            }
        }
        return nil
    }

    /// Computes a program-derived address from seeds and program ID.
    /// Returns nil if the result is on the ed25519 curve (not a valid PDA).
    static func createProgramAddress(
        seeds: [Data],
        programId: SolanaAddress
    ) -> SolanaAddress? {
        var data = Data()
        for seed in seeds {
            data.append(seed)
        }
        data.append(programId.data)
        data.append("ProgramDerivedAddress".data(using: .utf8)!)

        let hash = SHA256.hash(data: data)
        // A valid PDA must NOT be on the ed25519 curve.
        if Ed25519CurveCheck.isOnCurve(hash) {
            return nil
        }
        return SolanaAddress(fromData: hash)
    }
}

// MARK: - Ed25519 Curve Check (for PDA validation)

/// Checks whether a 32-byte value is a valid compressed Ed25519 point.
/// Used by `createProgramAddress` to reject on-curve hashes.
///
/// Ed25519 uses the twisted Edwards curve: -x^2 + y^2 = 1 + d*x^2*y^2
/// over the prime field p = 2^255 - 19, where d = -121665/121666.
///
/// A compressed point is the y-coordinate (255 bits, little-endian) with
/// the sign of x in the top bit. To check if bytes represent a valid point:
/// 1. Decode y (clear top bit)
/// 2. Compute x^2 = (y^2 - 1) / (d*y^2 + 1)
/// 3. Check if x^2 has a square root mod p (Euler criterion)
enum Ed25519CurveCheck {
    // p = 2^255 - 19
    private static let p: [UInt64] = FieldElement.p

    /// Returns true if the 32 bytes represent a valid point on the ed25519 curve.
    static func isOnCurve(_ bytes: Data) -> Bool {
        guard bytes.count == 32 else { return false }

        // Decode y from little-endian bytes (clear top bit = sign bit)
        var yBytes = Array(bytes)
        yBytes[31] &= 0x7F

        let y = FieldElement.fromLittleEndian(yBytes)

        // Check y < p (reject non-canonical representations)
        if !FieldElement.lessThan(y, FieldElement.p) {
            return false
        }

        // Compute y^2 mod p
        let y2 = FieldElement.mul(y, y)

        // u = y^2 - 1 mod p
        let u = FieldElement.sub(y2, FieldElement.one)

        // v = d * y^2 + 1 mod p
        let dy2 = FieldElement.mul(FieldElement.d, y2)
        let v = FieldElement.add(dy2, FieldElement.one)

        // x^2 = u * v^(-1) mod p
        // v^(-1) = v^(p-2) mod p (Fermat's little theorem)
        let vInv = FieldElement.pow(v, FieldElement.pMinus2)

        // Check v * vInv == 1 (if v == 0, the point is not valid)
        let check = FieldElement.mul(v, vInv)
        if !FieldElement.equal(check, FieldElement.one) {
            return false
        }

        let x2 = FieldElement.mul(u, vInv)

        // If x^2 == 0, it's on the curve (x = 0 is valid)
        if FieldElement.isZero(x2) {
            return true
        }

        // Euler criterion: x^2 is a quadratic residue iff x^2^((p-1)/2) == 1 mod p
        let euler = FieldElement.pow(x2, FieldElement.pMinus1Over2)
        return FieldElement.equal(euler, FieldElement.one)
    }
}

/// Modular arithmetic over the field F_p where p = 2^255 - 19.
/// Uses 4 × UInt64 limbs for 256-bit big integers (big-endian: limb[0] = most significant).
///
/// Not performance-optimized — only runs during PDA derivation (~1-3 iterations per call).
/// Uses `UInt64.multipliedFullWidth` for 128-bit intermediate results (no UInt128 dependency).
private enum FieldElement {
    typealias FE = [UInt64]  // 4 limbs, big-endian

    // p = 2^255 - 19
    static let p: FE = [
        0x7FFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFF,
        0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFED,
    ]

    static let pMinus2: FE = [
        0x7FFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFF,
        0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFEB,
    ]

    static let pMinus1Over2: FE = [
        0x3FFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFF,
        0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFF6,
    ]

    static let zero: FE = [0, 0, 0, 0]
    static let one: FE = [0, 0, 0, 1]

    // d = -121665/121666 mod p
    static let d: FE = [
        0x5203_6CEE_2B6F_FE73, 0x8CC7_4079_7779_E898,
        0x0070_0A4D_4141_D8AB, 0x75EB_4DCA_1359_78A3,
    ]

    static func fromLittleEndian(_ bytes: [UInt8]) -> FE {
        var result: FE = [0, 0, 0, 0]
        for limb in 0..<4 {
            var val: UInt64 = 0
            for i in 0..<8 {
                let byteIndex = (3 - limb) * 8 + i
                if byteIndex < bytes.count {
                    val |= UInt64(bytes[byteIndex]) << (i * 8)
                }
            }
            result[limb] = val
        }
        return result
    }

    static func isZero(_ a: FE) -> Bool {
        a[0] == 0 && a[1] == 0 && a[2] == 0 && a[3] == 0
    }

    static func equal(_ a: FE, _ b: FE) -> Bool {
        a[0] == b[0] && a[1] == b[1] && a[2] == b[2] && a[3] == b[3]
    }

    static func lessThan(_ a: FE, _ b: FE) -> Bool {
        for i in 0..<4 {
            if a[i] < b[i] { return true }
            if a[i] > b[i] { return false }
        }
        return false
    }

    // MARK: - Addition

    static func add(_ a: FE, _ b: FE) -> FE {
        var result: FE = [0, 0, 0, 0]
        var carry: UInt64 = 0
        for i in stride(from: 3, through: 0, by: -1) {
            let (s1, c1) = a[i].addingReportingOverflow(b[i])
            let (s2, c2) = s1.addingReportingOverflow(carry)
            result[i] = s2
            carry = (c1 ? 1 : 0) + (c2 ? 1 : 0)
        }
        if carry != 0 || !lessThan(result, p) {
            result = subNoBorrow(result, p)
        }
        return result
    }

    // MARK: - Subtraction

    static func sub(_ a: FE, _ b: FE) -> FE {
        if lessThan(a, b) {
            let diff = subNoBorrow(b, a)
            return subNoBorrow(p, diff)
        }
        return subNoBorrow(a, b)
    }

    private static func subNoBorrow(_ a: FE, _ b: FE) -> FE {
        var result: FE = [0, 0, 0, 0]
        var borrow: UInt64 = 0
        for i in stride(from: 3, through: 0, by: -1) {
            let (d1, b1) = a[i].subtractingReportingOverflow(b[i])
            let (d2, b2) = d1.subtractingReportingOverflow(borrow)
            result[i] = d2
            borrow = (b1 ? 1 : 0) + (b2 ? 1 : 0)
        }
        return result
    }

    // MARK: - Multiplication

    static func mul(_ a: FE, _ b: FE) -> FE {
        // Schoolbook 4×4 → 8 limb product
        var product = [UInt64](repeating: 0, count: 8)

        for i in stride(from: 3, through: 0, by: -1) {
            var carry: UInt64 = 0
            for j in stride(from: 3, through: 0, by: -1) {
                let k = i + j + 1
                let (hi, lo) = a[i].multipliedFullWidth(by: b[j])
                let (s1, c1) = product[k].addingReportingOverflow(lo)
                let (s2, c2) = s1.addingReportingOverflow(carry)
                product[k] = s2
                carry = hi &+ (c1 ? 1 : 0) &+ (c2 ? 1 : 0)
            }
            product[i] = product[i] &+ carry
        }

        return reduce512(product)
    }

    // MARK: - Exponentiation

    static func pow(_ base: FE, _ exp: FE) -> FE {
        var result = one
        var b = base
        for limbIdx in stride(from: 3, through: 0, by: -1) {
            var limb = exp[limbIdx]
            for _ in 0..<64 {
                if limb & 1 == 1 {
                    result = mul(result, b)
                }
                b = mul(b, b)
                limb >>= 1
            }
        }
        return result
    }

    // MARK: - Reduction

    private static func reduce512(_ product: [UInt64]) -> FE {
        // p = 2^255 - 19, so 2^255 ≡ 19 (mod p).
        // Split: low = bits 0..254, high = bits 255..511.
        // result = low + high * 19

        var low: FE = [
            product[4] & 0x7FFF_FFFF_FFFF_FFFF, product[5], product[6], product[7],
        ]

        let high: FE = [
            (product[0] << 1) | (product[1] >> 63),
            (product[1] << 1) | (product[2] >> 63),
            (product[2] << 1) | (product[3] >> 63),
            (product[3] << 1) | (product[4] >> 63),
        ]

        let high19 = mulSmall(high, 19)
        var result = addNoReduce(low, high19)

        // Fold overflow above bit 255
        let overflow = result[0] >> 63
        result[0] &= 0x7FFF_FFFF_FFFF_FFFF
        if overflow != 0 {
            result = addNoReduce(result, [0, 0, 0, overflow * 19])
            let overflow2 = result[0] >> 63
            result[0] &= 0x7FFF_FFFF_FFFF_FFFF
            if overflow2 != 0 {
                result = addNoReduce(result, [0, 0, 0, overflow2 * 19])
            }
        }

        if !lessThan(result, p) {
            result = subNoBorrow(result, p)
        }
        return result
    }

    private static func mulSmall(_ a: FE, _ scalar: UInt64) -> FE {
        var result: FE = [0, 0, 0, 0]
        var carry: UInt64 = 0
        for i in stride(from: 3, through: 0, by: -1) {
            let (hi, lo) = a[i].multipliedFullWidth(by: scalar)
            let (s1, c1) = lo.addingReportingOverflow(carry)
            result[i] = s1
            carry = hi &+ (c1 ? 1 : 0)
        }
        // Fold overflow: carry * 2^256 ≡ carry * 38 (mod p)
        if carry != 0 {
            var c2: UInt64 = 0
            let (hi2, lo2) = carry.multipliedFullWidth(by: 38 as UInt64)
            let (s, ov) = result[3].addingReportingOverflow(lo2)
            result[3] = s
            c2 = hi2 &+ (ov ? 1 : 0)
            if c2 != 0 {
                for i in stride(from: 2, through: 0, by: -1) {
                    let (s2, ov2) = result[i].addingReportingOverflow(c2)
                    result[i] = s2
                    if !ov2 { break }
                    c2 = 1
                }
            }
        }
        return result
    }

    private static func addNoReduce(_ a: FE, _ b: FE) -> FE {
        var result: FE = [0, 0, 0, 0]
        var carry: UInt64 = 0
        for i in stride(from: 3, through: 0, by: -1) {
            let (s1, c1) = a[i].addingReportingOverflow(b[i])
            let (s2, c2) = s1.addingReportingOverflow(carry)
            result[i] = s2
            carry = (c1 ? 1 : 0) + (c2 ? 1 : 0)
        }
        if carry != 0 {
            // 2^256 ≡ 38 mod p
            let (s, c) = result[3].addingReportingOverflow(carry * 38)
            result[3] = s
            if c {
                for i in stride(from: 2, through: 0, by: -1) {
                    let (s2, c2) = result[i].addingReportingOverflow(1)
                    result[i] = s2
                    if !c2 { break }
                }
            }
        }
        return result
    }
}

// MARK: - Pure Swift SHA-256 (WASM-compatible, no CryptoKit dependency)

enum SHA256 {
    static func hash(data: Data) -> Data {
        var hasher = SHA256Hasher()
        hasher.update(Array(data))
        return Data(hasher.finalize())
    }

    private struct SHA256Hasher {
        private static let k: [UInt32] = [
            0x428a_2f98, 0x7137_4491, 0xb5c0_fbcf, 0xe9b5_dba5,
            0x3956_c25b, 0x59f1_11f1, 0x923f_82a4, 0xab1c_5ed5,
            0xd807_aa98, 0x1283_5b01, 0x2431_85be, 0x550c_7dc3,
            0x72be_5d74, 0x80de_b1fe, 0x9bdc_06a7, 0xc19b_f174,
            0xe49b_69c1, 0xefbe_4786, 0x0fc1_9dc6, 0x240c_a1cc,
            0x2de9_2c6f, 0x4a74_84aa, 0x5cb0_a9dc, 0x76f9_88da,
            0x983e_5152, 0xa831_c66d, 0xb003_27c8, 0xbf59_7fc7,
            0xc6e0_0bf3, 0xd5a7_9147, 0x06ca_6351, 0x1429_2967,
            0x27b7_0a85, 0x2e1b_2138, 0x4d2c_6dfc, 0x5338_0d13,
            0x650a_7354, 0x766a_0abb, 0x81c2_c92e, 0x9272_2c85,
            0xa2bf_e8a1, 0xa81a_664b, 0xc24b_8b70, 0xc76c_51a3,
            0xd192_e819, 0xd699_0624, 0xf40e_3585, 0x106a_a070,
            0x19a4_c116, 0x1e37_6c08, 0x2748_774c, 0x34b0_bcb5,
            0x391c_0cb3, 0x4ed8_aa4a, 0x5b9c_ca4f, 0x682e_6ff3,
            0x748f_82ee, 0x78a5_636f, 0x84c8_7814, 0x8cc7_0208,
            0x90be_fffa, 0xa450_6ceb, 0xbef9_a3f7, 0xc671_78f2,
        ]

        private var h: [UInt32] = [
            0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a,
            0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19,
        ]

        private var buffer = [UInt8]()
        private var totalLength: UInt64 = 0

        mutating func update(_ bytes: [UInt8]) {
            buffer.append(contentsOf: bytes)
            totalLength += UInt64(bytes.count)
            processBlocks()
        }

        mutating func finalize() -> [UInt8] {
            // Padding
            buffer.append(0x80)
            while (buffer.count % 64) != 56 {
                buffer.append(0x00)
            }
            // Append length in bits as big-endian 64-bit
            let bitLength = totalLength * 8
            for i in stride(from: 56, through: 0, by: -8) {
                buffer.append(UInt8((bitLength >> i) & 0xFF))
            }
            processBlocks()

            var result = [UInt8]()
            for value in h {
                result.append(UInt8((value >> 24) & 0xFF))
                result.append(UInt8((value >> 16) & 0xFF))
                result.append(UInt8((value >> 8) & 0xFF))
                result.append(UInt8(value & 0xFF))
            }
            return result
        }

        private mutating func processBlocks() {
            while buffer.count >= 64 {
                let block = Array(buffer.prefix(64))
                buffer.removeFirst(64)
                processBlock(block)
            }
        }

        private mutating func processBlock(_ block: [UInt8]) {
            var w = [UInt32](repeating: 0, count: 64)
            for i in 0..<16 {
                w[i] =
                    UInt32(block[i * 4]) << 24
                    | UInt32(block[i * 4 + 1]) << 16
                    | UInt32(block[i * 4 + 2]) << 8
                    | UInt32(block[i * 4 + 3])
            }
            for i in 16..<64 {
                let s0 =
                    rightRotate(w[i - 15], by: 7) ^ rightRotate(w[i - 15], by: 18)
                    ^ (w[i - 15] >> 3)
                let s1 =
                    rightRotate(w[i - 2], by: 17) ^ rightRotate(w[i - 2], by: 19)
                    ^ (w[i - 2] >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }

            var a = h[0]
            var b = h[1]
            var c = h[2]
            var d = h[3]
            var e = h[4]
            var f = h[5]
            var g = h[6]
            var hh = h[7]

            for i in 0..<64 {
                let s1 = rightRotate(e, by: 6) ^ rightRotate(e, by: 11) ^ rightRotate(e, by: 25)
                let ch = (e & f) ^ (~e & g)
                let temp1 = hh &+ s1 &+ ch &+ SHA256Hasher.k[i] &+ w[i]
                let s0 = rightRotate(a, by: 2) ^ rightRotate(a, by: 13) ^ rightRotate(a, by: 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj

                hh = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }

            h[0] &+= a
            h[1] &+= b
            h[2] &+= c
            h[3] &+= d
            h[4] &+= e
            h[5] &+= f
            h[6] &+= g
            h[7] &+= hh
        }

        private func rightRotate(_ value: UInt32, by amount: UInt32) -> UInt32 {
            (value >> amount) | (value << (32 - amount))
        }
    }
}
