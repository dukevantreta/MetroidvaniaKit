extension Tiled {

    /**
    Contains the actual tile layer data or embedded image data.
    Unencoded tile data is not supported. Only losers do that.
    */
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

        struct Chunk {
            let x: IntType
            let y: IntType
            let width: IntType
            let height: IntType
            var text: String?
        }

        let text: String?
        let encoding: Encoding?
        let compression: Compression?
        var chunks: [Chunk] // used on infinite maps
    }
}

extension Tiled.Data: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.data)
        let attributes = xml.attributes
        self.init(
            text: xml.text,
            encoding: attributes?["encoding"].flatMap { Encoding(rawValue: $0) },
            compression: attributes?["compression"].flatMap { Compression(rawValue: $0) },
            chunks: []
        )
        for child in xml.children {
            if child.name == "chunk" {
                self.chunks.append(try Tiled.Data.Chunk(from: child))
            }
        }
    }
}
extension Tiled.Data.Chunk: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml.assertType(.chunk)
        let attributes = xml.attributes
        self.init(
            x: attributes?["x"]?.asInt() ?? 0,
            y: attributes?["y"]?.asInt() ?? 0,
            width: attributes?["width"]?.asInt() ?? 0,
            height: attributes?["height"]?.asInt() ?? 0,
            text: xml.text
        )
    }
}