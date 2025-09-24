import SwiftGodot

class CrouchState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isSpeedBoosting = false
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 24)
            player.hitbox?.position = Vector2(x: 0, y: -12)
        }
    }
    
    func update(_ player: PlayerNode, dt: Double) -> (any PlayerState)? {
        
        let yDirection = player.input.getVerticalAxis()
        let xDirection = player.input.getHorizontalAxis()
        
        if player.input.isActionJustPressed(.action1) {
            player.fire()
            player.lastShotTimestamp = Time.getTicksMsec()
        }
        
        // Jump
        if player.input.isActionJustPressed(.action0) {
            player.velocity.y = Float(-player.getJumpspeed())
            return JumpingState()
        }
        
        // Stand
        if player.input.isActionJustPressed(.up) || !xDirection.isZero {
            return RunningState()
        }
        
        // Morph
        if player.input.isActionJustPressed(.down) && player.stats.hasMorph {
            return MorphState()
        }
        
        // Sanity trigger
        if !player.isOnFloor() {
            return JumpingState()
        }
        
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
        
        return nil
    }
}
