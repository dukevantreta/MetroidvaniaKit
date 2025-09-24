import SwiftGodot
import Foundation

struct CellData: Codable {
    let x: Int32
    let y: Int32
    let z: Int32
    let borders: [BorderType]
}

final class Minimap {
    
    enum CellState: Int {
        case undiscovered = 0
    }
    
    final class Cell {
        var state: CellState = .undiscovered
        var borders: [BorderType] = [.empty, .empty, .empty, .empty]
        
        func getBorder(_ idx: Int) -> Int {
            // overrides
            return borders[idx].rawValue
        }
    }
    
    private(set) var cells: [Vector3i: Cell] = [:]
    
    subscript(x: Int32, y: Int32, z: Int32) -> Cell? {
        get {
            return cells[Vector3i(x: x, y: y, z: z)]
        }
        set(newValue) {
            cells[Vector3i(x: x, y: y, z: z)] = newValue
        }
    }
    
//    subscript(x: Int, y: Int) -> Cell {
//        
//    }
    
    func getCell(at coords: Vector3i) -> Cell? {
        return cells[coords]
    }
    
    func encode() throws -> String {
        let cellData = cells.map { (position, cell) in
            CellData(x: position.x, y: position.y, z: position.z, borders: cell.borders)
        }
        let data = try JSONEncoder().encode(cellData)
        return String(data: data, encoding: .utf8)!
    }
    
    static func load() throws -> Minimap {
        let fileData = FileAccess.getFileAsString(path: "res://maps/mapdata.json").data(using: .utf8)! // FIX
        let cellData = try JSONDecoder().decode([CellData].self, from: fileData)
        
        let map = Minimap()
        for cell in cellData {
            map[cell.x, cell.y, cell.z] = Cell()
            map[cell.x, cell.y, cell.z]?.borders = cell.borders
        }
        return map
    }
}
