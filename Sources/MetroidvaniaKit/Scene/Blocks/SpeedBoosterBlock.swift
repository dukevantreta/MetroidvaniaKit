import SwiftGodot

// This block has an area detection size of 64x64
@Godot
class SpeedBoosterBlock: RigidBody2D {
    
    @Node("DetectionArea") weak var detectionArea: Area2D?
    @Node("Hitbox2D") weak var hitbox: Hitbox2D?
    @Node("TileSprite2D") weak var coverSprite: Sprite2D?
    @Node("RealSprite") weak var realSprite: Sprite2D?
    @Node("AnimatedSprite2D") weak var destroyAnimation: AnimatedSprite2D?
    
    override func _ready() {
        guard let hitbox, let detectionArea else {
            logError("Collision area not found")
            return
        }
        
        freeze = true
        freezeMode = .kinematic
        
        setCollisionLayer(.floor)
        hitbox.setCollisionLayer(.floor)
        
        // Destroy
        destroyAnimation?.spriteFrames?.setAnimationLoop(anim: "default", loop: false)
        destroyAnimation?.animationFinished.connect { [weak self] in
            self?.queueFree()
        }
        
        // Scout
        hitbox.onHit = { [weak self] damage in
            guard let self else { return }
            if damage.value.contains(.mines) {
                self.reveal()
            }
        }
        
        // Speed booster player detection
        detectionArea.bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
            guard let self else { return }
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
            if layer & 0b1_0000_0000 != 0 {
                if let player = body as? Player, player.isOverclocking {
                    if player.globalPosition.y - 1 > self.globalPosition.y {
                        self.collisionLayer = 0 // Remove collision only if player is not above the block
                    }
                    self.reveal()
                    self.realSprite?.visible = false
                    self.destroyAnimation?.play()
                }
            }
        }
    }
    
    func reveal() {
        coverSprite?.visible = false
    }
}
