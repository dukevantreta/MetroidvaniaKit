import SwiftGodot

enum Upgrade {
    case doubleJump
    case wallGrab
}

@Godot
class PlayerUpgrades: Node2D {
    
    @Export var hasDoubleJump: Bool = false
    
    @Export var hasWallGrab: Bool = false
    
    @Export var hasSpeedBooster: Bool = false
}
