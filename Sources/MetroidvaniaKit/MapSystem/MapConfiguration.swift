import SwiftGodot

@Godot(.tool)
class MapConfiguration: Resource {
    
    @Export var cellSize: Vector2i = .init(x: 16, y: 16)
    
    @Export var passageWidth: Int = 4
    
    @Export var backgroundColor: Color = Color(r: 0.1, g: 0.1, b: 0.1)
    
    @Export var foregroundColor: Color = Color(r: 0.9, g: 0.9, b: 0.9)
}
