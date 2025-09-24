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
    
    static func parseTileSets(map: Tiled.TileMap, sourceFile: String) {
        var filePathComponents = sourceFile.components(separatedBy: "/")
        filePathComponents.removeLast()
        let filePath = filePathComponents.joined(separator: "/")
        
        let gTileset = TileSet()
//        gTileset.resourceName = tileset.name ?? ""
        gTileset.setupLocalToScene() // save .res from separate importer and load as resource?
        gTileset.tileShape = .square
        
        gTileset.addPhysicsLayer(toPosition: 0)
        gTileset.setPhysicsLayerCollisionLayer(layerIndex: 0, layer: 0b0001)
        
        for tilesetRef in map.tilesets {
            guard let firstGID = Int32(tilesetRef.firstGID ?? ""), let source = tilesetRef.source else { break }
            
            let tilesetFile = [filePath, source].joined(separator: "/")
            
            guard FileAccess.fileExists(path: tilesetFile) else {
                return // err
            }
            guard let tilesetXml = XML.parse(tilesetFile, with: XMLParser()) else {
                return //.errBug
            }
            guard let tileset = try? Tiled.TileSet(from: tilesetXml.root) else {
                return // err
            }
            
            let tileSize = Vector2i(
                x: Int32(tileset.tileWidth ?? 0),
                y: Int32(tileset.tileHeight ?? 0)
            )
            gTileset.tileSize = tileSize
            
            var pathComponents = sourceFile.components(separatedBy: "/")
            pathComponents.removeLast()
            let tilesetDir = pathComponents.joined(separator: "/")
            guard let imageSource = tileset.image?.source else {
                GD.print("ERROR IMG SOURCE"); return // nil
            }
            let imageFile = [tilesetDir, imageSource].joined(separator: "/")
            
            let atlasSource = TileSetAtlasSource()
            atlasSource.resourceName = imageFile.components(separatedBy: "/").last ?? ""
            atlasSource.texture = ResourceLoader.load(path: imageFile) as? Texture2D
            atlasSource.margins = Vector2i(x: tileset.margin, y: tileset.margin)
            atlasSource.separation = Vector2i(x: tileset.spacing, y: tileset.spacing)
            
            gTileset.addSource(atlasSource, atlasSourceIdOverride: firstGID)
            
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
        }
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
