import SwiftGodot

// This block has an area detection size of 64x64

@Godot
class SpeedBoosterBlock: RigidBody2D {
    
    @SceneTree(path: "Area2D") weak var area: Area2D?
    @SceneTree(path: "DetectionArea") weak var detectionArea: Area2D?
    @SceneTree(path: "CoverSprite") weak var coverSprite: Sprite2D?
    
    private var shouldDestroy = false
    private var destroyCountdown = 0.1
    
    override func _ready() {
        guard let area, let detectionArea else {
            log("COLLISION NOT FOUND")
            return
        }
        
        collisionLayer |= 0b0010
        
        freeze = true
        freezeMode = .kinematic
        
        area.collisionMask = 0b1_0000
        area.collisionLayer = 0b0011
        
        // Projectile detection
        area.areaEntered.connect { [weak self] otherArea in
            guard let otherArea else { return }
            if otherArea.collisionLayer & 0b0001_0000 != 0 {
                self?.reveal()
            }
        }
        
        // Speed booster player detection
        detectionArea.bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
            guard let self else { return }
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
            if layer & 0b1_0000_0000 != 0 {
                if let player = body as? PlayerNode, player.isSpeedBoosting {
                    if player.globalPosition.y - 1 > self.globalPosition.y {
                        self.collisionLayer = 0 // Remove collision only if player is not above the block
                    }
                    self.shouldDestroy = true
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
    
    func reveal() {
        coverSprite?.visible = false
    }
}
