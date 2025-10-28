import SwiftGodot

@Godot
class BreakableBlock: RigidBody2D {
    
    @Node("Hitbox2D") weak var hitbox: Hitbox2D?
    @Node("TileSprite2D") weak var coverSprite: Sprite2D?
    @Node("RealSprite") weak var realSprite: Sprite2D?
    @Node("AnimatedSprite2D") weak var destroyAnimation: AnimatedSprite2D?
    
    override func _ready() {
        guard let hitbox else {
            logError("Hitbox not found."); return
        }
        
        freeze = true
        freezeMode = .kinematic
        
        setCollisionLayer(.floor)
        
        destroyAnimation?.spriteFrames?.setAnimationLoop(anim: "default", loop: false)
        destroyAnimation?.animationFinished.connect { [weak self] in
            self?.queueFree()
        }

        hitbox.onHit = { [weak self] damage in
            guard let self else { return }
            if damage.value.contains(.player) {
                self.reveal()
                self.collisionLayer = 0
                self.realSprite?.visible = false
                self.destroyAnimation?.play()
            }
        }
    }
    
    func reveal() {
        coverSprite?.visible = false
    }
}
