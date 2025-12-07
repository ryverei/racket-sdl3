#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define)

(provide define-sdl
         sdl-lib)

;; Platform-specific library paths
;; SDL3 may be installed in non-standard locations (e.g., Homebrew on macOS)
(define sdl3-lib-paths
  (case (system-type 'os)
    [(macosx)
     ;; Try Homebrew paths on macOS (both ARM and Intel)
     '("/opt/homebrew/lib/libSDL3"    ; ARM Homebrew
       "/usr/local/lib/libSDL3"       ; Intel Homebrew
       "libSDL3")]                    ; System path
    [(unix)
     '("/usr/local/lib/libSDL3"
       "/usr/lib/libSDL3"
       "libSDL3")]
    [(windows)
     '("SDL3")]
    [else '("libSDL3")]))

;; Try to load SDL3 from the first available path
(define sdl-lib
  (let loop ([paths sdl3-lib-paths])
    (if (null? paths)
        (ffi-lib "libSDL3" '("0" #f))  ; Last resort, let it error with default message
        (with-handlers ([exn:fail? (λ (e) (loop (cdr paths)))])
          (ffi-lib (car paths) '("0" #f))))))

;; Define the FFI definer for SDL3 functions
;; - Uses hyphen-to-underscore conversion (e.g., SDL-Init -> SDL_Init)
;; - Provides graceful failure for unavailable functions
(define-ffi-definer define-sdl sdl-lib
  #:make-c-id convention:hyphen->underscore
  #:default-make-fail make-not-available)
