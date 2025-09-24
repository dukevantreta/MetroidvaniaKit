import SwiftGodot

@Godot(.tool)
class HUD: Control {
    
    @Node("HealthLabel") weak var healthLabel: Label?
    @Node("AmmoLabel") weak var ammoLabel: Label?
    @Node("MiniMapHUD") var minimap: MiniMapHUD?
    
    func setPlayerNode(_ playerStats: PlayerNode) {
        updateHealth(playerStats.stats.hp)
        updateAmmo(playerStats.ammo?.value ?? 0)
        playerStats.stats.hpChanged.connect { [weak self] hp in
            self?.updateHealth(hp)
        }
        playerStats.ammo?.didChange.connect { [weak self] ammo in
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
