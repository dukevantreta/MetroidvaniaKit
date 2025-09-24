import SwiftGodot

protocol PlayerState {
    func enter(_ player: PlayerNode)
    func update(_ player: PlayerNode, dt: Double) -> PlayerState?
}

class IdleState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.sprite?.play(name: "idle-1")
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let yDirection = Input.getVerticalAxis()
        let hDirection = Input.getHorizontalAxis()
        
        if Input.isActionJustPressed(.action1) {
            player.fire()
            player.lastShotTimestamp = Time.getTicksMsec()
        }
        
        if !hDirection.isZero {
            return RunningState()
        }
        if Input.isActionJustPressed(.action0) {
            player.velocity.y = Float(-player.getJumpspeed())
            return JumpingState()
        }
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        if Input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        if Input.isActionPressed(.leftShoulder) {
            if !yDirection.isZero {
                player.isAimingDown = yDirection < 0
            }
            if player.isAimingDown {
                player.sprite?.play(name: "aim-diag-down")
                player.aimDiagonalDown()
            } else {
                player.sprite?.play(name: "aim-diag-up")
                player.aimDiagonalUp()
            }
        } else {
            if yDirection > 0 {
                player.sprite?.play(name: "aim-up")
                player.aimUp()
            } else {
                if Time.getTicksMsec() - player.lastShotTimestamp < player.lastShotAnimationThreshold {
                    player.sprite?.play(name: "aim-idle")
                } else {
                    player.sprite?.play(name: "idle-1")
                }
                player.aimForward()
            }
        }
        
        return nil
    }
}
