#lang racket/base

;; Hello Shapes - idiomatic SDL3 example for drawing primitives

(require racket/match
         sdl3/safe)

(define window-width 800)
(define window-height 600)
(define window-title "SDL3 Racket - Hello Shapes")

;; Shape data (lists of numbers)
(define filled-rects '((50.0 50.0 100.0 80.0)
                       (170.0 50.0 100.0 80.0)
                       (290.0 50.0 100.0 80.0)))

(define outline-rects '((450.0 50.0 100.0 80.0)
                        (570.0 50.0 100.0 80.0)
                        (690.0 50.0 100.0 80.0)))

;; Triangle points (closed polyline)
(define triangle '((400.0 180.0)
                   (300.0 320.0)
                   (500.0 320.0)
                   (400.0 180.0)))

;; Star shape using connected lines
(define star '((200.0 400.0)
               (240.0 500.0)
               (150.0 440.0)
               (250.0 440.0)
               (160.0 500.0)
               (200.0 400.0)))

;; Grid of points (20x20)
(define grid-points
  (for*/list ([i (in-range 20)]
              [j (in-range 20)])
    (list (+ 550.0 (* i 4.0))
          (+ 350.0 (* j 4.0)))))

;; Sine wave points
(define wave-points
  (for/list ([x (in-range 0 400 4)])
    (list (+ 200.0 (exact->inexact x))
          (+ 500.0 (* 30.0 (sin (* x 0.05)))))))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer window-title window-width window-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  (let loop ([running? #t])
    (when running?
      ;; Handle events
      (define still-running?
        (for/fold ([run? #t])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            [(or (quit-event) (window-event 'close-requested)) #f]
            [(key-event 'down key _ _ _)
             (if (= key SDLK_ESCAPE) #f run?)]
            [_ run?])))

      (when still-running?
        ;; Background
        (set-draw-color! renderer 40 40 40)
        (render-clear! renderer)

        ;; Filled rectangles (red)
        (set-draw-color! renderer 220 60 60)
        (fill-rects! renderer filled-rects)

        ;; Outline rectangles (green)
        (set-draw-color! renderer 60 220 60)
        (draw-rects! renderer outline-rects)

        ;; Triangle (cyan)
        (set-draw-color! renderer 60 220 220)
        (draw-lines! renderer triangle)

        ;; Star (yellow)
        (set-draw-color! renderer 220 220 60)
        (draw-lines! renderer star)

        ;; Grid of points (white)
        (set-draw-color! renderer 255 255 255)
        (draw-points! renderer grid-points)

        ;; Sine wave (magenta)
        (set-draw-color! renderer 220 60 220)
        (draw-points! renderer wave-points)

        ;; Single filled rect (blue)
        (set-draw-color! renderer 60 60 220)
        (fill-rect! renderer 50.0 350.0 80.0 60.0)

        ;; Single line (orange)
        (set-draw-color! renderer 220 140 60)
        (draw-line! renderer 50.0 450.0 130.0 550.0)

        (render-present! renderer)
        (delay! 16)

        (loop still-running?))))

  ;; Clean up (important for REPL usage)
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run the example when executed directly
(module+ main
  (main))
