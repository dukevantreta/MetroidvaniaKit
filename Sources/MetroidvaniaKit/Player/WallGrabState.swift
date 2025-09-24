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
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let yDirection = player.input.getVerticalAxis()
        let xDirection = player.input.getHorizontalAxis()
        
        player.fire()
        player.fireSubweapon()
        
        if player.input.isActionJustPressed(.action0) {
            player.velocity.y = Float(-player.getJumpspeed())
            player.velocity.x = player.getWallNormal().sign().x * Float(player.speed) //* 0.25
            player.wallJumpTimestamp = Time.getTicksMsec()
            return JumpingState()
        } else if Int(player.getWallNormal().sign().x) == Int(xDirection) {
            return JumpingState()
        }
        
        player.facingDirection = -lastFacingDirection
        player.sprite?.flipH = player.facingDirection < 0
        
        if player.input.isActionPressed(.leftShoulder) || !yDirection.isZero {
            if !yDirection.isZero {
                player.isAimingDown = yDirection < 0
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
        
        return nil
    }
}
