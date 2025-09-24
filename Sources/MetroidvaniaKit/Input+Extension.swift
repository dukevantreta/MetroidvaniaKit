import SwiftGodot

enum InputAction: StringName {
    case up = "ui_up"
    case down = "ui_down"
    case left = "ui_left"
    case right = "ui_right"
    case action0 = "action_0" // Jump
    case action1 = "action_1" // Fire
    case action2 = "action_2"
    case action3 = "action_3"
    case leftShoulder = "action_left"
    case rightShoulder = "action_right"
    case start = "action_start"
}

extension Input {
    
    static func getAxis(negativeAction: InputAction, positiveAction: InputAction) -> Double {
        Input.getAxis(negativeAction: negativeAction.rawValue, positiveAction: positiveAction.rawValue)
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

@Godot
class InputController: Node {
    
    @Export var isEnabled: Bool = true
    
    func getHorizontalAxis() -> Double {
        isEnabled ? Input.getAxis(negativeAction: .left, positiveAction: .right) : 0.0
    }
    
    func getVerticalAxis() -> Double {
        isEnabled ? Input.getAxis(negativeAction: .down, positiveAction: .up) : 0.0
    }
    
    func isActionJustPressed(_ action: InputAction) -> Bool {
        Input.isActionJustPressed(action: action.rawValue) && isEnabled
    }
    
    func isActionPressed(_ action: InputAction) -> Bool {
        Input.isActionPressed(action: action.rawValue) && isEnabled
    }
    
    func isActionJustReleased(_ action: InputAction) -> Bool {
        Input.isActionJustReleased(action: action.rawValue) && isEnabled
    }
}
