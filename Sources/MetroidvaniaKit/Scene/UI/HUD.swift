import SwiftGodot

@Godot(.tool)
class HUD: Control {
    
    @Node("HealthLabel") weak var healthLabel: Label?
    @Node("AmmoLabel") weak var ammoLabel: Label?
    @Node("MiniMapHUD") var minimap: MiniMapHUD?
    
    func setPlayerNode(_ player: Player) {
        updateHealth(player.hp?.value ?? 0)
        updateAmmo(player.ammo?.value ?? 0)
        player.hp?.didChange.connect { [weak self] in
            self?.updateHealth($0)
        }
        player.ammo?.didChange.connect { [weak self] in
            self?.updateAmmo($0)
        }
    }
    
    func updateHealth(_ hp: Int) {
        healthLabel?.text = "\(hp)"
    }
    
    func updateAmmo(_ ammo: Int) {
        ammoLabel?.text = "\(ammo)"
    }
}
