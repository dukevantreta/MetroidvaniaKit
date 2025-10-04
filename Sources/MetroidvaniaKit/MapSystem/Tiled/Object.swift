extension Tiled {

    struct Object {
        let id: IntType
        let name: String
        let type: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let rotation: Double // degrees
        let gid: UInt32? // When the object has a gid set, then it is represented by the image of the tile with that global ID.
        let visible: IntType
        let template: String?
        var isEllipse = false
        var isPoint = false
        var polygon: Polygon?
        var polyline: Polyline?
        var text: Text?
        var properties: [Property]

        var isVisible: Bool {
            visible != 0
        }
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
            x: attributes?["x"]?.asDouble() ?? 0,
            y: attributes?["y"]?.asDouble() ?? 0,
            width: attributes?["width"]?.asDouble() ?? 0,
            height: attributes?["height"]?.asDouble() ?? 0,
            rotation: attributes?["rotation"]?.asDouble() ?? 0.0,
            gid: attributes?["gid"].flatMap { UInt32($0) },
            visible: attributes?["visible"]?.asInt() ?? 1,
            template: attributes?["template"],
            properties: []
        )
        for child in xml.children {
            if child.name == "ellipse" {
                isEllipse = true
            } else if child.name == "point" {
                isPoint = true
            } else if child.name == "polygon" {
                polygon = try Tiled.Polygon(from: child)
            } else if child.name == "polyline" {
                polyline = try Tiled.Polyline(from: child)
            } else if child.name == "text" {
                text = try Tiled.Text(from: child)
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}

extension Tiled {
    struct Polygon: XMLDecodable {
        
        let points: [(x: Double, y: Double)]
        
        init(from xml: XML.Element) throws {
            try xml.assertType(.polygon)
            let pointString = xml.attributes?["points"] ?? ""
            points = pointString.components(separatedBy: " ").map {
                let xy = $0.components(separatedBy: ",")
                return (Double(xy[0]) ?? 0.0, Double(xy[1]) ?? 0.0)
            }
        }
    }
}

extension Tiled {
    struct Polyline: XMLDecodable {
        
        let points: [(x: Double, y: Double)]
        
        init(from xml: XML.Element) throws {
            try xml.assertType(.polyline)
            let pointString = xml.attributes?["points"] ?? ""
            points = pointString.components(separatedBy: " ").map {
                let xy = $0.components(separatedBy: ",")
                return (Double(xy[0]) ?? 0.0, Double(xy[1]) ?? 0.0)
            }
        }
    }
}