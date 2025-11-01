import SwiftGodot

class IdleState: PlayerState {

    let canFire: Bool = true

    func enter(_ player: Player) {
        // if let hitboxRect = player.pHitbox?.shape as? RectangleShape2D {
        //     hitboxRect.size = Vector2(x: 14, y: 36)
        //     player.pHitbox?.position = Vector2(x: 0, y: -18)
        // }
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
            player.play(.standToCrouch)
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

        player.updateHorizontalMovement(dt)
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        player.moveAndSlide()

        // Handle animations
        if player.isMorphed {
            if player.hasActedRecently {
                player.play(.miniIdleAlt)
            } else {
                player.play(.miniIdle)
            }
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
            if player.joy1.y > 0 {
                player.aimUp()
                player.play(.idleAimUp)
            } else {
                player.aimForward()
                if player.hasShotRecently {
                    player.play(.idleAim)
                } else if player.hasActedRecently {
                    player.play(.idleAlt)
                } else {
                    player.play(.idle)
                }
            }
        }
    }
}
