import SwiftGodot

@Godot
class GameController: Node {
    
    @SceneTree(path: "../CharacterController2D") var player: CharacterController2D?
    @SceneTree(path: "../CanvasLayer/MiniMapHUD") var minimapHUD: MiniMapHUD?
    
    var lastCellPosition: Vector2i = .zero
    
    override func _ready() {
        log("Player: \(player)")
        log("MinimapHUD: \(minimapHUD)")
    }
    
    override func _process(delta: Double) {
        guard let player else {
            logError("Player instance not found!")
            return
        }
        
        let cellX = Int32(player.position.x / (16 * 25)) // FIXME magic numbers
        let cellY = Int32(player.position.y / (16 * 15))
        let playerCellPosition: Vector2i = .init(x: cellX, y: cellY)
        
        if playerCellPosition != lastCellPosition {
            lastCellPosition = playerCellPosition
            minimapHUD?.onCellChanged(newOffset: playerCellPosition)
        }
    }
}

