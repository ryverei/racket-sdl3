#lang racket/base

;; Idiomatic joystick API
;;
;; Low-level joystick access with automatic resource management.
;; For a higher-level controller API, use safe/gamepad.rkt instead.

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw/joystick.rkt"
         "../raw/init.rkt"
         "../private/types.rkt"
         "../private/constants.rkt")

(provide
 ;; Joystick struct
 (struct-out joystick)

 ;; Detection
 has-joystick?
 get-joysticks
 get-joystick-count

 ;; Opening/Closing
 open-joystick
 joystick-connected?
 joystick-destroy!

 ;; Info
 joystick-name
 joystick-path
 joystick-id
 joystick-type
 joystick-vendor
 joystick-product
 joystick-serial

 ;; Info by ID (before opening)
 get-joystick-name-for-id
 get-joystick-type-for-id

 ;; Capabilities
 joystick-num-axes
 joystick-num-buttons
 joystick-num-hats
 joystick-num-balls

 ;; State
 joystick-axis
 joystick-button
 joystick-hat
 joystick-ball

 ;; Player index
 joystick-player-index
 set-joystick-player-index!

 ;; Rumble
 joystick-rumble!
 joystick-rumble-triggers!

 ;; LED
 joystick-set-led!

 ;; Power
 joystick-power-info
 joystick-connection-state

 ;; Hat value conversion
 hat-value->symbol
 hat-value->list

 ;; Joystick type conversion
 joystick-type->symbol

 ;; Re-export hat constants for pattern matching
 SDL_HAT_CENTERED
 SDL_HAT_UP
 SDL_HAT_RIGHT
 SDL_HAT_DOWN
 SDL_HAT_LEFT
 SDL_HAT_RIGHTUP
 SDL_HAT_RIGHTDOWN
 SDL_HAT_LEFTUP
 SDL_HAT_LEFTDOWN)

;; ============================================================================
;; Joystick Struct (with custodian management)
;; ============================================================================

