import SwiftGodot

enum InputAction: StringName {
    case action0 = "action_0" // Jump
    case action1 = "action_1" // Fire
    case leftShoulder = "action_left"
    case rightShoulder = "action_right"
    case start = "action_start"
}

extension Input {
    
    static func getHorizontalAxis() -> Double {
        Input.getAxis(negativeAction: "ui_left", positiveAction: "ui_right")
    }
    
    static func getVerticalAxis() -> Double {
        Input.getAxis(negativeAction: "ui_down", positiveAction: "ui_up")
    }
    
    static func isActionJustPressed(_ action: InputAction) -> Bool {
        Input.isActionJustPressed(action: action.rawValue)
    }
    
    static func isActionPressed(_ action: InputAction) -> Bool {
        Input.isActionPressed(action: action.rawValue)
    }
    
    static func isActionJustReleased(_ action: InputAction) -> Bool {
        Input.isActionJustReleased(action: action.rawValue)
    }
}
