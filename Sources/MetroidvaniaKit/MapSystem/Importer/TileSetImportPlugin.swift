import SwiftGodot

@Godot(.tool)
class TileSetResource: Resource {
    @Export var atlasName: String = ""
}

// extension Bool: VariantConvertible {
//     func toVariant() -> Variant { Variant(self) }
// }


// extension Variant: ExpressibleByStringLiteral {
//     public convenience init(stringLiteral value: StringLiteralType) {
//         self.init(value)
//     }
//     public convenience init(extendedGraphemeClusterLiteral value: String) {
//         self.init(value)
//     }

//     public convenience init(unicodeScalarLiteral value: String) {
//         self.init(value)
//     }
// }

// extension Variant: ExpressibleByStringInterpolation {
//     public convenience init(stringInterpolation: DefaultStringInterpolation) {
//         self.init(String(stringInterpolation: stringInterpolation))
//     }
// }

// extension Variant: ExpressibleByBooleanLiteral {
//     public convenience init(booleanLiteral value: Bool) {
//         self.init(value)
//     }
// }

// extension Variant: ExpressibleByIntegerLiteral {
//     public convenience init(integerLiteral value: Int) {
//         self.init(value)
//     }
// }

// extension Variant: ExpressibleByFloatLiteral {
//     public convenience init(floatLiteral value: Double) {
//         self.init(value)
//     }
// }



// extension VariantDictionary: ExpressibleByDictionaryLiteral {
//     // public typealias Key = String
//     public typealias Key = Variant

//     public typealias Value = Variant

//     public convenience init(dictionaryLiteral elements: (Variant, Variant)...) {
//         self.init()
//         for (key, value) in elements {
//             // self[key] = value//.toVariant()
//             self.set(key: key, value: value)
//         }
//     }
// }





// @Godot(.tool)
// class TileSetImportPlugin: EditorImportPlugin {

// deinit {
//     GD.print("PLUGIN TILESET DEINIT")
// }
// override func _getFormatVersion() -> Int32 {
//     0
// }
//     override func _getImporterName() -> String {
//         "com.swiftTiledImporter.tileset"
//     }

//     override func _getVisibleName() -> String {
//         "TSX Importer"
//     }

//     override func _getRecognizedExtensions() -> PackedStringArray {
//         PackedStringArray(["tsx"])
//     }

//     override func _getResourceType() -> String {
//         // "Resource"
//         "TileSetResource"
//     }

//     override func _getSaveExtension() -> String {
//         "tres"
//     }

//     override func _getPriority() -> Double {
//         0.5
//     }

//     override func _getPresetCount() -> Int32 {
//         2
//     }

//     override func _getPresetName(presetIndex: Int32) -> String {
//         "preset-\(presetIndex)"
//     }

//     override func _getOptionVisibility(path: String, optionName: StringName, options: VariantDictionary) -> Bool {
//         true
//     }

//     let options: TypedArray<VariantDictionary> = []

//     func makeOptions(for index: Int32) -> TypedArray<VariantDictionary> {
//     //     let opt: VariantDictionary = [
//     //         // Variant("name"): Variant("test_option"),
//     //         // Variant("default_value"): Variant("true")
//     //         // "name": Variant("test_option"),
//     //         // "default_value": Variant("true")
//     //         "name": "test_option",
//             // "default_value": "truee"
//         // ]
//         let opt = VariantDictionary()
//         opt["name"] = "test_option"
//         opt["default_value"] = true
//         let opt2 = VariantDictionary()
//         opt2["name"] = "oh_noes"
//         opt2["default_value"] = "\(index)"
//         let opt3 = VariantDictionary()
//         opt3["name"] = "another_one"
//         opt3["default_value"] = Variant(index)
//         return [
//             opt, opt2, opt3
//         ]
//     }

//     override func _getImportOptions(path: String, presetIndex: Int32) -> TypedArray<VariantDictionary> {
//         options.clear()

