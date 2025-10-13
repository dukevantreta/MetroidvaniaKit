import SwiftGodot

@Godot
class PlayerData: Node {

    @Export var baseHP: Int = 99
    @Export var hpPerExpansion: Int = 50
    @Export var hpExpansions = 0

    @Export var baseAmmo: Int = 10
    @Export var ammoPerExpansion: Int = 5
    @Export var ammoExpansions = 0

    private(set) var upgrades: Upgrades = []

    func addUpgrade(_ upgrade: Upgrades) {
        upgrades.insert(upgrade)
    }
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
