import SwiftGodot

@Godot
class PlayerData: Node {

    #exportGroup("Health")
    @Export var baseHP: Int = 99
    @Export var hpPerExpansion: Int = 50
    @Export var hpExpansions = 0

    #exportGroup("Ammo")
    @Export var baseAmmo: Int = 10
    @Export var ammoPerExpansion: Int = 5
    @Export var ammoExpansions = 0

    #exportGroup("Upgrades")
    @Export(.flags, Upgrades.hintString) var upgrades: Upgrades = []

    var maxHp: Int {
        baseHP + hpPerExpansion * hpExpansions
    }

    var maxAmmo: Int {
        baseAmmo + ammoPerExpansion * ammoExpansions
    }
}