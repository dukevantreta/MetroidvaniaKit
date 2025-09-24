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
    
    // remove this, GIDs not consistent
//    func getGIDs() -> [Int32] {
//        (0..<getSourceCount()).map { getSourceId(index: $0) }
//    }
//    
//    func getColumnCount(gid: Int32) -> Int32 {
//        guard let source = getSource(sourceId: gid) as? TileSetAtlasSource else {
//            return -1
//        }
//        return source.getAtlasGridSize().x
//    }
//    
//    func getAtlasGID(tileGID: Int32) -> Int32 {
//        getGIDs().filter { $0 <= tileGID }.max() ?? -1
//    }
    
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
            }
        }
    }
}
