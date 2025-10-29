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
        if let hitbox = instance.findChild(pattern: "Hitbox2D") as? Hitbox2D {
            hitbox.monitorable = false
            hitbox.damage = 10
            hitbox.damageType = .rocket
            hitbox.collisionMask = 0b0010_0011
        }
        node.callDeferred(method: "add_child", Variant(instance))
        return instance
    }
}

protocol WeaponDelegate: AnyObject {
    func canUse(_ upgrade: Upgrades) -> Bool
    func firingPoint() -> Vector2
    var shotDirection: Vector2 { get }
}

@Godot
class Weapon: Node {

    @Node("../..") weak var delegate: (Node2D & WeaponDelegate)?

    @Export private(set) var autofire: Bool = false
    @Export private(set) var ammoCost: Int = 0
    @Export private(set) var cooldownTime: Double = 0.0 
    @Export private(set) var bulletSpeed: Float = 640
    @Export private(set) var lifetime: Double = 1.5

    var ammo: Ammo?
    var cooldown: Cooldown?

    // private 
    var isFirstFrame = true

    private(set) lazy var scene: BulletPool? = {
        return getNode(path: "/root/TestScene2") as? BulletPool
    }()
    
    func trigger(isPressed: Bool) -> Bool {
        guard isPressed else {
            isFirstFrame = true
            return false
        }
        guard autofire || isFirstFrame else { return false }
        isFirstFrame = false
        guard let cooldown, cooldown.isReady else { return false }
        if let ammo {
            guard ammo.consume(ammoCost) else {
                return false // play fail sfx
            }
        }
        cooldown.time = cooldownTime
        cooldown.use()
        fire()
        return true
    }

    func fire() {
        logError("Method not implemented")
    }

    // DEPRECATED
    func makeProjectiles(origin: Vector2, direction: Vector2) -> [Node2D] {
        logError("Method not implemented")
        return []
    }
}

@Godot
class MainWeapon: Weapon {

    private var spriteScene: PackedScene?

    override func _ready() {
        guard delegate != nil else {
            logError("Delegate not set!"); return
        }
        spriteScene = GD.load(path: "res://objects/bullets/bullet_normal.tscn")
        guard spriteScene != nil else {
            logError("Shot sprite not set!"); return
        }
    }

    override func fire() {
        guard let delegate else { return }
        scene?.spawnBullet { bullet in

            let direction = delegate.shotDirection
            bullet.position = delegate.firingPoint()

            if let sprite = spriteScene?.instantiate() as? Node2D {
                let angle = Float.atan2(y: direction.y, x: direction.x)
                sprite.rotation = Double(angle)
                bullet.setSprite(sprite)
            }

            let ai = LinearMoveAI()
            ai.direction = direction
            ai.speed = bulletSpeed

            bullet.ai = ai
            bullet <- ai

            bullet.lifetime = lifetime
            bullet.damageValue = [.player]

            bullet.hitbox.collisionLayer = 0
            bullet.hitbox.addCollisionMask([.floor, .enemy])
            if delegate.canUse(.waveBeam) {
                bullet.destroyMask.remove(.floor)
            }
            if !delegate.canUse(.plasmaBeam) {
                bullet.destroyMask.insert(.enemy)
            }

            var hitEffect = HitEffectSpawner()
            hitEffect.object = GD.load(path: "res://objects/bullets/hit_1.tscn")
            bullet.effectSpawner = hitEffect
        }
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

    override func fire() {
        var freeMine: Mine?
        for mine in minePool {
            if mine.getParent() == nil {
                freeMine = mine
                break
            }
        }
        guard let freeMine else { return }
        guard let delegate else { return }
        freeMine.position = delegate.position + Vector2(x: 0, y: -6)
        delegate.getParent()?.addChild(node: freeMine)
        freeMine.reset()
    }
}

@Godot
class RocketLauncher: Weapon {
    
    private var spriteScene: PackedScene?

