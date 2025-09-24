extension Tiled {
    struct ObjectGroup {
        let id: Int
        let name: String
        let color: String?
        let opacity: Double
        let isVisible: Bool
        let tintColor: String?
        let offsetX: Int
        let offsetY: Int
        let parallaxX: Double
        let parallaxY: Double
        let drawOrder: String? // index, topdown
        var properties: [Property]
        var objects: [Object]
    }
}

extension Tiled.ObjectGroup: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.objectgroup)
        let attributes = xml.attributes
        self.init(
            id: attributes?["id"]?.asInt() ?? 0,
            name: attributes?["name"] ?? "",
            color: attributes?["color"],
            opacity: attributes?["opacity"]?.asDouble() ?? 1.0,
            isVisible: attributes?["visible"]?.asBool() ?? true,
            tintColor: attributes?["tintcolor"],
            offsetX: attributes?["offsetx"]?.asInt() ?? 0,
            offsetY: attributes?["offsety"]?.asInt() ?? 0,
            parallaxX: attributes?["parallaxx"]?.asDouble() ?? 1.0,
            parallaxY: attributes?["parallaxy"]?.asDouble() ?? 1.0,
            drawOrder: attributes?["draworder"],
            properties: [],
            objects: []
        )
        for child in xml.children {
            if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            } else if child.name == "object" {
                objects.append(try Tiled.Object(from: child))
            }
        }
    }
}
