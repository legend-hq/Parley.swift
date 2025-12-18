import Eth
import Foundation
import SwiftNumber

public struct AcrossQuote: Codable, Equatable, Sendable {
    public let srcAsset: EthAddress
    public let dstAsset: EthAddress
    public let srcChainId: UInt
    public let dstChainId: UInt
    public let relayerGasFee: Number
    public let deltaFeePct: Number
    public let minDeposit: Number

    public init(
        srcAsset: EthAddress,
        dstAsset: EthAddress,
        srcChainId: UInt,
        dstChainId: UInt,
        relayerGasFee: Number,
        deltaFeePct: Number,
        minDeposit: Number
    ) {
        self.srcAsset = srcAsset
        self.dstAsset = dstAsset
        self.srcChainId = srcChainId
        self.dstChainId = dstChainId
        self.relayerGasFee = relayerGasFee
        self.deltaFeePct = deltaFeePct
        self.minDeposit = minDeposit
    }

    enum CodingKeys: String, CodingKey {
        case srcAsset = "src_asset"
        case dstAsset = "dst_asset"
        case srcChainId = "src_chain_id"
        case dstChainId = "dst_chain_id"
        case relayerGasFee = "relayer_gas_fee"
        case deltaFeePct = "delta_fee_pct"
        case minDeposit = "min_deposit"
    }
}

extension Array where Element == AcrossQuote {
    public func getQuote(srcAsset: Asset, dstAsset: Asset) -> AcrossQuote? {
        first(where: {
            $0.srcAsset == srcAsset.address && $0.dstAsset == dstAsset.address
                && Number($0.srcChainId) == srcAsset.chain.chainId
                && Number($0.dstChainId) == dstAsset.chain.chainId
        })
    }
}
