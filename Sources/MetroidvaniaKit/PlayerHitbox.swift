import SwiftGodot

@Godot
class PlayerHitbox: Area2D {
    
    @SceneTree(path: "..") var player: CharacterController2D?
    
    override func _ready() {
        guard let player else {
            GD.print("PLAYER NOT FOUND")
            return
        }
        collisionMask |= 0b00000010
        collisionMask |= 0b00000100
        collisionMask |= 0b00001000
        
//        areaEntered.connect { [weak self] area in
//            if let collisionArea = area as? CollisionObject2D {
//                if (collisionArea.collisionLayer & 0b00000100) != 0 {
//                    self?.player?.enterWater()
//                }
//            }
//        }
//        areaExited.connect { [weak self] area in
//            if let collisionArea = area as? CollisionObject2D {
//                if (collisionArea.collisionLayer & 0b00000100) != 0 {
//                    self?.player?.exitWater()
//                }
//            }
//        }
        
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
    
    var lastFrameInWater = false
    
//    override func _physicsProcess(delta: Double) {
    override func _process(delta: Double) {
        guard var playerPosition = player?.position else { return }
        playerPosition.y -= 1
        
        for body in getOverlappingBodies() {
            if let tilemap = body as? TileMap, let tileset = tilemap.tileSet {
                let mapCoordinates = tilemap.localToMap(localPosition: playerPosition)
                if let tileData = tilemap.getCellTileData(layer: 0, coords: mapCoordinates) {
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
