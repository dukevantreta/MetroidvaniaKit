import SwiftGodot

@Godot
class Bullet: Node2D {

    weak var scene: SceneService?

    var effectSpawner: HitEffectSpawner?

    var ai: NodeAI?

    var lifetime: Double = 1.5

    var hitsOnTimeout = false

    var destroyMask: LayerMask = .floor

    var damage: Int {
        get { hitbox.damage }
        set { hitbox.damage = newValue }
    }

    var damageType: Damage.Source {
        get { hitbox.damageType }
        set { hitbox.damageType = newValue }
    }

    var damageValue: Damage.Value {
        get { hitbox.damageValue }
        set { hitbox.damageValue = newValue }
    }

    var radius: Double {
        get { circle.radius }
        set { circle.radius = newValue }
    }

    var frame: Rect2 {
        var rect = circle.getRect()
        rect.position.x += position.x
        rect.position.y += position.y
        return rect
    }

    private(set) lazy var hitbox: Hitbox2D = {
        let hitbox = Hitbox2D()
        let collisionShape = CollisionShape2D()
        collisionShape.shape = circle
        hitbox <- collisionShape
        return hitbox
    }()

    private let circle: CircleShape2D = {
        let shape = CircleShape2D()
        shape.radius = 4
        return shape
    }()

    private var sprite: Node2D?

    private var shouldHit = false

    private var destroyPosition: Vector2 = .zero

    func setSprite(_ node: Node2D) {
        sprite = node
        self <- node
    }

    override func _ready() {
        self <- hitbox

        // hitbox.monitorable = false
        // hitbox.monitoring = false

        hitbox.bodyShapeEntered.connect { [weak self] rid, body, bodyShapeIndex, localShapeIndex in
            guard let self else { return }
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: rid)
            if !LayerMask(rawValue: layer).isDisjoint(with: destroyMask) {
                shouldHit = true
                destroyPosition = self.position
                self.callDeferred(method: "destroy")
            }
        }
        hitbox.areaEntered.connect { [weak self] other in
            guard let self, let other = other as? Area2D else { return }
            if !LayerMask(rawValue: other.collisionLayer).isDisjoint(with: destroyMask) {
                shouldHit = true
                destroyPosition = self.position
                self.callDeferred(method: "destroy")
            }
        }
    }

    override func _enterTree() {
        scene = ServiceLocator.resolve()
    }

    override func _exitTree() {
        radius = 4
        lifetime = 1.5
        destroyMask = .floor
        destroyPosition = .zero
        shouldHit = false
        hitsOnTimeout = false
        sprite?.queueFree()
        sprite = nil
        ai?.queueFree()
        ai = nil
        scene = nil
        effectSpawner = nil
    }

    override func _physicsProcess(delta: Double) {
        ai?.update(self, dt: delta)

        lifetime -= delta
        if lifetime <= 0 {
            destroyPosition = position
            shouldHit = hitsOnTimeout
            destroy()
        } else if scene?.isOutOfBounds(frame) == true {
            shouldHit = false
            destroy()
        }
    }

    @Callable func destroy() {
        if shouldHit {
            if let parent = getParent() {
                if let effect = effectSpawner?.spawn(on: parent) {
                    effect.position = destroyPosition
                }
            }
        }
        scene?.destroy(self)
    }
}