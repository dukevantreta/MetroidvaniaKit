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
class Weapon: Node {

    var ammo: Ammo?
    var cooldown: Cooldown?

    @Export var ammoCost: Int = 0
    
    @Export var cooldownTime: Double = 0.0 

    @Export var autofire: Bool = false
    
    var isFirstFrame = true
    
    func fire(from node: Node, origin: Vector2, direction: Vector2, isPressed: Bool) -> Bool {
        guard isPressed else {
            isFirstFrame = true
            return false
        }
        guard autofire || isFirstFrame else { return false }
        isFirstFrame = false
        guard let cooldown, cooldown.isReady else { return false }
        guard ammo?.consume(ammoCost) == true else { 
            return false // play fail sfx
        }
        cooldown.time = cooldownTime
        cooldown.use()
        let projectiles = makeProjectiles(origin: origin, direction: direction) 
        projectiles.forEach {
            $0.position = origin
            node.addChild(node: $0)
        }
        return true
    }

    func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
        logError("Method not implemented")
        return []
    }
}

@Godot
class DataMiner: Weapon {

    private let minePool = [
        Mine(),
        Mine(),
        Mine(),
        Mine()
    ]

    deinit {
        minePool.forEach { $0.queueFree() }
    }

    override func _ready() {
        minePool.forEach {
            $0.zIndex = 100
        }
    }

    override func fire(from node: Node, origin: Vector2, direction: Vector2, isPressed: Bool) -> Bool {
        guard isPressed else {
            isFirstFrame = true
            return false
        }
        guard isFirstFrame else { return false }
        isFirstFrame = false
        guard let cooldown, cooldown.isReady else { return false }
        cooldown.time = cooldownTime
        cooldown.use()
        let projectiles = makeProjectiles(origin: origin, direction: direction) 
        projectiles.forEach {
            $0.position = origin
            node.addChild(node: $0)
            ($0 as? Mine)?.reset()
        }
        return true
    }

    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
        for mine in minePool {
            if mine.getParent() == nil {
                // mine.reset()
                return [mine]
            }
        }
        return [] // FIXME: cooldown is gonna be eaten anyways
    }
}

@Godot
class PowerBeam: Weapon {
    
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
class WaveBeam: Weapon {
    
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
class PlasmaBeam: Weapon {
    
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
class RocketLauncher: Weapon {
    
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
class GranadeLauncher: Weapon {

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

@Godot
class SmartBomb: Weapon {

    // @Export var projectile: PackedScene?

    @Export var explosion: PackedScene?

    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
        let projectile = Projectile()
        
        let tex = PlaceholderTexture2D()
        tex.size = Vector2(x: 8, y: 8)
        let sprite = Sprite2D()
        sprite.texture = tex

        projectile.addChild(node: sprite)

        let ai = LinearMoveAI()
        projectile.ai = ai
        projectile.addChild(node: ai)
        
        ai.direction = direction
        ai.speed = 100
        projectile.lifetime = 1.0

        projectile.destroyOnTimeout = true

        var effectSpawner = HitEffectSpawner()
        effectSpawner.object = explosion
        projectile.effectSpawner = effectSpawner

        return [projectile]
    }
}

@Godot
class Flamethrower: Weapon {

    private var ammoCounter: Double = 0.0

    override func _process(delta: Double) {
        ammoCounter -= delta
    }

    override func fire(from node: Node, origin: Vector2, direction: Vector2, isPressed: Bool) -> Bool {
        guard isPressed else {
            // isFirstFrame = true
            ammoCounter = 0
            return false
        }
        guard let cooldown, cooldown.isReady else { return false }
        if ammoCounter <= 0 {
            guard ammo?.consume(ammoCost) == true else {
                return false
            }
            ammoCounter = 0.5
        }
        cooldown.time = cooldownTime
        cooldown.use()
        let projectiles = makeProjectiles(origin: origin, direction: direction) 
        projectiles.forEach {
            $0.position = origin
            node.addChild(node: $0)
        }
        return true
    }

    override func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
        let projectile = Projectile()

        let sprite = FlameSprite()
        projectile.addChild(node: sprite)

        let ai = LinearMoveAI()
        projectile.ai = ai
        projectile.addChild(node: ai)
        
        ai.direction = direction
        ai.speed = 200
        projectile.lifetime = 0.5

        return [projectile]
    }
}

@Godot
class FlameSprite: Sprite2D {

    var spriteScale = 1.0

    override func _ready() {
        let tex = PlaceholderTexture2D()
        tex.size = Vector2(x: 8, y: 8)
        self.texture = tex
    }

    override func _physicsProcess(delta: Double) {
        spriteScale += 8 * delta
        self.scale = Vector2(x: spriteScale, y: spriteScale) // TODO also needs to scale bullet collider size
    }
}