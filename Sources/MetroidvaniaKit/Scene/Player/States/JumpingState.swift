import SwiftGodot
import Foundation

class JumpingState: PlayerState {
    
    let canFire: Bool = true

    var jumpTimestamp: UInt = 0
    var jumpTime: Double = 0.0
    var canDoubleJump = false // consumable double jump flag

    func enter(_ player: Player) {
        jumpTimestamp = Time.getTicksMsec()
        player.overclockAccumulator = 0.0
        canDoubleJump = true
        player.aimPriority.x = 0.0
        jumpTime = 0.0
        player.sprite?.play(name: "jump-begin")

        if !player.isAiming {
            player.aimPriority.y = 0.0
        }
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {

        if player.raycastForWall() && Int(player.getWallNormal().sign().x) == -Int(player.joy1.x) && player.canUse(.wallGrab) {
            let xNormal = Int(player.getWallNormal().sign().x)
            if xNormal > 0 {
                player.position.x =  player.position.x.rounded(.down)
            } else if xNormal < 0 {
                player.position.x =  player.position.x.rounded(.up)
            }
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

        // Mid-air jump
        let isJumpJustPressed = player.input.isActionJustPressed(.actionDown)
        if isJumpJustPressed && canDoubleJump && player.canUse(.doubleJump) {
            player.velocity.y = -player.getJumpspeed()
            canDoubleJump = false
            jumpTimestamp = Time.getTicksMsec()
            jumpTime = 0.0
        }

        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        let hasShotDuringJump = player.lastShotTimestamp > jumpTimestamp

        // needs to be cached here, if done in processInput it can lead to a broken jump state
        let isJumpPressed = player.input.isActionPressed(.actionDown)
        let isJumpJustReleased = player.input.isActionJustReleased(.actionDown)
        
        player.updateHorizontalMovement(dt)
        
        // NOTE: This breaks with any vertical impulse-based mechanics (verified with hookshot)
        if isJumpJustReleased && player.velocity.y < 0 {
            player.velocity.y = 0 // stop jump mid-air
        }
        let height = player.getJumpspeed() * Float(jumpTime)
        if isJumpPressed && player.velocity.y < 0 && height < player.linearHeight && player.data.allowJumpSensitivity {
            // do nothing
        } else {
            player.velocity.y += player.getGravity() * Float(dt)
            player.enforceVerticalSpeedCap()
        }
        
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        
        player.moveAndSlide()

        jumpTime += dt // Update timer AFTER motion
        
        // Handle animations
        if player.isMorphed {
            if abs(player.getRealVelocity().x) > player.data.movespeed * 0.5 {
                player.play(.miniJumpSpin)
            } else {
                player.play(.miniJump)
            }
            return
        }

        if abs(player.getRealVelocity().x) > player.data.movespeed * 0.8 && !hasShotDuringJump {
            player.play(.jumpSpin) // breaks aiming?
        } else {
            if player.aimPriority.y > 0.0 {
                if player.aimPriority.x > 0.0 || player.isAiming {
                    player.aimDiagonalUp()
                    player.play(.jumpAimDiagonalUp)
                } else {
                    player.aimUp()
                    player.play(.jumpAimUp)
                }
            } else if player.aimPriority.y < 0.0 {
                if player.aimPriority.x > 0.0 || player.isAiming {
                    player.aimDiagonalDown()
                    player.play(.jumpAimDiagonalDown)
                } else {
                    player.aimDown()
                    player.play(.jumpAimUp)
                }
            } else {
                player.aimForward()
                if Time.getTicksMsec() - player.lastShotTimestamp < 3000 {
                    player.play(.jumpAim)
                } else {
                    player.play(.jumpStill)
                }
            }
        }
    }
}