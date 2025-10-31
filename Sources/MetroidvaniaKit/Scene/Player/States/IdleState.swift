import SwiftGodot

class IdleState: PlayerState {

    let canFire: Bool = true

    var aimUpProtectionFlag = true // stupid ass solution, but works for now
    
    func enter(_ player: Player) {
        player.sprite?.play(name: "idle-1")
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }

        // entering from crouch, toggle flag
        if player.input.isActionJustPressed(.up) {
            aimUpProtectionFlag = false
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        if !player.isOnFloor() {
            return .jump
        }
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = -player.getJumpspeed()
            return .jump
        }
        if abs(player.getRealVelocity().x) > player.runThreshold {
            return .run
        }
        if player.joy1.y < 0 && !player.input.isActionPressed(.leftShoulder) && !player.isMorphed {
            player.sprite?.spriteFrames?.setAnimationLoop(anim: "stand-to-crouch", loop: false)
            player.sprite?.play(name: "stand-to-crouch")
            return .crouch
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
        if player.input.isActionJustReleased(.up) {
            aimUpProtectionFlag = true
        }

        player.updateHorizontalMovement(dt)
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        player.moveAndSlide()

        // Handle animations
        if player.isMorphed {
            player.play(.miniIdle)
            return
        }

        if player.isAiming {
            if player.aimPriority.y < 0.0 {
                player.aimDiagonalDown()
                player.play(.idleAimDiagonalDown)
            } else {
                player.aimDiagonalUp()
                player.play(.idleAimDiagonalUp)
            }
        } else {
            if player.joy1.y > 0 && aimUpProtectionFlag {
                player.aimUp()
                player.play(.idleAimUp)
            } else {
                player.aimForward()
                if Time.getTicksMsec() - player.lastShotTimestamp < player.lastShotAnimationThreshold {
                    player.play(.idleAim)
                } else {
                    player.play(.idle)
                }
            }
        }
    }
}
