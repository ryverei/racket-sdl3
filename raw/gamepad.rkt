#lang racket/base

;; SDL3 Gamepad Input
;;
;; High-level gamepad API with standardized button/axis names.
;; Maps controllers to a consistent layout (Xbox-style) regardless of manufacturer.
;; For low-level joystick access, use raw/joystick.rkt instead.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt"
         "../private/constants.rkt")

(provide ;; Detection
         SDL-HasGamepad
         SDL-GetGamepads
         SDL-IsGamepad
         ;; Opening/Closing
         SDL-OpenGamepad
         SDL-CloseGamepad
         SDL-GamepadConnected
         SDL-GetGamepadFromID
         SDL-GetGamepadFromPlayerIndex
         ;; Info (before opening - by instance ID)
         SDL-GetGamepadNameForID
         SDL-GetGamepadPathForID
         SDL-GetGamepadPlayerIndexForID
         SDL-GetGamepadGUIDForID
         SDL-GetGamepadVendorForID
         SDL-GetGamepadProductForID
         SDL-GetGamepadProductVersionForID
         SDL-GetGamepadTypeForID
         ;; Info (after opening)
         SDL-GetGamepadName
         SDL-GetGamepadPath
         SDL-GetGamepadID
         SDL-GetGamepadType
         SDL-GetRealGamepadType
         SDL-GetGamepadVendor
         SDL-GetGamepadProduct
         SDL-GetGamepadProductVersion
         SDL-GetGamepadSerial
         SDL-GetGamepadJoystick
         ;; State - Buttons
         SDL-GetGamepadButton
         SDL-GamepadHasButton
         ;; State - Axes
         SDL-GetGamepadAxis
         SDL-GamepadHasAxis
         ;; Button labels
         SDL-GetGamepadButtonLabel
         SDL-GetGamepadButtonLabelForType
         ;; String conversion
         SDL-GetGamepadStringForButton
         SDL-GetGamepadButtonFromString
         SDL-GetGamepadStringForAxis
         SDL-GetGamepadAxisFromString
         SDL-GetGamepadStringForType
         SDL-GetGamepadTypeFromString
         ;; Player index
         SDL-GetGamepadPlayerIndex
         SDL-SetGamepadPlayerIndex
         ;; Rumble
         SDL-RumbleGamepad
         SDL-RumbleGamepadTriggers
         ;; LED
         SDL-SetGamepadLED
         ;; Power
         SDL-GetGamepadPowerInfo
         SDL-GetGamepadConnectionState
         ;; Touchpad
         SDL-GetNumGamepadTouchpads
         SDL-GetNumGamepadTouchpadFingers
         SDL-GetGamepadTouchpadFinger
         ;; Sensor
         SDL-GamepadHasSensor
         SDL-SetGamepadSensorEnabled
         SDL-GamepadSensorEnabled
         SDL-GetGamepadSensorData
         SDL-GetGamepadSensorDataRate
         ;; Events control
         SDL-SetGamepadEventsEnabled
         SDL-GamepadEventsEnabled
         ;; Update
         SDL-UpdateGamepads
         ;; Mapping
         SDL-GetGamepadMapping
         SDL-GetGamepadMappingForID)

;; ============================================================================
;; Detection
;; ============================================================================

