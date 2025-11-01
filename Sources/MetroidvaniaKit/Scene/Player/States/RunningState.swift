import SwiftGodot

class RunningState: PlayerState {
    
    let canFire: Bool = true
    
    func enter(_ player: Player) {
        player.overclockAccumulator = 0.0

        if !player.isAiming {
            player.aimPriority.y = 0.0
        }
        
        // if let hitboxRect = player.pHitbox?.shape as? RectangleShape2D {
        //     hitboxRect.size = Vector2(x: 14, y: 36)
        //     player.pHitbox?.position = Vector2(x: 0, y: -18)
        // }

    }
    
    func processInput(_ player: Player) -> Player.State? {

        if !player.isOnFloor() {
            return .jump
        }
        // Jump
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = -player.getJumpspeed()
            return .jump
        }
        if player.joy1.y > 0 && player.isMorphed {
            if player.hasSpaceToUnmorph() {
                player.unmorph()
                return .crouch
            }
        }

        if player.joy1.x.isZero && !player.isMorphed {
            if player.joy1.y < 0 && player.isOverclocking {
                player.sprite?.spriteFrames?.setAnimationLoop(anim: "stand-to-crouch", loop: false)
                player.sprite?.play(name: "stand-to-crouch")
                player.isOverclocking = false
                player.hasShinesparkCharge = true
                return .crouch
            }
            if player.joy1.y < 0 && !player.input.isActionPressed(.leftShoulder) {
                player.sprite?.spriteFrames?.setAnimationLoop(anim: "stand-to-crouch", loop: false)
                player.sprite?.play(name: "stand-to-crouch")
                return .crouch
            }
        }
        
        if player.input.isActionJustPressed(.rightShoulder) {
            if player.hasShinesparkCharge && (!player.joy1.x.isZero || !player.joy1.y.isZero) {
                return .charge
            }
            return .dash
        }

        if abs(player.getRealVelocity().x) < 0.1 {
            return .idle
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
            player.play(.miniRun)
            return
        }

        if player.isAiming || !player.joy1.y.isZero {
            if player.aimPriority.y < 0.0 {
                player.aimDiagonalDown()
                player.play(.runAimDiagonalDown)
            } else {
                player.aimDiagonalUp()
                player.play(.runAimDiagonalUp)
            }
        } else {
            player.aimForward()
            if player.hasShotRecently {
                player.play(.runAim)
            } else {
                player.play(.run)
            }
        }
    }
}
