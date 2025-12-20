#lang racket/base

;; Idiomatic gamepad API
;;
;; High-level gamepad access with standardized button/axis names.
;; Provides automatic resource management via custodians.

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw/gamepad.rkt"
         "../raw/init.rkt"
         "../private/types.rkt"
         "../private/constants.rkt")

(provide
 ;; Gamepad struct
 (struct-out gamepad)

 ;; Detection
 has-gamepad?
 get-gamepads
 get-gamepad-count
 is-gamepad?

 ;; Opening/Closing
 open-gamepad
 gamepad-connected?
 gamepad-destroy!

 ;; Info
 gamepad-name
 gamepad-path
 gamepad-id
 gamepad-type
 gamepad-real-type
 gamepad-vendor
 gamepad-product
 gamepad-serial

 ;; Info by ID (before opening)
 get-gamepad-name-for-id
 get-gamepad-type-for-id

 ;; State - Buttons
 gamepad-button
 gamepad-has-button?

 ;; State - Axes
 gamepad-axis
 gamepad-has-axis?

 ;; Button labels (for prompts)
 gamepad-button-label
 gamepad-button-label-for-type

 ;; Player index
 gamepad-player-index
 set-gamepad-player-index!

 ;; Rumble
 gamepad-rumble!
 gamepad-rumble-triggers!

 ;; LED
 gamepad-set-led!

 ;; Power
 gamepad-power-info
 gamepad-connection-state

 ;; Type conversions
 gamepad-type->symbol
 button->symbol
 symbol->button
 axis->symbol
 symbol->axis
 button-label->symbol

 ;; Re-export button constants
 SDL_GAMEPAD_BUTTON_SOUTH
 SDL_GAMEPAD_BUTTON_EAST
 SDL_GAMEPAD_BUTTON_WEST
 SDL_GAMEPAD_BUTTON_NORTH
 SDL_GAMEPAD_BUTTON_BACK
 SDL_GAMEPAD_BUTTON_GUIDE
 SDL_GAMEPAD_BUTTON_START
 SDL_GAMEPAD_BUTTON_LEFT_STICK
 SDL_GAMEPAD_BUTTON_RIGHT_STICK
 SDL_GAMEPAD_BUTTON_LEFT_SHOULDER
 SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER
 SDL_GAMEPAD_BUTTON_DPAD_UP
 SDL_GAMEPAD_BUTTON_DPAD_DOWN
 SDL_GAMEPAD_BUTTON_DPAD_LEFT
 SDL_GAMEPAD_BUTTON_DPAD_RIGHT

 ;; Re-export axis constants
 SDL_GAMEPAD_AXIS_LEFTX
 SDL_GAMEPAD_AXIS_LEFTY
 SDL_GAMEPAD_AXIS_RIGHTX
 SDL_GAMEPAD_AXIS_RIGHTY
 SDL_GAMEPAD_AXIS_LEFT_TRIGGER
 SDL_GAMEPAD_AXIS_RIGHT_TRIGGER)

;; ============================================================================
;; Gamepad Struct (with custodian management)
;; ============================================================================

