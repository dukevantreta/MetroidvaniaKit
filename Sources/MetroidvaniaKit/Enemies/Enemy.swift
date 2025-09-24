import SwiftGodot

protocol EnemyAI {
    func update(_ enemy: Enemy, delta: Double)
}

@Godot
class Enemy: Node2D {
    
    @SceneTree(path: "AI") var enemyAI: EnemyAI?
    
    override func _physicsProcess(delta: Double) {
        enemyAI?.update(self, delta: delta)
    }
}
