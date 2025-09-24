import SwiftGodot

class CrouchState: PlayerState {
    
    func enter(_ player: PlayerNode) {
        player.velocity.x = 0
        player.velocity.y = 0
        player.isSpeedBoosting = false
        
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 24)
            player.hitbox?.position = Vector2(x: 0, y: -12)
        }
    }
    
    func update(_ player: PlayerNode, dt: Double) -> (any PlayerState)? {
        
        let yDirection = Input.getVerticalAxis()
        let xDirection = Input.getHorizontalAxis()
        
        if Input.isActionJustPressed(.action1) {
            player.fire()
            player.lastShotTimestamp = Time.getTicksMsec()
        }
        
        // Jump
        if Input.isActionJustPressed(.action0) {
            player.velocity.y = Float(-player.getJumpspeed())
            exit(player)
            return JumpingState()
        }
        
        // Stand
        if Input.isActionJustPressed(action: "ui_up") || !xDirection.isZero {
            exit(player)
            return RunningState()
        }
        
        // Morph
        if Input.isActionJustPressed(action: "ui_down") {
            return MorphState()
        }
        
        // Sanity trigger
        if !player.isOnFloor() {
            exit(player)
            return JumpingState()
        }
        
        // Handle animations
        if Input.isActionPressed(.leftShoulder) {
            player.sprite?.play(name: "crouch-aim-up")
            player.aimCrouchUp()
        } else {
            if player.sprite?.animation != "stand-to-crouch" {
                player.sprite?.play(name: "crouch-aim")
            }
            player.aimCrouchForward()
        }
        
        return nil
    }
    
    // This is not good for hurt event
    func exit(_ player: PlayerNode) {
        if let hitboxRect = player.hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 36)
            player.hitbox?.position = Vector2(x: 0, y: -18)
        }
    }
}
