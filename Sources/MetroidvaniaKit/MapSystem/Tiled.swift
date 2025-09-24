import SwiftGodot

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
        
//        let tilemapBuilder = TilemapBuilder()
        
        // parse options
        
        // var node2D = tilemapCreator.create(source_file)
        
        let xmlParser = XMLParser()
        let xmlTree = XML.parse(sourceFile, with: xmlParser)
        
        if let xmlTree {
            printTree(xmlTree.root, level: 0)
        }
        
        return .ok
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
}

extension XML.Element: CustomStringConvertible {
    var description: String {
        "[XML] \(name) | has text: \(text?.isEmpty == false) | ATTR: \(attributes)"
    }
}

/*
 
 - XML
    - version
    - encoding
 - map:
    - tiledVersion
    - orientation
    - width
    - height
    ...
    - tileset:
        - firstgid
        - source
    - layer:
        - data
            - BUFFER
    - layer:
        - data
            - BUFFER
 
 */