(struct gamepad (ptr [closed? #:mutable])
  #:property prop:cpointer (λ (g) (gamepad-ptr g)))

(define (gamepad-destroy! gp)
  (unless (gamepad-closed? gp)
    (SDL-CloseGamepad (gamepad-ptr gp))
    (set-gamepad-closed?! gp #t)))

;; ============================================================================
;; Detection
;; ============================================================================

(define (has-gamepad?)
  (SDL-HasGamepad))

;; Get list of gamepad instance IDs
(define (get-gamepads)
  (define-values (arr count) (SDL-GetGamepads))
  (if (or (not arr) (zero? count))
      '()
      (begin0
        (for/list ([i (in-range count)])
          (ptr-ref arr _uint32 i))
        (SDL-free arr))))

(define (get-gamepad-count)
  (length (get-gamepads)))

;; Check if a joystick instance ID is a gamepad
(define (is-gamepad? instance-id)
  (SDL-IsGamepad instance-id))

;; ============================================================================
;; Opening/Closing
;; ============================================================================

;; Open a gamepad by instance ID
;; Registers with custodian for automatic cleanup
(define (open-gamepad instance-id)
  (define ptr (SDL-OpenGamepad instance-id))
  (unless ptr
    (error 'open-gamepad "failed to open gamepad ~a: ~a"
           instance-id (SDL-GetError)))
  (define gp (gamepad ptr #f))
  (register-custodian-shutdown
   gp
   (λ (g) (gamepad-destroy! g))
   (current-custodian)
   #:weak? #f)
  gp)

(define (gamepad-connected? gp)
  (and (not (gamepad-closed? gp))
       (SDL-GamepadConnected (gamepad-ptr gp))))

;; ============================================================================
;; Info (after opening)
;; ============================================================================

(define (gamepad-name gp)
  (SDL-GetGamepadName (gamepad-ptr gp)))

(define (gamepad-path gp)
  (SDL-GetGamepadPath (gamepad-ptr gp)))

(define (gamepad-id gp)
  (SDL-GetGamepadID (gamepad-ptr gp)))

(define (gamepad-type gp)
  (gamepad-type->symbol (SDL-GetGamepadType (gamepad-ptr gp))))

(define (gamepad-real-type gp)
  (gamepad-type->symbol (SDL-GetRealGamepadType (gamepad-ptr gp))))

(define (gamepad-vendor gp)
  (SDL-GetGamepadVendor (gamepad-ptr gp)))

(define (gamepad-product gp)
  (SDL-GetGamepadProduct (gamepad-ptr gp)))

(define (gamepad-serial gp)
  (SDL-GetGamepadSerial (gamepad-ptr gp)))

;; ============================================================================
;; Info by ID (before opening)
;; ============================================================================

(define (get-gamepad-name-for-id instance-id)
  (SDL-GetGamepadNameForID instance-id))

(define (get-gamepad-type-for-id instance-id)
  (gamepad-type->symbol (SDL-GetGamepadTypeForID instance-id)))

;; ============================================================================
;; State - Buttons
;; ============================================================================

;; Get the current state of a button
;; button: symbol or SDL_GAMEPAD_BUTTON_* constant
;; Returns: boolean
(define (gamepad-button gp button)
  (define btn (if (symbol? button) (symbol->button button) button))
  (SDL-GetGamepadButton (gamepad-ptr gp) btn))

;; Check if the gamepad has a specific button
(define (gamepad-has-button? gp button)
  (define btn (if (symbol? button) (symbol->button button) button))
  (SDL-GamepadHasButton (gamepad-ptr gp) btn))

;; ============================================================================
;; State - Axes
;; ============================================================================

;; Get the current state of an axis
;; axis: symbol or SDL_GAMEPAD_AXIS_* constant
;; Returns: -32768 to 32767 for sticks, 0 to 32767 for triggers
(define (gamepad-axis gp axis)
  (define ax (if (symbol? axis) (symbol->axis axis) axis))
  (SDL-GetGamepadAxis (gamepad-ptr gp) ax))

;; Check if the gamepad has a specific axis
(define (gamepad-has-axis? gp axis)
  (define ax (if (symbol? axis) (symbol->axis axis) axis))
  (SDL-GamepadHasAxis (gamepad-ptr gp) ax))

;; ============================================================================
;; Button Labels (for prompts)
;; ============================================================================

;; Get the label for a button (A/B/X/Y vs Cross/Circle/Square/Triangle)
(define (gamepad-button-label gp button)
  (define btn (if (symbol? button) (symbol->button button) button))
  (button-label->symbol (SDL-GetGamepadButtonLabel (gamepad-ptr gp) btn)))

;; Get the label for a button on a specific gamepad type
(define (gamepad-button-label-for-type type button)
  (define t (if (symbol? type) (symbol->gamepad-type type) type))
  (define btn (if (symbol? button) (symbol->button button) button))
  (button-label->symbol (SDL-GetGamepadButtonLabelForType t btn)))

;; ============================================================================
;; Player Index
;; ============================================================================

(define (gamepad-player-index gp)
  (SDL-GetGamepadPlayerIndex (gamepad-ptr gp)))

(define (set-gamepad-player-index! gp index)
  (unless (SDL-SetGamepadPlayerIndex (gamepad-ptr gp) index)
    (error 'set-gamepad-player-index! "failed to set player index: ~a"
           (SDL-GetError))))

;; ============================================================================
;; Rumble
;; ============================================================================

;; Start a rumble effect
;; low, high: motor intensity (0-65535)
;; duration-ms: duration in milliseconds, or 0 for infinite
(define (gamepad-rumble! gp low high [duration-ms 0])
  (SDL-RumbleGamepad (gamepad-ptr gp) low high duration-ms))

;; Start a trigger rumble effect (Xbox-style controllers)
(define (gamepad-rumble-triggers! gp left right [duration-ms 0])
  (SDL-RumbleGamepadTriggers (gamepad-ptr gp) left right duration-ms))

;; ============================================================================
;; LED
;; ============================================================================

;; Set the LED color (if supported)
(define (gamepad-set-led! gp r g b)
  (SDL-SetGamepadLED (gamepad-ptr gp) r g b))

;; ============================================================================
;; Power
;; ============================================================================

;; Get the power info
;; Returns: (values state percent) where state is a symbol and percent is 0-100 or -1
(define (gamepad-power-info gp)
  (define-values (state percent) (SDL-GetGamepadPowerInfo (gamepad-ptr gp)))
  (values (power-state->symbol state) percent))

;; Get the connection state as a symbol
(define (gamepad-connection-state gp)
  (connection-state->symbol (SDL-GetGamepadConnectionState (gamepad-ptr gp))))

;; ============================================================================
;; Type Conversions
;; ============================================================================

(define (gamepad-type->symbol type)
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

(define (symbol->gamepad-type sym)
  (case sym
    [(unknown) 0]
    [(standard) 1]
    [(xbox360) 2]
    [(xboxone) 3]
    [(ps3) 4]
    [(ps4) 5]
    [(ps5) 6]
    [(switch-pro) 7]
    [(switch-joycon-left) 8]
    [(switch-joycon-right) 9]
    [(switch-joycon-pair) 10]
    [else 0]))

(define (button->symbol btn)
  (case btn
    [(0) 'south]
    [(1) 'east]
    [(2) 'west]
    [(3) 'north]
    [(4) 'back]
    [(5) 'guide]
    [(6) 'start]
    [(7) 'left-stick]
    [(8) 'right-stick]
    [(9) 'left-shoulder]
    [(10) 'right-shoulder]
    [(11) 'dpad-up]
    [(12) 'dpad-down]
    [(13) 'dpad-left]
    [(14) 'dpad-right]
    [(15) 'misc1]
    [(16) 'right-paddle1]
    [(17) 'left-paddle1]
    [(18) 'right-paddle2]
    [(19) 'left-paddle2]
    [(20) 'touchpad]
    [else 'unknown]))

(define (symbol->button sym)
  (case sym
    [(south a cross) SDL_GAMEPAD_BUTTON_SOUTH]
    [(east b circle) SDL_GAMEPAD_BUTTON_EAST]
    [(west x square) SDL_GAMEPAD_BUTTON_WEST]
    [(north y triangle) SDL_GAMEPAD_BUTTON_NORTH]
    [(back select) SDL_GAMEPAD_BUTTON_BACK]
    [(guide home) SDL_GAMEPAD_BUTTON_GUIDE]
    [(start) SDL_GAMEPAD_BUTTON_START]
    [(left-stick l3) SDL_GAMEPAD_BUTTON_LEFT_STICK]
    [(right-stick r3) SDL_GAMEPAD_BUTTON_RIGHT_STICK]
    [(left-shoulder lb l1) SDL_GAMEPAD_BUTTON_LEFT_SHOULDER]
    [(right-shoulder rb r1) SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER]
    [(dpad-up up) SDL_GAMEPAD_BUTTON_DPAD_UP]
    [(dpad-down down) SDL_GAMEPAD_BUTTON_DPAD_DOWN]
    [(dpad-left left) SDL_GAMEPAD_BUTTON_DPAD_LEFT]
    [(dpad-right right) SDL_GAMEPAD_BUTTON_DPAD_RIGHT]
    [(misc1) SDL_GAMEPAD_BUTTON_MISC1]
    [(right-paddle1) SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1]
    [(left-paddle1) SDL_GAMEPAD_BUTTON_LEFT_PADDLE1]
    [(right-paddle2) SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2]
    [(left-paddle2) SDL_GAMEPAD_BUTTON_LEFT_PADDLE2]
    [(touchpad) SDL_GAMEPAD_BUTTON_TOUCHPAD]
    [else SDL_GAMEPAD_BUTTON_INVALID]))

(define (axis->symbol ax)
  (case ax
    [(0) 'left-x]
    [(1) 'left-y]
    [(2) 'right-x]
    [(3) 'right-y]
    [(4) 'left-trigger]
    [(5) 'right-trigger]
    [else 'unknown]))

(define (symbol->axis sym)
  (case sym
    [(left-x leftx lx) SDL_GAMEPAD_AXIS_LEFTX]
    [(left-y lefty ly) SDL_GAMEPAD_AXIS_LEFTY]
    [(right-x rightx rx) SDL_GAMEPAD_AXIS_RIGHTX]
    [(right-y righty ry) SDL_GAMEPAD_AXIS_RIGHTY]
    [(left-trigger lt l2) SDL_GAMEPAD_AXIS_LEFT_TRIGGER]
    [(right-trigger rt r2) SDL_GAMEPAD_AXIS_RIGHT_TRIGGER]
    [else SDL_GAMEPAD_AXIS_INVALID]))

(define (button-label->symbol label)
  (case label
    [(0) 'unknown]
    [(1) 'a]
    [(2) 'b]
    [(3) 'x]
    [(4) 'y]
    [(5) 'cross]
    [(6) 'circle]
    [(7) 'square]
    [(8) 'triangle]
    [else 'unknown]))

(define (power-state->symbol state)
  (case state
    [(-1) 'error]
    [(0) 'unknown]
    [(1) 'on-battery]
    [(2) 'no-battery]
    [(3) 'charging]
    [(4) 'charged]
    [else 'unknown]))

(define (connection-state->symbol state)
  (case state
    [(-1) 'invalid]
    [(0) 'unknown]
    [(1) 'wired]
    [(2) 'wireless]
    [else 'unknown]))
