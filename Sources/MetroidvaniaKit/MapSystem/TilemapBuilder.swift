import SwiftGodot

class TilemapBuilder {
    
    func create(sourceFile: String) {
        
    }
}

fileprivate extension String {
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

extension Tiled.Map: CustomDebugStringConvertible {
    
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

class Tiled {
    
    static func parseMap(from xmlNode: XML.Element) -> Tiled.Map? {
        guard xmlNode.name == "map", let attributes = xmlNode.attributes else {
            GD.pushError("PARSING MAP ERROR")
            return nil
        }
        // FIXME: check required properties instead of force-unwrapping
        var map = Map(
            version: attributes["version"]!,
            tiledVersion: attributes["tiledversion"],
            orientation: Map.Orientation(rawValue: attributes["orientation"] ?? "") ?? .orthogonal,
            renderOrder: Map.RenderOrder(rawValue: attributes["renderorder"] ?? "") ?? .rightDown,
            width: attributes["width"]?.asInt() ?? 0,
            height: attributes["height"]?.asInt() ?? 0,
            tileWidth: attributes["tilewidth"]?.asInt() ?? 0,
            tileHeight: attributes["tileheight"]?.asInt() ?? 0,
            parallaxOriginX: attributes["parallaxoriginx"]?.asInt() ?? 0,
            parallaxOriginY: attributes["parallaxoriginy"]?.asInt() ?? 0,
            backgroundColor: attributes["backgroundcolor"],
            nextLayerID: attributes["nextlayerid"]?.asInt() ?? 0,
            nextObjectID: attributes["nextobjectid"]?.asInt() ?? 0,
            isInfinite: attributes["infinite"] == "1", 
            layers: []
        )
        for child in xmlNode.children {
            if child.name == "layer" {
                if let layer = parseLayer(from: child) {
                    map.layers.append(layer)
                }
            }
        }
        return map
    }
    
    static func parseLayer(from xmlNode: XML.Element) -> Tiled.Layer? {
        guard xmlNode.name == "layer", let attributes = xmlNode.attributes else {
            GD.pushError("PARSE LAYER ERROR")
            return nil
        }
        var layer = Layer(
            id: attributes["id"]?.asInt() ?? 0,
            name: attributes["name"] ?? "",
            width: attributes["width"]?.asInt() ?? 0,
            height: attributes["height"]?.asInt() ?? 0,
            opacity: attributes["opacity"]?.asDouble() ?? 1.0,
            isVisible: attributes["visible"]?.asBool() ?? true,
            tintColor: attributes["tintcolor"],
            offsetX: attributes["offsetx"]?.asInt() ?? 0,
            offsetY: attributes["offsety"]?.asInt() ?? 0,
            parallaxX: attributes["parallaxx"]?.asDouble() ?? 1.0,
            parallaxY: attributes["parallaxy"]?.asDouble() ?? 1.0,
            data: nil
        )
        for child in xmlNode.children {
            if child.name == "data" {
                layer.data = parseData(from: child)
            }
        }
        return layer
    }
    
    static func parseData(from xmlNode: XML.Element) -> Tiled.Layer.Data? {
        guard xmlNode.name == "data", let attributes = xmlNode.attributes else {
            GD.pushError("PARSE DATA ERROR")
            return nil
        }
        let data = Layer.Data(
            text: xmlNode.text,
            encoding: attributes["encoding"],
            compression: attributes["compression"]
        )
        return data
    }

    // https://doc.mapeditor.org/en/stable/reference/tmx-map-format/
//    The tilesets used by the map should always be listed before the layers.
//
//    Can contain at most one: <properties>, <editorsettings> (since 1.3)
//
//    Can contain any number: <tileset>, <layer>, <objectgroup>, <imagelayer>, <group> (since 1.0)
    
    // TODO: hex map properties
    struct Map {
        
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
        
//        var tilesets: []
        var layers: [Layer]
//        var imageLayers: []
//        var objectGroups: []
//        var groups: []
    }
    
    struct EditorSettings {}
    
    // TODO: Missing properties
    struct TileSet {
        let firstGID: String?
        let source: String? // references a .tsx file, together w/ GID
        let name: String
        let tileWidth: Int
        let tileHeight: Int
        let spacing: Int
        let margin: Int
        let tileCount: Int
        let columns: Int
        let objectAlignment: String // Valid values are unspecified, topleft, top, topright, left, center, right, bottomleft, bottom and bottomright. The default value is unspecified, for compatibility reasons. When unspecified, tile objects use bottomleft in orthogonal mode and bottom in isometric mode. (since 1.4)
        let tileRenderSize: String // tile, grid
//        let fillMode: String
        
        // Can contain at most one: <image>, <tileoffset>, <grid> (since 1.0), <properties>, <terraintypes>, <wangsets> (since 1.1), <transformations> (since 1.5)
        
//        let tiles: [Tile]
    }
    
    
    
    struct Layer {
        
        struct Data {
            
            enum Encoding: String {
                case csv
                case base64
            }
            
            enum Compression: String {
                case gzip
                case zlib
                case zstd
            }
            
            var text: String?
            var encoding: String?
            var compression: String?
//            var encoding: Encoding?
//            var compression: Compression?
//            var tiles: [] // if no compression (is it even used?)
//            var chunks: [] // for infinite maps
        }
        
        let id: Int
        let name: String
        let width: Int
        let height: Int
        let opacity: Double?
        let isVisible: Bool?
        let tintColor: String?
        let offsetX: Int?
        let offsetY: Int?
        let parallaxX: Double?
        let parallaxY: Double?
//        let x: Int = 0
//        let y: Int = 0
//        var properties: ?
        var data: Data?
    }
    
    struct ObjectGroup {
        let id: Int
        let name: String
        let color: String?
        let opacity: Double?
        let isVisible: Bool?
        let tintColor: String?
        let offsetX: Int?
        let offsetY: Int?
        let parallaxX: Double?
        let parallaxY: Double?
        let drawOrder: String? // index, topdown
//        let width: Int
//        let height: Int
        
//        var properties: ?
//        var objects: []
    }
    
    struct Object {
        let id: Int
        let name: String
        let type: String
        let x: Int
        let y: Int
        let width: Int
        let height: Int
        let rotation: Double // degrees
        let gid: Int?
        let isVisible: Bool
//        let template: ?
        
//        var properties: ?
        // Can contain at most one: <properties>, <ellipse> (since 0.9), <point> (since 1.1), <polygon>, <polyline>, <text> (since 1.0)
    }
    
//    struct ImageLayer {}
    
    struct Group {
        let id: Int
        let name: String
        let offsetX: Int?
        let offsetY: Int?
        let parallaxX: Double?
        let parallaxY: Double?
        let opacity: Double?
        let isVisible: Bool
        let tintColor: String?
        
        let layers: [Layer]
        let objectGroups: [ObjectGroup]
//        let imageLayers: []
        let groups: [Group]
    }
    
    struct Property {
        let name: String
        let type: String // Can be string (default), int, float, bool, color, file, object or class (since 0.16, with color and file added in 0.17, object added in 1.4 and class added in 1.8).
        let value: String
        let propertyType: String?
    }
    
    
}
