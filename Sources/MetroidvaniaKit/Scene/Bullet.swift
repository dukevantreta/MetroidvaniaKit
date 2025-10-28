import SwiftGodot

@Godot
class Bullet: Node2D {

    weak var scene: SceneService?

    var ai: NodeAI?

    var lifetime: Double = 1.5

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

    // private(set) lazy var collisionShape: CollisionShape2D = {
    //     let collisionShape = CollisionShape2D()
    //     collisionShape.shape = circle
    //     return collisionShape
    // }()

    private let circle: CircleShape2D = {
        let shape = CircleShape2D()
        shape.radius = 4
        return shape
    }()

    private let sprite = Sprite2D()

    private var shouldDestroy = false

    override func _ready() {
        self <- sprite
        self <- hitbox

        let texture = PlaceholderTexture2D()
        texture.size = Vector2(x: 8, y: 8)
        sprite.texture = texture
        sprite.centered = true

        hitbox.bodyEntered.connect { [weak self] other in
            guard let self else { return }
            if let tilemap = other as? TileMapLayer {
                self.shouldDestroy = true
            }
        }
        hitbox.areaEntered.connect { [weak self] other in
            guard let self, let other = other as? Area2D else { return }
            if !LayerMask(rawValue: other.collisionLayer).isDisjoint(with: destroyMask) {
                self.shouldDestroy = true
            }
        }
    }

    override func _enterTree() {
        scene = ServiceLocator.resolve()
        shouldDestroy = false
    }

    override func _exitTree() {
        radius = 4
        lifetime = 1.5
        destroyMask = .floor
        ai?.queueFree()
        ai = nil
    }

    override func _physicsProcess(delta: Double) {
        ai?.update(self, dt: delta)

        lifetime -= delta
        if lifetime <= 0 {
            shouldDestroy = true
        }
        if scene?.isOutOfBounds(frame) == true {
            shouldDestroy = true
        }
    }

    override func _process(delta: Double) {
        if shouldDestroy {
            scene?.destroy(self)
        }
    }
}