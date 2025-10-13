import SwiftGodot

@Godot
class LinearBounceAI: NodeAI {
    
    // @Export var speed: Float = 100
    // @Export var direction: Vector2 = .zero
    
    // var size: Vector2 = .zero
    
    override func _ready() {
        size = Vector2(x: 16, y: 16) // TODO: get size from enemy
    }
    
    override func update(_ node: Node2D, dt: Double) {
        let delta = dt
        let enemy = node
        let deltaMove = direction * Double(speed) * delta
        enemy.position += deltaMove

        guard let space = getWorld2d()?.directSpaceState else { return }
        let dest = globalPosition + direction * size * 0.5
        let ray = PhysicsRayQueryParameters2D.create(from: globalPosition, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let normal = Vector2(result["normal"]) {
            if !normal.x.isZero {
                direction.x = -direction.x
            }
            if !normal.y.isZero {
                direction.y = -direction.y
            }
        }
    }
}
