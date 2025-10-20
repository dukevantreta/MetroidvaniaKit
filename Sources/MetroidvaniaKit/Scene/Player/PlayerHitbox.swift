import SwiftGodot

@Godot
class PlayerHitbox: Area2D {
    
    @Node("..") weak var player: Player?
    @Node("../Hitbox") weak var hitbox: Hitbox?
    
    private let hitTimer = Timer()
    private let invFramesTimer = Timer()
    
    private var isInvincible = false
    
    private var lastFrameInWater = false
    
    override func _ready() {
        guard let player else {
            logError("PLAYER NOT FOUND")
            return
        }
        
        self.collisionLayer = 0
        collisionMask |= 0b00000100
        hitbox?.collisionLayer = 0b1_0000_0000
      
        // Hit cooldown timer
        hitTimer.autostart = false
        hitTimer.oneShot = true
        hitTimer.timeout.connect { [weak self] in
            self?.hitTimeout()
        }
        addChild(node: hitTimer)
        
        // Invincible frames toggle timer
        invFramesTimer.autostart = false
        invFramesTimer.oneShot = false
        invFramesTimer.timeout.connect { [weak self] in
            guard let sprite = self?.player?.sprite else { return }
            sprite.visible = !sprite.visible
        }
        addChild(node: invFramesTimer)
        
        hitbox?.onHit = { [weak self] damage in
            self?.takeHit(damage)
        }
    }
    
    override func _process(delta: Double) {
        guard var playerPosition = player?.position else { return }
        checkForWater(at: playerPosition)
    }
    
    func checkForWater(at playerPosition: Vector2) {
        for body in getOverlappingBodies() {
            if let tilemap = body as? TileMapLayer, let tileset = tilemap.tileSet {
                var queryPosition = Vector2(x: playerPosition.x, y: playerPosition.y - 1)
                queryPosition -= tilemap.globalPosition
                let mapCoordinates = tilemap.localToMap(localPosition: queryPosition)
                if let tileData = tilemap.getCellTileData(coords: mapCoordinates) {
                    var tileCollisionLayer: UInt32 = 0
                    for physicsLayerIdx in 0..<tileset.getPhysicsLayersCount() { // ugly workaround to get tile's collision layer
                        if tileData.getCollisionPolygonsCount(layerId: physicsLayerIdx) > 0 {
                            tileCollisionLayer |= tileset.getPhysicsLayerCollisionLayer(layerIndex: physicsLayerIdx)
                        }
                    }
                    if tileCollisionLayer & 0b0000_0100 != 0 { // is in water
                        if !lastFrameInWater {
                            lastFrameInWater = true
                            player?.enterWater()
                        }
                        return
                    }
                }
            }
        }
        if lastFrameInWater {
            lastFrameInWater = false
            player?.exitWater()
        }
    }
    
    func takeHit(_ damage: Damage) {
        if damage.source == .bomb {
            if player?.currentState == .morph {
                player?.velocity.y = Float(-(player?.getJumpspeed() ?? 0.0))
            }
            return
        }

        guard !isInvincible else { return }
        isInvincible = true
        
        let xDirection: Float = (self.globalPosition - damage.origin).x < 0.0 ? -1.0 : 1.0
        
        player?.takeDamage(damage.amount, xDirection: xDirection)
        
        invFramesTimer.start(timeSec: 0.05)
        hitTimer.start(timeSec: 1.0)
    }
    
    func takeHit(_ damage: Int, xDirection: Float) {
        guard !isInvincible else { return }
        isInvincible = true
        
        player?.takeDamage(damage, xDirection: xDirection)
        
        invFramesTimer.start(timeSec: 0.05)
        hitTimer.start(timeSec: 1.0)
    }
    
    func hitTimeout() {
        invFramesTimer.stop()
        player?.sprite?.visible = true
        isInvincible = false
    }

    func restoreHealth(_ amount: Int) {
        player?.hp?.heal(amount)
    }

    func restoreAmmo(_ amount: Int) {
        player?.ammo?.restore(amount)
    }
}
