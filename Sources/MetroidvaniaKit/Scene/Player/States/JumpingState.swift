import SwiftGodot

class JumpingState: PlayerState {
    
    var jumpTimestamp: UInt = 0
    var hasShotDuringJump = false
    var canDoubleJump = false // consumable double jump flag
    var allowsDoubleJump = false // protection flag to prevent triggering double jump during the first frame
    
    func enter(_ player: Player) {
        canDoubleJump = true
        allowsDoubleJump = false
        jumpTimestamp = Time.getTicksMsec()
        player.sprite?.play(name: "jump-begin")
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        
        if player.raycastForWall() && Int(player.getWallNormal().sign().x) == -Int(player.joy1.x) && player.hasUpgrade(.wallGrab) {
            return .wallGrab
        }
        
        if player.isOnFloor() {
            player.sprite?.play(name: "fall-land")
            return .run
        }
        if player.input.isActionJustPressed(.rightShoulder) {
            if player.hasShinesparkCharge && (!player.joy1.x.isZero || !player.joy1.y.isZero) {
                return .charge
            }
            return .dash
        }
        if player.input.isActionJustReleased(.actionDown) {
            allowsDoubleJump = true
        }
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        
        var targetSpeed = player.speed * Double(player.joy1.x)
        
        if player.input.isActionJustPressed(.leftShoulder) {
            player.isAimingDown = false
        }
        
        // Horizontal Movement
        if player.isSpeedBoosting {
            targetSpeed *= 2
        }
        
        if Time.getTicksMsec() - player.wallJumpTimestamp > player.wallJumpThresholdMsec {
            if !player.joy1.x.isZero {
                if (player.velocity.x >= 0 && player.joy1.x > 0) || (player.velocity.x <= 0 && player.joy1.x < 0) {
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
        
        if player.input.isActionJustReleased(.actionDown) && player.velocity.y < 0 { // stop jump mid-air
            player.velocity.y = 0
        }
        if player.input.isActionPressed(.actionDown) && airHeight < player.linearHeight && player.allowJumpSensitivity {
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
        

        // if player.input.isActionJustPressed(.actionDown) {
        //     GD.print("CAN DOUBLE JUMP? \(canDoubleJump) --- HAS UPGRADE? \(player.hasUpgrade(.doubleJump))")
        // }
        // Mid-air jump
        if player.input.isActionJustPressed(.actionDown) && canDoubleJump && allowsDoubleJump && player.hasUpgrade(.doubleJump) {
            player.velocity.y = Float(-player.getJumpspeed())
            jumpTimestamp = Time.getTicksMsec()
            canDoubleJump = false
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
        if player.isMorphed {
            if abs(player.getRealVelocity().x) > Float(player.speed * 0.5) {
                player.sprite?.play(name: "mini-jump-spin")
            } else {
                player.sprite?.play(name: "mini-jump")
            }
            return
        }
        if abs(player.getRealVelocity().x) > Float(player.speed * 0.8) && !hasShotDuringJump {
            player.sprite?.play(name: "jump-spin")
            if player.joy1.y < 0 {
                player.aimDown()
            } else if player.joy1.y > 0 {
                player.aimUp()
            }
        } else {
            if player.input.isActionPressed(.leftShoulder) || (!player.joy1.y.isZero && !player.joy1.x.isZero) {
                if !player.joy1.y.isZero {
                    player.isAimingDown = player.joy1.y < 0
                }
                if player.isAimingDown {
                    player.sprite?.play(name: "jump-aim-diag-down")
                    player.aimDiagonalDown()
                } else {
                    player.sprite?.play(name: "jump-aim-diag-up")
                    player.aimDiagonalUp()
                }
            } else {
                if player.joy1.y < 0 {
                    player.sprite?.play(name: "jump-aim-down")
                    player.aimDown()
                } else if player.joy1.y > 0 {
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
