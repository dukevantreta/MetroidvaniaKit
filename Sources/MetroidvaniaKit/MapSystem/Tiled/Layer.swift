extension Tiled {

    struct Layer {
        
        struct Data {
            enum Encoding: String {
                case csv
                case base64
            }
            enum Compression: String {
                case gzip
                case zlib
                case zstd
            }
            var text: String?
            var encoding: String?
            var compression: String?
//            var encoding: Encoding?
//            var compression: Compression?
//            var tiles: [] // if no compression (is it even used?)
//            var chunks: [] // for infinite maps
        }
        
        let id: Int
        let name: String
        let width: Int
        let height: Int
        let opacity: Double?
        let isVisible: Bool?
        let tintColor: String?
        let offsetX: Int?
        let offsetY: Int?
        let parallaxX: Double?
        let parallaxY: Double?
//        let x: Int = 0
//        let y: Int = 0
        var properties: [Property]
        var data: Data?
        
        func getTileData() throws -> String {
            guard let data else {
                throw ImportError.layerData(.notFound)
            }
            guard data.encoding == "csv" else {
                throw ImportError.layerData(.formatNotSupported(data.encoding ?? "unknown"))
            }
            guard let text = data.text, !text.isEmpty else {
                throw ImportError.layerData(.empty)
            }
            return text
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
            width: attributes?["width"]?.asInt() ?? 0,
            height: attributes?["height"]?.asInt() ?? 0,
            opacity: attributes?["opacity"]?.asDouble() ?? 1.0,
            isVisible: attributes?["visible"]?.asBool() ?? true,
            tintColor: attributes?["tintcolor"],
            offsetX: attributes?["offsetx"]?.asInt() ?? 0,
            offsetY: attributes?["offsety"]?.asInt() ?? 0,
            parallaxX: attributes?["parallaxx"]?.asDouble() ?? 1.0,
            parallaxY: attributes?["parallaxy"]?.asDouble() ?? 1.0, 
            properties: [],
            data: nil
        )
        for child in xml.children {
            if child.name == "data" {
                self.data = try Data(from: child)
            } else if child.name == "properties" {
                for subchild in child.children {
                    properties.append(try Tiled.Property(from: subchild))
                }
            }
        }
    }
}

extension Tiled.Layer.Data: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.data)
        let attributes = xml.attributes
        self.init(
            text: xml.text,
            encoding: attributes?["encoding"],
            compression: attributes?["compression"]
        )
    }
}
