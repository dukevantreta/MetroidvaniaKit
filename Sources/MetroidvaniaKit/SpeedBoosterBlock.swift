import SwiftGodot

// This block has an area detection size of 64x64

@Godot
class SpeedBoosterBlock: Node2D {
    
    @SceneTree(path: "StaticBody2D") weak var staticBody: StaticBody2D?
    @SceneTree(path: "Area2D") weak var area: Area2D?
    
    private var shouldDestroy = false
    private var destroyCountdown = 0.1
    
    override func _ready() {
        guard let area else {
            log("COLLISION NOT FOUND")
            return
        }
        
        area.collisionMask |= 0b1_0000_0000
        
        area.bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
            if layer & 0b1_0000_0000 != 0 {
                if let player = body as? PlayerNode, player.isSpeedBoosting {
                    if player.position.y > self?.position.y ?? 0 {
                        self?.staticBody?.collisionLayer = 0 // Remove collision if player is not above the block
                    }
                    self?.shouldDestroy = true
                }
            }
        }
    }
    
    override func _process(delta: Double) {
        
        if shouldDestroy {
            destroyCountdown -= delta
            if destroyCountdown <= 0 {
                self.queueFree()
            }
        }
    }
    
//    func destroy() {
//        self.queueFree()
//    }
}
