import SwiftGodot

@Godot
final class PlayerDebug: Node2D {

    @Node("..") weak var player: Player?

    @Export var isEnabled = true

    override func _process(delta: Double) {
        guard isEnabled else { return }
        queueRedraw()
    }
    
    override func _draw() {
        guard let player else { 
            logError("Parent is not a [Player] node."); return
        }
        guard isEnabled else { return }

        let size = player.size
        let origin = Vector2(x: 0, y: -size.y / 2)
        let v = player.velocity * 0.1
        drawLine(from: origin, to: origin + v, color: .blue)
        drawLine(from: origin, to: origin + Vector2(x: v.x, y: 0), color: .red)
        drawLine(from: origin, to: origin + Vector2(x: 0, y: v.y), color: .green)
        
        drawLine(from: player.lowRay.origin, to: player.lowRay.target, color: .magenta)
        drawLine(from: player.midRay.origin, to: player.midRay.target, color: .magenta)
        drawLine(from: player.highRay.origin, to: player.highRay.target, color: .magenta)
        drawLine(from: .zero, to: Vector2(x: 0, y: player.data.floorCheckLength), color: .blueViolet)
        
        let shotRegion = Rect2(x: player.shotOrigin.x - 1, y: player.shotOrigin.y - 1, width: 2, height: 2)
        drawRect(shotRegion, color: .red)
    }
}