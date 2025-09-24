import SwiftGodot

@Godot
class NormalShot: RigidBody2D {
    
    var speed: Double = 400
    var direction: Int = 1
    
    override func _ready() {
        collisionMask = 0b0011
        collisionLayer = 0b1_0000
        
        self.freeze = true
        self.freezeMode = .kinematic
        contactMonitor = true
        maxContactsReported = 1
        
        let size = Vector2(x: 6, y: 6)
        let texture = PlaceholderTexture2D()
        texture.size = size
        let sprite = Sprite2D()
        sprite.texture = texture
        addChild(node: sprite)
        
        let rect = RectangleShape2D()
        rect.size = size
        let collisionBox = CollisionShape2D()
        collisionBox.shape = rect
        addChild(node: collisionBox)
        
        bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
            if layer & 0b0011 != 0 {
                self?.destroy()
            }
        }
    }
    
    override func _physicsProcess(delta: Double) {
        position.x += Float(speed * delta * Double(direction))
    }
    
    func destroy() {
        queueFree()
    }
}