    override func _ready() {
        spriteScene = GD.load(path: "res://objects/bullets/bullet_rocket.tscn")
        guard spriteScene != nil else {
            logError("Rocket sprite not set"); return
        }
    }

    override func fire() {
        guard let delegate else { return }
        scene?.spawnBullet { bullet in

            let direction = delegate.shotDirection
            bullet.position = delegate.firingPoint()

            if let sprite = spriteScene?.instantiate() as? Node2D {
                let angle = Float.atan2(y: direction.y, x: direction.x)
                sprite.rotation = Double(angle)
                bullet.setSprite(sprite)
            }
            bullet.radius = 5

            let ai = LinearMoveAI()
            ai.direction = direction
            ai.speed = bulletSpeed

            bullet.ai = ai
            bullet <- ai

            bullet.lifetime = lifetime
            bullet.damageValue = [.rocket]
            bullet.hitbox.collisionLayer = 0
            bullet.hitbox.addCollisionMask([.floor, .enemy])
            bullet.destroyMask.insert(.enemy)
        }
    }
}

@Godot
class GranadeLauncher: Weapon {

    @Export var projectile: PackedScene?

    @Export var hitEffect: PackedScene?

    @Export var speed: Float = 200

    override func fire() {
        guard let delegate else { return }
        scene?.spawnBullet { bullet in
            let direction = delegate.shotDirection
            bullet.position = delegate.firingPoint()

            let tex = PlaceholderTexture2D()
            tex.size = Vector2(x: 12, y: 12)
            let sprite = Sprite2D()
            sprite.texture = tex
            sprite.centered = true
            bullet.setSprite(sprite)

            let ai = FallAI()
            ai.speed = speed
            ai.direction = direction
            bullet.ai = ai
            bullet <- ai

            bullet.hitbox.damageType = .rocket // FIXME
            bullet.hitbox.collisionLayer = 0
            bullet.hitbox.addCollisionMask([.floor, .enemy])
            bullet.destroyMask.insert(.enemy)

            var spawner = GranadeHitSpawner()
            spawner.object = hitEffect
            bullet.effectSpawner = spawner
        }
    }
}

@Godot
class SmartBomb: Weapon {

    @Export var explosion: PackedScene?

    override func fire() {
        guard let delegate else { return }
        scene?.spawnBullet { bullet in
            let direction = delegate.shotDirection
            bullet.position = delegate.firingPoint()

            let tex = PlaceholderTexture2D()
            tex.size = Vector2(x: 8, y: 8)
            let sprite = Sprite2D()
            sprite.texture = tex
            bullet.setSprite(sprite)

            let ai = LinearMoveAI()
            ai.direction = direction
            ai.speed = 100

            bullet.ai = ai
            bullet <- ai

            bullet.lifetime = 1.0
            bullet.hitsOnTimeout = true

            var effectSpawner = HitEffectSpawner()
            effectSpawner.object = explosion
            bullet.effectSpawner = effectSpawner
        }
    }
}

@Godot
class Flamethrower: Weapon {

    private var ammoCounter: Double = 0.0

    override func _process(delta: Double) {
        ammoCounter -= delta
    }

    override func trigger(isPressed: Bool) -> Bool {
        guard isPressed else {
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
        fire()
        return true
    }

    override func fire() {
        guard let delegate else { return }
        scene?.spawnBullet { bullet in
            let direction = delegate.shotDirection
            bullet.position = delegate.firingPoint()
            
            let sprite = FlameSprite()
            bullet.setSprite(sprite)

            let ai = LinearMoveAI()
            ai.direction = direction
            ai.speed = bulletSpeed

            bullet.ai = ai
            bullet <- ai

            bullet.lifetime = lifetime
            bullet.destroyMask = []
        }
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

// old weapons

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
        
        let hitbox = Hitbox2D()
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
            
            let hitbox = Hitbox2D()
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
            
            let hitbox = Hitbox2D()
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