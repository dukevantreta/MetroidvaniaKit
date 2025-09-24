import SwiftGodot

@Godot
class CharacterController2D: CharacterBody2D {
    
    @SceneTree(path: "AnimationPlayer") var animationPlayer: AnimationPlayer?
    @SceneTree(path: "Sprite2D") var sprite: Sprite2D?
    
    @Export
    var speed: Double = 180.0
    @Export
    var acceleration: Double = 10.0
    @Export
    var deceleration: Double = 80.0
    
    @Export var allowJumpSensitivity: Bool = true
    
    @Export var jumpDuration: Double = 0.5
    
    @Export var linearHeight: Double = 20
    @Export var parabolicHeight: Double = 48
    
//    @Export var terminalVelocity: Float = 400
    @Export var terminalVelocityFactor: Float = 1.3
    
//    var gravity: Double = Double(ProjectSettings.getSetting(name: "physics/2d/default_gravity", defaultValue: Variant(0.0))) ?? 0.0
    
//    var animation: StringName = ""
    
    override func _ready() {
        motionMode = .grounded
        floorBlockOnWall = false
        slideOnCeiling = false // doesnt work on this movement model
        GD.print("Floor block on wall: \(floorBlockOnWall)")
        GD.print("Slide on ceiling: \(slideOnCeiling)")
//        floorSnapLength = 4.0
    }
    
    @Export var airTime: Double = 0
    
    @Export var wallJumpThresholdMsec: Int = 500
    
    var jumpTimestamp: UInt = 0
    var wallJumpTimestamp: UInt = 0
    
    var isGrabbingWall = false
    
    var startRunningTimestamp: UInt = 0
    var speedBoostThreshold = 3000
    
    var canDoubleJump = true
    
    override func _physicsProcess(delta: Double) {
//        if isInEvent { return }
        
        let gravity = 8 * parabolicHeight / (jumpDuration * jumpDuration)
        let jumpSpeed = isInWater ? (2 * parabolicHeight * gravity).squareRoot() * 0.7 : (2 * parabolicHeight * gravity).squareRoot()
        
        let direction = Input.getAxis(negativeAction: "ui_left", positiveAction: "ui_right")
        
        
        if isOnWallOnly() && Int(getWallNormal().sign().x) == -Int(direction) {
            isGrabbingWall = true
        } else {
            isGrabbingWall = false
        }
        
        var targetSpeed = isInWater ? speed * direction * 0.5 : speed * direction
        if Time.getTicksMsec() - startRunningTimestamp > speedBoostThreshold {
            targetSpeed *= 2
        }
        
        if !isOnFloor() {
            if Time.getTicksMsec() - wallJumpTimestamp > wallJumpThresholdMsec {
                if !direction.isZero {
                    if (velocity.x >= 0 && direction > 0) || (velocity.x <= 0 && direction < 0) {
                        velocity.x = Float(GD.moveToward(from: Double(velocity.x), to: targetSpeed, delta: acceleration))
                    } else {
                        velocity.x = Float(GD.moveToward(from: Double(velocity.x), to: targetSpeed, delta: deceleration))
                    }
                } else {
                    if Time.getTicksMsec() - startRunningTimestamp > speedBoostThreshold {
                    } else {
                        velocity.x = Float(GD.moveToward(from: Double(velocity.x), to: 0, delta: deceleration))
                    }
                }
            }
        } else { // is on floor
//            if velocity.isZeroApprox() {
//                startRunningTimestamp = Time.getTicksMsec()
//            }
            if !direction.isZero {
                if (velocity.x >= 0 && direction > 0) || (velocity.x <= 0 && direction < 0) {
                    velocity.x = Float(GD.moveToward(from: Double(velocity.x), to: targetSpeed, delta: acceleration))
                } else {
                    velocity.x = Float(GD.moveToward(from: Double(velocity.x), to: targetSpeed, delta: deceleration))
                }
            } else {
                startRunningTimestamp = Time.getTicksMsec()
                velocity.x = Float(GD.moveToward(from: Double(velocity.x), to: 0, delta: deceleration))
            }
        }
        
        
        if isOnFloor() {
            canDoubleJump = true
            if Input.isActionJustPressed(action: "ui_accept") {
                velocity.y = Float(-jumpSpeed)
                airTime = 0
                jumpTimestamp = Time.getTicksMsec()
            }
        } else if isGrabbingWall {
            velocity.y = 0
            if Input.isActionJustPressed(action: "ui_accept") {
                velocity.y = Float(-jumpSpeed)
                velocity.x = getWallNormal().sign().x * Float(speed) //* 0.25
                airTime = 0
                jumpTimestamp = Time.getTicksMsec()
                wallJumpTimestamp = Time.getTicksMsec()
            }
        } else {
            let airInterval = Time.getTicksMsec() - jumpTimestamp
            let airHeight = jumpSpeed * Double(airInterval) / 1000
            if Input.isActionJustReleased(action: "ui_accept") && velocity.y < 0 {
                velocity.y = 0
            }
            if Input.isActionPressed(action: "ui_accept") && airHeight < linearHeight && allowJumpSensitivity {
                
            } else {
                velocity.y += Float(gravity * delta)
                
                var terminalVelocity = Float(jumpSpeed) * terminalVelocityFactor
                if isInWater {
                    terminalVelocity *= 0.2
                }
                if velocity.y > terminalVelocity {
                    velocity.y = terminalVelocity
                }
            }
            
            if Input.isActionJustPressed(action: "ui_accept") && canDoubleJump {
                velocity.y = Float(-jumpSpeed)
                jumpTimestamp = Time.getTicksMsec()
                canDoubleJump = false
            }
            
            airTime += delta
        }
        
        moveAndSlide()
    }
    
    var isInWater = false
    
    func enterWater() {
        isInWater = true
        GD.print("ENTER WATER")
    }
    
    func exitWater() {
        isInWater = false
        GD.print("EXIT WATER")
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
    }
}
