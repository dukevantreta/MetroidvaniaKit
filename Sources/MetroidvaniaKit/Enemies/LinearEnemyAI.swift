import SwiftGodot

@Godot
class LinearEnemyAI: EnemyAI {
    
    @Export var speed: Float = 100
    @Export var moveDirection: Vector2 = .zero
    
    var size: Vector2 = .zero
    
    override func _ready() {
        size = Vector2(x: 16, y: 16) // TODO: get size from enemy
    }
    
    override func update(_ enemy: Enemy, delta: Double) {
        let deltaMove = moveDirection * Double(speed) * delta
        enemy.position += deltaMove

        guard let space = getWorld2d()?.directSpaceState else { return }
        let dest = globalPosition + moveDirection * size * 0.5
        let ray = PhysicsRayQueryParameters2D.create(from: globalPosition, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let normal = Vector2(result["normal"]) {
            if !normal.x.isZero {
                moveDirection.x = -moveDirection.x
            }
            if !normal.y.isZero {
                moveDirection.y = -moveDirection.y
            }
        }
    }
}
