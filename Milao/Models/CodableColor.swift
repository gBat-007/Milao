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

    /// Adaptive color based on given color scheme
    func resolved(for scheme: ColorScheme) -> Color {
        let uiColor = UIColor(color)

        guard let components = uiColor.cgColor.components else { return color }
        
        let r = components[0]
        let g = components.count >= 3 ? components[1] : r
        let b = components.count >= 3 ? components[2] : r
//        let a = uiColor.cgColor.alpha

        // Relative luminance per WCAG
        func relativeLuminance(_ c: CGFloat) -> CGFloat {
            return c <= 0.03928
                ? c / 12.92
                : pow((c + 0.055) / 1.055, 2.4)
        }

        let l1 = 0.2126 * relativeLuminance(r) +
                 0.7152 * relativeLuminance(g) +
                 0.0722 * relativeLuminance(b)

        let backgroundLuminance: CGFloat = scheme == .dark ? 0.0 : 1.0

        let brighter = max(l1, backgroundLuminance)
        let darker = min(l1, backgroundLuminance)

        let contrastRatio = (brighter + 0.05) / (darker + 0.05)

        // Adjust only if contrast is low
        if contrastRatio < 3.0 {
            let adjustedColor: UIColor
            if scheme == .light {
                // Darken for light mode
                adjustedColor = uiColor.withBrightnessMultiplier(0.5)
            } else {
                // Brighten for dark mode
                adjustedColor = uiColor.withBrightnessMultiplier(1.4)
            }
            return Color(adjustedColor)
        }

        return color
    }


    // Codable conformance
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

extension UIColor {
    func withBrightnessMultiplier(_ factor: CGFloat) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        if getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha) {
            let newBrightness = min(max(bri * factor, 0), 1)
            return UIColor(hue: hue, saturation: sat, brightness: newBrightness, alpha: alpha)
        }
        return self
    }
}
