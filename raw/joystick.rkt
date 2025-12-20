#lang racket/base

;; SDL3 Joystick Input
;;
;; Low-level joystick access. Provides raw access to buttons, axes, and hats.
;; For a higher-level controller API, use raw/gamepad.rkt instead.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt"
         "../private/constants.rkt")

(provide ;; Detection
         SDL-HasJoystick
         SDL-GetJoysticks
         ;; Opening/Closing
         SDL-OpenJoystick
         SDL-CloseJoystick
         SDL-JoystickConnected
         SDL-GetJoystickFromID
         ;; Info (before opening - by instance ID)
         SDL-GetJoystickNameForID
         SDL-GetJoystickPathForID
         SDL-GetJoystickPlayerIndexForID
         SDL-GetJoystickGUIDForID
         SDL-GetJoystickVendorForID
         SDL-GetJoystickProductForID
         SDL-GetJoystickProductVersionForID
         SDL-GetJoystickTypeForID
         ;; Info (after opening)
         SDL-GetJoystickName
         SDL-GetJoystickPath
         SDL-GetJoystickID
         SDL-GetJoystickType
         SDL-GetJoystickGUID
         SDL-GetJoystickVendor
         SDL-GetJoystickProduct
         SDL-GetJoystickProductVersion
         SDL-GetJoystickSerial
         ;; Capabilities
         SDL-GetNumJoystickAxes
         SDL-GetNumJoystickBalls
         SDL-GetNumJoystickButtons
         SDL-GetNumJoystickHats
         ;; State
         SDL-GetJoystickAxis
         SDL-GetJoystickAxisInitialState
         SDL-GetJoystickBall
         SDL-GetJoystickButton
         SDL-GetJoystickHat
         ;; Player index
         SDL-GetJoystickPlayerIndex
         SDL-SetJoystickPlayerIndex
         ;; Rumble
         SDL-RumbleJoystick
         SDL-RumbleJoystickTriggers
         ;; LED
         SDL-SetJoystickLED
         ;; Power
         SDL-GetJoystickPowerInfo
         SDL-GetJoystickConnectionState
         ;; Events control
         SDL-SetJoystickEventsEnabled
         SDL-JoystickEventsEnabled
         ;; Update
         SDL-UpdateJoysticks
         ;; Lock
         SDL-LockJoysticks
         SDL-UnlockJoysticks)

;; ============================================================================
;; Detection
;; ============================================================================

