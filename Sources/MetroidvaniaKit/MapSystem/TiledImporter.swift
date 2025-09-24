import SwiftGodot
import Dispatch

extension XML.Element: CustomStringConvertible {
    var description: String {
        "[XML] \(name) | has text: \(text?.isEmpty == false) | ATTR: \(attributes)"
    }
}

// print on console to help debug
func printTree(_ xml: XML.Element, level: Int) {
    var pad = ""
    for _ in 0..<level {
        pad += "    "
    }
    GD.print("\(pad)\(xml)")
    for child in xml.children {
        printTree(child, level: level + 1)
    }
}

enum ImportError: Error {
    case unknown
    case layerData(LayerDataErrorReason)
    case unhandledObject
    
    enum LayerDataErrorReason {
        case notFound
        case formatNotSupported(String)
        case empty
    }
}

@Godot(.tool)
class TiledImporter: EditorPlugin {
    
    // This piece works by manually adding the plugin node to the tree
//    var dock: Control?
//    
//    override func _enterTree() {
//        GD.print("PLUGIN entering tree")
//        let res: PackedScene? = GD.load(path: "res://addons/test/dock_test.tscn")
//        dock = res?.instantiate() as? Control
//        addControlToDock(slot: .leftUl, control: dock)
//    }
//    
//    override func _exitTree() {
//        GD.print("PLUGIN exiting tree")
//        removeControlFromDocks(control: dock)
//        dock?.queueFree()
//    }
    
    private var importPlugin: MapImportPlugin?
    
    override func _getPluginName() -> String {
        "Plugin Test Name !!!!!!"
    }
    
//    override func _enablePlugin() {
//        GD.print("PLUGIN ENABLED")
//    }
    
    @Callable
    func _enable() {
        GD.print("PLUGIN ENABLED")
        importPlugin = MapImportPlugin()
        addImportPlugin(importer: importPlugin, firstPriority: false)
    }
    
    @Callable
    func _disable() {
        GD.print("PLUGIN DISABLED")
        removeImportPlugin(importer: importPlugin)
        importPlugin = nil
    }
}

@Godot(.tool)
class MapImportPlugin: EditorImportPlugin {
    
    override func _getImporterName() -> String {
        "com.tiled.importer"
    }
    
    override func _getVisibleName() -> String {
        "Custom Import"
    }
    
    override func _getRecognizedExtensions() -> PackedStringArray {
        PackedStringArray(["tmx"])
    }
    
    override func _getResourceType() -> String {
        "PackedScene"
    }
    
    override func _getSaveExtension() -> String {
        "tscn"
    }
    
    override func _getImportOrder() -> Int32 {
        99
    }
    
    override func _getPriority() -> Double {
        0.2
    }
    
    override func _getPresetCount() -> Int32 {
        0
    }
    
    override func _getPresetName(presetIndex: Int32) -> String {
        "Random preset"
    }
    
    // BUG: This is not working on editor, options always end up empty
    override func _getImportOptions(
        path: String,
        presetIndex: Int32
    ) -> VariantCollection<GDictionary> {
        let opt1 = GDictionary()
        opt1["name"] = Variant("use_this_option")
        opt1["default_value"] = Variant(false)
        let opt2 = GDictionary()
        opt2["name"] = Variant("another_options")
        opt2["default_value"] = Variant(true)
//        let d3 = GDictionary()
//        d3["name"] = Variant("output file")
//        d3["default_value"] = Variant("output")
//        d3["property_hint"] = Variant(PropertyHint.saveFile.rawValue)
//        d3["hint_string"] = Variant("*.tres;Resource File")
        
        let c = VariantCollection(arrayLiteral: opt1)
        GD.print("GET import options PATH = \(path): \(c)")
        return [
            opt1,
            opt2
        ]
    }
    
    override func _getOptionVisibility(path: String, optionName: StringName, options: GDictionary) -> Bool {
        true
    }
    
    override func _import(
        sourceFile: String,
        savePath: String,
        options: GDictionary,
        platformVariants: VariantCollection<String>,
        genFiles: VariantCollection<String>
    ) -> GodotError {
        GD.print("IMPORTING: \(sourceFile) | TO: \(savePath)")
        GD.print("IMPORT OPTIONS: \(options)")
        guard FileAccess.fileExists(path: sourceFile) else {
            GD.pushError("[] Import file \(sourceFile) not found!")
            return .errFileNotFound
        }
        let xmlTree = XML.parse(sourceFile, with: XMLParser())
        guard let xmlTree else { return .errBug }
            
//        printTree(xmlTree.root, level: 0)
        
        // for some reason, this runs from a background thread during autoimport check
        DispatchQueue.main.async {
            self.importMap(sourceFile: sourceFile, xml: xmlTree.root)
        }
        return .ok
    }
    
