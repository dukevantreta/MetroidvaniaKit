import SwiftGodot

@Godot(.tool)
class MapConfiguration: Resource {
    
    @Export var cellSize: Vector2i = .init(x: 16, y: 16)
    
    @Export var passageWidth: Int = 4
    
    @Export var gridBackgroundColor: Color = Color(r: 33/255, g: 33/255, b: 74/255)
    
    @Export var gridForegroundColor: Color = Color(r: 0, g: 0, b: 148/255)
    
    @Export var unexploredColor: Color = Color(r: 0.5, g: 0.5, b: 0.5)
    
    @Export var exploredColor: Color = Color(r: 1.0, g: 0.0, b: 1.0)
    
//    @Export var secretExploredColor: Color
}
