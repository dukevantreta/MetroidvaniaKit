struct CellData: Codable {
    let x: Int
    let y: Int
    let z: Int
    let borders: [BorderType]
}

final class Map {
    
    enum CellState: Int {
        case undiscovered = 0
    }
    
    final class Cell {
//        var state: CellState
    }
}
