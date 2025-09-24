import SwiftGodot

struct Damage {
    enum Source: Int, CaseIterable {
        case none
        case enemy
        case rocket
    }
    let source: Source
    let amount: Int
    let origin: Vector2
    // knockback?
}