;; SDL_HasJoystick: Check if there are any joysticks connected
;; Returns: true if joysticks are connected
(define-sdl SDL-HasJoystick
  (_fun -> _stdbool)
  #:c-id SDL_HasJoystick)

;; SDL_GetJoysticks: Get a list of connected joystick instance IDs
;; count: pointer to receive the number of joysticks
;; Returns: array of SDL_JoystickID values (must be freed with SDL_free)
(define-sdl SDL-GetJoysticks
  (_fun (count : (_ptr o _int)) -> (arr : _pointer)
        -> (values arr count))
  #:c-id SDL_GetJoysticks)

;; ============================================================================
;; Opening/Closing
;; ============================================================================

;; SDL_OpenJoystick: Open a joystick for use
;; instance_id: the joystick instance ID from SDL_GetJoysticks
;; Returns: joystick pointer, or NULL on failure
(define-sdl SDL-OpenJoystick
  (_fun _SDL_JoystickID -> _SDL_Joystick-pointer/null)
  #:c-id SDL_OpenJoystick)

;; SDL_CloseJoystick: Close a joystick previously opened with SDL_OpenJoystick
;; joystick: the joystick to close
(define-sdl SDL-CloseJoystick
  (_fun _SDL_Joystick-pointer -> _void)
  #:c-id SDL_CloseJoystick)

;; SDL_JoystickConnected: Check if a joystick is still connected
;; joystick: the joystick to check
;; Returns: true if still connected
(define-sdl SDL-JoystickConnected
  (_fun _SDL_Joystick-pointer -> _stdbool)
  #:c-id SDL_JoystickConnected)

;; SDL_GetJoystickFromID: Get the joystick associated with an instance ID
;; instance_id: the instance ID to look for
;; Returns: joystick pointer, or NULL if not found
(define-sdl SDL-GetJoystickFromID
  (_fun _SDL_JoystickID -> _SDL_Joystick-pointer/null)
  #:c-id SDL_GetJoystickFromID)

;; ============================================================================
;; Info (before opening - by instance ID)
;; ============================================================================

;; SDL_GetJoystickNameForID: Get the name of a joystick (by instance ID)
;; Returns: joystick name string, or NULL on failure
(define-sdl SDL-GetJoystickNameForID
  (_fun _SDL_JoystickID -> _string/utf-8)
  #:c-id SDL_GetJoystickNameForID)

;; SDL_GetJoystickPathForID: Get the path of a joystick (by instance ID)
;; Returns: joystick path string, or NULL on failure
(define-sdl SDL-GetJoystickPathForID
  (_fun _SDL_JoystickID -> _string/utf-8)
  #:c-id SDL_GetJoystickPathForID)

;; SDL_GetJoystickPlayerIndexForID: Get the player index of a joystick (by instance ID)
;; Returns: player index, or -1 if unknown
(define-sdl SDL-GetJoystickPlayerIndexForID
  (_fun _SDL_JoystickID -> _int)
  #:c-id SDL_GetJoystickPlayerIndexForID)

;; SDL_GetJoystickGUIDForID: Get the GUID of a joystick (by instance ID)
;; Returns: 16-byte GUID struct (by value)
(define-sdl SDL-GetJoystickGUIDForID
  (_fun _SDL_JoystickID -> (_array _uint8 16))
  #:c-id SDL_GetJoystickGUIDForID)

;; SDL_GetJoystickVendorForID: Get the vendor ID of a joystick (by instance ID)
;; Returns: vendor ID, or 0 if unknown
(define-sdl SDL-GetJoystickVendorForID
  (_fun _SDL_JoystickID -> _uint16)
  #:c-id SDL_GetJoystickVendorForID)

;; SDL_GetJoystickProductForID: Get the product ID of a joystick (by instance ID)
;; Returns: product ID, or 0 if unknown
(define-sdl SDL-GetJoystickProductForID
  (_fun _SDL_JoystickID -> _uint16)
  #:c-id SDL_GetJoystickProductForID)

;; SDL_GetJoystickProductVersionForID: Get the product version of a joystick (by instance ID)
;; Returns: product version, or 0 if unknown
(define-sdl SDL-GetJoystickProductVersionForID
  (_fun _SDL_JoystickID -> _uint16)
  #:c-id SDL_GetJoystickProductVersionForID)

;; SDL_GetJoystickTypeForID: Get the type of a joystick (by instance ID)
;; Returns: SDL_JoystickType enum value
(define-sdl SDL-GetJoystickTypeForID
  (_fun _SDL_JoystickID -> _SDL_JoystickType)
  #:c-id SDL_GetJoystickTypeForID)

;; ============================================================================
;; Info (after opening)
;; ============================================================================

;; SDL_GetJoystickName: Get the name of an opened joystick
;; Returns: joystick name string
(define-sdl SDL-GetJoystickName
  (_fun _SDL_Joystick-pointer -> _string/utf-8)
  #:c-id SDL_GetJoystickName)

;; SDL_GetJoystickPath: Get the path of an opened joystick
;; Returns: joystick path string
(define-sdl SDL-GetJoystickPath
  (_fun _SDL_Joystick-pointer -> _string/utf-8)
  #:c-id SDL_GetJoystickPath)

;; SDL_GetJoystickID: Get the instance ID of an opened joystick
;; Returns: instance ID
(define-sdl SDL-GetJoystickID
  (_fun _SDL_Joystick-pointer -> _SDL_JoystickID)
  #:c-id SDL_GetJoystickID)

;; SDL_GetJoystickType: Get the type of an opened joystick
;; Returns: SDL_JoystickType enum value
(define-sdl SDL-GetJoystickType
  (_fun _SDL_Joystick-pointer -> _SDL_JoystickType)
  #:c-id SDL_GetJoystickType)

;; SDL_GetJoystickGUID: Get the GUID of an opened joystick
;; Returns: 16-byte GUID struct (by value)
(define-sdl SDL-GetJoystickGUID
  (_fun _SDL_Joystick-pointer -> (_array _uint8 16))
  #:c-id SDL_GetJoystickGUID)

;; SDL_GetJoystickVendor: Get the vendor ID of an opened joystick
;; Returns: vendor ID, or 0 if unknown
(define-sdl SDL-GetJoystickVendor
  (_fun _SDL_Joystick-pointer -> _uint16)
  #:c-id SDL_GetJoystickVendor)

;; SDL_GetJoystickProduct: Get the product ID of an opened joystick
;; Returns: product ID, or 0 if unknown
(define-sdl SDL-GetJoystickProduct
  (_fun _SDL_Joystick-pointer -> _uint16)
  #:c-id SDL_GetJoystickProduct)

;; SDL_GetJoystickProductVersion: Get the product version of an opened joystick
;; Returns: product version, or 0 if unknown
(define-sdl SDL-GetJoystickProductVersion
  (_fun _SDL_Joystick-pointer -> _uint16)
  #:c-id SDL_GetJoystickProductVersion)

;; SDL_GetJoystickSerial: Get the serial number of an opened joystick
;; Returns: serial number string, or NULL if unavailable
(define-sdl SDL-GetJoystickSerial
  (_fun _SDL_Joystick-pointer -> _string/utf-8)
  #:c-id SDL_GetJoystickSerial)

;; ============================================================================
;; Capabilities
;; ============================================================================

;; SDL_GetNumJoystickAxes: Get the number of axes on a joystick
;; Returns: number of axes, or -1 on error
(define-sdl SDL-GetNumJoystickAxes
  (_fun _SDL_Joystick-pointer -> _int)
  #:c-id SDL_GetNumJoystickAxes)

;; SDL_GetNumJoystickBalls: Get the number of trackballs on a joystick
;; Returns: number of balls, or -1 on error
(define-sdl SDL-GetNumJoystickBalls
  (_fun _SDL_Joystick-pointer -> _int)
  #:c-id SDL_GetNumJoystickBalls)

;; SDL_GetNumJoystickButtons: Get the number of buttons on a joystick
;; Returns: number of buttons, or -1 on error
(define-sdl SDL-GetNumJoystickButtons
  (_fun _SDL_Joystick-pointer -> _int)
  #:c-id SDL_GetNumJoystickButtons)

;; SDL_GetNumJoystickHats: Get the number of hats on a joystick
;; Returns: number of hats, or -1 on error
(define-sdl SDL-GetNumJoystickHats
  (_fun _SDL_Joystick-pointer -> _int)
  #:c-id SDL_GetNumJoystickHats)

;; ============================================================================
;; State
;; ============================================================================

;; SDL_GetJoystickAxis: Get the current state of an axis
;; joystick: the joystick to query
;; axis: axis index (0 to SDL_GetNumJoystickAxes-1)
;; Returns: axis value (-32768 to 32767)
(define-sdl SDL-GetJoystickAxis
  (_fun _SDL_Joystick-pointer _int -> _sint16)
  #:c-id SDL_GetJoystickAxis)

;; SDL_GetJoystickAxisInitialState: Get the initial state of an axis
;; joystick: the joystick to query
;; axis: axis index
;; Returns: (values has-initial-state initial-value)
(define-sdl SDL-GetJoystickAxisInitialState
  (_fun _SDL_Joystick-pointer _int (state : (_ptr o _sint16))
        -> (result : _stdbool)
        -> (values result state))
  #:c-id SDL_GetJoystickAxisInitialState)

;; SDL_GetJoystickBall: Get the ball axis change since last poll
;; joystick: the joystick to query
;; ball: ball index
;; Returns: (values success dx dy)
(define-sdl SDL-GetJoystickBall
  (_fun _SDL_Joystick-pointer _int
        (dx : (_ptr o _int))
        (dy : (_ptr o _int))
        -> (result : _stdbool)
        -> (values result dx dy))
  #:c-id SDL_GetJoystickBall)

;; SDL_GetJoystickButton: Get the current state of a button
;; joystick: the joystick to query
;; button: button index (0 to SDL_GetNumJoystickButtons-1)
;; Returns: true if pressed, false if not
(define-sdl SDL-GetJoystickButton
  (_fun _SDL_Joystick-pointer _int -> _stdbool)
  #:c-id SDL_GetJoystickButton)

;; SDL_GetJoystickHat: Get the current state of a hat
;; joystick: the joystick to query
;; hat: hat index (0 to SDL_GetNumJoystickHats-1)
;; Returns: hat position (SDL_HAT_* constant)
(define-sdl SDL-GetJoystickHat
  (_fun _SDL_Joystick-pointer _int -> _uint8)
  #:c-id SDL_GetJoystickHat)

;; ============================================================================
;; Player Index
;; ============================================================================

;; SDL_GetJoystickPlayerIndex: Get the player index of an opened joystick
;; Returns: player index, or -1 if not set
(define-sdl SDL-GetJoystickPlayerIndex
  (_fun _SDL_Joystick-pointer -> _int)
  #:c-id SDL_GetJoystickPlayerIndex)

;; SDL_SetJoystickPlayerIndex: Set the player index of an opened joystick
;; Returns: true on success
(define-sdl SDL-SetJoystickPlayerIndex
  (_fun _SDL_Joystick-pointer _int -> _sdl-bool)
  #:c-id SDL_SetJoystickPlayerIndex)

;; ============================================================================
;; Rumble
;; ============================================================================

;; SDL_RumbleJoystick: Start a rumble effect
;; joystick: the joystick to rumble
;; low_frequency_rumble: intensity of the low frequency motor (0-65535)
;; high_frequency_rumble: intensity of the high frequency motor (0-65535)
;; duration_ms: duration in milliseconds, or 0 for infinite
;; Returns: true on success
(define-sdl SDL-RumbleJoystick
  (_fun _SDL_Joystick-pointer _uint16 _uint16 _uint32 -> _sdl-bool)
  #:c-id SDL_RumbleJoystick)

;; SDL_RumbleJoystickTriggers: Start a rumble effect on triggers (Xbox-style)
;; joystick: the joystick to rumble
;; left_rumble: intensity for left trigger (0-65535)
;; right_rumble: intensity for right trigger (0-65535)
;; duration_ms: duration in milliseconds, or 0 for infinite
;; Returns: true on success (not all controllers support this)
(define-sdl SDL-RumbleJoystickTriggers
  (_fun _SDL_Joystick-pointer _uint16 _uint16 _uint32 -> _sdl-bool)
  #:c-id SDL_RumbleJoystickTriggers)

;; ============================================================================
;; LED
;; ============================================================================

;; SDL_SetJoystickLED: Set the LED color on a joystick
;; joystick: the joystick to set LED on
;; red, green, blue: LED color (0-255 each)
;; Returns: true on success (not all controllers have LEDs)
(define-sdl SDL-SetJoystickLED
  (_fun _SDL_Joystick-pointer _uint8 _uint8 _uint8 -> _sdl-bool)
  #:c-id SDL_SetJoystickLED)

;; ============================================================================
;; Power
;; ============================================================================

;; SDL_GetJoystickPowerInfo: Get the power info of a joystick
;; joystick: the joystick to query
;; Returns: (values power-state percent) where percent is 0-100 or -1 if unknown
(define-sdl SDL-GetJoystickPowerInfo
  (_fun _SDL_Joystick-pointer (percent : (_ptr o _int))
        -> (state : _SDL_PowerState)
        -> (values state percent))
  #:c-id SDL_GetJoystickPowerInfo)

;; SDL_GetJoystickConnectionState: Get the connection state of a joystick
;; Returns: SDL_JoystickConnectionState enum value
(define-sdl SDL-GetJoystickConnectionState
  (_fun _SDL_Joystick-pointer -> _SDL_JoystickConnectionState)
  #:c-id SDL_GetJoystickConnectionState)

;; ============================================================================
;; Events Control
;; ============================================================================

;; SDL_SetJoystickEventsEnabled: Enable/disable joystick event processing
;; enabled: true to enable events
(define-sdl SDL-SetJoystickEventsEnabled
  (_fun _stdbool -> _void)
  #:c-id SDL_SetJoystickEventsEnabled)

;; SDL_JoystickEventsEnabled: Check if joystick events are enabled
;; Returns: true if events are enabled
(define-sdl SDL-JoystickEventsEnabled
  (_fun -> _stdbool)
  #:c-id SDL_JoystickEventsEnabled)

;; ============================================================================
;; Update
;; ============================================================================

;; SDL_UpdateJoysticks: Update the state of all joysticks
;; Call this if you disable joystick events and poll state manually
(define-sdl SDL-UpdateJoysticks
  (_fun -> _void)
  #:c-id SDL_UpdateJoysticks)

;; ============================================================================
;; Locking
;; ============================================================================

;; SDL_LockJoysticks: Lock joysticks for multi-threaded access
(define-sdl SDL-LockJoysticks
  (_fun -> _void)
  #:c-id SDL_LockJoysticks)

;; SDL_UnlockJoysticks: Unlock joysticks after multi-threaded access
(define-sdl SDL-UnlockJoysticks
  (_fun -> _void)
  #:c-id SDL_UnlockJoysticks)
