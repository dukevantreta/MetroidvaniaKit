import SwiftGodot

@Godot
class LinearEnemy: Node2D {

    @Export var speed: Float = 100

    @Export var moveDirection: Vector2 = .zero

    func size() -> Vector2 {
        return Vector2(x: 16, y: 16)
    }

    override func _ready() {
    
    }

    override func _physicsProcess(delta: Double) {
        let deltaMove = moveDirection * Double(speed) * delta
        self.position += deltaMove

        guard let space = getWorld2d()?.directSpaceState else { return }
        let dest = position + moveDirection * size() * 0.5
        let ray = PhysicsRayQueryParameters2D.create(from: position, to: dest, collisionMask: 0b1)
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