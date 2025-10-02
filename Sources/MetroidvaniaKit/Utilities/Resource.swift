import SwiftGodot

func loadResource<T>(ofType type: T.Type, at path: String) throws(GodotError) -> T where T: Resource {
    guard FileAccess.fileExists(path: path) else {
        throw .errFileNotFound
    }
    guard let resource = ResourceLoader.load(path: path) else {
        throw .errCantAcquireResource
    }
    guard let resolvedResource = resource as? T else {
        throw .errCantResolve
    }
    return resolvedResource
}

func saveResource(_ resource: Resource, path: String) throws {
    let errorCode = ResourceSaver.save(resource: resource, path: path)
    if errorCode != .ok {
        throw ImportError.failedToSaveFile(path, errorCode)
    }
}
