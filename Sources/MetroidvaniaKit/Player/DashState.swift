import SwiftGodot

class DashState: PlayerState {
    
    private var xZero: Float = 0.0
    private var dashTime = 0.0
    
    func enter(_ player: PlayerNode) {
        dashTime = 0.0
        xZero = player.position.x
        player.sprite?.play(name: "dash")
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        
        if abs(player.position.x - xZero) >= Float(player.dashDistance) || dashTime >= player.dashTimeLimit {
            return .run
        }
        
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        
        player.velocity.x = Float(player.facingDirection) * player.dashSpeed
        
        player.moveAndSlide()
        
        dashTime += dt
    }
}
