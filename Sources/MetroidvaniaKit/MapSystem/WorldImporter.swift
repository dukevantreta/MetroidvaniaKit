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
    
    @Callable
    func importResource(
        sourceFile: String,
        savePath: String,
        options: GDictionary,
        platformVariants: VariantCollection<String>,
        genFiles: VariantCollection<String>
    ) -> Int {
        let error = `import`(sourceFile: sourceFile, savePath: savePath, options: options)
        return Int(error.rawValue)
    }
    
    private func `import`(
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
            let world = try JSONDecoder().decode(World.self, from: worldData)
            log("WORLD: \(world)")
            
            let root = Node2D()
            root.name = StringName(worldName)
            
            var minimapData = MinimapData(cells: [])
            
            for map in world.maps {
                let path = "res://tiled/\(map.fileName)"
                if let mapScene = ResourceLoader.load(path: path) as? PackedScene, let mapNode = mapScene.instantiate() as? Node2D {
                    log("FOUND SCENE NODE")
                    mapNode.position.x = Float(map.x)
                    mapNode.position.y = Float(map.y)
                    root.addChild(node: mapNode)
                    
                    processMinimapData(&minimapData, map: map, node: mapNode)
                } else {
                    log("MISSING SCENE NODE!!!")
                }
            }
            for child in root.getChildren() {
                child.owner = root
            }
            
            
            log("Minimap data: \(minimapData)")
            let encoded = try JSONEncoder().encode(minimapData)
            let dataString = String(data: encoded, encoding: .utf8)!
            let fileHandle = FileAccess.open(path: "res://maps/mapdata.json", flags: .write)
            fileHandle?.storeString(dataString)
            fileHandle?.close()
            
            
            let scene = PackedScene()
            scene.pack(path: root)
            
            let outputFile = "\(savePath).tscn"
            let err = ResourceSaver.save(resource: scene, path: outputFile)
            
            if err != .ok {
                logError("ERROR SAVING WORLD: \(err)")
            }
            return err
            
        } catch {
            logError("Error: \(error)") //
        }
        return .ok
    }
    
    func setOwner(_ owner: Node, to node: Node) {
        node.owner = owner
        for child in node.getChildren() {
            setOwner(owner, to: child)
        }
    }
    
    func processMinimapData(_ data: inout MinimapData, map: World.Map, node: Node2D) {
        guard let tilemap = node.getChildren().first as? TileMap else {
            logError("CANT GET TILEMAP FROM SCENE NODE")
            return
        }
        let roomSize = Vector2i(x: 25, y: 15) // static constant for the game
        let tileSize = Vector2i(x: 16, y: 16)
        
        let widthUnits = (map.width / tileSize.x) / roomSize.x
        let heightUnits = (map.height / tileSize.y) / roomSize.y
        
        let roomOrigin = Vector3i(
            x: (map.x / tileSize.x) / roomSize.x,
            y: (map.y / tileSize.y) / roomSize.y,
            z: 0
        )
        
        var roomMatrix: [[Int]] = Array(repeating: Array(repeating: 0, count: Int(heightUnits)), count: Int(widthUnits))
        
        for x in 0..<widthUnits {
            for y in 0..<heightUnits {
                let topLeftCorner = Vector2i(x: x * roomSize.x, y: y * roomSize.y)
                let bottomRightCorner = Vector2i(x: x * roomSize.x + (roomSize.x - 1), y: y * roomSize.y + (roomSize.y - 1))
                
                let topLeftTile = tilemap.getCellTileData(layer: 0, coords: topLeftCorner)
                let bottomRightTile = tilemap.getCellTileData(layer: 0, coords: bottomRightCorner)
                
                if topLeftTile != nil && bottomRightTile != nil {
//                    let cellCoordinates = Vector3i(
//                        x: roomOrigin.x + x,
//                        y: roomOrigin.y + y,
//                        z: roomOrigin.z)
                    
                    roomMatrix[Int(x)][Int(y)] = 1
                    
//                    data.cells.append(MinimapData.Cell(
//                        coordinates: MinimapData.Location(
//                            x: Int(roomOrigin.x + x),
//                            y: Int(roomOrigin.y + y),
//                            z: Int(roomOrigin.z)),
//                        borders: [-1,-1,-1,-1]
//                    ))
                }
            }
        }
        for x in 0..<widthUnits {
            for y in 0..<heightUnits {
                if roomMatrix[Int(x)][Int(y)] == 1 {
                    
                    var borders = [-1,-1,-1,-1]
                    
                    if x == 0 {
                        borders[2] = 0
                    } else if roomMatrix[Int(x) - 1][Int(y)] == 0 {
                        borders[2] = 0
                    }
                    
                    if x == widthUnits - 1 {
                        borders[0] = 0
                    } else if roomMatrix[Int(x) + 1][Int(y)] == 0 {
                        borders[0] = 0
                    }
                    
                    if y == 0 {
                        borders[3] = 0
                    } else if roomMatrix[Int(x)][Int(y) - 1] == 0 {
                        borders[3] = 0
                    }
                    
                    if y == heightUnits - 1 {
                        borders[1] = 0
                    } else if roomMatrix[Int(x)][Int(y) + 1] == 0 {
                        borders[1] = 0
                    }
                    
                    data.cells.append(MinimapData.Cell(
                        coordinates: MinimapData.Location(
                            x: Int(roomOrigin.x + x),
                            y: Int(roomOrigin.y + y),
                            z: Int(roomOrigin.z)),
                        borders: borders
                    ))
                }
            }
        }
    }
}

struct MinimapData: Codable {
    struct Location: Codable {
        let x: Int
        let y: Int
        let z: Int
    }
    struct Cell: Codable {
        let coordinates: Location
        let borders: [Int]
    }
    var cells: [Cell]
}

//class WorldImporter: EditorImportPlugin {
//    
//    override func _getImporterName() -> String {
//        "com.tiled.world.importer"
//    }
//    
//    override func _getVisibleName() -> String {
//        "World Importer"
//    }
//    
//    override func _getRecognizedExtensions() -> PackedStringArray {
//        PackedStringArray(["world"])
//    }
//    
//    override func _getResourceType() -> String {
//        "PackedScene"
//    }
//    
//    override func _getSaveExtension() -> String {
//        "tscn"
//    }
//    
//    override func _getImportOrder() -> Int32 {
//        0
//    }
//    
//    override func _getPriority() -> Double {
//        1.0
//    }
//    
//    override func _getImportOptions(
//        path: String,
//        presetIndex: Int32
//    ) -> VariantCollection<GDictionary> {
//        
//        GD.print("GET world import options")
//        return []
//    }
//    
//    override func _import(
//        sourceFile: String,
//        savePath: String,
//        options: GDictionary,
//        platformVariants: VariantCollection<String>,
//        genFiles: VariantCollection<String>
//    ) -> GodotError {
//        
//        GD.print("IMPORTING: \(sourceFile)")
//        
//        guard FileAccess.fileExists(path: sourceFile) else {
//            GD.pushError("[] Import file \(sourceFile) not found!")
//            return .errFileNotFound
//        }
//        
//        // do shenanigans
//        
//        return .ok
//    }
//}
