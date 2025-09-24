import SwiftGodot

@Godot
class GameController: Node {
    
    @SceneTree(path: "../CharacterController2D") var player: CharacterController2D?
    @SceneTree(path: "../CanvasLayer/MiniMapHUD") var minimapHUD: MiniMapHUD?
    
    override func _ready() {
        log("Player: \(player)")
        log("MinimapHUD: \(minimapHUD)")
    }
    
    override func _process(delta: Double) {
        
        let cellX = Int32(player!.position.x / (16 * 25))
        let cellY = Int32(player!.position.y / (16 * 15))
        
        minimapHUD?.center = Vector2i(x: cellX, y: cellY) // call onCellChanged()
    }
}

