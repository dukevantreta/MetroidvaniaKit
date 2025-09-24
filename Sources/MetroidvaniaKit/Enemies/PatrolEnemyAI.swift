import SwiftGodot

@Godot
class PatrolEnemyAI: Node2D, EnemyAI {
    
    enum State {
        case idle
        case patrol
    }
    
    @Export var speed: Float = 100
    @Export var direction: Float = 1
    @Export var idleTime: Double = 2
    
    private var state: State = .idle
    private var idleCountdown: Double = 0
    private var size: Vector2 = .zero
    
    override func _ready() {
        idleCountdown = idleTime
        size = Vector2(x: 16, y: 16) // TODO: get size from enemy
    }
    
    func update(_ enemy: Enemy, delta: Double) {
        switch state {
        
        case .idle:
            idleCountdown -= delta
            if idleCountdown <= 0 {
                state = .patrol
            }
            
        case .patrol:
            let deltaMove = Vector2(x: direction * speed * Float(delta), y: 0)
            if raycastForFloor() && !raycastForWall(deltaMove) {
                enemy.position += deltaMove
            } else {
                direction = -direction
                idleCountdown = idleTime
                state = .idle
            }
        }
    }
    
    func raycastForWall(_ deltaMove: Vector2) -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        let origin = Vector2(
            x: globalPosition.x,
            y: globalPosition.y - 1)
        let dest = origin + Vector2(x: (size.x * 0.5 + deltaMove.x) * direction, y: 0)
        let ray = PhysicsRayQueryParameters2D.create(from: origin, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let point = result["position"] {
            return true
        }
        return false
    }
    
    func raycastForFloor() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        let origin = Vector2(
            x: globalPosition.x + (size.x * 0.5 * direction),
            y: globalPosition.y - 1)
        let dest = origin + Vector2(x: 0, y: 5)
        let ray = PhysicsRayQueryParameters2D.create(from: origin, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let point = result["position"] {
            return true
        }
        return false
    }
}
