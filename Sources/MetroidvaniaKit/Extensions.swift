import SwiftGodot

infix operator ???

public func ???<T>(optional: T?, error: @autoclosure () -> Error) throws -> T {
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

extension Node2D {
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
