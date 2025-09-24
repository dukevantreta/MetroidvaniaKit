import SwiftGodot

@Godot(.tool)
class HUD: Control {
    
    @SceneTree(path: "HealthLabel") weak var healthLabel: Label?
    @SceneTree(path: "AmmoLabel") weak var ammoLabel: Label?
    @SceneTree(path: "MiniMapHUD") var minimap: MiniMapHUD?
    
    func setPlayerStats(_ playerStats: PlayerStats) {
        updateHealth(playerStats.hp)
        updateAmmo(playerStats.ammo)
        playerStats.hpChanged.connect { [weak self] hp in
            self?.updateHealth(hp)
        }
        playerStats.ammoChanged.connect { [weak self] ammo in
            self?.updateAmmo(ammo)
        }
    }
    
    func updateHealth(_ hp: Int) {
        healthLabel?.text = "\(hp)"
    }
    
    func updateAmmo(_ ammo: Int) {
        ammoLabel?.text = "\(ammo)"
    }
}
