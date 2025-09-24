import SwiftGodot

class DashState: PlayerState {
    
    private var dashTime = 0.0
    
    func enter(_ player: PlayerNode) {
        player.sprite?.play(name: "dash")
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        
        if dashTime > 0.5 {
            return .run
        }
        
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        
        player.velocity.x = Float(player.facingDirection * 200)
        
        player.moveAndSlide()
        
        dashTime += dt
    }
}
