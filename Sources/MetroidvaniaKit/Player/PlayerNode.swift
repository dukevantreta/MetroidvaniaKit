import SwiftGodot

enum CollisionMask: UInt32 {
    case floor = 0b0001
//    case oneWayPlatform = 0b0010 ?
    case player = 0b1_0000_0000
}

@Godot
class PlayerNode: CharacterBody2D {
    
    @SceneTree(path: "CollisionShape2D") var collisionShape: CollisionShape2D?
    @SceneTree(path: "PlayerUpgrades") var upgrades: PlayerUpgrades!
    
    @Export
    var speed: Double = 180.0
    @Export
    var acceleration: Double = 10.0
    @Export
    var deceleration: Double = 80.0
    
    @Export var allowJumpSensitivity: Bool = true
    
    @Export var jumpDuration: Double = 0.5
    
    @Export var linearHeight: Double = 20 // Height up to where gravity is ignored if the player holds the jump button
    @Export var parabolicHeight: Double = 48 // Jump height affected by gravity, after ignore range. Total jump height is the sum of both.
    
    @Export var terminalVelocityFactor: Float = 1.3
    
    @Export var airTime: Double = 0
    
    @Export var wallJumpThresholdMsec: Int = 500
    
    @Export var speedBoostThreshold: Int = 3000
    
    var state: PlayerState = IdleState()
    
    var facingDirection: Int = 1
    
    var canDoubleJump = true
    
    var wallJumpTimestamp: UInt = 0
    
    var isSpeedBoosting = false {
        didSet {
            floorSnapLength = isSpeedBoosting ? 12 : 6
        }
    }
    
    func getGravity() -> Double {
        8 * parabolicHeight / (jumpDuration * jumpDuration)
    }
    
    func getJumpspeed() -> Double {
        (2 * parabolicHeight * getGravity()).squareRoot()
    }
    
    func getCollisionRectSize() -> Vector2? {
        (collisionShape?.shape as? RectangleShape2D)?.size
    }
    
    override func _ready() {
        motionMode = .grounded
        floorBlockOnWall = false
        slideOnCeiling = false // doesnt work on this movement model
        floorSnapLength = 6.0
        collisionMask = 0b1011
    }
    
    override func _physicsProcess(delta: Double) {
        
        if let newState = state.update(self, dt: delta) {
            newState.enter(self)
            state = newState
        }
        
        let faceDirX = Int(velocity.sign().x)
        if faceDirX != 0 && faceDirX != facingDirection {
            facingDirection = faceDirX
        }
    }
    
    func raycastForWall() -> Bool {
        guard let size = getCollisionRectSize(), let space = getWorld2d()?.directSpaceState else { return false }
        
        let origin1 = position + Vector2(x: 0, y: -1)
        let dest1 = origin1 + Vector2(x: (size.x * 0.5 + 1) * Float(facingDirection), y: 0)
        let ray1 = PhysicsRayQueryParameters2D.create(from: origin1, to: dest1, collisionMask: 0b0001)
        
        let origin2 = position + Vector2(x: 0, y: -size.y)
        let dest2 = origin2 + Vector2(x: (size.x * 0.5 + 1) * Float(facingDirection), y: 0)
        let ray2 = PhysicsRayQueryParameters2D.create(from: origin2, to: dest2, collisionMask: 0b0001)
        
        let result1 = space.intersectRay(parameters: ray1)
        let result2 = space.intersectRay(parameters: ray2)
        
        if
            let point1 = result1["position"],
            let point2 = result2["position"]
        {
            return true
        }
        return false
    }
    
    // DEBUG
    override func _process(delta: Double) {
        queueRedraw()
    }
    
    override func _draw() {
        let origin = Vector2(x: 0, y: -14)
        let v = velocity * 0.1
        drawLine(from: origin, to: origin + v, color: .blue)
        drawLine(from: origin, to: origin + Vector2(x: v.x, y: 0), color: .red)
        drawLine(from: origin, to: origin + Vector2(x: 0, y: v.y), color: .green)
        
        let size = getCollisionRectSize() ?? .zero
        
        let rayOrigin1 = Vector2(x: 0, y: -1)
        let rayDest1 = Vector2(x: rayOrigin1.x + (size.x * 0.5 + 1) * Float(facingDirection), y: rayOrigin1.y)
        drawLine(from: rayOrigin1, to: rayDest1, color: .magenta)
        
        let rayOrigin2 = Vector2(x: 0, y: -size.y)
        let rayDest2 = Vector2(x: rayOrigin2.x + (size.x * 0.5 + 1) * Float(facingDirection), y: rayOrigin2.y)
        drawLine(from: rayOrigin2, to: rayDest2, color: .magenta)
    }
}
