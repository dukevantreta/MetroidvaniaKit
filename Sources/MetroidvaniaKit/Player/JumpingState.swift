import SwiftGodot

class JumpingState: PlayerState {
    
    var jumpTimestamp: UInt = 0
    var hasShotDuringJump = false
    
    func enter(_ player: PlayerNode) {
        jumpTimestamp = Time.getTicksMsec()
        player.sprite?.play(name: "jump-begin")
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let yDirection = Input.getVerticalAxis()
        let xDirection = Input.getHorizontalAxis()
        var targetSpeed = player.speed * xDirection
        
        if Input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        
        // Horizontal Movement
        if player.isSpeedBoosting {
            targetSpeed *= 2
        }
        
        if Time.getTicksMsec() - player.wallJumpTimestamp > player.wallJumpThresholdMsec {
            if !xDirection.isZero {
                if (player.velocity.x >= 0 && xDirection > 0) || (player.velocity.x <= 0 && xDirection < 0) {
                    player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
                } else {
                    player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
                }
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration * 0.2))
            }
        }
        
        // Vertical Movement
        let airInterval = Time.getTicksMsec() - jumpTimestamp
        let airHeight = player.getJumpspeed() * Double(airInterval) / 1000
        
        if Input.isActionJustReleased(.action0) && player.velocity.y < 0 { // stop jump mid-air
            player.velocity.y = 0
        }
        if Input.isActionPressed(.action0) && airHeight < player.linearHeight && player.allowJumpSensitivity {
            // do nothing
        } else {
            player.velocity.y += Float(player.getGravity() * dt)
            
            var terminalVelocity = Float(player.getJumpspeed()) * player.terminalVelocityFactor
//            if isInWater {
//                terminalVelocity *= 0.2
//            }
            if player.velocity.y > terminalVelocity {
                player.velocity.y = terminalVelocity
            }
        }
        
        // Mid-air jump
        if Input.isActionJustPressed(.action0) && player.canDoubleJump && player.upgrades.hasDoubleJump {
            player.velocity.y = Float(-player.getJumpspeed())
            jumpTimestamp = Time.getTicksMsec()
            player.canDoubleJump = false
            hasShotDuringJump = false
        }
        
        if abs(player.velocity.x) < Float(player.speed) {
            player.isSpeedBoosting = false
        }
        
        player.moveAndSlide()
        
        if Input.isActionJustPressed(.action1) {
            player.fire()
            player.lastShotTimestamp = Time.getTicksMsec()
            hasShotDuringJump = true
        }
        
        if player.raycastForWall() && Int(player.getWallNormal().sign().x) == -Int(xDirection) && player.upgrades.hasWallGrab {
            return WallGrabState()
        }
        
        if player.isOnFloor() {
            player.sprite?.play(name: "fall-land")
            return RunningState()
        }
        
        // Handle animations
        if abs(player.getRealVelocity().x) > Float(player.speed * 0.8) && !hasShotDuringJump {
            player.sprite?.play(name: "jump-spin")
            if yDirection < 0 {
                player.aimDown()
            } else if yDirection > 0 {
                player.aimUp()
            }
        } else {
            if Input.isActionPressed(.leftShoulder) || (!yDirection.isZero && !xDirection.isZero) {
                if !yDirection.isZero {
                    player.isAimingDown = yDirection < 0
                }
                if player.isAimingDown {
                    player.sprite?.play(name: "jump-aim-diag-down")
                    player.aimDiagonalDown()
                } else {
                    player.sprite?.play(name: "jump-aim-diag-up")
                    player.aimDiagonalUp()
                }
            } else {
                if yDirection < 0 {
                    player.sprite?.play(name: "jump-aim-down")
                    player.aimDown()
                } else if yDirection > 0 {
                    player.sprite?.play(name: "jump-aim-up")
                    player.aimUp()
                } else {
                    if Time.getTicksMsec() - player.lastShotTimestamp < 3000 {
                        player.sprite?.play(name: "jump-aim")
                    } else {
                        player.sprite?.play(name: "jump-still")
                    }
                    player.aimForward()
                }
            }
        }
        return nil
    }
}
