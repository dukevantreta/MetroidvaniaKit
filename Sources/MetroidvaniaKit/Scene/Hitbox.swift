import SwiftGodot

@Godot
class Hitbox2D: Area2D {
    
//    @Signal var onHit: SignalWithArguments<Damage>
    
    var onHit: ((Damage) -> Void)?
    
    @Export var damage: Int = 0
    
    @Export var damageType: Damage.Source = .none

    @Export(.flags) var damageValue: Damage.Value = []
    
    @Export var isContinuous: Bool = false
    
    private var trackedHitboxes: [Hitbox2D] = []
    
    override func _ready() {
        areaEntered.connect { [weak self] other in
            guard let self, let hitbox = other as? Hitbox2D else { return }
            if isContinuous {
                trackedHitboxes.append(hitbox)
            } else {
                hit(hitbox)
            }
        }
        areaExited.connect { [weak self] other in
            guard let self, let hitbox = other as? Hitbox2D else { return }
            if isContinuous {
                trackedHitboxes.removeAll { $0 === hitbox }
            }
        }
    }
    
    override func _physicsProcess(delta: Double) {
        if isContinuous {
            trackedHitboxes.forEach { hit($0) }
        }
    }
    
    private func hit(_ other: Hitbox2D) {
        let damage = Damage(value: damageValue, source: damageType, amount: damage, origin: globalPosition)
        other.takeHit(damage)
//        let direction = other.globalPosition - self.globalPosition
    }
    
    func takeHit(_ damage: Damage) {
//        onHit.emit(damage)
        onHit?(damage)
    }
}
