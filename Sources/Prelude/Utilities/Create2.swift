import Eth
import Foundation
import SwiftKeccak

public enum Create2 {
    public static let codeJarAddress = EthAddress("0x2b68764bCfE9fCD8d5a30a281F141f69b69Ae3C8")

    public static func getScriptAddress(_ creationCode: Hex) -> EthAddress {
        // Create2 address calculation according to EIP-1014
        // address = keccak256(0xff ++ deployingAddress ++ salt ++ keccak256(bytecode))[12:]

        // Pack the data according to create2 spec:
        // 1. 0xff - prevents collision with create
        // 2. deploying contract address
        // 3. salt (32 bytes of 0 in this case)
        // 4. keccak256 hash of initialization code
        var packed = Data()
        packed.append(Data([0xFF]))  // prefix byte
        packed.append(Create2.codeJarAddress.data)  // deploying address
        packed.append(Data(repeating: 0, count: 32))  // salt
        packed.append(SwiftKeccak.keccak256(creationCode.data))  // hash of init code

        // Take keccak256 hash and extract last 20 bytes for address
        let hash = SwiftKeccak.keccak256(packed)
        return EthAddress(Hex(hash.subdata(in: 12..<32)))!
    }
}
