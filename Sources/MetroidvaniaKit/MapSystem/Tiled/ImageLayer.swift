extension Tiled {

    struct ImageLayer {
        let id: IntType
        let name: String
        let `class`: String
        let offsetX: Double
        let offsetY: Double
        let parallaxX: Double
        let parallaxY: Double
        let opacity: Double
        let isVisible: Bool
        let tintColor: String?
        let repeatX: Bool
        let repeatY: Bool
        var image: Image?
        var properties: [Property]
    }
}

extension Tiled.ImageLayer: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.imagelayer)
        let attributes = xml.attributes
        self.init(
            id: attributes?["id"]?.asInt() ?? 0,
            name: attributes?["name"] ?? "",
            class: attributes?["class"] ?? "",
            offsetX: attributes?["offsetx"]?.asDouble() ?? 0.0,
            offsetY: attributes?["offsety"]?.asDouble() ?? 0.0,
            parallaxX: attributes?["parallaxx"]?.asDouble() ?? 1.0,
            parallaxY: attributes?["parallaxy"]?.asDouble() ?? 1.0,
            opacity: attributes?["opacity"]?.asDouble() ?? 1.0,
            isVisible: attributes?["visible"]?.asBool() ?? true,
            tintColor: attributes?["tintcolor"],
            repeatX: attributes?["repeatx"]?.asBool() ?? false,
            repeatY: attributes?["repeaty"]?.asBool() ?? false,
            image: nil,
            properties: []
        )
        for child in xml.children {
            if child.name == "image" {
                self.image = try Tiled.Image(from: child)
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}