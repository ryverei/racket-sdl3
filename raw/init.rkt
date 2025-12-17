#lang racket/base

;; SDL3 Initialization and Error Handling
;;
;; Core functions for initializing SDL subsystems and retrieving errors.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-Init
         SDL-Quit
         SDL-GetError
         SDL-free)

;; ============================================================================
;; Initialization
;; ============================================================================

;; SDL_Init: Initialize the SDL library
;; flags: SDL_InitFlags bitmask specifying subsystems to initialize
;; Returns: true on success, false on failure
(define-sdl SDL-Init (_fun _SDL_InitFlags -> _sdl-bool)
  #:c-id SDL_Init)

;; SDL_Quit: Clean up all initialized subsystems
(define-sdl SDL-Quit (_fun -> _void)
  #:c-id SDL_Quit)

;; ============================================================================
;; Error Handling
;; ============================================================================

;; SDL_GetError: Get the last error message
;; Returns: A string describing the last error
(define-sdl SDL-GetError (_fun -> _string)
  #:c-id SDL_GetError)

;; Register SDL_GetError with the types module for check-sdl-bool
(sdl-get-error-proc SDL-GetError)

;; ============================================================================
;; Memory Management
;; ============================================================================

;; SDL_free: Free memory allocated by SDL functions
;; Use this to free pointers returned by SDL_GetClipboardText, etc.
(define-sdl SDL-free
  (_fun _pointer -> _void)
  #:c-id SDL_free)
