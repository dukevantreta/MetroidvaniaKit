import SwiftGodot

class IdleState: PlayerState {

    let canFire: Bool = true
    
    func enter(_ player: Player) {
        player.sprite?.play(name: "idle-1")
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        if player.input.isActionJustPressed(.leftShoulder) {
            player.aimY = 0.0
        }
        player.isAiming = player.input.isActionPressed(.leftShoulder)

        if !player.joy1.y.isZero {
            player.aimY = player.joy1.sign().y
        }

        if player.isAiming {
            if player.aimY < 0.0 {
                player.aimDiagonalDown()
            } else {
                player.aimDiagonalUp()
            }
        } else {
            if player.joy1.y > 0 {
                player.aimUp()
            } else {
                player.aimForward()
            }
        }
        
        if !player.joy1.x.isZero {
            return .run
        }
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = -player.getJumpspeed()
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
        
        if player.isMorphed {
            player.sprite?.play(name: "mini-idle-1")
            return
        }
        
        if player.input.isActionPressed(.leftShoulder) {
            if player.aimY < 0.0 {
                player.sprite?.play(name: "aim-diag-down")
            } else {
                player.sprite?.play(name: "aim-diag-up")
            }
        } else {
            if player.joy1.y > 0 {
                player.sprite?.play(name: "aim-up")
            } else {
                if Time.getTicksMsec() - player.lastShotTimestamp < player.lastShotAnimationThreshold {
                    player.sprite?.play(name: "aim-idle")
                } else {
                    player.sprite?.play(name: "idle-1")
                }
            }
        }
    }
}
