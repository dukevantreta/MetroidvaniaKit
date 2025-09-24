import SwiftGodot

struct LayerMask: OptionSet {
    
    let rawValue: UInt32
    
    static let floor      = LayerMask(rawValue: 1 << 0)
    static let block      = 0b0010
    static let water      = 0b0100
    static let hazard     = 0b1000
    static let projectile = 0b0001_0000
    static let enemy      = LayerMask(rawValue: 1 << 5)
    static let player     = LayerMask(rawValue: 1 << 8)
}

extension CollisionObject2D {
    
    func setCollisionLayer(_ mask: LayerMask) {
        self.collisionLayer = mask.rawValue
    }
    
    func addCollisionMask(_ mask: LayerMask) {
        self.collisionMask |= mask.rawValue
    }
}

enum SubweaponType {
    case none
    case rocket
    case granade
    case smartBomb
}

@PickerNameProvider
enum WeaponType: Int {
    case normal
    case wave
    case plasma
}

@Godot
class PlayerNode: CharacterBody2D {
    
    enum State {
        case idle
        case run
        case jump
        case wallGrab
        case crouch
        case morph
        case dash
        case charge
        case hook
    }
    
    @Node("CollisionShape2D") weak var collisionShape: CollisionShape2D?
    @Node("PlayerHitbox/CollisionShape2D") weak var hitbox: CollisionShape2D?
    @Node("AnimatedSprite2D") weak var sprite: AnimatedSprite2D?
    
    @Node("Weapons/PowerBeam") var powerBeam: WeaponNode?
    @Node("Weapons/WaveBeam") var waveBeam: WeaponNode?
    @Node("Weapons/PlasmaBeam") var plasmaBeam: WeaponNode?
    @Node("Weapons/RocketLauncher") var rocketLauncher: WeaponNode?
    @Node("Weapons/GranadeLauncher") var granadeLauncher: WeaponNode?
    @Node("Weapons/SmartBomb") var smartBomb: WeaponNode?
    
    @Node("Hookshot") var hookshot: Hookshot?
    @Node("Ammo") var ammo: Ammo?
    
    @BindNode var stats: PlayerStats
    @BindNode var input: InputController
    
    @Export(.range, "0,4,") var weaponLevel: Int = 0 {
        didSet {
            switchWeapons(weaponLevel)
        }
    }
    
    @Export(.enum) var weaponType: WeaponType = .normal
    
    @Export
    var speed: Double = 180.0
    @Export
    var acceleration: Double = 10.0
    @Export
    var deceleration: Double = 80.0
    
    @Export var damageSpeed: Float = 500
    
    @Export var allowJumpSensitivity: Bool = true
    
    @Export var jumpDuration: Double = 0.5
    
    /// Height up to where gravity is ignored if the player holds the jump button
    var linearHeight: Double {
        stats.hasSuperJump ? 52 : 20
    }
    
    /// Jump height affected by gravity, after ignore range. Total jump height is the sum of both.
    @Export var parabolicHeight: Double = 48
    
    @Export var terminalVelocityFactor: Float = 1.3
    
    @Export var airTime: Double = 0
    
    var wallJumpThresholdMsec: Int {
        stats.hasWallGrabUpgrade ? 100 : 500
    }
    
    @Export var speedBoostThreshold: Int = 3000
    
    @Export var idleAnimationThreshold: Int = 10000
    
    @Export var lastShotAnimationThreshold: Int = 3000
    
    @Export var dashDistance: Int = 48
    
    @Export var dashSpeed: Float = 240
    
    @Export var dashTimeLimit: Double = 1.0
    
    @Export var hookLaunchSpeed: Float = 700
    
    let states: [State: PlayerState] = [
        .idle: IdleState(),
        .run: RunningState(),
        .jump: JumpingState(),
        .wallGrab: WallGrabState(),
        .crouch: CrouchState(),
        .morph: MorphState(),
        .dash: DashState(),
        .charge: ShinesparkState(),
        .hook: HookState()
    ]
    var currentState: State = .idle
    
    var xDirection: Double = 0.0
    var yDirection: Double = 0.0
    
    var weapon: WeaponNode?
    
    var subweapon: WeaponNode?
    
    var facingDirection: Int = 1
    
    var canDoubleJump = true
    
    var wallJumpTimestamp: UInt = 0
    
    var lastShotTimestamp: UInt = 0
    
    var isAimingDown = false
    
    var isInWater = false
    
    var isAffectedByWater: Bool {
        isInWater && !stats.hasWaterMovement
    }
    
    var isSpeedBoosting = false {
        didSet {
            floorSnapLength = isSpeedBoosting ? 12 : 6
            self.modulate = isSpeedBoosting ? Color.red : Color.white
        }
    }
    
    var hasShinesparkCharge = false {
        didSet {
            if hasShinesparkCharge {
                log("STORED SHINESPARK")
            }
            self.modulate = hasShinesparkCharge ? Color.blue : Color.white
        }
    }
    
    var shotOrigin: Vector2 = .zero
    var shotDirection: Vector2 = .zero
    
