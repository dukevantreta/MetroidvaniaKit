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

struct File {
    
    enum Error: Swift.Error {
        case malformedFileName(String)
    }
    
    let path: String
    let name: String
    let `extension`: String
    let directory: String
    
    init(path: String) throws {
        var pathComponents = path.components(separatedBy: "/")
        let fileName = pathComponents.removeLast()
        let nameStrings = fileName.components(separatedBy: ".")
        
        self.path = path
        self.name = try nameStrings.first ??? Error.malformedFileName(fileName)
        self.extension = try nameStrings.last ??? Error.malformedFileName(fileName)
        self.directory = pathComponents.joined(separator: "/")
    }
    
    var exists: Bool {
        FileAccess.fileExists(path: self.path)
    }
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
        let error = `import`(sourceFile: sourceFile, savePath: savePath, options: options)
//        let error = importModular(sourceFile: sourceFile, savePath: savePath, options: options)
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
    
//    var currentTileset: TileSet? // find a better solution
//    var localTilesetRefs: [Int32: String] = [:]
    
    private func importTileMap(
        sourceFile: String,
        savePath: String,
        gTileset: TileSet
    ) throws {
        let file = try File(path: sourceFile)
        guard FileAccess.fileExists(path: file.path) else {
            logError("Import file '\(sourceFile)' not found.")
            throw ImportError.godotError(.errFileNotFound)
        }
        let xml = try XML.parse(file.path, with: XMLParser())
        let map = try Tiled.TileMap(from: xml.root)
        guard map.orientation == .orthogonal else {
            throw ImportError.unsupportedMapType(map.orientation)
        }
        
        for tilesetRef in map.tilesets {
            let tilesetPath = [file.directory, tilesetRef.source ?? ""].joined(separator: "/")
            
            // open tileset file
            log("OPENING TILESET FILE: \(tilesetPath)")
            try openTileSet(sourceFile: tilesetPath, importTo: gTileset)
            
//            if let gid = Int32(tilesetRef.firstGID ?? "") {
//                let name = tilesetRef.source?.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
//                localTilesetRefs[gid] = name
//            }
        }
        
//        let tilemap = try TileMapImporter().createTileMap(map: map, using: gTileset)
//        tilemap.name = StringName(file.name)
//        
//        let scene = PackedScene()
//        scene.pack(path: tilemap)
//        try saveResource(scene, path: "\(savePath).tscn")
//        
//        try saveResource(gTileset, path: "res://maps/tileset.tres")
    }
    
    private func openTileSet(sourceFile: String, importTo gTileset: TileSet) throws {
        guard FileAccess.fileExists(path: sourceFile) else {
            logError("Import file '\(sourceFile)' not found.")
            throw ImportError.godotError(.errFileNotFound)
        }
        let xml = try XML.parse(sourceFile, with: XMLParser())
        
        let tiledTileset = try Tiled.TileSet(from: xml.root)
        
        guard let imageSource = tiledTileset.image?.source else {
            logError("No image source reference found for tileset: \(tiledTileset.name)")
            throw ImportError.noTileSetImageSource
        }
        
        var path = sourceFile.components(separatedBy: "/")
        var filename = path.removeLast()
        let atlasName = filename.components(separatedBy: ".").first ?? ""
        
        let spritesheetPath = [path.joined(separator: "/"), imageSource].joined(separator: "/")
        
        let atlasTexture = try loadResource(ofType: Texture2D.self, at: spritesheetPath)
        
        if !gTileset.hasSource(named: atlasName) {
            log("Creating new atlas source: \(atlasName)")
            
            parseProperties(from: tiledTileset, toGodot: gTileset)
            
            let atlasSource = TileSetAtlasSource()
            atlasSource.resourceName = atlasName
            atlasSource.texture = atlasTexture
            atlasSource.margins = Vector2i(x: tiledTileset.margin, y: tiledTileset.margin)
            atlasSource.separation = Vector2i(x: tiledTileset.spacing, y: tiledTileset.spacing)
            
            let columns = Int32(tiledTileset.columns ?? 0)
            let rows = Int32(tiledTileset.tileCount ?? 0) / columns
            
            // create tiles
            for row in 0..<rows {
                for column in 0..<columns {
                    let atlasCoords = Vector2i(x: column, y: row)
                    atlasSource.createTile(atlasCoords: atlasCoords)
                }
            }
            
            for tile in tiledTileset.tiles {
                let atlasCoords = Vector2i(
                    x: Int32(tile.id) % columns,
                    y: Int32(tile.id) / columns)
                
                guard let tileData = atlasSource.getTileData(atlasCoords: atlasCoords, alternativeTile: 0) else {
                    GD.print("ERROR GETTING TILE DATA"); break
                }
                let tileSize = Vector2i(
                    x: Int32(tiledTileset.tileWidth ?? 0),
                    y: Int32(tiledTileset.tileHeight ?? 0)
                )
                let halfTile = tileSize / 2
                
                // there is some buggy stuff here
// LOG: scene/resources/tile_set.cpp:5430 - Index p_layer_id = 0 is out of bounds (physics.size() = 0).
                if let objectGroup = tile.objectGroup {
                    for object in objectGroup.objects {
                        
                        var physicsLayerIdx: Int32 = 0
                        for property in object.properties {
                            if property.name == "physics_layer" {
                                if let index = Int32(property.value ?? "") {
                                    physicsLayerIdx = index
                                }
                            }
                        }
                        
                        if let polygon = object.polygon {
                            let origin = Vector2i(x: Int32(object.x), y: Int32(object.y))
                            let array = PackedVector2Array()
                            for point in polygon.points {
                                array.append(value: Vector2(
                                    x: origin.x + Int32(point.x) - halfTile.x,
                                    y: origin.y + Int32(point.y) - halfTile.y
                                ))
                            }
                            GD.print("ADDING COLLISION POLYGON TO: \(physicsLayerIdx)")
                            tileData.addCollisionPolygon(layerId: physicsLayerIdx)
                            tileData.setCollisionPolygonPoints(layerId: physicsLayerIdx, polygonIndex: 0, polygon: array)
                        } else { // rectangle
                            let origin = Vector2i(x: Int32(object.x) - tileSize.x >> 1, y: Int32(object.y) - tileSize.y >> 1)
                            let array = PackedVector2Array()
                            array.append(value: Vector2(x: origin.x, y: origin.y))
                            array.append(value: Vector2(x: origin.x + object.width, y: origin.y))
                            array.append(value: Vector2(x: origin.x + object.width, y: origin.y + object.height))
                            array.append(value: Vector2(x: origin.x, y: origin.y + object.height))
                            GD.print("ADDING COLLISION RECT TO: \(physicsLayerIdx)")
                            tileData.addCollisionPolygon(layerId: physicsLayerIdx)
                            tileData.setCollisionPolygonPoints(layerId: physicsLayerIdx, polygonIndex: 0, polygon: array)
                        }
                    }
                }
                
                // tile animation support is too limited
//                if let animationFrames = tile.animation?.frames {
//                    atlasSource.setTileAnimationFramesCount(atlasCoords: atlasCoords, framesCount: Int32(animationFrames.count))
//                    let uniqueFrames = Array(Set(animationFrames.map { $0.tileID }))
//                    atlasSource.setTileAnimationColumns(atlasCoords: atlasCoords, frameColumns: Int32(animationFrames.count))
//                    for i in 0..<animationFrames.count {
//                        let frameDuration = Double(animationFrames[i].duration) / 1000
//                        atlasSource.setTileAnimationFrameDuration(atlasCoords: atlasCoords, frameIndex: Int32(i), duration: frameDuration)
//                    }
//                }
            }
            
            
        }
    }
    
