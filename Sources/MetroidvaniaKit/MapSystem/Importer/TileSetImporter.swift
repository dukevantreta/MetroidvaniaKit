import SwiftGodot
import Dispatch

protocol VerboseLogger {
    var verbose: Bool { get set }
    func logVerbose(_ message: String)
}

extension VerboseLogger where Self: RefCounted {
    func logVerbose(_ message: String) {
        if verbose {
            log(message)
        }
    }
}

extension RefCounted: GodotLogger {}

@Godot(.tool)
class TileSetImporter: RefCounted, VerboseLogger {
    
    static let defaultImportPath = "res://maps/tileset.tres"
    let defaultOutputPath = "res://maps/"
    let defaultTileSetPath = "res://maps/tileset.tres"

    static let defaultTileShape: TileSet.TileShape = .square
    static let defaultTileSetName = "tileset"

    var sourceFile = ""
    var verbose = false

    deinit {
        logVerbose("Deinitializing importer for \(sourceFile)")
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
        self.sourceFile = sourceFile
        guard FileAccess.fileExists(path: sourceFile) else {
            logError("Import file '\(sourceFile)' not found.")
            return .errFileNotFound
        }
        
        verbose = options["verbose"]?.to() ?? false

        logVerbose("Importing tileset: '\(sourceFile)'...")
        do {
            let file = try File(path: sourceFile)
            let xml = try XML.parse(file.path, with: XMLParser())
            let tiledTileset = try Tiled.TileSet(from: xml.root)

            guard let tileWidth = tiledTileset.tileWidth, let tileHeight = tiledTileset.tileHeight else {
                throw ImportError.undefinedTileSize
            }

            let godotTileset = try TileSetImporter.touchTileSet(tileWidth: Int32(tileWidth), tileHeight: Int32(tileHeight))
            // try importLazy(sourceFile: sourceFile, intoTileSet: godotTileset)
            try importLazy(from: tiledTileset, intoTileSet: godotTileset, file: file)

            let res = TileSetResource()
            res.atlasName = file.name
            try saveResource(res, path: "\(savePath).tres")
            GD.print("Saved \(savePath).tres")
            return .ok
        } catch let error as XML.ParseError {
            logError("Failed to parse .tsx file: \(error)")
            return .errFileCantRead
        } catch let error as Tiled.ParseError {
            logError("Failed to parse tileset data: \(error)")
            return .errInvalidData
        } catch {
            logError("Failed to import '\(sourceFile)' with error: \(error)")
            return .errScriptFailed
        }
    }
    
    static func touchTileSet(tileWidth: Int32, tileHeight: Int32) throws -> TileSet {
        let gTileset: TileSet
        if !FileAccess.fileExists(path: defaultImportPath) {
            let newTileset = TileSet()
            newTileset.resourceName = Self.defaultTileSetName
            newTileset.tileShape = Self.defaultTileShape
            newTileset.tileSize = Vector2i(
                x: tileWidth,
                y: tileHeight
            )
            gTileset = newTileset
        } else {
            gTileset = try loadResource(ofType: TileSet.self, at: defaultImportPath)
            // check for consistency (tile size, tile shape...)
        }
        return gTileset
    }
    
    // func importLazy(sourceFile: String, intoTileSet gTileset: TileSet) throws {
    func importLazy(from tiledTileset: Tiled.TileSet, intoTileSet gTileset: TileSet, file: File) throws {
        // let file = try File(path: sourceFile)
        // let atlasName = file.name
        let atlasName = tiledTileset.name ?? ""

        if !gTileset.hasSource(named: atlasName) {
            log("Importing tileset atlas '\(atlasName)'...")
            guard let imageSource = tiledTileset.image?.source else {
                logError("No image source reference found for tileset: \(tiledTileset.name)")
                throw ImportError.noTileSetImageSource
            }
            
            let spritesheetPath = [file.directory, imageSource].joined(separator: "/")
            let atlasTexture = try loadResource(ofType: Texture2D.self, at: spritesheetPath)
            
            parseProperties(from: tiledTileset, intoGodot: gTileset)
            
            let atlasSource = TileSetAtlasSource()
            atlasSource.resourceName = atlasName
            atlasSource.texture = atlasTexture
            atlasSource.margins = Vector2i(x: tiledTileset.margin, y: tiledTileset.margin)
            atlasSource.separation = Vector2i(x: tiledTileset.spacing, y: tiledTileset.spacing)
            
            gTileset.addSource(atlasSource) // NOTE: Seems that atlas need to be added BEFORE adding collision to tiles (collisions bugging on import)
            
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
                            tileData.addCollisionPolygon(layerId: physicsLayerIdx)
                            tileData.setCollisionPolygonPoints(layerId: physicsLayerIdx, polygonIndex: 0, polygon: array)
                        } else { // rectangle
                            let origin = Vector2i(x: Int32(object.x) - tileSize.x >> 1, y: Int32(object.y) - tileSize.y >> 1)
                            let array = PackedVector2Array()
                            array.append(value: Vector2(x: origin.x, y: origin.y))
                            array.append(value: Vector2(x: origin.x + object.width, y: origin.y))
                            array.append(value: Vector2(x: origin.x + object.width, y: origin.y + object.height))
                            array.append(value: Vector2(x: origin.x, y: origin.y + object.height))
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
            
            try saveResource(gTileset, path: defaultTileSetPath)
            
            log("Imported tileset atlas source: '\(atlasName)'")
            
        } else {
            log("Found tileset atlas '\(atlasName)'. Skipping import...")
        }
    }
    
    // check for layer before adding?
    func parseProperties(from tiledTileset: Tiled.TileSet, intoGodot tileset: TileSet) {
        for property in tiledTileset.properties {
            if property.name.hasPrefix("collision_layer_") {
                if let layerIndex = Int32(property.name.components(separatedBy: "_").last ?? "") {
                    if layerIndex >= tileset.getPhysicsLayersCount() {
                        GD.print("ADDING PHYSICS LAYER: \(layerIndex)")
                        tileset.addPhysicsLayer(toPosition: layerIndex)
                        var layerMask: UInt32 = 0
                        for layer in property.value?.components(separatedBy: ",").compactMap { UInt32($0) } ?? [] {
                            layerMask |= 1 << (layer - 1)
                        }
                        tileset.setPhysicsLayerCollisionLayer(layerIndex: layerIndex, layer: layerMask)
                    }
                }
            }
        }
    }
}