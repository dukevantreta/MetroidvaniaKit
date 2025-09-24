import SwiftGodot

protocol MovementAI {
    var speed: Float { get }
    var direction: Vector2 { get }
    func update(_ node: Node2D, delta: Double)
}
