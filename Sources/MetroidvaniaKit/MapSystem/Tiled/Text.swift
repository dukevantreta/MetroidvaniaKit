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
        let pixelSize: IntType
        let wrap: IntType
        let color: String
        let bold: IntType
        let italic: IntType
        let underline: IntType
        let strikeout: IntType
        let kerning: IntType
        let horizontalAlignment: HorizontalAlignment
        let verticalAlignment: VerticalAlignment

        var shouldWrap: Bool {
            wrap != 0
        }
        var isBold: Bool {
            bold != 0
        }
        var isItalic: Bool {
            italic != 0
        }
        var hasUnderline: Bool {
            underline != 0
        }
        var hasStrikeout: Bool {
            strikeout != 0
        }
        var useKerning: Bool {
            kerning != 0
        }
    }
}

extension Tiled.Text: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.text)
        let attributes = xml.attributes
        self.init(
            fontFamily: attributes?["fontfamily"] ?? "sans-serif",
            pixelSize: attributes?["pixelsize"]?.asInt() ?? 16,
            wrap: attributes?["wrap"]?.asInt() ?? 0,
            color: attributes?["color"] ?? "#000000",
            bold: attributes?["bold"]?.asInt() ?? 0,
            italic: attributes?["italic"]?.asInt() ?? 0,
            underline: attributes?["underline"]?.asInt() ?? 0,
            strikeout: attributes?["strikeout"]?.asInt() ?? 0,
            kerning: attributes?["kerning"]?.asInt() ?? 1,
            horizontalAlignment: attributes?["halign"].flatMap { HorizontalAlignment(rawValue: $0) } ?? .left,
            verticalAlignment: attributes?["valign"].flatMap { VerticalAlignment(rawValue: $0) } ?? .top
        )
    }
}
