import SwiftGodot

struct Upgrades: OptionSet {
    
    let rawValue: UInt32

    static let morph            = Upgrades(rawValue: 1 << 0)
    static let mines            = Upgrades(rawValue: 1 << 1)
    static let overclock        = Upgrades(rawValue: 1 << 2)
    static let highJump         = Upgrades(rawValue: 1 << 3)
    static let doubleJump       = Upgrades(rawValue: 1 << 4)
    static let wallGrab         = Upgrades(rawValue: 1 << 5)
    static let betterWallGrab   = Upgrades(rawValue: 1 << 6)
    static let waterWalking     = Upgrades(rawValue: 1 << 7)
    static let waterMovement    = Upgrades(rawValue: 1 << 8)
    static let hookshot         = Upgrades(rawValue: 1 << 9)
    static let rocket           = Upgrades(rawValue: 1 << 10)
    static let granade          = Upgrades(rawValue: 1 << 11)
    static let flamethrower     = Upgrades(rawValue: 1 << 12)
    static let smartBomb        = Upgrades(rawValue: 1 << 13)
    static let normalPhaser     = Upgrades(rawValue: 1 << 14)
    static let wallPhaser       = Upgrades(rawValue: 1 << 15)
    static let piercePhaser     = Upgrades(rawValue: 1 << 16)
    static let glitchPhaser     = Upgrades(rawValue: 1 << 17)
    static let widePhaser       = Upgrades(rawValue: 1 << 18)
    static let airDash          = Upgrades(rawValue: 1 << 19)
    static let pause            = Upgrades(rawValue: 1 << 20)
    static let autofire         = Upgrades(rawValue: 1 << 21)
    static let rocketAutofire   = Upgrades(rawValue: 1 << 22)
    static let knockbackArmor   = Upgrades(rawValue: 1 << 23)

    static let lookup: [ItemType: Upgrades] = [
        .overclock: .overclock,
        .rocket: .rocket,
    ]

    static let editorNames: [String] = [
        "Morph",
        "Morph Bombs",
        "Overclock",
        "High Jump",
        "Double Jump",
        "Wall Grab",
        "Advanced Wall Grab",
        "Water Walking",
        "Water Movement",
        "Hookshot",
        "Rocket Launcher",
        "Granade Launcher",
        "Flamethrower",
        "Smart Bomb",
        "Normal Beam",
        "Wave Beam",
        "Plasma Beam",
        "Glitch Beam",
        "Wide Beam",
        "Air Dash",
        "Pause",
        "Autofire",
        "Rocket Autofire",
        "Knockback Armor"
    ]

    static let hintString = editorNames.joined(separator: ",")
}

// This is needed to circumvent type support. Allows exposing this type to the editor as @Export property.
extension Upgrades: CaseIterable {
    static let allCases: [Upgrades] = [] // Only needed for conformance. Fill if needs to be used.
}
