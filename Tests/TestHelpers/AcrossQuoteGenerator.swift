import Eth
import Foundation
import Prelude
import SwiftNumber

@testable import Charter

/// A helper class to build up a list of `AcrossQuote` objects from a series of `Given` cases.
public class AcrossQuoteState {
    public var givenAcrossQuotes: [(TokenAmount, Double, TokenAmount)] = []
    private let allNetworks: [Network] = [.ethereum, .base, .arbitrum, .optimism, .worldChain]

    public init() {}

    public func apply(_ given: Given) {
        switch given {
            case .acrossQuote(let gasFee, let feePct):
                givenAcrossQuotes.append(
                    (
                        gasFee, feePct,
                        TokenAmount(
                            fromWei: Number(0),
                            ofToken: gasFee.token
                        )
                    )
                )
            case .acrossQuoteWithMin(let gasFee, let feePct, let minAmount):
                givenAcrossQuotes.append((gasFee, feePct, minAmount))
            default:
                // Ignore other cases as they don't affect Across quotes
                break
        }
    }

    public var quotes: [AcrossQuote] {
        let networkPairs = allNetworks.flatMap { x in
            allNetworks.filter { $0 != x }
                .map { y in
                    (x, y)
                }
        }

        return givenAcrossQuotes.flatMap { gasFee, feePct, minAmount in
            networkPairs.compactMap { srcNetwork, destNetwork -> AcrossQuote? in
                guard let srcTokenAddress = gasFee.token.address(network: srcNetwork),
                    let destTokenAddress = gasFee.token.address(network: destNetwork)
                else {
                    return nil
                }

                return AcrossQuote(
                    srcAsset: srcTokenAddress,
                    dstAsset: destTokenAddress,
                    srcChainId: try! srcNetwork.chainId.toUInt(),
                    dstChainId: try! destNetwork.chainId.toUInt(),
                    relayerGasFee: gasFee.amount,
                    deltaFeePct: Number(feePct * 1e18),
                    minDeposit: minAmount.amount
                )
            }
        }
    }
}

/// Generates an array of `AcrossQuote` objects based on a given array of `Given` cases.
///
/// - Parameter givens: An array of `Given` enums that describe the desired state.
/// - Returns: An array of `AcrossQuote` objects representing the state across all supported networks.
public func generateAcrossQuotes(from givens: [Given]) -> [AcrossQuote] {
    let state = AcrossQuoteState()
    for given in givens {
        state.apply(given)
    }
    return state.quotes
}
