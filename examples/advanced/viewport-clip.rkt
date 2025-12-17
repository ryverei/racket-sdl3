#lang racket/base

;; Viewport and Clipping Demo
;;
;; Demonstrates viewport, clipping, and render scale features:
;; - Split-screen effect using viewports
;; - Clipping rectangles to constrain drawing
;; - Render scale for resolution independence
;;
;; Controls:
;;   1 - Show split-screen viewports demo
;;   2 - Show clipping rectangle demo
;;   3 - Show render scale demo
;;   +/= - Increase scale (in scale mode)
;;   -   - Decrease scale (in scale mode)
;;   ESC - Quit

(require racket/match
         racket/format
         racket/math
         sdl3)

(define window-width 800)
(define window-height 600)
(define window-title "SDL3 Viewport & Clipping Demo")

;; Demo modes
(define MODE-VIEWPORT 1)
(define MODE-CLIPPING 2)
(define MODE-SCALE 3)

;; Draw a simple scene with shapes
(define (draw-scene renderer offset-x offset-y)
  ;; Red square
  (set-draw-color! renderer 220 60 60)
  (fill-rect! renderer (+ 50 offset-x) (+ 50 offset-y) 80 80)

  ;; Green square
  (set-draw-color! renderer 60 220 60)
  (fill-rect! renderer (+ 150 offset-x) (+ 50 offset-y) 80 80)

  ;; Blue square
  (set-draw-color! renderer 60 60 220)
  (fill-rect! renderer (+ 250 offset-x) (+ 50 offset-y) 80 80)

  ;; Yellow circle approximation (octagon)
  (set-draw-color! renderer 220 220 60)
  (define cx (+ 180 offset-x))
  (define cy (+ 200 offset-y))
  (define r 60)
  (define points
    (for/list ([i (in-range 9)])
      (define angle (* i (/ (* 2 3.14159) 8)))
      (list (+ cx (* r (cos angle)))
            (+ cy (* r (sin angle))))))
  (draw-lines! renderer points)

  ;; Cyan diagonal lines
  (set-draw-color! renderer 60 220 220)
  (for ([i (in-range 0 300 20)])
    (draw-line! renderer (+ offset-x i) (+ offset-y 300)
                         (+ offset-x (+ i 100)) (+ offset-y 150))))

