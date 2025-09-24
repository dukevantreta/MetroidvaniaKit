import SwiftGodot

@Godot(.tool)
class MapConfiguration: Resource {
    
    @Export var cellSize: Vector2i = .init(x: 16, y: 16)
    
    @Export var passageWidth: Int = 4
}
