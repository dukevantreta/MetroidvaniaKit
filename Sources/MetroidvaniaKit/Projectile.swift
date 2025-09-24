import SwiftGodot

@Godot
class Projectile: Node2D {
    
    var lifetime: Double = 2.0
    var damage: Int = 10
    var speed: Double = 800
    var direction: Vector2 = .zero
    
    var behavior: ProjectileBehavior?
    var hitbox: Area2D?
    
    override func _ready() {
        hitbox?.bodyEntered.connect { [weak self] otherBody in
            guard let self else { return }
            self.destroy()
        }
        hitbox?.areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            self.destroy()
        }
    }
    
    override func _physicsProcess(delta: Double) {
        behavior?.update(self, delta: delta)
        
        lifetime -= delta
        if lifetime <= 0 {
            queueFree()
        }
    }
    
    func destroy() {
        // do effects
        queueFree()
    }
    
    deinit {
        GD.print("BULLET DESTROYED")
    }
}

protocol Weapon {
    func fire(direction: Vector2) -> Node2D
}

class PowerBeam: Weapon {
    
    private var sprite = ResourceLoader.load(path: "res://objects/bullets/bullet_normal.tscn") as? PackedScene
    
    func fire(direction: Vector2) -> Node2D {
        let projectile = Projectile()
        
        if let sprite = sprite?.instantiate() as? AnimatedSprite2D {
            projectile.addChild(node: sprite)
            let angle = Float.atan2(y: direction.y, x: direction.x)
            sprite.rotation = Double(angle)
        }
        
        let collisionRect = RectangleShape2D()
        collisionRect.size = Vector2(x: 16, y: 8)
        let collisionBox = CollisionShape2D()
        collisionBox.shape = collisionRect
        let area2d = Area2D()
        area2d.addChild(node: collisionBox)
        projectile.addChild(node: area2d)
        
        projectile.hitbox = area2d
        projectile.behavior = NormalShotBehavior()
        projectile.direction = direction
        projectile.hitbox?.collisionLayer = 0b1_0000
        projectile.hitbox?.collisionMask = 0b0010_0011
        
        return projectile
    }
}
