import SwiftGodot

@Godot
class SinWaveAI: NodeAI {
    
    var amplitude: Float = 0.0
    var frequency: Float = 0.0
    var multiplyFactor: Float = 1
    private var timeElapsed: Double = 0.0
    
    override func update(_ node: Node2D, dt: Double) {
        timeElapsed += dt
        
        node.position.x += speed * direction.x * Float(dt)
        node.position.y += speed * direction.y * Float(dt)
        
        let perp = direction.rotated(angle: .pi / 2.0)
        
        let offset = Float.sin(Float(timeElapsed) * frequency * .pi) * amplitude * multiplyFactor
        node.position.x += offset * perp.x
        node.position.y += offset * perp.y
    }
}