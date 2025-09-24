import SwiftGodot
import Dispatch
import Foundation

@Godot(.tool)
class TileMapImporter: Node {
    
//    @Callable
//    func importResource(
//        sourceFile: String,
//        savePath: String,
//        options: GDictionary,
//        platformVariants: VariantCollection<String>,
//        genFiles: VariantCollection<String>
//    ) -> Int {
//        DispatchQueue.main.async {
//            self.`import`(sourceFile: sourceFile, savePath: savePath, options: options)
//        }
//        return 0
//    }
    
    @discardableResult
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
            let map = try Tiled.TileMap(from: xml.root)
            guard map.orientation == .orthogonal else {
                return .errBug //
            }
            let godotTileset = try TileSetImporter.loadTileSet()
            let tilemap = try createTileMap(map: map, using: godotTileset)
            
//            let filename = sourceFile.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
            let filename = try getFileName(from: sourceFile)
            tilemap.name = StringName(filename)
            
            let scene = PackedScene()
            scene.pack(path: tilemap)
            try saveResource(scene, path: "\(savePath).tscn")
            log("Successfully imported '\(sourceFile)'.")
            return .ok
        } catch let error as XML.ParseError {
            logError("Failed to parse .tmx file: \(error)")
            return .errFileCantRead
        } catch let error as Tiled.ParseError {
            logError("Failed to parse tiled map data: \(error)")
            return .errInvalidData
        } catch {
            logError("Failed to import '\(sourceFile)' with error: \(error)")
            return .errScriptFailed
        }
        return .ok
    }
    
    var currentTileset: TileSet? // find a better solution
    var localTilesetRefs: [Int32: String] = [:]
    
    func createTileMap(map: Tiled.TileMap, using tileset: TileSet) throws -> Node2D {
        currentTileset = tileset
        
        for tilesetRef in map.tilesets {
            if let gid = Int32(tilesetRef.firstGID ?? "") {
                let name = tilesetRef.source?.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
                localTilesetRefs[gid] = name
            }
        }
        GD.print("TILESET DICT: \(localTilesetRefs)")
        
        let gids = map.tilesets.compactMap { Int32($0.firstGID ?? "") }
        
        let root = Node2D()
        
        // TODO: Flipped tiles bit shifting
        for layer in map.layers {
            let tilemap = TileMap()
            tilemap.setName(layer.name)
            tilemap.tileSet = tileset
            let cellArray = try layer.getTileData()
                .components(separatedBy: .whitespacesAndNewlines)
                .joined()
                .components(separatedBy: ",")
                .compactMap { Int32($0) }
            for idx in 0..<cellArray.count {
                let cellValue = cellArray[idx]
                if cellValue == 0 {
                    continue
                }
                
                let tilesetGID = gids.filter { $0 <= cellValue }.max() ?? 0
                let tileIndex = cellValue - tilesetGID
                
                let resourceName = localTilesetRefs[tilesetGID] ?? ""
                let sourceID = tileset.getSourceId(named: resourceName)
                let tilesetColumns = tileset.getColumnCount(sourceId: sourceID)
                
                let mapCoords = Vector2i(
                    x: Int32(idx % layer.width),
                    y: Int32(idx / layer.width))
                let tileCoords = Vector2i(
                    x: tileIndex % tilesetColumns,
                    y: tileIndex / tilesetColumns
                )
                tilemap.setCell(layer: 0, coords: mapCoords, sourceId: sourceID, atlasCoords: tileCoords, alternativeTile: 0)
            }
            root.addChild(node: tilemap)
        }
        for group in map.groups {
            root.addChild(node: transformGroup(group))
        }
        for group in map.objectGroups {
            root.addChild(node: transformObjectGroup(group))
        }
        for child in root.getChildren() {
            setOwner(root, to: child)
        }
        return root
    }
    
    func setOwner(_ owner: Node, to node: Node) {
        node.owner = owner
        for child in node.getChildren() {
            setOwner(owner, to: child)
        }
    }
    
    // Solve GIDs
    func transformLayer(_ layer: Tiled.Layer) throws -> Node2D {
        let tilemap = TileMap()
        tilemap.setName(layer.name)
//        tilemap.tileSet = tileset
        let cells = try layer.getTileData()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .components(separatedBy: ",")
            .compactMap { Int($0) }
//        for idx in 0..<cells.count {
//            let tileIndex = cells[idx] - (tilesetGID ?? 0)
//            if tileIndex < 0 {
//                continue
//            }
//            let mapCoords = Vector2i(
//                x: Int32(idx % layer.width),
//                y: Int32(idx / layer.width))
//            let tileCoords = Vector2i(
//                x: Int32(tileIndex % tilesetColumns),
//                y: Int32(tileIndex / tilesetColumns)
//            )
//            tilemap.setCell(layer: 0, coords: mapCoords, sourceId: tilesetSourceID, atlasCoords: tileCoords, alternativeTile: 0)
//        }
        return tilemap
    }
    
    func transformGroup(_ group: Tiled.Group) -> Node2D {
        let node = Node2D()
        node.name = StringName(group.name)
        node.position.x = Float(group.offsetX)
        node.position.y = Float(group.offsetY)
        node.visible = group.isVisible
        // TODO: layers
        for objectGroup in group.objectGroups {
            node.addChild(node: transformObjectGroup(objectGroup))
        }
        // TODO: image layers
        for subgroup in group.groups {
            node.addChild(node: transformGroup(subgroup))
        }
        return node
    }
    
    func transformObjectGroup(_ objectGroup: Tiled.ObjectGroup) -> Node2D {
        let node = Node2D()
        node.name = StringName(objectGroup.name)
        node.position.x = Float(objectGroup.offsetX)
        node.position.y = Float(objectGroup.offsetY)
        // TODO: handle parallax
        // TODO: handle draw order
        node.visible = objectGroup.isVisible
        // TODO: handle properties
//        node.modulate -> use this for opacity and tint?
        for object in objectGroup.objects {
            node.addChild(node: transformObject(object))
        }
        return node
    }
    
    func transformObject(_ object: Tiled.Object) -> Node2D {
        let node: Node2D
        
        if let gid = object.gid { // is tile
            let sprite = Sprite2D()
            node = sprite
            
            guard let currentTileset else { fatalError() }
            
            let gids: [Int32] = Array(localTilesetRefs.keys)
            let tilesetGID = gids.filter { $0 <= gid }.max() ?? 0
            
            let atlasName = localTilesetRefs[Int32(tilesetGID)] ?? ""
            guard let atlas = currentTileset.getSource(named: atlasName) as? TileSetAtlasSource else {
                GD.print("ERROR GETTING ATLAS SOURCE")
                return node
            }
            
            let tileIndex = Int32(gid) - tilesetGID
            
//            let tilesetColumns = currentTileset.getColumnCount(gid: tilesetGID)
            let sourceID = currentTileset.getSourceId(named: atlasName)
            let tilesetColumns = currentTileset.getColumnCount(sourceId: sourceID)
            let tileCoords = Vector2i(
                x: tileIndex % tilesetColumns,
                y: tileIndex / tilesetColumns)
            
            let texRegion = atlas.getTileTextureRegion(atlasCoords: tileCoords)
            
            sprite.texture = atlas.texture
            sprite.regionEnabled = true
            sprite.regionRect = Rect2(from: texRegion)
            
            sprite.offset.x = Float(currentTileset.tileSize.x >> 1)
            sprite.offset.y = Float(currentTileset.tileSize.y >> 1)
            
        } else if let polygon = object.polygon {
            let type = object.type.lowercased()
            node = if type == "area" || type == "area2d" {
                Area2D()
            } else {
                StaticBody2D()
            }
            let collision = CollisionPolygon2D()
            let array = PackedVector2Array()
            for point in polygon.points {
                array.append(value: Vector2(x: point.x, y: point.y))
            }
            collision.polygon = array
            node.addChild(node: collision)
//        } else if let text = object.text { // is text obj
//        } else if let template = object.template { // TODO
        } else if object.isPoint {
            node = Node2D()
//        } else if object.isEllipse {
        } else { // treat as a rectangle
            let type = object.type.lowercased()
            node = if type == "area" || type == "area2d" {
                Area2D()
            } else {
                StaticBody2D()
            }
            let shape = RectangleShape2D()
            shape.size = Vector2(x: object.width, y: object.height)
            let collision = CollisionShape2D()
            collision.shape = shape
            collision.position = Vector2(x: object.width >> 1, y: object.height >> 1)
            node.addChild(node: collision)
        }
        node.setName(object.name)
        node.position = Vector2(x: object.x, y: object.y)
        node.visible = object.isVisible
        return node
    }
    
