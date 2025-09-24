import SwiftGodot

class WallGrabState: PlayerState {
    
    private var lastFacingDirection: Int = 0
    
    func enter(_ player: PlayerNode) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isSpeedBoosting = false
        player.sprite?.play(name: "wall-aim")
        lastFacingDirection = player.facingDirection
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let direction = Input.getHorizontalAxis()
        
        if Input.isActionJustPressed(.action0) {
            player.velocity.y = Float(-player.getJumpspeed())
            player.velocity.x = player.getWallNormal().sign().x * Float(player.speed) //* 0.25
            player.wallJumpTimestamp = Time.getTicksMsec()
            return JumpingState()
        } else if Int(player.getWallNormal().sign().x) == Int(direction) {
            return JumpingState()
        }
        
        player.facingDirection = -lastFacingDirection
        player.sprite?.flipH = player.facingDirection < 0
        
        return nil
    }
}
