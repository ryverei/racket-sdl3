#lang racket/base

;; Idiomatic display/monitor management helpers

(require ffi/unsafe
         "../raw.rkt"
         "window.rkt")

(provide
 ;; Display enumeration
 get-displays
 primary-display
 display-name

 ;; Display bounds
 display-bounds
 display-usable-bounds

 ;; Display modes
 current-display-mode
 desktop-display-mode
 fullscreen-display-modes

 ;; Window-display relationship
 window-display
 display-content-scale
 window-display-scale

 ;; Display mode struct accessors (re-exported from types)
 SDL_DisplayMode-displayID
 SDL_DisplayMode-format
 SDL_DisplayMode-w
 SDL_DisplayMode-h
 SDL_DisplayMode-pixel_density
 SDL_DisplayMode-refresh_rate
 SDL_DisplayMode-refresh_rate_numerator
 SDL_DisplayMode-refresh_rate_denominator

 ;; Display mode helpers
 display-mode-resolution
 display-mode-refresh-rate)

;; =========================================================================
;; Display Enumeration
;; =========================================================================

;; Get a list of all connected displays
;; Returns: (listof display-id)
(define (get-displays)
  (define-values (ptr count) (SDL-GetDisplays))
  (unless ptr
    (error 'get-displays "Failed to get displays: ~a" (SDL-GetError)))
  (begin0
    (for/list ([i (in-range count)])
      (ptr-ref ptr _uint32 i))
    (SDL-free ptr)))

;; Get the primary display
;; Returns: display-id
(define (primary-display)
  (define id (SDL-GetPrimaryDisplay))
  (when (zero? id)
    (error 'primary-display "Failed to get primary display: ~a" (SDL-GetError)))
  id)

;; Get the name of a display
;; Returns: string
(define (display-name display-id)
  (define name (SDL-GetDisplayName display-id))
  (unless name
    (error 'display-name "Failed to get display name: ~a" (SDL-GetError)))
  name)

;; =========================================================================
;; Display Bounds
;; =========================================================================

;; Get the desktop area represented by a display
;; Returns: (values x y w h)
(define (display-bounds display-id)
  (define rect (make-SDL_Rect 0 0 0 0))
  (unless (SDL-GetDisplayBounds display-id rect)
    (error 'display-bounds "Failed to get display bounds: ~a" (SDL-GetError)))
  (values (SDL_Rect-x rect)
          (SDL_Rect-y rect)
          (SDL_Rect-w rect)
          (SDL_Rect-h rect)))

;; Get the usable desktop area (excludes taskbar, dock, etc.)
;; Returns: (values x y w h)
(define (display-usable-bounds display-id)
  (define rect (make-SDL_Rect 0 0 0 0))
  (unless (SDL-GetDisplayUsableBounds display-id rect)
    (error 'display-usable-bounds "Failed to get usable bounds: ~a" (SDL-GetError)))
  (values (SDL_Rect-x rect)
          (SDL_Rect-y rect)
          (SDL_Rect-w rect)
          (SDL_Rect-h rect)))

;; =========================================================================
;; Display Modes
;; =========================================================================

;; Get the current display mode
;; Returns: SDL_DisplayMode pointer (owned by SDL, don't free)
(define (current-display-mode display-id)
  (define mode (SDL-GetCurrentDisplayMode display-id))
  (unless mode
    (error 'current-display-mode "Failed to get current display mode: ~a"
           (SDL-GetError)))
  mode)

;; Get the desktop display mode (mode at SDL initialization)
;; Returns: SDL_DisplayMode pointer (owned by SDL, don't free)
(define (desktop-display-mode display-id)
  (define mode (SDL-GetDesktopDisplayMode display-id))
  (unless mode
    (error 'desktop-display-mode "Failed to get desktop display mode: ~a"
           (SDL-GetError)))
  mode)

;; Get all available fullscreen display modes for a display
;; Returns: (listof SDL_DisplayMode-pointer)
(define (fullscreen-display-modes display-id)
  (define-values (ptr count) (SDL-GetFullscreenDisplayModes display-id))
  (unless ptr
    (error 'fullscreen-display-modes "Failed to get fullscreen modes: ~a"
           (SDL-GetError)))
  (begin0
    ;; The returned array contains pointers to SDL_DisplayMode structs
    (for/list ([i (in-range count)])
      (ptr-ref ptr _pointer i))
    (SDL-free ptr)))

;; =========================================================================
;; Window-Display Relationship
;; =========================================================================

;; Get the display that contains the center of a window
;; Returns: display-id
(define (window-display win)
  (define id (SDL-GetDisplayForWindow (window-ptr win)))
  (when (zero? id)
    (error 'window-display "Failed to get display for window: ~a" (SDL-GetError)))
  id)

;; Get the content scale of a display (for HiDPI)
;; Returns: float (e.g., 2.0 for Retina displays)
(define (display-content-scale display-id)
  (define scale (SDL-GetDisplayContentScale display-id))
  (when (zero? scale)
    (error 'display-content-scale "Failed to get content scale: ~a" (SDL-GetError)))
  scale)

;; Get the display scale of a window
;; Returns: float
(define (window-display-scale win)
  (define scale (SDL-GetWindowDisplayScale (window-ptr win)))
  (when (zero? scale)
    (error 'window-display-scale "Failed to get window display scale: ~a"
           (SDL-GetError)))
  scale)

;; =========================================================================
;; Display Mode Helpers
;; =========================================================================

;; Get the resolution of a display mode as (values w h)
(define (display-mode-resolution mode)
  (values (SDL_DisplayMode-w mode)
          (SDL_DisplayMode-h mode)))

;; Get the refresh rate of a display mode
;; Returns the floating-point refresh rate
(define (display-mode-refresh-rate mode)
  (SDL_DisplayMode-refresh_rate mode))
