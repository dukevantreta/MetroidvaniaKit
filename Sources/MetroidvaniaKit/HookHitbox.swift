import SwiftGodot

@Godot
@NativeHandleDiscarding
class HookHitbox: Area2D {
    
    weak var player: CharacterController2D?
    
    var direction: Int = 1
    
    var range: Float = 150
    
    var isReturning = false
    
    var lock = false
    
    private var collisionToken: Object?
    
//    required init(nativeHandle: UnsafeRawPointer) {
//        super.init(nativeHandle: nativeHandle)
//    }
    
    required init(_ context: InitContext) {
        super.init(context)
        
        collisionMask |= 0b00000001
        collisionMask |= 0b00000010
        collisionMask |= 0b00001000
        
        let texture = PlaceholderTexture2D()
        texture.size = Vector2(x: 8, y: 8)
        let sprite = Sprite2D()
        sprite.texture = texture
        addChild(node: sprite)
        
        let rectShape = RectangleShape2D()
        rectShape.size.x = 8
        rectShape.size.y = 8
        let collisionShape = CollisionShape2D()
        collisionShape.shape = rectShape
        addChild(node: collisionShape)
        
//        collisionToken =
        bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
            if layer & 0b01 != 0 {
                self?.hitWall()
            }
        }
    }
    
//    required init(_ context: InitContext) {
//        fatalError("init(_:) has not been implemented")
//    }
    
//    override func _ready() {
//        
//    }
    
    override func _physicsProcess(delta: Double) {
        if lock {
            return
        }
        if !isReturning {
            position.x += 900 * Float(direction) * Float(delta)
            if abs(position.x) > range {
                isReturning = true
            }
        } else {
            var xDelta = 900 * Float(direction) * Float(delta)
            if direction == -1 {
                xDelta = -xDelta
            }
            let xPos = GD.moveToward(from: Double(position.x), to: 0, delta: Double(xDelta))
            position.x = Float(xPos)
            if abs(position.x) < 1 {
                queueFree()
            }
        }
    }
    
    func hitWall() {
        guard let collisionToken else { return }
//        bodyShapeEntered.disconnect(collisionToken)
//        GD.print("HOOK HIT WALL")
//        queueFree()
        lock = true
        player?.hookshot()
    }
    
    func destroy() {
        queueFree()
    }
    
    deinit {
        GD.print("HOOK DEINIT")
    }
}
