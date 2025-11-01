import SwiftGodot

typealias Ray = (origin: Vector2, target: Vector2)

enum Z {

}
enum Magic {
    static let normalShotCooldown = 0.1
    static let bombsCooldown = 0.11
}

enum SubweaponType {
    case none
    case rocket
    case granade
    case smartBomb
    case flamethrower
}

// Order of execution: inputs -> state changes -> physics -> aiming -> animations -> shooting
@Godot
final class Player: CharacterBody2D {
    
    enum State {
        case idle
        case run
        case jump
        case wallGrab
        case crouch
        case dash
        case charge
        case hook
    }
    
    @Node("AnimatedSprite2D") weak var sprite: AnimatedSprite2D?
    @Node("CollisionShape2D") weak var collisionShape: CollisionShape2D?
    @Node("Hitbox2D") var hitbox: Hitbox2D?
    
    @Node("Weapons/MainWeapon") var mainWeapon: Weapon?
    @Node("Weapons/RocketLauncher") var rocketLauncher: Weapon?
    @Node("Weapons/GranadeLauncher") var granadeLauncher: Weapon?
    @Node("Weapons/SmartBomb") var smartBomb: Weapon?
    @Node("Weapons/Flamethrower") var flamethrower: Flamethrower?
    @Node("Weapons/DataMiner") var dataMiner: Weapon?
    
    @Node("Hookshot") var hookshot: Hookshot?

    @Node("Health") var hp: Health?
    @Node("Ammo") var ammo: Ammo?

    @Node("data") let data: PlayerData!
    @Node("input") let input: InputController

    @Export private(set) var runThreshold: Float = 6.0

    @Export private(set) var damageSpeed: Float = 500
    
    @Export var dashDistance: Int = 48
    @Export var dashSpeed: Float = 240
    @Export var dashTimeLimit: Double = 1.0
    
    @Export var hookLaunchSpeed: Float = 700

    @Export private(set) var size: Vector2 = .zero {
        didSet {
            (collisionShape?.shape as? RectangleShape2D)?.size = size
            collisionShape?.position = Vector2(x: 0, y: -size.y / 2)
            updateWallGrabRaycast()
        }
    }

    var lookDirection: Float = 1.0 {
        didSet {
            updateWallGrabRaycast()
        }
    }
    
    private let states: [State: PlayerState] = [
        .idle: IdleState(),
        .run: RunningState(),
        .jump: JumpingState(),
        .wallGrab: WallGrabState(),
        .crouch: CrouchState(),
        .dash: DashState(),
        .charge: ShinesparkState(),
        .hook: HookState()
    ]
    private(set) var currentState: State = .idle

    private let weaponCooldown = Cooldown()
    private var subweapon: Weapon?

    private(set) var joy1: Vector2 = .zero
    private(set) var joy2: Vector2 = .zero

    var aimPriority: Vector2 = .zero
    private(set) var shotOrigin: Vector2 = .zero
    private(set) var shotDirection: Vector2 = .zero
    private(set) var shotOffset: Vector2 = .zero

    private let hitTimer = GameTimer()
    private let invFramesTimer = GameTimer()
    
    private(set) var timeSinceLastAction: Double = 9999
    private(set) var timeSinceLastShot: Double = 69420

    var hasActedRecently: Bool {
        timeSinceLastAction < data.idleThresholdTime
    }

    var hasShotRecently: Bool {
        timeSinceLastShot < data.lastShotThresholdTime
    }

    private(set) var isAiming = false
    
    private(set) var isInWater = false
    private var lastFrameInWater = false

    private(set) var isMorphed = false

    private var isInvincible = false
    
    var isAffectedByWater: Bool {
        isInWater && !canUse(.waterMovement)
    }

    var overclockAccumulator: Double = 0.0

