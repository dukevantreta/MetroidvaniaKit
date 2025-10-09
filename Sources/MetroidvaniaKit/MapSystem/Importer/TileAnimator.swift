import SwiftGodot

@Godot
final class TileAnimator: Node {

    @Export weak var tilemap: TileMapLayer?

    @Export var mapCoords: Vector2i = .zero

    @Export var frameCoords: [Vector2i] = []
    @Export var frameDurations: [Double] = []

    @Export var sourceID: Int32 = 0
    @Export var altFlags: Int32 = 0

    @Export var isRandom = false

    private var accumulator: Double = 0.0
    private var index: Int = 0

    override func _ready() {
        if frameCoords.count != frameDurations.count {
            logError("Tile animator frame arrays size doesn't match! Tile coords = \(mapCoords)")
        }
        if isRandom {
            index = Int.random(in: 0..<frameCoords.count)
            accumulator = Double.random(in: 0.0..<frameDurations[index])
        }
    }

    override func _process(delta: Double) {
        accumulator += delta
        if accumulator >= frameDurations[index] {
            accumulator -= frameDurations[index]
            index += 1
            if index >= frameCoords.count {
                index = 0
            }
            tilemap?.setCell(
                coords: mapCoords, 
                sourceId: sourceID, 
                atlasCoords: frameCoords[index], 
                alternativeTile: altFlags
            )
        }
    }
}