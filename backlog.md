# Backlog

### Player
- Increase distance between wall grab raycasts to more than 2 tiles (avoids step-grab).
- Add a 3rd raycast in the middle.
- Fine-tune collider sizes on state changes, adjust sprites & animations.
    - Investigate collider rendering issue (centered vs top-left?).
- Reimplement beams as layers (like Super Metroid).

### Camera
- Manually clamp camera movement to room bounds.
- Fix room transition, apply actions in the following order: 
    1. Lock: Align the camera's edges to the room matrix. (lateral axis)
    2. Translate position to next room. (dominant axis)
    3. Unlock: Smoothly adjust position back from alignment. (lateral axis)
- Experiment with forwarding the anchor point X as the player moves, to increase lookahead area (Metroid Dread does this).

### UI
- Change text align from center to left on labels that display from a strea of characters.

### Unknowns
- Evaluate the need of obsevability on cooldowns, to add callbacks for rendering UI indicators.