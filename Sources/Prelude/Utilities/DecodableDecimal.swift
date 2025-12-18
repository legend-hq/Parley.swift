import SwiftNumber

struct CodableDecimal: Codable {
    let type: String = "decimal"
    let precision: Int
    let value: Number

    enum CodingKeys: String, CodingKey {
        case type
        case precision
        case uintString = "uint_string"
    }

    init(precision: Int, value: Number) {
        self.precision = precision
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        guard type == "decimal" else {
            let context = DecodingError.Context(
                codingPath: container.codingPath + [CodableDecimal.CodingKeys.type],
                debugDescription: "Invalid type: \(type). Expected 'decimal'."
            )
            throw DecodingError.dataCorrupted(context)
        }

        precision = try container.decode(Int.self, forKey: .precision)

        let decodedDecimalString = try container.decode(String.self, forKey: .uintString)
        guard let value = Number(decodedDecimalString) else {
            let context = DecodingError.Context(
                codingPath: container.codingPath + [CodableDecimal.CodingKeys.uintString],
                debugDescription: "Invalid Number string: \(decodedDecimalString)"
            )
            throw DecodingError.dataCorrupted(context)
        }

        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(precision, forKey: .precision)
        try container.encode(value.description, forKey: .uintString)
    }
}
