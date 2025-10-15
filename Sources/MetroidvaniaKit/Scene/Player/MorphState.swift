import SwiftGodot

class MorphState: PlayerState {
    
    var jumpTimestamp: UInt = 0
    
    func enter(_ player: Player) {
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 14)
            player.hitbox?.position = Vector2(x: 0, y: -7)
        }
        if let collisionRect = player.collisionShape?.shape as? RectangleShape2D {
            collisionRect.size = Vector2(x: 14, y: 14)
            player.collisionShape?.position = Vector2(x: 0, y: -7)
        }
        player.sprite?.play(name: "cube")
    }
    
    func processInput(_ player: Player) -> Player.State? {
        // Unmorph
        if player.input.isActionJustPressed(.up) && player.isOnFloor() {
            if !player.raycastForUnmorph() {
                if let rect = player.collisionShape?.shape as? RectangleShape2D {
                    rect.size = Vector2(x: 14, y: 30)
                    player.collisionShape?.position = Vector2(x: 0, y: -15)
                }
                return .crouch
            }
        }
        return nil
    }
    
    func processPhysics(_ player: Player, dt: Double) {
        
        let xDirection = player.input.getHorizontalAxis()
        
        
        
        // Jump
        if player.input.isActionJustPressed(.actionDown) && player.isOnFloor() {
            player.velocity.y = Float(-player.getJumpspeed())
        }
        
        // Horizontal movement
        if !xDirection.isZero {
            let targetSpeed = player.speed * xDirection
            if (player.velocity.x >= 0 && xDirection > 0) || (player.velocity.x <= 0 && xDirection < 0) {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.acceleration))
            } else {
                player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: targetSpeed, delta: player.deceleration))
            }
        } else {
            player.velocity.x = Float(GD.moveToward(from: Double(player.velocity.x), to: 0, delta: player.deceleration))
        }
        
        if !player.isOnFloor() {
            let jumpspeed = player.getJumpspeed()
            let airInterval = Time.getTicksMsec() - jumpTimestamp
            let airHeight = jumpspeed * Double(airInterval) / 1000
            
            if player.input.isActionJustReleased(.actionDown) && player.velocity.y < 0 { // stop jump mid-air
                player.velocity.y = 0
            }
            if player.input.isActionPressed(.actionDown) && airHeight < player.linearHeight && player.allowJumpSensitivity {
                // do nothing
            } else {
                player.velocity.y += Float(player.getGravity() * dt)
                
                var terminalVelocity = Float(jumpspeed) * player.terminalVelocityFactor
                if player.isAffectedByWater {
                    terminalVelocity *= 0.2
                }
                if player.velocity.y > terminalVelocity {
                    player.velocity.y = terminalVelocity
                }
            }
        }
        
        if player.isAffectedByWater {
            player.velocity *= 0.9
        }
        
        player.moveAndSlide()
    }
}
