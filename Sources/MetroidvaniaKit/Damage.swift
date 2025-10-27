import SwiftGodot

struct Damage {

    struct Value: OptionSet {
        let rawValue: UInt32

        static let player       = Value(rawValue: 1 << 0)
        static let mines        = Value(rawValue: 1 << 1)
        static let rocket       = Value(rawValue: 1 << 2)
        static let smartBomb    = Value(rawValue: 1 << 3)
        static let overclock    = Value(rawValue: 1 << 4)

        static let enemy        = Value(rawValue: 1 << 10)
    }
    enum Source: Int, CaseIterable {
        case none
        case enemy
        case rocket
        case bomb
    }
    let value: Value
    let source: Source
    let amount: Int
    let origin: Vector2
    // knockback?
}

extension Damage.Value: CaseIterable {
    static let allCases: [Damage.Value] = [] // Only needed for conformance. Fill if needs to be used.
}