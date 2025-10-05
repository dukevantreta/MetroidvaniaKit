extension Tiled {

    struct ImageLayer: Layer {
        let id: IntType
        let name: String
        let `class`: String
        let offsetX: Double
        let offsetY: Double
        let parallaxX: Double
        let parallaxY: Double
        let opacity: Double
        let visible: IntType
        let tintColor: String?
        let repeatX: IntType
        let repeatY: IntType
        var image: Image?
        var properties: [Property]

        var isVisible: Bool {
            visible != 0
        }
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
            visible: attributes?["visible"]?.asInt() ?? 1,
            tintColor: attributes?["tintcolor"],
            repeatX: attributes?["repeatx"]?.asInt() ?? 0,
            repeatY: attributes?["repeaty"]?.asInt() ?? 0,
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