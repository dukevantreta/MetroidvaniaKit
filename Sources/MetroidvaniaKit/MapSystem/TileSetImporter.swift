import SwiftGodot

protocol TypeDescribable {
    static var typeDescription: String { get }
    var typeDescription: String { get }
}

extension TypeDescribable {
    static var typeDescription: String {
        return String(describing: self)
    }
    
    var typeDescription: String {
        return type(of: self).typeDescription
    }
}

protocol GodotLogger: TypeDescribable {
    func log(_ message: String)
    func logError(_ message: String)
}

extension GodotLogger {
    func log(_ message: String) {
        GD.print("[\(typeDescription)] \(message)")
    }
    func logError(_ message: String) {
        GD.pushError("[\(typeDescription)] \(message)")
    }
}

extension Node: GodotLogger {}

@Godot(.tool)
class TileSetImporter: Node {
    
    let defaultOutputPath = "res://output/"
    
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
        
        do {
            let xml = try XML.parse(sourceFile, with: XMLParser())
            let tiledTileset = try Tiled.TileSet(from: xml.root)
            guard let imageSource = tiledTileset.image?.source else {
                fatalError()
            }
            var path = sourceFile.components(separatedBy: "/")
            var filename = path.removeLast()
            let imageFile = [path.joined(separator: "/"), imageSource].joined(separator: "/")
            guard FileAccess.fileExists(path: imageFile) else {
                logError("Tileset source image '\(imageFile)' not found.")
                return .errFileNotFound
            }
            let imageName = imageFile.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
            
            let atlasSource = TileSetAtlasSource()
            atlasSource.resourceName = imageName //imageFile.components(separatedBy: "/").last ?? ""
            atlasSource.texture = ResourceLoader.load(path: imageFile) as? Texture2D
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
            
            let saveError = ResourceSaver.save(resource: atlasSource, path: "\(savePath).tres")
            if saveError != .ok {
                logError("Failed to save resource at '\(savePath)'")
                return saveError
            }
            
//            let copyName = "\(filename.components(separatedBy: ".").first ?? "").tres"
//            let copyError = ResourceSaver.save(resource: atlasSource, path: "\(defaultOutputPath)\(copyName)")
//            if copyError != .ok {
//                logError("Failed to save copy of '\(copyName)'")
//                return copyError
//            }
        } catch {
            logError("Error: \(error)")
        }
        
        return .ok
    }
}

class TileSetParser {
    
    static func parseTileSets(map: Tiled.TileMap, sourceFile: String) -> TileSet? {
        var filePathComponents = sourceFile.components(separatedBy: "/")
        filePathComponents.removeLast()
        let filePath = filePathComponents.joined(separator: "/")
        
        
        let gTileset = TileSet()
        gTileset.resourceName = "test-tileset" //tiledTileset.name ?? ""
        gTileset.setupLocalToScene() // save .res from separate importer and load as resource?
        
        let tileSize = Vector2i(
            x: Int32(map.tileWidth ?? 0),
            y: Int32(map.tileHeight ?? 0)
        )
        gTileset.tileShape = .square
        gTileset.tileSize = tileSize
        
        for tilesetRef in map.tilesets {
            guard let firstGID = tilesetRef.firstGID,
                  let source = tilesetRef.source else { return nil }
            let tilesetFile = [filePath, source].joined(separator: "/")
            
            
            guard FileAccess.fileExists(path: tilesetFile) else {
                GD.pushError("[] Import file \(tilesetFile) not found!")
                return nil//.errFileNotFound
            }
            guard let tilesetXml = try? XML.parse(tilesetFile, with: XMLParser()) else {
                return nil//.errBug
            }
            guard let tiledTileset = try? Tiled.TileSet(from: tilesetXml.root) else {
                return nil
            }
            
            var pathComponents = tilesetFile.components(separatedBy: "/")
            pathComponents.removeLast()
            let tilesetDir = pathComponents.joined(separator: "/")
            
            guard let imageSource = tiledTileset.image?.source else {
                GD.print("ERROR IMG SOURCE"); return nil
            }
            
            let imageFile = [tilesetDir, imageSource].joined(separator: "/")
//            let imageName = imageFile.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
            let tilesetName = tilesetFile.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
            
            let atlasSource = TileSetAtlasSource()
            atlasSource.margins = Vector2i(x: tiledTileset.margin, y: tiledTileset.margin)
            atlasSource.separation = Vector2i(x: tiledTileset.spacing, y: tiledTileset.spacing)
            atlasSource.texture = ResourceLoader.load(path: imageFile) as? Texture2D
            atlasSource.resourceName = tilesetName //imageFile.components(separatedBy: "/").last ?? ""
            GD.print("ATLAS RESOURCE NAME: \(atlasSource.resourceName)")
            let sourceId = gTileset.addSource(atlasSource)
//            let sourceId = gTileset.addSource(atlasSource, atlasSourceIdOverride: Int32(firstGID) ?? 0)
            
            for property in tiledTileset.properties {
                if property.name.hasPrefix("collision_layer_") {
                    if let layerIndex = Int32(property.name.components(separatedBy: "_").last ?? "") {
                        gTileset.addPhysicsLayer(toPosition: layerIndex)
                        var layerMask: UInt32 = 0
                        for layer in property.value?.components(separatedBy: ",").compactMap { UInt32($0) } ?? [] {
                            layerMask |= 1 << (layer - 1)
                        }
                        gTileset.setPhysicsLayerCollisionLayer(layerIndex: layerIndex, layer: layerMask)
                    }
                }
            }
            
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
                let halfTile = tileSize / 2
                
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
        }
        return gTileset
    }
    
