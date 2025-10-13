import SwiftGodot

@Godot
class SelfDestruct: Node {

    @Export var lifetime: Double = 1.0

    override func _process(delta: Double) {
        lifetime -= delta
        if lifetime <= 0 {
            getParent()?.queueFree()
        }
    }
}