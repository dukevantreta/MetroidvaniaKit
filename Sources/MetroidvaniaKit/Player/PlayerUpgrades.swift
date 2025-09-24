import SwiftGodot

@Godot
class PlayerUpgrades: Node2D {
    
    @Export var hasDoubleJump: Bool = false
    
    @Export var hasWallGrab: Bool = false
}
