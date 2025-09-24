import SwiftGodot

@Godot //(.tool)
class MiniMap: Control {
    
    @Export var trackPosition: Bool = true
    
    @Export var area: Vector2i = Vector2i(x: 3, y: 3) // area
    {
        didSet {
            updateConfigurationWarnings()
            updateMinimumSize()
        }
    }
    
    @Export var center: Vector2i = .zero {
        didSet {
            queueRedraw()
        }
    }
    
    @Export var layer: Int = 0 {
        didSet {
            queueRedraw()
        }
    }
    
    override func _ready() {
        if Engine.isEditorHint() { return }
        
        // setup listen to mapUpdated event
    }
    
    func onCellChanged() {
//    new_cell: Vector3i
//    center = Vector2i(new_cell.x, new_cell.y)
//    layer = new_cell.z
    }
    
    override func _getConfigurationWarnings() -> PackedStringArray {
        var message = PackedStringArray()
        if area.x.isMultiple(of: 2) || area.y.isMultiple(of: 2) {
            message.append(value: "Using even area dimensions is not recommended.")
        }
        return message
    }
    
    override func _getMinimumSize() -> Vector2 {
        Vector2(from: area) * Vector2(x: 32, y: 32) // CELL_SIZE
    }
    
    override func _draw() {
        let offset = -area / 2
        for x in 0..<area.x {
            for y in 0..<area.y {
                // draw cell
                let coords = Vector3i(x: center.x + offset.x + x, y: center.y + offset.y + y, z: Int32(layer))
                RoomDrawer.draw(canvasItem: self, offset: Vector2(x: x, y: y), coords: coords)
            }
        }
        
        // draw shared border if applicable
        
        // draw custom elements
    }
}

class RoomDrawer {
    
    static func draw(canvasItem: CanvasItem, offset: Vector2, coords: Vector3i) {
        
        guard let cellData = MapData.getCell(at: coords) else {
            drawEmpty(canvasItem: canvasItem, offset: offset)
            return
        }
        
        let ci = canvasItem.getCanvasItem()
        
        if let centerTexture = ResourceLoader.load(path: "res://SampleProject/MF/RoomFill.png") as? Texture2D {
            let color = Color(r: 1.0, g: 0.0, b: 1.0)
            centerTexture.draw(canvasItem: ci, position: offset * 32, modulate: color)
        }
        
        drawRegularBorders(canvasItem: canvasItem, offset: offset, coords: coords)
        
        canvasItem.drawSetTransformMatrix(xform: Transform2D())
    }
    
    static func drawEmpty(canvasItem: CanvasItem, offset: Vector2) {
        guard let texture = ResourceLoader.load(path: "res://SampleProject/MF/Empty.png") as? Texture2D else {
            return
        }
        let ci = canvasItem.getCanvasItem()
        texture.draw(canvasItem: ci, position: offset * 32, modulate: Color.white)
    }
    
    static func drawRegularBorders(canvasItem: CanvasItem, offset: Vector2, coords: Vector3i) {
        
        guard let cellData = MapData.getCell(at: coords) else {
            return
        }
//        let cellData = CellData()
        
        var borders: [Int] = [1, 0, -1, 2]
        
        for i in 0..<4 {
            borders[i] = cellData.getBorder(i)
        }
        
        // draw separator?
//        for i in 0..<2 {
//            if let tex = getBorderTexture(idx: -1, direction: i) {
//                drawBorder(canvasItem: canvasItem, offset: offset, i: i, texture: tex, color: .white)
//            }
//        }
        
        for i in 0..<4 {
            if let tex = getBorderTexture(idx: borders[i], direction: i) {
                drawBorder(canvasItem: canvasItem, offset: offset, i: i, texture: tex, color: .white)
            }
        }
    }
    
    static func drawBorder(canvasItem: CanvasItem, offset: Vector2, i: Int, texture: Texture2D, color: Color) {
        let rotation = .pi * 0.5 * Double(i)
        canvasItem.drawSetTransform(position: offset * 32 + Vector2(x: 16, y: 16), rotation: rotation, scale: .one)
        let ci = canvasItem.getCanvasItem()
        texture.draw(canvasItem: ci, position: -(texture.getSize() / 2) + Vector2.right * Double(Int32(16) - texture.getWidth() / 2), modulate: color)
//        if i == 0 || i == 2 {
//            let vec = Vector2.right * Double(Int32(16) - texture.getWidth() / 2)
//            let position = -(texture.getSize() / 2) + vec
//            texture.draw(canvasItem: canvasItem.getCanvasItem(), position: position, modulate: color)
//        } else if i == 1 || i == 3 {
//            let vec = Vector2.right * Double(Int32(16) - texture.getWidth() / 2)
//            let position = -(texture.getSize() / 2) + vec
//            texture.draw(canvasItem: canvasItem.getCanvasItem(), position: position, modulate: color)
//        }
    }
    
    static func getBorderTexture(idx: Int, direction: Int) -> Texture2D? {
        let wall: Texture2D? = ResourceLoader.load(path: "res://SampleProject/MF/BorderWall.png") as! Texture2D
        let passage: Texture2D? = ResourceLoader.load(path: "res://SampleProject/MF/BorderPassage.png") as! Texture2D
        let separator: Texture2D? = nil // ResourceLoader.load(path: "res://SampleProject/MF/BorderPassage.png") as? Texture2D
        let borders: [Texture2D?] = [
            ResourceLoader.load(path: "res://SampleProject/MF/Borders/Door1.png") as! Texture2D,
            ResourceLoader.load(path: "res://SampleProject/MF/Borders/Door2.png") as! Texture2D,
            ResourceLoader.load(path: "res://SampleProject/MF/Borders/Door3.png") as! Texture2D,
            ResourceLoader.load(path: "res://SampleProject/MF/Borders/Door4.png") as! Texture2D
        ]
        
//        let textureName: StringName
//        if direction == 0 || direction == 2 {
//            textureName = switch idx {
//                case -1: "vertical_separator"
//                case 0: "vertical_wall"
//                case 1: "vertical_passage"
//                default: "vertical_borders"
//            }
//        } else {
//            textureName = switch idx {
//                case -1: "horizontal_separator"
//                case 0: "horizontal_wall"
//                case 1: "horizontal_passage"
//                default: "horizontal_borders"
//            }
//        }
//        textureName = switch idx {
//            case -1: "separator"
//            case 0: "wall"
//            case 1: "passage"
//            default: "borders"
//        }
        
        let tex: Texture2D?
        if idx >= 2 {
            tex = borders[idx - 2]
        } else {
            tex = switch idx {
            case -1: separator
            case 0: wall
            case 1: passage
            default: nil
            }
        }
        
        return tex
    }
}

class CellData {
    var borders: [Int] = [-1, -1, -1, -1]
    
    init(borders: [Int]) {
        self.borders = borders
    }
    
    func getBorder(_ idx: Int) -> Int {
        // overrides
        return borders[idx]
    }
}

class MapData {
    
    static var cells: [Vector3i: CellData] = [
        Vector3i(x: 0, y: 0, z: 0): CellData(borders: [1,0,-1,2]),
        Vector3i(x: 1, y: 1, z: 0): CellData(borders: [1,0,-1,2]),
        Vector3i(x: 1, y: 0, z: 0): CellData(borders: [0,1,1,0]),
    ]
    
    static func getCell(at coords: Vector3i) -> CellData? {
        return cells[coords]
    }
}
