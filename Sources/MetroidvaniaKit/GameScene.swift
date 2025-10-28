import SwiftGodot

protocol BulletPool: AnyObject {
    func spawnBullet(setup: (Bullet) -> Void)
    func destroy(_ bullet: Bullet)
}

protocol SceneService: BulletPool {
    func isOutOfBounds(_ rect: Rect2) -> Bool
}

@Godot
final class GameScene: Node2D {

    @Node("Player") var player: Player?

    private(set) var roomRect: Rect2 = .zero

    private let bulletPool = ObjectPool<Bullet>()

    override func _ready() {
        position = .zero

        ServiceLocator.register(self as SceneService)

        bulletPool.preload(10)
    }

    func setCurrentRoom(_ map: World.Map) {
        roomRect = Rect2(x: Float(map.x), y: Float(map.y), width: Float(map.width), height: Float(map.height))
    }
}

extension GameScene: SceneService {

    func isOutOfBounds(_ rect: Rect2) -> Bool {
        !roomRect.intersects(b: rect, includeBorders: true)
    }

    func spawnBullet(setup: (Bullet) -> Void) {
        let bullet = bulletPool.acquire()
        setup(bullet)
        self <- bullet
    }

    func destroy(_ bullet: Bullet) {
        bullet.removeFromParent()
        bulletPool.release(bullet)
    }
}