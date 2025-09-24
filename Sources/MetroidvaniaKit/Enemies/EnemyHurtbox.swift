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

@Godot
class EnemyHitbox: Area2D {
    
    @Export var damage: Int = 10
    
    private weak var playerHurtboxRef: PlayerHitbox?
    
    override func _ready() {
        collisionMask = 0b1_0000_0000
        
        areaEntered.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            if let playerHurtbox = otherArea as? PlayerHitbox {
                self.playerHurtboxRef = playerHurtbox
            }
        }
        
        areaExited.connect { [weak self] otherArea in
            guard let self, let otherArea else { return }
            if let _ = otherArea as? PlayerHitbox {
                self.playerHurtboxRef = nil
            }
        }
    }
    
    override func _physicsProcess(delta: Double) {
        if let playerHurtboxRef {
            onAreaStay(playerHurtboxRef)
        }
    }
    
    func onAreaStay(_ playerHurtbox: PlayerHitbox) {
        let direction: Float = playerHurtbox.globalPosition < self.globalPosition ? -1.0 : 1.0
        playerHurtbox.takeHit(damage, xDirection: direction)
    }
}
