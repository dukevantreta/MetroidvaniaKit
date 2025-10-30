import SwiftGodot

class CrouchState: PlayerState {

    let canFire: Bool = true
    
    func enter(_ player: Player) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isOverclocking = false
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 24)
            player.hitbox?.position = Vector2(x: 0, y: -12)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {

        if player.input.isActionPressed(.leftShoulder) {
            player.aimCrouchUp()
        } else {
            player.aimCrouchForward()
        }

        // Jump
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = -player.getJumpspeed()
            return .jump
        }
        
        // Stand
        if player.input.isActionJustPressed(.up) || !player.joy1.x.isZero {
            return .run
        }
        
        // Morph
        if player.input.isActionJustPressed(.down) && player.canUse(.morph) {
            player.morph()
            return .run
        }
        
        // Sanity check
        if !player.isOnFloor() {
            return .jump
        }
        
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        
        // Handle animations
        if player.input.isActionPressed(.leftShoulder) {
            player.sprite?.play(name: "crouch-aim-up")
        } else {
            if player.sprite?.animation != "stand-to-crouch" {
                player.sprite?.play(name: "crouch-aim")
            }
        }
    }
}
