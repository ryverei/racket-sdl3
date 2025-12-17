#lang racket/base

;; SDL3 Window Management
;;
;; Functions for creating, destroying, and managing windows.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-CreateWindow
         SDL-CreateWindowAndRenderer
         SDL-DestroyWindow
         SDL-SetWindowTitle
         SDL-GetWindowTitle
         SDL-SetWindowIcon
         SDL-GetWindowID
         SDL-GetWindowFromID
         SDL-ShowWindow
         SDL-HideWindow
         SDL-RaiseWindow
         SDL-MaximizeWindow
         SDL-MinimizeWindow
         SDL-RestoreWindow
         SDL-SetWindowMinimumSize
         SDL-SetWindowMaximumSize
         SDL-GetWindowMinimumSize
         SDL-GetWindowMaximumSize
         SDL-SetWindowBordered
         SDL-SetWindowResizable
         SDL-SetWindowOpacity
         SDL-GetWindowOpacity
         SDL-FlashWindow
         SDL-GetWindowSurface
         SDL-UpdateWindowSurface
         SDL-GetWindowPixelDensity
         SDL-GetWindowSize
         SDL-SetWindowSize
         SDL-GetWindowPosition
         SDL-SetWindowPosition
         SDL-GetWindowFlags
         SDL-SetWindowFullscreen)

;; ============================================================================
;; Window Creation/Destruction
;; ============================================================================

