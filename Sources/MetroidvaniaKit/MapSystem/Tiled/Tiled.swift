protocol XMLDecodable {
    init(from xml: XML.Element) throws
}

extension XML.Element {
    var type: Tiled.XMLElementType {
        Tiled.XMLElementType(rawValue: name) ?? .unknown
    }
    
    func assertType(_ expectedType: Tiled.XMLElementType) throws {
        guard self.type == expectedType else {
            throw Tiled.ParseError(expected: expectedType, found: self.type)
        }
    }
}

extension String {
    func asInt() -> Int? {
        Int(self)
    }
    
    func asDouble() -> Double? {
        Double(self)
    }
    
    func asBool() -> Bool? {
        if self == "true" {
            return true
        } else if self == "false" {
            return false
        }
        return nil
    }
}

/*
 All documentation is copied from Tiled map editor reference docs.
 
 TMX Map Format documentation can be found at: https://doc.mapeditor.org/en/stable/reference/tmx-map-format/
 */
class Tiled {
    
    enum XMLElementType: String {
        case map
        case tileset
        case layer
        case data
        case object
        case objectgroup
        case group
        case property
        case tileoffset
        case grid
        case image
        case tile
        case unknown
    }
    
    struct ParseError: Error {
        let expected: XMLElementType
        let found: XMLElementType
    }

    // https://doc.mapeditor.org/en/stable/reference/tmx-map-format/
//    The tilesets used by the map should always be listed before the layers.
//    Can contain at most one: <properties>, <editorsettings> (since 1.3)
//    Can contain any number: <tileset>, <layer>, <objectgroup>, <imagelayer>, <group> (since 1.0)
    
    struct EditorSettings {}
    
//    struct ImageLayer {}
}

extension Tiled {
    struct Image {
        let source: String?
        let width: Int?
        let height: Int?
        let transparentColor: String? // #FF00FF
    }
}

extension Tiled.Image: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.image)
        let attributes = xml.attributes
        self.init(
            source: attributes?["source"],
            width: attributes?["width"]?.asInt() ?? 0,
            height: attributes?["height"]?.asInt() ?? 0,
            transparentColor: attributes?["trans"]
        )
    }
}
