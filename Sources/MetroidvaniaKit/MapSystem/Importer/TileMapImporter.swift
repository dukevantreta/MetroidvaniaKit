import SwiftGodot
import Dispatch
import Foundation

@Godot(.tool)
class TileMapImporter: Node {
    
    enum Error: Swift.Error {
        case missingTileSetSource(gid: String?)
    }
    
    let objectsPath = "res://objects/"
    
    var currentTileset: TileSet? // find a better solution
    var gidToNameDict: [UInt32: String] = [:]
    
    override func _enterTree() {
        self.name = "TMX Importer"
    }

    @Callable
    func importResource(
        sourceFile: String,
        savePath: String,
        options: GDictionary,
        platformVariants: VariantCollection<String>,
        genFiles: VariantCollection<String>
    ) -> Int {
        // DispatchQueue.main.async {
            // self.`import`(sourceFile: sourceFile, savePath: savePath, options: options)
        // }
        return Int(`import`(sourceFile: sourceFile, savePath: savePath, options: options).rawValue)
    }
    
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
            let file = try File(path: sourceFile)
            let xml = try XML.parse(file.path, with: XMLParser())
            let map = try Tiled.TileMap(from: xml.root)
            guard map.orientation == .orthogonal else {
                return .errBug //
            }
            
            let godotTileset = try TileSetImporter.touchTileSet(tileWidth: Int32(map.tileWidth), tileHeight: Int32(map.tileHeight))
            
            let tilesetImporter = TileSetImporter()
            for tilesetRef in map.tilesets {
                let tilesetSource = try tilesetRef.source ??? Error.missingTileSetSource(gid: tilesetRef.firstGID)
                let tilesetSourceFile = [file.directory, tilesetSource].joined(separator: "/")
                try tilesetImporter.importLazy(sourceFile: tilesetSourceFile, toTileSet: godotTileset)
            }
            
