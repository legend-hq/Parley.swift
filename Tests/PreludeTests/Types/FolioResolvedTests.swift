import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

@Suite("Folio Resolved Tests")
struct FolioResolvedTests {

    let wallet: EthAddress = "0xaabbccddee1234567890abcdef1234567890abcd"

    // MARK: - 1. Single patch, trigger unsatisfied

    @Test("Single patch applied when trigger is unsatisfied")
    func singlePatchUnsatisfied() {
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    100_000_000,
                    decimals: 6
                )
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-50e6"
                    )
                ]
            ]
        )

        let resolved = folio.resolved()
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(50_000_000, decimals: 6)
        )
    }

    // MARK: - 2. Single patch, trigger satisfied

    @Test("Single patch skipped when trigger is satisfied")
    func singlePatchSatisfied() {
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    100_000_000,
                    decimals: 6
                )
            ],
            completionStatuses: [
                .quarkNonce(wallet: wallet, nonce: nonce): true
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-50e6"
                    )
                ]
            ]
        )

        let resolved = folio.resolved()
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(100_000_000, decimals: 6)
        )
    }

    // MARK: - 3. Multiple triggers, mixed satisfaction

    @Test("Only unsatisfied trigger deltas are applied")
    func multipleTriggersMixed() {
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"
        let relayHash: Hex =
            "0x1111111111111111111111111111111111111111111111111111111111111111"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    100_000_000,
                    decimals: 6
                )
            ],
            completionStatuses: [
                .quarkNonce(wallet: wallet, nonce: nonce): true
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-30e6"
                    )
                ],
                .acrossFill(wallet: wallet, relayHash: relayHash): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-20e6"
                    )
                ],
            ]
        )

        let resolved = folio.resolved()
        // quarkNonce satisfied → skip -30. acrossFill unsatisfied → apply -20. 100 - 20 = 80.
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(80_000_000, decimals: 6)
        )
    }

    // MARK: - 4. Multiple patches same balance key

    @Test("Multiple unsatisfied triggers sum deltas on same balance")
    func multiplePatchesSameBalance() {
        let nonce1: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"
        let nonce2: Hex = "0x0000000000000000000000000000000000000000000000000000000000000002"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    100_000_000,
                    decimals: 6
                )
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce1): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-30e6"
                    )
                ],
                .quarkNonce(wallet: wallet, nonce: nonce2): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-20e6"
                    )
                ],
            ]
        )

        let resolved = folio.resolved()
        // -30 + -20 = -50 from 100 → 50
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(50_000_000, decimals: 6)
        )
    }

    // MARK: - 5. Missing balance key + positive delta

    @Test("Positive delta creates balance from zero when key is missing")
    func missingBalancePositiveDelta() {
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"

        let folio = Folio(
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "10e6"
                    )
                ]
            ]
        )

        let resolved = folio.resolved()
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(10_000_000, decimals: 6)
        )
    }

    // MARK: - 6. Clamp to zero

    @Test("Negative delta clamps balance to zero")
    func clampToZero() {
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    5_000_000,
                    decimals: 6
                )
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-50e6"
                    )
                ]
            ]
        )

        let resolved = folio.resolved()
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(0, decimals: 6)
        )
    }

    // MARK: - 7. Bridge: two triggers, one fires

    @Test("Bridge scenario — source trigger satisfied, dest trigger unsatisfied")
    func bridgeOneTriggerFires() {
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000005"
        let relayHash: Hex =
            "0x1111111111111111111111111111111111111111111111111111111111111111"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    100_000_000,
                    decimals: 6
                ),
                .token(network: .arbitrum, symbol: "USDC", wallet: wallet.on(.arbitrum)): Amount(
                    200_000_000,
                    decimals: 6
                ),
            ],
            completionStatuses: [
                .quarkNonce(wallet: wallet, nonce: nonce): true
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-100e6"
                    )
                ],
                .acrossFill(wallet: wallet, relayHash: relayHash): [
                    Folio.Patch(
                        target: .token(network: .arbitrum, symbol: "USDC", wallet: wallet.on(.arbitrum)),
                        delta: "99e6"
                    )
                ],
            ]
        )

        let resolved = folio.resolved()
        // Source: quarkNonce satisfied → skip, balance stays 100
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(100_000_000, decimals: 6)
        )
        // Dest: acrossFill unsatisfied → apply +99, 200 + 99 = 299
        #expect(
            resolved.balances[.token(network: .arbitrum, symbol: "USDC", wallet: wallet.on(.arbitrum))]
                == Amount(299_000_000, decimals: 6)
        )
    }

    // MARK: - 8. No patches

    @Test("Folio with no patches returns identical balances")
    func noPatches() {
        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    100_000_000,
                    decimals: 6
                )
            ]
        )

        let resolved = folio.resolved()
        #expect(resolved.balances == folio.balances)
    }

    // MARK: - 9. All triggers satisfied

    @Test("All triggers satisfied returns identical balances")
    func allTriggersSatisfied() {
        let nonce: Hex = "0x0000000000000000000000000000000000000000000000000000000000000001"
        let relayHash: Hex =
            "0x1111111111111111111111111111111111111111111111111111111111111111"

        let folio = Folio(
            balances: [
                .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)): Amount(
                    100_000_000,
                    decimals: 6
                )
            ],
            completionStatuses: [
                .quarkNonce(wallet: wallet, nonce: nonce): true,
                .acrossFill(wallet: wallet, relayHash: relayHash): true,
            ],
            patches: [
                .quarkNonce(wallet: wallet, nonce: nonce): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "-50e6"
                    )
                ],
                .acrossFill(wallet: wallet, relayHash: relayHash): [
                    Folio.Patch(
                        target: .token(network: .base, symbol: "USDC", wallet: wallet.on(.base)),
                        delta: "99e6"
                    )
                ],
            ]
        )

        let resolved = folio.resolved()
        #expect(
            resolved.balances[.token(network: .base, symbol: "USDC", wallet: wallet.on(.base))]
                == Amount(100_000_000, decimals: 6)
        )
    }
}
