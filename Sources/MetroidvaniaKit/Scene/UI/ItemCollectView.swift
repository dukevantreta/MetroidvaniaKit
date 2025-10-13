import SwiftGodot

@Godot
class ItemCollectView: Control {

    var onContinue: (() -> Void)?

    @Node("Panel") let panel: Panel?
    @Node("Panel/Title") let titleLabel: Label?
    @Node("Panel/Description") let descLabel: Label?

    // override func _ready() {
    //     guard let titleLabel, let descLabel else { return }
    //     log("\(titleLabel.text)")
    //     log("\(descLabel.text)")
    // }

    // override func _unhandledInput(event: InputEvent?) {
        
    // }

    override func _process(delta: Double) {
        if 
            Input.isActionPressed(.actionDown) || 
            Input.isActionPressed(.actionUp) ||
            Input.isActionPressed(.actionLeft) ||
            Input.isActionPressed(.actionRight) ||
            Input.isActionPressed(.start)
        {
            onContinue?()
        }
    }
}