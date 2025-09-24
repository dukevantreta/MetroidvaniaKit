import SwiftGodot

@Godot
class PauseMenu: Control {
    
    @SceneTree(path: "../../GameController") var gameController: GameController?
    
    override func _process(delta: Double) {
        if Input.isActionJustPressed(action: "ui_cancel") {
            gameController?.unpause()
        }
    }
}