    private func overrideTileSet(named name: String) throws -> TileSet {
        let tilesetName = "\(name).tileset"
        if FileAccess.fileExists(path: "res://maps/\(tilesetName).tres") {
            let err = DirAccess().remove(path: "res://maps/\(tilesetName).tres")
            if err != .ok {
                logError("Failed to delete tileset resource file: \(err)")
                throw ImportError.godotError(err)
            }
        }
        let tileset = TileSet()
        tileset.resourceName = tilesetName
        tileset.tileShape = .square
        tileset.tileSize = Vector2i(x: 16, y: 16) // MAGIC NUMBER
        return tileset
    }
    
    static func touchTileSet(width: Int32, height: Int32) -> TileSet {
        let gTileset: TileSet
        if !FileAccess.fileExists(path: "res://maps/tileset.tres") {
            let newTileset = TileSet()
            newTileset.resourceName = "tileset"
            newTileset.tileShape = .square
            newTileset.tileSize = Vector2i(
                x: width,
                y: height
            )
//                ResourceSaver.save(resource: newTileset, path: defaultTileSetPath)
            gTileset = newTileset
        } else {
            gTileset = ResourceLoader.load(path: "res://maps/tileset.tres") as! TileSet
        }
        
//        for tTileset in tiledMap.tilesets {
//            
//        }
        
        return gTileset
    }
    
    func parseProperties(from tiledTileset: Tiled.TileSet, toGodot tileset: TileSet) {
        for property in tiledTileset.properties {
            if property.name.hasPrefix("collision_layer_") {
                if let layerIndex = Int32(property.name.components(separatedBy: "_").last ?? "") {
                    tileset.addPhysicsLayer(toPosition: layerIndex)
                    GD.print("ADDING PHYSICS LAYER: \(layerIndex)")
                    var layerMask: UInt32 = 0
                    for layer in property.value?.components(separatedBy: ",").compactMap { UInt32($0) } ?? [] {
                        layerMask |= 1 << (layer - 1)
                    }
                    tileset.setPhysicsLayerCollisionLayer(layerIndex: layerIndex, layer: layerMask)
                }
            }
        }
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
            let world = try JSONDecoder().decode(World.self, from: worldData)
            log("WORLD: \(world)")
            
            let root = Node2D()
            root.name = StringName(worldName)
            
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
    
    func processMapData(_ data: Minimap, map: World.Map, node: Node2D) {
        guard let tilemap = node.getChildren().first as? TileMap else {
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
                    if tilemap.getCellTileData(layer: 0, coords: leftTileCoords) != nil {
                        leftCount += 1
                    }
                    let rightTileCoords = Vector2i(x: maxX, y: minY + i)
                    if tilemap.getCellTileData(layer: 0, coords: rightTileCoords) != nil {
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
                    if tilemap.getCellTileData(layer: 0, coords: upTileCoords) != nil {
                        upCount += 1
                    }
                    let downTileCoords = Vector2i(x: minX + i, y: maxY)
                    if tilemap.getCellTileData(layer: 0, coords: downTileCoords) != nil {
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
//
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
