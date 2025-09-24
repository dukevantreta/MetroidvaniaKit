import SwiftGodot

protocol PlayerState {
    func enter(_ player: PlayerNode)
    func update(_ player: PlayerNode, dt: Double) -> PlayerState?
}

class IdleState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.sprite?.play(name: "idle-1")
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let yDirection = player.input.getVerticalAxis()
        let hDirection = player.input.getHorizontalAxis()
        
        player.fire()
        player.fireSubweapon()
        
        if !hDirection.isZero {
            return RunningState()
        }
        if player.input.isActionJustPressed(.action0) {
            player.velocity.y = Float(-player.getJumpspeed())
            return JumpingState()
        }
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        if player.input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        if player.input.isActionPressed(.leftShoulder) {
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
