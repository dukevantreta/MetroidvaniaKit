import SwiftGodot
import Foundation

let TILE_SIZE: Int32 = 16
let ROOM_WIDTH: Int32 = 25
let ROOM_HEIGHT: Int32 = 15

@Godot
class GameController: Node {
    
    @Node("../PlayerNode") var player: PlayerNode?
    @Node("../SidescrollerCamera") var camera: SidescrollerCamera?
    @Node("../SidescrollerCamera/Overlay") var bgOverlay: Polygon2D?
    @Node("../SubViewport") var subViewport: SubViewport?
    
    @Node("../CanvasLayer/HUD") var hud: HUD?
    @Node("../CanvasLayer/PauseMenu") var pauseMenu: Control?
    @Node("../CanvasLayer/PauseMenu/Overlay") var canvasOverlay: ColorRect?
    
    @Node("../Parallax2D") var parallaxLayer: Parallax2D?
    
    @Export var worldToLoad: String = ""
    @Export var roomToLoad: String = ""
    
    @Export var tileMaterial: ShaderMaterial? // move somewhere else
    
    private(set) var world: World?
    
    var lastCellPosition: Vector2i = .zero
    
    var currentRoom: Node2D?
    
    var isPaused = false
    
    override func _ready() {
        self.processMode = .always
        
        let worldFile = "res://tiled/\(worldToLoad).world"
        do {
            self.world = try World.load(from: worldFile)
        } catch {
            logError("Failed to decode world data from '\(worldFile)' with error: \(error).")
        }
        
        guard let player, let world else { return }
        
        camera?.target = player
        hud?.setPlayerNode(player)
        
        if roomToLoad != "" {
            for map in world.maps {
                if File(path: map.fileName).name == roomToLoad {
                    player.position.x = Float(map.x)
                    player.position.y = Float(map.y)
                }
            }
        }
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
    
    func pause() {
        isPaused = true
        pauseMenu?.visible = true
        getTree()?.paused = true
        
        _ = getTree()?.createTween()?
            .setPauseMode(.process)?
            .tweenProperty(object: canvasOverlay, property: "modulate", finalVal: Variant(Color.white), duration: 0.4)
    }
    
    func unpause() {
//        isPaused = false
//        getTree()?.paused = false
//        pauseMenu?.visible = false
        
        let tween = getTree()?.createTween()?
            .setPauseMode(.process)?
            .tweenProperty(object: canvasOverlay, property: "modulate", finalVal: Variant(Color.transparent), duration: 0.4)
        tween?.finished.connect { [weak self] in
            self?.isPaused = false
            self?.getTree()?.paused = false
            self?.pauseMenu?.visible = false
        }
    }
    
    func instantiateRoom(_ map: World.Map) -> Node2D? {
        let mapPath = "res://tiled/\(map.fileName)"
        let roomScene = ResourceLoader.load(path: mapPath) as? PackedScene
        let room = roomScene?.instantiate() as? Node2D
        room?.position = Vector2(x: Float(map.x), y: Float(map.y))
        
        if let parallaxLayer {
            for child in parallaxLayer.getChildren() {
                child?.queueFree()
            }
            if let parallax = room?.findChild(pattern: "parallax") as? Node2D {
                parallax.owner = nil
                parallax.reparent(newParent: parallaxLayer, keepGlobalTransform: false)

                if let xParallax = parallax.getMeta(name: "parallax_x", default: 1.0) {
                    parallaxLayer.scrollScale.x = Float(xParallax)
                }
                if let yParallax = parallax.getMeta(name: "parallax_y", default: 1.0) {
                    parallaxLayer.scrollScale.y = Float(yParallax)
                }
            }
        }
        
        // proof of concept for x-ray collisions
//        if let collisionLayer = room?.findChild(pattern: "collision-mask") as? Node2D {
//            collisionLayer.visible = true
//            collisionLayer.zIndex = 1000
////            collisionLayer.setVisibilityLayerBit(layer: 1, enabled: false)
////            collisionLayer.setVisibilityLayerBit(layer: 2, enabled: true)
//            collisionLayer.modulate = Color.white
//            if let tileMaterial {
//                collisionLayer.material = tileMaterial.duplicate() as? Material
//            }
//        }
        
        return room
    }
    
    func onCellChanged(_ nextCell: Vector2i, playerPosition: Vector2) {
        guard let world else {
            logError("World instance not found!")
            return
        }
        
        let moveDelta = nextCell - lastCellPosition
        lastCellPosition = nextCell
        hud?.minimap?.onCellChanged(newOffset: nextCell)
        
        for map in world.maps {
            if // find which room the player is in
                Int32(playerPosition.x) >= map.x && Int32(playerPosition.x) < map.x + map.width &&
                Int32(playerPosition.y) >= map.y && Int32(playerPosition.y) < map.y + map.height
            {
                if StringName(File(path: map.fileName).name) != currentRoom?.name {
                    onRoomTransition(to: map, moveDelta: moveDelta)
                }
            }
        }
    }
    
    func onRoomTransition(to map: World.Map, moveDelta: Vector2i) {
        if currentRoom == nil { // is the first room, just set the limits
            let newRoom = instantiateRoom(map)
//            getParent()?.addChild(node: newRoom)
            addChild(node: newRoom)
            camera?.limitLeft = map.x
            camera?.limitRight = map.x + map.width
            camera?.limitTop = map.y
            camera?.limitBottom = map.y + map.height
            currentRoom = newRoom
            
            if let spawn = newRoom?.findChild(pattern: "spawn-point", recursive: true) as? Node2D {
                player?.globalPosition.x = spawn.globalPosition.x
                player?.globalPosition.y = spawn.globalPosition.y
            }
        } else { // perform room transition
            guard let camera else { return }
            let sceneTree = getTree()
            sceneTree?.paused = true
            
            let overlayTween = getTree()?.createTween()?
                .setPauseMode(.process)?
                .tweenProperty(object: bgOverlay, property: "self_modulate", finalVal: Variant(Color.black), duration: 0.15)
            overlayTween?.finished.connect { [weak self] in
                let newRoom = self?.instantiateRoom(map)
                self?.getParent()?.addChild(node: newRoom)
                
                let offset = Vector2(x: TILE_SIZE * ROOM_WIDTH * moveDelta.x, y: TILE_SIZE * ROOM_HEIGHT * moveDelta.y)
                let tween = self?.getTree()?.createTween()?
                    .setPauseMode(.process)
                _ = tween?.tweenProperty(object: camera, property: "offset", finalVal: Variant(offset), duration: 0.7)
                _ = tween?.tweenProperty(object: self?.bgOverlay, property: "self_modulate", finalVal: Variant(Color.transparent), duration: 0.15)
                
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
        }
        log("Current room: \(currentRoom?.name ?? "")")
    }
}
