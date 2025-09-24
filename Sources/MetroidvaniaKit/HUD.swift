import SwiftGodot

@Godot(.tool)
class HUD: Control {
    
    @SceneTree(path: "HealthLabel") weak var healthLabel: Label?
    @SceneTree(path: "AmmoLabel") weak var ammoLabel: Label?
    @SceneTree(path: "MiniMapHUD") var minimap: MiniMapHUD?
    
    private(set) weak var playerStats: PlayerStats?
    
    func setPlayerStats(_ playerStats: PlayerStats) {
        self.playerStats = playerStats
        playerStats.connect(signal: PlayerStats.hpChanged, to: self, method: "healthChanged")
        playerStats.connect(signal: PlayerStats.ammoChanged, to: self, method: "ammoChanged")
        healthChanged()
        ammoChanged()
    }
    
    @Callable func healthChanged() {
        guard let playerStats else { return }
        healthLabel?.text = "\(playerStats.hp)"
    }
    
    @Callable func ammoChanged() {
        guard let playerStats else { return }
        ammoLabel?.text = "\(playerStats.ammo)"
    }
}
