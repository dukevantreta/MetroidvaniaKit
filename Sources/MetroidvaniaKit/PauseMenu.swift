import SwiftGodot

@Godot
class PauseMenu: Control {
    
    @Node("../../GameController") var gameController: GameController?
    @Node("MiniMapHUD") var minimap: MiniMapHUD?
    
    override func _process(delta: Double) {
        if Input.isActionJustPressed(action: "ui_cancel") {
            gameController?.unpause()
        }
    }
}
