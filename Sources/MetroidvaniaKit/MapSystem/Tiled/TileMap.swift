extension Tiled {
    
    // TODO: hex map properties
    struct TileMap {
        
        enum Orientation: String {
            case orthogonal
            case isometric
            case staggered
            case hexagonal
        }
        
        enum RenderOrder: String {
            case rightDown = "right-down"
            case rightUp = "right-up"
            case leftDown = "left-down"
            case leftUp = "left-up"
        }
        
        let version: String
        let tiledVersion: String?
        let orientation: Orientation
        let renderOrder: RenderOrder
        let width: Int
        let height: Int
        let tileWidth: Int
        let tileHeight: Int
        let parallaxOriginX: Int
        let parallaxOriginY: Int
        let backgroundColor: String?
        let nextLayerID: Int
        let nextObjectID: Int
        let isInfinite: Bool
//        var editorSettings: ? // not needed?
//        var properties: ?
        
        var tilesets: [TileSet]
        var layers: [Layer]
//        var imageLayers: []
        var objectGroups: [ObjectGroup]
        var groups: [Group]
    }
}

extension Tiled.TileMap: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.map)
        let attributes = xml.attributes
        // FIXME: check required properties instead of force-unwrapping
        self.init(
            version: attributes!["version"]!,
            tiledVersion: attributes?["tiledversion"],
            orientation: Orientation(rawValue: attributes?["orientation"] ?? "") ?? .orthogonal,
            renderOrder: RenderOrder(rawValue: attributes?["renderorder"] ?? "") ?? .rightDown,
            width: attributes?["width"]?.asInt() ?? 0,
            height: attributes?["height"]?.asInt() ?? 0,
            tileWidth: attributes?["tilewidth"]?.asInt() ?? 0,
            tileHeight: attributes?["tileheight"]?.asInt() ?? 0,
            parallaxOriginX: attributes?["parallaxoriginx"]?.asInt() ?? 0,
            parallaxOriginY: attributes?["parallaxoriginy"]?.asInt() ?? 0,
            backgroundColor: attributes?["backgroundcolor"],
            nextLayerID: attributes?["nextlayerid"]?.asInt() ?? 0,
            nextObjectID: attributes?["nextobjectid"]?.asInt() ?? 0,
            isInfinite: attributes?["infinite"] == "1",
            tilesets: [],
            layers: [],
            objectGroups: [],
            groups: []
        )
        for child in xml.children {
            if child.name == "layer" {
                layers.append(try Tiled.Layer(from: child))
            } else if child.name == "tileset" {
                tilesets.append(try Tiled.TileSet(from: child))
            } else if child.name == "objectgroup" {
                objectGroups.append(try Tiled.ObjectGroup(from: child))
            } else if child.name == "group" {
                groups.append(try Tiled.Group(from: child))
            }
        }
    }
}

extension Tiled.TileMap: CustomDebugStringConvertible {
    
    var debugDescription: String {
        var result = ""
        let mirror = Mirror(reflecting: self)
        for (label, value) in mirror.children {
            if let label {
                result += "\t\(label): \(value)\n"
            }
        }
        return result
    }
}
