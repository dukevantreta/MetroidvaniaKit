extension Tiled {
    struct Tile {
        let id: Int
        let type: String
        let probability: Int
        let x: Int
        let y: Int
        let width: Int?
        let height: Int?
        var properties: [Property]
        var image: Image?
        var objectGroup: ObjectGroup?
//        var animation: ?
    }
}

extension Tiled.Tile: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.tile)
        let attributes = xml.attributes
        self.init(
            id: attributes?["id"]?.asInt() ?? 0,
            type: attributes?["type"] ?? "",
            probability: attributes?["probability"]?.asInt() ?? 0,
            x: attributes?["x"]?.asInt() ?? 0,
            y: attributes?["y"]?.asInt() ?? 0,
            width: attributes?["width"]?.asInt(),
            height: attributes?["height"]?.asInt(),
            properties: []
        )
        for child in xml.children {
            if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            } else if child.name == "image" {
                image = try Tiled.Image(from: child)
            } else if child.name == "objectgroup" {
                objectGroup = try Tiled.ObjectGroup(from: child)
            } else if child.name == "animation" {
                //
            }
        }
    }
}
