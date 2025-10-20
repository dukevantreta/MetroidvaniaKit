import SwiftGodot

@Godot
class Hitbox: Area2D {
    
//    @Signal var onHit: SignalWithArguments<Damage>
    
    var onHit: ((Damage) -> Void)?
    
    @Export var damage: Int = 0
    
    @Export var damageType: Damage.Source = .none
    
    @Export var isContinuous: Bool = false
    
    private var trackedHitboxes: [Hitbox] = []
    
    override func _ready() {
        areaEntered.connect { [weak self] otherArea in
            guard let self, let hitbox = otherArea as? Hitbox else { return }
            if isContinuous {
                trackedHitboxes.append(hitbox)
            } else {
                hit(hitbox)
            }
        }
        areaExited.connect { [weak self] otherArea in
            guard let self, let hitbox = otherArea as? Hitbox else { return }
            if isContinuous {
                trackedHitboxes.removeAll { $0 === hitbox }
            }
        }
    }
    
    override func _process(delta: Double) {
        if isContinuous {
            trackedHitboxes.forEach { hit($0) }
        }
    }
    
    private func hit(_ other: Hitbox) {
        let damage = Damage(source: damageType, amount: damage, origin: globalPosition)
        other.takeHit(damage)
//        let direction = other.globalPosition - self.globalPosition
    }
    
    func takeHit(_ damage: Damage) {
//        onHit.emit(damage)
        onHit?(damage)
    }
}
