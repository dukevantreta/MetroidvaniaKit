import SwiftGodot

@Godot
class Room: Node2D {

    var width: Int32 = 0
    var height: Int32 = 0

    override func _ready() {
        guard let tree = getTree() else {
            logError("Cannot get scene tree!"); return
        }
        let items = tree.getNodesInGroup("items")
        for item in items {
            if let id = item?.getMeta(name: "key", default: "") {
                if SaveData.shared.itemsCollected[String(id)] == true {
                    item?.queueFree()
                } else {
                    // make item
                    let itemNode = Item()
                    // let key: String = item?.getMeta(name: "key", default: "") ?? ""
                    itemNode.key = id
                    let type: String = item?.getMeta(name: "type", default: "") ?? ""
                    itemNode.type = ItemType(rawValue: type)
                    item?.addChild(node: itemNode)
                }
            }
        }
    }
}





class SaveData {

    static let shared = SaveData()
    private init() {

    }

    var itemsCollected: [String: Bool] = [:]
}