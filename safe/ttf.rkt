#lang racket/base

;; Idiomatic SDL_ttf helpers with custodian-based cleanup

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw.rkt"
         "../ttf.rkt"
         "texture.rkt"
         "window.rkt")

(provide
 ;; Font management
 open-font
 close-font!
 font?
 font-ptr

 ;; Rendering
 render-text
 draw-text!)

;; ==========================================================================
;; Font wrapper struct
;; ==========================================================================

(struct font (ptr [destroyed? #:mutable])
  #:property prop:cpointer (λ (f) (font-ptr f)))

;; ==========================================================================
;; Initialization
;; ==========================================================================

(define ttf-initialized? #f)
(define ttf-shutdown-registered? #f)
(define ttf-shutdown-token (vector 'sdl3-ttf-shutdown))

(define (ensure-ttf-initialized! #:custodian [cust (current-custodian)])
  (unless ttf-initialized?
    (unless (TTF-Init)
      (error 'open-font "Failed to initialize SDL_ttf: ~a" (SDL-GetError)))
    (set! ttf-initialized? #t)

    ;; Tear down SDL_ttf when the custodian shuts down
    (unless ttf-shutdown-registered?
      (register-custodian-shutdown
       ttf-shutdown-token
       (λ (_)
         (when ttf-initialized?
           (TTF-Quit)
           (set! ttf-initialized? #f)))
       cust
       #:at-exit? #t)
      (set! ttf-shutdown-registered? #t))))

;; ==========================================================================
;; Font Management
;; ==========================================================================

(define (open-font path size
                   #:custodian [cust (current-custodian)])
  (ensure-ttf-initialized! #:custodian cust)

  (define ptr (TTF-OpenFont path (exact->inexact size)))
  (unless ptr
    (error 'open-font "Failed to load font ~a: ~a" path (SDL-GetError)))

  (define f (font ptr #f))

  ;; Register destructor with custodian
  (register-custodian-shutdown
   f
   (λ (ft)
     (unless (font-destroyed? ft)
       (TTF-CloseFont (font-ptr ft))
       (set-font-destroyed?! ft #t)))
   cust
   #:at-exit? #t)

  f)

(define (close-font! f)
  (unless (font-destroyed? f)
    (TTF-CloseFont (font-ptr f))
    (set-font-destroyed?! f #t)))

;; ==========================================================================
;; Color Helpers
;; ==========================================================================

(define (color-struct? v)
  (with-handlers ([exn:fail? (λ (_) #f)])
    (SDL_Color-r v) ; will raise if not an SDL_Color cstruct
    #t))

(define (color->SDL_Color color)
  (cond
    [(color-struct? color) color]
    [(and (list? color) (>= (length color) 3))
     (make-SDL_Color (list-ref color 0)
                     (list-ref color 1)
                     (list-ref color 2)
                     (if (>= (length color) 4) (list-ref color 3) 255))]
    [(and (vector? color) (>= (vector-length color) 3))
     (make-SDL_Color (vector-ref color 0)
                     (vector-ref color 1)
                     (vector-ref color 2)
                     (if (>= (vector-length color) 4) (vector-ref color 3) 255))]
    [else
     (error 'render-text
            "color must be an SDL_Color, list, or vector of 3 or 4 integers")]))

;; ==========================================================================
;; Rendering
;; ==========================================================================

(define (render-text f text color
                     #:renderer [rend #f]
                     #:mode [mode 'blended]
                     #:custodian [cust (current-custodian)])
  (unless rend
    (error 'render-text "renderer is required"))

  (when (font-destroyed? f)
    (error 'render-text "font is closed"))

  (if (string=? text "")
      #f
      (let ()
        (define sdl-color (color->SDL_Color color))

        ;; Render text to a surface using the selected quality mode
        (define surface
          (case mode
            [(solid) (TTF-RenderText-Solid (font-ptr f) text 0 sdl-color)]
            [(blended) (TTF-RenderText-Blended (font-ptr f) text 0 sdl-color)]
            [else (error 'render-text "unsupported mode: ~a" mode)]))

        (unless surface
          (error 'render-text "Failed to render text: ~a" (SDL-GetError)))

        ;; Convert to a texture for rendering
        (define tex-ptr (SDL-CreateTextureFromSurface (renderer-ptr rend) surface))
        (SDL-DestroySurface surface)

        (unless tex-ptr
          (error 'render-text "Failed to create texture from text: ~a" (SDL-GetError)))

        (texture-from-pointer tex-ptr #:custodian cust))))

(define (draw-text! rend f text x y color
                    #:mode [mode 'blended]
                    #:custodian [cust (current-custodian)])
  (define tex (render-text f text color
                           #:renderer rend
                           #:mode mode
                           #:custodian cust))

  ;; Skip empty text
  (when tex
    (render-texture! rend tex x y)
    (texture-destroy! tex)))