//    func createTileMapUsingLayers(map: Tiled.TileMap, using tileset: TileSet) throws -> Node2D {
//        guard let source = tileset.getSource(sourceId: tileset.getSourceId(index: 0)) as? TileSetAtlasSource else {
//            throw ImportError.unknown // no source
//        }
//        let textureWidth = source.texture?.getWidth() ?? -1
//        let tilesetColumns = Int(textureWidth / tileset.tileSize.x)
//        let tilesetSourceID = tileset.getSourceId(index: 0)
//
//        let tilemap = TileMap()
//        tilemap.name = "<name>"
//        tilemap.tileSet = tileset
//        let tilesetGID = Int(map.tilesets.first?.firstGID ?? "0") ?? -99999
//
//        for layerIdx in 0..<map.layers.count {
//            let layer = map.layers[layerIdx]
//            tilemap.addLayer(toPosition: Int32(layerIdx))
//            let cellArray = try layer.getTileData()
//                .components(separatedBy: .whitespacesAndNewlines)
//                .joined()
//                .components(separatedBy: ",")
//                .compactMap { Int($0) }
//            for idx in 0..<cellArray.count {
//                let cellValue = cellArray[idx]
//                let tileIndex = cellValue - (tilesetGID ?? 0)
//                if tileIndex < 0 {
//                    continue
//                }
//                let mapCoords = Vector2i(
//                    x: Int32(idx % layer.width),
//                    y: Int32(idx / layer.width))
//                let tileCoords = Vector2i(
//                    x: Int32(tileIndex % tilesetColumns),
//                    y: Int32(tileIndex / tilesetColumns)
//                )
//                tilemap.setCell(layer: Int32(layerIdx), coords: mapCoords, sourceId: tilesetSourceID, atlasCoords: tileCoords, alternativeTile: 0)
//            }
//        }
//        let rootNode = Node2D()
//        rootNode.name = "root"
//        rootNode.addChild(node: tilemap)
//        tilemap.owner = rootNode
//        return rootNode
//    }
}
