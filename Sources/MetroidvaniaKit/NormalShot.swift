import SwiftGodot

@Godot
class NormalShot: Area2D {
    
    var damage = 10
    var speed: Double = 800
    var direction: Vector2 = .zero
    
    var behavior: ProjectileBehavior = LinearShotBehavior()
    
    override func _ready() {
        collisionMask = 0b0010_0011
        collisionLayer = 0b1_0000
        
        let texture = PlaceholderTexture2D()
        texture.size = Vector2(x: 6, y: 6)
        let sprite = Sprite2D()
        sprite.texture = texture
        addChild(node: sprite)
        
        let rect = RectangleShape2D()
        rect.size = Vector2(x: 14, y: 14)
        let collisionBox = CollisionShape2D()
        collisionBox.shape = rect
        addChild(node: collisionBox)
        
        bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
            if layer & 0b0011 != 0 {
                self?.destroy()
            }
        }
        areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            if otherArea.collisionLayer & 0b0011 != 0 {
                self.destroy()
            } else if otherArea.collisionLayer & 0b0010_0000 != 0 {
                if let enemyHurtbox = otherArea as? Hurtbox {
                    enemyHurtbox.onDamage?(damage)
                }
            }
        }
    }
    
    override func _physicsProcess(delta: Double) {
        position.x += Float(speed * delta) * direction.x
        position.y += Float(speed * delta) * direction.y

//        behavior.update(self, delta: delta)
    }
    
    func destroy() {
        queueFree()
    }
}

protocol ProjectileBehavior {
    func update(_ shot: Projectile, delta: Double)
}

class LinearShotBehavior: ProjectileBehavior {
    func update(_ shot: Projectile, delta: Double) {
        shot.position.x += Float(shot.speed * delta) * shot.direction.x
        shot.position.y += Float(shot.speed * delta) * shot.direction.y
    }
}

class WaveShotBehavior: ProjectileBehavior {
    
    var timeElapsed: Double = 0.0
    let waveAmplitude: Float = 4.0
    let waveFrequency: Float = 10.0
    
    func update(_ shot: Projectile, delta: Double) {
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
