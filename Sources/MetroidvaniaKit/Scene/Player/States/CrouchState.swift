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
        // Jump
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = Float(-player.getJumpspeed())
            return .jump
        }
        
        // Stand
        if player.input.isActionJustPressed(.up) || !player.joy1.x.isZero {
            return .run
        }
        
        // Morph
        if player.input.isActionJustPressed(.down) && player.hasUpgrade(.morph) {
            player.morph()
            return .run
            // return .morph
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
            player.aimCrouchUp()
        } else {
            if player.sprite?.animation != "stand-to-crouch" {
                player.sprite?.play(name: "crouch-aim")
            }
            player.aimCrouchForward()
        }
    }
}
