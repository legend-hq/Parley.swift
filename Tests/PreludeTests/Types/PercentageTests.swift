import Foundation
import Prelude
import Testing

struct PercentageTests {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    }

    @Test
    func testFormatPercentage() {
        let percentage = Percentage("256071867773760000")
        let formattedPercentage = percentage.formatted()
        #expect(formattedPercentage == "25.61%")
    }

    @Test
    func testFormatPercentageWithoutDecimals() {
        let percentage = Percentage("256071867773760000")
        let formattedPercentage = percentage.formatted(showDecimals: false)
        #expect(formattedPercentage == "26%")
    }

    func testFormatPercentageAsMultiplier() {
        let percentage = Percentage(double: 4.20)
        let formattedPercentage = percentage.formattedMultiplier()
        #expect(formattedPercentage == "4.20x")
    }

    @Test
    func testAddingPercentages() {
        let percentage1 = Percentage("256071867773760000")
        let percentage2 = Percentage("343186637796385872")
        let sum = percentage1 + percentage2
        let formattedSum = sum.formatted()
        #expect(formattedSum == "59.93%")
    }

    @Test
    func testComparingPercentages() {
        let percentage1 = Percentage("256071867773760000")
        let percentage2 = Percentage("343186637796385872")
        #expect(percentage1 < percentage2)
    }

    @Test
    func testAbs() {
        let positive = Percentage("100000000000000000")
        #expect(positive.abs() == positive)

        let negative = Percentage(0) - Percentage("100000000000000000")
        #expect(negative.abs() == positive)
    }

    @Test
    func testInitFromDouble() {
        let percentage = Percentage(double: 0.42)
        #expect(percentage == Percentage("420000000000000000"))
    }

    @Test
    func testInitFromSmallDouble() {
        let percentage = Percentage(double: 0.00000069)
        #expect(percentage == Percentage("690000000000"))
    }

    @Test
    func testToDecimal() {
        let percentage = Percentage("420000000000000000")
        #expect(percentage.toDecimal() == Decimal(0.42))
    }

    @Test
    func testToCgFloat() {
        let percentage = Percentage("420000000000000000")
        #expect(abs(percentage.toCgFloat() - 0.42) < 0.0001)
    }

    @Test
    func testMultiplication() {
        let percentage1 = Percentage(double: 0.5)
        let percentage2 = Percentage(double: 0.4)
        #expect(percentage1 * percentage2 == Percentage(double: 0.2))
    }

    @Test
    func testMultiplicationWithDifferentFactorScales() {
        let percentage1 = Percentage(double: 0.5, factorScale: 17)
        let percentage2 = Percentage(double: 0.4)
        #expect(percentage1 * percentage2 == Percentage(double: 0.2, factorScale: 17))
    }

    @Test
    func testSettingDifferentFactorScale() {
        let percentage1 = Percentage("100000000000000000", factorScale: 19)
        let percentage2 = Percentage("10000000000000000", factorScale: 18)

        #expect(percentage1 == percentage2)

        let sum = percentage1 + percentage2
        #expect(sum == Percentage(double: 0.02))
    }

    func testDivision() {
        let percentage1 = Percentage(double: 0.1)
        let percentage2 = Percentage(double: 0.5)

        #expect(percentage1 / percentage2 == Percentage(double: 0.2))
    }

    @Test("Percentage Scientific parsing")
    func percentageScientificParsing() throws {
        let percentage = try Percentage.init(scientificString: "0.37")
        #expect(percentage == Percentage("370000000000000000"))

        let percentage2 = try Percentage.init(scientificString: "0.999873231920273")
        #expect(percentage2 == Percentage("999873231920273000"))

        let percentage3 = try Percentage.init(scientificString: "-0.999873231920273")
        #expect(percentage3 == Percentage("-999873231920273000"))
    }

    @Test("Percentage Scientific crafting")
    func percentageScientificCrafting() throws {
        #expect("0.37" == Percentage("370000000000000000").scientific)
        #expect("0.999873231920273" == Percentage("999873231920273000").scientific)
        #expect("-0.999873231920273" == Percentage("-999873231920273000").scientific)
    }

    @Test("Percentage Scientific Decoding")
    func percentageScientificDecoding() throws {
        let encoded = "\"0.37\""
        let percentage: Percentage = try! decoder.decode(
            Percentage.self,
            from: encoded.data(using: .utf8)!
        )
        #expect(percentage == Percentage("370000000000000000"))
    }

    @Test("Percentage Scientific Encoding")
    func percentageScientificEncoding() throws {
        let data = try encoder.encode(Percentage("370000000000000000"))
        let json = String(data: data, encoding: .utf8)!
        #expect("\"0.37\"" == json)
    }
}
