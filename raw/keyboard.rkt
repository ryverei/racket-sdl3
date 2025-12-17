#lang racket/base

;; SDL3 Keyboard Input
;;
;; Functions for keyboard input handling.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-GetKeyboardState
         SDL-GetModState
         SDL-ResetKeyboard
         SDL-GetKeyFromScancode
         SDL-GetScancodeFromKey
         SDL-GetScancodeName
         SDL-GetScancodeFromName
         SDL-GetKeyFromName
         SDL-GetKeyName
         ;; Text input
         SDL-StartTextInput
         SDL-StopTextInput)

;; ============================================================================
;; Keyboard State
;; ============================================================================

;; SDL_GetKeyboardState: Get a snapshot of the current state of the keyboard
;; numkeys: pointer to receive the length of the returned array (can be NULL)
;; Returns: pointer to an array of bool values (true = pressed)
;; Note: The returned pointer is valid for the lifetime of the application
;; Use scancodes as indices into this array
(define-sdl SDL-GetKeyboardState
  (_fun (numkeys : (_ptr o _int))
        -> (result : _pointer)
        -> (values result numkeys))
  #:c-id SDL_GetKeyboardState)

;; SDL_GetModState: Get the current key modifier state
;; Returns: SDL_Keymod bitmask of currently active modifiers
(define-sdl SDL-GetModState (_fun -> _SDL_Keymod)
  #:c-id SDL_GetModState)

;; SDL_ResetKeyboard: Clear the state of the keyboard
;; This will generate key up events for all pressed keys
(define-sdl SDL-ResetKeyboard (_fun -> _void)
  #:c-id SDL_ResetKeyboard)

;; ============================================================================
;; Key/Scancode Conversion
;; ============================================================================

;; SDL_GetKeyFromScancode: Get the key code for a scancode according to current layout
;; scancode: the SDL_Scancode to query
;; modstate: the modifier state to use when translating
;; key_event: true if the keycode will be used in key events
;; Returns: the corresponding SDL_Keycode
(define-sdl SDL-GetKeyFromScancode
  (_fun _SDL_Scancode _SDL_Keymod _stdbool -> _SDL_Keycode)
  #:c-id SDL_GetKeyFromScancode)

;; SDL_GetScancodeFromKey: Get the scancode for a key code
;; key: the SDL_Keycode to query
;; modstate: pointer to receive the modifier state (can be NULL)
;; Returns: the corresponding SDL_Scancode
(define-sdl SDL-GetScancodeFromKey
  (_fun _SDL_Keycode _pointer -> _SDL_Scancode)
  #:c-id SDL_GetScancodeFromKey)

;; SDL_GetScancodeName: Get a human-readable name for a scancode
;; scancode: the SDL_Scancode to query
;; Returns: the name of the scancode (empty string if no name)
(define-sdl SDL-GetScancodeName (_fun _SDL_Scancode -> _string)
  #:c-id SDL_GetScancodeName)

;; SDL_GetScancodeFromName: Get a scancode from a human-readable name
;; name: the scancode name
;; Returns: the corresponding SDL_Scancode, or SDL_SCANCODE_UNKNOWN if not found
(define-sdl SDL-GetScancodeFromName (_fun _string -> _SDL_Scancode)
  #:c-id SDL_GetScancodeFromName)

;; SDL_GetKeyFromName: Get a key code from a human-readable name
;; name: the key name
;; Returns: the corresponding SDL_Keycode, or SDLK_UNKNOWN if not found
(define-sdl SDL-GetKeyFromName (_fun _string -> _SDL_Keycode)
  #:c-id SDL_GetKeyFromName)

;; SDL_GetKeyName: Get a human-readable name for a key
;; key: SDL_Keycode value
;; Returns: A human-readable key name string
(define-sdl SDL-GetKeyName (_fun _SDL_Keycode -> _string)
  #:c-id SDL_GetKeyName)

;; ============================================================================
;; Text Input
;; ============================================================================

;; SDL_StartTextInput: Start accepting text input events
;; window: the window to enable text input for
;; Returns: true on success, false on failure
(define-sdl SDL-StartTextInput (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_StartTextInput)

;; SDL_StopTextInput: Stop accepting text input events
;; window: the window to disable text input for
;; Returns: true on success, false on failure
(define-sdl SDL-StopTextInput (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_StopTextInput)
