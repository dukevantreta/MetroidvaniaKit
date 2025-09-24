import SwiftGodot

@Godot(.tool)
class HUD: Control {
    
    @Node("HealthLabel") weak var healthLabel: Label?
    @Node("AmmoLabel") weak var ammoLabel: Label?
    @Node("MiniMapHUD") var minimap: MiniMapHUD?
    
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