//         // let opts: TypedArray<VariantDictionary> = 
//         // [
//         //     [
//         //         "name": "test_option",
//         //         "default_value": true
//         //     ],
//         //     [
//         //         "name": "another_one",
//         //         "default_value": false
//         //     ],
//         //     // [
//         //     //     "name": "an_int",
//         //     //     "default_value": 353
//         //     // ]
//         // ]
//         let opts: [[String: any VariantConvertible]] = [
//             [
//                 "name": "test_option",
//                 "default_value": true
//             ],
//             [
//                 "name": "another_one",
//                 "default_value": 54
//             ],
//             [
//                 "name": "and_other",
//                 "default_value": "\(presetIndex)"
//             ],
//         ]

//         let optsss : TypedArray<VariantDictionary> = TypedArray( opts.map {
//             let d = VariantDictionary()
//             let _ = $0.reduce(d, {
//                 $0[$1.key] = $1.value.toVariant()
//                 return $0
//             })
//             return d
//         })

//         for o in optsss {
//         options.append(o)
//         }

//         //  let opt: VariantDictionary = [
//         //     // Variant("name"): Variant("test_option"),
//         //     // Variant("default_value"): Variant("true")
//         //     // "name": Variant("test_option"),
//         //     // "default_value": Variant("true")
//         //     "name": "test_option",
//         //     "default_value": true
//         // ]
//         // let opts = [opt]//makeOptions(for: presetIndex)
//         // for o in opts {
//         //     options.append(o)
//         // }

//         // let options = makeOptions()

//         // let opt = VariantDictionary()
//         // opt["name"] = Variant("test_option")
//         // opt["default_value"] = Variant(true)
//         // let opt2 = VariantDictionary()
//         // opt2["name"] = Variant("oh_noes")
//         // opt2["default_value"] = Variant("\(presetIndex)")
//         // let opt3 = VariantDictionary()
//         // opt3["name"] = Variant("another_one")
//         // opt3["default_value"] = Variant(presetIndex)

//         // let opts = TypedArray<VariantDictionary>()
//         // opts.append(opt)
//         // opts.append(opt2)
//         // opts.append(opt3)
        
//         // [
//         //     opt, opt2
//         // ]

//         // arr = opts
//         GD.print("GET OPTIONS: \(options)")
//         return options
//         // [
//         //     opt, opt2
//         // ]
//     }

//     override func _getImportOrder() -> Int32 {
//         50
//     }

//     override func _import(
//         sourceFile: String, 
//         savePath: String, 
//         options: VariantDictionary, 
//         platformVariants: TypedArray<String>, 
//         genFiles: TypedArray<String>
//     ) -> GodotError {
//         GD.print("IMPORTING TILESET - \(options)")

//         let res = TileSetResource()
//         res.atlasName = savePath
//         do {
//             try saveResource(res, path: "\(savePath).tres")
//             GD.print("Saved \(savePath).tres")
//         } catch {
//             GD.print("ERROR")
//             return .errBug
//         }
//         return .ok
//     }
// }

/*
#@tool
#extends EditorImportPlugin
#
#func _get_importer_name():
	#return "com.swiftTiledImporter.tileset"
#
#func _get_visible_name() -> String:
	#return "TSX Importer"
#
#func _get_recognized_extensions() -> PackedStringArray:
	#return PackedStringArray(["tsx"])
#
#func _get_resource_type() -> String:
	#return "TileSetAtlasSource"
#
#func _get_save_extension() -> String:
	#return "tres"
	#
#func _get_priority() -> float:
	#return 0.99
	#
#func _get_preset_count() -> int:
	#return 0
#
#func _get_preset_name(preset_index: int) -> String:
	#return ""
#
#func _get_import_options(path: String, preset_index: int) -> Array:
	#return [
		#{ "name": "test_option", "default_value": true },
		#{ "name": "a_random_option", "default_value": false },
		#{ "name": "oh_noes", "default_value": "" },
	#]
#
#func _get_import_order() -> int:
	#return 90
#
#func _get_option_visibility(path, option_name, options):
	#return true
#
#func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array):
	#print("TileSet Import – source file: %s, save path: %s" % [source_file, save_path])
	#var importer = TileSetImporter.new()
	#return importer.importResource(source_file, save_path, options, platform_variants, gen_files)
*/