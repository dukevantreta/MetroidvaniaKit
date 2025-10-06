import SwiftGodot
import Foundation

struct World: Codable {
    struct Map: Codable {
        let fileName: String
        let width: Int32
        let height: Int32
        let x: Int32
        let y: Int32
    }
    let maps: [Map]
    let type: String
    let onlyShowAdjacentMaps: Bool
}

extension World {
    
    static func load(from file: String) throws -> World {
        guard let worldData = FileAccess.getFileAsString(path: file).data(using: .ascii) else {
            throw GameError.godotError(.errFileCantRead)
        }
        let world = try JSONDecoder().decode(World.self, from: worldData)
        return world
    }
}
