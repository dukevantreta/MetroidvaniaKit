import SwiftGodot

@Godot
class SidescrollerCamera: Camera2D {
    
//    @Export var target: CharacterController2D?
//    @SceneTree(path: "../CharacterController2D") var target: CharacterController2D?
    weak var target: Node2D?
    
    override func _process(delta: Double) {
        guard let target else { return }
        
        self.position = Vector2(
            x: target.position.x,
            y: target.position.y - 30)
    }
}
