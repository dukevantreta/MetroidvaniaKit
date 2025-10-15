import SwiftGodot

protocol PlayerState {
    func enter(_ player: Player)
    func processInput(_ player: Player) -> Player.State?
    func processPhysics(_ player: Player, dt: Double)
}

class IdleState: PlayerState {
    
    func enter(_ player: Player) {
        player.sprite?.play(name: "idle-1")
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        
        if !player.xDirection.isZero {
            return .run
        }
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = Float(-player.getJumpspeed())
            return .jump
        }
        if !player.isOnFloor() {
            return .jump
        }
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        
        player.fire()
        player.fireSubweapon()
        
        if player.input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        if player.input.isActionPressed(.leftShoulder) {
            if !player.yDirection.isZero {
                player.isAimingDown = player.yDirection < 0
            }
            if player.isAimingDown {
                player.sprite?.play(name: "aim-diag-down")
                player.aimDiagonalDown()
            } else {
                player.sprite?.play(name: "aim-diag-up")
                player.aimDiagonalUp()
            }
        } else {
            if player.yDirection > 0 {
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
    }
}
