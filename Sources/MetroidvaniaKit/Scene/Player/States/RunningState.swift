import SwiftGodot

class RunningState: PlayerState {
    
    let canFire: Bool = true
    
    var lastActionTimestamp: UInt = 0
    
    func enter(_ player: Player) {
        player.overclockAccumulator = 0.0
        lastActionTimestamp = Time.getTicksMsec()

        if !player.input.isActionPressed(.leftShoulder) {
            player.aimY = 0.0
        }
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        if player.input.isActionJustPressed(.leftShoulder) {
            player.aimY = 0.0
        }
        if player.input.isActionJustReleased(.leftShoulder) {
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
            if player.joy1.y != 0 {
                if player.joy1.x != 0 {
                    if player.joy1.y > 0 {
                        player.aimDiagonalUp()
                    } else if player.joy1.y < 0 {
                        player.aimDiagonalDown()
                    }
                } else {
                    player.aimUp()
                }
            } else {
                player.aimForward()
            }
        }

        if !player.isOnFloor() {
            return .jump
        }
        // Jump
        if player.input.isActionJustPressed(.actionDown) {
            lastActionTimestamp = Time.getTicksMsec()
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
        
        if Time.getTicksMsec() - lastActionTimestamp > player.idleAnimationThreshold {
            return .idle
        }
        if player.input.isActionJustPressed(.rightShoulder) {
            if player.hasShinesparkCharge && (!player.joy1.x.isZero || !player.joy1.y.isZero) {
                return .charge
            }
            return .dash
        }
        
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        player.updateHorizontalMovement(dt)

        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        
        player.moveAndSlide()
        
        if player.isMorphed {
            if abs(player.getRealVelocity().x) > 0 {
                player.sprite?.play(name: "mini-run")
            } else {
                player.sprite?.play(name: "mini-idle-2")
            }
            return
        }
         
        // Handle animations
        if abs(player.getRealVelocity().x) > 0 {
            if player.isAiming || !player.joy1.y.isZero {
                if player.aimY < 0.0 {
                    player.sprite?.play(name: "run-aim-down")
                } else {
                    player.sprite?.play(name: "run-aim-up")
                }
            } else {
                if Time.getTicksMsec() - player.lastShotTimestamp < player.lastShotAnimationThreshold {
                    player.sprite?.play(name: "run-aim")
                } else {
                    player.sprite?.play(name: "run")
                }
            }
        } else {
            if player.isAiming {
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
                        player.sprite?.play(name: "idle-3")
                    }
                }
            }
        }
        
        
    }
}
