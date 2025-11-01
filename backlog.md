# Backlog

### Player
- Fine-tune hitbox sizes on state changes.
    - Investigate collider rendering issue (centered vs top-left?).
- Reimplement beams as layers (like Super Metroid).
- Jump while overclocking must lock firing any weapons.
- Refine animations timings.
    - Keep frame index on switch between run & aim.
    - Add / fix jump begin, fall land, etc: transition anims.
- Make playing aiming animations consistent with 'has weapons' checks and last shot threshold.

### Camera
- Manually clamp camera movement to room bounds.
- Fix room transition, apply actions in the following order: 
    1. Lock: Align the camera's edges to the room matrix. (lateral axis)
    2. Translate position to next room. (dominant axis)
    3. Unlock: Smoothly adjust position back from alignment. (lateral axis)
- Experiment with forwarding the anchor point X as the player moves, to increase lookahead area (Metroid Dread does this).

### UI
- Change text align from center to left on labels that display from a strea of characters.

### Minor Details
- Bullet's hit effects position should align with collision point instead of bullet's current position.

### Bugs
- Fix item pick locking next pause screen.
    - Pause storage is breaking room transitions.

### Unknowns
- Evaluate the need of obsevability on cooldowns, to add callbacks for rendering UI indicators.