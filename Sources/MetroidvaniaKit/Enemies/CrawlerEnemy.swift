import SwiftGodot

@Godot
class CrawlerEnemy: Node2D {
    
    @Export var speed: Float = 100
    
    @Export var direction: Double = 1
    
    var moveDirection: Vector2 = .zero
    var floorCheckDirection: Vector2 = .zero
    
    var idleCountdown = 0.1
    var hasTurn = false
    
    func size() -> Vector2 {
        return Vector2(x: 16, y: 16)
    }
    
    override func _ready() {
        moveDirection = Vector2(x: direction, y: 0)
        floorCheckDirection = Vector2(x: 0, y: 1)
    }
    
    override func _physicsProcess(delta: Double) {
        idleCountdown -= delta
        guard idleCountdown <= 0 else { return } // hackish way to skip first frames before floor is ready
        
        let deltaMove = moveDirection * Double(speed) * delta
        self.position += deltaMove
        
        if hasTurn { // allow an extra frame of movement before checking ground again
            hasTurn = false
            return
        }
        
        if raycastForWall() {
            moveDirection = moveDirection.rotated(angle: -.pi * 0.5 * direction)
            floorCheckDirection = floorCheckDirection.rotated(angle: -.pi * 0.5 * direction)
            self.rotation -= .pi * 0.5 * direction
            hasTurn = true
        } else if !raycastForFloor() {
            position.x += moveDirection.x * size().x * 0.45 + floorCheckDirection.x * size().x * 0.45
            position.y += floorCheckDirection.y * size().y * 0.45 + moveDirection.y * size().y * 0.45
            moveDirection = moveDirection.rotated(angle: .pi * 0.5 * direction)
            floorCheckDirection = floorCheckDirection.rotated(angle: .pi * 0.5 * direction)
            self.rotation += .pi * 0.5 * direction
            hasTurn = true
        }
    }
    
    func raycastForFloor() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        let dest = position + Vector2(
            x: floorCheckDirection.x * (size().x * 0.5 + 2),
            y: floorCheckDirection.y * (size().y * 0.5 + 2))
        let ray = PhysicsRayQueryParameters2D.create(from: position, to: dest, collisionMask: 0b1)
        let result = space.intersectRay(parameters: ray)
        if let point = result["position"] {
            return true
        }
        return false
    }
    
    func raycastForWall() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        let dest = position + Vector2(
            x: moveDirection.x * (size().x * 0.5),
            y: moveDirection.y * (size().y * 0.5))
        let ray = PhysicsRayQueryParameters2D.create(from: position, to: dest, collisionMask: 0b1)
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
        let origin1 = position
        let dest1 = position + Vector2(
            x: floorCheckDirection.x * (size().x * 0.5 + 2),
            y: floorCheckDirection.y * (size().y * 0.5 + 2))
        drawLine(from: origin1, to: dest1, color: .blue)
    }
}
