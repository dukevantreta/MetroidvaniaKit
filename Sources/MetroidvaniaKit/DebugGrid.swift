import SwiftGodot

@Godot(.tool)
class DebugGrid: Node2D {
    
    @Export var tileSize: Vector2i = .zero {
        didSet {
            queueRedraw()
        }
    }

    @Export var widthInTiles: Int32 = 0 {
        didSet {
            queueRedraw()
        }
    }

    @Export var heightInTiles: Int32 = 0 {
        didSet {
            queueRedraw()
        }
    }

    override func _draw() {
        guard Engine.isEditorHint() else { return }

        for i in 0...widthInTiles {
            drawLine(
                from: Vector2(x: i * tileSize.x, y: 0),
                to: Vector2(x: i * tileSize.x, y: heightInTiles * tileSize.y),
                color: .green,
                width: -1.0,
                antialiased: false
            )
        }
        for i in 0...heightInTiles {
            drawLine(
                from: Vector2(x: 0, y: i * tileSize.y),
                to: Vector2(x: widthInTiles * tileSize.x, y: i * tileSize.y),
                color: .green,
                width: -1.0,
                antialiased: false
            )
        }
    }
}