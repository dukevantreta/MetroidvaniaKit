import SwiftGodot
import Foundation

@Godot(.tool)
class WorldImporter: RefCounted, VerboseLogger {
    
    let mapsDir = "res://maps/"
    
    var sourceFile = ""
    var outputDirectory = ""
    var tileSize: Int32 = 0
    var roomWidth: Int32 = 0
    var roomHeight: Int32 = 0
    var verbose = false

    private var startTime: UInt = 0
    
    deinit {
        let secondsElapsed = TimeInterval(Time.getTicksMsec() - startTime) / 1000
        logVerbose("--> Finished import for \"\(sourceFile)\" after \(String(format: "%.3f", secondsElapsed))s")
    }

    @Callable
    func importResource(
        sourceFile: String,
        savePath: String,
        options: VariantDictionary,
        platformVariants: TypedArray<String>,
        genFiles: TypedArray<String>
    ) -> Int {
        let error = `import`(sourceFile: sourceFile, savePath: savePath, options: options)
        return Int(error.rawValue)
    }
    
    private func `import`(
        sourceFile: String,
        savePath: String,
        options: VariantDictionary
    ) -> GodotError {
        self.startTime = Time.getTicksMsec()
        self.sourceFile = sourceFile
        outputDirectory = options["map_data_output"]?.to() ?? ""
        tileSize = options["tile_size_in_pixels"].to() ?? 1
        roomWidth = options["room_width_in_tiles"].to() ?? 1
        roomHeight = options["room_height_in_tiles"].to() ?? 1
        verbose = options["verbose"]?.to() ?? false
        
        logVerbose("Importing world: \"\(sourceFile)\"")
        do {
            let file = File(path: sourceFile)
            let data = try file.getData(.ascii)
            let root = try createWorld(from: file, from: data)
            let scene = PackedScene()
            let error = scene.pack(path: root)
            guard error == .ok else {
                logError("Failed to pack scene '\(root.name)'")
                throw error
            }
            try File(path: "\(savePath).tscn").saveResource(scene)
            return .ok
        } catch {
            logError("Failed to create world with error: \(error)")
            return .errScriptFailed
        }
    }
    
    func createWorld(from file: File, from data: Data) throws -> Node2D {
        let world = try JSONDecoder().decode(World.self, from: data)
        let mapData = Minimap()

        let root = Node2D()
        root.setName(file.name)
        
        for map in world.maps {
            let mapFile = File(path: "\(file.directory)/\(map.fileName)")
            let mapNode: Node2D = try mapFile.loadResource(ofType: PackedScene.self).instantiate()
            mapNode.position.x = Float(map.x)
            mapNode.position.y = Float(map.y)
            root.addChild(node: mapNode)

            logVerbose("Processing map data for \"\(file.path)\"")
            processMapData(mapData, map: map, node: mapNode)
        }
        for child in root.getChildren() {
            child?.owner = root
        }
        
        let dataString = try mapData.encode()
        let outputFile = "\(outputDirectory)/\(file.name).json"
        guard let fileHandle = FileAccess.open(path: outputFile, flags: .write) else {
            throw ImportError.failedToSaveFile(file.name, FileAccess.getOpenError())
        }
        if fileHandle.storeString(dataString) == false {
            logError("Failed to save world data to file.")
        }
        fileHandle.close()
        return root
    }
    
    func processMapData(_ data: Minimap, map: World.Map, node: Node2D) {
        guard let tilemap = node.findChild(pattern: "collision-mask") as? TileMapLayer else {
            logError("Collision mask not found for scene: \(node)")
            return
        }
        let moduleSize = Vector2i(x: roomWidth, y: roomHeight)
        let tileSize = Vector2i(x: tileSize, y: tileSize)
        
        let roomMatrix = Rect2i(
            x: (map.x / tileSize.x) / moduleSize.x,
            y: (map.y / tileSize.y) / moduleSize.y,
            width: (map.width / tileSize.x) / moduleSize.x,
            height: (map.height / tileSize.y) / moduleSize.y
        )
        let zLayer: Int32 = 0
        
        var indexedCells: [Vector3i: Minimap.Cell] = [:]
        
        for xCell in 0..<roomMatrix.size.x {
            for yCell in 0..<roomMatrix.size.y {
                var borders: [BorderType] = [.empty, .empty, .empty, .empty]
                
                let minX = xCell * moduleSize.x
                let maxX = (xCell + 1) * moduleSize.x - 1
                
                let minY = yCell * moduleSize.y
                let maxY = (yCell + 1) * moduleSize.y - 1
                
                // left & right
                var leftCount = 0
                var rightCount = 0
                for i in 0..<moduleSize.y {
                    let leftTileCoords = Vector2i(x: minX, y: minY + i)
                    if tilemap.getCellTileData(coords: leftTileCoords) != nil {
                        leftCount += 1
                    }
                    let rightTileCoords = Vector2i(x: maxX, y: minY + i)
                    if tilemap.getCellTileData(coords: rightTileCoords) != nil {
                        rightCount += 1
                    }
                }
                if rightCount == moduleSize.y {
                    borders[0] = .wall
                } else if rightCount >= moduleSize.y - 5 {
                    borders[0] = .passage
                }
                if leftCount == moduleSize.y {
                    borders[2] = .wall
                } else if leftCount >= moduleSize.y - 5 {
                    borders[2] = .passage
                }
                
                // up & down
                var upCount = 0
                var downCount = 0
                for i in 0..<moduleSize.x {
                    let upTileCoords = Vector2i(x: minX + i, y: minY)
                    if tilemap.getCellTileData(coords: upTileCoords) != nil {
                        upCount += 1
                    }
                    let downTileCoords = Vector2i(x: minX + i, y: maxY)
                    if tilemap.getCellTileData(coords: downTileCoords) != nil {
                        downCount += 1
                    }
                }
                if upCount == moduleSize.x {
                    borders[3] = .wall
                } else if upCount >= moduleSize.x - 5 {
                    borders[3] = .passage
                }
                if downCount == moduleSize.x {
                    borders[1] = .wall
                } else if downCount >= moduleSize.x - 5 {
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
