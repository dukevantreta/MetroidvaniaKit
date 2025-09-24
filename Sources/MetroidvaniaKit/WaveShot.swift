import SwiftGodot
import Numerics

@Godot
class WaveShot: Area2D {
    
    var speed: Double = 300
    
    var amplitude: Float = 32
    
    var frequency: Float = 4
    
    var direction: Int = 1
    
//    var lifetime: Float = 2
    
    private var centerY: Float = 0
    
    private var startTime: UInt = 0
    
    override func _ready() {
        collisionMask = 0b0001
        centerY = position.y
        startTime = Time.getTicksMsec()
        
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
            if layer & 0b0001 != 0 {
                self?.destroy()
            }
        }
    }
    
    override func _physicsProcess(delta: Double) {
        let timeDelta = Float(Time.getTicksMsec() - startTime) * 0.001
        position.y = centerY + -Float.sin(2 * .pi * timeDelta * frequency) * (amplitude * 0.5)
        position.x += Float(speed * delta * Double(direction))
    }
    
    func destroy() {
        queueFree()
    }
}
