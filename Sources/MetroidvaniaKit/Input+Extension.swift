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

    // static func getVector(
    //     negativeX: InputAction, 
    //     positiveX: InputAction, 
    //     negativeY: InputAction, 
    //     positiveY: InputAction,
    //     deadzone: Double
    // ) -> Vector2 {
    //     Input.getVector(
    //         negativeX: negativeX.rawValue,
    //         positiveX: positiveX.rawValue,
    //         negativeY: negativeY.rawValue,
    //         positiveY: positiveY.rawValue,
    //         deadzone: deadzone
    //     )
    // }
    
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

    // func getJoy1Axis() -> Vector2 {
    //     isEnabled ? Input.getVector(negativeX: .left, positiveX: .right, negativeY: .down, positiveY: .up, deadzone: 0.5) : .zero
    // }

    // func getJoy2Axis() -> Vector2 {
    //     isEnabled ? Input.getVector(negativeX: .secondaryLeft, positiveX: .secondaryRight, negativeY: .secondaryDown, positiveY: .secondaryUp, deadzone: 0.5) : .zero
    // }
    
    func getHorizontalAxis() -> Double {
        isEnabled ? Input.getAxis(negativeAction: .left, positiveAction: .right) : 0.0
    }
    
    func getVerticalAxis() -> Double {
        isEnabled ? Input.getAxis(negativeAction: .down, positiveAction: .up) : 0.0
    }

    func getSecondaryHorizontalAxis() -> Double {
        isEnabled ? Input.getAxis(negativeAction: .secondaryLeft, positiveAction: .secondaryRight) : 0.0
    }

    func getSecondaryVerticalAxis() -> Double {
        isEnabled ? Input.getAxis(negativeAction: .secondaryDown, positiveAction: .secondaryUp) : 0.0
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
