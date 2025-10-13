import SwiftGodot

@Godot
class NodeAI: Node2D {
    @Export var speed: Float = 0
    @Export var direction: Vector2 = .zero
    @Export var size: Vector2 = .zero
    func update(_ node: Node2D, dt: Double) {}
}