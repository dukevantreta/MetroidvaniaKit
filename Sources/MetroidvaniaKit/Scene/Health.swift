import SwiftGodot

@Godot
class Health: Node {

    @Signal var didChange: SignalWithArguments<Int>

    @Export var maxValue: Int = 0 {
        didSet {
            value = min(value, maxValue)
        }
    }

    private(set) var value: Int = 0 {
        didSet {
            didChange.emit(value)
        }
    }

    func damage(_ amount: Int) {
        value -= amount
        if value <= 0 {
            // TODO: kill
            log("DEAD")
        }
    }

    func heal(_ amount: Int) {
        value = min(value + amount, maxValue)
    }
 }