#lang racket/base

;; Idiomatic texture management with custodian-based cleanup

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw.rkt"
         "../image.rkt"
         "window.rkt")

(provide
 ;; Texture management
 load-texture
 texture-from-pointer
 texture?
 texture-ptr
 texture-destroy!
 texture-size

 ;; Rendering
 render-texture!)

;; ============================================================================
;; Texture wrapper struct
;; ============================================================================

(struct texture (ptr [destroyed? #:mutable])
  #:property prop:cpointer (λ (t) (texture-ptr t)))

;; ============================================================================
;; Texture Loading
;; ============================================================================

(define (load-texture rend path
                      #:custodian [cust (current-custodian)])
  (define ptr (IMG-LoadTexture (renderer-ptr rend) path))
  (unless ptr
    (error 'load-texture "Failed to load texture ~a: ~a" path (SDL-GetError)))

  (texture-from-pointer ptr #:custodian cust))

(define (texture-from-pointer ptr
                              #:custodian [cust (current-custodian)])
  (unless ptr
    (error 'texture-from-pointer "Texture pointer is null: ~a" (SDL-GetError)))

  (define tex (texture ptr #f))

  ;; Register destructor with custodian
  (register-custodian-shutdown
   tex
   (λ (t)
     (unless (texture-destroyed? t)
       (SDL-DestroyTexture (texture-ptr t))
       (set-texture-destroyed?! t #t)))
   cust
   #:at-exit? #t)

  tex)

(define (texture-destroy! tex)
  (unless (texture-destroyed? tex)
    (SDL-DestroyTexture (texture-ptr tex))
    (set-texture-destroyed?! tex #t)))

;; ============================================================================
;; Texture Properties
;; ============================================================================

(define (texture-size tex)
  (define w-ptr (malloc _float 'atomic-interior))
  (define h-ptr (malloc _float 'atomic-interior))
  (unless (SDL-GetTextureSize (texture-ptr tex) w-ptr h-ptr)
    (error 'texture-size "Failed to get texture size: ~a" (SDL-GetError)))
  (values (ptr-ref w-ptr _float) (ptr-ref h-ptr _float)))

;; ============================================================================
;; Texture Rendering
;; ============================================================================

;; Render a texture at position (x, y)
;; Optional #:width and #:height to scale the texture
;; Optional #:src-x, #:src-y, #:src-w, #:src-h to specify source rectangle
(define (render-texture! rend tex x y
                         #:width [w #f]
                         #:height [h #f]
                         #:src-x [src-x #f]
                         #:src-y [src-y #f]
                         #:src-w [src-w #f]
                         #:src-h [src-h #f])
  ;; Get texture size if width/height not specified
  (define-values (tex-w tex-h)
    (if (or (not w) (not h))
        (texture-size tex)
        (values w h)))

  (define actual-w (or w tex-w))
  (define actual-h (or h tex-h))

  ;; Create destination rect
  (define dst-rect (make-SDL_FRect (exact->inexact x)
                                   (exact->inexact y)
                                   (exact->inexact actual-w)
                                   (exact->inexact actual-h)))

  ;; Create source rect if specified
  (define src-rect
    (if (and src-x src-y src-w src-h)
        (make-SDL_FRect (exact->inexact src-x)
                        (exact->inexact src-y)
                        (exact->inexact src-w)
                        (exact->inexact src-h))
        #f))

  (SDL-RenderTexture (renderer-ptr rend) (texture-ptr tex) src-rect dst-rect))
