import SwiftGodot

struct File {
    
    enum Error: Swift.Error {
        case malformedFileName(String)
    }
    
    let path: String
    let name: String
    let `extension`: String
    let directory: String
    
    init(path: String) throws {
        var pathComponents = path.components(separatedBy: "/")
        let fileName = pathComponents.removeLast()
        let nameStrings = fileName.components(separatedBy: ".")
        
        self.path = path
        self.name = try nameStrings.first ??? Error.malformedFileName(fileName)
        self.extension = try nameStrings.last ??? Error.malformedFileName(fileName)
        self.directory = pathComponents.joined(separator: "/")
    }
    
    var exists: Bool {
        FileAccess.fileExists(path: self.path)
    }
}

func getFileName(from path: String) throws -> String {
    guard let name = path
        .components(separatedBy: "/").last?
        .components(separatedBy: ".").first
    else {
        throw ImportError.malformedPath(path)
    }
    return name
}
