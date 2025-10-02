extension Tiled {
    
    struct Image {
        let format: String?
        let source: String?
        let width: Int?
        let height: Int?
        let transparentColor: String?
        var data: Data?
    }
}

extension Tiled.Image: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.image)
        let attributes = xml.attributes
        self.init(
            format: attributes?["format"],
            source: attributes?["source"],
            width: attributes?["width"]?.asInt() ?? 0,
            height: attributes?["height"]?.asInt() ?? 0,
            transparentColor: attributes?["trans"]
        )
        for child in xml.children {
            if child.name == "data" {
                self.data = try Tiled.Data(from: child)
            }
        }
    }
}