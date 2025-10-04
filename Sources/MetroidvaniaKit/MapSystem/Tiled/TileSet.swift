// TODO: Missing properties
extension Tiled {
    
    /** 
    A representation of a Tiled's tileset data. When loaded from a `.tsx` file, it contains the 
    properties that describes the tileset. When found inside a tile map's `.tmx` file, however, it 
    contains only the `firstGID` and the `source` properties, poiting to an external tileset.
    */
    struct TileSet {

        /**
        Controls the alignment for tile objects. The default value is unspecified, for compatibility reasons. 
        When unspecified, tile objects use `bottomleft` in orthogonal mode and `bottom` in isometric mode.
        */
        enum ObjectAlignment: String {
            case unspecified
            case topleft
            case top
            case topright
            case left
            case center
            case right
            case bottomleft
            case bottom
            case bottonright
        }

        /**
        The size to use when rendering tiles from this tileset on a tile layer. 
        When set to grid, the tile is drawn at the tile grid size of the map.
        */
        enum RenderSize: String {
            case tile
            case grid
        }

        enum FillMode: String {
            case stretch
            case fit = "preserve-aspect-fit"
        }

        /**
        This element is used to specify an offset in pixels, to be applied when drawing a 
        tile from the related tileset. When not present, no offset is applied.
        */
        struct TileOffset {
            let x: IntType
            let y: IntType
        }

        /** 
        This element is only used in case of isometric orientation, and determines 
        how tile overlays for terrain and collision information are rendered.
        */
        struct Grid {
            enum Orientation: String {
                case orthogonal
                case isometric
            }
            let orientation: Orientation
            let width: IntType
            let height: IntType
        }

        /// The first global tile ID of this tileset (this global ID maps to the first tile in this tileset).
        let firstGID: String?
        /// If this tileset is stored in an external TSX (Tile Set XML) file, this attribute refers to that file. That TSX file has the same structure as the <tileset> element described here. (There is the firstgid attribute missing and this source attribute is also not there. These two attributes are kept in the TMX map, since they are map specific.)
        let source: String?
        let name: String?
        let `class`: String
        let tileWidth: IntType?
        let tileHeight: IntType?
        let spacing: IntType
        let margin: IntType
        let tileCount: IntType?
        let columns: IntType?
        let objectAlignment: ObjectAlignment
        let tileRenderSize: RenderSize
        let fillMode: FillMode?
        var image: Image?
        var tileOffset: TileOffset?
        var grid: Grid?
//        var terrainTypes: ?
//        var wangSets: ?
//        var transformations: ?
        var tiles: [Tile]
        var properties: [Property]
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
            class: attributes?["class"] ?? "",
            tileWidth: attributes?["tilewidth"]?.asInt(),
            tileHeight: attributes?["tileheight"]?.asInt(),
            spacing: attributes?["spacing"]?.asInt() ?? 0,
            margin: attributes?["margin"]?.asInt() ?? 0,
            tileCount: attributes?["tilecount"]?.asInt(),
            columns: attributes?["columns"]?.asInt(),
            objectAlignment: attributes?["objectalignment"].flatMap { ObjectAlignment(rawValue: $0) } ?? .unspecified,
            tileRenderSize: attributes?["tilerendersize"].flatMap { RenderSize(rawValue: $0) } ?? .tile,
            fillMode: attributes?["fillmode"].flatMap { FillMode(rawValue: $0) } ?? .stretch,
            image: nil,
            tileOffset: nil,
            grid: nil,
            tiles: [],
            properties: []
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
