#lang racket/base

(require ffi/unsafe)

(provide check-sdl-bool
         _sdl-bool
         ;; Init flags
         _SDL_InitFlags
         SDL_INIT_VIDEO
         ;; Window flags
         _SDL_WindowFlags
         SDL_WINDOW_RESIZABLE
         ;; Pointer types
         _SDL_Window-pointer
         _SDL_Window-pointer/null
         _SDL_Renderer-pointer
         _SDL_Renderer-pointer/null
         ;; Event constants
         SDL_EVENT_QUIT
         ;; Error handling forward reference
         sdl-get-error-proc)

;; SDL3 types, enums, and structs
;; This file will be expanded with SDL3 type definitions as bindings are added.

;; SDL3 boolean type - SDL3 uses C99 bool (not int like SDL2)
(define _sdl-bool _bool)

;; ============================================================================
;; Init Flags (SDL_InitFlags) - used with SDL_Init
;; ============================================================================
(define SDL_INIT_VIDEO #x00000020)

;; SDL_InitFlags is a 32-bit unsigned integer (flags can be combined with bitwise-ior)
(define _SDL_InitFlags _uint32)

;; ============================================================================
;; Window Flags (SDL_WindowFlags) - 64-bit in SDL3
;; ============================================================================
(define SDL_WINDOW_RESIZABLE #x0000000000000020)

;; SDL_WindowFlags is a 64-bit unsigned integer in SDL3 (flags can be combined with bitwise-ior)
(define _SDL_WindowFlags _uint64)

;; ============================================================================
;; Pointer Types
;; ============================================================================
(define-cpointer-type _SDL_Window-pointer)
(define-cpointer-type _SDL_Renderer-pointer)

;; ============================================================================
;; Event Constants
;; ============================================================================
(define SDL_EVENT_QUIT #x100)

;; ============================================================================
;; Error Handling
;; ============================================================================

;; Placeholder for SDL_GetError - will be replaced with actual FFI binding
;; This is defined here to avoid circular dependencies
(define sdl-get-error-proc (make-parameter #f))

;; Check an SDL3 boolean result and raise an error if false
;; SDL3 functions return true on success, false on failure
(define (check-sdl-bool who result)
  (unless result
    (define get-error (sdl-get-error-proc))
    (define msg (if get-error
                    (get-error)
                    "SDL error (SDL_GetError not yet available)"))
    (error who "SDL error: ~a" msg))
  #t)
