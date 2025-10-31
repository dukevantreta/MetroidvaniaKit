import SwiftGodot

enum PlayerAnimation: StringName {

    case idle = "idle-1"
    case idleAlt = "idle-3"
    case idleAim = "aim-idle"
    case idleAimUp = "aim-up"
    case idleAimDiagonalUp = "aim-diag-up"
    case idleAimDiagonalDown = "aim-diag-down"

    case run = "run"
    case runAim = "run-aim"
    case runAimDiagonalUp = "run-aim-up"
    case runAimDiagonalDown = "run-aim-down"

    case jumpStill = "jump-still"
    case jumpSpin = "jump-spin"
    case jumpAim = "jump-aim"
    case jumpAimUp = "jump-aim-up"
    case jumpAimDown = "jump-aim-down"
    case jumpAimDiagonalUp = "jump-aim-diag-up"
    case jumpAimDiagonalDown = "jump-aim-diag-down"

    case wallAim = "wall-aim"
    case wallAimUp = "wall-aim-up"
    case wallAimDown = "wall-aim-down"

    case standToCrouch = "stand-to-crouch"
    case crouchAim = "crouch-aim"
    case crouchAimDiagonalUp = "crouch-aim-up"

    case dash = "dash"

    case miniIdle = "mini-idle-1"
    case miniIdleAlt = "mini-idle-2"
    case miniRun = "mini-run"
    case miniJump = "mini-jump"
    case miniJumpSpin = "mini-jump-spin"
    case miniWall = "mini-wall"
    case miniDash = "mini-dash"
}