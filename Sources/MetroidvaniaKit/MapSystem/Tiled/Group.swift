extension Tiled {

    struct Group {
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
        var layers: [Layer]
        var imageLayers: [ImageLayer]
        var objectGroups: [ObjectGroup]
        var groups: [Group]
        var properties: [Property]

        var isVisible: Bool {
            visible != 0
        }
    }
}

extension Tiled.Group: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.group)
        let attributes = xml.attributes
        self.init(
            id: attributes?["id"]?.asInt() ?? 0,
            name: attributes?["name"] ?? "",
            class: attributes?["class"] ?? "",
            offsetX: attributes?["offsetx"]?.asDouble() ?? 0,
            offsetY: attributes?["offsety"]?.asDouble() ?? 0,
            parallaxX: attributes?["parallaxx"]?.asDouble() ?? 1.0,
            parallaxY: attributes?["parallaxy"]?.asDouble() ?? 1.0,
            opacity: attributes?["opacity"]?.asDouble() ?? 1.0,
            visible: attributes?["visible"]?.asInt() ?? 1,
            tintColor: attributes?["tintcolor"],
            layers: [],
            imageLayers: [],
            objectGroups: [],
            groups: [],
            properties: []
        )
        for child in xml.children {
            if child.name == "layer" {
                layers.append(try Tiled.Layer(from: child))
            } else if child.name == "imagelayer" {
                imageLayers.append(try Tiled.ImageLayer(from: child))
            } else if child.name == "objectgroup" {
                objectGroups.append(try Tiled.ObjectGroup(from: child))
            } else if child.name == "group" {
                groups.append(try Tiled.Group(from: child))
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}
