import SwiftGodot

infix operator ???

public func ???<T,E>(optional: T?, error: @autoclosure () -> E) throws(E) -> T {
    guard let value = optional else {
        throw error()
    }
    return value
}

extension Vector2 {
    public static func *(lhs: Vector2, rhs: Float) -> Vector2 {
        return Vector2(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

enum GameError: Error {
    case failedToLoadScene
    case typeMismatch
    case godotError(GodotError)
}

// Using this prevents node memory leak in case of errors
extension PackedScene {
    func instantiate<T>(file: String = #file, line: Int = #line) throws(GameError) -> T where T: Node {
        guard let instance = self.instantiate() else {
            logError("Instantiation failed for scene: \(self.resourcePath)")
            throw .failedToLoadScene
        }
        guard let typedInstance = instance as? T else {
            let filename = file.split(separator: "/").last ?? ""
            logError("\(filename):\(line) > Scene \(self.resourcePath) cannot be cast to expected type \(T.typeDescription). Freeing node memory...")
            instance.queueFree()
            throw .typeMismatch
        }
        return typedInstance
    }
}

extension Vector2 {
    init(x: Int, y: Int) {
        self.init(x: Float(x), y: Float(y))
    }
    
    init(x: Int32, y: Int32) {
        self.init(x: Float(x), y: Float(y))
    }
    
    init(x: Double, y: Double) {
        self.init(x: Float(x), y: Float(y))
    }
}

extension Node {
    func setName(_ name: String) {
        self.name = StringName(name)
    }
}

extension TileSet {
    
    func getColumnCount(sourceId: Int32) -> Int32 {
        guard let source = getSource(sourceId: sourceId) as? TileSetAtlasSource else {
            return -1
        }
        return source.getAtlasGridSize().x
    }
    
    func getSourceId(named name: String) -> Int32 {
        for i in 0..<getSourceCount() {
            let sourceId = getSourceId(index: i)
            let source = getSource(sourceId: sourceId) as? TileSetAtlasSource
            if source?.resourceName == name {
                return sourceId
            }
        }
        return -1
    }
    
    func getSource(named name: String) -> TileSetAtlasSource? {
        for i in 0..<getSourceCount() {
            let sourceId = getSourceId(index: i)
            let source = getSource(sourceId: sourceId) as? TileSetAtlasSource
            if source?.resourceName == name {
                return source
            }
        }
        return nil
    }
    
    func hasSource(named name: String) -> Bool {
        for i in 0..<getSourceCount() {
            let sourceId = getSourceId(index: i)
            let source = getSource(sourceId: sourceId) as? TileSetAtlasSource
            if source?.resourceName == name {
                return true
            }
        }
        return false
    }
    
    func removeSource(named name: String) {
        for i in 0..<getSourceCount() {
            let sourceId = getSourceId(index: i)
            let source = getSource(sourceId: sourceId) as? TileSetAtlasSource
            if source?.resourceName == name {
                removeSource(sourceId: sourceId)
                return
            }
        }
    }
}
