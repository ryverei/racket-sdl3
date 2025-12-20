# Joystick & Gamepad Implementation Plan

This document outlines the implementation plan for adding joystick and gamepad support to racket-sdl3.

## Overview

SDL3 provides two levels of controller input:

1. **Joystick API** - Low-level, generic interface treating devices as arbitrary buttons, axes, and hats
2. **Gamepad API** - High-level, standardized interface mapping devices to a console-style controller layout (d-pad, face buttons, triggers, etc.)

Most games should use the **Gamepad API** since it provides consistent button names across devices. The Joystick API is useful for custom configuration UIs or unsupported devices.

## Implementation Phases

### Phase 1: Core Types & Constants

Add to `private/types.rkt` and `private/constants.rkt`:

**Pointer Types:**
- `_SDL_Joystick-pointer`
- `_SDL_Gamepad-pointer`

**Joystick Types:**
- `_SDL_JoystickID` (Uint32)
- `_SDL_JoystickType` enum (UNKNOWN, GAMEPAD, WHEEL, ARCADE_STICK, FLIGHT_STICK, DANCE_PAD, GUITAR, DRUM_KIT, ARCADE_PAD, THROTTLE)
- `_SDL_JoystickConnectionState` enum (INVALID, UNKNOWN, WIRED, WIRELESS)

**Gamepad Types:**
- `_SDL_GamepadType` enum (UNKNOWN, STANDARD, XBOX360, XBOXONE, PS3, PS4, PS5, NINTENDO_SWITCH_PRO, etc.)
- `_SDL_GamepadButton` enum (SOUTH, EAST, WEST, NORTH, BACK, GUIDE, START, LEFT_STICK, RIGHT_STICK, shoulders, d-pad, paddles, touchpad, misc)
- `_SDL_GamepadAxis` enum (LEFTX, LEFTY, RIGHTX, RIGHTY, LEFT_TRIGGER, RIGHT_TRIGGER)
- `_SDL_GamepadButtonLabel` enum (A, B, X, Y, CROSS, CIRCLE, SQUARE, TRIANGLE)

**Hat Constants:**
- `SDL_HAT_CENTERED`, `SDL_HAT_UP`, `SDL_HAT_RIGHT`, `SDL_HAT_DOWN`, `SDL_HAT_LEFT`
- `SDL_HAT_RIGHTUP`, `SDL_HAT_RIGHTDOWN`, `SDL_HAT_LEFTUP`, `SDL_HAT_LEFTDOWN`

**Init Flag:**
- `SDL_INIT_JOYSTICK` (includes gamepad support)

### Phase 2: Event Types

Add to `private/constants.rkt`:

