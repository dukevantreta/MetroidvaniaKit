import SwiftGodot

extension Vector2 {
    init(x: Int, y: Int) {
        self.init(x: Float(x), y: Float(y))
    }
    
    init(x: Int32, y: Int32) {
        self.init(x: Float(x), y: Float(y))
    }
}
