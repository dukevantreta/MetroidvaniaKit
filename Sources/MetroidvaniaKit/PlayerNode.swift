import SwiftGodot

@Godot
class PlayerNode: CharacterBody2D {
    
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
    
    var state: PlayerState = IdleState()
    
    var facingDirection: Int = 1
    
    func getGravity() -> Double {
        8 * parabolicHeight / (jumpDuration * jumpDuration)
    }
    
    func getJumpspeed() -> Double {
        (2 * parabolicHeight * getGravity()).squareRoot()
    }
    
    override func _ready() {
        motionMode = .grounded
        floorBlockOnWall = false
        slideOnCeiling = false // doesnt work on this movement model
        floorSnapLength = 4.0
        collisionMask = 0b1011
    }
    
    override func _physicsProcess(delta: Double) {
        let lastDirX = Int(getLastMotion().sign().x)
        if lastDirX != 0 && lastDirX != facingDirection {
            facingDirection = lastDirX
        }
        
        if let newState = state.update(self, dt: delta) {
            newState.enter(self)
            state = newState
        }
    }
}

protocol PlayerState {
    func enter(_ player: PlayerNode)
    func update(_ player: PlayerNode, dt: Double) -> PlayerState?
}

class IdleState: PlayerState {
    func enter(_ player: PlayerNode) {
        
    }
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        let direction = Input.getHorizontalAxis()
        if !direction.isZero {
            return RunningState()
        }
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        return nil
    }
}

class RunningState: PlayerState {
    func enter(_ player: PlayerNode) {
        
    }
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        let direction = Input.getHorizontalAxis()
        var targetSpeed = player.speed * direction
        
        if !direction.isZero {
            if (player.velocity.x >= 0 && direction > 0) || (player.velocity.x <= 0 && direction < 0) {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
            }
        } else {
//            startRunningTimestamp = Time.getTicksMsec()
            player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration))
        }
        
        // Jump
        if Input.isActionJustPressed(action: "ui_accept") {
            player.velocity.y = Float(-player.getJumpspeed())
        }
        
        player.moveAndSlide()
        
        if !player.isOnFloor() {
            return JumpingState()
        }
        
        return nil
    }
}

class JumpingState: PlayerState {
    
    var jumpTimestamp: UInt = 0
    
    func enter(_ player: PlayerNode) {
        jumpTimestamp = Time.getTicksMsec()
    }
    
    func update(_ player: PlayerNode, dt: Double) -> PlayerState? {
        
        // Horizontal Movement
        let direction = Input.getHorizontalAxis()
        var targetSpeed = player.speed * direction
        
        if !direction.isZero {
            if (player.velocity.x >= 0 && direction > 0) || (player.velocity.x <= 0 && direction < 0) {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
            }
        } else {
            player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration))
        }
        
        // Vertical Movement
        let airInterval = Time.getTicksMsec() - jumpTimestamp
        let airHeight = player.getJumpspeed() * Double(airInterval) / 1000
        
        if Input.isActionJustReleased(action: "ui_accept") && player.velocity.y < 0 { // stop jump mid-air
            player.velocity.y = 0
        }
        if Input.isActionPressed(action: "ui_accept") && airHeight < player.linearHeight && player.allowJumpSensitivity {
            // do nothing
        } else {
            player.velocity.y += Float(player.getGravity() * dt)
            
            var terminalVelocity = Float(player.getJumpspeed()) * player.terminalVelocityFactor
//            if isInWater {
//                terminalVelocity *= 0.2
//            }
            if player.velocity.y > terminalVelocity {
                player.velocity.y = terminalVelocity
            }
        }
        
        player.moveAndSlide()
        
        if player.isOnFloor() {
            return RunningState()
        }
        
        return nil
    }
}
