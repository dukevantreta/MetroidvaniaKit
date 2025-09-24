import SwiftGodot

@Godot
class EnemyHurtbox: Area2D {
    
    var onDamage: ((Int) -> Void)?
    
    override func _ready() {
        collisionLayer = 0b0010_0000
        collisionMask = 0b0001_0000
        
        areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            if let projectile = otherArea as? Projectile {
                self.onDamage?(projectile.damage)
            }
        }
    }
}


//@Godot
//class EnemyHitbox: Area2D {
//    
//    var damage: Int = 0
//    var destroyMask: UInt32 = 0
//    
//    var onDestroy: (() -> Void)?
//    
//    override func _ready() {
//        areaEntered.connect { [weak self] otherArea in
//            guard let self, let otherArea else { return }
////            if let hurtbox = otherArea as? Hurtbox {
////                hurtbox.onDamage?(damage)
////            }
//            if otherArea.collisionLayer & destroyMask != 0 {
//                onDestroy?()
//            }
//        }
//    }
//}
