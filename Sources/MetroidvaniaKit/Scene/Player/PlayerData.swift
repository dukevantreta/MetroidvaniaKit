import SwiftGodot

@Godot
final class PlayerData: Node {

    #exportGroup("Health")
    @Export var baseHP: Int = 99
    @Export var hpPerExpansion: Int = 50
    @Export var hpExpansions = 0

    #exportGroup("Ammo")
    @Export var baseAmmo: Int = 10
    @Export var ammoPerExpansion: Int = 5
    @Export var ammoExpansions = 0

    #exportGroup("Upgrades")
    @Export(.flags, Upgrades.hintString) var upgradesObtained: Upgrades = []
    @Export(.flags, Upgrades.hintString) var upgradesEnabled: Upgrades = Upgrades(rawValue: 0xFFFFFFFF)

    #exportGroup("Physics")
    @Export private(set) var bodySizeDefault: Vector2i = Vector2i(x: 12, y: 30) {
        didSet { updateConfigurationWarnings() }
    }
    @Export private(set) var bodySizeMorphed: Vector2i = Vector2i(x: 12, y: 14) {
        didSet { updateConfigurationWarnings() }
    }

    #exportSubgroup("Wall Grab")
    @Export private(set) var wallDetectionLength: Float = 1.0
    @Export private(set) var highRayOffsetY: Float = 1.0
    @Export private(set) var lowRayOffsetY: Float = -1.0
    @Export private(set) var floorCheckLength: Float = 8.0

    #exportGroup("Movement")
    @Export private(set) var movespeed: Float = 180.0
    @Export private(set) var acceleration: Float = 8.0
    @Export private(set) var deceleration: Float = 80.0
    @Export private(set) var airDampFactor: Float = 0.4
    @Export private(set) var overclockFactor: Float = 2.0

    // Linear height is up to where gravity is ignored if the player holds the jump button.
    // Parabolic height / duration refers to the interval of the jump where gravity is actually applied.
    // Full jump height = linear + parabolic (if jump sensitivity == true)
    #exportSubgroup("Jumping")
    @Export private(set) var baseJumpLinearHeight: Float = 20 // = 1 tile + 4px margin
    @Export private(set) var superJumpExtraHeight: Float = 32 // = 2 tiles
    @Export private(set) var parabolicHeight: Float = 48 // = 3 tiles
    @Export private(set) var parabolicJumpDuration: Float = 0.5
    @Export private(set) var allowJumpSensitivity: Bool = true
    @Export private(set) var fallSpeedCap: Float = 500.0

    #exportGroup("Animation")
    @Export private(set) var idleThresholdTime: Double = 5.0
    @Export private(set) var lastShotThresholdTime: Double = 3.0
    @Export private(set) var overclockThresholdTime: Double = 3.0

    var maxHp: Int {
        baseHP + hpPerExpansion * hpExpansions
    }

    var maxAmmo: Int {
        baseAmmo + ammoPerExpansion * ammoExpansions
    }

    override func _getConfigurationWarnings() -> PackedStringArray {
        var message = PackedStringArray()
        if !bodySizeDefault.x.isMultiple(of: 2) || !bodySizeDefault.y.isMultiple(of: 2) ||
            !bodySizeMorphed.x.isMultiple(of: 2) || !bodySizeMorphed.y.isMultiple(of: 2)
        {
            message.append("Using odd dimensions for body size is not recommended.")
        }
        return message
    }
}