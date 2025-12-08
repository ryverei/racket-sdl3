#lang racket/base

;; Texture Color & Alpha Modulation Demo
;;
;; Demonstrates tinting textures with color modulation and fading with alpha modulation.
;;
;; Controls:
;;   R - Apply red tint
;;   G - Apply green tint
;;   B - Apply blue tint
;;   Up/Down - Adjust alpha (fade in/out)
;;   Space - Reset to normal (white, full opacity)
;;   ESC - Quit

(require racket/match
         racket/format
         sdl3/safe)

(define window-width 800)
(define window-height 600)
(define window-title "SDL3 Texture Tint Demo")

(define font-path "/System/Library/Fonts/Supplemental/Arial.ttf")
(define base-font-size 18.0)
(define image-path "examples/assets/test.png")

;; Alpha step for up/down keys
(define alpha-step 15)

(define (clamp v lo hi)
  (max lo (min hi v)))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer window-title window-width window-height
                          #:window-flags SDL_WINDOW_HIGH_PIXEL_DENSITY))

  ;; Scale font for high-DPI
  (define pixel-density (window-pixel-density window))
  (define font-size (* base-font-size pixel-density))
  (define font (open-font font-path font-size))

  ;; Load texture
  (define tex (load-texture renderer image-path))
  (define-values (tex-w tex-h) (texture-size tex))

  ;; Center texture position
  (define tex-x (/ (- window-width tex-w) 2.0))
  (define tex-y (/ (- window-height tex-h) 2.0))

  ;; Enable blending for alpha modulation to work
  (set-blend-mode! renderer 'blend)

  (let loop ([r 255] [g 255] [b 255] [alpha 255] [running? #t])
    (when running?
      ;; Handle events
      (define-values (new-r new-g new-b new-alpha still-running?)
        (for/fold ([cr r] [cg g] [cb b] [ca alpha] [run? #t])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            [(or (quit-event) (window-event 'close-requested))
             (values cr cg cb ca #f)]

            [(key-event 'down key _ _ _)
             (cond
               [(= key SDLK_ESCAPE)
                (values cr cg cb ca #f)]
               ;; R key - red tint
               [(or (= key SDLK_r) (= key SDLK_R))
                (values 255 100 100 ca run?)]
               ;; G key - green tint
               [(or (= key SDLK_g) (= key SDLK_G))
                (values 100 255 100 ca run?)]
               ;; B key - blue tint
               [(or (= key SDLK_b) (= key SDLK_B))
                (values 100 100 255 ca run?)]
               ;; Space - reset
               [(= key SDLK_SPACE)
                (values 255 255 255 255 run?)]
               ;; Up - increase alpha
               [(= key SDLK_UP)
                (values cr cg cb (clamp (+ ca alpha-step) 0 255) run?)]
               ;; Down - decrease alpha
               [(= key SDLK_DOWN)
                (values cr cg cb (clamp (- ca alpha-step) 0 255) run?)]
               [else
                (values cr cg cb ca run?)])]

            [_ (values cr cg cb ca run?)])))

      (when still-running?
        ;; Apply color and alpha modulation to texture
        (texture-set-color-mod! tex new-r new-g new-b)
        (texture-set-alpha-mod! tex new-alpha)

        ;; Clear to dark background
        (set-draw-color! renderer 40 40 40)
        (render-clear! renderer)

        ;; Draw the tinted texture
        (render-texture! renderer tex tex-x tex-y)

        ;; Draw info text
        (draw-text! renderer font "Texture Color & Alpha Modulation"
                    20 20 '(255 255 255 255))

        (draw-text! renderer font "R/G/B = Apply tint | Up/Down = Adjust alpha | Space = Reset"
                    20 50 '(180 180 180 255))

        ;; Show current values
        (define color-text (format "Color mod: R=~a G=~a B=~a" new-r new-g new-b))
        (define alpha-text (format "Alpha mod: ~a" new-alpha))

        (draw-text! renderer font color-text 20 (- window-height 70) '(255 255 0 255))
        (draw-text! renderer font alpha-text 20 (- window-height 40) '(255 255 0 255))

        ;; Draw color preview box
        (set-draw-color! renderer new-r new-g new-b new-alpha)
        (fill-rect! renderer (- window-width 70) 20 50 50)
        (set-draw-color! renderer 255 255 255 255)
        (draw-rect! renderer (- window-width 70) 20 50 50)

        (render-present! renderer)
        (delay! 16)

        (loop new-r new-g new-b new-alpha still-running?))))

  (close-font! font))

;; Run the example
(main)
