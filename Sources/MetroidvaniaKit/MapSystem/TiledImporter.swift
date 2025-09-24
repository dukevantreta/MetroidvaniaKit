import SwiftGodot

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
        addImportPlugin(importer: importPlugin, firstPriority: true)
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
        PackedStringArray(["tmx", "tsx"])
    }
    
    override func _getResourceType() -> String {
        "PackedScene"
    }
    
    override func _getSaveExtension() -> String {
        "tscn"
    }
    
    override func _getImportOrder() -> Int32 {
        0
    }
    
    override func _getPriority() -> Double {
        1.0
    }
    
    override func _getPresetCount() -> Int32 {
        1
    }
    
    override func _getPresetName(presetIndex: Int32) -> String {
        "Random preset"
    }
    
    // BUG: This is not working on editor, options always end up empty
    override func _getImportOptions(
        path: String,
        presetIndex: Int32
    ) -> VariantCollection<GDictionary> {
        let d1 = GDictionary()
        d1["name"] = Variant("use_layers")
//        d1["default_value"] = Variant(false)
        let d2 = GDictionary()
        d2["name"] = Variant("use_tilemap_layers")
        d2["default_value"] = Variant(false)
        let d3 = GDictionary()
        d3["name"] = Variant("output file")
        d3["default_value"] = Variant("output")
        d3["property_hint"] = Variant(PropertyHint.saveFile.rawValue)
        d3["hint_string"] = Variant("*.tres;Resource File")
        
        let c = VariantCollection(arrayLiteral: d3)
        GD.print("GET import options PATH = \(path): \(c)")
        return [
            d1,
            d3,
            d2
//            { "name": "use_tilemap_layers", "default_value": false },
        ]
    }
    
    override func _getOptionVisibility(path: String, optionName: StringName, options: GDictionary) -> Bool {
        true
    }
    
    var outputPath = "res://output_test/"
    
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
            let map = try Tiled.TileMap(from: xmlTree.root)
            guard map.orientation == .orthogonal else { // support only orthogonal
                return .errBug
            }
            
            for tilesetRef in map.tilesets {
                guard let firstGID = tilesetRef.firstGID,
                      let source = tilesetRef.source else { break }
                
                let tilesetFile = [filePath, source].joined(separator: "/")
                GD.print("TILESET SOURCE: \(tilesetFile)")
                
                guard FileAccess.fileExists(path: tilesetFile) else {
                    GD.pushError("[] Import file \(tilesetFile) not found!")
                    return .errFileNotFound
                }
                guard let tilesetXml = XML.parse(tilesetFile, with: XMLParser()) else {
                    return .errBug
                }
//                        GD.print("TILESET XML -----------------------------")
//                        printTree(tilesetXml.root, level: 0)
                let tileset = try Tiled.TileSet(from: tilesetXml.root)
//                GD.print("TILESET MODEL -----------------------------")
//                GD.print(tileset)
                
                createTileSet(tileset, sourceFile: tilesetFile)
            }
            
        } catch {
            GD.print("ERROR PARSING MAP \(error)")
        }
//            if let map = Tiled.parseMap(from: xmlTree.root) {
//                GD.print("MAP MODEL -----------------------------")
//                GD.print(map)
//            }
//        }
        
        return .ok
    }
    
    func createTileSet(_ tileset: Tiled.TileSet, sourceFile: String) {
        let gTileset = TileSet()
        gTileset.resourceName = tileset.name ?? ""
        
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
            GD.print("ERROR IMG SOURCE"); return
        }
        
        let imageFile = [tilesetDir, imageSource].joined(separator: "/")
        guard let image = Image.loadFromFile(path: imageFile) else {
            GD.print("ERROR LOADING IMAGE"); return
        }
        guard let imageTexture = ImageTexture.createFromImage(image) else {
            GD.print("ERROR MAKING IMAGE TEXTURE"); return
        }
        
        let margin = Int32(tileset.margin ?? 0)
        let spacing = Int32(tileset.spacing ?? 0)
        
        let atlasSource = TileSetAtlasSource()
        atlasSource.margins = Vector2i(x: margin, y: margin)
        atlasSource.separation = Vector2i(x: spacing, y: spacing)
        atlasSource.texture = imageTexture
        atlasSource.resourceName = imageFile.components(separatedBy: "/").last ?? ""
        
        // create tiles
        let columns = tileset.columns ?? 0
        for tile in tileset.tiles {
            let atlasCoords = Vector2i(
                x: Int32(tile.id % columns),
                y: Int32(tile.id / columns))
            atlasSource.createTile(atlasCoords: atlasCoords)
        }
        
        gTileset.addSource(atlasSource)
        
        let outputDir = "res://output"
        if !DirAccess.dirExistsAbsolute(path: outputDir) {
            DirAccess.makeDirRecursiveAbsolute(path: outputDir)
        }
        let saveFile = "tileset_test.tres"
        let outputFile = [outputDir, saveFile].joined(separator: "/")
        let err = ResourceSaver.save(resource: gTileset, path: outputFile)
        if err != .ok {
            GD.print("ERROR SAVING RESOURCE: \(err)")
        }
    }
    
//    func createTileMap(xml: XML.Element) throws {
//        let map = try Tiled.TileMap(from: xmlTree.root)
//    }
}
