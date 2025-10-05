extension Tiled {

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
        let `class`: String
        let orientation: Orientation
        let renderOrder: RenderOrder
        let width: IntType
        let height: IntType
        let tileWidth: IntType
        let tileHeight: IntType
        let parallaxOriginX: IntType
        let parallaxOriginY: IntType
        let backgroundColor: String?
        let nextLayerID: IntType
        let nextObjectID: IntType
        let isInfinite: Bool
        var tilesets: [TileSet]
        var layers: [Layer]
        var properties: [Property]
    }
}

extension Tiled.TileMap: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.map)
        let attributes = xml.attributes
        self.init(
            version: attributes?["version"] ?? "",
            tiledVersion: attributes?["tiledversion"],
            class: attributes?["class"] ?? "",
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
            properties: []
        )
        for child in xml.children {
            if child.name == "layer" {
                layers.append(try Tiled.TileLayer(from: child))
            } else if child.name == "imagelayer" {
                layers.append(try Tiled.ImageLayer(from: child))
            } else if child.name == "objectgroup" {
                layers.append(try Tiled.ObjectGroup(from: child))
            } else if child.name == "group" {
                layers.append(try Tiled.Group(from: child))
            } else if child.name == "tileset" {
                tilesets.append(try Tiled.TileSet(from: child))
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
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
