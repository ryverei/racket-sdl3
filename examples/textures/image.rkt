#lang racket/base

;; SDL3_image example - load and display a PNG
;; Arrow keys move the image, Escape quits
;;
;; This example uses the safe interface.

(require racket/match
         sdl3)

(define window-width 800)
(define window-height 600)
(define move-speed 10.0)

(define (main)
  ;; Initialize SDL video subsystem
  (sdl-init!)

  ;; Create window and renderer
  (define-values (window renderer)
    (make-window+renderer "SDL3 Image - Arrow keys to move"
                          window-width window-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  ;; Load texture
  (define image-path "examples/assets/test.png")
  (define tex (load-texture renderer image-path))

  ;; Get texture dimensions and center it
  (define-values (tex-w tex-h) (texture-size tex))
  (define start-x (/ (- window-width tex-w) 2.0))
  (define start-y (/ (- window-height tex-h) 2.0))

  ;; Main loop
  (let loop ([x start-x] [y start-y] [running? #t])
    (when running?
      ;; Process all pending events, accumulating position changes
      (define-values (new-x new-y still-running?)
        (for/fold ([curr-x x] [curr-y y] [run? #t])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            ;; Quit events
            [(or (quit-event) (window-event 'close-requested))
             (values curr-x curr-y #f)]

            ;; Key down events
            [(key-event 'down key _ _ _)
             (cond
               [(= key SDLK_ESCAPE)
                (values curr-x curr-y #f)]
               [(= key SDLK_LEFT)
                (values (- curr-x move-speed) curr-y run?)]
               [(= key SDLK_RIGHT)
                (values (+ curr-x move-speed) curr-y run?)]
               [(= key SDLK_UP)
                (values curr-x (- curr-y move-speed) run?)]
               [(= key SDLK_DOWN)
                (values curr-x (+ curr-y move-speed) run?)]
               [else
                (values curr-x curr-y run?)])]

            ;; Ignore other events
            [_ (values curr-x curr-y run?)])))

      ;; Render if still running
      (when still-running?
        ;; Clear to dark gray
        (set-draw-color! renderer 40 40 40)
        (render-clear! renderer)

        ;; Draw the texture at current position
        (render-texture! renderer tex new-x new-y)

        ;; Present
        (render-present! renderer)

        ;; Small delay (~60fps)
        (delay! 16)

        (loop new-x new-y still-running?))))

  ;; Clean up (important for REPL usage)
  (texture-destroy! tex)
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run when executed directly
(module+ main
  (main))
