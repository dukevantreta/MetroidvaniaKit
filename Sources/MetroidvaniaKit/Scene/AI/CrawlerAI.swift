import SwiftGodot

// FIXME? Crawler is only working is placed above a platform, not under

@Godot
// class CrawlerEnemyAI: EnemyAI {
class CrawlerAI: NodeAI {
    
    // @Export var speed: Double = 100
    @Export var xdirection: Double = 1
    
    // var moveDirection: Vector2 = .zero
    var floorCheckDirection: Vector2 = .zero
    
    var idleCountdown = 0.1
    var hasTurn = false
    
    // var size: Vector2 = .zero
    
    override func _ready() {
        direction = Vector2(x: xdirection, y: 0)
        floorCheckDirection = Vector2(x: 0, y: 1) // FIXME?
        size = Vector2(x: 16, y: 16) // TODO: get size from enemy
    }
    
    override func update(_ node: Node2D, dt: Double) {
        let delta = dt
        idleCountdown -= delta
        guard idleCountdown <= 0 else { return } // hackish way to skip first frames before floor is ready
        
        let deltaMove: Vector2 = direction * speed * Float(delta)
        node.position += deltaMove
        
        if hasTurn { // allow an extra frame of movement before checking ground again
            hasTurn = false
            return
        }
        
        if raycastForWall() {
            direction = direction.rotated(angle: -.pi * 0.5 * xdirection)
            floorCheckDirection = floorCheckDirection.rotated(angle: -.pi * 0.5 * xdirection)
            node.rotation -= .pi * 0.5 * xdirection
            hasTurn = true
        } else if !raycastForFloor() {
            node.position.x += direction.x * size.x * 0.45 + floorCheckDirection.x * size.x * 0.45
            node.position.y += floorCheckDirection.y * size.y * 0.45 + direction.y * size.y * 0.45
            direction = direction.rotated(angle: .pi * 0.5 * xdirection)
            floorCheckDirection = floorCheckDirection.rotated(angle: .pi * 0.5 * xdirection)
            node.rotation += .pi * 0.5 * xdirection
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
            x: direction.x * (size.x * 0.5),
            y: direction.y * (size.y * 0.5))
        let ray = PhysicsRayQueryParameters2D.create(from: globalPosition, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let point = result["position"] {
            return true
        }
        return false
    }
}
