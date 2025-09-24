import SwiftGodot

@Godot
class PlayerHitbox: Area2D {
    
    @SceneTree(path: "..") weak var player: PlayerNode?
    
    private var lastFrameInWater = false
    
    override func _ready() {
        guard let player else {
            logError("PLAYER NOT FOUND")
            return
        }
        
        collisionLayer = 0b1_0000_0000
        collisionMask |= 0b00000100
        
//        areaEntered.connect { [weak self] area in
//            guard let self, let area else { return }
//            if area.collisionLayer & 0b0100 != 0 {
//                GD.print("ENTER WATER")
//                player.enterWater()
//            }
//        }
//        areaExited.connect { [weak self] area in
//            guard let self, let area else { return }
//            if area.collisionLayer & 0b0100 != 0 {
//                GD.print("EXIT WATER")
//                player.exitWater()
//            }
//        }
    }
    
    override func _process(delta: Double) {
        guard var playerPosition = player?.position else { return }
        checkForWater(at: playerPosition)
    }
    
    func checkForWater(at playerPosition: Vector2) {
        for body in getOverlappingBodies() {
            if let tilemap = body as? TileMapLayer, let tileset = tilemap.tileSet {
                var queryPosition = Vector2(x: playerPosition.x, y: playerPosition.y - 1)
                queryPosition -= tilemap.globalPosition
                let mapCoordinates = tilemap.localToMap(localPosition: queryPosition)
                if let tileData = tilemap.getCellTileData(coords: mapCoordinates) {
                    var tileCollisionLayer: UInt32 = 0
                    for physicsLayerIdx in 0..<tileset.getPhysicsLayersCount() { // ugly workaround to get tile's collision layer
                        if tileData.getCollisionPolygonsCount(layerId: physicsLayerIdx) > 0 {
                            tileCollisionLayer |= tileset.getPhysicsLayerCollisionLayer(layerIndex: physicsLayerIdx)
                        }
                    }
                    if tileCollisionLayer & 0b0000_0100 != 0 { // is in water
                        if !lastFrameInWater {
                            lastFrameInWater = true
                            player?.enterWater()
                        }
                        return
                    }
                }
            }
        }
        if lastFrameInWater {
            lastFrameInWater = false
            player?.exitWater()
        }
    }
}
