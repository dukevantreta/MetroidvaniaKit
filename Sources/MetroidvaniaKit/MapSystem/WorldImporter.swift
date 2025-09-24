//import SwiftGodot
//
//@Godot(.tool)
//class WorldImporter: EditorImportPlugin {
//    
//    override func _getImporterName() -> String {
//        "com.tiled.world.importer"
//    }
//    
//    override func _getVisibleName() -> String {
//        "World Importer"
//    }
//    
//    override func _getRecognizedExtensions() -> PackedStringArray {
//        PackedStringArray(["world"])
//    }
//    
//    override func _getResourceType() -> String {
//        "PackedScene"
//    }
//    
//    override func _getSaveExtension() -> String {
//        "tscn"
//    }
//    
//    override func _getImportOrder() -> Int32 {
//        0
//    }
//    
//    override func _getPriority() -> Double {
//        1.0
//    }
//    
//    override func _getImportOptions(
//        path: String,
//        presetIndex: Int32
//    ) -> VariantCollection<GDictionary> {
//        
//        GD.print("GET world import options")
//        return []
//    }
//    
//    override func _import(
//        sourceFile: String,
//        savePath: String,
//        options: GDictionary,
//        platformVariants: VariantCollection<String>,
//        genFiles: VariantCollection<String>
//    ) -> GodotError {
//        
//        GD.print("IMPORTING: \(sourceFile)")
//        
//        guard FileAccess.fileExists(path: sourceFile) else {
//            GD.pushError("[] Import file \(sourceFile) not found!")
//            return .errFileNotFound
//        }
//        
//        // do shenanigans
//        
//        return .ok
//    }
//}
