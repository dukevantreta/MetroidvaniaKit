import SwiftGodot

@Godot
class SidescrollerCamera: Camera2D {
    
//    @Export var target: CharacterController2D?
//    @SceneTree(path: "../PlayerNode") var target: Node2D?
    weak var target: Node2D?
    
    override func _process(delta: Double) {
        guard let target else { return }
        
        self.position = Vector2(
            x: target.position.x,
            y: target.position.y - 24)
        
//        self.position.x = Float(GD.moveToward(
//            from: Double(position.x),
//            to: Double(target.position.x),
//            delta: 200 * delta))
//        
//        self.position.y = Float(GD.moveToward(
//            from: Double(position.y),
//            to: Double(target.position.y - 30),
//            delta: 200 * delta))
    }
}
