import SwiftGodot

@Godot
class PatrolEnemy: Node2D {
    
    enum State {
        case idle
        case patrol
    }
    
//    @SceneTree(path: "CollisionShape2D") weak var collisionShape: CollisionShape2D?
    
    @Export var speed: Float = 100
    
    @Export var direction: Float = 1
    
    @Export var idleTime: Double = 2
    
    private var state: State = .idle
    
    private var facingDirection: Int = 1 // remove?
    
    private var idleCountdown: Double = 0
    
    func getCollisionRectSize() -> Vector2 {
//        (collisionShape?.shape as? RectangleShape2D)?.size ?? .zero
        return Vector2(x: 16, y: 16)
    }
    
    override func _ready() {
        idleCountdown = idleTime
    }
    
    override func _physicsProcess(delta: Double) {
        switch state {
        
        case .idle:
            idleCountdown -= delta
            if idleCountdown <= 0 {
                state = .patrol
            }
            
        case .patrol:
            let deltaMove = Vector2(x: direction * speed * Float(delta), y: 0)
            if raycastForFloor() && !raycastForWall(deltaMove) {
                self.position += deltaMove
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
            x: position.x,
            y: position.y - 1)
        let dest = origin + Vector2(x: (getCollisionRectSize().x * 0.5 + deltaMove.x) * direction, y: 0)
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
            x: position.x + (getCollisionRectSize().x * 0.5 * direction),
            y: position.y - 1)
        let dest = origin + Vector2(x: 0, y: 5)
        let ray = PhysicsRayQueryParameters2D.create(from: origin, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let point = result["position"] {
            return true
        }
        return false
    }
    
    override func _process(delta: Double) {
        queueRedraw()
    }
    
    override func _draw() {
        let origin1 = Vector2(x: (getCollisionRectSize().x * 0.5 * direction), y: -1)
        let dest1 = origin1 + Vector2(x: 0, y: 5)
        drawLine(from: origin1, to: dest1, color: .red)
    }
}
