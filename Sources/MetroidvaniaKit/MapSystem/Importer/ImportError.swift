import SwiftGodot

enum ImportError: Error {
    case unknown
    case layerData(LayerDataErrorReason)
    case unhandledObject
    case failedToSaveFile(_ path: String, GodotError)
    case tileSetNotFound
    case godotError(GodotError)
    case malformedPath(String)
    case unsupportedMapType(Tiled.TileMap.Orientation)
    case noTileSetImageSource
    case undefinedTileSize
    
    enum LayerDataErrorReason {
        case notFound
        case formatNotSupported(String)
        case empty
    }
}
