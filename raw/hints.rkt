#lang racket/base

;; SDL3 Hints API
;;
;; Functions for configuring SDL behavior at runtime through hints.
;; Hints are configuration variables that affect SDL's behavior.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt"
         "../private/constants.rkt")

(provide SDL-SetHint
         SDL-SetHintWithPriority
         SDL-GetHint
         SDL-GetHintBoolean
         SDL-ResetHint
         SDL-ResetHints)

;; ============================================================================
;; Hint Management
;; ============================================================================

;; SDL_SetHint: Set a hint with normal priority
;; name: The hint name (e.g., "SDL_RENDER_DRIVER")
;; value: The value to set (e.g., "opengl")
;; Returns: true if the hint was set, false otherwise
(define-sdl SDL-SetHint (_fun _string _string -> _bool)
  #:c-id SDL_SetHint)

;; SDL_SetHintWithPriority: Set a hint with a specific priority
;; name: The hint name
;; value: The value to set
;; priority: SDL_HINT_DEFAULT, SDL_HINT_NORMAL, or SDL_HINT_OVERRIDE
;; Returns: true if the hint was set, false otherwise
(define-sdl SDL-SetHintWithPriority (_fun _string _string _int -> _bool)
  #:c-id SDL_SetHintWithPriority)

;; SDL_GetHint: Get the value of a hint
;; name: The hint name
;; Returns: The string value of the hint, or NULL if not set
(define-sdl SDL-GetHint (_fun _string -> _string/utf-8)
  #:c-id SDL_GetHint)

;; SDL_GetHintBoolean: Get the boolean value of a hint
;; name: The hint name
;; default-value: The value to return if the hint is not set
;; Returns: The boolean value of the hint, or default-value if not set
(define-sdl SDL-GetHintBoolean (_fun _string _bool -> _bool)
  #:c-id SDL_GetHintBoolean)

;; SDL_ResetHint: Reset a hint to its default value
;; name: The hint name
;; Returns: true if the hint was reset, false otherwise
(define-sdl SDL-ResetHint (_fun _string -> _bool)
  #:c-id SDL_ResetHint)

;; SDL_ResetHints: Reset all hints to their default values
(define-sdl SDL-ResetHints (_fun -> _void)
  #:c-id SDL_ResetHints)
