#lang racket/base

;; SDL3 Surface Operations
;;
;; Functions for managing surfaces (software-based image buffers).
;; Surface struct accessors (SDL_Surface-w, SDL_Surface-h) are in private/types.rkt.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-DestroySurface)

;; ============================================================================
;; Surface Management
;; ============================================================================

;; SDL_DestroySurface: Free a surface (replaces SDL_FreeSurface from SDL2)
;; surface: the surface to destroy
(define-sdl SDL-DestroySurface (_fun _SDL_Surface-pointer -> _void)
  #:c-id SDL_DestroySurface)
