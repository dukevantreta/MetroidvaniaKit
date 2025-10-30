import SwiftGodot
import Foundation

class JumpingState: PlayerState {
    
    let canFire: Bool = true

    var jumpTimestamp: UInt = 0
    var jumpTime: Double = 0.0
    var hasShotDuringJump = false
    var canDoubleJump = false // consumable double jump flag
    var allowsDoubleJump = false // protection flag to prevent triggering double jump during the first frame

    // var isJumpAimDown = false
    // var isAimingUp = false
    var isForward = false
    // var aimY: Float = 0.0

    func enter(_ player: Player) {
        jumpTimestamp = Time.getTicksMsec()
        player.overclockAccumulator = 0.0
        canDoubleJump = true
        allowsDoubleJump = false
        hasShotDuringJump = false
        // isAimingUp = false
        isForward = false
        jumpTime = 0.0
        // player.aimY = 0.0
        player.sprite?.play(name: "jump-begin")
        
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

        if Int64(player.lastShotTimestamp) - Int64(jumpTimestamp) > 0 {
            hasShotDuringJump = true
        }

        if !player.joy1.y.isZero { // toggle
            player.aimY = player.joy1.sign().y
            if player.joy1.x.isZero {
                isForward = false
            }
        }
        if !player.joy1.x.isZero {
            isForward = true
            if player.joy1.y.isZero {
                player.aimY = 0.0
            }
        }


        if player.isAiming {
            if player.aimY < 0.0 {
                player.aimDiagonalDown()
            } else {
                player.aimDiagonalUp()
            }
        } else {
            if player.aimY > 0.0 {
                if isForward {
                    player.aimDiagonalUp()
                } else {
                    player.aimUp()
                }
            } else if player.aimY < 0.0 {
                if isForward {
                    player.aimDiagonalDown()
                } else {
                    player.aimDown()
                }
            } else {
                player.aimForward()
            }
        }

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
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {

        // needs to be cached here, if done in processInput it can lead to a broken jump state
        let isJumpPressed = player.input.isActionPressed(.actionDown)
        let isJumpJustPressed = player.input.isActionJustPressed(.actionDown)
        let isJumpJustReleased = player.input.isActionJustReleased(.actionDown)
        
        if isJumpJustReleased {
            allowsDoubleJump = true
        }
        
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
        
        // Mid-air jump
        if isJumpJustPressed && canDoubleJump && allowsDoubleJump && player.canUse(.doubleJump) {
            player.velocity.y = -player.getJumpspeed()
            jumpTime = 0.0
            canDoubleJump = false
            hasShotDuringJump = false
        }
        
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        
        player.moveAndSlide()

        jumpTime += dt // Update timer AFTER motion
        
        // Handle animations
        if player.isMorphed {
            if abs(player.getRealVelocity().x) > player.data.movespeed * 0.5 {
                player.sprite?.play(name: "mini-jump-spin")
            } else {
                player.sprite?.play(name: "mini-jump")
            }
            return
        }

        if abs(player.getRealVelocity().x) > player.data.movespeed * 0.8 && !hasShotDuringJump {
            player.sprite?.play(name: "jump-spin") // breaks aiming
        } else {
            if player.isAiming {
                if player.aimY < 0.0 {
                    player.sprite?.play(name: "jump-aim-diag-down")
                } else {
                    player.sprite?.play(name: "jump-aim-diag-up")
                }
            } else {
                if player.aimY < 0.0 {
                    if isForward {
                        player.sprite?.play(name: "jump-aim-diag-down")
                    } else {
                        player.sprite?.play(name: "jump-aim-down")
                    }
                } else if player.aimY > 0.0 {
                    if isForward {
                        player.sprite?.play(name: "jump-aim-diag-up")
                    } else {
                        player.sprite?.play(name: "jump-aim-up")
                    }
                } else {
                    if Time.getTicksMsec() - player.lastShotTimestamp < 3000 {
                        player.sprite?.play(name: "jump-aim")
                    } else {
                        player.sprite?.play(name: "jump-still")
                    }
                }
            }
        }
    }
}

// enum PlayerAnimation {

//     case idle
//     case run(mode: Run)
//     case jump(mode: Jump)
    
//     enum Run {
//         case normal
//         case aim(Aim)
//     }
    
//     enum Jump {
//         case still
//         case spin
//         case aim(Aim)
//     }
//     enum Aim {
//         case forward
//         case up
//         case down
//         case diagonalUp
//         case diagonalDown
//     }

//     func check(_ animation: PlayerAnimation) {
//         switch animation {
//         case .idle:
//             break
//         case .run(let mode):
//             switch mode {
//             case .normal:
//                 break
//             case .aim(let aim):
//                 switch aim {
//                 case .forward:
//                     break
//                 case .diagonalDown:
//                     break
//                 case .diagonalUp:
//                     break
//                 case .down:
//                     break
//                 case .up:
//                     break
//                 }
//             }
//         case .jump(let mode):
//             switch mode {
//             case .still:
//                 break
//             case .spin:
//                 break
//             case .aim(let aim):
//                 switch aim {
//                 case .forward:
//                     break
//                 case .diagonalDown:
//                     break
//                 case .diagonalUp:
//                     break
//                 case .down:
//                     break
//                 case .up:
//                     break
//                 }
//             }
//         }
//     }
// }
