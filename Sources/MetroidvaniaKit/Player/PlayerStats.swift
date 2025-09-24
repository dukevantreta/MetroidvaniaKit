import SwiftGodot

enum Upgrade {
    case doubleJump
    case wallGrab
}

@Godot
class PlayerStats: Node2D {
    
    @Export var hp: Int = 100
    
    @Export var energy: Int = 100
    
    @Export var hasMorph: Bool = false
    
    @Export var hasSuperJump: Bool = false
    
    @Export var hasDoubleJump: Bool = false
    
    @Export var hasWallGrab: Bool = false
    
    @Export var hasSpeedBooster: Bool = false
    
    @Export var hasWaterMovement: Bool = false
}
