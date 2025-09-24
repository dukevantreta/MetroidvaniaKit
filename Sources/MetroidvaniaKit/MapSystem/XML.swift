import SwiftGodot

class XML {
    
    enum ParseError: Error {
        
    }
    
    struct Tree {
        let root: Element
    }
    
    class Element {
        
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
    
    private init() {}
    
    // this sh!t is a piece of art
    static func parse(_ sourceFile: String, with xmlParser: XMLParser) -> XML.Tree? {
        let openError = xmlParser.open(file: sourceFile)
        if openError != .ok {
            return nil// error
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
                    GD.print("SOMETHING BAD HAPPENED")
                }
                parseStack.popLast()
            }
        }
        guard let root else {
            return nil // explode()
        }
        return Tree(root: root)
    }
}
