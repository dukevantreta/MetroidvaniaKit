import SwiftGodot
import Numerics

protocol Weapon {
    var ammoCost: Int { get }
    func fire(origin: Vector2, direction: Vector2) -> [Node2D]
}

@Godot
class PowerBeam: Node, Weapon {
    
    @Export var sprite: PackedScene?
    
    @Export var hitEffect: PackedScene?
    
    var ammoCost: Int = 0
    
    func fire(origin: Vector2, direction: Vector2) -> [Node2D] {
        let projectile = Projectile()
        
        if let sprite = sprite?.instantiate() as? AnimatedSprite2D {
            projectile.addChild(node: sprite)
            let angle = Float.atan2(y: direction.y, x: direction.x)
            sprite.rotation = Double(angle)
        }

        projectile.position = origin
        
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
        projectile.lifetime = 1.0
        
        // projectile.behavior = LinearShotBehavior()
        projectile.direction = direction
        projectile.hitbox?.collisionLayer = 0b1_0000
        projectile.hitbox?.collisionMask = 0b0010_0011
        projectile.destroyMask.insert(.enemy)
        projectile.type = .normal
        
        projectile.onDestroy = { [weak self, weak projectile] in
            if let hit = self?.hitEffect?.instantiate() as? AnimatedSprite2D {
                hit.position = projectile?.position ?? .zero
                projectile?.getParent()?.addChild(node: hit)
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
    
    func fire(origin: Vector2, direction: Vector2) -> [Node2D] {
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
    
    func fire(origin: Vector2, direction: Vector2) -> [Node2D] {
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
    
    func fire(origin: Vector2, direction: Vector2) -> [Node2D] {
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

// extension Node {

// }

// Using this prevents node memory leak in case of errors
extension PackedScene {
    // func instantiate<T>(on node: Node) -> T? where T: Node {
    func instantiate<T>() -> T? where T: Node {
        if let instance = self.instantiate() {
            if let typed = instance as? T {
                // node.addChild(node: typed)
                return typed
            } else {
                GD.printErr("ERROR CASTING INSTANCE")
                instance.queueFree()
            }
        }
        return nil
    }
}

@Godot
class GranadeLauncher: Node, Weapon {

    @Export var projectile: PackedScene?

    @Export var hitEffect: PackedScene?

    @Export var ammoCost: Int = 1

    @Export var speed: Float = 200

    @Export var cooldown: Double = 1.0

    func fire(origin: Vector2, direction: Vector2) -> [Node2D] {
        guard let parent = getParent()?.getParent()?.getParent() else { return [] }
        // getParent()?.getParent()?.addChild(node: Node?)
        guard cooldown <= 0 else { return [] }
        cooldown = 1.0

        // use ammo
        
        
        guard let p: Projectile = projectile?.instantiate() else { return [] }
        p.position = origin

        p.hitbox = p.findChild(pattern: "Hitbox") as? Hitbox
        let ai = FallAI()
        p.addChild(node: ai)


        p.speed = speed
        p.direction = direction
        ai.speed = p.speed
        ai.direction = direction
        p.ai = ai
        
        p.hitbox?.damage = 10
        p.hitbox?.damageType = .rocket
        p.hitbox?.collisionLayer = 0b1_0000
        p.hitbox?.collisionMask = 0b0010_0011
        p.destroyMask.insert(.enemy)
        
        p.onDestroy = { [weak self, weak p] in
            if let hit = self?.hitEffect?.instantiate() as? Node2D {
                hit.position = p?.position ?? .zero
                if let hitbox = hit.findChild(pattern: "Hitbox") as? Hitbox {
                    hitbox.monitorable = false
                    hitbox.damage = p?.hitbox?.damage ?? 0
                    hitbox.damageType = p?.hitbox?.damageType ?? .none
                    hitbox.collisionLayer = p?.hitbox?.collisionLayer ?? 0
                    hitbox.collisionMask = p?.hitbox?.collisionMask ?? 0
               }
               p?.getParent()?.callDeferred(method: "add_child", Variant(hit))
            }

        }
        parent.addChild(node: p)
        // log("SHOT \(parent.name)")
        return [p]
    }

    override func _process(delta: Double) {
        cooldown -= delta
    }
}