    var isOverclocking = false {
        didSet {
            floorSnapLength = isOverclocking ? 12 : 6
            self.modulate = isOverclocking ? Color.red : Color.white
            // if isSpeedBoosting { self.modulate = Color.red }
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

    private(set) var highRay: Ray = (.zero, .zero)
    private(set) var midRay: Ray = (.zero, .zero)
    private(set) var lowRay: Ray = (.zero, .zero)
    
    var wallJumpTimestamp: UInt = 0 // Using a timestamp here allows cheating
    
    var wallJumpThresholdMsec: Int {
        canUse(.betterWallGrab) ? data.wallIgnoreImprovedTimeMsec : data.wallIgnoreTimeMsec
    }

    var jumpDuration: Float {
        data.parabolicJumpDuration
    }

    var terminalVelocity: Float {
        return isAffectedByWater ? data.fallSpeedCap * 0.2 : data.fallSpeedCap
    }
    
    // TODO: water physics values
    var linearHeight: Float {   
        canUse(.highJump) ? data.baseJumpLinearHeight + data.superJumpExtraHeight : data.baseJumpLinearHeight
    }
    
    func getGravity() -> Float {
        8 * data.parabolicHeight / (jumpDuration * jumpDuration)
    }
    
    func getJumpspeed() -> Float {
        (2 * data.parabolicHeight * getGravity()).squareRoot()
    }
    
    func canUse(_ upgrade: Upgrades) -> Bool {
        data.upgradesObtained.contains(upgrade) && data.upgradesEnabled.contains(upgrade)
    }

    override func _ready() {
        guard data != nil else {
            logError("PlayerData node not found."); return
        }
        self.size = Vector2(from: data.bodySizeDefault)

        motionMode = .grounded
        floorConstantSpeed = true
        floorBlockOnWall = false
        slideOnCeiling = false // doesnt work on this movement model
        floorSnapLength = 6.0

        guard let sprite else { return }
        sprite.animationChanged.connect { [weak self] in
            self?.updateAimOffset()
        }
        sprite.frameChanged.connect { [weak self] in
            self?.updateAimOffset()
        }
        sprite.spriteFrames?.setAnimationLoop(anim: "stand-to-crouch", loop: false)

        setCollisionLayer(.player)
        addCollisionMask(.floor)
        hitbox?.setCollisionLayer(.player)
        hitbox?.collisionMask = 0 //
        hitbox?.addCollisionMask(.water)
        hitbox?.collisionMask |= 0b1000_0000_0000_0000

        hitbox?.onHit = { [weak self] damage in
            self?.takeHit(damage)
        }
        hitbox?.areaEntered.connect { [weak self] other in
            guard let self, let other else { return }
            if other.collisionLayer == 0b1000_0000_0000_0000 {
                self.enterLowGravity()
            }
        }
        hitbox?.areaExited.connect { [weak self] other in
            guard let self, let other else { return }
            if other.collisionLayer == 0b1000_0000_0000_0000 {
                self.exitLowGravity()
            }
        }

        hitTimer.isRepeating = false
        invFramesTimer.isRepeating = true

        hitTimer.onTimeout = { [weak self] in
            self?.hitTimeout()
        }
        invFramesTimer.onTimeout = { [weak self] in
            guard let sprite = self?.sprite else { return }
            sprite.visible = !sprite.visible
        }

        [
            mainWeapon,
            dataMiner,
            rocketLauncher,
            granadeLauncher,
            smartBomb,
            flamethrower,
        ].compactMap {$0}.forEach { 
            $0.ammo = ammo
            $0.cooldown = weaponCooldown 
        } 

        // ammo?.restore(ammo?.maxValue ?? 0)
        let maxAmmo = data.maxAmmo
        ammo?.maxValue = maxAmmo
        ammo?.restore(maxAmmo)

        let maxHp = data.maxHp
        hp?.maxValue = maxHp
        hp?.heal(maxHp)

        // mainWeapon = phaser
        switchSubweapon(.rocket) // check for weapon flags
        hookshot?.didHit.connect { [weak self] in
            self?.hookHit()
        }
        hookshot?.didHitHook.connect { [weak self] in
            self?.hookHitHook()
        }
        
        states[currentState]?.enter(self)
    }
    
    override func _physicsProcess(delta: Double) {
        // update all time-based stuff
        timeSinceLastAction += delta
        timeSinceLastShot += delta
        weaponCooldown.update(delta)
        hitTimer.update(delta)
        invFramesTimer.update(delta)

        joy1 = Vector2(x: input.getHorizontalAxis(), y: input.getVerticalAxis()).sign()
        joy2 = Vector2(x: input.getSecondaryHorizontalAxis(), y: input.getSecondaryVerticalAxis())

        takeAim()

        // this check is bad, no-actions still trigger the time
        if input.isActionPressed(.actionDown) || input.isActionPressed(.actionUp) || input.isActionPressed(.actionLeft) || input.isActionPressed(.actionRight) {
            timeSinceLastAction = 0.0
        }

        // process state
        if let newState = states[currentState]?.processInput(self) {
            if newState != currentState {
                currentState = newState
                states[currentState]?.enter(self)
            }
        }
        states[currentState]?.processPhysics(self, dt: delta)

        checkForWater()
        updateWaterWalkStatus()

        let faceDirection = velocity.sign().x
        if faceDirection != 0 && faceDirection != lookDirection {
            lookDirection = faceDirection
            sprite?.flipH = lookDirection < 0
        }

        if abs(joy2.x) > 0.5 || abs(joy2.y) > 0.5 {
            let angle = joy2.angle()
            if abs(angle) <= .pi / 4 { // right
                switchSubweapon(.granade)
            } else if angle > .pi / 4 && angle < 3 * .pi / 4 { // up
                switchSubweapon(.rocket)
            } else if abs(angle) >= 3 * .pi / 4 { // left
                switchSubweapon(.smartBomb)
            } else { // down, angle is 5π to 7π
                switchSubweapon(.flamethrower)
            }
        }

        if states[currentState]?.canFire == true {
            if canUse(.mines), isMorphed, let dataMiner {
                tryFire(dataMiner, pressing: .actionLeft)
            } else if let mainWeapon {
                tryFire(mainWeapon, pressing: .actionLeft)
            }
            if let subweapon {
                tryFire(subweapon, pressing: .actionUp)
            }
        }
        
        if input.isActionJustPressed(.actionRight) {
            hookshot?.origin = shotOrigin
            hookshot?.position = shotOrigin
            hookshot?.direction = shotDirection
            hookshot?.activate()
        }
    }

    func play(_ animation: PlayerAnimation) {
        sprite?.play(name: animation.rawValue)
    }

    func morph() {
        isMorphed = true
        self.size = Vector2(from: data.bodySizeMorphed)
        // if let hitboxRect = pHitbox?.shape as? RectangleShape2D {
        //     hitboxRect.size = Vector2(x: 14, y: 14)
        //     pHitbox?.position = Vector2(x: 0, y: -7)
        // }
    }

    func unmorph() {
        isMorphed = false
        self.size = Vector2(from: data.bodySizeDefault)
    }

    func expandHealth() {
        data.hpExpansions += 1
        let maxHp = data.maxHp
        hp?.maxValue = maxHp
        hp?.heal(maxHp)
    }

    func expandAmmo() {
        data.ammoExpansions += 1
        ammo?.maxValue = data.maxAmmo
        ammo?.restore(data.ammoPerExpansion)
    }

    func restoreHealth(_ amount: Int) {
        hp?.heal(amount)
    }

    func restoreAmmo(_ amount: Int) {
        ammo?.restore(amount)
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

    func takeHit(_ damage: Damage) {
        if damage.value.contains(.mines) {
            if isMorphed == true {
                velocity.y = Float(-(getJumpspeed() ?? 0.0))
            }
            return
        }

        guard !isInvincible else { return }
        isInvincible = true
        
        let xDirection: Float = (self.globalPosition - damage.origin).x < 0.0 ? -1.0 : 1.0
        
        takeDamage(damage.amount, xDirection: xDirection)
        
        invFramesTimer.start(time: 0.05)
        hitTimer.start(time: 1.0)
    }
    
    func takeDamage(_ amount: Int, xDirection: Float) {
        velocity.x = xDirection * damageSpeed * (isOnFloor() ? 1.0 : 0.7)
        hp?.damage(amount)
    }

    func hitTimeout() {
        invFramesTimer.stop()
        sprite?.visible = true
        isInvincible = false
    }
    
    func enterWater() {
        isInWater = true
    }
    
    func exitWater() {
        isInWater = false
    }

    func enterLowGravity() {
        // jumpDuration = 1.0
    }

    func exitLowGravity() {
        // jumpDuration = 0.5
    }

    // MARK: MOVEMENT FUNCTIONS

    func updateWaterWalkStatus() {
        if abs(getRealVelocity().x) > data.waterWalkingMinSpeed && !isInWater && canUse(.waterWalking) {
            addCollisionMask(.water)
        } else {
            removeCollisionMask(.water)
        }
    }

    func checkForWater() {
        guard let hitbox = hitbox else { return }
        for body in hitbox.getOverlappingBodies() {
            if let tilemap = body as? TileMapLayer, let tileset = tilemap.tileSet {
                var queryPosition = Vector2(x: position.x, y: position.y - 1)
                queryPosition -= tilemap.globalPosition
                let mapCoordinates = tilemap.localToMap(localPosition: queryPosition)
                if let tileData = tilemap.getCellTileData(coords: mapCoordinates) {
                    var tileCollisionLayer: UInt32 = 0
                    for physicsLayerIdx in 0..<tileset.getPhysicsLayersCount() { // ugly workaround to get tile's collision layer
                        if tileData.getCollisionPolygonsCount(layerId: physicsLayerIdx) > 0 {
                            tileCollisionLayer |= tileset.getPhysicsLayerCollisionLayer(layerIndex: physicsLayerIdx)
                        }
                    }
                    if LayerMask(rawValue: tileCollisionLayer).contains(.water) {
                        if !lastFrameInWater {
                            lastFrameInWater = true
                            enterWater()
                        }
                        return
                    }
                }
            }
        }
        if lastFrameInWater {
            lastFrameInWater = false
            exitWater()
        }
    }

    func updateHorizontalMovement(_ delta: Double) {
        var targetSpeed = data.movespeed * joy1.x
        if overclockAccumulator >= data.overclockThresholdTime && canUse(.overclock) {
            isOverclocking = true
        }
        if isOverclocking {
            targetSpeed *= data.overclockFactor
        }
        guard isOnFloor() || Time.getTicksMsec() - wallJumpTimestamp > wallJumpThresholdMsec else { 
            return
        }
        if joy1.x != 0.0 {
            if (velocity.x >= 0 && joy1.x > 0) || (velocity.x <= 0 && joy1.x < 0) { // joystick is aligned w/ movement
                if isOnFloor() && !isMorphed {
                    overclockAccumulator += delta
                }
                velocity.x = GD.moveToward(from: velocity.x, to: targetSpeed, delta: data.acceleration)
            } else {
                velocity.x = GD.moveToward(from: velocity.x, to: targetSpeed, delta: data.deceleration)
            }
        } else {
            let dampFactor = isOnFloor() ? 1.0 : data.airDampFactor
            velocity.x = GD.moveToward(from: velocity.x, to: 0, delta: data.deceleration * dampFactor)
        }
        if abs(getRealVelocity().x) < data.movespeed * 0.95 {
            overclockAccumulator = 0.0
            isOverclocking = false //
        }
    }

    func enforceVerticalSpeedCap() {
        if velocity.y > terminalVelocity {
            velocity.y = terminalVelocity
        }
    }
    
    // MARK: RAYCASTS & BOUNDARIES CHECKING

    func updateWallGrabRaycast() {
        guard let data else { return }
        
        let x0 = size.x * 0.5 * lookDirection
        let xf = (size.x * 0.5 + data.wallDetectionLength) * lookDirection
        
        highRay.origin.x = x0
        highRay.target.x = xf
        highRay.origin.y = -size.y + data.highRayOffsetY
        highRay.target.y = -size.y + data.highRayOffsetY
        
        midRay.origin.x = x0
        midRay.target.x = xf
        midRay.origin.y = -size.y / 2
        midRay.target.y = -size.y / 2
        
        lowRay.origin.x = x0
        lowRay.target.x = xf
        lowRay.origin.y = data.lowRayOffsetY
        lowRay.target.y = data.lowRayOffsetY
    }
    
    func raycastForWall() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        let resultLow = space.raycast(from: position + lowRay.origin, to: position + lowRay.target, mask: .floor)
        let resultMid = space.raycast(from: position + midRay.origin, to: position + midRay.target, mask: .floor)
        let resultHigh = space.raycast(from: position + highRay.origin, to: position + highRay.target, mask: .floor)
        let downRay = Vector2(x: 0, y: data.floorCheckLength)
        let resultDown = space.raycast(from: position, to: position + downRay, mask: .floor)
        if 
            resultLow["position"] != nil && 
            resultMid["position"] != nil && 
            resultHigh["position"] != nil && 
            resultDown["position"] == nil
        {
            return true
        }
        return false
    }
    
    func hasSpaceToUnmorph() -> Bool {
        guard let space = getWorld2d()?.directSpaceState else { return false }
        
        let morphSize = data.bodySizeMorphed
        let humanSize = data.bodySizeDefault
        
        let leftRay = Ray(
            origin: Vector2(x: -morphSize.x / 2, y: -morphSize.y), 
            target: Vector2(x: -humanSize.x / 2, y: -humanSize.y))
        let rightRay = Ray(
            origin: Vector2(x: morphSize.x / 2, y: -morphSize.y),
            target: Vector2(x: humanSize.x / 2, y: -humanSize.y))

        let resultLeft = space.raycast(from: position + leftRay.origin, to: position + leftRay.target, mask: .floor)
        let resultRight = space.raycast(from: position + rightRay.origin, to: position + rightRay.target, mask: .floor)

        if resultLeft["position"] == nil && resultRight["position"] == nil {
            return true
        }
        return false
    }
    
    // MARK: WEAPON FUNCTIONS
    
    func switchSubweapon(_ type: SubweaponType) {
        switch type {
        case .none: subweapon = nil
        case .rocket: subweapon = rocketLauncher
        case .granade: subweapon = granadeLauncher
        case .smartBomb: subweapon = smartBomb
        case .flamethrower: subweapon = flamethrower
        }
    }

    func tryFire(_ weapon: Weapon, pressing action: InputAction) {
        if weapon.trigger(isPressed: input.isActionPressed(action)) {
            timeSinceLastShot = 0.0
        }
    }
    
    // MARK: AIMING FUNCTIONS

    func takeAim() {
        isAiming = input.isActionPressed(.leftShoulder)
        if input.isActionJustPressed(.leftShoulder) {
            aimPriority.y = 1.0
        } else if input.isActionJustReleased(.leftShoulder) {
            aimPriority.y = 0.0
        }
        if !joy1.y.isZero { // toggle y
            aimPriority.y = joy1.sign().y
            if joy1.x.isZero {
                aimPriority.x = 0.0
            }
        }
        if !joy1.x.isZero { // toggle x
            aimPriority.x = 1.0
            if joy1.y.isZero && !isAiming {
                aimPriority.y = 0.0
            }
        }
    }
    
    func aimForward() {
        shotOrigin = Vector2(x: 14, y: -27)
        shotDirection = Vector2(x: lookDirection, y: 0).normalized()
    }
    
    func aimDiagonalUp() {
        shotOrigin = Vector2(x: 10, y: -36)
        shotDirection = Vector2(x: lookDirection, y: -1).normalized()
    }
    
    func aimDiagonalDown() {
        shotOrigin = Vector2(x: 11, y: -18)
        shotDirection = Vector2(x: lookDirection, y: 1).normalized()
    }
    
    func aimUp() {
        shotOrigin = Vector2(x: 2, y: -40)
        shotDirection = Vector2(x: 0, y: -1).normalized()
    }
    
    func aimDown() {
        shotOrigin = Vector2(x: 1, y: -12)
        shotDirection = Vector2(x: 0, y: 1).normalized()
    }
    
    func aimWallForward() {
        shotOrigin = Vector2(x: 23, y: -23)
        shotDirection = Vector2(x: lookDirection, y: 0).normalized()
    }

    func aimWallUp() {
        shotOrigin = Vector2(x: 19, y: -32)
        shotDirection = Vector2(x: lookDirection, y: -1).normalized()
    }
    
    func aimWallDown() {
        shotOrigin = Vector2(x: 19, y: -14)
        shotDirection = Vector2(x: lookDirection, y: 1).normalized()
    }
    
    func aimCrouchForward() {
        shotOrigin = Vector2(x: 14, y: -14)
        shotDirection = Vector2(x: lookDirection, y: 0).normalized()
    }
    
    func aimCrouchUp() {
        shotOrigin = Vector2(x: 10, y: -23)
        shotDirection = Vector2(x: lookDirection, y: -1).normalized()
    }

    func updateAimOffset() {
        guard let sprite else { shotOffset = .zero; return }
        let animationName = String(sprite.animation)
        if animationName.hasPrefix("run-aim") {
            let offset: Float = switch sprite.frame {
                case 0, 2, 5, 7: 1.0
                case 3, 8: 2.0
                case 4, 9: 3.0
                default: 0.0
            }
            shotOffset = Vector2(x: 0.0, y: offset)
            if animationName.hasSuffix("up") {
                shotOffset.x = 1.0
            }
        } else if sprite.animation == "jump-aim" {
            shotOffset = Vector2(x: 0.0, y: 1.0)
        } else if sprite.animation == "jump-aim-diag-up" {
            shotOffset = Vector2(x: 1.0, y: 1.0)
        } else if sprite.animation == "jump-aim-diag-down" {
            shotOffset = Vector2(x: 0.0, y: 1.0)
        } else {
            shotOffset = .zero
        }
    }
}

extension Player: MainWeaponDelegate {

    var hasMainWeapon: Bool {
        !data.upgradesObtained.intersection(data.upgradesEnabled).intersection(.allShots).isEmpty
    }
    
    func aimDirection() -> Vector2 {
        shotDirection
    }
    
    func firingPoint() -> Vector2 {
        var localOffset = shotOrigin + shotOffset
        localOffset.x *= lookDirection
        return globalPosition + localOffset
    }

    func getMomentum() -> Vector2 {
        if velocity.x != 0.0 { // sanity check because real velocity persists in non-moving states
            return Vector2(x: getRealVelocity().x, y: 0.0)
        }
        return .zero
    }
}