extension Tiled {

    struct Tile {

        struct Animation {
            struct Frame {
                let tileID: Int
                let duration: Int
            }
            var frames: [Frame]
        }

        let id: Int
        let type: String
        let probability: Int
        let x: Int
        let y: Int
        let width: Int?
        let height: Int?
        var image: Image?
        var objectGroup: ObjectGroup?
        var animation: Animation?
        var properties: [Property]
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
                animation = try Tiled.Tile.Animation(from: child)
            }
        }
    }
}

extension Tiled.Tile.Animation: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.animation)
        self.init(frames: [])
        for child in xml.children {
            frames.append(try Tiled.Tile.Animation.Frame(from: child))
        }
    }
}

extension Tiled.Tile.Animation.Frame: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.frame)
        let attributes = xml.attributes
        self.init(
            tileID: attributes?["tileid"]?.asInt() ?? 0,
            duration: attributes?["duration"]?.asInt() ?? 0
        )
    }
}
