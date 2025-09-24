import SwiftGodot

protocol EnemyAI {
    func update(_ enemy: Enemy, delta: Double)
}

@Godot
class Enemy: Node2D {
    
    @SceneTree(path: "AI") var enemyAI: EnemyAI?
    @SceneTree(path: "Hurtbox") var hurtbox: EnemyHurtbox?
    
    @Export var hp: Int = 10
    
    override func _ready() {
        hurtbox?.onDamage = { [weak self] damage in
            self?.takeDamage(damage)
        }
    }
    
    override func _physicsProcess(delta: Double) {
        enemyAI?.update(self, delta: delta)
    }
    
    func takeDamage(_ amount: Int) {
        hp -= amount
        if hp <= 0 {
            queueFree()
        }
    }
}
