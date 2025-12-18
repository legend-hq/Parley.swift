import SwiftNumber
import Testing
import Foundation

@testable import Prelude

struct ValueTests {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    @Test("Value Scientific parsing")
    func valueScientificParsing() throws {
        let value = try Value.init(scientificString: "149.37000000")
        #expect(value == Value("14937000000"))
    }

    @Test("Value Scientific crafting")
    func valueScientificCrafting() throws {
        #expect("149.37" == Value("14937000000").scientific)
    }

    @Test("Value Scientific Decoding")
    func valueScientificDecoding() throws {
        let encoded = "\"149.37\""
        let value: Value = try decoder.decode(Value.self, from: encoded.data(using: .utf8)!)
        #expect(value == Value("14937000000"))
    }

    @Test("Value Scientific Encoding")
    func valueScientificEncoding() throws {
        let data = try encoder.encode(Value("14937000000"))
        let json = String(data: data, encoding: .utf8)!
        #expect("\"149.37\"" == json)
    }
}
