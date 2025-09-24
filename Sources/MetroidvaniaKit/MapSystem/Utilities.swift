//

//import Foundation
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

protocol TypeDescribable {
    static var typeDescription: String { get }
    var typeDescription: String { get }
}

extension TypeDescribable {
    static var typeDescription: String {
        return String(describing: self)
    }
    
    var typeDescription: String {
        return type(of: self).typeDescription
    }
}

protocol GodotLogger: TypeDescribable {
    func log(_ message: String)
    func logError(_ message: String)
}

extension GodotLogger {
    func log(_ message: String) {
        GD.print("[\(typeDescription)] \(message)")
    }
    func logError(_ message: String) {
        GD.pushError("[\(typeDescription)] \(message)")
    }
}

extension Node: GodotLogger {}
//extension GodotError

func loadResource<T>(ofType type: T.Type, at path: String) throws -> T where T: Resource {
    guard FileAccess.fileExists(path: path) else {
        throw ImportError.godotError(.errFileNotFound)
    }
    guard let resource = ResourceLoader.load(path: path) else {
        throw ImportError.godotError(.errCantAcquireResource)
    }
    guard let resolvedResource = resource as? T else {
        throw ImportError.godotError(.errCantResolve)
    }
    return resolvedResource
}

func saveResource(_ resource: Resource, path: String) throws {
    let errorCode = ResourceSaver.save(resource: resource, path: path)
    if errorCode != .ok {
        throw ImportError.failedToSaveFile(path, errorCode)
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
