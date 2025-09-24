import SwiftGodot

enum InputAction: StringName {
    case accept = "ui_accept"
}

extension Input {
    
    static func getHorizontalAxis() -> Double {
        Input.getAxis(negativeAction: "ui_left", positiveAction: "ui_right")
    }
    
    static func isActionJustPressed(_ action: InputAction) -> Bool {
        Input.isActionJustPressed(action: action.rawValue)
    }
}
