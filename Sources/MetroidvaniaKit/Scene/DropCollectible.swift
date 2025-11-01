import SwiftGodot

enum DropType: Int, CaseIterable {
    case health
    case healthBig
    case ammo

    var sceneName: String {
        switch self {
        case .health: "drop_health"
        case .healthBig: "drop_health_big"
        case .ammo: "drop_ammo"
        }
    }
}

@Godot
class DropCollectible: Area2D {

    @Export(.enum) var type: DropType = .health
    @Export var amount: Int = 0
    @Export var lifetime: Double = 10.0
    @Export var blinkLifetime: Double = 3.0
    
    private let blinkTimer = Timer()
    
    private var accumulator: Double = 0.0

    override func _ready() {
        collisionLayer = 0b0100_0000
        collisionMask = 0b1_0000_0000
        
        blinkTimer.autostart = false
        blinkTimer.oneShot = false
        blinkTimer.timeout.connect { [weak self] in
            guard let self else { return }
            self.visible = !self.visible
        }
        addChild(node: blinkTimer)

        areaEntered.connect { [weak self] other in
            guard let self, let other else { return }
            if let player = other.getParent() as? Player {
                self.collect(player)
            }
        }
    }
    
    override func _process(delta: Double) {
        accumulator += delta
        if accumulator >= lifetime - blinkLifetime && blinkTimer.isStopped() {
            blinkTimer.start(timeSec: 0.05)
        }
        if accumulator >= lifetime {
            queueFree()
        }
    }
    
    func collect(_ player: Player) {
        switch self.type {
        case .health, .healthBig:
            player.restoreHealth(amount)
        case .ammo:
            player.restoreAmmo(amount)
        }
        self.queueFree()
    }
}
