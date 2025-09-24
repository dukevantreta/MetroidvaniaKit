import SwiftGodot
import Foundation

@Godot
class GameController: Node {
    
//    @SceneTree(path: "../CharacterController2D/Camera2D") var camera: Camera2D?
    @SceneTree(path: "../SidescrollerCamera") var camera: SidescrollerCamera?
//    @SceneTree(path: "../CharacterController2D") var player: CharacterController2D?
    @SceneTree(path: "../PlayerNode") var player: CharacterBody2D?
    @SceneTree(path: "../CanvasLayer/MiniMapHUD") var minimapHUD: MiniMapHUD?
    
    @SceneTree(path: "../CanvasLayer/PauseMenu") var pauseMenu: Control?
    
    @SceneTree(path: "../CanvasLayer/PauseMenu/Overlay") var overlay: ColorRect?
    
    private(set) var world: World?
    
    var lastCellPosition: Vector2i = .zero
    var currentRoom: String = ""
    
    var isPaused = false
    
    override func _ready() {
        self.processMode = .always
        
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
        
        camera?.target = player
    }
    
    override func _process(delta: Double) {
        if Input.isActionJustPressed(action: "ui_cancel") {
            if isPaused {
                unpause()
            } else {
                pause()
            }
        }
        
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
            let moveDelta = playerCellPosition - lastCellPosition
            lastCellPosition = playerCellPosition
            minimapHUD?.onCellChanged(newOffset: playerCellPosition)
            
            for map in world.maps {
                if // find which room the player is in
                    Int32(player.position.x) >= map.x && Int32(player.position.x) < map.x + map.width &&
                    Int32(player.position.y) >= map.y && Int32(player.position.y) < map.y + map.height
                {
                    if let roomName = try? getFileName(from: map.fileName), roomName != currentRoom {
                        if currentRoom == "" { // is the first room, just set the limits
                            camera?.limitLeft = map.x
                            camera?.limitRight = map.x + map.width
                            camera?.limitTop = map.y
                            camera?.limitBottom = map.y + map.height
                        } else {
                            guard let camera else { return }
                            
                            let sceneTree = getTree()
                            sceneTree?.paused = true
                            
                            let tween = getTree()?.createTween()
                            tween?.setPauseMode(.process)
                            
                            let offset = Vector2(x: 16 * 25 * moveDelta.x, y: 16 * 15 * moveDelta.y)
                            tween?.tweenProperty(object: camera, property: "offset", finalVal: Variant(offset),
                                                 duration: 0.7)
                            
                            tween?.finished.connect {
                                camera.offset = .zero
                                camera.limitLeft = map.x
                                camera.limitRight = map.x + map.width
                                camera.limitTop = map.y
                                camera.limitBottom = map.y + map.height
                                
                                sceneTree?.paused = false
                            }
                        }
                        
                        currentRoom = roomName
                        log("Current room: \(currentRoom)")
                    }
                }
            }
        }
    }
    
    func pause() {
        isPaused = true
        pauseMenu?.visible = true
        getTree()?.paused = true
        
        log("\(overlay)")
        let tween = getTree()?.createTween()
        tween?.setPauseMode(.process)
        tween?.tweenProperty(object: overlay, property: "modulate", finalVal: Variant(Color.white), duration: 0.4)
    }
    
    func unpause() {
//        isPaused = false
//        getTree()?.paused = false
//        pauseMenu?.visible = false
        
        let tween = getTree()?.createTween()
        tween?.setPauseMode(.process)
        tween?.tweenProperty(object: overlay, property: "modulate", finalVal: Variant(Color.transparent), duration: 0.4)
        tween?.finished.connect { [weak self] in
            self?.isPaused = false
            self?.getTree()?.paused = false
            self?.pauseMenu?.visible = false
        }
    }
}

