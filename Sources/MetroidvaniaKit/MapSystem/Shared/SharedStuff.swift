enum HexColorFormat: CaseIterable {
    case rgba
    case argb
}

func parseHexColor(_ hex: String, format: HexColorFormat = .rgba) -> (r: Float, g: Float, b: Float, a: Float)? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        guard hexString.count == 8 || hexString.count == 6 else { return nil }
        guard let hexValue = UInt32(hexString, radix: 16) else { return nil }

        let r, g, b, a: UInt32
        if format == .argb || hexString.count == 6 {
            r = (hexValue & 0x00FF0000) >> 16
            g = (hexValue & 0x0000FF00) >> 8
            b = hexValue & 0x000000FF
            a = hexString.count == 8 ? (hexValue & 0xFF000000) >> 24 : 0xFF
        } else {
            r = (hexValue & 0xFF000000) >> 24
            g = (hexValue & 0x00FF0000) >> 16
            b = (hexValue & 0x0000FF00) >> 8
            a = hexValue & 0x000000FF
        }
        return (Float(r) / 255.0, Float(g) / 255.0, Float(b) / 255.0, Float(a) / 255.0)
    }