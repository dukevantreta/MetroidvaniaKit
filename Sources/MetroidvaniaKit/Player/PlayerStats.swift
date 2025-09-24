import SwiftGodot

enum Upgrade {
    case doubleJump
    case wallGrab
}

@Godot
class PlayerStats: Node2D {
    
    @Signal var hpChanged: SignalWithArguments<Int>
    @Signal var ammoChanged: SignalWithArguments<Int>

    @Export var maxHp: Int = 100
    @Export var maxAmmo: Int = 10
    
    @Export var hp: Int = 100 {
        didSet {
            hpChanged.emit(hp)
        }
    }
    
    @Export var ammo: Int = 10 {
        didSet {
            ammoChanged.emit(ammo)
        }
    }
    
    @Export var hasMorph: Bool = false
    
    @Export var hasSuperJump: Bool = false
    
    @Export var hasDoubleJump: Bool = false
    
    @Export var hasWallGrab: Bool = false
    
    @Export var hasWallGrabUpgrade: Bool = false
    
    @Export var hasSpeedBooster: Bool = false
    
    @Export var hasWaterMovement: Bool = false
    
    @Export var hasWaterWalking: Bool = false

    func restoreHealth(_ amount: Int) {
        hp = min(hp + amount, maxHp)
    }

    func restoreAmmo(_ amount: Int) {
        ammo = min(ammo + amount, maxAmmo)
    }
}
