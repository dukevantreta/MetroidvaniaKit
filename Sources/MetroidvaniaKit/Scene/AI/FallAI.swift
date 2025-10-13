import SwiftGodot

@Godot
class FallAI: NodeAI {

    var velocity: Vector2 = .zero

    var gravity: Float = 600

    override func _ready() {
        velocity = direction * speed //Vector2(x: direction.x * speed, y: Double)
    }

    override func update(_ node: Node2D, dt: Double) {
        velocity.y += gravity * Float(dt)

        node.position += velocity * dt
        // node.position.x += velocity.x * direction.x * Float(dt)
        // node.position.x += speed * direction.x * Float(dt)
        // node.position.y += speed * direction.y * Float(dt)
    }
}