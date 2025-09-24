import SwiftGodot

@Godot
class BreakableBlock: RigidBody2D {
    
    @SceneTree(path: "Area2D") weak var area: Area2D?
    @SceneTree(path: "Sprite2D") weak var coverSprite: Sprite2D?
    
    private var shouldDestroy = false
    private var destroyCountdown = 0.1
    
    override func _ready() {
        guard let area else {
            logError("Collision area not found")
            return
        }
        
        freeze = true
        freezeMode = .kinematic
        
        collisionLayer |= 0b0010
        
        area.collisionMask = 0b1_0000
        area.collisionLayer = 0b0011
        
        area.areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            if otherArea.collisionLayer & 0b0001_0000 != 0 {
                self.reveal()
                self.shouldDestroy = true
                self.collisionLayer = 0
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