    func importMap(sourceFile: String, xml: XML.Element) {
        guard let map = try? Tiled.TileMap(from: xml) else {
            return //.errBug
        }
        guard map.orientation == .orthogonal else { // support only orthogonal
            return //.errBug
        }
        
        var tileset: TileSet?
        
        for tilesetRef in map.tilesets {
            guard let firstGID = tilesetRef.firstGID,
                  let source = tilesetRef.source else { break }
            
            var filePathComponents = sourceFile.components(separatedBy: "/")
            filePathComponents.removeLast()
            let filePath = filePathComponents.joined(separator: "/")
            let tilesetFile = [filePath, source].joined(separator: "/")
            GD.print("TILESET SOURCE: \(tilesetFile)")
            
            guard FileAccess.fileExists(path: tilesetFile) else {
                GD.pushError("[] Import file \(tilesetFile) not found!")
                return //.errFileNotFound
            }
            guard let tilesetXml = XML.parse(tilesetFile, with: XMLParser()) else {
                return //.errBug
            }
            if let tiledTileset = try? Tiled.TileSet(from: tilesetXml.root) {
                tileset = TileSetImporter.createTileSet(tiledTileset, sourceFile: tilesetFile)
            }
        }
        
        guard let tileset else { return }
        guard let tilemapNode = try? createTileMap(map: map, using: tileset) else { return }
        
        let scene = PackedScene()
        scene.pack(path: tilemapNode)
        let err = ResourceSaver.save(resource: scene, path: "res://output/scene_output.tscn")
        
        if err != .ok {
            GD.print("ERROR SAVING OUTPUT: \(err)")
        } else {
            GD.print("SAVE SUCCESSFUL")
        }
    }
    
    func createTileMap(map: Tiled.TileMap, using tileset: TileSet) throws -> Node2D {
        guard let source = tileset.getSource(sourceId: tileset.getSourceId(index: 0)) as? TileSetAtlasSource else {
            throw ImportError.unknown // no source
        }
        let textureWidth = source.texture?.getWidth() ?? -1
        let tilesetColumns = Int(textureWidth / tileset.tileSize.x)
        let tilesetSourceID = tileset.getSourceId(index: 0)

        let root = Node2D()
        
        let tilesetGID = Int(map.tilesets.first?.firstGID ?? "0") ?? -99999

        // TODO: Flipped tiles bit shifting
        for layer in map.layers {
            let tilemap = TileMap()
            tilemap.name = "<name>"
            tilemap.tileSet = tileset
            let cellArray = try layer.getTileData()
                .components(separatedBy: .whitespacesAndNewlines)
                .joined()
                .components(separatedBy: ",")
                .compactMap { Int($0) }
            for idx in 0..<cellArray.count {
                let cellValue = cellArray[idx]
                let tileIndex = cellValue - (tilesetGID ?? 0)
                if tileIndex < 0 {
                    continue
                }
                let mapCoords = Vector2i(
                    x: Int32(idx % layer.width),
                    y: Int32(idx / layer.width))
                let tileCoords = Vector2i(
                    x: Int32(tileIndex % tilesetColumns),
                    y: Int32(tileIndex / tilesetColumns)
                )
                tilemap.setCell(layer: 0, coords: mapCoords, sourceId: tilesetSourceID, atlasCoords: tileCoords, alternativeTile: 0)
            }
            root.addChild(node: tilemap)
            tilemap.owner = root
        }
        for group in map.groups {
            // hardest to handle
        }
        for group in map.objectGroups {
            root.addChild(node: try transformObjectGroup(group))
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
    
    func transformObjectGroup(_ objectGroup: Tiled.ObjectGroup) throws -> Node2D {
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
            // TODO
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
    
    func createTileMapUsingLayers(map: Tiled.TileMap, using tileset: TileSet) throws -> Node2D {
        guard let source = tileset.getSource(sourceId: tileset.getSourceId(index: 0)) as? TileSetAtlasSource else {
            throw ImportError.unknown // no source
        }
        let textureWidth = source.texture?.getWidth() ?? -1
        let tilesetColumns = Int(textureWidth / tileset.tileSize.x)
        let tilesetSourceID = tileset.getSourceId(index: 0)

        let tilemap = TileMap()
        tilemap.name = "<name>"
        tilemap.tileSet = tileset
        let tilesetGID = Int(map.tilesets.first?.firstGID ?? "0") ?? -99999

        for layerIdx in 0..<map.layers.count {
            let layer = map.layers[layerIdx]
            tilemap.addLayer(toPosition: Int32(layerIdx))
            let cellArray = try layer.getTileData()
                .components(separatedBy: .whitespacesAndNewlines)
                .joined()
                .components(separatedBy: ",")
                .compactMap { Int($0) }
            for idx in 0..<cellArray.count {
                let cellValue = cellArray[idx]
                let tileIndex = cellValue - (tilesetGID ?? 0)
                if tileIndex < 0 {
                    continue
                }
                let mapCoords = Vector2i(
                    x: Int32(idx % layer.width),
                    y: Int32(idx / layer.width))
                let tileCoords = Vector2i(
                    x: Int32(tileIndex % tilesetColumns),
                    y: Int32(tileIndex / tilesetColumns)
                )
                tilemap.setCell(layer: Int32(layerIdx), coords: mapCoords, sourceId: tilesetSourceID, atlasCoords: tileCoords, alternativeTile: 0)
            }
        }
        let rootNode = Node2D()
        rootNode.name = "root"
        rootNode.addChild(node: tilemap)
        tilemap.owner = rootNode
        return rootNode
    }
}
