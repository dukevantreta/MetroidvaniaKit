import SwiftGodot
import Foundation

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
    static let defaultTileShape: TileSet.TileShape = .square

    var sourceFile = ""
    var targetName = ""
    var targetDirectory = ""
    var verbose = false
    var overrideAtlas = false

    var targetPath: String {
        URL(string: targetDirectory)?
            .appendingPathComponent(targetName)
            .appendingPathExtension("tres")
            .absoluteString ?? ""
    }

    deinit {
        logVerbose("<<< Finished import for '\(sourceFile)' >>>")
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
        targetDirectory = options["target_directory"]?.to() ?? ""
        targetName = options["target_filename"]?.to() ?? ""
        verbose = options["verbose"]?.to() ?? false
        overrideAtlas = options["overrides_existing_atlas"]?.to() ?? false

        logVerbose("--> Importing tileset: '\(sourceFile)'...")
        do {
            let file = try File(path: sourceFile)
            let xml = try XML.parse(file.path, with: XMLParser())
            let tiledTileset = try Tiled.TileSet(from: xml.root)

            guard let tileWidth = tiledTileset.tileWidth, let tileHeight = tiledTileset.tileHeight else {
                throw ImportError.undefinedTileSize
            }

            let godotTileset = try touchTileSet(tileWidth: Int32(tileWidth), tileHeight: Int32(tileHeight))
            try importLazy(from: tiledTileset, intoTileSet: godotTileset, file: file)

            let resource = TileSetResource()
            resource.atlasName = file.name
            try saveResource(resource, path: "\(savePath).tres")
            logVerbose("Successfully imported \(file.name).tsx")
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
    
    func touchTileSet(tileWidth: Int32, tileHeight: Int32) throws -> TileSet {
        let tileset: TileSet
        if !FileAccess.fileExists(path: targetPath) {
            let newTileset = TileSet()
            newTileset.resourceName = targetName
            newTileset.tileShape = Self.defaultTileShape
            newTileset.tileSize = Vector2i(
                x: tileWidth,
                y: tileHeight
            )
            tileset = newTileset
        } else {
            tileset = try loadResource(ofType: TileSet.self, at: targetPath)
            // check for consistency (tile size, tile shape...)
        }
        return tileset
    }
    
    func importLazy(from tiledTileset: Tiled.TileSet, intoTileSet gTileset: TileSet, file: File) throws {
        let atlasName = tiledTileset.name ?? ""

        if overrideAtlas && gTileset.hasSource(named: atlasName) {
            logVerbose("Overriding atlas source, removing '\(atlasName)'")
            gTileset.removeSource(named: atlasName)
        }

        if !gTileset.hasSource(named: atlasName) {
            guard let imageSource = tiledTileset.image?.source else {
                logError("No image source reference found for tileset: \(tiledTileset.name)")
                throw ImportError.noTileSetImageSource
            }
            
            parseProperties(from: tiledTileset, intoGodot: gTileset)
            
            let spritesheetPath = [file.directory, imageSource].joined(separator: "/")
            let atlasSource = TileSetAtlasSource()
            atlasSource.resourceName = atlasName
            atlasSource.texture = try loadResource(ofType: Texture2D.self, at: spritesheetPath)
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
                    logError("Failed to get tile data from atlas source."); break
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
            
            logVerbose("Saving '\(atlasName)' atlas to '\(targetPath)'")
            try saveResource(gTileset, path: targetPath)
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
                        logVerbose("ADDING PHYSICS LAYER: \(layerIndex)")
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