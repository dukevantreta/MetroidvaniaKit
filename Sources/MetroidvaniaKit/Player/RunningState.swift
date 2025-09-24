import SwiftGodot

class RunningState: PlayerState {
    
    var isFirstRunningFrame: Bool = true
    var startRunningTimestamp: UInt = 0
    
    var lastActionTimestamp: UInt = 0
    
    func enter(_ player: PlayerNode) {
        player.canDoubleJump = true
        startRunningTimestamp = Time.getTicksMsec()
        lastActionTimestamp = Time.getTicksMsec()
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        if !player.isOnFloor() {
            return .jump
        }
        // Jump
        if player.input.isActionJustPressed(.actionRight) {
            lastActionTimestamp = Time.getTicksMsec()
            player.velocity.y = Float(-player.getJumpspeed())
        }
        if player.xDirection.isZero {
            if player.yDirection < 0 && player.isSpeedBoosting {
                player.sprite?.spriteFrames?.setAnimationLoop(anim: "stand-to-crouch", loop: false)
                player.sprite?.play(name: "stand-to-crouch")
                player.isSpeedBoosting = false
                player.hasShinesparkCharge = true
                return .crouch
            }
            if player.yDirection < 0 && !player.input.isActionPressed(.leftShoulder) {
                player.sprite?.spriteFrames?.setAnimationLoop(anim: "stand-to-crouch", loop: false)
                player.sprite?.play(name: "stand-to-crouch")
                return .crouch
            }
        }
        
        if Time.getTicksMsec() - lastActionTimestamp > player.idleAnimationThreshold {
            return .idle
        }
        if player.input.isActionJustPressed(.rightShoulder) {
            if player.hasShinesparkCharge && (!player.xDirection.isZero || !player.yDirection.isZero) {
                return .charge
            }
            return .dash
        }
        
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        
        var targetSpeed = player.speed * player.xDirection
        
        if player.input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        
        // Speed booster turn on
        if Time.getTicksMsec() - startRunningTimestamp > player.speedBoostThreshold && player.stats.hasSpeedBooster {
            player.isSpeedBoosting = true
        }
        if player.isSpeedBoosting {
            targetSpeed *= 2
        }
        
        // Horizontal movement
        if !player.xDirection.isZero {
            lastActionTimestamp = Time.getTicksMsec()
            if isFirstRunningFrame {
                startRunningTimestamp = Time.getTicksMsec()
                isFirstRunningFrame = false
            }
            if (player.velocity.x >= 0 && player.xDirection > 0) || (player.velocity.x <= 0 && player.xDirection < 0) {
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
        
        
        
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        
        player.moveAndSlide()
        
        player.fire()
        player.fireSubweapon()
        
        
        
        // Handle animations
        if abs(player.getRealVelocity().x) > 0 {
            if player.input.isActionPressed(.leftShoulder) || !player.yDirection.isZero {
                if !player.yDirection.isZero {
                    player.isAimingDown = player.yDirection < 0
                }
                if player.isAimingDown {
                    player.sprite?.play(name: "run-aim-down")
                    player.aimDiagonalDown()
                } else {
                    player.sprite?.play(name: "run-aim-up")
                    player.aimDiagonalUp()
                }
            } else {
                if Time.getTicksMsec() - player.lastShotTimestamp < player.lastShotAnimationThreshold {
                    player.sprite?.play(name: "run-aim")
                } else {
                    player.sprite?.play(name: "run")
                }
                player.aimForward()
            }
        } else {
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
                        player.sprite?.play(name: "idle-3")
                    }
                    player.aimForward()
                }
            }
        }
        
        
    }
}
