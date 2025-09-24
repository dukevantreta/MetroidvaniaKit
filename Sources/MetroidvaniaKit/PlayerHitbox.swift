import SwiftGodot

@Godot
class PlayerHitbox: Area2D {
    
    @SceneTree(path: "..") var player: PlayerNode?
    
    override func _ready() {
        guard let player else {
            logError("PLAYER NOT FOUND")
            return
        }
        
        collisionLayer = 0b1_0000_0000
//        collisionMask |= 0b00000010
        collisionMask |= 0b00000100
//        collisionMask |= 0b00001000
        
        areaEntered.connect { [weak self] area in
            guard let self, let area else { return }
            if area.collisionLayer & 0b0100 != 0 {
                GD.print("ENTER WATER")
                player.enterWater()
            }
        }
        areaExited.connect { [weak self] area in
            guard let self, let area else { return }
            if area.collisionLayer & 0b0100 != 0 {
                GD.print("EXIT WATER")
                player.exitWater()
            }
        }
        
//        areaShapeEntered.connect { areaRid, area, areaShapeIndex, localShapeIndex in
//            GD.print("AREA SHAPE ENTERED")
//            let layer = PhysicsServer2D.areaGetCollisionLayer(area: areaRid)
//            if layer & 0b0000_1000 != 0 {
////                self?.player?.enterWater()
//                GD.print("AREA WATER FROM TILES")
//            }
//        }
        
//        bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
//            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
//            if layer & 0b0000_1000 != 0 {
////                self?.player?.enterWater()
////                GD.print("BODY WATER FROM TILES")
//            }
//        }
//        
//        bodyShapeExited.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
//            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
//            if layer & 0b0000_1000 != 0 {
////                self?.player?.
////                GD.print("EXITED WATER FROM TILES")
//            }
//        }
    }
    
//    var lastFrameInWater = false
    
//    override func _physicsProcess(delta: Double) {
    override func _process(delta: Double) {
//        guard var playerPosition = player?.position else { return }
//        playerPosition.y -= 1
//        
//        for body in getOverlappingBodies() {
//            if let tilemap = body as? TileMapLayer, let tileset = tilemap.tileSet {
//                let mapCoordinates = tilemap.localToMap(localPosition: playerPosition)
//                if let tileData = tilemap.getCellTileData(coords: mapCoordinates) {
//                    var tileCollisionLayer: UInt32 = 0
//                    for physicsLayerIdx in 0..<tileset.getPhysicsLayersCount() { // ugly workaround to get tile's collision layer
//                        if tileData.getCollisionPolygonsCount(layerId: physicsLayerIdx) > 0 {
//                            tileCollisionLayer |= tileset.getPhysicsLayerCollisionLayer(layerIndex: physicsLayerIdx)
//                        }
//                    }
//                    if tileCollisionLayer & 0b0000_0100 != 0 { // is in water
//                        if !lastFrameInWater {
//                            lastFrameInWater = true
//                            player?.enterWater()
//                        }
//                        return
//                    }
//                }
//            }
//        }
//        if lastFrameInWater {
//            lastFrameInWater = false
//            player?.exitWater()
//        }
    }
}
