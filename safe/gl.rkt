#lang racket/base

;; Idiomatic OpenGL wrappers

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw.rkt"
         "../raw/gl.rkt"
         "../private/safe-syntax.rkt"
         "window.rkt")

(provide (all-from-out "../raw/gl.rkt") ; Re-export raw bindings for now
         create-gl-context
         gl-context?
         gl-make-current!
         gl-swap-window!
         gl-set-attribute!
         gl-get-attribute
         gl-set-swap-interval!
         gl-get-swap-interval
         
         ;; Re-export OpenGL attributes
         SDL_GL_RED_SIZE
         SDL_GL_GREEN_SIZE
         SDL_GL_BLUE_SIZE
         SDL_GL_ALPHA_SIZE
         SDL_GL_BUFFER_SIZE
         SDL_GL_DOUBLEBUFFER
         SDL_GL_DEPTH_SIZE
         SDL_GL_STENCIL_SIZE
         SDL_GL_ACCUM_RED_SIZE
         SDL_GL_ACCUM_GREEN_SIZE
         SDL_GL_ACCUM_BLUE_SIZE
         SDL_GL_ACCUM_ALPHA_SIZE
         SDL_GL_STEREO
         SDL_GL_MULTISAMPLEBUFFERS
         SDL_GL_MULTISAMPLESAMPLES
         SDL_GL_ACCELERATED_VISUAL
         SDL_GL_RETAINED_BACKING
         SDL_GL_CONTEXT_MAJOR_VERSION
         SDL_GL_CONTEXT_MINOR_VERSION
         SDL_GL_CONTEXT_FLAGS
         SDL_GL_CONTEXT_PROFILE_MASK
         SDL_GL_SHARE_WITH_CURRENT_CONTEXT
         SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
         SDL_GL_CONTEXT_RELEASE_BEHAVIOR
         SDL_GL_CONTEXT_RESET_NOTIFICATION
         SDL_GL_CONTEXT_NO_ERROR
         SDL_GL_FLOATBUFFERS
         SDL_GL_EGL_PLATFORM
         ;; Context profiles
         SDL_GL_CONTEXT_PROFILE_CORE
         SDL_GL_CONTEXT_PROFILE_COMPATIBILITY
         SDL_GL_CONTEXT_PROFILE_ES
         ;; Context flags
         SDL_GL_CONTEXT_DEBUG_FLAG
         SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG
         SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG
         SDL_GL_CONTEXT_RESET_ISOLATION_FLAG)

;; =========================================================================
;; OpenGL Context Resource
;; =========================================================================

(define-sdl-resource gl-context
  SDL-GL-DestroyContext)

;; Create an OpenGL context for a window
;; window: window to associate with
;; custodian: custodian to manage the context (defaults to current)
;; Returns: gl-context object
(define (create-gl-context window #:custodian [cust (current-custodian)])
  (unless (window? window)
    (raise-argument-error 'create-gl-context "window?" window))
  
  (define ctx (SDL-GL-CreateContext (window-ptr window)))
  (unless ctx
    (error 'create-gl-context "Failed to create GL context: ~a" (SDL-GetError)))
  
  (wrap-gl-context ctx #:custodian cust))

;; Make the context current for the window
(define (gl-make-current! window ctx)
  (unless (window? window)
    (raise-argument-error 'gl-make-current! "window?" window))
  (unless (gl-context? ctx)
    (raise-argument-error 'gl-make-current! "gl-context?" ctx))
  
  (unless (SDL-GL-MakeCurrent (window-ptr window) (gl-context-ptr ctx))
    (error 'gl-make-current! "Failed to make GL context current: ~a" (SDL-GetError))))

;; Swap buffers for the window
(define (gl-swap-window! window)
  (unless (window? window)
    (raise-argument-error 'gl-swap-window! "window?" window))
  
  (unless (SDL-GL-SwapWindow (window-ptr window))
    (error 'gl-swap-window! "Failed to swap window buffers: ~a" (SDL-GetError))))

;; Set an OpenGL attribute
(define (gl-set-attribute! attr value)
  (unless (SDL-GL-SetAttribute attr value)
    (error 'gl-set-attribute! "Failed to set GL attribute ~a to ~a: ~a" 
           attr value (SDL-GetError))))

;; Get an OpenGL attribute
(define (gl-get-attribute attr)
  (define-values (ok val) (SDL-GL-GetAttribute attr))
  (unless ok
    (error 'gl-get-attribute "Failed to get GL attribute ~a: ~a" 
           attr (SDL-GetError)))
  val)

;; Set swap interval (vsync)
;; 0 = immediate, 1 = vsync, -1 = adaptive vsync
(define (gl-set-swap-interval! interval)
  (unless (SDL-GL-SetSwapInterval interval)
    (error 'gl-set-swap-interval! "Failed to set swap interval: ~a" (SDL-GetError))))

;; Get swap interval
(define (gl-get-swap-interval)
  (define-values (ok val) (SDL-GL-GetSwapInterval))
  (unless ok
    (error 'gl-get-swap-interval "Failed to get swap interval: ~a" (SDL-GetError)))
  val)
