#lang racket/base

;; SDL3 Vulkan Information Example
;;
;; Demonstrates querying Vulkan extensions and loading the library.
;; This does not create a full Vulkan instance as that would require 
;; a Vulkan binding library, but it shows SDL's support for Vulkan setup.

(require racket/match
         sdl3)

(define (main)
  (sdl-init!)

  (printf "SDL3 Vulkan Info~n")
  (printf "================~n")

  ;; Load Vulkan library
  (printf "Loading Vulkan library...~n")
  (with-handlers ([exn:fail? (lambda (e) (printf "Vulkan library not found or failed to load: ~a~n" (exn-message e)))])
    (if (SDL-Vulkan-LoadLibrary #f)
        (begin
          (printf "Vulkan library loaded successfully.~n")
          
          ;; Get required extensions
          (printf "Required Instance Extensions:~n")
          (let ([exts (vulkan-instance-extensions)])
            (for ([ext exts])
              (printf "  - ~a~n" ext)))
          
          ;; Unload
          (SDL-Vulkan-UnloadLibrary)
          (printf "Vulkan library unloaded.~n"))
        (printf "Failed to load Vulkan library: ~a~n" (error-message))))

  (sdl-quit!))

(module+ main
  (main))
