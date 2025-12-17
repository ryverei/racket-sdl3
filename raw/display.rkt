#lang racket/base

;; SDL3 Display Management
;;
;; Functions for querying display/monitor information.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-GetDisplays
         SDL-GetPrimaryDisplay
         SDL-GetDisplayName
         SDL-GetDisplayBounds
         SDL-GetDisplayUsableBounds
         SDL-GetCurrentDisplayMode
         SDL-GetDesktopDisplayMode
         SDL-GetFullscreenDisplayModes
         SDL-GetDisplayForWindow
         SDL-GetDisplayContentScale
         SDL-GetWindowDisplayScale)

;; ============================================================================
;; Display Management
;; ============================================================================

;; SDL_GetDisplays: Get a list of currently connected displays
;; count: pointer to receive the number of displays
;; Returns: pointer to array of SDL_DisplayID values (free with SDL_free)
(define-sdl SDL-GetDisplays
  (_fun (count : (_ptr o _int))
        -> (result : _pointer)
        -> (values result count))
  #:c-id SDL_GetDisplays)

;; SDL_GetPrimaryDisplay: Get the primary display
;; Returns: the display ID of the primary display, or 0 on failure
(define-sdl SDL-GetPrimaryDisplay
  (_fun -> _SDL_DisplayID)
  #:c-id SDL_GetPrimaryDisplay)

;; SDL_GetDisplayName: Get the name of a display
;; displayID: the instance ID of the display to query
;; Returns: the name of the display, or NULL on failure
(define-sdl SDL-GetDisplayName
  (_fun _SDL_DisplayID -> _string)
  #:c-id SDL_GetDisplayName)

;; SDL_GetDisplayBounds: Get the desktop area represented by a display
;; displayID: the instance ID of the display to query
;; rect: pointer to SDL_Rect to fill with the display bounds
;; Returns: true on success, false on failure
(define-sdl SDL-GetDisplayBounds
  (_fun _SDL_DisplayID _SDL_Rect-pointer -> _sdl-bool)
  #:c-id SDL_GetDisplayBounds)

;; SDL_GetDisplayUsableBounds: Get the usable desktop area represented by a display
;; This excludes areas like taskbars/docks that take up screen space
;; displayID: the instance ID of the display to query
;; rect: pointer to SDL_Rect to fill with the usable bounds
;; Returns: true on success, false on failure
(define-sdl SDL-GetDisplayUsableBounds
  (_fun _SDL_DisplayID _SDL_Rect-pointer -> _sdl-bool)
  #:c-id SDL_GetDisplayUsableBounds)

;; SDL_GetCurrentDisplayMode: Get information about the current display mode
;; displayID: the instance ID of the display to query
;; Returns: pointer to the display mode structure, or NULL on failure
;; Note: The returned pointer is owned by SDL - don't free it
(define-sdl SDL-GetCurrentDisplayMode
  (_fun _SDL_DisplayID -> _SDL_DisplayMode-pointer/null)
  #:c-id SDL_GetCurrentDisplayMode)

;; SDL_GetDesktopDisplayMode: Get information about the desktop display mode
;; This returns the mode that was being used when SDL was initialized
;; displayID: the instance ID of the display to query
;; Returns: pointer to the display mode structure, or NULL on failure
;; Note: The returned pointer is owned by SDL - don't free it
(define-sdl SDL-GetDesktopDisplayMode
  (_fun _SDL_DisplayID -> _SDL_DisplayMode-pointer/null)
  #:c-id SDL_GetDesktopDisplayMode)

;; SDL_GetFullscreenDisplayModes: Get the available fullscreen display modes
;; displayID: the instance ID of the display to query
;; count: pointer to receive the number of modes
;; Returns: pointer to array of SDL_DisplayMode pointers (free with SDL_free)
(define-sdl SDL-GetFullscreenDisplayModes
  (_fun _SDL_DisplayID
        (count : (_ptr o _int))
        -> (result : _pointer)
        -> (values result count))
  #:c-id SDL_GetFullscreenDisplayModes)

;; SDL_GetDisplayForWindow: Get the display associated with a window
;; window: the window to query
;; Returns: the display ID of the display containing the center of the window,
;;          or 0 on failure
(define-sdl SDL-GetDisplayForWindow
  (_fun _SDL_Window-pointer -> _SDL_DisplayID)
  #:c-id SDL_GetDisplayForWindow)

;; SDL_GetDisplayContentScale: Get the content scale of a display
;; displayID: the instance ID of the display to query
;; Returns: the content scale of the display, or 0.0 on failure
;; (e.g., 2.0 means HiDPI/Retina display)
(define-sdl SDL-GetDisplayContentScale
  (_fun _SDL_DisplayID -> _float)
  #:c-id SDL_GetDisplayContentScale)

;; SDL_GetWindowDisplayScale: Get the display scale of a window
;; This combines the window's pixel density with the display's content scale
;; window: the window to query
;; Returns: the content scale of the window, or 0.0 on failure
(define-sdl SDL-GetWindowDisplayScale
  (_fun _SDL_Window-pointer -> _float)
  #:c-id SDL_GetWindowDisplayScale)
