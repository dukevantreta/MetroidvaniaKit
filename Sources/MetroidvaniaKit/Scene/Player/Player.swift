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

@PickerNameProvider
enum WeaponType: Int {
    case normal
    case wave
    case plasma
}

extension Player: WeaponDelegate {
    
    func firingPoint() -> Vector2 {
        globalPosition + shotOrigin
    }
}

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
    
    @Node("CollisionShape2D") weak var collisionShape: CollisionShape2D?
    @Node("PlayerHitbox/CollisionShape2D") weak var hitbox: CollisionShape2D?
    @Node("AnimatedSprite2D") weak var sprite: AnimatedSprite2D?
    
    @Node("Weapons/MainWeapon") var mainWeapon: Weapon?
    @Node("Weapons/PowerBeam") var powerBeam: Weapon?
    @Node("Weapons/WaveBeam") var waveBeam: Weapon?
    @Node("Weapons/PlasmaBeam") var plasmaBeam: Weapon?
    @Node("Weapons/RocketLauncher") var rocketLauncher: Weapon?
    @Node("Weapons/GranadeLauncher") var granadeLauncher: Weapon?
    @Node("Weapons/SmartBomb") var smartBomb: Weapon?
    @Node("Weapons/Flamethrower") var flamethrower: Flamethrower?
    @Node("Weapons/DataMiner") var dataMiner: Weapon?
    
    @Node("Hookshot") var hookshot: Hookshot?
    @Node("Health") var hp: Health?
    @Node("Ammo") var ammo: Ammo?

    @Node("data") let data: PlayerData!
    
    @BindNode var input: InputController
    
    @Export(.range, "0,4,") var weaponLevel: Int = 0 {
        didSet {
            switchWeapons(weaponLevel)
        }
    }
    
    @Export(.enum) var weaponType: WeaponType = .normal

    @Export var damageSpeed: Float = 500
    
    @Export var idleAnimationThreshold: Int = 10000
    
    @Export var lastShotAnimationThreshold: Int = 3000
    
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
    
    let states: [State: PlayerState] = [
        .idle: IdleState(),
        .run: RunningState(),
        .jump: JumpingState(),
        .wallGrab: WallGrabState(),
        .crouch: CrouchState(),
        .dash: DashState(),
        .charge: ShinesparkState(),
        .hook: HookState()
    ]
    var currentState: State = .idle

    var joy1: Vector2 = .zero

    var weaponCooldown = Cooldown()
    
    var weapon: Weapon?
    
    var subweapon: Weapon?

    var hasMainWeapon: Bool {
        !data.upgradesObtained.intersection(data.upgradesEnabled).intersection(.allShots).isEmpty
    }

    private(set) var highRay: Ray = (.zero, .zero)
    private(set) var midRay: Ray = (.zero, .zero)
    private(set) var lowRay: Ray = (.zero, .zero)
    
    var lastShotTimestamp: UInt = 0
    
    var isAimingDown = false
    
    var isInWater = false

    private(set) var isMorphed = false
    
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
    
    private(set) var shotOrigin: Vector2 = .zero
    private(set) var shotDirection: Vector2 = .zero

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
        floorBlockOnWall = false
        slideOnCeiling = false // doesnt work on this movement model
        floorSnapLength = 6.0
        collisionLayer = 0
        collisionMask = 0b1011
        mainWeapon?.ammo = ammo
        mainWeapon?.cooldown = weaponCooldown
        [
            powerBeam,
            waveBeam,
            plasmaBeam,
            rocketLauncher,
            granadeLauncher,
            smartBomb,
            flamethrower,
        ].compactMap {$0}.forEach { $0.ammo = ammo; $0.cooldown = weaponCooldown } 
        dataMiner?.ammo = ammo
        dataMiner?.cooldown = weaponCooldown

        // ammo?.restore(ammo?.maxValue ?? 0)
        let maxAmmo = data.maxAmmo
        ammo?.maxValue = maxAmmo
        ammo?.restore(maxAmmo)

        let maxHp = data.maxHp
        hp?.maxValue = maxHp
        hp?.heal(maxHp)

        switchWeapons(weaponLevel)
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
        weaponCooldown.update(delta)

        joy1 = Vector2(x: input.getHorizontalAxis(), y: input.getVerticalAxis()).sign()
        let joy2 = Vector2(x: input.getSecondaryHorizontalAxis(), y: input.getSecondaryVerticalAxis())
        
        let faceDirX = velocity.sign().x
        if faceDirX != 0 && faceDirX != lookDirection {
            lookDirection = faceDirX
            sprite?.flipH = lookDirection < 0
        }

        updateWaterWalkStatus()
        
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
            } else if let weapon, hasMainWeapon {
                tryFire(weapon, pressing: .actionLeft)
            }
            if let subweapon {
                tryFire(subweapon, pressing: .actionUp)
            }
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

    func morph() {
        isMorphed = true
        self.size = Vector2(from: data.bodySizeMorphed)
        if let hitboxRect = hitbox?.shape as? RectangleShape2D {
            hitboxRect.size = Vector2(x: 14, y: 14)
            hitbox?.position = Vector2(x: 0, y: -7)
        }
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
        hp?.damage(amount)
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

    func layBomb() {
        // dataMiner?.fire(from: getParent()!, origin: self.position + Vector2(x: 0, y: -6), direction: .zero)
    }

    // MARK: MOVEMENT FUNCTIONS

    func updateWaterWalkStatus() {
        if velocity.x != 0.0 && !isInWater && canUse(.waterWalking) {
            addCollisionMask(.water)
        } else {
            removeCollisionMask(.water)
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
    
    func switchWeapons(_ level: Int) {
        // switch level {
        // case 0: weapon = nil
        // case 1: weapon = powerBeam
        // case 2: weapon = waveBeam
        // default: weapon = plasmaBeam
        // }
        weapon = mainWeapon
    }
    
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
            lastShotTimestamp = Time.getTicksMsec()
        }
    }
    
    // MARK: AIMING FUNCTIONS
    
    func aimForward() {
        shotOrigin = Vector2(x: 16 * lookDirection, y: -27)
        shotDirection = Vector2(x: lookDirection, y: 0).normalized()
    }
    
    func aimDiagonalUp() {
        shotOrigin = Vector2(x: 12 * lookDirection, y: -37)
        shotDirection = Vector2(x: lookDirection, y: -1).normalized()
    }
    
    func aimDiagonalDown() {
        shotOrigin = Vector2(x: 13 * lookDirection, y: -18)
        shotDirection = Vector2(x: lookDirection, y: 1).normalized()
    }
    
    func aimUp() {
        shotOrigin = Vector2(x: 4 * lookDirection, y: -42)
        shotDirection = Vector2(x: 0, y: -1).normalized()
    }
    
    func aimDown() {
        shotOrigin = Vector2(x: 0, y: -12)
        shotDirection = Vector2(x: 0, y: 1).normalized()
    }
    
    func aimWallUp() {
        shotOrigin = Vector2(x: 17 * lookDirection, y: -37)
        shotDirection = Vector2(x: lookDirection, y: -1).normalized()
    }
    
    func aimWallDown() {
        shotOrigin = Vector2(x: 17 * lookDirection, y: -18)
        shotDirection = Vector2(x: lookDirection, y: 1).normalized()
    }
    
    func aimCrouchForward() {
        shotOrigin = Vector2(x: 16 * lookDirection, y: -14)
        shotDirection = Vector2(x: lookDirection, y: 0).normalized()
    }
    
    func aimCrouchUp() {
        shotOrigin = Vector2(x: 13 * lookDirection, y: -24)
        shotDirection = Vector2(x: lookDirection, y: -1).normalized()
    }
}