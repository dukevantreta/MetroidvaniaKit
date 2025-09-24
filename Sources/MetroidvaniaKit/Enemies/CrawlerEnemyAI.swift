import SwiftGodot

@Godot
class CrawlerEnemyAI: Node2D, EnemyAI {
    
    @Export var speed: Double = 100
    @Export var direction: Double = 1
    
    var moveDirection: Vector2 = .zero
    var floorCheckDirection: Vector2 = .zero
    
    var idleCountdown = 0.1
    var hasTurn = false
    
    var size: Vector2 = .zero
    
    override func _ready() {
        moveDirection = Vector2(x: direction, y: 0)
        floorCheckDirection = Vector2(x: 0, y: 1)
        size = Vector2(x: 16, y: 16) // TODO: get size from enemy
    }
    
    func update(_ enemy: Enemy, delta: Double) {
        idleCountdown -= delta
        guard idleCountdown <= 0 else { return } // hackish way to skip first frames before floor is ready
        
        let deltaMove = moveDirection * speed * delta
        enemy.position += deltaMove
        
        if hasTurn { // allow an extra frame of movement before checking ground again
            hasTurn = false
            return
        }
        
        if raycastForWall() {
            moveDirection = moveDirection.rotated(angle: -.pi * 0.5 * direction)
            floorCheckDirection = floorCheckDirection.rotated(angle: -.pi * 0.5 * direction)
            enemy.rotation -= .pi * 0.5 * direction
            hasTurn = true
        } else if !raycastForFloor() {
            enemy.position.x += moveDirection.x * size.x * 0.45 + floorCheckDirection.x * size.x * 0.45
            enemy.position.y += floorCheckDirection.y * size.y * 0.45 + moveDirection.y * size.y * 0.45
            moveDirection = moveDirection.rotated(angle: .pi * 0.5 * direction)
            floorCheckDirection = floorCheckDirection.rotated(angle: .pi * 0.5 * direction)
            enemy.rotation += .pi * 0.5 * direction
            hasTurn = true
        }
    }
    
    func raycastForFloor() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        let dest = globalPosition + Vector2(
            x: floorCheckDirection.x * (size.x * 0.5 + 2),
            y: floorCheckDirection.y * (size.y * 0.5 + 2))
        let ray = PhysicsRayQueryParameters2D.create(from: globalPosition, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let point = result["position"] {
            return true
        }
        return false
    }
    
    func raycastForWall() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        let dest = globalPosition + Vector2(
            x: moveDirection.x * (size.x * 0.5),
            y: moveDirection.y * (size.y * 0.5))
        let ray = PhysicsRayQueryParameters2D.create(from: globalPosition, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let point = result["position"] {
            return true
        }
        return false
    }
}
