import SwiftGodot

enum Upgrade {
    case doubleJump
    case wallGrab
}

@Godot
class PlayerStats: Node2D {
    
    @Export var hp: Int = 100
    
    @Export var ammo: Int = 10
    
    @Export var hasMorph: Bool = false
    
    @Export var hasSuperJump: Bool = false
    
    @Export var hasDoubleJump: Bool = false
    
    @Export var hasWallGrab: Bool = false
    
    @Export var hasWallGrabUpgrade: Bool = false
    
    @Export var hasSpeedBooster: Bool = false
    
    @Export var hasWaterMovement: Bool = false
    
    @Export var hasWaterWalking: Bool = false
}
