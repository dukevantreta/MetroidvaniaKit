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
        "Map Importer!"
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
        0
    }
    
    override func _getPriority() -> Double {
        1.0
    }
    
    override func _getPresetCount() -> Int32 {
        0
    }
    
    override func _getImportOptions(
        path: String,
        presetIndex: Int32
    ) -> VariantCollection<GDictionary> {
        
        GD.print("GET import options")
        let d1 = GDictionary()
        d1["name"] = Variant("use_layers")
        d1["default_value"] = Variant(false)
        let d2 = GDictionary()
        d2["name"] = Variant("use_tilemaps")
        d2["default_value"] = Variant(true)
        return [
            d1,
            d2
        ]
    }
    
    var outputPath = "res://output_test/"
    
    override func _import(
        sourceFile: String,
        savePath: String,
        options: GDictionary,
        platformVariants: VariantCollection<String>,
        genFiles: VariantCollection<String>
    ) -> GodotError {
        GD.print("IMPORTING: \(sourceFile)")
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
                
                createTileSet(tileset)
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
    
    func createTileSet(_ tileset: Tiled.TileSet) {
        let gTileset = TileSet()
        gTileset.resourceName = "VERY TILE SET"
        
        
        let savePath = outputPath + "imported_set.tres"
        
        
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



/*
 godot objects to create:
 
 - TileSetAtlasSource
 - TileSet
 - TileMap
 */
