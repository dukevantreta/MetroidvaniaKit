import SwiftGodot

class WallGrabState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isSpeedBoosting = false
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let direction = Input.getHorizontalAxis()
        
        if Input.isActionJustPressed(action: "ui_accept") {
            player.velocity.y = Float(-player.getJumpspeed())
            player.velocity.x = player.getWallNormal().sign().x * Float(player.speed) //* 0.25
            player.wallJumpTimestamp = Time.getTicksMsec()
            return JumpingState()
        } else if Int(player.getWallNormal().sign().x) == Int(direction) {
            return JumpingState()
        }
        
        return nil
    }
}
