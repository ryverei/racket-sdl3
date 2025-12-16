#lang racket/base

;; Idiomatic window and renderer management with custodian-based cleanup

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw.rkt"
         "syntax.rkt")

(provide
 ;; Initialization
 sdl-init!
 sdl-quit!

 ;; Window management
 make-window
 window?
 window-ptr
 window-destroy!
 window-set-title!
 window-pixel-density
 window-size
 window-set-size!
 window-position
 window-set-position!
 window-fullscreen?
 window-set-fullscreen!

 ;; Renderer management
 make-renderer
 renderer?
 renderer-ptr
 renderer-destroy!

 ;; Convenience
 make-window+renderer

 ;; Re-export common flags
 (all-from-out "../raw.rkt"))

;; ============================================================================
;; Resource wrapper structs
;; ============================================================================

(define-sdl-resource window SDL-DestroyWindow)
(define-sdl-resource renderer SDL-DestroyRenderer)

;; ============================================================================
;; Initialization
;; ============================================================================

(define (sdl-init! [flags SDL_INIT_VIDEO])
  (unless (SDL-Init flags)
    (error 'sdl-init! "Failed to initialize SDL: ~a" (SDL-GetError))))

(define (sdl-quit!)
  (SDL-Quit))

;; ============================================================================
;; Window Management
;; ============================================================================

(define (make-window title width height
                     #:flags [flags 0]
                     #:custodian [cust (current-custodian)])
  (define ptr (SDL-CreateWindow title width height flags))
  (unless ptr
    (error 'make-window "Failed to create window: ~a" (SDL-GetError)))
  (wrap-window ptr #:custodian cust))

(define (window-set-title! win title)
  (SDL-SetWindowTitle (window-ptr win) title))

(define (window-pixel-density win)
  (SDL-GetWindowPixelDensity (window-ptr win)))

;; Get the size of a window's client area
;; Returns: (values width height)
(define (window-size win)
  (define-values (success w h) (SDL-GetWindowSize (window-ptr win)))
  (unless success
    (error 'window-size "Failed to get window size: ~a" (SDL-GetError)))
  (values w h))

;; Set the size of a window's client area
(define (window-set-size! win w h)
  (unless (SDL-SetWindowSize (window-ptr win) w h)
    (error 'window-set-size! "Failed to set window size: ~a" (SDL-GetError))))

;; Get the position of a window
;; Returns: (values x y)
(define (window-position win)
  (define-values (success x y) (SDL-GetWindowPosition (window-ptr win)))
  (unless success
    (error 'window-position "Failed to get window position: ~a" (SDL-GetError)))
  (values x y))

;; Set the position of a window
(define (window-set-position! win x y)
  (unless (SDL-SetWindowPosition (window-ptr win) x y)
    (error 'window-set-position! "Failed to set window position: ~a" (SDL-GetError))))

;; Check if window is fullscreen
(define (window-fullscreen? win)
  (not (zero? (bitwise-and (SDL-GetWindowFlags (window-ptr win))
                           SDL_WINDOW_FULLSCREEN))))

;; Set window fullscreen mode
(define (window-set-fullscreen! win fullscreen?)
  (unless (SDL-SetWindowFullscreen (window-ptr win) fullscreen?)
    (error 'window-set-fullscreen! "Failed to set fullscreen: ~a" (SDL-GetError))))

;; ============================================================================
;; Renderer Management
;; ============================================================================

(define (make-renderer win
                       #:name [name #f]
                       #:custodian [cust (current-custodian)])
  (define ptr (SDL-CreateRenderer (window-ptr win) name))
  (unless ptr
    (error 'make-renderer "Failed to create renderer: ~a" (SDL-GetError)))
  (wrap-renderer ptr #:custodian cust))

;; ============================================================================
;; Convenience Functions
;; ============================================================================

(define (make-window+renderer title width height
                              #:window-flags [window-flags 0]
                              #:renderer-name [renderer-name #f]
                              #:custodian [cust (current-custodian)])
  (define win (make-window title width height
                           #:flags window-flags
                           #:custodian cust))
  (define rend (make-renderer win
                              #:name renderer-name
                              #:custodian cust))
  (values win rend))
