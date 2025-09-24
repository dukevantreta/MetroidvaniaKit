import SwiftGodot

class JumpingState: PlayerState {
    
    var jumpTimestamp: UInt = 0
    var hasShotDuringJump = false
    
    func enter(_ player: PlayerNode) {
        jumpTimestamp = Time.getTicksMsec()
        player.sprite?.play(name: "jump-begin")
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        
        if player.raycastForWall() && Int(player.getWallNormal().sign().x) == -Int(player.xDirection) && player.stats.hasWallGrab {
            return .wallGrab
        }
        
        if player.isOnFloor() {
            player.sprite?.play(name: "fall-land")
            return .run
        }
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        
//        let yDirection = player.input.getVerticalAxis()
//        let xDirection = player.input.getHorizontalAxis()
        var targetSpeed = player.speed * player.xDirection
        
        if player.input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        
        // Horizontal Movement
        if player.isSpeedBoosting {
            targetSpeed *= 2
        }
        
        if Time.getTicksMsec() - player.wallJumpTimestamp > player.wallJumpThresholdMsec {
            if !player.xDirection.isZero {
                if (player.velocity.x >= 0 && player.xDirection > 0) || (player.velocity.x <= 0 && player.xDirection < 0) {
                    player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
                } else {
                    player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
                }
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration * 0.4))
            }
        }
        
        // Vertical Movement
        let airInterval = Time.getTicksMsec() - jumpTimestamp
        let airHeight = player.getJumpspeed() * Double(airInterval) / 1000
        
        if player.input.isActionJustReleased(.action0) && player.velocity.y < 0 { // stop jump mid-air
            player.velocity.y = 0
        }
        if player.input.isActionPressed(.action0) && airHeight < player.linearHeight && player.allowJumpSensitivity {
            // do nothing
        } else {
            player.velocity.y += Float(player.getGravity() * dt)
            
            var terminalVelocity = Float(player.getJumpspeed()) * player.terminalVelocityFactor
            if player.isAffectedByWater {
                terminalVelocity *= 0.2
            }
            if player.velocity.y > terminalVelocity {
                player.velocity.y = terminalVelocity
            }
        }
        
        // Mid-air jump
        if player.input.isActionJustPressed(.action0) && player.canDoubleJump && player.stats.hasDoubleJump {
            player.velocity.y = Float(-player.getJumpspeed())
            jumpTimestamp = Time.getTicksMsec()
            player.canDoubleJump = false
            hasShotDuringJump = false
        }
        
        if abs(player.velocity.x) < Float(player.speed) {
            player.isSpeedBoosting = false
        }
        
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        
        player.moveAndSlide()
        
        if player.fire() {
            hasShotDuringJump = true
        } else if player.fireSubweapon() {
            hasShotDuringJump = true
        }
        
        
        
        // Handle animations
        if abs(player.getRealVelocity().x) > Float(player.speed * 0.8) && !hasShotDuringJump {
            player.sprite?.play(name: "jump-spin")
            if player.yDirection < 0 {
                player.aimDown()
            } else if player.yDirection > 0 {
                player.aimUp()
            }
        } else {
            if player.input.isActionPressed(.leftShoulder) || (!player.yDirection.isZero && !player.xDirection.isZero) {
                if !player.yDirection.isZero {
                    player.isAimingDown = player.yDirection < 0
                }
                if player.isAimingDown {
                    player.sprite?.play(name: "jump-aim-diag-down")
                    player.aimDiagonalDown()
                } else {
                    player.sprite?.play(name: "jump-aim-diag-up")
                    player.aimDiagonalUp()
                }
            } else {
                if player.yDirection < 0 {
                    player.sprite?.play(name: "jump-aim-down")
                    player.aimDown()
                } else if player.yDirection > 0 {
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
    }
}
