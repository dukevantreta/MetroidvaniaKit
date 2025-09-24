import SwiftGodot
import Foundation

struct World: Codable {
    struct Map: Codable {
        let fileName: String
        let width: Int32
        let height: Int32
        let x: Int32
        let y: Int32
    }
    let maps: [Map]
    let type: String
    let onlyShowAdjacentMaps: Bool
}

@Godot(.tool)
class WorldImporter: Node {
    
    let mapsDir = "res://maps/"
    
    @Callable
    func importResource(
        sourceFile: String,
        savePath: String,
        options: GDictionary,
        platformVariants: VariantCollection<String>,
        genFiles: VariantCollection<String>
    ) -> Int {
//        let error = `import`(sourceFile: sourceFile, savePath: savePath, options: options)
        let error = importModular(sourceFile: sourceFile, savePath: savePath, options: options)
        return Int(error.rawValue)
    }
    
    private func `import`(
        sourceFile: String,
        savePath: String,
        options: GDictionary
    ) -> GodotError {
        
        // remove old tileset .tres here
        
//        let gTileset = touchTileSet(tiledMap: map)
        
//        do {
//            let file = try File(path: sourceFile)
//            
//            guard FileAccess.fileExists(path: file.path) else {
//                logError("Import file '\(sourceFile)' not found.")
//                return .errFileNotFound
//            }
//            guard let worldData = FileAccess.getFileAsString(path: file.path).data(using: .utf8) else {
//                logError("Failed to read world data from '\(sourceFile)'.")
//                return .errInvalidData
//            }
//            
//            let world = try JSONDecoder().decode(World.self, from: worldData)
//            log("Importing world: \(file.name)")
//            
//            let tileset = try overrideTileSet(named: file.name)
//            
//            // save tileset after or before maps
//            
//            let root = Node2D()
//            root.name = StringName(file.name)
//            
//            let mapData = Minimap()
//            
//            for map in world.maps {
//                let mapPath = "\(file.directory)/\(map.fileName)"
//                
//                let mapName = map.fileName.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
//                
//                // import map
//                try importTileMap(sourceFile: mapPath, savePath: "res://maps/\(mapName)", gTileset: tileset)
//                
//                let path = "res://tiled/\(map.fileName)"
//                if let mapScene = ResourceLoader.load(path: path) as? PackedScene, let mapNode = mapScene.instantiate() as? Node2D {
//                    log("FOUND SCENE NODE")
//                    mapNode.position.x = Float(map.x)
//                    mapNode.position.y = Float(map.y)
//                    root.addChild(node: mapNode)
//                    
//                    processMapData(mapData, map: map, node: mapNode)
//                } else {
//                    log("MISSING SCENE NODE!!!")
//                }
//            }
//            
//            // save tileset
//            try saveResource(tileset, path: "res://maps/\(file.name).tileset.tres")
//            
//            let dataString = try mapData.encode()
//            let fileHandle = FileAccess.open(path: "res://maps/mapdata.json", flags: .write)
//            fileHandle?.storeString(dataString)
//            fileHandle?.close()
//            
//            for child in root.getChildren() {
//                child.owner = root
//            }
//            
//            let scene = PackedScene()
//            scene.pack(path: root)
//            
//            let outputFile = "\(savePath).tscn"
//            let err = ResourceSaver.save(resource: scene, path: outputFile)
//            
//            if err != .ok {
//                logError("ERROR SAVING WORLD: \(err)")
//            }
//            return err
//            
//        } catch {
//            logError("ERROR IMPORTING WORLD: \(error)")
//            return .ok
//        }
        return .ok
    }
    
    private func importModular(
        sourceFile: String,
        savePath: String,
        options: GDictionary
    ) -> GodotError {
        guard FileAccess.fileExists(path: sourceFile) else {
            logError("Import file '\(sourceFile)' not found.")
            return .errFileNotFound
        }
        guard let worldData = FileAccess.getFileAsString(path: sourceFile).data(using: .utf8) else {
            logError("Failed to read world data from '\(sourceFile)'.")
            return .errInvalidData
        }
        guard let worldName = sourceFile.components(separatedBy: "/").last?.components(separatedBy: ".").first else {
            logError("Malformed filename: \(sourceFile).")
            return .errFileUnrecognized
        }
        do {
            let root = try createWorld(named: worldName, from: worldData)
            let scene = PackedScene()
            scene.pack(path: root)
            try saveResource(scene, path: "\(savePath).tscn")
            return .ok
        } catch {
            logError("Failed to create world with error: \(error)")
            return .errScriptFailed
        }
    }
    