    static func createTileSet(_ tileset: Tiled.TileSet, sourceFile: String) -> TileSet? {
        let gTileset = TileSet()
        gTileset.resourceName = tileset.name ?? ""
        
        gTileset.setupLocalToScene() // save .res from separate importer and load as resource?
        
        let tileSize = Vector2i(
            x: Int32(tileset.tileWidth ?? 0),
            y: Int32(tileset.tileHeight ?? 0)
        )
        
        gTileset.tileShape = .square
        gTileset.tileSize = tileSize
        
        var pathComponents = sourceFile.components(separatedBy: "/")
        pathComponents.removeLast()
        let tilesetDir = pathComponents.joined(separator: "/")
        
        guard let imageSource = tileset.image?.source else {
            GD.print("ERROR IMG SOURCE"); return nil
        }
        
        let imageFile = [tilesetDir, imageSource].joined(separator: "/")
        
        let atlasSource = TileSetAtlasSource()
        atlasSource.margins = Vector2i(x: tileset.margin, y: tileset.margin)
        atlasSource.separation = Vector2i(x: tileset.spacing, y: tileset.spacing)
        atlasSource.texture = ResourceLoader.load(path: imageFile) as? Texture2D
        atlasSource.resourceName = imageFile.components(separatedBy: "/").last ?? ""
        let sourceId = gTileset.addSource(atlasSource)
        
        gTileset.addPhysicsLayer(toPosition: 0)
        gTileset.setPhysicsLayerCollisionLayer(layerIndex: 0, layer: 0b0001)
        
        // create tiles
        let columns = tileset.columns ?? 0
        for tile in tileset.tiles {
            let atlasCoords = Vector2i(
                x: Int32(tile.id % columns),
                y: Int32(tile.id / columns))
            atlasSource.createTile(atlasCoords: atlasCoords)
            
            guard let tileData = atlasSource.getTileData(atlasCoords: atlasCoords, alternativeTile: 0) else {
                GD.print("ERROR GETTING TILE DATA"); break
            }
            let halfTile = tileSize / 2
            
            if let objectGroup = tile.objectGroup {
                for object in objectGroup.objects {
                    if let polygon = object.polygon {
                        let origin = Vector2i(x: Int32(object.x), y: Int32(object.y))
                        let array = PackedVector2Array()
                        for point in polygon.points {
                            array.append(value: Vector2(
                                x: origin.x + Int32(point.x) - halfTile.x,
                                y: origin.y + Int32(point.y) - halfTile.y
                            ))
                        }
                        tileData.addCollisionPolygon(layerId: 0)
                        tileData.setCollisionPolygonPoints(layerId: 0, polygonIndex: 0, polygon: array)
                    } else { // rectangle
                        let origin = Vector2i(x: Int32(object.x) - tileSize.x >> 1, y: Int32(object.y) - tileSize.y >> 1)
                        let array = PackedVector2Array()
                        array.append(value: Vector2(x: origin.x, y: origin.y))
                        array.append(value: Vector2(x: origin.x + object.width, y: origin.y))
                        array.append(value: Vector2(x: origin.x + object.width, y: origin.y + object.height))
                        array.append(value: Vector2(x: origin.x, y: origin.y + object.height))
                        tileData.addCollisionPolygon(layerId: 0)
                        tileData.setCollisionPolygonPoints(layerId: 0, polygonIndex: 0, polygon: array)
                    }
                }
            }
        }
        return gTileset
    }
}
