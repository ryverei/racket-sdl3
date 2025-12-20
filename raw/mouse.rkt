#lang racket/base

;; SDL3 Mouse Input
;;
;; Functions for mouse input and cursor handling.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide ;; Mouse state
         SDL-HasMouse
         SDL-GetMice
         SDL-GetMouseNameForID
         SDL-GetMouseFocus
         SDL-GetMouseState
         SDL-GetRelativeMouseState
         SDL-GetGlobalMouseState
         SDL-SetWindowRelativeMouseMode
         SDL-GetWindowRelativeMouseMode
         SDL-WarpMouseInWindow
         SDL-WarpMouseGlobal
         SDL-CaptureMouse
         ;; Cursor
         SDL-CreateSystemCursor
         SDL-SetCursor
         SDL-GetCursor
         SDL-DestroyCursor
         SDL-ShowCursor
         SDL-HideCursor
         SDL-CursorVisible)

;; ============================================================================
;; Mouse Enumeration
;; ============================================================================

;; SDL_HasMouse: Check if any mouse is connected
;; Returns: true if a mouse is connected, false otherwise
(define-sdl SDL-HasMouse (_fun -> _sdl-bool)
  #:c-id SDL_HasMouse)

;; SDL_GetMice: Get a list of connected mouse IDs
;; count: pointer to receive the number of mice (can be NULL)
;; Returns: pointer to a 0-terminated array of SDL_MouseID values
;; The returned array must be freed with SDL_free
(define-sdl SDL-GetMice
  (_fun (count : (_ptr o _int))
        -> (result : _pointer)
        -> (values result count))
  #:c-id SDL_GetMice)

;; SDL_GetMouseNameForID: Get the name of a mouse by instance ID
;; instance_id: the SDL_MouseID to query
;; Returns: the name of the mouse, or NULL on failure
(define-sdl SDL-GetMouseNameForID
  (_fun _SDL_MouseID -> _string/utf-8)
  #:c-id SDL_GetMouseNameForID)

;; SDL_GetMouseFocus: Get the window that currently has mouse focus
;; Returns: the window with mouse focus, or NULL if none
(define-sdl SDL-GetMouseFocus
  (_fun -> _SDL_Window-pointer/null)
  #:c-id SDL_GetMouseFocus)

;; ============================================================================
;; Mouse State
;; ============================================================================

;; SDL_GetMouseState: Get the current state of the mouse
;; x: pointer to receive x position (can be NULL)
;; y: pointer to receive y position (can be NULL)
;; Returns: SDL_MouseButtonFlags bitmask of button states
(define-sdl SDL-GetMouseState
  (_fun _pointer _pointer -> _uint32)
  #:c-id SDL_GetMouseState)

;; SDL_GetRelativeMouseState: Get the relative mouse state (delta since last call)
;; Returns: (values buttons dx dy) - button flags and relative motion
(define-sdl SDL-GetRelativeMouseState
  (_fun (x : (_ptr o _float))
        (y : (_ptr o _float))
        -> (buttons : _uint32)
        -> (values buttons x y))
  #:c-id SDL_GetRelativeMouseState)

;; SDL_SetWindowRelativeMouseMode: Enable/disable relative mouse mode for a window
;; window: the window to set
;; enabled: true to enable relative mode (hides cursor, captures mouse)
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowRelativeMouseMode
  (_fun _SDL_Window-pointer _stdbool -> _sdl-bool)
  #:c-id SDL_SetWindowRelativeMouseMode)

;; SDL_GetWindowRelativeMouseMode: Get the relative mouse mode state for a window
;; window: the window to query
;; Returns: true if relative mode is enabled
(define-sdl SDL-GetWindowRelativeMouseMode
  (_fun _SDL_Window-pointer -> _stdbool)
  #:c-id SDL_GetWindowRelativeMouseMode)

;; SDL_GetGlobalMouseState: Get the current state of the mouse in global screen coordinates
;; Returns: (values buttons x y) - button flags and global position
(define-sdl SDL-GetGlobalMouseState
  (_fun (x : (_ptr o _float))
        (y : (_ptr o _float))
        -> (buttons : _uint32)
        -> (values buttons x y))
  #:c-id SDL_GetGlobalMouseState)

;; SDL_WarpMouseInWindow: Move the mouse cursor to the given position within a window
;; window: the window to warp mouse in (can be NULL for focused window)
;; x: x coordinate within the window
;; y: y coordinate within the window
(define-sdl SDL-WarpMouseInWindow
  (_fun _SDL_Window-pointer/null _float _float -> _void)
  #:c-id SDL_WarpMouseInWindow)

;; SDL_WarpMouseGlobal: Move the mouse cursor to the given position in global screen space
;; x: x coordinate in global screen space
;; y: y coordinate in global screen space
;; Returns: true on success, false on failure (may not be supported on all platforms)
(define-sdl SDL-WarpMouseGlobal
  (_fun _float _float -> _sdl-bool)
  #:c-id SDL_WarpMouseGlobal)

;; SDL_CaptureMouse: Capture the mouse to track input outside a window
;; enabled: true to enable capture, false to disable
;; Returns: true on success, false on failure
;; Note: While captured, mouse events are delivered to the focused window
;; even when the cursor is outside the window
(define-sdl SDL-CaptureMouse
  (_fun _stdbool -> _sdl-bool)
  #:c-id SDL_CaptureMouse)

;; ============================================================================
;; Cursor
;; ============================================================================

;; SDL_CreateSystemCursor: Create a system cursor
;; id: SDL_SystemCursor enum value
;; Returns: cursor pointer, or NULL on failure
(define-sdl SDL-CreateSystemCursor
  (_fun _SDL_SystemCursor -> _SDL_Cursor-pointer/null)
  #:c-id SDL_CreateSystemCursor)

;; SDL_SetCursor: Set the active cursor
;; cursor: cursor to set, or NULL to use default
;; Returns: true on success, false on failure
(define-sdl SDL-SetCursor
  (_fun _SDL_Cursor-pointer/null -> _sdl-bool)
  #:c-id SDL_SetCursor)

;; SDL_GetCursor: Get the active cursor
;; Returns: the active cursor, or NULL if no custom cursor is set
(define-sdl SDL-GetCursor
  (_fun -> _SDL_Cursor-pointer/null)
  #:c-id SDL_GetCursor)

;; SDL_DestroyCursor: Free a cursor created with SDL_CreateSystemCursor
;; cursor: the cursor to destroy
(define-sdl SDL-DestroyCursor
  (_fun _SDL_Cursor-pointer -> _void)
  #:c-id SDL_DestroyCursor)

;; SDL_ShowCursor: Show the cursor
;; Returns: true on success, false on failure
(define-sdl SDL-ShowCursor
  (_fun -> _sdl-bool)
  #:c-id SDL_ShowCursor)

;; SDL_HideCursor: Hide the cursor
;; Returns: true on success, false on failure
(define-sdl SDL-HideCursor
  (_fun -> _sdl-bool)
  #:c-id SDL_HideCursor)

;; SDL_CursorVisible: Check if the cursor is visible
;; Returns: true if the cursor is visible
(define-sdl SDL-CursorVisible
  (_fun -> _stdbool)
  #:c-id SDL_CursorVisible)
