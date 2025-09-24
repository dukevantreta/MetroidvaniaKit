import SwiftGodot

struct XMLTree {
    
}

class XMLNode: CustomStringConvertible {
    
    let name: String
    let attributes: [String: String]?
    var text: String?
    var children: [XMLNode]
    
    internal init(name: String, attributes: [String : String]? = nil, text: String? = nil, children: [XMLNode] = []) {
        self.name = name
        self.attributes = attributes
        self.text = text
        self.children = children
    }
    
    var description: String {
        "[XML] \(name) | has text: \(text?.isEmpty == false) | ATTR: \(attributes)"
    }
}


class XML {
    
    let xmlParser: XMLParser
    
    init() {
        xmlParser = XMLParser()
    }
    
    // this sh!t is a piece of art
    func parse(_ sourceFile: String) {
        let openError = xmlParser.open(file: sourceFile)
        if openError != .ok {
            return // error
        }
        
        var root: XMLNode?
        var stack: [XMLNode] = []
        
        while xmlParser.read() == .ok {
            let type = xmlParser.getNodeType()
            
            if type == .element {
                let name = xmlParser.getNodeName()
                let attributes = xmlParser.getAttributeCount() > 0 ? 
                (0..<xmlParser.getAttributeCount()).reduce(into: [String: String](), {
                    $0[xmlParser.getAttributeName(idx: $1)] = xmlParser.getAttributeValue(idx: $1)
                }) : nil
                let newNode = XMLNode(
                    name: name,
                    attributes: attributes,
                    text: nil,
                    children: []
                )
                if root == nil {
                    root = newNode
                }
                stack.last?.children.append(newNode)
                if !xmlParser.isEmpty() {
                    stack.append(newNode)
                }
            } else if type == .text {
                let text = xmlParser.getNodeData().trimmingCharacters(in: .whitespacesAndNewlines)
                stack.last?.text = text
            } else if type == .elementEnd {
                let name = xmlParser.getNodeName()
                if name != stack.last?.name {
                    GD.print("SOMETHING BAD HAPPENED")
                }
                stack.popLast()
            }
        }
        printNode(root!, level: 0)
        
        // return root
    }
    
    func printNode(_ node: XMLNode, level: Int) {
        var pad = ""
        for _ in 0..<level {
            pad += "    "
        }
        GD.print("\(pad)\(node)")
        for child in node.children {
            printNode(child, level: level + 1)
        }
    }
}

// 1- if type == .text, dont get attributes of that node
// 2- add text to previous node
// 3- nodes are only elements
// 4- empty elements dont have a matching .end


//    IMPORTING: res://test/corridor.tmx
//
//    XML FIRST ELEMENT
//    Type: .none
//    Name:
//    Attributes: 0
//
//    XML SECOND ELEMENT
//    Type: .unknown
//    Name: ?xml version="1.0" encoding="UTF-8"?
//    Attributes: 0

//    PARSED XML:
//    - data: ["encoding": "csv"]
//    - version: 1.10
//    - <data>: ["encoding": "csv"]
//    - height: 15
//    - nextobjectid: 1
//    - tilewidth: 16
//    - tileheight: 16
//    - renderorder: right-down
//    - infinite: 0
//    - width: 100
//    - nextlayerid: 2
//    - orientation: orthogonal
//    - type: map
//    - layer: ["id": "1", "height": "15", "name": "Tile Layer 1", "width": "100"]
//    - tileset: ["firstgid": "1", "source": "../Godot/tilemaps/tilesets/CollisionMask2D.tsx"]
//    - tiledversion: 1.10.2

//    READ CODES -----------------
//    .ok | .unknown
//    .ok | .element -> map | ATTR: 11 | Is empty: false
//    .ok | .element -> tileset | ATTR: 2 | Is empty: true
//    .ok | .element -> layer | ATTR: 4 | Is empty: false
//    .ok | .text -> |==>0 | ATTR: 4 | Is empty: false
//    .ok | .element -> data | ATTR: 1 | Is empty: false
//    .ok | .text -> <BIG STRING>|==>3013 | ATTR: 1 | Is empty: false
//    .ok | .elementEnd -> data | ATTR: 0 | Is empty: false
//    .ok | .elementEnd -> layer | ATTR: 0 | Is empty: false
//    .ok | .elementEnd -> map | ATTR: 0 | Is empty: false
//    .errFileEof | .elementEnd -> map | ATTR: 0 | Is empty: false
