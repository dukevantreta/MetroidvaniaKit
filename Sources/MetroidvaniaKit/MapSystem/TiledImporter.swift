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
        
        var filePathComponents = sourceFile.components(separatedBy: "/")
        filePathComponents.removeLast()
        let filePath = filePathComponents.joined(separator: "/")
        // TODO parse options
        
        let xmlTree = XML.parse(sourceFile, with: XMLParser())
        guard let xmlTree else { return .errBug }
            
        printTree(xmlTree.root, level: 0)
        
        do {
            
            // for some reason, this runs from a background thread during autoimport check
            DispatchQueue.main.async {
                
                guard let map = try? Tiled.TileMap(from: xmlTree.root) else {
                    return //.errBug
                }
                guard map.orientation == .orthogonal else { // support only orthogonal
                    return //.errBug
                }
    //            GD.print("MAP MODEL -----------------------------"); GD.print(map)
                
                var tileset: TileSet?
    //            var tilesetGID: Int?
                var tilesetColumns: Int = 0
                var sourceID: Int32 = 0
                
                for tilesetRef in map.tilesets {
                    guard let firstGID = tilesetRef.firstGID,
                          let source = tilesetRef.source else { break }
                    
                    let tilesetFile = [filePath, source].joined(separator: "/")
                    GD.print("TILESET SOURCE: \(tilesetFile)")
                    
                    guard FileAccess.fileExists(path: tilesetFile) else {
                        GD.pushError("[] Import file \(tilesetFile) not found!")
                        return //.errFileNotFound
                    }
                    guard let tilesetXml = XML.parse(tilesetFile, with: XMLParser()) else {
                        return //.errBug
                    }
    //                        GD.print("TILESET XML -----------------------------")
    //                        printTree(tilesetXml.root, level: 0)
                    if let tiledTileset = try? Tiled.TileSet(from: tilesetXml.root) {
                        //                GD.print("TILESET MODEL -----------------------------")
                        //                GD.print(tileset)
                        
                        let tup = self.createTileSet(tiledTileset, sourceFile: tilesetFile)
                        tileset = tup?.0
                        sourceID = tup?.1 ?? -1
                        //                tilesetGID = Int(tiledTileset.firstGID ?? "")
                        tilesetColumns = tiledTileset.columns ?? 0
                    }
                }
            
                let tilemap = TileMap()
                tilemap.name = "<name>"
                
                tileset?.setupLocalToScene() // save .res from separate importer and load as resource?
                tilemap.tileSet = tileset
    //            tilemap.tileSet = resTileset
                GD.print("Is layer 0 enabled: \(tilemap.isLayerEnabled(layer: 0))")
                
                    let tilesetGID = Int(map.tilesets.first?.firstGID ?? "0") ?? -99999
                    
                    let sid = sourceID
                    GD.print("TileSet source ID: \(sid)")
                    
                // TODO: Flipped tiles bit shifting
                for layer in map.layers {
                    if let data = layer.data {
                        guard data.encoding == "csv" else {
                            return  // err
                        }
                        guard let text = data.text else {
                            return  // err
                        }
                        let cellArray = text
                            .components(separatedBy: .whitespacesAndNewlines)
                            .joined()
                            .components(separatedBy: ",")
                            .compactMap { Int($0) }
                        
                        GD.print("Cell count: \(cellArray.count)")
                        
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
                            tilemap.setCell(layer: 0, coords: mapCoords, sourceId: sid, atlasCoords: tileCoords, alternativeTile: 0)
                        }
                    }
                }
            
            
//            let tilemap2 = TileMap()
//            tilemap2.name = "tilemap 2"
//
                let node = Node2D()
                node.name = "root"
                node.addChild(node: tilemap)
                tilemap.owner = node
    //            node.addChild(node: tilemap2)
                let scene = PackedScene()
                scene.pack(path: node)
//                scene.pack(path: tilemap)
                let err = ResourceSaver.save(resource: scene, path: "res://output/scene_output.tscn")
                
                if err != .ok {
                    GD.print("ERROR SAVING OUTPUT: \(err)")
                } else {
                    GD.print("SAVE SUCCESSFUL")
                }
            }
            
            
            
            return .ok // bp
            
        } catch {
            GD.print("ERROR PARSING MAP \(error)")
        }
        
//            if let map = Tiled.parseMap(from: xmlTree.root) {
//                GD.print("MAP MODEL -----------------------------"); GD.print(map)
//            }
//        }
//        let node = Node2D()
//        node.name = "root"
//        
//        let scene = PackedScene()
//        scene.pack(path: node)
//        let err = ResourceSaver.save(resource: scene, path: "res://output/scene_output.tscn")
//        
//        if err != .ok {
//            GD.print("ERROR SAVING OUTPUT: \(err)")
//        }
        
        return .ok
    }
    
    func createTileSet(_ tileset: Tiled.TileSet, sourceFile: String) -> (TileSet, Int32)? {
        let gTileset = TileSet()
        gTileset.resourceName = tileset.name ?? ""
        
        gTileset.setupLocalToScene()
        
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
        guard let image = Image.loadFromFile(path: imageFile) else {
            GD.print("ERROR LOADING IMAGE"); return nil
        }
        guard let imageTexture = ImageTexture.createFromImage(image) else {
            GD.print("ERROR MAKING IMAGE TEXTURE"); return nil
        }
        
        let margin = Int32(tileset.margin ?? 0)
        let spacing = Int32(tileset.spacing ?? 0)
        
        let atlasSource = TileSetAtlasSource()
        atlasSource.margins = Vector2i(x: margin, y: margin)
        atlasSource.separation = Vector2i(x: spacing, y: spacing)
        atlasSource.texture = imageTexture
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
        
        
        GD.print("ADDED SOURCE WITH ID: \(sourceId)")
        
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
        return (gTileset, sourceId)
    }
}
