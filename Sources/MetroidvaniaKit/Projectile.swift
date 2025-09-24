import SwiftGodot

enum ProjectileType {
    case normal
    case wave
    case plasma
    case rocket
}

@Godot
class Projectile: Area2D {
    
    var type: ProjectileType = .normal
    
    var damage: Int = 10
    
    var lifetime: Double = 1.5
    
    var speed: Double = 800
    
    var direction: Vector2 = .zero
    
    var behavior: ProjectileBehavior?
    
    var onDestroy: (() -> Void)?
    
    override func _ready() {
        bodyEntered.connect { [weak self] otherBody in
            guard let self else { return }
            self.destroy()
        }
        areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            self.destroy()
        }
    }
    
    override func _physicsProcess(delta: Double) {
        behavior?.update(self, delta: delta)
        
        lifetime -= delta
        if lifetime <= 0 {
            queueFree()
        }
    }
    
    func destroy() {
        onDestroy?()
        queueFree()
    }
}
