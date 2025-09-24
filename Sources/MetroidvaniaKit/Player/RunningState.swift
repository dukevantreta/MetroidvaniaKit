import SwiftGodot

class RunningState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.canDoubleJump = true
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let direction = Input.getHorizontalAxis()
        var targetSpeed = player.speed * direction
        
        if !direction.isZero {
            if (player.velocity.x >= 0 && direction > 0) || (player.velocity.x <= 0 && direction < 0) {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
            }
        } else {
//            startRunningTimestamp = Time.getTicksMsec()
            player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration))
        }
        
        // Jump
        if Input.isActionJustPressed(.accept) {
            GD.print("Jump")
            player.velocity.y = Float(-player.getJumpspeed())
        }
        
        player.moveAndSlide()
        
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        return nil
    }
}
