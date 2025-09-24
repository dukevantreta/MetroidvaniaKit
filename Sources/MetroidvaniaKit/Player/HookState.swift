import SwiftGodot

class HookState: PlayerState {
    
    var direction: Vector2 = .zero
    
    var frameCount = 0
    
    func enter(_ player: PlayerNode) {
        direction = player.hookshot?.direction ?? .zero
        frameCount = 0
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        
//        if let collision = player.getLastSlideCollision() {
//            player.hookshot?.deactivate()
//            return .jump
//        }
        
//        if player.position - player.hookshot?.position
        player.velocity.x = direction.x * 700
        player.velocity.y = direction.y * 700
        
        if frameCount > 3 {
            player.hookshot?.deactivate()
            return .jump
        }
        
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        
        player.moveAndSlide()
        
        frameCount += 1
    }
}
