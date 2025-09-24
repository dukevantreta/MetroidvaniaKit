extension Tiled {
    struct Property {
        let name: String
        let type: String? // Can be string (default), int, float, bool, color, file, object or class (since 0.16, with color and file added in 0.17, object added in 1.4 and class added in 1.8).
        let value: String? // (default string is “”, default number is 0, default boolean is “false”, default color is #00000000, default file is “.” (the current file’s parent directory))
        let customType: String?
    }
}

extension Tiled.Property: XMLDecodable {
    init(from xml: XML.Element) throws {
        try xml .assertType(.property)
        let attributes = xml.attributes
        self.init(
            name: attributes?["name"] ?? "",
            type: attributes?["type"],
            value: attributes?["value"],
            customType: attributes?["propertytype"]
        )
    }
}
