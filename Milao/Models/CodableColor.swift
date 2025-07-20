import SwiftUI

// Helper wrapper for decoding either a Double or a String that can convert to Double
struct StringOrDouble: Codable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self),
                  let double = Double(string) {
            self.value = double
        } else {
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected Double or String convertible to Double"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct CodableColor: Codable, Equatable {
    let color: Color

    init(color: Color) {
        self.color = color
    }

    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .alpha)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let red = try container.decode(StringOrDouble.self, forKey: .red).value
        let green = try container.decode(StringOrDouble.self, forKey: .green).value
        let blue = try container.decode(StringOrDouble.self, forKey: .blue).value
        let alpha = try container.decode(StringOrDouble.self, forKey: .alpha).value

        self.color = Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
