import SwiftGodot

@Godot
class BreakableBlock: Node2D {
    
//    @SceneTree(path: "StaticBody2D") var body: PhysicsBody2D?
    @SceneTree(path: "Area2D") weak var area: Area2D?
//    @SceneTree(path: "RigidBody2D") var body: RigidBody2D?
    
    override func _ready() {
        guard let area else {
            log("COLLISION NOT FOUND")
            return
        }
        
        area.collisionMask |= 0b1_0000_0000
//        body.collisionMask |= 0b1_0000_0000
//        
//        body.contactMonitor = true
//        body.maxContactsReported = 9
        
//        area.bodyEntered.connect { [weak self] body in
//            
//        }
        area.bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
            if layer & 0b1_0000_0000 != 0 {
                if let player = body as? PlayerNode {
//                    self?.queueFree()
                }
            }
        }
        
//        body.bodyShapeEntered.connect { [weak self] bodyRid, body, bodyShapeIndex, localShapeIndex in
//            let layer = PhysicsServer2D.bodyGetCollisionLayer(body: bodyRid)
//            if layer & 0b1_0000_0000 != 0 {
//                GD.print("BODY COLLISION")
//            }
//        }
    }
    
    func destroy() {
        self.queueFree()
    }
}
