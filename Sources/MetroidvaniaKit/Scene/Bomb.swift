import SwiftGodot

@Godot
class Bomb: Node2D {

    private var bombSprite: Sprite2D?
    private var explosionSprite: Sprite2D?
    private var hitbox: Hitbox?

    private let timer = Timer()
    private let destroyTimer = Timer()

    deinit {
        log("BOMB DEINIT")
    }

    override func _ready() {
        let texture = PlaceholderTexture2D()
        texture.size = Vector2(x: 8, y: 8)
        let sprite = Sprite2D()
        sprite.texture = texture
        sprite.centered = true
        addChild(node: sprite)

        let explosionTex = PlaceholderTexture2D()
        explosionTex.size = Vector2(x: 16, y: 16)
        let explosionSpr = Sprite2D()
        explosionSpr.texture = explosionTex
        explosionSpr.centered = true
        addChild(node: explosionSpr)

        let rect = RectangleShape2D()
        rect.size = Vector2(x: 16, y: 16)
        let collision = CollisionShape2D()
        collision.shape = rect

        let hitbox = Hitbox()
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

        timer.autostart = true
        timer.waitTime = 1.0
        timer.timeout.connect { [weak self] in
            self?.explode()
        }
        addChild(node: timer)

        destroyTimer.autostart = false
        destroyTimer.waitTime = 0.3
        destroyTimer.timeout.connect { [weak self] in
            self?.destroy()
        }
        addChild(node: destroyTimer)

        hitbox.areaEntered.connect { [weak self] other in
            guard let self, let other else { return }
            if let hitbox = other as? Hitbox {
                if let player = hitbox.getParent() as? Player {
                    self.hitPlayer(player)
                }
            }
        }
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
        queueFree()
    }
}