import SwiftGodot

protocol XMLDecodable {
    init(from xml: XML.Element) throws
}

enum XML {
    
    enum ParseError: Error {
        case fileOpenError(Error)
        case dataCorruped
        case noData
    }
    
    struct Tree {
        let root: Element
    }
    
    final class Element {
        
        let name: String
        let attributes: [String: String]?
        var text: String?
        var children: [Element]
        
        internal init(
            name: String,
            attributes: [String : String]? = nil,
            text: String? = nil,
            children: [Element] = []) 
        {
            self.name = name
            self.attributes = attributes
            self.text = text
            self.children = children
        }
    }
    
    // this sh!t is a piece of art
    static func parse(_ sourceFile: String, with xmlParser: XMLParser) throws(XML.ParseError) -> XML.Tree {
        let openError = xmlParser.open(file: sourceFile)
        if openError != .ok {
            throw .fileOpenError(openError)
        }
        
        var root: XML.Element?
        var parseStack: [XML.Element] = []
        
        while xmlParser.read() == .ok {
            let type = xmlParser.getNodeType()
            
            if type == .element {
                let name = xmlParser.getNodeName()
                let attributes = xmlParser.getAttributeCount() > 0 ? 
                (0..<xmlParser.getAttributeCount()).reduce(into: [String: String](), {
                    $0[xmlParser.getAttributeName(idx: $1)] = xmlParser.getAttributeValue(idx: $1)
                }) : nil
                let newNode = XML.Element(
                    name: name,
                    attributes: attributes
                )
                if root == nil {
                    root = newNode
                }
                parseStack.last?.children.append(newNode)
                if !xmlParser.isEmpty() {
                    parseStack.append(newNode)
                }
            } else if type == .text {
                let text = xmlParser.getNodeData().trimmingCharacters(in: .whitespacesAndNewlines)
                parseStack.last?.text = text
            } else if type == .elementEnd {
                let name = xmlParser.getNodeName()
                if name != parseStack.last?.name {
                    throw .dataCorruped
                }
                _ = parseStack.popLast()
            }
        }
        guard let root else {
            throw .noData
        }
        return Tree(root: root)
    }
}

extension XML.Element: CustomStringConvertible {
    var description: String {
        "<[XML] \(name) | Text: \(text ?? "nil") | Attributes: \(attributes ?? [:])>"
    }
}

extension XML.Element {
    /// Recursively prints the XML tree to the console, to help debugging.
    func printTree(level: Int = 0) {
        var pad = ""
        for _ in 0..<level {
            pad += "    "
        }
        GD.print("\(pad)\(self)")
        for child in children {
            child.printTree(level: level + 1)
        }
    }
}