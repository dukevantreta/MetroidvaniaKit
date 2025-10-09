import SwiftGodot

@Godot
final class TileSprite2D: Sprite2D {
    
    @Export var frameRegions: [Rect2] = []
    @Export var frameDurations: [Double] = []

    @Export var isRandom = false

    private var accumulator: Double = 0.0
    private var index: Int = 0

    override func _ready() {
        if frameRegions.count != frameDurations.count {
            logError("Tile sprite frame arrays size doesn't match!")
        }
        if isRandom {
            index = Int.random(in: 0..<frameRegions.count)
            accumulator = Double.random(in: 0.0..<frameDurations[index])
        }
    }

    override func _process(delta: Double) {
        guard !frameRegions.isEmpty else { return }
        accumulator += delta
        if accumulator >= frameDurations[index] {
            accumulator -= frameDurations[index]
            index += 1
            if index >= frameRegions.count {
                index = 0
            }
            regionRect = frameRegions[index]
        }
    }
}