**Joystick Events:**
- `SDL_EVENT_JOYSTICK_AXIS_MOTION` (#x600)
- `SDL_EVENT_JOYSTICK_BALL_MOTION`
- `SDL_EVENT_JOYSTICK_HAT_MOTION`
- `SDL_EVENT_JOYSTICK_BUTTON_DOWN`
- `SDL_EVENT_JOYSTICK_BUTTON_UP`
- `SDL_EVENT_JOYSTICK_ADDED`
- `SDL_EVENT_JOYSTICK_REMOVED`
- `SDL_EVENT_JOYSTICK_BATTERY_UPDATED`

**Gamepad Events:**
- `SDL_EVENT_GAMEPAD_AXIS_MOTION` (#x650)
- `SDL_EVENT_GAMEPAD_BUTTON_DOWN`
- `SDL_EVENT_GAMEPAD_BUTTON_UP`
- `SDL_EVENT_GAMEPAD_ADDED`
- `SDL_EVENT_GAMEPAD_REMOVED`
- `SDL_EVENT_GAMEPAD_REMAPPED`
- `SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN`
- `SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION`
- `SDL_EVENT_GAMEPAD_TOUCHPAD_UP`
- `SDL_EVENT_GAMEPAD_SENSOR_UPDATE`

Add to `private/types.rkt`:

**Event Structs:**
```racket
;; SDL_JoyAxisEvent - 20 bytes
(define-cstruct _SDL_JoyAxisEvent
  ([type _uint32]
   [reserved _uint32]
   [timestamp _uint64]
   [which _uint32]      ; SDL_JoystickID
   [axis _uint8]
   [padding1 _uint8]
   [padding2 _uint8]
   [padding3 _uint8]
   [value _sint16]
   [padding4 _uint16]))

;; SDL_JoyButtonEvent - 16 bytes
(define-cstruct _SDL_JoyButtonEvent
  ([type _uint32]
   [reserved _uint32]
   [timestamp _uint64]
   [which _uint32]
   [button _uint8]
   [down _bool]
   [padding1 _uint8]
   [padding2 _uint8]))

;; SDL_JoyHatEvent - 16 bytes
(define-cstruct _SDL_JoyHatEvent
  ([type _uint32]
   [reserved _uint32]
   [timestamp _uint64]
   [which _uint32]
   [hat _uint8]
   [value _uint8]
   [padding1 _uint8]
   [padding2 _uint8]))

;; SDL_JoyDeviceEvent - 16 bytes
(define-cstruct _SDL_JoyDeviceEvent
  ([type _uint32]
   [reserved _uint32]
   [timestamp _uint64]
   [which _uint32]))

;; SDL_GamepadAxisEvent - 20 bytes (same layout as JoyAxisEvent)
(define-cstruct _SDL_GamepadAxisEvent
  ([type _uint32]
   [reserved _uint32]
   [timestamp _uint64]
   [which _uint32]
   [axis _uint8]        ; SDL_GamepadAxis
   [padding1 _uint8]
   [padding2 _uint8]
   [padding3 _uint8]
   [value _sint16]
   [padding4 _uint16]))

;; SDL_GamepadButtonEvent - 16 bytes
(define-cstruct _SDL_GamepadButtonEvent
  ([type _uint32]
   [reserved _uint32]
   [timestamp _uint64]
   [which _uint32]
   [button _uint8]      ; SDL_GamepadButton
   [down _bool]
   [padding1 _uint8]
   [padding2 _uint8]))

;; SDL_GamepadDeviceEvent - 16 bytes
(define-cstruct _SDL_GamepadDeviceEvent
  ([type _uint32]
   [reserved _uint32]
   [timestamp _uint64]
   [which _uint32]))
```

### Phase 3: Raw Joystick Bindings

Create `raw/joystick.rkt`:

**Core Functions (Priority 1):**
```racket
;; Detection
(define-sdl SDL-HasJoystick (_fun -> _bool))
(define-sdl SDL-GetJoysticks (_fun (count : (_ptr o _int)) -> _pointer))

;; Opening/Closing
(define-sdl SDL-OpenJoystick (_fun _uint32 -> _SDL_Joystick-pointer))
(define-sdl SDL-CloseJoystick (_fun _SDL_Joystick-pointer -> _void))
(define-sdl SDL-JoystickConnected (_fun _SDL_Joystick-pointer -> _bool))

;; Info (before opening)
(define-sdl SDL-GetJoystickNameForID (_fun _uint32 -> _string))
(define-sdl SDL-GetJoystickTypeForID (_fun _uint32 -> _SDL_JoystickType))

;; Info (after opening)
(define-sdl SDL-GetJoystickName (_fun _SDL_Joystick-pointer -> _string))
(define-sdl SDL-GetJoystickID (_fun _SDL_Joystick-pointer -> _uint32))
(define-sdl SDL-GetJoystickType (_fun _SDL_Joystick-pointer -> _SDL_JoystickType))

;; Capabilities
(define-sdl SDL-GetNumJoystickAxes (_fun _SDL_Joystick-pointer -> _int))
(define-sdl SDL-GetNumJoystickButtons (_fun _SDL_Joystick-pointer -> _int))
(define-sdl SDL-GetNumJoystickHats (_fun _SDL_Joystick-pointer -> _int))
(define-sdl SDL-GetNumJoystickBalls (_fun _SDL_Joystick-pointer -> _int))

;; State
(define-sdl SDL-GetJoystickAxis (_fun _SDL_Joystick-pointer _int -> _sint16))
(define-sdl SDL-GetJoystickButton (_fun _SDL_Joystick-pointer _int -> _bool))
(define-sdl SDL-GetJoystickHat (_fun _SDL_Joystick-pointer _int -> _uint8))

;; Update
(define-sdl SDL-UpdateJoysticks (_fun -> _void))
```

**Extended Functions (Priority 2):**
```racket
;; Player index
(define-sdl SDL-GetJoystickPlayerIndex (_fun _SDL_Joystick-pointer -> _int))
(define-sdl SDL-SetJoystickPlayerIndex (_fun _SDL_Joystick-pointer _int -> _bool))

;; USB info
(define-sdl SDL-GetJoystickVendor (_fun _SDL_Joystick-pointer -> _uint16))
(define-sdl SDL-GetJoystickProduct (_fun _SDL_Joystick-pointer -> _uint16))
(define-sdl SDL-GetJoystickSerial (_fun _SDL_Joystick-pointer -> _string))

;; Rumble
(define-sdl SDL-RumbleJoystick (_fun _SDL_Joystick-pointer _uint16 _uint16 _uint32 -> _bool))
(define-sdl SDL-RumbleJoystickTriggers (_fun _SDL_Joystick-pointer _uint16 _uint16 _uint32 -> _bool))

;; LED
(define-sdl SDL-SetJoystickLED (_fun _SDL_Joystick-pointer _uint8 _uint8 _uint8 -> _bool))

;; Power
(define-sdl SDL-GetJoystickPowerInfo (_fun _SDL_Joystick-pointer (percent : (_ptr o _int)) -> _SDL_PowerState))
(define-sdl SDL-GetJoystickConnectionState (_fun _SDL_Joystick-pointer -> _SDL_JoystickConnectionState))

;; Events control
(define-sdl SDL-SetJoystickEventsEnabled (_fun _bool -> _void))
(define-sdl SDL-JoystickEventsEnabled (_fun -> _bool))
```

### Phase 4: Raw Gamepad Bindings

Create `raw/gamepad.rkt`:

**Core Functions (Priority 1):**
```racket
;; Detection
(define-sdl SDL-HasGamepad (_fun -> _bool))
(define-sdl SDL-GetGamepads (_fun (count : (_ptr o _int)) -> _pointer))
(define-sdl SDL-IsGamepad (_fun _uint32 -> _bool))

;; Opening/Closing
(define-sdl SDL-OpenGamepad (_fun _uint32 -> _SDL_Gamepad-pointer))
(define-sdl SDL-CloseGamepad (_fun _SDL_Gamepad-pointer -> _void))
(define-sdl SDL-GamepadConnected (_fun _SDL_Gamepad-pointer -> _bool))

;; Info (before opening)
(define-sdl SDL-GetGamepadNameForID (_fun _uint32 -> _string))
(define-sdl SDL-GetGamepadTypeForID (_fun _uint32 -> _SDL_GamepadType))

;; Info (after opening)
(define-sdl SDL-GetGamepadName (_fun _SDL_Gamepad-pointer -> _string))
(define-sdl SDL-GetGamepadID (_fun _SDL_Gamepad-pointer -> _uint32))
(define-sdl SDL-GetGamepadType (_fun _SDL_Gamepad-pointer -> _SDL_GamepadType))
(define-sdl SDL-GetGamepadJoystick (_fun _SDL_Gamepad-pointer -> _SDL_Joystick-pointer))

;; State
(define-sdl SDL-GetGamepadAxis (_fun _SDL_Gamepad-pointer _SDL_GamepadAxis -> _sint16))
(define-sdl SDL-GetGamepadButton (_fun _SDL_Gamepad-pointer _SDL_GamepadButton -> _bool))
(define-sdl SDL-GamepadHasAxis (_fun _SDL_Gamepad-pointer _SDL_GamepadAxis -> _bool))
(define-sdl SDL-GamepadHasButton (_fun _SDL_Gamepad-pointer _SDL_GamepadButton -> _bool))

;; Button labels (for correct prompts)
(define-sdl SDL-GetGamepadButtonLabel (_fun _SDL_Gamepad-pointer _SDL_GamepadButton -> _SDL_GamepadButtonLabel))
(define-sdl SDL-GetGamepadButtonLabelForType (_fun _SDL_GamepadType _SDL_GamepadButton -> _SDL_GamepadButtonLabel))

;; Update
(define-sdl SDL-UpdateGamepads (_fun -> _void))
```

**Extended Functions (Priority 2):**
```racket
;; Player index
(define-sdl SDL-GetGamepadPlayerIndex (_fun _SDL_Gamepad-pointer -> _int))
(define-sdl SDL-SetGamepadPlayerIndex (_fun _SDL_Gamepad-pointer _int -> _bool))

;; USB info
(define-sdl SDL-GetGamepadVendor (_fun _SDL_Gamepad-pointer -> _uint16))
(define-sdl SDL-GetGamepadProduct (_fun _SDL_Gamepad-pointer -> _uint16))
(define-sdl SDL-GetGamepadSerial (_fun _SDL_Gamepad-pointer -> _string))

;; Rumble
(define-sdl SDL-RumbleGamepad (_fun _SDL_Gamepad-pointer _uint16 _uint16 _uint32 -> _bool))
(define-sdl SDL-RumbleGamepadTriggers (_fun _SDL_Gamepad-pointer _uint16 _uint16 _uint32 -> _bool))

;; LED
(define-sdl SDL-SetGamepadLED (_fun _SDL_Gamepad-pointer _uint8 _uint8 _uint8 -> _bool))

;; Power
(define-sdl SDL-GetGamepadPowerInfo (_fun _SDL_Gamepad-pointer (percent : (_ptr o _int)) -> _SDL_PowerState))
(define-sdl SDL-GetGamepadConnectionState (_fun _SDL_Gamepad-pointer -> _SDL_JoystickConnectionState))

;; String conversion
(define-sdl SDL-GetGamepadStringForButton (_fun _SDL_GamepadButton -> _string))
(define-sdl SDL-GetGamepadButtonFromString (_fun _string -> _SDL_GamepadButton))
(define-sdl SDL-GetGamepadStringForAxis (_fun _SDL_GamepadAxis -> _string))
(define-sdl SDL-GetGamepadAxisFromString (_fun _string -> _SDL_GamepadAxis))
(define-sdl SDL-GetGamepadStringForType (_fun _SDL_GamepadType -> _string))
(define-sdl SDL-GetGamepadTypeFromString (_fun _string -> _SDL_GamepadType))

;; Events control
(define-sdl SDL-SetGamepadEventsEnabled (_fun _bool -> _void))
(define-sdl SDL-GamepadEventsEnabled (_fun -> _bool))
```

**Touchpad & Sensors (Priority 3):**
```racket
(define-sdl SDL-GetNumGamepadTouchpads (_fun _SDL_Gamepad-pointer -> _int))
(define-sdl SDL-GetNumGamepadTouchpadFingers (_fun _SDL_Gamepad-pointer _int -> _int))
(define-sdl SDL-GetGamepadTouchpadFinger
  (_fun _SDL_Gamepad-pointer _int _int
        (down : (_ptr o _bool)) (x : (_ptr o _float)) (y : (_ptr o _float)) (pressure : (_ptr o _float))
        -> _bool))
(define-sdl SDL-GamepadHasSensor (_fun _SDL_Gamepad-pointer _SDL_SensorType -> _bool))
(define-sdl SDL-SetGamepadSensorEnabled (_fun _SDL_Gamepad-pointer _SDL_SensorType _bool -> _bool))
```

### Phase 5: Safe Wrapper - Joystick

Create `safe/joystick.rkt`:

```racket
#lang racket/base
(require ffi/unsafe
         racket/match
         "../raw/joystick.rkt"
         "../private/types.rkt")

(provide
 ;; Structs
 (struct-out joystick)

 ;; Detection
 has-joystick?
 get-joysticks        ; -> (listof joystick-id)

 ;; Opening
 open-joystick        ; joystick-id -> joystick
 joystick-connected?
 joystick-destroy!

 ;; Info
 joystick-name
 joystick-type
 joystick-id

 ;; Capabilities
 joystick-num-axes
 joystick-num-buttons
 joystick-num-hats

 ;; State
 joystick-axis        ; joystick axis-index -> value (-32768 to 32767)
 joystick-button      ; joystick button-index -> boolean
 joystick-hat         ; joystick hat-index -> symbol (centered, up, down, left, right, etc.)

 ;; Hat symbols
 hat-centered hat-up hat-down hat-left hat-right
 hat-up-left hat-up-right hat-down-left hat-down-right)

;; Resource wrapper with custodian cleanup
(struct joystick (ptr id name)
  #:property prop:cpointer 0)

(define (open-joystick id)
  (define ptr (SDL-OpenJoystick id))
  (unless ptr
    (error 'open-joystick "failed to open joystick ~a: ~a" id (SDL-GetError)))
  (define j (joystick ptr id (SDL-GetJoystickName ptr)))
  (register-custodian-shutdown j joystick-destroy! #:weak? #f)
  j)

;; Convert hat value to symbol
(define (hat-value->symbol v)
  (cond
    [(= v 0) 'centered]
    [(= v 1) 'up]
    [(= v 2) 'right]
    [(= v 3) 'up-right]
    [(= v 4) 'down]
    [(= v 6) 'down-right]
    [(= v 8) 'left]
    [(= v 9) 'up-left]
    [(= v 12) 'down-left]
    [else 'unknown]))
```

### Phase 6: Safe Wrapper - Gamepad

Create `safe/gamepad.rkt`:

```racket
#lang racket/base
(require ffi/unsafe
         racket/match
         "../raw/gamepad.rkt"
         "../private/types.rkt")

(provide
 ;; Structs
 (struct-out gamepad)

 ;; Detection
 has-gamepad?
 get-gamepads         ; -> (listof joystick-id)
 gamepad?/id          ; joystick-id -> boolean (is this ID a gamepad?)

 ;; Opening
 open-gamepad         ; joystick-id -> gamepad
 gamepad-connected?
 gamepad-destroy!

 ;; Info
 gamepad-name
 gamepad-type         ; -> symbol (xbox360, xboxone, ps4, ps5, switch-pro, etc.)
 gamepad-id

 ;; State - Buttons (returns boolean)
 gamepad-button       ; gamepad button-symbol -> boolean
 gamepad-has-button?

 ;; State - Axes (returns -32768 to 32767 for sticks, 0 to 32767 for triggers)
 gamepad-axis         ; gamepad axis-symbol -> integer
 gamepad-has-axis?

 ;; Button labels (for displaying correct prompts)
 gamepad-button-label ; gamepad button-symbol -> symbol (a, b, x, y, cross, circle, square, triangle)

 ;; Rumble
 gamepad-rumble!      ; gamepad low high duration-ms -> boolean

 ;; LED
 gamepad-set-led!     ; gamepad r g b -> boolean

 ;; Button/axis symbols
 button-south button-east button-west button-north
 button-back button-guide button-start
 button-left-stick button-right-stick
 button-left-shoulder button-right-shoulder
 button-dpad-up button-dpad-down button-dpad-left button-dpad-right

 axis-left-x axis-left-y axis-right-x axis-right-y
 axis-left-trigger axis-right-trigger)

(struct gamepad (ptr id name type)
  #:property prop:cpointer 0)

(define (open-gamepad id)
  (define ptr (SDL-OpenGamepad id))
  (unless ptr
    (error 'open-gamepad "failed to open gamepad ~a: ~a" id (SDL-GetError)))
  (define gp (gamepad ptr id
                       (SDL-GetGamepadName ptr)
                       (gamepad-type-symbol (SDL-GetGamepadType ptr))))
  (register-custodian-shutdown gp gamepad-destroy! #:weak? #f)
  gp)

;; Convert gamepad type enum to symbol
(define (gamepad-type-symbol type)
  (case type
    [(0) 'unknown]
    [(1) 'standard]
    [(2) 'xbox360]
    [(3) 'xboxone]
    [(4) 'ps3]
    [(5) 'ps4]
    [(6) 'ps5]
    [(7) 'switch-pro]
    [(8) 'switch-joycon-left]
    [(9) 'switch-joycon-right]
    [(10) 'switch-joycon-pair]
    [else 'unknown]))
```

### Phase 7: Event Integration

Update `safe/events.rkt`:

```racket
;; Add new event structs
(struct joy-axis-event (which axis value) #:transparent)
(struct joy-button-event (type which button) #:transparent)  ; type = 'down or 'up
(struct joy-hat-event (which hat value) #:transparent)
(struct joy-device-event (type which) #:transparent)  ; type = 'added or 'removed

(struct gamepad-axis-event (which axis value) #:transparent)
(struct gamepad-button-event (type which button) #:transparent)
(struct gamepad-device-event (type which) #:transparent)

;; Update parse-event to handle new event types
(define (parse-event ptr)
  (define type (ptr-ref ptr _uint32))
  (cond
    ;; ... existing cases ...

    ;; Joystick events
    [(= type SDL_EVENT_JOYSTICK_AXIS_MOTION)
     (define e (cast ptr _pointer _SDL_JoyAxisEvent-pointer))
     (joy-axis-event (SDL_JoyAxisEvent-which e)
                     (SDL_JoyAxisEvent-axis e)
                     (SDL_JoyAxisEvent-value e))]

    [(or (= type SDL_EVENT_JOYSTICK_BUTTON_DOWN)
         (= type SDL_EVENT_JOYSTICK_BUTTON_UP))
     (define e (cast ptr _pointer _SDL_JoyButtonEvent-pointer))
     (joy-button-event (if (= type SDL_EVENT_JOYSTICK_BUTTON_DOWN) 'down 'up)
                       (SDL_JoyButtonEvent-which e)
                       (SDL_JoyButtonEvent-button e))]

    ;; Gamepad events
    [(= type SDL_EVENT_GAMEPAD_AXIS_MOTION)
     (define e (cast ptr _pointer _SDL_GamepadAxisEvent-pointer))
     (gamepad-axis-event (SDL_GamepadAxisEvent-which e)
                         (axis-index->symbol (SDL_GamepadAxisEvent-axis e))
                         (SDL_GamepadAxisEvent-value e))]

    [(or (= type SDL_EVENT_GAMEPAD_BUTTON_DOWN)
         (= type SDL_EVENT_GAMEPAD_BUTTON_UP))
     (define e (cast ptr _pointer _SDL_GamepadButtonEvent-pointer))
     (gamepad-button-event (if (= type SDL_EVENT_GAMEPAD_BUTTON_DOWN) 'down 'up)
                           (SDL_GamepadButtonEvent-which e)
                           (button-index->symbol (SDL_GamepadButtonEvent-button e)))]
    ;; ...
    ))
```

### Phase 8: Examples

Create `examples/input/gamepad.rkt`:

```racket
#lang racket

(require sdl3)

;; Initialize with joystick support
(sdl-init! '(video joystick))

(define-values (win ren) (make-window+renderer "Gamepad Test" 800 600))

;; Wait for a gamepad to connect
(printf "Waiting for gamepad... Press any key to exit.~n")

(define running? #t)
(define gp #f)

(let loop ()
  (for ([e (in-events)])
    (match e
      [(quit-event) (set! running? #f)]
      [(key-event 'down _ _ 'escape _ _) (set! running? #f)]

      ;; Gamepad connected
      [(gamepad-device-event 'added which)
       (printf "Gamepad connected: ~a~n" (SDL-GetGamepadNameForID which))
       (set! gp (open-gamepad which))]

      ;; Gamepad disconnected
      [(gamepad-device-event 'removed which)
       (printf "Gamepad disconnected~n")
       (when gp (gamepad-destroy! gp))
       (set! gp #f)]

      ;; Button events
      [(gamepad-button-event type which button)
       (printf "Button ~a: ~a~n" button type)]

      ;; Axis events (with deadzone)
      [(gamepad-axis-event which axis value)
       (when (> (abs value) 8000)
         (printf "Axis ~a: ~a~n" axis value))]

      [_ (void)]))

  ;; Draw current state if gamepad connected
  (set-draw-color! ren 30 30 30)
  (render-clear! ren)

  (when gp
    ;; Draw left stick position
    (define lx (gamepad-axis gp 'left-x))
    (define ly (gamepad-axis gp 'left-y))
    (define cx (+ 200 (quotient (* lx 100) 32768)))
    (define cy (+ 300 (quotient (* ly 100) 32768)))
    (set-draw-color! ren 100 100 255)
    (fill-rect! ren (- cx 10) (- cy 10) 20 20)

    ;; Draw right stick position
    (define rx (gamepad-axis gp 'right-x))
    (define ry (gamepad-axis gp 'right-y))
    (define cx2 (+ 600 (quotient (* rx 100) 32768)))
    (define cy2 (+ 300 (quotient (* ry 100) 32768)))
    (set-draw-color! ren 255 100 100)
    (fill-rect! ren (- cx2 10) (- cy2 10) 20 20)

    ;; Draw triggers
    (define lt (gamepad-axis gp 'left-trigger))
    (define rt (gamepad-axis gp 'right-trigger))
    (set-draw-color! ren 100 255 100)
    (fill-rect! ren 100 100 (quotient (* lt 200) 32767) 30)
    (fill-rect! ren 500 100 (quotient (* rt 200) 32767) 30))

  (render-present! ren)
  (when running? (loop)))

(when gp (gamepad-destroy! gp))
```

---

## File Summary

| File | Purpose |
|------|---------|
| `private/types.rkt` | Add joystick/gamepad pointer types, enums |
| `private/constants.rkt` | Add event constants, hat values, init flags |
| `raw/joystick.rkt` | Low-level joystick FFI bindings |
| `raw/gamepad.rkt` | Low-level gamepad FFI bindings |
| `raw.rkt` | Re-export joystick and gamepad modules |
| `safe/joystick.rkt` | Idiomatic joystick wrapper |
| `safe/gamepad.rkt` | Idiomatic gamepad wrapper |
| `safe/events.rkt` | Add joystick/gamepad event parsing |
| `safe.rkt` | Re-export joystick and gamepad modules |
| `examples/input/gamepad.rkt` | Interactive gamepad demo |

---

## Implementation Order

| Step | Phase | Deliverable |
|------|-------|-------------|
| 1 | Phase 1 | Types & constants for joystick/gamepad |
| 2 | Phase 2 | Event type constants and structs |
| 3 | Phase 3 | Raw joystick bindings |
| 4 | Phase 4 | Raw gamepad bindings |
| 5 | Phase 5 | Safe joystick wrapper |
| 6 | Phase 6 | Safe gamepad wrapper |
| 7 | Phase 7 | Event integration |
| 8 | Phase 8 | Examples |

---

## Function Counts

| Phase | Raw Functions | Safe Wrappers | Types/Constants |
|-------|---------------|---------------|-----------------|
| Phase 1-2 | 0 | 0 | ~25 |
| Phase 3 | ~20 | 0 | 0 |
| Phase 4 | ~25 | 0 | 0 |
| Phase 5 | 0 | ~15 | 0 |
| Phase 6 | 0 | ~20 | 0 |
| Phase 7 | 0 | ~7 events | 0 |
| **Total** | **~45** | **~42** | **~25** |

---

## Testing Notes

- Test with Xbox controller (most common)
- Test with PlayStation controller (DualShock 4/DualSense)
- Test with Nintendo Switch Pro controller
- Verify hot-plug works (connect/disconnect during runtime)
- Test rumble on supported controllers
- Verify button labels are correct per controller type

---

## Dependencies

- SDL3 must be initialized with `SDL_INIT_JOYSTICK` flag
- Gamepad support is included when joystick is initialized
- No additional libraries needed (gamepad mappings built into SDL3)

---

## Testing Strategy

After each phase:
1. Clear compiled cache: `make clean`
2. Compile: `PLTCOLLECTS="$PWD:" raco make raw/joystick.rkt` (or appropriate file)
3. Run the phase's example program
4. Verify existing examples still work
