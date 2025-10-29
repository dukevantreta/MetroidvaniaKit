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

@Godot
class WideCurveAI: NodeAI {

    var amplitude: Float = 16.0

    @Export var multiplyFactor: Double = 10.0
    @Export var offsetX: Double = 0.1
    @Export var flattenFactor: Double = 0.15

    private var firstRefPosition: Vector2 = .zero
    private var referencePosition: Vector2 = .zero

    func calculateAmplitude(for distance: Vector2) -> Double {
        let moveDistance = distance.length() / 16.0
        let factor = Double.log2(multiplyFactor * (moveDistance + offsetX)) * flattenFactor
        return factor
    }

    override func update(_ node: Node2D, dt: Double) {
        if referencePosition == .zero {
            firstRefPosition = node.position
            referencePosition = node.position
        }
        referencePosition.x += speed * direction.x * Float(dt)
        referencePosition.y += speed * direction.y * Float(dt)

        let distance = referencePosition - firstRefPosition
        let factor = calculateAmplitude(for: distance)

        let expand = direction.orthogonal() * amplitude * factor
        node.position.x = referencePosition.x + expand.x
        node.position.y = referencePosition.y + expand.y
    }
}