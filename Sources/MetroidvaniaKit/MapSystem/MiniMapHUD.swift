import SwiftGodot

@Godot(.tool)
class MiniMapHUD: Control {
    
//    let cellSize = Vector2(x: 32, y: 32)
//    let cellSize = Vector2(x: 8, y: 8)
    
//    let mapData = MapData.load()
    let mapData: Minimap = (try? Minimap.load()) ?? Minimap()
    
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
        Vector2(from: area) * Vector2(from: MapDrawer.shared.cellSize)
    }
    
    override func _draw() {
        let offset = -area / 2
        for x in 0..<area.x {
            for y in 0..<area.y {
                // draw cell
                let coords = Vector3i(x: center.x + offset.x + x, y: center.y + offset.y + y, z: Int32(layer))
                MapDrawer.shared.draw(canvasItem: self, offset: Vector2i(x: x, y: y), coords: coords, mapData: mapData)
            }
        }
        
        // draw shared border if applicable
        
        // draw custom elements
    }
}

//class MapCellData {
////    var borders: [Int] = [-1, -1, -1, -1]
//    var borders: [BorderType] = [.empty, .empty, .empty, .empty]
//    
//    init(borders: [BorderType]) {
//        self.borders = borders
//    }
//    
//    func getBorder(_ idx: Int) -> Int {
//        // overrides
//        return borders[idx].rawValue
//    }
//}
//
//import Foundation
//
//class MapData {
//    
//    var cells: [Vector3i: MapCellData]
//    
//    func getCell(at coords: Vector3i) -> MapCellData? {
//        return cells[coords]
//    }
//    
//    init(cells: [Vector3i : MapCellData]) {
//        self.cells = cells
//    }
//    
//    static func mock() -> MapData {
//        let mapData = MapData(cells: [:])
//        mapData.cells = [
//            Vector3i(x: 0, y: 0, z: 0): MapCellData(borders: [.passage, .wall, .empty, .door]),
//            Vector3i(x: 1, y: 1, z: 0): MapCellData(borders: [.passage, .wall, .empty, .door]),
//            Vector3i(x: 1, y: 0, z: 0): MapCellData(borders: [.wall, .passage, .passage, .wall]),
//        ]
//        return mapData
//    }
//    
//    static func load() -> MapData {
//        let fileData = FileAccess.getFileAsString(path: "res://maps/mapdata.json").data(using: .utf8)!
//        let minimapData = try! JSONDecoder().decode(MinimapData.self, from: fileData)
//        
//        var cellsData: [Vector3i: MapCellData] = [:]
//        for cell in minimapData.cells {
//            let point = Vector3i(x: Int32(cell.coordinates.x), y: Int32(cell.coordinates.y), z: Int32(cell.coordinates.z))
//            cellsData[point] = MapCellData(borders: cell.borders)
////            cellsData[point] = CellData(borders: cell.borders.map { $0.rawValue })
//        }
//        return MapData(cells: cellsData)
//    }
//    
////    static var cells: [Vector3i: CellData] = [
////        Vector3i(x: 0, y: 0, z: 0): CellData(borders: [1,0,-1,2]),
////        Vector3i(x: 1, y: 1, z: 0): CellData(borders: [1,0,-1,2]),
////        Vector3i(x: 1, y: 0, z: 0): CellData(borders: [0,1,1,0]),
////    ]
////
////    static func getCell(at coords: Vector3i) -> CellData? {
////        return cells[coords]
////    }
//}
