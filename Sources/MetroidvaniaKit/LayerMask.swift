import SwiftGodot

struct LayerMask: OptionSet {
    
    let rawValue: UInt32
    
    static let floor      = LayerMask(rawValue: 1 << 0)
    static let block      = 0b0010
    static let water      = LayerMask(rawValue: 1 << 2)
    static let hazard     = 0b1000
    static let projectile = 0b0001_0000
    static let enemy      = LayerMask(rawValue: 1 << 5)
    // static let pickup     = LayerMask(rawValue: 1 << 6)
    static let player     = LayerMask(rawValue: 1 << 8)
}

extension CollisionObject2D {
    
    func setCollisionLayer(_ mask: LayerMask) {
        self.collisionLayer = mask.rawValue
    }
    
    func addCollisionMask(_ mask: LayerMask) {
        self.collisionMask |= mask.rawValue
    }

    func removeCollisionMask(_ mask: LayerMask) {
        self.collisionMask &= ~mask.rawValue
    }
}