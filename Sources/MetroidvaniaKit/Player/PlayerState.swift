import SwiftGodot

protocol PlayerState {
    func enter(_ player: PlayerNode)
    func update(_ player: PlayerNode, dt: Double) -> PlayerState?
}

class IdleState: PlayerState {
    func enter(_ player: PlayerNode) {
        
    }
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        let direction = Input.getHorizontalAxis()
        if !direction.isZero {
            return RunningState()
        }
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        return nil
    }
}
