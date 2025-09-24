import SwiftGodot

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
    
    func getGIDs() -> [Int32] {
        (0..<getSourceCount()).map { getSourceId(index: $0) }
    }
    
    func getColumnCount(gid: Int32) -> Int32 {
        guard let source = getSource(sourceId: gid) as? TileSetAtlasSource else {
            return -1
        }
        return source.getAtlasGridSize().x
    }
    
    func getAtlasGID(tileGID: Int32) -> Int32 {
        getGIDs().filter { $0 <= tileGID }.max() ?? -1
    }
}
