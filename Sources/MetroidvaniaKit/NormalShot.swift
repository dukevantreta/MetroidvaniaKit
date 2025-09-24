import SwiftGodot

@Godot
class NormalShot: RigidBody2D {
    
    var speed: Double = 400
    var direction: Vector2 = .zero
    
    var behavior: ProjectileBehavior = WaveShotBehavior()
    
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
//        position.x += Float(speed * delta) * direction.x
//        position.y += Float(speed * delta) * direction.y
        behavior.update(self, delta: delta)
    }
    
    func destroy() {
        queueFree()
    }
}

protocol ProjectileBehavior {
    func update(_ shot: NormalShot, delta: Double)
}

class NormalShotBehavior: ProjectileBehavior {
    func update(_ shot: NormalShot, delta: Double) {
        shot.position.x += Float(shot.speed * delta) * shot.direction.x
        shot.position.y += Float(shot.speed * delta) * shot.direction.y
    }
}

class WaveShotBehavior: ProjectileBehavior {
    
    var timeElapsed: Double = 0.0
    let waveAmplitude: Float = 4.0
    let waveFrequency: Float = 10.0
    
    func update(_ shot: NormalShot, delta: Double) {
        timeElapsed += delta
        
        shot.position.x += Float(shot.speed * delta) * shot.direction.x
        shot.position.y += Float(shot.speed * delta) * shot.direction.y
        
        let perpX = -shot.direction.y
        let perpY = shot.direction.x
        
        let waveOffset = Float.sin(Float(timeElapsed) * waveFrequency * .pi) * waveAmplitude
        shot.position.x += waveOffset * perpX
        shot.position.y += waveOffset * perpY
    }
}
