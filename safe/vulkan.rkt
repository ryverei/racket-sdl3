#lang racket/base

;; Idiomatic Vulkan wrappers

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw.rkt"
         "../raw/vulkan.rkt"
         "../private/safe-syntax.rkt"
         "window.rkt")

(provide (all-from-out "../raw/vulkan.rkt")
         vulkan-instance-extensions
         create-vulkan-surface
         vulkan-surface?
         vulkan-surface-ptr
         vulkan-surface-destroy!
         SDL_WINDOW_VULKAN)

;; SDL_WINDOW_VULKAN is #x10000000 in SDL3 (actually 64-bit but fits here)
(define SDL_WINDOW_VULKAN #x10000000)

;; =========================================================================
;; Vulkan Surface Resource
;; =========================================================================

;; Note: Vulkan surface destruction requires the instance.
;; Our simple define-sdl-resource only takes one pointer for destructor.
;; So we define it manually to handle the instance.

(struct vulkan-surface (ptr instance [destroyed? #:mutable])
  #:property prop:cpointer (λ (obj) (vulkan-surface-ptr obj)))

(define (vulkan-surface-destroy! surf)
  (unless (vulkan-surface-destroyed? surf)
    (SDL-Vulkan-DestroySurface (vulkan-surface-instance surf)
                               (vulkan-surface-ptr surf)
                               #f)
    (set-vulkan-surface-destroyed?! surf #t)))

;; Create a Vulkan surface for a window
;; window: window to attach to
;; instance: VkInstance handle
;; custodian: custodian to manage the surface
;; Returns: vulkan-surface object
(define (create-vulkan-surface window instance #:custodian [cust (current-custodian)])
  (unless (window? window)
    (raise-argument-error 'create-vulkan-surface "window?" window))
  
  (define-values (ok surf-ptr) (SDL-Vulkan-CreateSurface (window-ptr window) instance #f))
  (unless ok
    (error 'create-vulkan-surface "Failed to create Vulkan surface: ~a" (SDL-GetError)))
  
  (define obj (vulkan-surface surf-ptr instance #f))
  (register-custodian-shutdown obj vulkan-surface-destroy! cust #:at-exit? #t)
  obj)

;; =========================================================================
;; Extensions
;; =========================================================================

;; Get list of required Vulkan instance extensions
(define (vulkan-instance-extensions)
  (define ext (SDL-Vulkan-GetInstanceExtensions))
  (unless ext
    (error 'vulkan-instance-extensions "Failed to get Vulkan extensions: ~a" (SDL-GetError)))
  ext)
