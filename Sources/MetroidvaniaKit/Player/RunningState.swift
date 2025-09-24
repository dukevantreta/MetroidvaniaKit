import SwiftGodot

class RunningState: PlayerState {
    
    var isFirstRunningFrame: Bool = true
    var startRunningTimestamp: UInt = 0
    
    var lastActionTimestamp: UInt = 0
    
    func enter(_ player: PlayerNode) {
        player.canDoubleJump = true
        startRunningTimestamp = Time.getTicksMsec()
        lastActionTimestamp = Time.getTicksMsec()
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let yDirection = Input.getVerticalAxis()
        let xDirection = Input.getHorizontalAxis()
        var targetSpeed = player.speed * xDirection
        
        if Input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        
        // Speed booster turn on
        if Time.getTicksMsec() - startRunningTimestamp > player.speedBoostThreshold && player.upgrades.hasSpeedBooster {
            player.isSpeedBoosting = true
        }
        if player.isSpeedBoosting {
            targetSpeed *= 2
        }
        
        // Horizontal movement
        if !xDirection.isZero {
            lastActionTimestamp = Time.getTicksMsec()
            if isFirstRunningFrame {
                startRunningTimestamp = Time.getTicksMsec()
                isFirstRunningFrame = false
            }
            if (player.velocity.x >= 0 && xDirection > 0) || (player.velocity.x <= 0 && xDirection < 0) {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
            }
        } else {
            player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration))
            
            if yDirection < 0 && !Input.isActionPressed(.leftShoulder) {
                player.sprite?.spriteFrames?.setAnimationLoop(anim: "stand-to-crouch", loop: false)
                player.sprite?.play(name: "stand-to-crouch")
                return CrouchState()
            }
        }
        
        // Speed booster cancel
        if abs(player.velocity.x) < Float(player.speed) * 0.9 || player.getRealVelocity().x == 0 {
            isFirstRunningFrame = true
            startRunningTimestamp = Time.getTicksMsec()
            player.isSpeedBoosting = false
        }
        
        // Jump
        if Input.isActionJustPressed(.action0) {
            lastActionTimestamp = Time.getTicksMsec()
            player.velocity.y = Float(-player.getJumpspeed())
        }
        
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        
        player.moveAndSlide()
        
        if Input.isActionJustPressed(.action1) {
            player.fire()
            player.lastShotTimestamp = Time.getTicksMsec()
        }
        
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        // Handle animations
        if abs(player.getRealVelocity().x) > 0 {
            if Input.isActionPressed(.leftShoulder) || !yDirection.isZero {
                if !yDirection.isZero {
                    player.isAimingDown = yDirection < 0
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
                        player.sprite?.play(name: "idle-3")
                    }
                    player.aimForward()
                }
            }
        }
        
        if Time.getTicksMsec() - lastActionTimestamp > player.idleAnimationThreshold {
            return IdleState()
        }
        
        return nil
    }
}
