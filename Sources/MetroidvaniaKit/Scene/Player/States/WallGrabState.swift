import SwiftGodot

class WallGrabState: PlayerState {

    let canFire: Bool = true
    
    private var lastLookDirection: Float = 0.0
    
    func enter(_ player: Player) {
        player.isOverclocking = false
        player.velocity.x = 0
        player.velocity.y = 0
        lastLookDirection = player.lookDirection
        
        // if let hitboxRect = player.pHitbox?.shape as? RectangleShape2D {
        //     hitboxRect.size = Vector2(x: 14, y: 36)
        //     player.pHitbox?.position = Vector2(x: 0, y: -18)
        // }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        // no cancel diagonal on L press or release

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
            player.play(.miniWall)
            return
        }

        if player.isAiming || !player.joy1.y.isZero {
            if player.aimPriority.y < 0.0 {
                player.aimWallDown()
                player.play(.wallAimDown)
            } else {
                player.aimWallUp()
                player.play(.wallAimUp)
            }
        } else {
            player.aimWallForward()
            player.play(.wallAim)
        }
    }
}
