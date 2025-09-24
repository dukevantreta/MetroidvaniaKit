import SwiftGodot

protocol Weapon {
    func fire(direction: Vector2) -> [Node2D]
}

class PowerBeam: Weapon {
    
    private var sprite = ResourceLoader.load(path: "res://objects/bullets/bullet_normal.tscn") as? PackedScene
    
    func fire(direction: Vector2) -> [Node2D] {
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
        projectile.addChild(node: collisionBox)
        
        projectile.behavior = LinearShotBehavior()
        projectile.direction = direction
        projectile.collisionLayer = 0b1_0000
        projectile.collisionMask = 0b0010_0011
        
        return [projectile]
    }
}

class PlasmaBeam: Weapon {
    
    private var sprite = ResourceLoader.load(path: "res://objects/bullets/bullet_normal.tscn") as? PackedScene
    
    func fire(direction: Vector2) -> [Node2D] {
        let projectiles = [Projectile(), Projectile(), Projectile()]
        
        for i in 0..<3 {
            let angle = .pi / 24 * Double(i - 1)
            let newDirection = direction.rotated(angle: angle)
            
            if let sprite = sprite?.instantiate() as? AnimatedSprite2D {
                projectiles[i].addChild(node: sprite)
                sprite.rotation = Double(Float.atan2(y: newDirection.y, x: newDirection.x))
            }
            
            let collisionRect = RectangleShape2D()
            collisionRect.size = Vector2(x: 16, y: 8)
            let collisionBox = CollisionShape2D()
            collisionBox.shape = collisionRect
            projectiles[i].addChild(node: collisionBox)
            
            projectiles[i].behavior = LinearShotBehavior()
            projectiles[i].direction = newDirection
            projectiles[i].collisionLayer = 0b1_0000
            projectiles[i].collisionMask = 0b0000_0011
        }
        return projectiles
    }
}