;; SDL_CreateWindow: Create a window with the specified title, size, and flags
;; title: The title of the window (UTF-8)
;; w: Width of the window in pixels
;; h: Height of the window in pixels
;; flags: SDL_WindowFlags bitmask
;; Returns: Pointer to the window, or NULL on failure
(define-sdl SDL-CreateWindow
  (_fun _string _int _int _SDL_WindowFlags -> _SDL_Window-pointer/null)
  #:c-id SDL_CreateWindow)

;; SDL_CreateWindowAndRenderer: Create a window and default renderer
;; title: The title of the window (UTF-8)
;; width: Width of the window in pixels
;; height: Height of the window in pixels
;; window_flags: SDL_WindowFlags bitmask
;; window: Pointer to receive the created window
;; renderer: Pointer to receive the created renderer
;; Returns: true on success, false on failure
(define-sdl SDL-CreateWindowAndRenderer
  (_fun _string _int _int _SDL_WindowFlags
        (window : (_ptr o _SDL_Window-pointer/null))
        (renderer : (_ptr o _SDL_Renderer-pointer/null))
        -> (result : _sdl-bool)
        -> (values result window renderer))
  #:c-id SDL_CreateWindowAndRenderer)

;; SDL_DestroyWindow: Destroy a window
(define-sdl SDL-DestroyWindow (_fun _SDL_Window-pointer -> _void)
  #:c-id SDL_DestroyWindow)

;; ============================================================================
;; Window Properties
;; ============================================================================

;; SDL_GetWindowPixelDensity: Get the pixel density of a window
;; window: the window to query
;; Returns: the pixel density (e.g., 2.0 for Retina displays)
(define-sdl SDL-GetWindowPixelDensity (_fun _SDL_Window-pointer -> _float)
  #:c-id SDL_GetWindowPixelDensity)

;; SDL_GetWindowSize: Get the size of a window's client area
;; window: the window to query
;; Returns: (values success? width height)
(define-sdl SDL-GetWindowSize
  (_fun _SDL_Window-pointer
        (w : (_ptr o _int))
        (h : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result w h))
  #:c-id SDL_GetWindowSize)

;; SDL_SetWindowSize: Set the size of a window's client area
;; window: the window to resize
;; w, h: the new width and height
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowSize
  (_fun _SDL_Window-pointer _int _int -> _sdl-bool)
  #:c-id SDL_SetWindowSize)

;; SDL_GetWindowPosition: Get the position of a window
;; window: the window to query
;; Returns: (values success? x y)
(define-sdl SDL-GetWindowPosition
  (_fun _SDL_Window-pointer
        (x : (_ptr o _int))
        (y : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result x y))
  #:c-id SDL_GetWindowPosition)

;; SDL_SetWindowPosition: Set the position of a window
;; window: the window to move
;; x, y: the new position
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowPosition
  (_fun _SDL_Window-pointer _int _int -> _sdl-bool)
  #:c-id SDL_SetWindowPosition)

;; SDL_GetWindowFlags: Get the window flags
;; window: the window to query
;; Returns: SDL_WindowFlags bitmask
(define-sdl SDL-GetWindowFlags
  (_fun _SDL_Window-pointer -> _SDL_WindowFlags)
  #:c-id SDL_GetWindowFlags)

;; SDL_SetWindowFullscreen: Set the fullscreen mode of a window
;; window: the window to modify
;; fullscreen: true for fullscreen, false for windowed
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowFullscreen
  (_fun _SDL_Window-pointer _stdbool -> _sdl-bool)
  #:c-id SDL_SetWindowFullscreen)

;; ============================================================================
;; Window Title and Icon
;; ============================================================================

;; SDL_SetWindowTitle: Set the title of a window
;; window: The window to modify
;; title: The new title (UTF-8)
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowTitle (_fun _SDL_Window-pointer _string -> _sdl-bool)
  #:c-id SDL_SetWindowTitle)

;; SDL_GetWindowTitle: Get the title of a window
;; window: The window to query
;; Returns: The title of the window (UTF-8), or empty string on failure
(define-sdl SDL-GetWindowTitle (_fun _SDL_Window-pointer -> _string)
  #:c-id SDL_GetWindowTitle)

;; SDL_SetWindowIcon: Set the icon for a window
;; window: The window to modify
;; icon: An SDL_Surface with the icon image
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowIcon (_fun _SDL_Window-pointer _SDL_Surface-pointer -> _sdl-bool)
  #:c-id SDL_SetWindowIcon)

;; SDL_GetWindowID: Get the numeric ID of a window
;; window: The window to query
;; Returns: The ID of the window, or 0 on failure
(define-sdl SDL-GetWindowID (_fun _SDL_Window-pointer -> _SDL_WindowID)
  #:c-id SDL_GetWindowID)

;; SDL_GetWindowFromID: Get a window from a stored ID
;; id: The ID of the window
;; Returns: The window associated with id, or NULL if not found
(define-sdl SDL-GetWindowFromID (_fun _SDL_WindowID -> _SDL_Window-pointer/null)
  #:c-id SDL_GetWindowFromID)

;; ============================================================================
;; Window Visibility
;; ============================================================================

;; SDL_ShowWindow: Show a window
;; window: The window to show
;; Returns: true on success, false on failure
(define-sdl SDL-ShowWindow (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_ShowWindow)

;; SDL_HideWindow: Hide a window
;; window: The window to hide
;; Returns: true on success, false on failure
(define-sdl SDL-HideWindow (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_HideWindow)

;; SDL_RaiseWindow: Raise a window above other windows and set input focus
;; window: The window to raise
;; Returns: true on success, false on failure
(define-sdl SDL-RaiseWindow (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_RaiseWindow)

;; SDL_MaximizeWindow: Make a window as large as possible
;; window: The window to maximize
;; Returns: true on success, false on failure
(define-sdl SDL-MaximizeWindow (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_MaximizeWindow)

;; SDL_MinimizeWindow: Minimize a window to an iconic representation
;; window: The window to minimize
;; Returns: true on success, false on failure
(define-sdl SDL-MinimizeWindow (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_MinimizeWindow)

;; SDL_RestoreWindow: Restore the size and position of a minimized/maximized window
;; window: The window to restore
;; Returns: true on success, false on failure
(define-sdl SDL-RestoreWindow (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_RestoreWindow)

;; ============================================================================
;; Window Constraints
;; ============================================================================

;; SDL_SetWindowMinimumSize: Set the minimum size of a window's client area
;; window: The window to set the minimum size on
;; min_w, min_h: The minimum width and height
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowMinimumSize
  (_fun _SDL_Window-pointer _int _int -> _sdl-bool)
  #:c-id SDL_SetWindowMinimumSize)

;; SDL_GetWindowMinimumSize: Get the minimum size of a window's client area
;; window: The window to query
;; Returns: (values success? width height)
(define-sdl SDL-GetWindowMinimumSize
  (_fun _SDL_Window-pointer
        (w : (_ptr o _int))
        (h : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result w h))
  #:c-id SDL_GetWindowMinimumSize)

;; SDL_SetWindowMaximumSize: Set the maximum size of a window's client area
;; window: The window to set the maximum size on
;; max_w, max_h: The maximum width and height
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowMaximumSize
  (_fun _SDL_Window-pointer _int _int -> _sdl-bool)
  #:c-id SDL_SetWindowMaximumSize)

;; SDL_GetWindowMaximumSize: Get the maximum size of a window's client area
;; window: The window to query
;; Returns: (values success? width height)
(define-sdl SDL-GetWindowMaximumSize
  (_fun _SDL_Window-pointer
        (w : (_ptr o _int))
        (h : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result w h))
  #:c-id SDL_GetWindowMaximumSize)

;; SDL_SetWindowBordered: Set the border state of a window
;; window: The window to modify
;; bordered: true to add a border, false to remove it
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowBordered (_fun _SDL_Window-pointer _stdbool -> _sdl-bool)
  #:c-id SDL_SetWindowBordered)

;; SDL_SetWindowResizable: Set the resizable state of a window
;; window: The window to modify
;; resizable: true to allow resizing, false to disallow
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowResizable (_fun _SDL_Window-pointer _stdbool -> _sdl-bool)
  #:c-id SDL_SetWindowResizable)

;; ============================================================================
;; Window Appearance
;; ============================================================================

;; SDL_SetWindowOpacity: Set the opacity of a window
;; window: The window to set the opacity on
;; opacity: The opacity value (0.0 to 1.0)
;; Returns: true on success, false on failure
(define-sdl SDL-SetWindowOpacity (_fun _SDL_Window-pointer _float -> _sdl-bool)
  #:c-id SDL_SetWindowOpacity)

;; SDL_GetWindowOpacity: Get the opacity of a window
;; window: The window to query
;; Returns: The opacity (0.0 to 1.0), or -1.0 on failure
(define-sdl SDL-GetWindowOpacity (_fun _SDL_Window-pointer -> _float)
  #:c-id SDL_GetWindowOpacity)

;; SDL_FlashWindow: Request a window to demand attention from the user
;; window: The window to flash
;; operation: The flash operation (SDL_FLASH_CANCEL, SDL_FLASH_BRIEFLY, SDL_FLASH_UNTIL_FOCUSED)
;; Returns: true on success, false on failure
(define-sdl SDL-FlashWindow (_fun _SDL_Window-pointer _SDL_FlashOperation -> _sdl-bool)
  #:c-id SDL_FlashWindow)

;; ============================================================================
;; Window Surface
;; ============================================================================

;; SDL_GetWindowSurface: Get the SDL surface associated with a window
;; window: The window to query
;; Returns: The surface associated with the window, or NULL on failure
;; Note: You cannot use a renderer and GetWindowSurface on the same window
(define-sdl SDL-GetWindowSurface (_fun _SDL_Window-pointer -> _SDL_Surface-pointer/null)
  #:c-id SDL_GetWindowSurface)

;; SDL_UpdateWindowSurface: Copy the window surface to the screen
;; window: The window to update
;; Returns: true on success, false on failure
(define-sdl SDL-UpdateWindowSurface (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_UpdateWindowSurface)
