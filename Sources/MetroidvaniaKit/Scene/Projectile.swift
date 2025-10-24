import SwiftGodot

enum ProjectileType {
    case normal
    case wave
    case plasma
    case rocket
}

@Godot
class Projectile: Node2D {
    
    var type: ProjectileType = .normal
    
    var damage: Int = 10
    
    var lifetime: Double = 1.5
    
    var speed: Float = 800
    
    var ai: NodeAI?
    
    // var onDestroy: (() -> Void)?

    var destroyOnTimeout: Bool = false
    
    var destroyMask: LayerMask = .floor
    // @Node("Hitbox") 
    var hitbox: Hitbox?

    var effectSpawner: Spawner?

    deinit {
        // GD.print("Projectile DEINIT")
    }
    
    override func _ready() {
        hitbox?.damage = damage
        hitbox?.bodyEntered.connect { [weak self] otherBody in
            guard let self else { return }
            if let tilemap = otherBody as? TileMapLayer {
                // TODO: Check tile map coords to get physics layer (like water check)
//                if !LayerMask(rawValue: otherBody.collisionLayer).isDisjoint(with: destroyMask) {
                    self.destroy()
//                }
            }
        }
        hitbox?.areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea = otherArea as? Area2D else { return }
            if !LayerMask(rawValue: otherArea.collisionLayer).isDisjoint(with: destroyMask) {
                self.destroy()
            }
        }
    }

    override func _physicsProcess(delta: Double) {
        ai?.update(self, dt: delta)
        
        lifetime -= delta
        if lifetime <= 0 {
            // queueFree()
            self.timeout()
        }
    }
    
    func destroy() {
        // onDestroy?()
        if let parent = getParent() {
            if let effect = effectSpawner?.spawn(on: parent) {
                effect.position = self.position
            }
        }
        queueFree()
    }

    func timeout() {
        if destroyOnTimeout, let parent = getParent() {
            if let effect = effectSpawner?.spawn(on: parent) {
                effect.position = self.position
            }
        }
        queueFree()
    }
}
