import SwiftGodot
import Foundation

fileprivate extension Node {
    func setOwnerRecursive(of node: Node?) {
        if let node {
            if node.owner == nil {
                node.owner = self
            }
            for child in node.getChildren() {
                self.setOwnerRecursive(of: child)
            }
        }
    }
}

@Godot(.tool)
class TileMapImporter: RefCounted, VerboseLogger {
    
    let objectsPath = "res://objects/"

    var sourceFile = ""
    var tilesetResourcePath = ""
    var isInfinite = false
    var verbose = false

    var currentFile: File?
    var currentTileset: TileSet?
    var gidToNameDict: [UInt32: String] = [:]
    var tilesetGIDs: [UInt32] = []

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
        currentTileset = nil
        gidToNameDict.removeAll()
        tilesetGIDs.removeAll()
        return Int(error.rawValue)
    }
    
    @discardableResult
    private func `import`(
        sourceFile: String,
        savePath: String,
        options: VariantDictionary
    ) -> GodotError {
        self.startTime = Time.getTicksMsec()
        self.sourceFile = sourceFile
        tilesetResourcePath = options["tileset_resource"]?.to() ?? ""
        verbose = options["verbose"]?.to() ?? false

        logVerbose("Importing tile map: \"\(sourceFile)\"")
        do {
            let file = File(path: sourceFile)
            currentFile = file
            let xml = try XML.parse(file.path, with: XMLParser())
            let map = try Tiled.TileMap(from: xml.root)
            guard map.orientation == .orthogonal else {
                logError("Unsupported map orientation: \(map.orientation)")
                return .errUnavailable
            }
            isInfinite = map.isInfinite
            guard !isInfinite else {
                logError("Infinite maps are not supported yet.")
                return .errUnavailable
            }

            try loadTilesetAndReferences(for: map)
            logVerbose("Creating map with TileSets: \(gidToNameDict)", level: 1)
            
            let root = try createTileMap(from: map)
            root.setName(file.name)
            
            let scene = PackedScene()
            let error = scene.pack(path: root)
            guard error == .ok else {
                logError("Failed to pack scene '\(root.name)'")
                throw error
            }
            try File(path: "\(savePath).tscn").saveResource(scene)
            logVerbose("Successfully imported '\(sourceFile)'.", level: 1)
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

    func loadTilesetAndReferences(for map: Tiled.TileMap) throws(ImportError) {
        let tilesetResourceFile = File(path: tilesetResourcePath)
        let tileset: TileSet
        do {
            tileset = try tilesetResourceFile.loadResource(ofType: TileSet.self)
        } catch {
            throw .fileError(error)
        }
        for tilesetRef in map.tilesets {
            if let gid = tilesetRef.firstGID.flatMap({ UInt32($0) }) {
                let file = File(path: tilesetRef.source ?? "")
                if tileset.getSourceId(named: file.name) < 0 {
                    throw .tileSetNotFound(file.name)
                }
                gidToNameDict[gid] = file.name
                tilesetGIDs.append(gid)
            }
        }
        currentTileset = tileset
    }

    func createTileMap(from map: Tiled.TileMap) throws -> Node2D {
        let root = Node2D()
        for layer in map.layers {
            root.addChild(node: try transformLayer(layer))
        }
        for layer in map.imageLayers {
            root.addChild(node: try transformImageLayer(layer))
        }
        for group in map.groups {
            root.addChild(node: try transformGroup(group))
        }
        for group in map.objectGroups {
            root.addChild(node: try transformObjectGroup(group))
        }
        for property in map.properties {
            root.setMeta(name: property.name, value: property.value)
        }
        for child in root.getChildren() {
            root.setOwnerRecursive(of: child)
        }
        return root
    }
    
    func transformLayer(_ layer: Tiled.Layer) throws(ImportError) -> Node2D {
        let tileset = try currentTileset ??? ImportError.fatal
        let tilemap = TileMapLayer()
        tilemap.setName(layer.name)
        tilemap.tileSet = tileset
        tilemap.position.x = Float(layer.offsetX)
        tilemap.position.y = Float(layer.offsetY)
        tilemap.visible = layer.isVisible
        tilemap.modulate = Color(r: 1, g: 1, b: 1, a: Float(layer.opacity))
        if let colorString = layer.tintColor, let color = parseHexColor(colorString, format: .argb) {
            tilemap.selfModulate = Color(r: color.r, g: color.g, b: color.b, a: color.a)
        }

        guard let data = layer.data else {
            throw .layerData(.notFound)
        }
        guard data.encoding == .csv else {
            throw .layerData(.formatNotSupported(data.encoding?.rawValue ?? "unknown"))
        }
        guard let text = data.text, !text.isEmpty else {
            throw .layerData(.empty)
        }
        let cellArray = text
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .components(separatedBy: ",")
            .compactMap { UInt32($0) }
        for idx in 0..<cellArray.count  {
            let cellValue = cellArray[idx]
            if cellValue == 0 {
                continue
            }
            let trueGID: UInt32 = UInt32(cellValue) & 0x0FFF_FFFF
            let flipBits: UInt32 = UInt32(cellValue) & 0xF000_0000
            let flipHorizontally = flipBits & 1 << 31 != 0 ? TileSetAtlasSource.transformFlipH : 0
            let flipVertically = flipBits & 1 << 30 != 0 ? TileSetAtlasSource.transformFlipV : 0
            let flipDiagonally = flipBits & 1 << 29 != 0 ? TileSetAtlasSource.transformTranspose : 0
            let altFlags = Int32(flipHorizontally | flipVertically | flipDiagonally)
            
            let tilesetGID = tilesetGIDs.filter { $0 <= trueGID }.max() ?? 0
            let tileIndex = trueGID - tilesetGID
            
            let resourceName = gidToNameDict[tilesetGID] ?? ""
            let sourceID = tileset.getSourceId(named: resourceName)
            let tilesetColumns = tileset.getColumnCount(sourceId: sourceID)
            
            let mapCoords = Vector2i(
                x: Int32(idx) % layer.width,
                y: Int32(idx) / layer.width)
            let tileCoords = Vector2i(
                x: Int32(tileIndex) % tilesetColumns,
                y: Int32(tileIndex) / tilesetColumns
            )
            tilemap.setCell(coords: mapCoords, sourceId: sourceID, atlasCoords: tileCoords, alternativeTile: altFlags)
        }
        let properties = parseProperties(layer.properties)
        if let zIndex = properties["z_index"] as? Int32 {
            tilemap.zIndex = zIndex
        }
        for property in layer.properties {
            tilemap.setMeta(name: property.name, value: property.value)
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

    func transformImageLayer(_ layer: Tiled.ImageLayer) throws(ImportError) -> Node2D {
        let file = try currentFile ??? ImportError.fatal
        let sprite = Sprite2D()
        sprite.setName(layer.name)
        sprite.centered = false
        sprite.position = Vector2(x: layer.offsetX, y: layer.offsetY)
        sprite.visible = layer.isVisible
        sprite.modulate = Color(r: 1, g: 1, b: 1, a: Float(layer.opacity))
        if let colorString = layer.tintColor, let color = parseHexColor(colorString, format: .argb) {
            sprite.selfModulate = Color(r: color.r, g: color.g, b: color.b, a: color.a)
        }
        guard let sourcePath = layer.image?.source else {
            logWarning("<\(file.name)> Missing image source path for image layer '\(layer.name)'.")
            return sprite
        }
        do {
            sprite.texture = try File(path: "\(file.directory)/\(sourcePath)").loadResource(ofType: Texture2D.self)
        } catch {
            throw .fileError(error)
        }
        if layer.repeatX != 0 || layer.repeatY != 0 {
            sprite.textureRepeat = .enabled
        }
        for property in layer.properties {
            sprite.setMeta(name: property.name, value: property.value)
        }
        return sprite
    }
    
    func transformGroup(_ group: Tiled.Group) throws -> Node2D {
        let node = Node2D()
        node.setName(group.name)
        node.position.x = Float(group.offsetX)
        node.position.y = Float(group.offsetY)
        node.visible = group.isVisible
        node.modulate = Color(r: 1, g: 1, b: 1, a: Float(group.opacity))
        if let colorString = group.tintColor, let color = parseHexColor(colorString, format: .argb) {
            node.selfModulate = Color(r: color.r, g: color.g, b: color.b, a: color.a)
        }
        // TODO: handle parallax
        for layer in group.layers {
            node.addChild(node: try transformLayer(layer))
        }
        for imageLayer in group.imageLayers {
            node.addChild(node: try transformImageLayer(imageLayer))
        }
        for objectGroup in group.objectGroups {
            node.addChild(node: try transformObjectGroup(objectGroup))
        }
        for subgroup in group.groups {
            node.addChild(node: try transformGroup(subgroup))
        }
        for property in group.properties {
            node.setMeta(name: property.name, value: property.value)
        }
        return node
    }
    
    func transformObjectGroup(_ objectGroup: Tiled.ObjectGroup) throws -> Node2D {
        let node = Node2D()
        node.setName(objectGroup.name)
        node.position.x = Float(objectGroup.offsetX)
        node.position.y = Float(objectGroup.offsetY)
        node.visible = objectGroup.isVisible
        node.modulate = Color(r: 1, g: 1, b: 1, a: Float(objectGroup.opacity))
        if let colorString = objectGroup.tintColor, let color = parseHexColor(colorString, format: .argb) {
            node.selfModulate = Color(r: color.r, g: color.g, b: color.b, a: color.a)
        }
        // TODO: handle parallax
        // TODO: handle draw order
        for object in objectGroup.objects {
            node.addChild(node: try transformObject(object))
        }
        for property in objectGroup.properties {
            node.setMeta(name: property.name, value: property.value)
        }
        return node
    }
    
    func transformObject(_ object: Tiled.Object) throws(ImportError) -> Node2D {
        let node: Node2D = if !object.type.isEmpty, let overrideObject = instantiate(object) {
            overrideObject
        } else {
            Node2D()
        }
        if let gid = object.gid { // object is a tile
            guard let currentTileset else { throw .fatal }

            let trueGID: UInt32 = UInt32(gid) & 0x0FFF_FFFF
            let flipBits: UInt32 = UInt32(gid) & 0xF000_0000
            let flipHorizontally = flipBits & 1 << 31 != 0
            let flipVertically = flipBits & 1 << 30 != 0
            
            let tilesetGID = tilesetGIDs.filter { $0 <= trueGID }.max() ?? 0
            let atlasName = gidToNameDict[UInt32(tilesetGID)] ?? ""
            guard let atlas = currentTileset.getSource(named: atlasName) else {
                throw .tileSetNotFound(atlasName)
            }
            
            let tileIndex = trueGID - tilesetGID
            
            let sourceID = currentTileset.getSourceId(named: atlasName)
            let tilesetColumns = currentTileset.getColumnCount(sourceId: sourceID)
            let tileCoords = Vector2i(
                x: Int32(tileIndex) % tilesetColumns,
                y: Int32(tileIndex) / tilesetColumns)
            let texRegion = atlas.getTileTextureRegion(atlasCoords: tileCoords)
            
            let sprite = Sprite2D()
            sprite.setName("Sprite2D")
            sprite.texture = atlas.texture
            sprite.regionEnabled = true
            sprite.regionRect = Rect2(from: texRegion)
            sprite.offset.x = Float(currentTileset.tileSize.x >> 1)
            sprite.offset.y = Float(currentTileset.tileSize.y >> 1)
            sprite.flipH = flipHorizontally
            sprite.flipV = flipVertically
            sprite.rotation = object.rotation * .pi / 180
            node.addChild(node: sprite)
        } else if let polygon = object.polygon {
            let body = parsePolygon(polygon, from: object)
            node.addChild(node: body)
        } else if let _ = object.text {
            logWarning("Text objects are not supported yet.")
        } else if let _ = object.template {
            logWarning("Templates are not supported yet.")
        } else if object.isPoint {
            // do nothing
        } else if object.isEllipse {
            logWarning("Ellipses are not supported yet.")
        } else { // treat as a rectangle
            let body = parseRectangle(from: object)
            node.addChild(node: body)
        }
        node.setName("\(object.name)-\(object.id)")
        node.position = Vector2(x: object.x, y: object.y)
        node.visible = object.isVisible
        for property in object.properties {
            node.setMeta(name: property.name, value: property.value)
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
        collision.setName("CollisionPolygon2D")
        let array = PackedVector2Array()
        for point in polygon.points {
            array.append(Vector2(x: point.x, y: point.y))
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
        collision.setName("CollisionShape2D")
        collision.shape = shape
        collision.position = Vector2(x: object.width * 0.5, y: object.height * 0.5)
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
            case "int": Int32(property.value ?? "0") as Any
            case "float": Float(property.value ?? "0") as Any
            case "bool": Bool(property.value ?? "false") as Any
            case "color": String(property.value ?? "#00000000")
            case "file": String(property.value ?? ".")
            default: String(property.value ?? "")
            }
            properties[property.name] = value
        }
        return properties
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

