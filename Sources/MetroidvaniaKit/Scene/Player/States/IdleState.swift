import SwiftGodot

class IdleState: PlayerState {
    
    func enter(_ player: Player) {
        player.sprite?.play(name: "idle-1")
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        
        if !player.joy1.x.isZero {
            return .run
        }
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = Float(-player.getJumpspeed())
            return .jump
        }
        if !player.isOnFloor() {
            return .jump
        }
        if player.input.isActionJustPressed(.up) && player.isMorphed {
            if player.hasSpaceToUnmorph() {
                player.unmorph()
                return .crouch
            }
        }
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        
        player.fire()
        player.fireSubweapon()

        if player.isMorphed {
            player.sprite?.play(name: "mini-idle-1")
            return
        }
        
        if player.input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        if player.input.isActionPressed(.leftShoulder) {
            if !player.joy1.y.isZero {
                player.isAimingDown = player.joy1.y < 0
            }
            if player.isAimingDown {
                player.sprite?.play(name: "aim-diag-down")
                player.aimDiagonalDown()
            } else {
                player.sprite?.play(name: "aim-diag-up")
                player.aimDiagonalUp()
            }
        } else {
            if player.joy1.y > 0 {
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
