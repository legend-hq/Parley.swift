import Foundation
import Prelude
import Testing

struct TokenTests {
    @Test func testInit() {
        var token: Token = .init("USDC")
        #expect(Token.USDC == token)
        
        token = .init("usdc")
        #expect(Token.USDC == token)
        
        token = .init("HarryPotterObamaSonic10Inu")
        #expect(Token.UNKNOWN == token)
    }
}