    func createWorld(named name: String, from data: Data) throws -> Node2D {
        let world = try JSONDecoder().decode(World.self, from: data)
        log("WORLD: \(world)")
        
        let root = Node2D()
        root.name = StringName(name)
        
        let mapData = Minimap()
        
        for map in world.maps {
            let path = "res://tiled/\(map.fileName)"
            if let mapScene = ResourceLoader.load(path: path) as? PackedScene, let mapNode = mapScene.instantiate() as? Node2D {
                log("FOUND SCENE NODE")
                mapNode.position.x = Float(map.x)
                mapNode.position.y = Float(map.y)
                root.addChild(node: mapNode)
                
                processMapData(mapData, map: map, node: mapNode)
            } else {
                log("MISSING SCENE NODE!!!")
            }
        }
        for child in root.getChildren() {
            child.owner = root
        }
        
        let dataString = try mapData.encode()
        let fileHandle = FileAccess.open(path: "res://maps/mapdata.json", flags: .write)
        fileHandle?.storeString(dataString)
        fileHandle?.close()
        
        return root
    }
    
//    func setOwner(_ owner: Node, to node: Node) {
//        node.owner = owner
//        for child in node.getChildren() {
//            setOwner(owner, to: child)
//        }
//    }
    
    func processMapData(_ data: Minimap, map: World.Map, node: Node2D) {
        guard let tilemap = node.getChildren().first as? TileMapLayer else {
            logError("CANT GET TILEMAP FROM SCENE NODE")
            return
        }
        let viewportSize = Vector2i(x: 25, y: 15) // static constant for the game
        let tileSize = Vector2i(x: 16, y: 16)
        
        let roomMatrix = Rect2i(
            x: (map.x / tileSize.x) / viewportSize.x,
            y: (map.y / tileSize.y) / viewportSize.y,
            width: (map.width / tileSize.x) / viewportSize.x,
            height: (map.height / tileSize.y) / viewportSize.y
        )
        let zLayer: Int32 = 0
        
        var indexedCells: [Vector3i: Minimap.Cell] = [:]
        
        for xCell in 0..<roomMatrix.size.x {
            for yCell in 0..<roomMatrix.size.y {
                var borders: [BorderType] = [.empty, .empty, .empty, .empty]
                
                let minX = xCell * viewportSize.x
                let maxX = (xCell + 1) * viewportSize.x - 1
                
                let minY = yCell * viewportSize.y
                let maxY = (yCell + 1) * viewportSize.y - 1
                
                // left & right
                var leftCount = 0
                var rightCount = 0
                for i in 0..<viewportSize.y {
                    let leftTileCoords = Vector2i(x: minX, y: minY + i)
                    if tilemap.getCellTileData(coords: leftTileCoords) != nil {
                        leftCount += 1
                    }
                    let rightTileCoords = Vector2i(x: maxX, y: minY + i)
                    if tilemap.getCellTileData(coords: rightTileCoords) != nil {
                        rightCount += 1
                    }
                }
                if rightCount == viewportSize.y {
                    borders[0] = .wall
                } else if rightCount >= viewportSize.y - 5 {
                    borders[0] = .passage
                }
                if leftCount == viewportSize.y {
                    borders[2] = .wall
                } else if leftCount >= viewportSize.y - 5 {
                    borders[2] = .passage
                }
                
                // up & down
                var upCount = 0
                var downCount = 0
                for i in 0..<viewportSize.x {
                    let upTileCoords = Vector2i(x: minX + i, y: minY)
                    if tilemap.getCellTileData(coords: upTileCoords) != nil {
                        upCount += 1
                    }
                    let downTileCoords = Vector2i(x: minX + i, y: maxY)
                    if tilemap.getCellTileData(coords: downTileCoords) != nil {
                        downCount += 1
                    }
                }
                if upCount == viewportSize.x {
                    borders[3] = .wall
                } else if upCount >= viewportSize.x - 5 {
                    borders[3] = .passage
                }
                if downCount == viewportSize.x {
                    borders[1] = .wall
                } else if downCount >= viewportSize.x - 5 {
                    borders[1] = .passage
                }
                
                if upCount == 0 && downCount == 0 && leftCount == 0 && rightCount == 0 {
                    // need to check for room 100% empty for big rooms
                    continue
                }
                
                let cellCoords = Vector3i(x: roomMatrix.position.x + xCell, y: roomMatrix.position.y + yCell, z: zLayer)
                let cell = Minimap.Cell(borders: borders)
                indexedCells[cellCoords] = cell
                
                // walk room
                // i = 2
                if let sideCell = indexedCells[cellCoords + .left] {
                    if cell.borders[2] != sideCell.borders[0] {
                        cell.borders[2] = .empty
                        sideCell.borders[0] = .empty
                    } else if cell.borders[2] != .empty {
                        cell.borders[2] = .empty
                        sideCell.borders[0] = .empty
                    }
                }

                // i = 3
                if let sideCell = indexedCells[cellCoords + .up] {
                    if cell.borders[3] != sideCell.borders[1] {
                        cell.borders[3] = .empty
                        sideCell.borders[1] = .empty
                    } else if cell.borders[3] != .empty {
                        cell.borders[3] = .empty
                        sideCell.borders[1] = .empty
                    }
                }
            }
        }
        for indexedCell in indexedCells {
            let loc = indexedCell.key
            data[loc.x, loc.y, loc.z] = indexedCell.value
        }
    }
}
