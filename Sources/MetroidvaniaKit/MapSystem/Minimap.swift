import SwiftGodot
import Foundation

enum Border: Int {
    case right = 0
    case down = 1
    case left = 2
    case up = 3
    
    init(idx: Int) {
        self.init(rawValue: idx % 4)!
    }
}

enum BorderType: Int, Codable {
    case empty = -1
    case wall = 0
    case passage = 1
    case door = 2
}


// cell xyz can be a uint8
struct CellData: Codable {
    let x: Int32
    let y: Int32
    let z: Int32
    let borders: [BorderType]
}

final class Minimap {
    
    enum CellState: Int {
        case undiscovered = 0
        case mapped
        case explored
        // case exploredSecret
    }
    
    final class Cell {
        var state: CellState// = .undiscovered
        var borders: [BorderType]// = [.empty, .empty, .empty, .empty]
        
        init(borders: [BorderType] = [.empty, .empty, .empty, .empty]) {
            self.state = .undiscovered
            self.borders = borders
        }
        
        func getBorder(_ idx: Int) -> Int {
            // overrides
            return borders[idx].rawValue
        }
        
        subscript(border: Border) -> BorderType {
            get {
                borders[border.rawValue]
            }
            set {
                borders[border.rawValue] = newValue
            }
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
    
    func visitCell(at coords: Vector3i) {
        cells[coords]?.state = .explored
    }
    
    func encode() throws -> String {
        let cellData = cells.map { (position, cell) in
            CellData(x: position.x, y: position.y, z: position.z, borders: cell.borders)
        }
        let data = try JSONEncoder().encode(cellData)
        return String(data: data, encoding: .utf8)!
    }
    
    static func load(at path: String) throws -> Minimap {
        let fileData = FileAccess.getFileAsString(path: path).data(using: .utf8)! // FIX
        let cellData = try JSONDecoder().decode([CellData].self, from: fileData)
        
        let map = Minimap()
        for cell in cellData {
            map[cell.x, cell.y, cell.z] = Cell()
            map[cell.x, cell.y, cell.z]?.borders = cell.borders
        }
        return map
    }
}
