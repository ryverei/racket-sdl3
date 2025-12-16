#lang racket/base

;; Shared syntax and helpers for SDL3 FFI bindings

(require ffi/unsafe
         ffi/unsafe/define)

(provide load-sdl-library
         check-sdl-success
         check-sdl-result)

;; ============================================================================
;; Library Loading
;; ============================================================================

;; Load an SDL library with platform-specific paths
;; base-name: the library name without prefix (e.g., "SDL3", "SDL3_image", "SDL3_ttf")
;; Returns: the loaded ffi-lib
(define (load-sdl-library base-name)
  (define paths
    (case (system-type 'os)
      [(macosx)
       ;; Try Homebrew paths on macOS (both ARM and Intel)
       (list (string-append "/opt/homebrew/lib/lib" base-name)    ; ARM Homebrew
             (string-append "/usr/local/lib/lib" base-name)       ; Intel Homebrew
             (string-append "lib" base-name))]                    ; System path
      [(unix)
       (list (string-append "/usr/local/lib/lib" base-name)
             (string-append "/usr/lib/lib" base-name)
             (string-append "lib" base-name))]
      [(windows)
       (list base-name)]
      [else
       (list (string-append "lib" base-name))]))
  (let loop ([ps paths])
    (if (null? ps)
        (ffi-lib (string-append "lib" base-name) '("0" #f))  ; Last resort
        (with-handlers ([exn:fail? (λ (_) (loop (cdr ps)))])
          (ffi-lib (car ps) '("0" #f))))))

;; ============================================================================
;; Error Handling Macros
;; ============================================================================

;; Check that an SDL call succeeded (returned true/non-null)
;; Raises an error with SDL_GetError message on failure
;; Usage: (check-sdl-success 'function-name (SDL-SomeCall ...))
(define-syntax-rule (check-sdl-success name expr)
  (let ([get-error (λ () ((ffi-lib-ref (ffi-lib #f) "SDL_GetError"
                                        (_fun -> _string))))])
    (unless expr
      (error name "~a" (get-error)))))

;; Check an SDL call that returns success flag and result
;; Returns the result on success, raises error on failure
;; Usage: (check-sdl-result 'fn-name success-expr result-expr)
(define-syntax-rule (check-sdl-result name success-expr result-expr)
  (let ([get-error (λ () ((ffi-lib-ref (ffi-lib #f) "SDL_GetError"
                                        (_fun -> _string))))])
    (if success-expr
        result-expr
        (error name "~a" (get-error)))))
