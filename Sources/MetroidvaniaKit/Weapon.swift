import SwiftGodot
import Numerics

protocol Weapon {
    var ammoCost: Int { get }
    func fire(direction: Vector2) -> [Node2D]
}

@Godot
class PowerBeam: Node, Weapon {
    
    @Export var sprite: PackedScene?
    
    @Export var hitEffect: PackedScene?
    
    var ammoCost: Int = 0
    
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
        
        let hitbox = Hitbox()
        hitbox.addChild(node: collisionBox)
        
        projectile.addChild(node: hitbox)
        projectile.hitbox = hitbox
        
        let ai = LinearMoveAI()
        projectile.ai = ai
        projectile.addChild(node: ai)
        
        ai.direction = direction
        ai.speed = projectile.speed
        
        // projectile.behavior = LinearShotBehavior()
        projectile.direction = direction
        projectile.hitbox?.collisionLayer = 0b1_0000
        projectile.hitbox?.collisionMask = 0b0010_0011
        projectile.destroyMask.insert(.enemy)
        projectile.type = .normal
        
        projectile.onDestroy = { [weak self] in
            if let hit = self?.hitEffect?.instantiate() as? AnimatedSprite2D {
                hit.position = projectile.position
                projectile.getParent()?.addChild(node: hit)
            }
        }
        
        return [projectile]
    }
}

@Godot
class WaveBeam: Node, Weapon {
    
    @Export var waveAmplitude: Float = 3.5
    @Export var waveFrequency: Float = 15.0
    
    @Export var sprite: PackedScene?
    
    var ammoCost: Int = 0
    
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
            
            let hitbox = Hitbox()
            hitbox.addChild(node: collisionBox)
            
            projectiles[i].addChild(node: hitbox)
            projectiles[i].hitbox = hitbox
            
            let ai = SinWaveAI()
            projectiles[i].ai = ai
            projectiles[i].addChild(node: ai)
            
            ai.direction = direction
            ai.speed = projectiles[i].speed
            
            ai.amplitude = waveAmplitude
            ai.frequency = waveFrequency
            
            // let behavior = WaveShotBehavior()//amplitude: waveAmplitude, frequency: waveFrequency)
            // behavior.waveAmplitude = waveAmplitude
            // behavior.waveFrequency = waveFrequency
            if i == 1 {
                // behavior.multiplyFactor = -1
                ai.multiplyFactor = -1
            }
            // projectiles[i].behavior = behavior
            projectiles[i].direction = direction
            projectiles[i].hitbox?.collisionLayer = 0b1_0000
            projectiles[i].hitbox?.collisionMask = 0b0010_0000
            projectiles[i].destroyMask.remove(.floor)
            projectiles[i].destroyMask.insert(.enemy)
            projectiles[i].type = .wave
        }
        return projectiles
    }
}

@Godot
class PlasmaBeam: Node, Weapon {
    
    @Export var sprite: PackedScene?
    
    var ammoCost: Int = 0
    
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
            
            let ai = LinearMoveAI()
            projectiles[i].ai = ai
            projectiles[i].addChild(node: ai)
            
            ai.direction = direction
            ai.speed = projectiles[i].speed
            ai.direction = newDirection
            
            let hitbox = Hitbox()
            hitbox.addChild(node: collisionBox)
            
            projectiles[i].addChild(node: hitbox)
            projectiles[i].hitbox = hitbox
            
            // projectiles[i].behavior = LinearShotBehavior()
            projectiles[i].direction = newDirection
            projectiles[i].hitbox?.collisionLayer = 0b1_0000
            projectiles[i].hitbox?.collisionMask = 0b0010_0011
            projectiles[i].type = .plasma
        }
        projectiles[1].zIndex += 1
        return projectiles
    }
}

@Godot
class RocketLauncher: Node, Weapon {
    
    @Export var sprite: PackedScene?

    @Export var ammoCost: Int = 1
    
    func fire(direction: Vector2) -> [Node2D] {
        let projectile = Projectile()
        if let sprite = sprite?.instantiate() as? Sprite2D {
            projectile.addChild(node: sprite)
            sprite.rotation = Double(Float.atan2(y: direction.y, x: direction.x))
        }
        
        let hitbox = Hitbox()
        
        let collisionRect = RectangleShape2D()
        collisionRect.size = Vector2(x: 14, y: 10)
        let collisionBox = CollisionShape2D()
        collisionBox.shape = collisionRect
        
        hitbox.addChild(node: collisionBox)
        
        projectile.addChild(node: hitbox)
        projectile.hitbox = hitbox
        hitbox.damageType = .rocket
        
        let ai = LinearMoveAI()
        projectile.ai = ai
        projectile.addChild(node: ai)
        
        ai.direction = direction
        ai.speed = projectile.speed
        
        // projectile.behavior = LinearShotBehavior()
        projectile.direction = direction
        projectile.hitbox?.collisionLayer = 0b1_0000
        projectile.hitbox?.collisionMask = 0b0010_0011
        projectile.destroyMask.insert(.enemy)
        projectile.type = .rocket
        projectile.damage = 50
        
        return [projectile]
    }
}
