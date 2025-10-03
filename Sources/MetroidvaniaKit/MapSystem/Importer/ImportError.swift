import SwiftGodot

enum ImportError: Error {
    case fatal // should never happen, is a programmer error
    case fileError(File.Error)
    case layerData(LayerDataErrorReason)
    case undefinedTileSize
    case tileSetNotFound(String)
    case failedToSaveFile(_ path: String, GodotError)
    case godotError(GodotError)
    
    enum LayerDataErrorReason {
        case notFound
        case formatNotSupported(String)
        case empty
    }
}
