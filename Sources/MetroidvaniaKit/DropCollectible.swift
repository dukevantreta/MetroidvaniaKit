import SwiftGodot

enum DropType: Int, CaseIterable {
    case health
    case healthBig
    case ammo

    var sceneName: String {
        switch self {
        case .health: "collectible_health"
        case .healthBig: "collectible_health_big"
        case .ammo: "collectible_ammo"
        }
    }
}

@Godot
class DropCollectible: Area2D {

    @Export(.enum) var type: DropType = .health

    @Export var amount: Int = 0

    // TODO lifetime & disappear

    override func _ready() {
        collisionMask = 0b1_0000_0000

        areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            if let hitbox = otherArea as? PlayerHitbox {
                self.collect(hitbox)
            }
        }
    }
    
    func collect(_ playerHitbox: PlayerHitbox) {
        switch self.type {
        case .health:
            playerHitbox.restoreHealth(amount)
        case .healthBig:
            playerHitbox.restoreHealth(amount)
        case .ammo:
            playerHitbox.restoreAmmo(amount)
        }
        self.queueFree()
    }
}