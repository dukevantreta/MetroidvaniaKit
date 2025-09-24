import SwiftGodot

enum Upgrade {
    case doubleJump
    case wallGrab
}

@Godot
class PlayerStats: Node2D {
    
    #signal("hp_changed")
    #signal("ammo_changed")
    
    @Export var hp: Int = 100 {
        didSet {
            emit(signal: PlayerStats.hpChanged)
        }
    }
    
    @Export var ammo: Int = 10 {
        didSet {
            emit(signal: PlayerStats.ammoChanged)
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
}
