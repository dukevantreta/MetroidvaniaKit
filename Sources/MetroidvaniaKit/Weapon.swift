import SwiftGodot
import Numerics

protocol Weapon {
    func fire(direction: Vector2) -> [Node2D]
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
    
    var waveAmplitude: Float = 0.0
    var waveFrequency: Float = 0.0
    var multiplyFactor: Float = 1
    private var timeElapsed: Double = 0.0
    
    func update(_ shot: Projectile, delta: Double) {
        timeElapsed += delta
        
        shot.position.x += Float(shot.speed * delta) * shot.direction.x
        shot.position.y += Float(shot.speed * delta) * shot.direction.y
        
        let perp = shot.direction.rotated(angle: .pi / 2.0)
        
        let waveOffset = Float.sin(Float(timeElapsed) * waveFrequency * .pi) * waveAmplitude * multiplyFactor
        shot.position.x += waveOffset * perp.x
        shot.position.y += waveOffset * perp.y
    }
}

@Godot
class PowerBeam: Node, Weapon {
    
    @Export var sprite: PackedScene?
    
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

@Godot
class WaveBeam: Node, Weapon {
    
    @Export var waveAmplitude: Float = 3.5
    @Export var waveFrequency: Float = 15.0
    
    @Export var sprite: PackedScene?
    
    func fire(direction: Vector2) -> [Node2D] {
        let projectiles = [Projectile(), Projectile()]
        for i in 0..<2 {
            if let sprite = sprite?.instantiate() as? AnimatedSprite2D {
                projectiles[i].addChild(node: sprite)
            }
            
            let collisionRect = RectangleShape2D()
            collisionRect.size = Vector2(x: 14, y: 14)
            let collisionBox = CollisionShape2D()
            collisionBox.shape = collisionRect
            projectiles[i].addChild(node: collisionBox)
            
            let behavior = WaveShotBehavior()//amplitude: waveAmplitude, frequency: waveFrequency)
            behavior.waveAmplitude = waveAmplitude
            behavior.waveFrequency = waveFrequency
            if i == 1 {
                behavior.multiplyFactor = -1
            }
            projectiles[i].behavior = behavior
            projectiles[i].direction = direction
            projectiles[i].collisionLayer = 0b1_0000
            projectiles[i].collisionMask = 0b0010_0000
        }
        return projectiles
    }
}

@Godot
class PlasmaBeam: Node, Weapon {
    
    @Export var sprite: PackedScene?
    
    func fire(direction: Vector2) -> [Node2D] {
        let projectiles = [Projectile(), Projectile(), Projectile()]
        
        for i in 0..<3 {
            let angle = .pi / 30 * Double(i - 1)
            let newDirection = direction.rotated(angle: angle)
            
            if let sprite = sprite?.instantiate() as? AnimatedSprite2D {
                projectiles[i].addChild(node: sprite)
                sprite.rotation = Double(Float.atan2(y: direction.y, x: direction.x))
            }
            
            let collisionRect = RectangleShape2D()
            collisionRect.size = Vector2(x: 16, y: 14)
            let collisionBox = CollisionShape2D()
            collisionBox.shape = collisionRect
            projectiles[i].addChild(node: collisionBox)
            
            projectiles[i].behavior = LinearShotBehavior()
            projectiles[i].direction = newDirection
            projectiles[i].collisionLayer = 0b1_0000
            projectiles[i].collisionMask = 0b0000_0000
        }
        return projectiles
    }
}
