import SwiftGodot

class DashState: PlayerState {

    let canFire: Bool = false
    
    private var xZero: Float = 0.0
    private var dashTime = 0.0
    
    func enter(_ player: Player) {
        player.isOverclocking = false
        dashTime = 0.0
        xZero = player.position.x
        player.velocity.y = 0.0
        if player.isMorphed {
            player.play(.miniDash)
        } else {
            player.play(.dash)
        }
    }
    
    func processInput(_ player: Player) -> Player.State? {
        
        if abs(player.position.x - xZero) >= Float(player.dashDistance) || dashTime >= player.dashTimeLimit {
            return .run
        }
        
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        
        player.velocity.x = player.lookDirection * player.dashSpeed
        
        player.moveAndSlide()
        
        dashTime += dt
    }
}
