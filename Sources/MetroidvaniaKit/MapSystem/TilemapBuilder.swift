import SwiftGodot

class TilemapBuilder {
    
    func create(sourceFile: String) {
        
    }
}

class DictionaryBuilder {
    
    func getDictionary(sourceFile: String) {
        
    }
}

class XMLDictionary {
    
    let xml: XMLControl
    
    init() {
        xml = XMLControl()
    }
    
    func create(sourceFile: String) -> [String: Any]? {
        let err = xml.open(sourceFile: sourceFile)
        if err != .ok {
            return nil
        }
        
        var currentElement = xml.nextElement()
        var baseAttributes = xml.getAttributes()
        var currentDictionary: [String: Any] = baseAttributes
        
        currentDictionary["type"] = currentElement
        let isMap = currentElement == "map"
        
        var baseElement = currentElement
        
        var error = GodotError.ok
        while error == .ok && (!xml.isEnd() || currentElement != baseElement) {
            currentElement = xml.nextElement()
            
            if currentElement == nil {
                error = .errParseError
                break
            }
            if xml.isEnd() {
                continue
            }
            var cAttributes = xml.getAttributes()
            
            if xml.isEmpty() {
                currentDictionary[currentElement!] = cAttributes
            } else {
                currentDictionary[currentElement!] = cAttributes
            }
        }
        
        return currentDictionary
    }
    
//    func insertAttributes(_ attr: [String: String], on dict: [String: String]) {
//        for (key, value) in attr {
//
//        }
//    }
}

class XMLControl {
    
    var parser: XMLParser
    
    init() {
        parser = XMLParser()
    }
    
    func open(sourceFile: String) -> GodotError {
        parser.open(file: sourceFile)
    }
    
    func nextElement() -> String? {
        let err = parseOn()
        if err != .ok {
            return nil
        }
        
        if parser.getNodeType() == .text {
            let text = parser.getNodeData()
            print("NODE DATA: *\(text)*")
            if text.count > 0 {
                return "<data>"
            }
        }
        
        while parser.getNodeType() != .element && parser.getNodeType() != .elementEnd {
            let err2 = parseOn()
            if err != .ok {
                return nil
            }
        }
        
        return parser.getNodeName()
    }
    
    func isEnd() -> Bool {
        parser.getNodeType() == .elementEnd
    }
    
    func isEmpty() -> Bool {
        parser.isEmpty()
    }
    
    func getData() -> String {
        parser.getNodeData()
    }
    
    func getAttributes() -> [String: String] {
        var dict: [String: String] = [:]
        for i in 0..<parser.getAttributeCount() {
            let name = parser.getAttributeName(idx: i)
            let value = parser.getAttributeValue(idx: i)
            dict[name] = value
        }
        return dict
    }
    
    func parseOn() -> GodotError {
        let err = parser.read()
        if err != .ok {
            GD.print("Error parsing file")
        }
        return err
    }
}
