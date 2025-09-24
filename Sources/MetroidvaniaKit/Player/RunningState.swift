import SwiftGodot

class RunningState: PlayerState {
    
    var isFirstRunningFrame: Bool = true
    var startRunningTimestamp: UInt = 0
    
    func enter(_ player: PlayerNode) {
        player.canDoubleJump = true
        startRunningTimestamp = Time.getTicksMsec()
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let direction = Input.getHorizontalAxis()
        var targetSpeed = player.speed * direction
        
        // Speed booster turn on
        if Time.getTicksMsec() - startRunningTimestamp > player.speedBoostThreshold && player.upgrades.hasSpeedBooster {
            player.isSpeedBoosting = true
        }
        if player.isSpeedBoosting {
            targetSpeed *= 2
        }
        
        // Horizontal movement
        if !direction.isZero {
            if isFirstRunningFrame {
                startRunningTimestamp = Time.getTicksMsec()
                isFirstRunningFrame = false
            }
            if (player.velocity.x >= 0 && direction > 0) || (player.velocity.x <= 0 && direction < 0) {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
            }
        } else {
            player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration))
        }
        
        // Speed booster cancel
        if abs(player.velocity.x) < Float(player.speed) * 0.9 || player.getRealVelocity().x == 0 {
            isFirstRunningFrame = true
            startRunningTimestamp = Time.getTicksMsec()
            player.isSpeedBoosting = false
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
