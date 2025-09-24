import SwiftGodot

class ShinesparkState: PlayerState {
    
    var direction: Vector2 = .zero
    
    private var collisionTime = 0.0
    private var collided = false
    private var chainShinespark = false
    
    func enter(_ player: PlayerNode) {
        collisionTime = 0.0
        collided = false
        chainShinespark = false
        player.hasShinesparkCharge = false
        player.sprite?.modulate = .orange
        direction = Vector2(x: player.xDirection, y: player.yDirection)
        player.sprite?.play(name: "dash")
    }
    
    func processInput(_ player: PlayerNode) -> PlayerNode.State? {
        if chainShinespark {
            player.sprite?.modulate = .white
            player.velocity.x = Float(player.speed * player.xDirection * 2)
            player.isSpeedBoosting = true
            return .run
        }
        if collisionTime > 0.7 {
            player.sprite?.modulate = .white
            return .jump
        }
        return nil
    }
    
    func processPhysics(_ player: PlayerNode, dt: Double) {
        if !collided {
            player.velocity.x = direction.sign().x * 500
            player.velocity.y = -direction.sign().y * 500
            collided = player.moveAndSlide()
        }
        if collided {
            player.velocity.x = 0.0
            player.velocity.y = 0.0
            if let collision = player.getLastSlideCollision() {
                let normal = collision.getNormal()
                GD.print("NORMAL: \(normal)")
                if !normal.x.isZero && normal.y < 0 {
                    chainShinespark = true
                }
            }
            collisionTime += dt
        }
    }
}