;; Draw viewport demo - split screen into 4 quadrants
(define (draw-viewport-demo renderer width height)
  (define half-w (quotient width 2))
  (define half-h (quotient height 2))

  ;; Clear the entire screen first
  (set-render-viewport! renderer #f)
  (set-draw-color! renderer 40 40 40)
  (render-clear! renderer)

  ;; Top-left viewport (red tint background)
  (set-render-viewport! renderer (make-SDL_Rect 0 0 half-w half-h))
  (set-draw-color! renderer 60 30 30)
  (fill-rect! renderer 0 0 half-w half-h)
  (draw-scene renderer 0 0)

  ;; Top-right viewport (green tint background)
  (set-render-viewport! renderer (make-SDL_Rect half-w 0 half-w half-h))
  (set-draw-color! renderer 30 60 30)
  (fill-rect! renderer 0 0 half-w half-h)
  (draw-scene renderer 0 0)

  ;; Bottom-left viewport (blue tint background)
  (set-render-viewport! renderer (make-SDL_Rect 0 half-h half-w half-h))
  (set-draw-color! renderer 30 30 60)
  (fill-rect! renderer 0 0 half-w half-h)
  (draw-scene renderer 0 0)

  ;; Bottom-right viewport (gray background)
  (set-render-viewport! renderer (make-SDL_Rect half-w half-h half-w half-h))
  (set-draw-color! renderer 50 50 50)
  (fill-rect! renderer 0 0 half-w half-h)
  (draw-scene renderer 0 0)

  ;; Reset viewport to full screen for UI
  (set-render-viewport! renderer #f)

  ;; Draw dividing lines
  (set-draw-color! renderer 255 255 255)
  (draw-line! renderer half-w 0 half-w height)
  (draw-line! renderer 0 half-h width half-h)

  ;; Draw title
  (set-draw-color! renderer 255 255 0)
  (render-debug-text! renderer 10 10 "VIEWPORT DEMO - Split screen into 4 viewports")
  (render-debug-text! renderer 10 25 "Each viewport renders the same scene independently"))

;; Draw clipping demo - show content being clipped
(define (draw-clipping-demo renderer width height frame)
  ;; Clear background
  (set-draw-color! renderer 40 40 40)
  (render-clear! renderer)

  ;; Draw instruction text (not clipped)
  (set-draw-color! renderer 255 255 0)
  (render-debug-text! renderer 10 10 "CLIPPING DEMO - Drawing is constrained to clip rectangle")
  (render-debug-text! renderer 10 25 "The red rectangle shows the clip area")

  ;; Calculate animated clip rectangle
  (define clip-x (+ 150 (* 100 (sin (* frame 0.02)))))
  (define clip-y (+ 150 (* 50 (cos (* frame 0.03)))))
  (define clip-w 300)
  (define clip-h 200)

  ;; Draw clip area outline (before clipping is enabled)
  (set-draw-color! renderer 200 60 60)
  (draw-rect! renderer clip-x clip-y clip-w clip-h)

  ;; Enable clipping
  (set-render-clip-rect! renderer (make-SDL_Rect (exact-floor clip-x)
                                                  (exact-floor clip-y)
                                                  clip-w clip-h))

  ;; Draw lots of content that will be clipped
  ;; Grid of circles
  (for* ([x (in-range 0 width 40)]
         [y (in-range 80 height 40)])
    (define color-shift (+ x y frame))
    (set-draw-color! renderer
                     (modulo (+ 100 (quotient color-shift 3)) 256)
                     (modulo (+ 150 (quotient color-shift 5)) 256)
                     (modulo (+ 200 (quotient color-shift 7)) 256))
    (fill-rect! renderer x y 30 30))

  ;; Draw diagonal lines across entire screen (will be clipped)
  (set-draw-color! renderer 255 255 255)
  (for ([i (in-range 0 1000 30)])
    (draw-line! renderer i 50 (- i 200) height))

  ;; Disable clipping
  (set-render-clip-rect! renderer #f)

  ;; Show clip status
  (set-draw-color! renderer 200 200 200)
  (render-debug-text! renderer 10 (- height 30)
                       (~a "Clip rect: (" (exact-floor clip-x) ", " (exact-floor clip-y)
                           ") " clip-w "x" clip-h)))

;; Draw scale demo - show render scale effect
(define (draw-scale-demo renderer width height scale)
  ;; Reset scale temporarily for background
  (set-render-scale! renderer 1.0 1.0)
  (set-draw-color! renderer 40 40 40)
  (render-clear! renderer)

  ;; Draw instructions (at normal scale)
  (set-draw-color! renderer 255 255 0)
  (render-debug-text! renderer 10 10 "SCALE DEMO - Render scale affects all coordinates")
  (render-debug-text! renderer 10 25 "+/- to change scale, coordinates stay the same")
  (render-debug-text! renderer 10 40 (~a "Current scale: " (~r scale #:precision 2) "x"))

  ;; Apply scale
  (set-render-scale! renderer scale scale)

  ;; Draw a grid pattern (coordinates don't change, but visual size does)
  (set-draw-color! renderer 80 80 80)
  (for ([x (in-range 0 400 50)])
    (draw-line! renderer x 80 x 350))
  (for ([y (in-range 80 350 50)])
    (draw-line! renderer 0 y 400 y))

  ;; Draw shapes at fixed coordinates
  (set-draw-color! renderer 220 60 60)
  (fill-rect! renderer 50 100 50 50)

  (set-draw-color! renderer 60 220 60)
  (fill-rect! renderer 150 100 50 50)

  (set-draw-color! renderer 60 60 220)
  (fill-rect! renderer 250 100 50 50)

  ;; Draw coordinate labels
  (set-draw-color! renderer 255 255 255)
  (render-debug-text! renderer 50 160 "(50,100)")
  (render-debug-text! renderer 150 160 "(150,100)")
  (render-debug-text! renderer 250 160 "(250,100)")

  ;; Draw a larger shape
  (set-draw-color! renderer 220 220 60)
  (fill-rect! renderer 100 200 100 100)
  (set-draw-color! renderer 40 40 40)
  (render-debug-text! renderer 110 240 "100x100")

  ;; Reset scale for next frame
  (set-render-scale! renderer 1.0 1.0))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer window-title window-width window-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  (let loop ([running? #t]
             [mode MODE-VIEWPORT]
             [scale 1.0]
             [frame 0])
    (when running?
      ;; Get current window size
      (define-values (win-w win-h) (window-size window))

      ;; Handle events
      (define-values (still-running? new-mode new-scale)
        (for/fold ([run? #t]
                   [m mode]
                   [s scale])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            [(or (quit-event) (window-event 'close-requested))
             (values #f m s)]

            [(key-event 'down key _ _ _)
             (cond
               [(= key SDLK_ESCAPE) (values #f m s)]
               [(= key SDLK_1) (values run? MODE-VIEWPORT s)]
               [(= key SDLK_2) (values run? MODE-CLIPPING s)]
               [(= key SDLK_3) (values run? MODE-SCALE s)]
               [(or (= key SDLK_EQUALS) (= key SDLK_PLUS))
                (values run? m (min 4.0 (+ s 0.25)))]
               [(= key SDLK_MINUS)
                (values run? m (max 0.25 (- s 0.25)))]
               [else (values run? m s)])]

            [_ (values run? m s)])))

      (when still-running?
        ;; Draw based on mode
        (case new-mode
          [(1) (draw-viewport-demo renderer win-w win-h)]
          [(2) (draw-clipping-demo renderer win-w win-h frame)]
          [(3) (draw-scale-demo renderer win-w win-h new-scale)])

        ;; Draw mode selector at bottom
        (set-render-scale! renderer 1.0 1.0)  ; ensure normal scale
        (set-render-viewport! renderer #f)     ; ensure full viewport
        (set-render-clip-rect! renderer #f)    ; ensure no clipping
        (set-draw-color! renderer 150 150 150)
        (render-debug-text! renderer 10 (- win-h 15)
                             "Press 1=Viewport, 2=Clipping, 3=Scale | ESC=Quit")

        (render-present! renderer)
        (delay! 16)

        (loop still-running? new-mode new-scale (+ frame 1)))))

  ;; Clean up
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run the example when executed directly
(module+ main
  (main))
