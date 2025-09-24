import SwiftGodot
import Foundation

let TILE_SIZE: Int32 = 16
let ROOM_WIDTH: Int32 = 25
let ROOM_HEIGHT: Int32 = 15

@Godot
class GameController: Node {
    
    @SceneTree(path: "../SidescrollerCamera") var camera: SidescrollerCamera?
    @SceneTree(path: "../PlayerNode") var player: CharacterBody2D?
    @SceneTree(path: "../CanvasLayer/MiniMapHUD") var minimapHUD: MiniMapHUD?
    
    @SceneTree(path: "../CanvasLayer/PauseMenu") var pauseMenu: Control?
    
    @SceneTree(path: "../CanvasLayer/PauseMenu/Overlay") var overlay: ColorRect?
    
    private(set) var world: World?
    
    var lastCellPosition: Vector2i = .zero
//    var currentRoomName: String = ""
    var currentRoom: Node2D?
    
    var isPaused = false
    
    override func _ready() {
        self.processMode = .always
        
        log("Player: \(player)")
        log("MinimapHUD: \(minimapHUD)")
        
        let worldFile = "res://tiled/world-test.world"
        do {
            self.world = try World.load(from: worldFile)
        } catch {
            logError("Failed to decode world data from '\(worldFile)' with error: \(error).")
        }
        
        camera?.target = player
        
//        guard let player else { return }
//        let cellX = Int32(player.position.x / Float(TILE_SIZE * ROOM_WIDTH))
//        let cellY = Int32(player.position.y / Float(TILE_SIZE * ROOM_HEIGHT))
//        let playerCellPosition: Vector2i = .init(x: cellX, y: cellY)
//        onCellChanged(playerCellPosition, playerPosition: player.position)
    }
    
    override func _process(delta: Double) {
        if Input.isActionJustPressed(.start) {
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
        
        let cellX = Int32(player.position.x / Float(TILE_SIZE * ROOM_WIDTH))
        let cellY = Int32(player.position.y / Float(TILE_SIZE * ROOM_HEIGHT))
        let playerCellPosition: Vector2i = .init(x: cellX, y: cellY)
        
        if playerCellPosition != lastCellPosition {
            onCellChanged(playerCellPosition, playerPosition: player.position)
        }
    }
    
    func onCellChanged(_ nextCell: Vector2i, playerPosition: Vector2) {
        guard let world else {
            logError("World instance not found!")
            return
        }
        
        let moveDelta = nextCell - lastCellPosition
        lastCellPosition = nextCell
        minimapHUD?.onCellChanged(newOffset: nextCell)
        
        for map in world.maps {
            if // find which room the player is in
                Int32(playerPosition.x) >= map.x && Int32(playerPosition.x) < map.x + map.width &&
                Int32(playerPosition.y) >= map.y && Int32(playerPosition.y) < map.y + map.height
            {
                if let roomName = try? getFileName(from: map.fileName), StringName(roomName) != currentRoom?.name {
                    log("ROOM NAME: \(roomName), CURRENT ROOM: \(currentRoom?.name)")
                    
                    let mapPath = "res://tiled/\(map.fileName)"
                    let roomScene = ResourceLoader.load(path: mapPath) as? PackedScene
                    let newRoom = roomScene?.instantiate() as? Node2D
                    newRoom?.position = Vector2(x: Float(map.x), y: Float(map.y))
                    getParent()?.addChild(node: newRoom)
                    
//                if newRoom?.name != currentRoom?.name {
//                    if currentRoomName == "" {
                    if currentRoom == nil { // is the first room, just set the limits
                        camera?.limitLeft = map.x
                        camera?.limitRight = map.x + map.width
                        camera?.limitTop = map.y
                        camera?.limitBottom = map.y + map.height
                        currentRoom = newRoom
                    } else {
                        guard let camera else { return }
                        
                        let sceneTree = getTree()
                        sceneTree?.paused = true
                        
                        let tween = getTree()?.createTween()
                        tween?.setPauseMode(.process)
                        
                        let offset = Vector2(x: 16 * 25 * moveDelta.x, y: 16 * 15 * moveDelta.y)
                        tween?.tweenProperty(object: camera, property: "offset", finalVal: Variant(offset),
                                             duration: 0.7)
                        
                        tween?.finished.connect { [weak self] in
                            camera.offset = .zero
                            camera.limitLeft = map.x
                            camera.limitRight = map.x + map.width
                            camera.limitTop = map.y
                            camera.limitBottom = map.y + map.height
                            
                            self?.currentRoom?.queueFree()
                            self?.currentRoom = newRoom
                            
                            sceneTree?.paused = false
                        }
                    }
                    
//                    currentRoomName = roomName
                    log("Current room: \(currentRoom?.name ?? "")")
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

