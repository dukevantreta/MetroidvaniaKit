import SwiftGodot

class WallGrabState: PlayerState {
    
    private var lastFacingDirection: Int = 0
    
    func enter(_ player: PlayerNode) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isSpeedBoosting = false
        lastFacingDirection = player.facingDirection
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        if player.input.isActionJustPressed(.actionDown) {
            player.velocity.y = Float(-player.getJumpspeed())
            player.velocity.x = player.getWallNormal().sign().x * Float(player.speed) //* 0.25
            player.wallJumpTimestamp = Time.getTicksMsec()
            return .jump
        } else if Int(player.getWallNormal().sign().x) == Int(player.xDirection) {
            return .jump
        }
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        
//        let yDirection = player.input.getVerticalAxis()
//        let xDirection = player.input.getHorizontalAxis()
        
        player.fire()
        player.fireSubweapon()
        
        
        player.facingDirection = -lastFacingDirection
        player.sprite?.flipH = player.facingDirection < 0
        
        if player.input.isActionPressed(.leftShoulder) || !player.yDirection.isZero {
            if !player.yDirection.isZero {
                player.isAimingDown = player.yDirection < 0
            }
            if player.isAimingDown {
                player.sprite?.play(name: "wall-aim-down")
                player.aimWallDown()
            } else {
                player.sprite?.play(name: "wall-aim-up")
                player.aimWallUp()
            }
        } else {
            player.sprite?.play(name: "wall-aim")
            player.aimForward()
        }
    }
}
