#lang racket/base

;; Hello Mouse - idiomatic SDL3 example
;; - Circle follows cursor, color reflects pressed buttons
;; - Trail of previous positions

(require racket/match
         racket/math
         racket/list
         sdl3)

(define window-width 800)
(define window-height 600)
(define window-title "SDL3 Racket - Hello Mouse")

(define pi 3.141592653589793)

;; Draw a filled circle with horizontal line slices
(define (draw-circle renderer cx cy radius)
  (for* ([dy (in-range (- radius) (add1 radius))])
    (define dx-max (sqrt (max 0 (- (* radius radius) (* dy dy)))))
    (when (> dx-max 0)
      (draw-line! renderer (- cx dx-max) (+ cy dy)
                  (+ cx dx-max) (+ cy dy)))))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer window-title window-width window-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  (let loop ([trail '()] [max-trail 50] [running? #t])
    (when running?
      ;; Process events
      (define still-running?
        (for/fold ([run? #t])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            [(or (quit-event) (window-event 'close-requested)) #f]
            [(key-event 'down key _ _ _) (if (= key SDLK_ESCAPE) #f run?)]
            [_ run?])))

      (when still-running?
        ;; Mouse state
        (define-values (mx my buttons) (get-mouse-state))

        (define left? (mouse-button-pressed? buttons SDL_BUTTON_LMASK))
        (define middle? (mouse-button-pressed? buttons SDL_BUTTON_MMASK))
        (define right? (mouse-button-pressed? buttons SDL_BUTTON_RMASK))

        ;; Trail update
        (define new-trail (cons (cons mx my) trail))
        (define trimmed-trail (if (> (length new-trail) max-trail)
                                  (take new-trail max-trail)
                                  new-trail))

        ;; Background
        (set-draw-color! renderer 20 20 30)
        (render-clear! renderer)

        ;; Draw trail (fading circles)
        (for ([pos (in-list (reverse trimmed-trail))]
              [i (in-naturals)])
          (define alpha (/ i (max 1 max-trail)))
          (define trail-radius (+ 5 (* 15 alpha)))
          (set-draw-color! renderer 100 100 (inexact->exact (round (+ 100 (* 55 alpha)))))
          (draw-circle renderer (car pos) (cdr pos) trail-radius))

        ;; Cursor color from button state
        (define-values (r g b)
          (cond
            [(and left? right?) (values 255 255 0)]
            [left? (values 255 100 100)]
            [right? (values 100 100 255)]
            [middle? (values 100 255 100)]
            [else (values 255 255 255)]))

        ;; Cursor circles
        (set-draw-color! renderer r g b)
        (draw-circle renderer mx my 25.0)
        (set-draw-color! renderer (quotient r 2) (quotient g 2) (quotient b 2))
        (draw-circle renderer mx my 15.0)

        ;; Crosshair
        (set-draw-color! renderer r g b)
        (draw-line! renderer (- mx 30) my (- mx 10) my)
        (draw-line! renderer (+ mx 10) my (+ mx 30) my)
        (draw-line! renderer mx (- my 30) mx (- my 10))
        (draw-line! renderer mx (+ my 10) mx (+ my 30))

        ;; Button indicators
        (define indicator-y 560.0)
        (define indicator-size 30.0)

        (set-draw-color! renderer (if left? 255 80) (if left? 100 40) (if left? 100 40))
        (fill-rect! renderer 50.0 indicator-y indicator-size indicator-size)

        (set-draw-color! renderer (if middle? 100 40) (if middle? 255 80) (if middle? 100 40))
        (fill-rect! renderer 90.0 indicator-y indicator-size indicator-size)

        (set-draw-color! renderer (if right? 100 40) (if right? 100 40) (if right? 255 80))
        (fill-rect! renderer 130.0 indicator-y indicator-size indicator-size)

        (render-present! renderer)
        (delay! 16)

        (loop trimmed-trail max-trail still-running?))))

  ;; Clean up (important for REPL usage)
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run the example when executed directly
(module+ main
  (main))
