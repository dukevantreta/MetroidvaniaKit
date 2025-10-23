import SwiftGodot

@Godot(.tool)
final class PlayerConfig: Resource {

    @Export private(set) var speed: Double = 180.0
    @Export private(set) var acceleration: Double = 10.0
    @Export private(set) var deceleration: Double = 80.0
    
}