(struct joystick (ptr [closed? #:mutable])
  #:property prop:cpointer (λ (j) (joystick-ptr j)))

(define (joystick-destroy! joy)
  (unless (joystick-closed? joy)
    (SDL-CloseJoystick (joystick-ptr joy))
    (set-joystick-closed?! joy #t)))

;; ============================================================================
;; Detection
;; ============================================================================

(define (has-joystick?)
  (SDL-HasJoystick))

;; Get list of joystick instance IDs
(define (get-joysticks)
  (define-values (arr count) (SDL-GetJoysticks))
  (if (or (not arr) (zero? count))
      '()
      (begin0
        (for/list ([i (in-range count)])
          (ptr-ref arr _uint32 i))
        (SDL-free arr))))

(define (get-joystick-count)
  (length (get-joysticks)))

;; ============================================================================
;; Opening/Closing
;; ============================================================================

;; Open a joystick by instance ID
;; Registers with custodian for automatic cleanup
(define (open-joystick instance-id)
  (define ptr (SDL-OpenJoystick instance-id))
  (unless ptr
    (error 'open-joystick "failed to open joystick ~a: ~a"
           instance-id (SDL-GetError)))
  (define joy (joystick ptr #f))
  (register-custodian-shutdown
   joy
   (λ (j) (joystick-destroy! j))
   (current-custodian)
   #:weak? #f)
  joy)

(define (joystick-connected? joy)
  (and (not (joystick-closed? joy))
       (SDL-JoystickConnected (joystick-ptr joy))))

;; ============================================================================
;; Info (after opening)
;; ============================================================================

(define (joystick-name joy)
  (SDL-GetJoystickName (joystick-ptr joy)))

(define (joystick-path joy)
  (SDL-GetJoystickPath (joystick-ptr joy)))

(define (joystick-id joy)
  (SDL-GetJoystickID (joystick-ptr joy)))

(define (joystick-type joy)
  (joystick-type->symbol (SDL-GetJoystickType (joystick-ptr joy))))

(define (joystick-vendor joy)
  (SDL-GetJoystickVendor (joystick-ptr joy)))

(define (joystick-product joy)
  (SDL-GetJoystickProduct (joystick-ptr joy)))

(define (joystick-serial joy)
  (SDL-GetJoystickSerial (joystick-ptr joy)))

;; ============================================================================
;; Info by ID (before opening)
;; ============================================================================

(define (get-joystick-name-for-id instance-id)
  (SDL-GetJoystickNameForID instance-id))

(define (get-joystick-type-for-id instance-id)
  (joystick-type->symbol (SDL-GetJoystickTypeForID instance-id)))

;; ============================================================================
;; Capabilities
;; ============================================================================

(define (joystick-num-axes joy)
  (SDL-GetNumJoystickAxes (joystick-ptr joy)))

(define (joystick-num-buttons joy)
  (SDL-GetNumJoystickButtons (joystick-ptr joy)))

(define (joystick-num-hats joy)
  (SDL-GetNumJoystickHats (joystick-ptr joy)))

(define (joystick-num-balls joy)
  (SDL-GetNumJoystickBalls (joystick-ptr joy)))

;; ============================================================================
;; State
;; ============================================================================

;; Get the current value of an axis (-32768 to 32767)
(define (joystick-axis joy axis-index)
  (SDL-GetJoystickAxis (joystick-ptr joy) axis-index))

;; Get the current state of a button (boolean)
(define (joystick-button joy button-index)
  (SDL-GetJoystickButton (joystick-ptr joy) button-index))

;; Get the current hat position as a symbol
(define (joystick-hat joy hat-index)
  (hat-value->symbol (SDL-GetJoystickHat (joystick-ptr joy) hat-index)))

;; Get the trackball delta since last call
;; Returns: (values dx dy)
(define (joystick-ball joy ball-index)
  (define-values (ok dx dy) (SDL-GetJoystickBall (joystick-ptr joy) ball-index))
  (if ok
      (values dx dy)
      (error 'joystick-ball "failed to get ball state: ~a" (SDL-GetError))))

;; ============================================================================
;; Player Index
;; ============================================================================

(define (joystick-player-index joy)
  (SDL-GetJoystickPlayerIndex (joystick-ptr joy)))

(define (set-joystick-player-index! joy index)
  (unless (SDL-SetJoystickPlayerIndex (joystick-ptr joy) index)
    (error 'set-joystick-player-index! "failed to set player index: ~a"
           (SDL-GetError))))

;; ============================================================================
;; Rumble
;; ============================================================================

;; Start a rumble effect
;; low, high: motor intensity (0-65535)
;; duration-ms: duration in milliseconds, or 0 for infinite
(define (joystick-rumble! joy low high [duration-ms 0])
  (SDL-RumbleJoystick (joystick-ptr joy) low high duration-ms))

;; Start a trigger rumble effect (Xbox-style controllers)
(define (joystick-rumble-triggers! joy left right [duration-ms 0])
  (SDL-RumbleJoystickTriggers (joystick-ptr joy) left right duration-ms))

;; ============================================================================
;; LED
;; ============================================================================

;; Set the LED color (if supported)
(define (joystick-set-led! joy r g b)
  (SDL-SetJoystickLED (joystick-ptr joy) r g b))

;; ============================================================================
;; Power
;; ============================================================================

;; Get the power info
;; Returns: (values state percent) where state is a symbol and percent is 0-100 or -1
(define (joystick-power-info joy)
  (define-values (state percent) (SDL-GetJoystickPowerInfo (joystick-ptr joy)))
  (values (power-state->symbol state) percent))

;; Get the connection state as a symbol
(define (joystick-connection-state joy)
  (connection-state->symbol (SDL-GetJoystickConnectionState (joystick-ptr joy))))

;; ============================================================================
;; Type Conversions
;; ============================================================================

(define (hat-value->symbol v)
  (cond
    [(= v SDL_HAT_CENTERED) 'centered]
    [(= v SDL_HAT_UP) 'up]
    [(= v SDL_HAT_RIGHT) 'right]
    [(= v SDL_HAT_DOWN) 'down]
    [(= v SDL_HAT_LEFT) 'left]
    [(= v SDL_HAT_RIGHTUP) 'up-right]
    [(= v SDL_HAT_RIGHTDOWN) 'down-right]
    [(= v SDL_HAT_LEFTUP) 'up-left]
    [(= v SDL_HAT_LEFTDOWN) 'down-left]
    [else 'unknown]))

;; Get hat directions as a list (for compound directions)
(define (hat-value->list v)
  (cond
    [(= v SDL_HAT_CENTERED) '()]
    [else
     (append (if (not (zero? (bitwise-and v SDL_HAT_UP))) '(up) '())
             (if (not (zero? (bitwise-and v SDL_HAT_DOWN))) '(down) '())
             (if (not (zero? (bitwise-and v SDL_HAT_LEFT))) '(left) '())
             (if (not (zero? (bitwise-and v SDL_HAT_RIGHT))) '(right) '()))]))

(define (joystick-type->symbol type)
  (case type
    [(0) 'unknown]
    [(1) 'gamepad]
    [(2) 'wheel]
    [(3) 'arcade-stick]
    [(4) 'flight-stick]
    [(5) 'dance-pad]
    [(6) 'guitar]
    [(7) 'drum-kit]
    [(8) 'arcade-pad]
    [(9) 'throttle]
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
