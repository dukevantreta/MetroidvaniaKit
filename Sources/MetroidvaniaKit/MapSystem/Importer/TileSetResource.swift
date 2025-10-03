import SwiftGodot

@Godot(.tool)
class TileSetResource: Resource {
    @Export var atlasName: String = ""
}