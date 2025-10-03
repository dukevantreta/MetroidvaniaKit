extension Tiled {

    struct Layer {
        
        let id: IntType
        let name: String
        let `class`: String
        let width: IntType
        let height: IntType
        let opacity: Double
        let visible: IntType
        let tintColor: String?
        let offsetX: Double
        let offsetY: Double
        let parallaxX: Double
        let parallaxY: Double
        var data: Data?
        var properties: [Property]
        
        var isVisible: Bool {
            visible != 0
        }
    }
}

extension Tiled.Layer: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.layer)
        let attributes = xml.attributes
        self.init(
            id: attributes?["id"]?.asInt() ?? 0,
            name: attributes?["name"] ?? "",
            class: attributes?["class"] ?? "",
            width: attributes?["width"]?.asInt32() ?? 0,
            height: attributes?["height"]?.asInt32() ?? 0,
            opacity: attributes?["opacity"]?.asDouble() ?? 1.0,
            visible: attributes?["visible"]?.asInt32() ?? 1,
            tintColor: attributes?["tintcolor"],
            offsetX: attributes?["offsetx"]?.asDouble() ?? 0.0,
            offsetY: attributes?["offsety"]?.asDouble() ?? 0.0,
            parallaxX: attributes?["parallaxx"]?.asDouble() ?? 1.0,
            parallaxY: attributes?["parallaxy"]?.asDouble() ?? 1.0, 
            data: nil,
            properties: []
        )
        for child in xml.children {
            if child.name == "data" {
                self.data = try Tiled.Data(from: child)
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}


