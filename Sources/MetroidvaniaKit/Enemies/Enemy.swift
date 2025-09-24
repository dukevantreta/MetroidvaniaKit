import SwiftGodot

@Godot
class EnemyAI: Node2D {
    func update(_ enemy: Enemy, delta: Double) {}
}

@Godot
class Enemy: Node2D {
    
    @Node("AI") var enemyAI: EnemyAI?
    @Node("Sprite2D") var sprite: Sprite2D?
    @Node("Hitbox") var hitbox: Hitbox?
    
    @Export var hp: Int = 10
    
    var hitTimer = Timer()
    var isStunlocked = false
    
    override func _ready() {
        hitTimer.autostart = false
        hitTimer.oneShot = true
        hitTimer.timeout.connect { [weak self] in
            self?.flashTimeout()
        }
        addChild(node: hitTimer)
        
        hitbox?.damage = 10
        hitbox?.damageType = .enemy
        hitbox?.isContinuous = true
        hitbox?.monitoring = true
        hitbox?.monitorable = true
        hitbox?.setCollisionLayer(.enemy)
        hitbox?.addCollisionMask(.player)
        
        hitbox?.onHit = { [weak self] damage in
            self?.takeDamage(damage.amount)
        }
    }
    
    override func _physicsProcess(delta: Double) {
        guard !isStunlocked else { return }
        enemyAI?.update(self, delta: delta)
    }
    
    func takeDamage(_ amount: Int) {
        flash()
        hp -= amount
        if hp <= 0 {
            destroy()
        }
    }
    
    func flash() {
        isStunlocked = true
        (sprite?.material as? ShaderMaterial)?.setShaderParameter(param: "flash_factor", value: Variant(1.0))
        hitTimer.start(timeSec: 0.1)
    }
    
    func flashTimeout() {
        isStunlocked = false
        (sprite?.material as? ShaderMaterial)?.setShaderParameter(param: "flash_factor", value: Variant(0.0))
    }
    
    func destroy() {
        if let dropType = DropTable.default.rollDrop() {
            log("ENEMY DROP: \(dropType.sceneName)")
            let object = ResourceLoader.load(path: "res://objects/\(dropType.sceneName).tscn") as? PackedScene
            if let drop = object?.instantiate() as? Node2D {
                drop.position = position
                getParent()?.callDeferred(method: "add_child", Variant(drop))
            }
        }
        queueFree()
    }
}