;; SDL_HasGamepad: Check if there are any gamepads connected
;; Returns: true if gamepads are connected
(define-sdl SDL-HasGamepad
  (_fun -> _stdbool)
  #:c-id SDL_HasGamepad)

;; SDL_GetGamepads: Get a list of connected gamepad instance IDs
;; Returns: (values array count) - array must be freed with SDL_free
(define-sdl SDL-GetGamepads
  (_fun (count : (_ptr o _int)) -> (arr : _pointer)
        -> (values arr count))
  #:c-id SDL_GetGamepads)

;; SDL_IsGamepad: Check if a joystick instance ID is a gamepad
;; Returns: true if this joystick is supported as a gamepad
(define-sdl SDL-IsGamepad
  (_fun _SDL_JoystickID -> _stdbool)
  #:c-id SDL_IsGamepad)

;; ============================================================================
;; Opening/Closing
;; ============================================================================

;; SDL_OpenGamepad: Open a gamepad for use
;; instance_id: the joystick instance ID from SDL_GetGamepads
;; Returns: gamepad pointer, or NULL on failure
(define-sdl SDL-OpenGamepad
  (_fun _SDL_JoystickID -> _SDL_Gamepad-pointer/null)
  #:c-id SDL_OpenGamepad)

;; SDL_CloseGamepad: Close a gamepad previously opened with SDL_OpenGamepad
;; gamepad: the gamepad to close
(define-sdl SDL-CloseGamepad
  (_fun _SDL_Gamepad-pointer -> _void)
  #:c-id SDL_CloseGamepad)

;; SDL_GamepadConnected: Check if a gamepad is still connected
;; gamepad: the gamepad to check
;; Returns: true if still connected
(define-sdl SDL-GamepadConnected
  (_fun _SDL_Gamepad-pointer -> _stdbool)
  #:c-id SDL_GamepadConnected)

;; SDL_GetGamepadFromID: Get the gamepad associated with an instance ID
;; Returns: gamepad pointer, or NULL if not found
(define-sdl SDL-GetGamepadFromID
  (_fun _SDL_JoystickID -> _SDL_Gamepad-pointer/null)
  #:c-id SDL_GetGamepadFromID)

;; SDL_GetGamepadFromPlayerIndex: Get the gamepad associated with a player index
;; Returns: gamepad pointer, or NULL if not found
(define-sdl SDL-GetGamepadFromPlayerIndex
  (_fun _int -> _SDL_Gamepad-pointer/null)
  #:c-id SDL_GetGamepadFromPlayerIndex)

;; ============================================================================
;; Info (before opening - by instance ID)
;; ============================================================================

;; SDL_GetGamepadNameForID: Get the name of a gamepad (by instance ID)
(define-sdl SDL-GetGamepadNameForID
  (_fun _SDL_JoystickID -> _string/utf-8)
  #:c-id SDL_GetGamepadNameForID)

;; SDL_GetGamepadPathForID: Get the path of a gamepad (by instance ID)
(define-sdl SDL-GetGamepadPathForID
  (_fun _SDL_JoystickID -> _string/utf-8)
  #:c-id SDL_GetGamepadPathForID)

;; SDL_GetGamepadPlayerIndexForID: Get the player index of a gamepad (by instance ID)
(define-sdl SDL-GetGamepadPlayerIndexForID
  (_fun _SDL_JoystickID -> _int)
  #:c-id SDL_GetGamepadPlayerIndexForID)

;; SDL_GetGamepadGUIDForID: Get the GUID of a gamepad (by instance ID)
(define-sdl SDL-GetGamepadGUIDForID
  (_fun _SDL_JoystickID -> (_array _uint8 16))
  #:c-id SDL_GetGamepadGUIDForID)

;; SDL_GetGamepadVendorForID: Get the vendor ID of a gamepad (by instance ID)
(define-sdl SDL-GetGamepadVendorForID
  (_fun _SDL_JoystickID -> _uint16)
  #:c-id SDL_GetGamepadVendorForID)

;; SDL_GetGamepadProductForID: Get the product ID of a gamepad (by instance ID)
(define-sdl SDL-GetGamepadProductForID
  (_fun _SDL_JoystickID -> _uint16)
  #:c-id SDL_GetGamepadProductForID)

;; SDL_GetGamepadProductVersionForID: Get the product version (by instance ID)
(define-sdl SDL-GetGamepadProductVersionForID
  (_fun _SDL_JoystickID -> _uint16)
  #:c-id SDL_GetGamepadProductVersionForID)

;; SDL_GetGamepadTypeForID: Get the type of a gamepad (by instance ID)
(define-sdl SDL-GetGamepadTypeForID
  (_fun _SDL_JoystickID -> _SDL_GamepadType)
  #:c-id SDL_GetGamepadTypeForID)

;; ============================================================================
;; Info (after opening)
;; ============================================================================

;; SDL_GetGamepadName: Get the name of an opened gamepad
(define-sdl SDL-GetGamepadName
  (_fun _SDL_Gamepad-pointer -> _string/utf-8)
  #:c-id SDL_GetGamepadName)

;; SDL_GetGamepadPath: Get the path of an opened gamepad
(define-sdl SDL-GetGamepadPath
  (_fun _SDL_Gamepad-pointer -> _string/utf-8)
  #:c-id SDL_GetGamepadPath)

;; SDL_GetGamepadID: Get the instance ID of an opened gamepad
(define-sdl SDL-GetGamepadID
  (_fun _SDL_Gamepad-pointer -> _SDL_JoystickID)
  #:c-id SDL_GetGamepadID)

;; SDL_GetGamepadType: Get the type of an opened gamepad
(define-sdl SDL-GetGamepadType
  (_fun _SDL_Gamepad-pointer -> _SDL_GamepadType)
  #:c-id SDL_GetGamepadType)

;; SDL_GetRealGamepadType: Get the actual type (bypassing mapping overrides)
(define-sdl SDL-GetRealGamepadType
  (_fun _SDL_Gamepad-pointer -> _SDL_GamepadType)
  #:c-id SDL_GetRealGamepadType)

;; SDL_GetGamepadVendor: Get the vendor ID of an opened gamepad
(define-sdl SDL-GetGamepadVendor
  (_fun _SDL_Gamepad-pointer -> _uint16)
  #:c-id SDL_GetGamepadVendor)

;; SDL_GetGamepadProduct: Get the product ID of an opened gamepad
(define-sdl SDL-GetGamepadProduct
  (_fun _SDL_Gamepad-pointer -> _uint16)
  #:c-id SDL_GetGamepadProduct)

;; SDL_GetGamepadProductVersion: Get the product version of an opened gamepad
(define-sdl SDL-GetGamepadProductVersion
  (_fun _SDL_Gamepad-pointer -> _uint16)
  #:c-id SDL_GetGamepadProductVersion)

;; SDL_GetGamepadSerial: Get the serial number of an opened gamepad
(define-sdl SDL-GetGamepadSerial
  (_fun _SDL_Gamepad-pointer -> _string/utf-8)
  #:c-id SDL_GetGamepadSerial)

;; SDL_GetGamepadJoystick: Get the underlying joystick for a gamepad
;; Useful for accessing low-level joystick features
(define-sdl SDL-GetGamepadJoystick
  (_fun _SDL_Gamepad-pointer -> _SDL_Joystick-pointer/null)
  #:c-id SDL_GetGamepadJoystick)

;; ============================================================================
;; State - Buttons
;; ============================================================================

;; SDL_GetGamepadButton: Get the current state of a button
;; gamepad: the gamepad to query
;; button: SDL_GamepadButton enum value
;; Returns: true if pressed, false if not
(define-sdl SDL-GetGamepadButton
  (_fun _SDL_Gamepad-pointer _SDL_GamepadButton -> _stdbool)
  #:c-id SDL_GetGamepadButton)

;; SDL_GamepadHasButton: Check if a gamepad has a specific button
;; Returns: true if the gamepad has this button
(define-sdl SDL-GamepadHasButton
  (_fun _SDL_Gamepad-pointer _SDL_GamepadButton -> _stdbool)
  #:c-id SDL_GamepadHasButton)

;; ============================================================================
;; State - Axes
;; ============================================================================

;; SDL_GetGamepadAxis: Get the current state of an axis
;; gamepad: the gamepad to query
;; axis: SDL_GamepadAxis enum value
;; Returns: axis value (-32768 to 32767 for sticks, 0 to 32767 for triggers)
(define-sdl SDL-GetGamepadAxis
  (_fun _SDL_Gamepad-pointer _SDL_GamepadAxis -> _sint16)
  #:c-id SDL_GetGamepadAxis)

;; SDL_GamepadHasAxis: Check if a gamepad has a specific axis
;; Returns: true if the gamepad has this axis
(define-sdl SDL-GamepadHasAxis
  (_fun _SDL_Gamepad-pointer _SDL_GamepadAxis -> _stdbool)
  #:c-id SDL_GamepadHasAxis)

;; ============================================================================
;; Button Labels
;; ============================================================================

;; SDL_GetGamepadButtonLabel: Get the label for a button on this gamepad
;; Returns correct label (A/B/X/Y vs Cross/Circle/Square/Triangle)
;; for displaying button prompts
(define-sdl SDL-GetGamepadButtonLabel
  (_fun _SDL_Gamepad-pointer _SDL_GamepadButton -> _SDL_GamepadButtonLabel)
  #:c-id SDL_GetGamepadButtonLabel)

;; SDL_GetGamepadButtonLabelForType: Get the label for a button on a specific type
;; Useful for showing prompts before a gamepad is opened
(define-sdl SDL-GetGamepadButtonLabelForType
  (_fun _SDL_GamepadType _SDL_GamepadButton -> _SDL_GamepadButtonLabel)
  #:c-id SDL_GetGamepadButtonLabelForType)

;; ============================================================================
;; String Conversion
;; ============================================================================

;; SDL_GetGamepadStringForButton: Get the string name for a button enum
;; Returns: string like "a", "b", "x", "y", "back", "start", etc.
(define-sdl SDL-GetGamepadStringForButton
  (_fun _SDL_GamepadButton -> _string/utf-8)
  #:c-id SDL_GetGamepadStringForButton)

;; SDL_GetGamepadButtonFromString: Parse a button string to enum
;; Returns: SDL_GamepadButton enum, or SDL_GAMEPAD_BUTTON_INVALID
(define-sdl SDL-GetGamepadButtonFromString
  (_fun _string/utf-8 -> _SDL_GamepadButton)
  #:c-id SDL_GetGamepadButtonFromString)

;; SDL_GetGamepadStringForAxis: Get the string name for an axis enum
;; Returns: string like "leftx", "lefty", "rightx", "righty", etc.
(define-sdl SDL-GetGamepadStringForAxis
  (_fun _SDL_GamepadAxis -> _string/utf-8)
  #:c-id SDL_GetGamepadStringForAxis)

;; SDL_GetGamepadAxisFromString: Parse an axis string to enum
;; Returns: SDL_GamepadAxis enum, or SDL_GAMEPAD_AXIS_INVALID
(define-sdl SDL-GetGamepadAxisFromString
  (_fun _string/utf-8 -> _SDL_GamepadAxis)
  #:c-id SDL_GetGamepadAxisFromString)

;; SDL_GetGamepadStringForType: Get the string name for a gamepad type
;; Returns: string like "xbox360", "xboxone", "ps4", "ps5", etc.
(define-sdl SDL-GetGamepadStringForType
  (_fun _SDL_GamepadType -> _string/utf-8)
  #:c-id SDL_GetGamepadStringForType)

;; SDL_GetGamepadTypeFromString: Parse a type string to enum
;; Returns: SDL_GamepadType enum, or SDL_GAMEPAD_TYPE_UNKNOWN
(define-sdl SDL-GetGamepadTypeFromString
  (_fun _string/utf-8 -> _SDL_GamepadType)
  #:c-id SDL_GetGamepadTypeFromString)

;; ============================================================================
;; Player Index
;; ============================================================================

;; SDL_GetGamepadPlayerIndex: Get the player index of an opened gamepad
(define-sdl SDL-GetGamepadPlayerIndex
  (_fun _SDL_Gamepad-pointer -> _int)
  #:c-id SDL_GetGamepadPlayerIndex)

;; SDL_SetGamepadPlayerIndex: Set the player index of an opened gamepad
(define-sdl SDL-SetGamepadPlayerIndex
  (_fun _SDL_Gamepad-pointer _int -> _sdl-bool)
  #:c-id SDL_SetGamepadPlayerIndex)

;; ============================================================================
;; Rumble
;; ============================================================================

;; SDL_RumbleGamepad: Start a rumble effect
;; gamepad: the gamepad to rumble
;; low_frequency_rumble: intensity of the low frequency motor (0-65535)
;; high_frequency_rumble: intensity of the high frequency motor (0-65535)
;; duration_ms: duration in milliseconds, or 0 for infinite
;; Returns: true on success
(define-sdl SDL-RumbleGamepad
  (_fun _SDL_Gamepad-pointer _uint16 _uint16 _uint32 -> _sdl-bool)
  #:c-id SDL_RumbleGamepad)

;; SDL_RumbleGamepadTriggers: Start a rumble effect on triggers (Xbox-style)
;; gamepad: the gamepad to rumble
;; left_rumble: intensity for left trigger (0-65535)
;; right_rumble: intensity for right trigger (0-65535)
;; duration_ms: duration in milliseconds, or 0 for infinite
;; Returns: true on success (not all controllers support this)
(define-sdl SDL-RumbleGamepadTriggers
  (_fun _SDL_Gamepad-pointer _uint16 _uint16 _uint32 -> _sdl-bool)
  #:c-id SDL_RumbleGamepadTriggers)

;; ============================================================================
;; LED
;; ============================================================================

;; SDL_SetGamepadLED: Set the LED color on a gamepad
;; gamepad: the gamepad to set LED on
;; red, green, blue: LED color (0-255 each)
;; Returns: true on success (not all controllers have LEDs)
(define-sdl SDL-SetGamepadLED
  (_fun _SDL_Gamepad-pointer _uint8 _uint8 _uint8 -> _sdl-bool)
  #:c-id SDL_SetGamepadLED)

;; ============================================================================
;; Power
;; ============================================================================

;; SDL_GetGamepadPowerInfo: Get the power info of a gamepad
;; Returns: (values power-state percent) where percent is 0-100 or -1 if unknown
(define-sdl SDL-GetGamepadPowerInfo
  (_fun _SDL_Gamepad-pointer (percent : (_ptr o _int))
        -> (state : _SDL_PowerState)
        -> (values state percent))
  #:c-id SDL_GetGamepadPowerInfo)

;; SDL_GetGamepadConnectionState: Get the connection state of a gamepad
(define-sdl SDL-GetGamepadConnectionState
  (_fun _SDL_Gamepad-pointer -> _SDL_JoystickConnectionState)
  #:c-id SDL_GetGamepadConnectionState)

;; ============================================================================
;; Touchpad
;; ============================================================================

;; SDL_GetNumGamepadTouchpads: Get the number of touchpads on the gamepad
(define-sdl SDL-GetNumGamepadTouchpads
  (_fun _SDL_Gamepad-pointer -> _int)
  #:c-id SDL_GetNumGamepadTouchpads)

;; SDL_GetNumGamepadTouchpadFingers: Get the max fingers supported on a touchpad
(define-sdl SDL-GetNumGamepadTouchpadFingers
  (_fun _SDL_Gamepad-pointer _int -> _int)
  #:c-id SDL_GetNumGamepadTouchpadFingers)

;; SDL_GetGamepadTouchpadFinger: Get the state of a touchpad finger
;; Returns: (values success down x y pressure)
(define-sdl SDL-GetGamepadTouchpadFinger
  (_fun _SDL_Gamepad-pointer _int _int
        (down : (_ptr o _stdbool))
        (x : (_ptr o _float))
        (y : (_ptr o _float))
        (pressure : (_ptr o _float))
        -> (result : _stdbool)
        -> (values result down x y pressure))
  #:c-id SDL_GetGamepadTouchpadFinger)

;; ============================================================================
;; Sensor
;; ============================================================================

;; SDL_GamepadHasSensor: Check if a gamepad has a specific sensor
;; type: SDL_SensorType (gyro, accelerometer)
(define-sdl SDL-GamepadHasSensor
  (_fun _SDL_Gamepad-pointer _int -> _stdbool)  ; _int for SDL_SensorType
  #:c-id SDL_GamepadHasSensor)

;; SDL_SetGamepadSensorEnabled: Enable/disable a sensor on the gamepad
(define-sdl SDL-SetGamepadSensorEnabled
  (_fun _SDL_Gamepad-pointer _int _stdbool -> _sdl-bool)
  #:c-id SDL_SetGamepadSensorEnabled)

;; SDL_GamepadSensorEnabled: Check if a sensor is enabled
(define-sdl SDL-GamepadSensorEnabled
  (_fun _SDL_Gamepad-pointer _int -> _stdbool)
  #:c-id SDL_GamepadSensorEnabled)

;; SDL_GetGamepadSensorData: Get the current sensor data
;; data: pointer to float array to receive data
;; num_values: number of values to read (3 for gyro/accel)
(define-sdl SDL-GetGamepadSensorData
  (_fun _SDL_Gamepad-pointer _int _pointer _int -> _sdl-bool)
  #:c-id SDL_GetGamepadSensorData)

;; SDL_GetGamepadSensorDataRate: Get the data rate of a sensor
;; Returns: data rate in Hz, or 0 if unsupported
(define-sdl SDL-GetGamepadSensorDataRate
  (_fun _SDL_Gamepad-pointer _int -> _float)
  #:c-id SDL_GetGamepadSensorDataRate)

;; ============================================================================
;; Events Control
;; ============================================================================

;; SDL_SetGamepadEventsEnabled: Enable/disable gamepad event processing
(define-sdl SDL-SetGamepadEventsEnabled
  (_fun _stdbool -> _void)
  #:c-id SDL_SetGamepadEventsEnabled)

;; SDL_GamepadEventsEnabled: Check if gamepad events are enabled
(define-sdl SDL-GamepadEventsEnabled
  (_fun -> _stdbool)
  #:c-id SDL_GamepadEventsEnabled)

;; ============================================================================
;; Update
;; ============================================================================

;; SDL_UpdateGamepads: Update the state of all gamepads
;; Call this if you disable gamepad events and poll state manually
(define-sdl SDL-UpdateGamepads
  (_fun -> _void)
  #:c-id SDL_UpdateGamepads)

;; ============================================================================
;; Mapping
;; ============================================================================

;; SDL_GetGamepadMapping: Get the current mapping string for a gamepad
;; Returns: mapping string (must be freed with SDL_free), or NULL
(define-sdl SDL-GetGamepadMapping
  (_fun _SDL_Gamepad-pointer -> _pointer)  ; returns malloc'd string
  #:c-id SDL_GetGamepadMapping)

;; SDL_GetGamepadMappingForID: Get the mapping string for a gamepad by ID
(define-sdl SDL-GetGamepadMappingForID
  (_fun _SDL_JoystickID -> _pointer)  ; returns malloc'd string
  #:c-id SDL_GetGamepadMappingForID)
