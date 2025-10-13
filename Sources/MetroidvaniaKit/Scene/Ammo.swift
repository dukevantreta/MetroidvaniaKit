import SwiftGodot

@Godot
class Ammo: Node {

    @Signal var didChange: SignalWithArguments<Int>

    @Export var maxValue: Int = 10 // TODO: get these values somewhere else

    private(set) var value: Int = 10 {
        didSet {
            didChange.emit(value)
        }
    }

    func consume(_ amount: Int) -> Bool {
        if amount <= value {
            value -= amount
            return true
        }
        return false
    }

    func restore(_ amount: Int) {
        value = min(value + amount, maxValue)
    }
} 