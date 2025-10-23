protocol PlayerState {
    func enter(_ player: Player)
    func processInput(_ player: Player) -> Player.State?
    func processPhysics(_ player: Player, dt: Double)
}