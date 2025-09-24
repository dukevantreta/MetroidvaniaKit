//import SwiftGodot
//
//@Godot //(.tool)
//class MiniMap: Control {
//    
//    @Export var trackPosition: Bool = true
//    
//    @Export var size: Vector2i = Vector2i(x: 3, y: 3) // area
//    
//    @Export var center: Vector2i = .zero {
//        didSet {
//            queueRedraw()
//        }
//    }
//    
//    @Export var layer: Int = 0 {
//        didSet {
//            queueRedraw()
//        }
//    }
//    
//    override func _ready() {
//        if Engine.isEditorHint() { return }
//        
//        // setup listen to mapUpdated event
//    }
//    
//    func onCellChanged() {
////    new_cell: Vector3i
////    center = Vector2i(new_cell.x, new_cell.y)
////    layer = new_cell.z
//    }
//    
//    override func _getConfigurationWarnings() -> PackedStringArray {
//        var message = PackedStringArray()
//        if size.x.isMultiple(of: 2) || size.y.isMultiple(of: 2) {
//            message.append(value: "Using even area dimensions is not recommended.")
//        }
//        return message
//    }
//    
//    override func _getMinimumSize() -> Vector2 {
//        Vector2(from: size) * Vector2(x: 32, y: 32) // CELL_SIZE
//    }
//    
//    override func _draw() {
//        let offset = -size / 2
//        for x in 0..<size.x {
//            for y in 0..<size.y {
//                // draw cell
//            }
//        }
//        
//        // draw shared border if applicable
//        
//        // draw custom elements
//    }
//}
