import SwiftGodot

class CrouchState: PlayerState {

    let canFire: Bool = true
    
    func enter(_ player: Player) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isOverclocking = false
        
        // if let hitboxRect = player.pHitbox?.shape as? RectangleShape2D {
        //     hitboxRect.size = Vector2(x: 14, y: 24)
        //     player.pHitbox?.position = Vector2(x: 0, y: -12)
        // }
    }
    
    func processInput(_ player: Player) -> Player.State? {
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
            return .idle
        }
        
        // Sanity check
        if !player.isOnFloor() {
            return .jump
        }
        
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        player.moveAndSlide()

        if player.isAiming {
            player.aimPriority.y = 1.0
            player.aimCrouchUp()
            player.play(.crouchAimDiagonalUp)
        } else {
            player.aimCrouchForward()
            if player.sprite?.animation != "stand-to-crouch" {
                player.play(.crouchAim)
            }
        }
    }
}
