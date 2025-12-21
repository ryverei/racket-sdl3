#lang racket/base

;; SDL3 Timer Functions
;;
;; Functions for timing and delays.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-GetTicks
         SDL-GetTicksNS
         SDL-GetPerformanceCounter
         SDL-GetPerformanceFrequency
         SDL-DelayPrecise)

;; ============================================================================
;; Timer
;; ============================================================================

;; SDL_GetTicks: Get the number of milliseconds since SDL library initialization
;; Returns: Uint64 milliseconds since SDL_Init was called
(define-sdl SDL-GetTicks (_fun -> _uint64)
  #:c-id SDL_GetTicks)

;; SDL_GetTicksNS: Get the number of nanoseconds since SDL library initialization
;; Returns: Uint64 nanoseconds since SDL_Init was called
(define-sdl SDL-GetTicksNS (_fun -> _uint64)
  #:c-id SDL_GetTicksNS)

;; SDL_GetPerformanceCounter: Get the current value of the high resolution counter
;; Use for profiling. Values are only meaningful relative to each other.
;; Convert differences to time using SDL_GetPerformanceFrequency.
;; Returns: Uint64 current counter value
(define-sdl SDL-GetPerformanceCounter (_fun -> _uint64)
  #:c-id SDL_GetPerformanceCounter)

;; SDL_GetPerformanceFrequency: Get the count per second of the high resolution counter
;; Returns: Uint64 platform-specific counts per second
(define-sdl SDL-GetPerformanceFrequency (_fun -> _uint64)
  #:c-id SDL_GetPerformanceFrequency)

;; SDL_DelayPrecise: Wait a specified number of nanoseconds with busy-waiting
;; More precise than SDL_DelayNS, but uses more CPU. Good for frame timing.
;; ns: The number of nanoseconds to delay
(define-sdl SDL-DelayPrecise (_fun #:blocking? #t _uint64 -> _void)
  #:c-id SDL_DelayPrecise)
