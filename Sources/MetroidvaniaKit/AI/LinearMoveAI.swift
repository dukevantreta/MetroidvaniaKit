import SwiftGodot

@Godot
class LinearMoveAI: NodeAI {
    override func update(_ node: Node2D, dt: Double) {
        node.position.x += speed * direction.x * Float(dt)
        node.position.y += speed * direction.y * Float(dt)
    }
}