    func getGravity() -> Double {
        8 * parabolicHeight / (jumpDuration * jumpDuration)
    }
    
    func getJumpspeed() -> Double {
        (2 * parabolicHeight * getGravity()).squareRoot()
    }
    
    func getCollisionRectSize() -> Vector2? {
        (collisionShape?.shape as? RectangleShape2D)?.size
    }
    
    override func _ready() {
        motionMode = .grounded
        floorBlockOnWall = false
        slideOnCeiling = false // doesnt work on this movement model
        floorSnapLength = 6.0
        collisionLayer = 0
        collisionMask = 0b1011
        [
            powerBeam,
            waveBeam,
            plasmaBeam,
            rocketLauncher,
            granadeLauncher,
            smartBomb
        ].compactMap {$0}.forEach { $0.ammo = ammo } 

        switchWeapons(weaponLevel)
        switchSubweapon(.smartBomb) // check for weapon flags
        hookshot?.didHit.connect { [weak self] in
            self?.hookHit()
        }
        hookshot?.didHitHook.connect { [weak self] in
            self?.hookHitHook()
        }
        
        states[currentState]?.enter(self)
    }
    
    override func _physicsProcess(delta: Double) {
        xDirection = input.getHorizontalAxis()
        yDirection = input.getVerticalAxis()
        
        let faceDirX = Int(velocity.sign().x)
        if faceDirX != 0 && faceDirX != facingDirection {
            facingDirection = faceDirX
            sprite?.flipH = facingDirection < 0
        }
        
        if input.isActionPressed(.rightShoulder) && !isInWater && stats.hasWaterWalking {
            collisionMask |= 0b0100
        } else {
            collisionMask = 0b1011
        }
        
        if let newState = states[currentState]?.processInput(self) {
            if newState != currentState {
                currentState = newState
                states[currentState]?.enter(self)
            }
        }
        states[currentState]?.processPhysics(self, dt: delta)
        
        if input.isActionJustPressed(.actionRight) {
            hookshot?.origin = shotOrigin
            hookshot?.position = shotOrigin
            hookshot?.direction = shotDirection
            hookshot?.activate()
        }
    }
    
    func hookHitHook() {
        currentState = .hook
//        let direction = hookshot?.direction ?? .zero
//        if direction.y.isZero {
//            velocity.y = -300
//        } else {
//            velocity.y = direction.y * hookLaunchSpeed
//        }
//        velocity.x = direction.x * hookLaunchSpeed
        
        states[currentState]?.enter(self)
    }
    
    func hookHit() {
        currentState = .hook
        let direction = hookshot?.direction ?? .zero
        velocity.x = direction.x * 500
        velocity.y = direction.y * 500
        states[currentState]?.enter(self)
    }
    
    func takeDamage(_ amount: Int, xDirection: Float) {
        velocity.x = xDirection * damageSpeed * (isOnFloor() ? 1.0 : 0.7)
        stats.hp -= amount
        if stats.hp <= 0 {
            log("GAME OVER") // try to use hp change signal to trigger game over
        }
    }
    
    func enterWater() {
        isInWater = true
    }
    
    func exitWater() {
        isInWater = false
    }
    
    // MARK: RAYCASTS
    
    func raycastForWall() -> Bool {
        guard let size = getCollisionRectSize(), let space = getWorld2d()?.directSpaceState else { return false }
        
        // I have no idea why this hack is needed
        // Left wall grab stopped working after a map importer update, this fixes it
        let correctionFactor: Float = facingDirection < 0 ? 2.0 : 1.0
        
        let origin1 = position + Vector2(x: 0, y: -1)
        let dest1 = origin1 + Vector2(x: (size.x * 0.5 + correctionFactor) * Float(facingDirection), y: 0)
        let ray1 = PhysicsRayQueryParameters2D.create(from: origin1, to: dest1, collisionMask: 0b0001)
        
        let origin2 = position + Vector2(x: 0, y: -size.y)
        let dest2 = origin2 + Vector2(x: (size.x * 0.5 + correctionFactor) * Float(facingDirection), y: 0)
        let ray2 = PhysicsRayQueryParameters2D.create(from: origin2, to: dest2, collisionMask: 0b0001)
        
        let result1 = space.intersectRay(parameters: ray1)
        let result2 = space.intersectRay(parameters: ray2)
        
        if
            let point1 = result1["position"],
            let point2 = result2["position"]
        {
            return true
        }
        return false
    }
    
    func raycastForUnmorph() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        
        let origin1 = position + Vector2(x: -7, y: -14)
        let dest1 = origin1 + Vector2(x: 0, y: -16)
        let ray1 = PhysicsRayQueryParameters2D.create(from: origin1, to: dest1, collisionMask: 0b0001)
        
        let origin2 = position + Vector2(x: 6, y: -14)
        let dest2 = origin2 + Vector2(x: 0, y: -16)
        let ray2 = PhysicsRayQueryParameters2D.create(from: origin2, to: dest2, collisionMask: 0b0001)
        
