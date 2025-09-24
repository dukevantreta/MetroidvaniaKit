import SwiftGodot

class CrouchState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isSpeedBoosting = false
        player.sprite?.play(name: "stand-to-crouch")
    }
    
    func update(_ player: PlayerNode, dt: Double) -> (any PlayerState)? {
        
        let yDirection = Input.getVerticalAxis()
        let xDirection = Input.getHorizontalAxis()
        
        if Input.isActionJustPressed(.action1) {
            player.fire()
            player.lastShotTimestamp = Time.getTicksMsec()
        }
        
        // Jump
        if Input.isActionJustPressed(.action0) {
            player.velocity.y = Float(-player.getJumpspeed())
            return JumpingState()
        }
        
        // Stand
        if yDirection > 0 || !xDirection.isZero {
            return RunningState()
        }
        
        if Input.isActionPressed(.leftShoulder) {
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
