import SwiftGodot
import Foundation

@Godot
class GameController: Node {
    
    @SceneTree(path: "../CharacterController2D/Camera2D") var camera: Camera2D?
    @SceneTree(path: "../CharacterController2D") var player: CharacterController2D?
    @SceneTree(path: "../CanvasLayer/MiniMapHUD") var minimapHUD: MiniMapHUD?
    
    private(set) var world: World?
    
    var lastCellPosition: Vector2i = .zero
    
    override func _ready() {
        log("Player: \(player)")
        log("MinimapHUD: \(minimapHUD)")
        
        let worldFile = "res://tiled/world-test.world"
        guard let worldData = FileAccess.getFileAsString(path: worldFile).data(using: .utf8) else {
            logError("Failed to read world data from '\(worldFile)'.")
            return
        }
        do {
            let world = try JSONDecoder().decode(World.self, from: worldData)
            self.world = world
        } catch {
            logError("Failed to decode world data from '\(worldFile)'.")
        }
    }
    
    override func _process(delta: Double) {
        guard let player else {
            logError("Player instance not found!")
            return
        }
        guard let world else {
            logError("World instance not found!")
            return
        }
        
        let cellX = Int32(player.position.x / (16 * 25)) // FIXME magic numbers
        let cellY = Int32(player.position.y / (16 * 15))
        let playerCellPosition: Vector2i = .init(x: cellX, y: cellY)
        
        if playerCellPosition != lastCellPosition {
            lastCellPosition = playerCellPosition
            minimapHUD?.onCellChanged(newOffset: playerCellPosition)
            
            for map in world.maps {
                if Int32(player.position.x) >= map.x && Int32(player.position.x) < map.x + map.width &&
                    Int32(player.position.y) >= map.y && Int32(player.position.y) < map.y + map.height {
                    let roomName = try? getFileName(from: map.fileName) ?? ""
                    log("Current room: \(roomName)")
                    
                    camera?.limitLeft = map.x
                    camera?.limitRight = map.x + map.width
                    camera?.limitTop = map.y
                    camera?.limitBottom = map.y + map.height
                }
            }
        }
    }
}

