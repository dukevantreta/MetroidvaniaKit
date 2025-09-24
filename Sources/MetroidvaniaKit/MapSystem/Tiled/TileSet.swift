extension Tiled {
    // TODO: Missing properties
    struct TileSet {
        let firstGID: String?
        let source: String? // references a .tsx file, together w/ GID
        let name: String?
        let tileWidth: Int?
        let tileHeight: Int?
        let spacing: Int?
        let margin: Int?
        let tileCount: Int?
        let columns: Int?
        let objectAlignment: String? // Valid values are unspecified, topleft, top, topright, left, center, right, bottomleft, bottom and bottomright. The default value is unspecified, for compatibility reasons. When unspecified, tile objects use bottomleft in orthogonal mode and bottom in isometric mode. (since 1.4)
        let tileRenderSize: String? // tile, grid
//        let fillMode: String
        
        // Can contain at most one: <image>, <tileoffset>, <grid> (since 1.0), <properties>, <terraintypes>, <wangsets> (since 1.1), <transformations> (since 1.5)
        
//        let tiles: [Tile]
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
            spacing: attributes?["spacing"]?.asInt(),
            margin: attributes?["margin"]?.asInt(),
            tileCount: attributes?["tilecount"]?.asInt(),
            columns: attributes?["columns"]?.asInt(),
            objectAlignment: attributes?["objectalignment"],
            tileRenderSize: attributes?["tilerendersize"]
        )
    }
}
