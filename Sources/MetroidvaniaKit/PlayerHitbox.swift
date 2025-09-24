import SwiftGodot

@Godot
class PlayerHitbox: Area2D {
    
    @SceneTree(path: "..") var player: CharacterController2D?
    
    override func _ready() {
        guard let player else {
            GD.print("PLAYER NOT FOUND")
            return
        }
        collisionMask |= 0b00000100
        
        areaEntered.connect { [weak self] area in
            if let collisionArea = area as? CollisionObject2D {
                if (collisionArea.collisionLayer & 0b00000100) != 0 {
                    self?.player?.enterWater()
                }
            }
        }
        areaExited.connect { [weak self] area in
            if let collisionArea = area as? CollisionObject2D {
                if (collisionArea.collisionLayer & 0b00000100) != 0 {
                    self?.player?.exitWater()
                }
            }
        }
    }
}
