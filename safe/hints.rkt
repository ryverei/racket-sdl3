#lang racket/base

;; Idiomatic wrappers for SDL hints API
;;
;; Hints are configuration variables that affect SDL's behavior.
;; They can be set before or during SDL initialization.

(require "../raw/hints.rkt"
         "../private/constants.rkt")

(provide
 ;; Core hint operations
 set-hint!              ; name value [priority] -> bool
 get-hint               ; name -> string or #f
 get-hint-boolean       ; name default -> bool
 reset-hint!            ; name -> bool
 reset-all-hints!       ; -> void

 ;; Convenience wrappers for common hints
 set-app-name!          ; name -> bool
 set-app-id!            ; id -> bool
 set-render-driver!     ; driver -> bool
 allow-screensaver!     ; enabled? -> bool

 ;; Re-export hint priority constants
 (rename-out [SDL_HINT_DEFAULT hint-priority-default]
             [SDL_HINT_NORMAL hint-priority-normal]
             [SDL_HINT_OVERRIDE hint-priority-override])

 ;; Re-export common hint name constants
 (rename-out [SDL_HINT_APP_NAME hint-name-app-name]
             [SDL_HINT_APP_ID hint-name-app-id]
             [SDL_HINT_RENDER_DRIVER hint-name-render-driver]
             [SDL_HINT_RENDER_VSYNC hint-name-render-vsync]
             [SDL_HINT_VIDEO_ALLOW_SCREENSAVER hint-name-video-allow-screensaver]
             [SDL_HINT_FRAMEBUFFER_ACCELERATION hint-name-framebuffer-acceleration]
             [SDL_HINT_MOUSE_RELATIVE_MODE_WARP hint-name-mouse-relative-mode-warp]))

;; ============================================================================
;; Core Hint Operations
;; ============================================================================

;; Set a hint value
;; priority can be 'default, 'normal, 'override or the integer constants
(define (set-hint! name value [priority 'normal])
  (define pri (cond
                [(eq? priority 'default) SDL_HINT_DEFAULT]
                [(eq? priority 'normal) SDL_HINT_NORMAL]
                [(eq? priority 'override) SDL_HINT_OVERRIDE]
                [(integer? priority) priority]
                [else (error 'set-hint!
                             "priority must be 'default, 'normal, 'override, or an integer; got ~e"
                             priority)]))
  (SDL-SetHintWithPriority name value pri))

;; Get a hint value, returns #f if not set
(define (get-hint name)
  (SDL-GetHint name))

;; Get a hint as a boolean, with default value
(define (get-hint-boolean name default)
  (SDL-GetHintBoolean name default))

;; Reset a hint to its default value
(define (reset-hint! name)
  (SDL-ResetHint name))

;; Reset all hints to their default values
(define (reset-all-hints!)
  (SDL-ResetHints))

;; ============================================================================
;; Convenience Wrappers for Common Hints
;; ============================================================================

;; Set the application name (shown in audio controls, taskbar, etc.)
;; Should be called before SDL_Init
(define (set-app-name! name)
  (set-hint! SDL_HINT_APP_NAME name))

;; Set the application ID (used by desktop compositors)
;; Should be called before SDL_Init
(define (set-app-id! id)
  (set-hint! SDL_HINT_APP_ID id))

;; Set the render driver to use ("opengl", "metal", "vulkan", "software", etc.)
;; Should be called before creating a renderer
(define (set-render-driver! driver)
  (set-hint! SDL_HINT_RENDER_DRIVER driver))

;; Allow or prevent the screensaver from activating
(define (allow-screensaver! enabled?)
  (set-hint! SDL_HINT_VIDEO_ALLOW_SCREENSAVER (if enabled? "1" "0")))
