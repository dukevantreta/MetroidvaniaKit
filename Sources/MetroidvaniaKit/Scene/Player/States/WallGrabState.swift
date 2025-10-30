import SwiftGodot

class WallGrabState: PlayerState {

    let canFire: Bool = true
    
    private var lastLookDirection: Float = 0.0
    
    func enter(_ player: Player) {
        player.isOverclocking = false
        player.velocity.x = 0
        player.velocity.y = 0
        lastLookDirection = player.lookDirection
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        player.isAiming = player.input.isActionPressed(.leftShoulder)

        if !player.joy1.y.isZero {
            player.aimY = player.joy1.sign().y
        }

        if player.isAiming || !player.joy1.y.isZero {
            if player.aimY < 0.0 {
                player.aimWallDown()
            } else {
                player.aimWallUp()
            }
        } else {
            player.aimWallForward()
        }

        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = -player.getJumpspeed()
            player.velocity.x = player.getWallNormal().sign().x * player.data.movespeed //* 0.25
            player.wallJumpTimestamp = Time.getTicksMsec()
            return .jump
        } else if Int(player.getWallNormal().sign().x) == Int(player.joy1.x) {
            return .jump
        }
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        
        player.lookDirection = -lastLookDirection
        player.sprite?.flipH = player.lookDirection < 0
        
        if player.isMorphed {
            player.sprite?.play(name: "mini-wall")
            return
        }
        if player.isAiming || !player.joy1.y.isZero {
            if player.aimY < 0.0 {
                player.sprite?.play(name: "wall-aim-down")
            } else {
                player.sprite?.play(name: "wall-aim-up")
            }
        } else {
            player.sprite?.play(name: "wall-aim")
        }
    }
}
