import SwiftGodot

class TileSetImporter {
    
    func importTileSet(tilesetFile: String) -> GodotError {
        guard FileAccess.fileExists(path: tilesetFile) else {
            return .errFileNotFound
        }
        
//        let outputDir = "res://output"
//        if !DirAccess.dirExistsAbsolute(path: outputDir) {
//            DirAccess.makeDirRecursiveAbsolute(path: outputDir)
//        }
//        let saveFile = "tileset_test.tres"
//        let outputFile = [outputDir, saveFile].joined(separator: "/")
//        let err = ResourceSaver.save(resource: gTileset, path: outputFile)
//        if err != .ok {
//            GD.print("ERROR SAVING RESOURCE: \(err)")
//        }
        return .ok
    }
    
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
        
        // continue from here
//        for tilesetRef in map.tilesets {
        if let tilesetRef = map.tilesets.first {
            guard let firstGID = tilesetRef.firstGID,
                  let source = tilesetRef.source else { return nil }
            let tilesetFile = [filePath, source].joined(separator: "/")
            
            
            guard FileAccess.fileExists(path: tilesetFile) else {
                GD.pushError("[] Import file \(tilesetFile) not found!")
                return nil//.errFileNotFound
            }
            guard let tilesetXml = XML.parse(tilesetFile, with: XMLParser()) else {
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
            
            let atlasSource = TileSetAtlasSource()
            atlasSource.margins = Vector2i(x: tiledTileset.margin, y: tiledTileset.margin)
            atlasSource.separation = Vector2i(x: tiledTileset.spacing, y: tiledTileset.spacing)
            atlasSource.texture = ResourceLoader.load(path: imageFile) as? Texture2D
            atlasSource.resourceName = imageFile.components(separatedBy: "/").last ?? ""
            let sourceId = gTileset.addSource(atlasSource)
            
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
            
            // create tiles
            let columns = tiledTileset.columns ?? 0
            for tile in tiledTileset.tiles {
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
                            let origin = Vector2i(x: object.x, y: object.y)
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
                            let origin = Vector2i(x: object.x - tileSize.x >> 1, y: object.y - tileSize.y >> 1)
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
        }
        return gTileset
    }
    
    static func parseTileSets2(map: Tiled.TileMap, sourceFile: String) -> TileSet? {
        var filePathComponents = sourceFile.components(separatedBy: "/")
        filePathComponents.removeLast()
        let filePath = filePathComponents.joined(separator: "/")
        
        let gTileset = TileSet()
        gTileset.resourceName = "test-tileset"//tileset.name ?? ""
        gTileset.setupLocalToScene() // save .res from separate importer and load as resource?
        gTileset.tileShape = .square
        
        gTileset.addPhysicsLayer(toPosition: 0)
        gTileset.setPhysicsLayerCollisionLayer(layerIndex: 0, layer: 0b0001)
        
        
        
        guard let tilesetRef = map.tilesets.first else { return nil }
        guard let firstGID = tilesetRef.firstGID,
              let source = tilesetRef.source else { return nil }
        let tilesetFile = [filePath, source].joined(separator: "/")
        
        
        var pathComponents = sourceFile.components(separatedBy: "/")
        pathComponents.removeLast()
        let tilesetDir = pathComponents.joined(separator: "/")
        guard FileAccess.fileExists(path: tilesetFile) else {
            return nil // err
        }
        guard let tilesetXml = XML.parse(tilesetFile, with: XMLParser()) else {
            return nil //.errBug
        }
        guard let tileset = try? Tiled.TileSet(from: tilesetXml.root) else {
            return nil // err
        }
        
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
        
        
        
//        for tilesetRef in map.tilesets {
//            guard let firstGID = Int32(tilesetRef.firstGID ?? ""), let source = tilesetRef.source else { break }
//            
//            let tilesetFile = [filePath, source].joined(separator: "/")
//            
//            guard FileAccess.fileExists(path: tilesetFile) else {
//                return nil // err
//            }
//            guard let tilesetXml = XML.parse(tilesetFile, with: XMLParser()) else {
//                return nil //.errBug
//            }
//            guard let tileset = try? Tiled.TileSet(from: tilesetXml.root) else {
//                return nil // err
//            }
//            
//            let tileSize = Vector2i(
//                x: Int32(tileset.tileWidth ?? 0),
//                y: Int32(tileset.tileHeight ?? 0)
//            )
//            gTileset.tileSize = tileSize
//            
//            var pathComponents = sourceFile.components(separatedBy: "/")
//            pathComponents.removeLast()
//            let tilesetDir = pathComponents.joined(separator: "/")
//            guard let imageSource = tileset.image?.source else {
//                GD.print("ERROR IMG SOURCE"); return nil
//            }
//            let imageFile = [tilesetDir, imageSource].joined(separator: "/")
//            
//            let atlasSource = TileSetAtlasSource()
//            atlasSource.resourceName = imageFile.components(separatedBy: "/").last ?? ""
//            atlasSource.texture = ResourceLoader.load(path: imageFile) as? Texture2D
//            atlasSource.margins = Vector2i(x: tileset.margin, y: tileset.margin)
//            atlasSource.separation = Vector2i(x: tileset.spacing, y: tileset.spacing)
//            
////            gTileset.addSource(atlasSource, atlasSourceIdOverride: firstGID)
////            gTileset.addSource(atlasSource)
//            
//            // create tiles
////            let columns = tileset.columns ?? 0
////            for tile in tileset.tiles {
////                let atlasCoords = Vector2i(
////                    x: Int32(tile.id % columns),
////                    y: Int32(tile.id / columns))
////                atlasSource.createTile(atlasCoords: atlasCoords)
////                
////                guard let tileData = atlasSource.getTileData(atlasCoords: atlasCoords, alternativeTile: 0) else {
////                    GD.print("ERROR GETTING TILE DATA"); break
////                }
////                let halfTile = tileSize / 2
////                
////                if let objectGroup = tile.objectGroup {
////                    for object in objectGroup.objects {
////                        if let polygon = object.polygon {
////                            let origin = Vector2i(x: object.x, y: object.y)
////                            let array = PackedVector2Array()
////                            for point in polygon.points {
////                                array.append(value: Vector2(
////                                    x: origin.x + Int32(point.x) - halfTile.x,
////                                    y: origin.y + Int32(point.y) - halfTile.y
////                                ))
////                            }
////                            tileData.addCollisionPolygon(layerId: 0)
////                            tileData.setCollisionPolygonPoints(layerId: 0, polygonIndex: 0, polygon: array)
////                        } else { // rectangle
////                            let origin = Vector2i(x: object.x - tileSize.x >> 1, y: object.y - tileSize.y >> 1)
////                            let array = PackedVector2Array()
////                            array.append(value: Vector2(x: origin.x, y: origin.y))
////                            array.append(value: Vector2(x: origin.x + object.width, y: origin.y))
////                            array.append(value: Vector2(x: origin.x + object.width, y: origin.y + object.height))
////                            array.append(value: Vector2(x: origin.x, y: origin.y + object.height))
////                            tileData.addCollisionPolygon(layerId: 0)
////                            tileData.setCollisionPolygonPoints(layerId: 0, polygonIndex: 0, polygon: array)
////                        }
////                    }
////                }
////            }
//        }
        
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
                        let origin = Vector2i(x: object.x, y: object.y)
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
                        let origin = Vector2i(x: object.x - tileSize.x >> 1, y: object.y - tileSize.y >> 1)
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
