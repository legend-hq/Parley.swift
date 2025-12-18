import Eth
import Foundation
import SwiftNumber
import Testing

@testable import Prelude

@Suite("Create2 Tests")
struct Create2Tests {
    @Test("Test Create2")
    func testCreate2() async throws {
        let address = Create2.getScriptAddress(Hex("0xaa"))
        #expect(address == EthAddress("0x103B7e61BBaa2F62028Ebf3Ea7C47dC74Bd3a617"))
    }
}
