import SwiftGodot

@Godot
class Hookshot: Area2D {
    
    @Signal var didHit: SimpleSignal
    @Signal var didHitHook: SimpleSignal
    
    @Export var range: Double = 160
    
    var direction: Vector2 = .zero
    var origin: Vector2 = .zero
    
    var isReturning = false
    
    private var lock = false
    private var active = false
    
    override func _ready() {
        
        collisionLayer = 0b00_0001_0000
        collisionMask |= 0b1000_0011
        
        monitoring = false
        
        visible = false
        
        bodyEntered.connect { [weak self] body in
            self?.hit()
        }
        areaEntered.connect { [weak self] area in
            guard let area else { return }
            if area.collisionLayer & 0b1000_0000 != 0 {
                self?.hitHook()
            }
        }
    }
    
    override func _physicsProcess(delta: Double) {
        guard active else { return }
        if lock { return }
        if !isReturning {
            position.x += direction.x * 700 * Float(delta)
            position.y += direction.y * 700 * Float(delta)
            
            if (position - origin).length() > range {
                isReturning = true
            }
        } else {
            let deltaMove = Vector2(
                x: abs(direction.x * 700 * Float(delta)),
                y: abs(direction.y * 700 * Float(delta))
            )
            position.x = Float(GD.moveToward(from: Double(position.x), to: Double(origin.x), delta: Double(deltaMove.x)))
            position.y = Float(GD.moveToward(from: Double(position.y), to: Double(origin.x), delta: Double(deltaMove.y)))
            if (position - origin).length() < 5 {
                deactivate()
            }
        }
    }
    
    func hitHook() {
        lock = true
        active = false
        self.setDeferred(property: "monitoring", value: Variant(false))
        didHitHook.emit()
        visible = false
    }
    
    func hit() {
        lock = true
        active = false
        self.setDeferred(property: "monitoring", value: Variant(false))
        didHit.emit()
    }
    
    func activate() {
        lock = false
        isReturning = false
        active = true
        self.setDeferred(property: "monitoring", value: Variant(true))
        visible = true
    }
    
    func deactivate() {
        active = false
        self.setDeferred(property: "monitoring", value: Variant(false))
        visible = false
    }
}
