import SwiftGodot

func saveResource(_ resource: Resource, path: String) throws {
    let errorCode = ResourceSaver.save(resource: resource, path: path)
    if errorCode != .ok {
        throw ImportError.failedToSaveFile(path, errorCode)
    }
}
