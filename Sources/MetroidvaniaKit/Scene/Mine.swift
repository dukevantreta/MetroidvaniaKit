import SwiftGodot

@Godot
class Mine: Node2D {

    private var bombSprite: Sprite2D?
    private var explosionSprite: Sprite2D?
    private var hitbox: Hitbox2D?

    private let timer = Timer()
    private let destroyTimer = Timer()

    override func _ready() {
        let texture = PlaceholderTexture2D()
        texture.size = Vector2(x: 8, y: 8)
        let sprite = Sprite2D()
        sprite.texture = texture
        sprite.centered = true
        addChild(node: sprite)

        let explosionTex = PlaceholderTexture2D()
        explosionTex.size = Vector2(x: 32, y: 32)
        let explosionSpr = Sprite2D()
        explosionSpr.texture = explosionTex
        explosionSpr.centered = true
        addChild(node: explosionSpr)

        let rect = RectangleShape2D()
        rect.size = Vector2(x: 32, y: 32)
        let collision = CollisionShape2D()
        collision.shape = rect

        let hitbox = Hitbox2D()
        hitbox.addChild(node: collision)
        hitbox.collisionLayer = 0
        hitbox.addCollisionMask(.player)
        hitbox.monitoring = false
        hitbox.damageType = .bomb
        addChild(node: hitbox)

        explosionSpr.visible = false

        self.bombSprite = sprite
        self.explosionSprite = explosionSpr
        self.hitbox = hitbox

        timer.autostart = false
        timer.waitTime = 0.5
        timer.oneShot = true
        timer.timeout.connect { [weak self] in
            self?.explode()
        }
        addChild(node: timer)

        destroyTimer.autostart = false
        destroyTimer.waitTime = 0.06
        destroyTimer.oneShot = true
        destroyTimer.timeout.connect { [weak self] in
            self?.destroy()
        }
        addChild(node: destroyTimer)

        hitbox.areaEntered.connect { [weak self] other in
            guard let self, let other else { return }
            if let hitbox = other as? Hitbox2D {
                if let player = hitbox.getParent() as? Player {
                    self.hitPlayer(player)
                }
            }
        }
    }

    func reset() {
        bombSprite?.visible = true
        timer.start()
    }

    func hitPlayer(_ player: Player) {
        // log("BALL HIT")
    }

    func explode() {
        hitbox?.monitoring = true
        bombSprite?.visible = false
        explosionSprite?.visible = true
        destroyTimer.start()
    }

    func destroy() {
        hitbox?.monitoring = false
        explosionSprite?.visible = false
        getParent()?.removeChild(node: self)
    }
}