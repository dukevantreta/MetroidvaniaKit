extension Tiled {
    struct Text {
        enum HorizontalAlignment: String {
            case left
            case center
            case right
            case justify
        }
        enum VerticalAlignment: String {
            case top
            case center
            case bottom
        }
        let fontFamily: String
        let pixelSize: Int
        let wrap: Bool
        let color: String
        let isBold: Bool
        let isItalic: Bool
        let hasUnderline: Bool
        let hasStrikeout: Bool
        let useKerning: Bool
        let horizontalAlignment: HorizontalAlignment
        let verticalAlignment: VerticalAlignment
    }
}

extension Tiled.Text: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.text)
        let attributes = xml.attributes
        self.init(
            fontFamily: attributes?["fontfamily"] ?? "sans-serif",
            pixelSize: attributes?["pixelsize"]?.asInt() ?? 16,
            wrap: attributes?["wrap"]?.asBool() ?? false,
            color: attributes?["color"] ?? "#000000",
            isBold: attributes?["bold"]?.asBool() ?? false,
            isItalic: attributes?["italic"]?.asBool() ?? false,
            hasUnderline: attributes?["underline"]?.asBool() ?? false,
            hasStrikeout: attributes?["strikeout"]?.asBool() ?? false,
            useKerning: attributes?["kerning"]?.asBool() ?? true,
            horizontalAlignment: HorizontalAlignment(rawValue: attributes?["halign"] ?? "") ?? .left,
            verticalAlignment: VerticalAlignment(rawValue: attributes?["valign"] ?? "") ?? .top
        )
    }
}
