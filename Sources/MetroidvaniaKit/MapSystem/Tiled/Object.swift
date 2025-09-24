extension Tiled {
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
        var properties: [Property]
        // Can contain at most one: <properties>, <ellipse> (since 0.9), <point> (since 1.1), <polygon>, <polyline>, <text> (since 1.0)
    }
}

extension Tiled.Object: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.object)
        let attributes = xml.attributes
        self.init(
            id: attributes?["id"]?.asInt() ?? 0,
            name: attributes?["name"] ?? "",
            type: attributes?["type"] ?? "",
            x: attributes?["x"]?.asInt() ?? 0,
            y: attributes?["y"]?.asInt() ?? 0,
            width: attributes?["width"]?.asInt() ?? 0,
            height: attributes?["height"]?.asInt() ?? 0,
            rotation: attributes?["rotation"]?.asDouble() ?? 0.0,
            gid: attributes?["gid"]?.asInt(),
            isVisible: attributes?["visible"]?.asBool() ?? true,
            properties: []
        )
        for child in xml.children {
            if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}
