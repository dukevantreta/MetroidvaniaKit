import SwiftGodot

fileprivate let playerMask = 0b1_00000000

@Godot
class TriggerArea2D: Area2D {
    
    override func _ready() {
        bodyEntered.connect { body in
            if body.isClass("\(CharacterController2D.self)") {
                GD.print("Player entered area")
            }
            if let collisionBody = body as? CollisionObject2D {
                let isPlayer = (collisionBody.collisionLayer & 0b1_00000000) != 0
                let isFloor = (collisionBody.collisionLayer & 0b01) != 0
                GD.print("collision layer: \(collisionBody.collisionLayer)")
                GD.print("Is player?: \(isPlayer)")
                GD.print("Is floor?: \(isFloor)")
            }
        }
    }
}
