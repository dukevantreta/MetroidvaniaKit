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
            if let tileLayer = layer as? Tiled.TileLayer {
                root.addChild(node: try transformTileLayer(tileLayer))
            } else if let imageLayer = layer as? Tiled.ImageLayer {
                root.addChild(node: try transformImageLayer(imageLayer))
            } else if let group = layer as? Tiled.Group {
                root.addChild(node: try transformGroup(group))
            } else if let objectGroup = layer as? Tiled.ObjectGroup {
                root.addChild(node: try transformObjectGroup(objectGroup))
            }
        }
        for property in map.properties {
            root.setMeta(name: property.name, value: property.value)
        }
        for child in root.getChildren() {
            root.setOwnerRecursive(of: child)
        }
        return root
    }
    
    func transformTileLayer(_ layer: Tiled.TileLayer) throws(ImportError) -> Node2D {
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
            let atlasCoords = Vector2i(
                x: Int32(tileIndex) % tilesetColumns,
                y: Int32(tileIndex) / tilesetColumns
            )
            
            // Add animators to tilemap. This is sketchy as f***, but it works
            if
                let source = currentTileset?.getSource(named: resourceName),
                let tileData = source.getTileData(atlasCoords: atlasCoords, alternativeTile: altFlags),
                tileData.hasCustomData(layerName: "animation"),
                let variant = tileData.getCustomData(layerName: "animation"),
                let text = variant.to(String.self),
                !text.isEmpty
            {
                logVerbose("Processing tile \(mapCoords) animation data: \(text)", level: 2)
                let animator = TileAnimator()
                animator.setName("TileAnimator-\(mapCoords.x),\(mapCoords.y)")
                animator.mapCoords = mapCoords
                animator.sourceID = sourceID
                animator.altFlags = altFlags

                var framesText = text
                if framesText.first == "?" {
                    framesText.removeFirst()
                    animator.isRandom = true
                }

                let frames = framesText.split(separator: "-")
                for frame in frames {
                    let split = frame.split(separator: ",")
                    let frameID = Int32(split[0]) ?? 0
                    let duration = Int32(split[1]) ?? 0
                    let frameCoords = Vector2i(
                        x: frameID % tilesetColumns, 
                        y: frameID / tilesetColumns)
                    animator.frameCoords.append(frameCoords)
                    animator.frameDurations.append(Double(duration) / 1000)
                }
                animator.tilemap = tilemap
                tilemap.addChild(node: animator)
            }
            tilemap.setCell(coords: mapCoords, sourceId: sourceID, atlasCoords: atlasCoords, alternativeTile: altFlags)
        }
        parseProperties(layer.properties, for: tilemap)
        
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
        parseProperties(layer.properties, for: sprite)
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
            if let tileLayer = layer as? Tiled.TileLayer {
                node.addChild(node: try transformTileLayer(tileLayer))
            } else if let imageLayer = layer as? Tiled.ImageLayer {
                node.addChild(node: try transformImageLayer(imageLayer))
            } else if let group = layer as? Tiled.Group {
                node.addChild(node: try transformGroup(group))
            } else if let objectGroup = layer as? Tiled.ObjectGroup {
                node.addChild(node: try transformObjectGroup(objectGroup))
            }
        }
        parseProperties(group.properties, for: node)
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
        parseProperties(objectGroup.properties, for: node)
        return node
    }
    
    func transformObject(_ object: Tiled.Object) throws(ImportError) -> Node2D {
        var node: Node2D
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
            node = sprite
        } else if let polygon = object.polygon {
            node = parsePolygon(polygon, from: object)
        } else if let polyline = object.polyline {
            node = parsePolyline(polyline, from: object)
        } else if let _ = object.text {
            logWarning("Text objects are not supported yet.")
            node = Node2D()
        } else if let _ = object.template {
            logWarning("Templates are not supported yet.")
            node = Node2D()
        } else if object.isPoint {
            node = Node2D()
        } else if object.isEllipse {
            logWarning("Ellipses are not supported yet.")
            node = Node2D()
        } else { // treat as a rectangle
            node = parseRectangle(from: object)
        }
        if !object.type.isEmpty, let overrideObject = instantiate(object) {
            overrideObject.addChild(node: node)
            node = overrideObject
        }
        node.setName("\(object.name)-\(object.id)")
        node.position = Vector2(x: object.x, y: object.y)
        node.visible = object.isVisible
        parseProperties(object.properties, for: node)
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
        return body
    }

    // TODO: collision lines (use SegmentShape2D)
    func parsePolyline(_ polyline: Tiled.Polyline, from object: Tiled.Object) -> Node2D {
        let type = object.type.lowercased()
        let line = Line2D()
        let array = PackedVector2Array()
        for point in polyline.points {
            array.append(Vector2(x: point.x, y: point.y))
        }
        line.points = array
        return line
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
        return body
    }

    func parseProperties(_ properties: [Tiled.Property], for node: Node2D) {
        let propDict = properties.reduce(into: [String: Tiled.Property]()) { 
            node.setMeta(name: $1.name, value: $1.value)
            $0[$1.name] = $1 
        }
        if let group = propDict["group"]?.value {
            node.addToGroup(StringName(group), persistent: true)
        }
        if let z = propDict["z_index"]?.value, let zIndex = Int32(z) {
            node.zIndex = zIndex
        }
        if let layer = propDict["collision_layer"]?.value, let collisionLayer = Int32(layer) {
            if let body = node as? CollisionObject2D {
                body.collisionLayer = 0
                body.setCollisionLayerValue(layerNumber: collisionLayer, value: true)
            }
        }
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

