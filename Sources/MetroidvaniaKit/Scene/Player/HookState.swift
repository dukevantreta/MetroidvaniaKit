import SwiftGodot

class HookState: PlayerState {
    
    var direction: Vector2 = .zero
    
    var targetPosition: Vector2 = .zero
    
    var frameCount = 0
    
    var shouldEnd = false
    
    func enter(_ player: PlayerNode) {
        targetPosition = player.position + (player.hookshot?.position ?? .zero)
        direction = player.hookshot?.direction ?? .zero
        frameCount = 0
        shouldEnd = false
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        
        if shouldEnd {
            if direction.y.isZero {
                player.velocity.y = -300
            } else {
                player.velocity.y = direction.y * player.hookLaunchSpeed
            }
            player.velocity.x = direction.x * player.hookLaunchSpeed
            return .jump
        }
        
        if let collision = player.getLastSlideCollision(), frameCount > 1 {
            player.hookshot?.deactivate()
            player.velocity.x = 0
            player.velocity.y = 0
            return .jump
        }
        
//        if let hookPosition = player.hookshot?.position {
        
//        }
//        if player.position - player.hookshot?.position
        
        
//        if frameCount > 3 {
//            player.hookshot?.deactivate()
//            return .jump
//        }
        
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        
//        let deltaMove = Vector2(
//            x: abs(direction.x * 500 * Float(dt)),
//            y: abs(direction.y * 500 * Float(dt))
//        )
//        let dot = (targetPosition - player.position).dot(with: direction)
        if (targetPosition - player.position).dot(with: direction) < 0.0 {
            shouldEnd = true
        } else {
            player.velocity.x = direction.x * 500
            player.velocity.y = direction.y * 500
        }
        
//        player.velocity.x = direction.x * 500
//        player.velocity.y = direction.y * 500
        
        player.moveAndSlide()
        
        frameCount += 1
    }
}
