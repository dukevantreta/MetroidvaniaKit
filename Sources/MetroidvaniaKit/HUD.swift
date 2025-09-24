import SwiftGodot

@Godot(.tool)
class HUD: Control {
    
    @SceneTree(path: "HealthLabel") weak var healthLabel: Label?
    @SceneTree(path: "AmmoLabel") weak var ammoLabel: Label?
    
    weak var playerStats: PlayerStats? {
        didSet {
            if let playerStats {
                connectSignals()
            }
        }
    }
    
    func connectSignals() {
        playerStats?.connect(signal: PlayerStats.hpChanged, to: self, method: "healthChanged")
        playerStats?.connect(signal: PlayerStats.ammoChanged, to: self, method: "ammoChanged")
    }
    
    @Callable func healthChanged() {
        guard let playerStats else { return }
        healthLabel?.text = "HP:\(playerStats.hp)"
    }
    
    @Callable func ammoChanged() {
        guard let playerStats else { return }
        ammoLabel?.text = "Ammo:\(playerStats.ammo)"
    }
}
