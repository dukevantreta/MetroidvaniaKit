import SwiftGodot

enum ItemType: String {
    case hp
    case ammo
    case rocket
    case overclock
}

@Godot
class Item: Area2D {

    var key: String? //StringName?
    var type: ItemType?

    override func _ready() {
        addCollisionMask(.player)
        
        let rect = RectangleShape2D()
        rect.size = Vector2(x: 16, y: 16)
        let collision = CollisionShape2D()
        collision.shape = rect
        collision.position = Vector2(x: 8, y: 8)
        addChild(node: collision)

        areaEntered.connect { [weak self] other in
            guard let self, let other else { return }
            if let hitbox = other as? Hitbox {
                if let player = hitbox.getParent() as? PlayerNode {
                    self.collect(player: player)
                }
            }
        }
    }

    func collect(player: PlayerNode) {
        guard let key, let type else { return }

        switch type {
        case .hp:
            player.expandHealth()
        case .ammo:
            player.expandAmmo()
        default:
            if let upgrade = Upgrades.lookup[type] {
                player.data.addUpgrade(upgrade)
            }
        }
        SaveData.shared.itemsCollected[key] = true
        if let controller = getTree()?.getNodesInGroup("game-controller").first as? GameController {
            controller.showGetItem(title: "up.\(type.rawValue).name", description: "up.\(type.rawValue).description")
        }

        getParent()?.queueFree() // fuk da polise
    }
}