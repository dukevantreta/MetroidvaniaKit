import SwiftGodot

@Godot
class SmartBombExplosion: Node2D {

    @Node("Sprite2D") var sprite: Sprite2D?

    @Node("Hitbox") var hitbox: Hitbox?
    @Node("Hitbox/CollisionShape2D") var collision: CollisionShape2D?

    // var lifetime = 2.0
    var expanding = true

    override func _ready() {
        hitbox?.collisionLayer = 0
        hitbox?.collisionMask = 0b0010_0011
        hitbox?.damage = 100
        // hitbox?.damageType
        
    }

    override func _physicsProcess(delta: Double) {
        guard let circle = collision?.shape as? CircleShape2D else {
            logError("Shape not a circle")
            return
        }

        if expanding {
            // 1 = 8, 2 = 16
            let deltaRadius = 160 * delta
            circle.radius += deltaRadius
            let s = (circle.radius * 2) / 8
            sprite?.scale = Vector2(x: s, y: s)
            
            if circle.radius >= 160 {
                expanding = false
            }
        } else {
            let deltaRadius = 160 * delta
            circle.radius -= deltaRadius
            let s = (circle.radius * 2) / 8
            sprite?.scale = Vector2(x: s, y: s)

            if circle.radius <= 8 {
                queueFree()
            }
        }
    }

    deinit {
        log("Deinit")
    }
}