        let result1 = space.intersectRay(parameters: ray1)
        let result2 = space.intersectRay(parameters: ray2)
        if result1["position"] != nil || result2["position"] != nil {
            return true
        }
        return false
    }
    
    // MARK: WEAPON FUNCTIONS
    
    func switchWeapons(_ level: Int) {
        switch level {
        case 0: weapon = nil
        case 1: weapon = powerBeam
        case 2: weapon = waveBeam
        default: weapon = plasmaBeam
        }
    }
    
    func switchSubweapon(_ type: SubweaponType) {
        switch type {
        case .none: subweapon = nil
        case .rocket: subweapon = rocketLauncher
        case .granade: subweapon = granadeLauncher
        case .smartBomb: subweapon = smartBomb
        }
    }
    
    @discardableResult
    func fire() -> Bool {
        guard let weapon, let parent = getParent() else { return false }
        if weapon.autofire {
            if input.isActionPressed(.actionLeft) {
                weapon.fire(from: parent, origin: self.position + shotOrigin, direction: shotDirection) 
                lastShotTimestamp = Time.getTicksMsec()
                return true
            }
        } else {
            if input.isActionJustPressed(.actionLeft) {
                weapon.fire(from: parent, origin: self.position + shotOrigin, direction: shotDirection) 
                lastShotTimestamp = Time.getTicksMsec()
                return true
            }
        }
        return false
    }
    
    @discardableResult
    func fireSubweapon() -> Bool {
        guard let subweapon, let parent = getParent() else { return false }
        if subweapon.autofire {
            if input.isActionPressed(.actionUp) {
                subweapon.fire(from: parent, origin: self.position + shotOrigin, direction: shotDirection) 
                lastShotTimestamp = Time.getTicksMsec()
                return true
            }
        } else {
            if input.isActionJustPressed(.actionUp) {
                subweapon.fire(from: parent, origin: self.position + shotOrigin, direction: shotDirection) 
                lastShotTimestamp = Time.getTicksMsec()
                return true
            }
        }
        return false
    }
    
    // MARK: AIMING FUNCTIONS
    
    func aimForward() {
        shotOrigin = Vector2(x: Float(16 * facingDirection), y: -27)
        shotDirection = Vector2(x: facingDirection, y: 0).normalized()
    }
    
    func aimDiagonalUp() {
        shotOrigin = Vector2(x: Float(12 * facingDirection), y: -37)
        shotDirection = Vector2(x: facingDirection, y: -1).normalized()
    }
    
    func aimDiagonalDown() {
        shotOrigin = Vector2(x: Float(13 * facingDirection), y: -18)
        shotDirection = Vector2(x: facingDirection, y: 1).normalized()
    }
    
    func aimUp() {
        shotOrigin = Vector2(x: Float(4 * facingDirection), y: -42)
        shotDirection = Vector2(x: 0, y: -1).normalized()
    }
    
    func aimDown() {
        shotOrigin = Vector2(x: 0, y: -12)
        shotDirection = Vector2(x: 0, y: 1).normalized()
    }
    
    func aimWallUp() {
        shotOrigin = Vector2(x: Float(17 * facingDirection), y: -37)
        shotDirection = Vector2(x: facingDirection, y: -1).normalized()
    }
    
    func aimWallDown() {
        shotOrigin = Vector2(x: Float(17 * facingDirection), y: -18)
        shotDirection = Vector2(x: facingDirection, y: 1).normalized()
    }
    
    func aimCrouchForward() {
        shotOrigin = Vector2(x: Float(16 * facingDirection), y: -14)
        shotDirection = Vector2(x: facingDirection, y: 0).normalized()
    }
    
    func aimCrouchUp() {
        shotOrigin = Vector2(x: Float(13 * facingDirection), y: -24)
        shotDirection = Vector2(x: facingDirection, y: -1).normalized()
    }
    
    // MARK: DEBUG
    
    override func _process(delta: Double) {
        queueRedraw()
    }
    
    override func _draw() {
        let origin = Vector2(x: 0, y: -14)
        let v = velocity * 0.1
        drawLine(from: origin, to: origin + v, color: .blue)
        drawLine(from: origin, to: origin + Vector2(x: v.x, y: 0), color: .red)
        drawLine(from: origin, to: origin + Vector2(x: 0, y: v.y), color: .green)
        
        let size = getCollisionRectSize() ?? .zero
        
        let rayOrigin1 = Vector2(x: 0, y: -1)
        let rayDest1 = Vector2(x: rayOrigin1.x + (size.x * 0.5 + 1) * Float(facingDirection), y: rayOrigin1.y)
        drawLine(from: rayOrigin1, to: rayDest1, color: .magenta)
        
        let rayOrigin2 = Vector2(x: 0, y: -size.y)
        let rayDest2 = Vector2(x: rayOrigin2.x + (size.x * 0.5 + 1) * Float(facingDirection), y: rayOrigin2.y)
        drawLine(from: rayOrigin2, to: rayDest2, color: .magenta)
        
        let shotRegion = Rect2(x: shotOrigin.x - 1, y: shotOrigin.y - 1, width: 3, height: 3)
        drawRect(shotRegion, color: .red)
    }
}
