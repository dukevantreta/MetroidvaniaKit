import SwiftGodot

enum InputAction: StringName {
    
    case left = "ui_left"
    case right = "ui_right"
    case up = "ui_up"
    case down = "ui_down"
    
    case secondaryLeft = "bg_left"
    case secondaryRight = "bg_right"
    case secondaryUp = "bg_up"
    case secondaryDown = "bg_down"
    
    case actionLeft = "action_left"
    case actionRight = "action_right"
    case actionUp = "action_up"
    case actionDown = "action_down"
    
    case leftShoulder = "left_shoulder"
    case rightShoulder = "right_shoulder"
    case leftTrigger = "left_trigger"
    case rightTrigger = "right_trigger"
    
    case start = "action_start"
    case select = "action_select"
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
