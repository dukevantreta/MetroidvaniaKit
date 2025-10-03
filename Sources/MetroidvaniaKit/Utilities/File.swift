import SwiftGodot
import Foundation

struct File {
    
    enum Error: Swift.Error {
        case notFound(String)
        case invalidEncoding(String.Encoding)
        case noData
        case cannotAcquireResource(String)
        case failedToResolveResource(String)
        case failedToSave(String, GodotError)
    }
    
    let path: String
    let name: String
    let `extension`: String
    let directory: String
    
    init(path: String) {
        var pathComponents = path.components(separatedBy: "/")
        let fileName = pathComponents.removeLast()
        let nameStrings = fileName.components(separatedBy: ".")
        
        self.path = path
        self.name = nameStrings.first ?? ""
        self.extension = nameStrings.last ?? ""
        self.directory = pathComponents.joined(separator: "/")
    }
    
    func getData(_ encoding: String.Encoding) throws(Error) -> Data {
        guard FileAccess.fileExists(path: path) else {
            throw .notFound(path)
        }
        guard let data = FileAccess.getFileAsString(path: path).data(using: encoding) else {
            throw .invalidEncoding(encoding)
        }
        guard !data.isEmpty else {
            throw .noData
        }
        return data
    }

    func loadResource<T>(ofType type: T.Type) throws(Error) -> T where T: Resource {
        guard FileAccess.fileExists(path: path) else {
            throw .notFound(path)
        }
        guard let resource = ResourceLoader.load(path: path) else {
            throw .cannotAcquireResource(path)
        }
        guard let resolvedResource = resource as? T else {
            throw .failedToResolveResource(path)
        }
        return resolvedResource
    }

    func saveResource(_ resource: Resource) throws(Error) {
        let errorCode = ResourceSaver.save(resource: resource, path: path)
        if errorCode != .ok {
            throw .failedToSave(path, errorCode)
        }
    }
}