extension Tiled {

    struct ObjectGroup {

        enum DrawOrder: String {
            case topdown
            case index
        }

        let id: IntType
        let name: String
        let `class`: String
        let color: String?
        let opacity: Double
        let isVisible: Bool
        let tintColor: String?
        let offsetX: Double
        let offsetY: Double
        let parallaxX: Double
        let parallaxY: Double
        let drawOrder: DrawOrder
        var objects: [Object]
        var properties: [Property]
    }
}

extension Tiled.ObjectGroup: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.objectgroup)
        let attributes = xml.attributes
        self.init(
            id: attributes?["id"]?.asInt() ?? 0,
            name: attributes?["name"] ?? "",
            class: attributes?["class"] ?? "",
            color: attributes?["color"],
            opacity: attributes?["opacity"]?.asDouble() ?? 1.0,
            isVisible: attributes?["visible"]?.asBool() ?? true,
            tintColor: attributes?["tintcolor"],
            offsetX: attributes?["offsetx"]?.asDouble() ?? 0.0,
            offsetY: attributes?["offsety"]?.asDouble() ?? 0.0,
            parallaxX: attributes?["parallaxx"]?.asDouble() ?? 1.0,
            parallaxY: attributes?["parallaxy"]?.asDouble() ?? 1.0,
            drawOrder: DrawOrder(rawValue: attributes?["draworder"] ?? "") ?? .topdown,
            objects: [],
            properties: []
        )
        for child in xml.children {
            if child.name == "object" {
                objects.append(try Tiled.Object(from: child))
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}