            let tilemap = try createTileMap(map: map, using: godotTileset)
            
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
    }
    
    // Flipped tiles are clunky to setup, better use manual flipping
    func createTileMap(map: Tiled.TileMap, using tileset: TileSet) throws -> Node2D {
        currentTileset = tileset
        
        for tilesetRef in map.tilesets {
            if let gid = UInt32(tilesetRef.firstGID ?? "") {
                let name = try getFileName(from: tilesetRef.source ?? "")
                gidToNameDict[gid] = name
            }
        }
        log("Creating map with TileSets: \(gidToNameDict)")
        
        let gids = map.tilesets.compactMap { UInt32($0.firstGID ?? "") }
        
        let root = Node2D()

        for layer in map.layers {
            root.addChild(node: try transformLayer(layer, tilesetGIDs: gids))
        }
        for group in map.groups {
            root.addChild(node: transformGroup(group))
        }
        for group in map.objectGroups {
            root.addChild(node: transformObjectGroup(group))
        }
        for property in map.properties {
            root.setMeta(name: StringName(property.name), value: Variant(property.value))
        }
        for child in root.getChildren() {
            setOwner(root, to: child)
        }
        return root
    }
    
    func setOwner(_ owner: Node, to node: Node?) {
        if let node {
            node.owner = owner
            for child in node.getChildren() {
                setOwner(owner, to: child)
            }
        }
    }
    
    // Solve GIDs
    func transformLayer(_ layer: Tiled.Layer, tilesetGIDs: [UInt32]) throws -> Node2D {
        let tileset = try currentTileset ??? ImportError.tileSetNotFound
        let tilemap = TileMapLayer()
        tilemap.setName(layer.name)
        tilemap.tileSet = tileset
        tilemap.modulate = Color(r: 1, g: 1, b: 1, a: Float(layer.opacity))
        if let colorString = layer.tintColor {
            if let color = parseHexColor(colorString) {
                tilemap.selfModulate = Color(r: color.r, g: color.g, b: color.b, a: color.a)
            }
        }
        tilemap.visible = layer.isVisible
        
        let cellArray = try layer.getTileData()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .components(separatedBy: ",")
            .compactMap { UInt32($0) }
        for idx in 0..<cellArray.count {
            let cellValue = cellArray[idx]
            if cellValue == 0 {
                continue
            }
            let trueGID: UInt32 = UInt32(cellValue) & 0x0FFF_FFFF
//                let flipBits: UInt32 = UInt32(cellValue) & 0xF000_0000
//                let flipHorizontally = flipBits & 1 << 31 != 0
//                let flipVertically = flipBits & 1 << 30 != 0
            
            let tilesetGID = tilesetGIDs.filter { $0 <= trueGID }.max() ?? 0
            let tileIndex = cellValue - tilesetGID
            
            let resourceName = gidToNameDict[tilesetGID] ?? ""
            let sourceID = tileset.getSourceId(named: resourceName)
            let tilesetColumns = tileset.getColumnCount(sourceId: sourceID)
            
            let mapCoords = Vector2i(
                x: Int32(idx) % layer.width,
                y: Int32(idx) / layer.width)
            let tileCoords = Vector2i(
                x: Int32(tileIndex % UInt32(tilesetColumns)),
                y: Int32(tileIndex / UInt32(tilesetColumns))
            )
            tilemap.setCell(coords: mapCoords, sourceId: sourceID, atlasCoords: tileCoords, alternativeTile: 0)
        }
        let properties = parseProperties(layer.properties)
        if let zIndex = properties["z_index"] as? Int32 {
            tilemap.zIndex = zIndex
        }
        for property in layer.properties {
            tilemap.setMeta(name: StringName(property.name), value: Variant(property.value))
        }
        
        // Handle parallax layer (this is broken)
//            if let xParallax = layer.parallaxX, let yParallax = layer.parallaxY, (xParallax != 1.0 || yParallax != 1.0) {
//                let parallax = Parallax2D()
//                parallax.name = StringName("Parallax2D")
//                parallax.scrollScale = Vector2(x: -xParallax, y: -yParallax)
////                parallax.repeatSize = Vector2(x: layer.width * TILE_SIZE, y: layer.height * TILE_SIZE)
//                parallax.repeatSize = Vector2(x: 25 * TILE_SIZE, y: 15 * TILE_SIZE)
//                parallax.followViewport = true
//                parallax.addChild(node: tilemap)
////                parallax.repeatTimes = 3
//                root.addChild(node: parallax)
//            } else {
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
        for property in objectGroup.properties {

        }
//        node.modulate -> use this for opacity and tint?
        for object in objectGroup.objects {
            node.addChild(node: transformObject(object))
        }
        return node
    }
    
    func transformObject(_ object: Tiled.Object) -> Node2D {
        let node: Node2D = if !object.type.isEmpty, let overrideObject = instantiate(object) {
            overrideObject
        } else {
            Node2D()
        }
        if let gid = object.gid { // is tile
            let trueGID: UInt32 = UInt32(gid) & 0x0FFF_FFFF
            let flipBits: UInt32 = UInt32(gid) & 0xF000_0000
            let flipHorizontally = flipBits & 1 << 31 != 0
            let flipVertically = flipBits & 1 << 30 != 0
            
            let sprite = Sprite2D()
            // sprite.name = StringName("Sprite2D")
            node.addChild(node: sprite)
            
            guard let currentTileset else { fatalError() }
            
            let gids: [UInt32] = Array(gidToNameDict.keys)
            let tilesetGID = gids.filter { $0 <= trueGID }.max() ?? 0
            
            let atlasName = gidToNameDict[UInt32(tilesetGID)] ?? ""
            guard let atlas = currentTileset.getSource(named: atlasName) as? TileSetAtlasSource else {
                GD.print("ERROR GETTING ATLAS SOURCE")
                return node
            }
            
            let tileIndex = trueGID - tilesetGID
            
            let sourceID = currentTileset.getSourceId(named: atlasName)
            let tilesetColumns = currentTileset.getColumnCount(sourceId: sourceID)
            let tileCoords = Vector2i(
                x: Int32(tileIndex % UInt32(tilesetColumns)),
                y: Int32(tileIndex / UInt32(tilesetColumns)))
            
            let texRegion = atlas.getTileTextureRegion(atlasCoords: tileCoords)
            
            sprite.texture = atlas.texture
            sprite.regionEnabled = true
            sprite.regionRect = Rect2(from: texRegion)
            
            sprite.offset.x = Float(currentTileset.tileSize.x >> 1)
            sprite.offset.y = Float(currentTileset.tileSize.y >> 1)
            
            sprite.flipH = flipHorizontally
            sprite.flipV = flipVertically
            
        } else if let polygon = object.polygon {
            let body = parsePolygon(polygon, from: object)
            node.addChild(node: body)
            
//        } else if let text = object.text { // is text obj
//        } else if let template = object.template { // TODO
        } else if object.isPoint {
//            node = Node2D()
//        } else if object.isEllipse {
        } else { // treat as a rectangle
            let body = parseRectangle(from: object)
            node.addChild(node: body)
        }
        node.setName(object.name.isEmpty ? "\(object.id)" : object.name)
        node.position = Vector2(x: object.x, y: object.y)
        node.visible = object.isVisible
        for property in object.properties {
            node.setMeta(name: StringName(property.name), value: Variant(property.value))
        }
        return node
    }
    
    func parsePolygon(_ polygon: Tiled.Polygon, from object: Tiled.Object) -> Node2D {
        let type = object.type.lowercased()
        let body: CollisionObject2D
        if type == "area" || type == "area2d" {
            body = Area2D()
            body.setName("Area2D")
        } else {
            body = StaticBody2D()
            body.setName("StaticBody2D")
        }
        let collision = CollisionPolygon2D()
        let array = PackedVector2Array()
        for point in polygon.points {
            array.append(value: Vector2(x: point.x, y: point.y))
        }
        collision.polygon = array
        body.addChild(node: collision)
        let properties = parseProperties(object.properties)
        if let layer = properties["collision_layer"] as? Int32 {
            body.collisionLayer = 0
            body.setCollisionLayerValue(layerNumber: layer, value: true)
        }
        return body
    }
    
    func parseRectangle(from object: Tiled.Object) -> Node2D {
        let type = object.type.lowercased()
        let body: CollisionObject2D
        if type == "area" || type == "area2d" {
            body = Area2D()
            body.setName("Area2D")
        } else {
            body = StaticBody2D()
            body.setName("StaticBody2D")
        }
        let shape = RectangleShape2D()
        shape.size = Vector2(x: object.width, y: object.height)
        let collision = CollisionShape2D()
        collision.shape = shape
        collision.position = Vector2(x: object.width >> 1, y: object.height >> 1)
        body.addChild(node: collision)
        let properties = parseProperties(object.properties)
        if let layer = properties["collision_layer"] as? Int32 {
            body.collisionLayer = 0
            body.setCollisionLayerValue(layerNumber: layer, value: true)
        }
        return body
    }
    
    func parseProperties(_ propertyArray: [Tiled.Property]) -> [String: Any] {
        var properties: [String: Any] = [:]
        for property in propertyArray {
            let value: Any = switch property.type {
            case "string": String(property.value ?? "")
            case "int": Int32(property.value ?? "0")
            case "float": Float(property.value ?? "0")
            case "bool": Bool(property.value ?? "false")
            case "color": String(property.value ?? "#00000000")
            case "file": String(property.value ?? ".")
            default: String(property.value ?? "")
            }
            properties[property.name] = value
        }
        return properties
    }
    
    func parseHexColor(_ hex: String) -> (r: Float, g: Float, b: Float, a: Float)? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        
        guard scanner.scanHexInt64(&hexNumber) else {
            return nil
        }
        
        let r = Float((hexNumber & 0x00FF0000) >> 16) / 255.0
        let g = Float((hexNumber & 0x0000FF00) >> 8) / 255.0
        let b = Float(hexNumber & 0x000000FF) / 255.0
        let a = hexString.count == 8 ? Float((hexNumber & 0xFF000000) >> 24) / 255.0 : 1.0
        
        return (r, g, b, a)
    }
    
    func instantiate(_ object: Tiled.Object) -> Node2D? {
        let path = "\(objectsPath)\(object.type).tscn"
        if
            FileAccess.fileExists(path: path),
            let scene = ResourceLoader.load(path: path) as? PackedScene,
            let node = scene.instantiate() as? Node2D
        {
            return node
        }
        return nil
    }
}

