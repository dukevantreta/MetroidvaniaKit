// TODO: Missing properties
extension Tiled {
    
    /// A representation of a Tiled's tileset data. When loaded from a .tsx file, it contains the properties that describes the tileset. When found inside a tile map's .tmx file, however, is contains only the `firstGID` and the `source` properties, poiting to an external tileset.
    struct TileSet {
        /// The first global tile ID of this tileset (this global ID maps to the first tile in this tileset).
        let firstGID: String?
        /// If this tileset is stored in an external TSX (Tile Set XML) file, this attribute refers to that file. That TSX file has the same structure as the <tileset> element described here. (There is the firstgid attribute missing and this source attribute is also not there. These two attributes are kept in the TMX map, since they are map specific.)
        let source: String?
        let name: String?
        let tileWidth: Int?
        let tileHeight: Int?
        let spacing: Int32
        let margin: Int32
        let tileCount: Int?
        let columns: Int?
        let objectAlignment: String? // Valid values are unspecified, topleft, top, topright, left, center, right, bottomleft, bottom and bottomright. The default value is unspecified, for compatibility reasons. When unspecified, tile objects use bottomleft in orthogonal mode and bottom in isometric mode. (since 1.4)
        let tileRenderSize: String? // tile, grid
        let fillMode: String?
        
        var properties: [Property]
        // Can contain at most one: <image>, <tileoffset>, <grid> (since 1.0), <properties>, <terraintypes>, <wangsets> (since 1.1), <transformations> (since 1.5)
        var image: Image?
        var tileOffset: TileOffset?
        var grid: Grid?
//        var terrainTypes: ?
//        var wangSets: ?
//        var transformations: ?
        var tiles: [Tile]
    }
}

extension Tiled.TileSet: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.tileset)
        let attributes = xml.attributes
        self.init(
            firstGID: attributes?["firstgid"],
            source: attributes?["source"],
            name: attributes?["name"],
            tileWidth: attributes?["tilewidth"]?.asInt(),
            tileHeight: attributes?["tileheight"]?.asInt(),
            spacing: attributes?["spacing"]?.asInt32() ?? 0,
            margin: attributes?["margin"]?.asInt32() ?? 0,
            tileCount: attributes?["tilecount"]?.asInt(),
            columns: attributes?["columns"]?.asInt(),
            objectAlignment: attributes?["objectalignment"],
            tileRenderSize: attributes?["tilerendersize"],
            fillMode: attributes?["fillmode"], 
            properties: [],
            image: nil,
            tileOffset: nil,
            grid: nil,
            tiles: []
        )
        for child in xml.children {
            if child.name == "tile" {
                tiles.append(try Tiled.Tile(from: child))
            } else if child.name == "image" {
                image = try Tiled.Image(from: child)
            } else if child.name == "tileoffset" {
                tileOffset = try TileOffset(from: child)
            } else if child.name == "grid" {
                grid = try Grid(from: child)
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}

extension Tiled.TileSet {
    struct TileOffset {
        let x: Int
        let y: Int
    }
}

extension Tiled.TileSet.TileOffset: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.tileoffset)
        let attributes = xml.attributes
        self.init(
            x: attributes?["x"]?.asInt() ?? 0,
            y: attributes?["y"]?.asInt() ?? 0
        )
    }
}

extension Tiled.TileSet {
    /// This element is only used in case of isometric orientation, and determines how tile overlays for terrain and collision information are rendered.
    struct Grid {
        enum Orientation: String {
            case orthogonal
            case isometric
        }
        let orientation: Orientation
        let width: Int
        let height: Int
    }
}

extension Tiled.TileSet.Grid: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.grid)
        let attributes = xml.attributes
        self.init(
            orientation: Orientation(rawValue: attributes?["orientation"] ?? "") ?? .orthogonal,
            width: attributes?["width"]?.asInt() ?? 0,
            height: attributes?["height"]?.asInt() ?? 0
        )
    }
}
