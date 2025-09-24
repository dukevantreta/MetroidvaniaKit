import SwiftGodot
import Numerics

protocol Spawner {
    var object: PackedScene? { get set }
    func spawn(on node: Node) -> Node2D?
}

struct HitEffectSpawner: Spawner {

    var object: PackedScene?

    func spawn(on node: Node) -> Node2D? {
        guard let instance: Node2D = try? object?.instantiate() else { return nil }
        node.callDeferred(method: "add_child", Variant(instance))
        return instance
    }
}

struct GranadeHitSpawner: Spawner {

    var object: PackedScene?

    func spawn(on node: Node) -> Node2D? {
        guard let instance: Node2D = try? object?.instantiate() else { return nil }
        if let hitbox = instance.findChild(pattern: "Hitbox") as? Hitbox {
            hitbox.monitorable = false
            hitbox.damage = 10
            hitbox.damageType = .rocket
            hitbox.collisionMask = 0b0010_0011
        }
        node.callDeferred(method: "add_child", Variant(instance))
        return instance
    }
}

@Godot
class WeaponNode: Node {

    var ammo: Ammo?

    @Export var ammoCost: Int = 0
    
    @Export var cooldown: Double = 0.0

    @Export var autofire: Bool = false
    
    private(set) var cooldownCounter: Double = 0.0

    override func _process(delta: Double) {
        cooldownCounter -= delta
    }
    
    func fire(from node: Node, origin: Vector2, direction: Vector2) {
        guard cooldownCounter <= 0 else {
            log("Weapon in cooldown")
            return 
        }
        guard ammo?.consume(ammoCost) == true else {
            log("No ammo")
            return // play fail sfx
        }
        cooldownCounter = cooldown
        let projectiles = makeProjectiles(origin: origin, direction: direction) 
        projectiles.forEach {
            $0.position = origin
            node.addChild(node: $0)
        }
    }

    func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
        logError("Method not implemented")
        return []
    }
}

@Godot
class PowerBeam: WeaponNode {
    
    @Export var sprite: PackedScene?
    
    @Export var hitEffect: PackedScene?
    
    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
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
        
        projectile.hitbox?.collisionLayer = 0b1_0000
        projectile.hitbox?.collisionMask = 0b0010_0011
        projectile.destroyMask.insert(.enemy)
        projectile.type = .normal

        var effectSpawner = HitEffectSpawner()
        effectSpawner.object = hitEffect
        projectile.effectSpawner = effectSpawner
        
        return [projectile]
    }
}

@Godot
class WaveBeam: WeaponNode {
    
    @Export var waveAmplitude: Float = 3.5
    @Export var waveFrequency: Float = 15.0
    
    @Export var sprite: PackedScene?
    
    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
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
            
            if i == 1 {
                ai.multiplyFactor = -1
            }
            projectiles[i].position = origin

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
class PlasmaBeam: WeaponNode {
    
    @Export var sprite: PackedScene?
    
    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
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

            projectiles[i].position = origin
            
            projectiles[i].hitbox?.collisionLayer = 0b1_0000
            projectiles[i].hitbox?.collisionMask = 0b0010_0011
            projectiles[i].type = .plasma
        }
        projectiles[1].zIndex += 1
        return projectiles
    }
}

@Godot
class RocketLauncher: WeaponNode {
    
    @Export var sprite: PackedScene?

    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
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
        
        projectile.hitbox?.collisionLayer = 0b1_0000
        projectile.hitbox?.collisionMask = 0b0010_0011
        projectile.destroyMask.insert(.enemy)
        projectile.type = .rocket
        projectile.damage = 50
        return [projectile]
    }
}

@Godot
class GranadeLauncher: WeaponNode {

    @Export var projectile: PackedScene?

    @Export var hitEffect: PackedScene?

    @Export var speed: Float = 200

    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
        guard let p: Projectile = try? projectile?.instantiate() else { 
            return []
        }
        p.position = origin

        p.hitbox = p.findChild(pattern: "Hitbox") as? Hitbox
        let ai = FallAI()
        
        ai.speed = speed
        ai.direction = direction
        
        p.ai = ai
        
        p.hitbox?.damage = 10
        p.hitbox?.damageType = .rocket
        p.hitbox?.collisionLayer = 0b1_0000
        p.hitbox?.collisionMask = 0b0010_0011
        p.destroyMask.insert(.enemy)
        
        var spawner = GranadeHitSpawner()
        spawner.object = hitEffect
        p.effectSpawner = spawner

        p.addChild(node: ai)
        return [p]
    }
}