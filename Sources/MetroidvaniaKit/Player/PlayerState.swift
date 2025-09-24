import SwiftGodot

protocol PlayerState {
    func enter(_ player: PlayerNode)
    func update(_ player: PlayerNode, dt: Double) -> PlayerState?
}

class IdleState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.sprite?.play(name: "idle-1")
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        let direction = Input.getHorizontalAxis()
        if !direction.isZero {
            return RunningState()
        }
        if Input.isActionJustPressed(.accept) {
            player.velocity.y = Float(-player.getJumpspeed())
            return JumpingState()
        }
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        return nil
    }
}
