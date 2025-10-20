import SwiftGodot

@Godot
class ItemCollectView: Control {

    var onContinue: (() -> Void)?

    @Node("Panel") let panel: Panel?
    @Node("Panel/Title") let titleLabel: Label?
    @Node("Panel/Description") let descLabel: RichTextLabel?

    var font: Font!

    override func _ready() {
        let file = File(path: "sprites/TorusSansX.png")
        guard let resource = try? file.loadResource(ofType: Font.self) else {
            logError("Font resource not found: \(file.path)")
            return
        }
        font = resource
    //     guard let titleLabel, let descLabel else { return }
    //     log("\(titleLabel.text)")
    //     log("\(descLabel.text)")
    }

    // override func _unhandledInput(event: InputEvent?) {
        
    // }

    private var buffer: String = ""
    private var clock = 0

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

        if clock < 1 {
            clock += 1
            return
        }
        clock = 0
        if !buffer.isEmpty {
            let char = buffer.removeFirst()
            descLabel?.addText(String(char))
        }
    }

    func pushText(_ text: String) {
        descLabel?.text = ""
        descLabel?.pushFont(font)
        descLabel?.pushFontSize(10)
        let localizedText = tr(message: StringName(text))
        buffer = "\(localizedText)"
    }
}