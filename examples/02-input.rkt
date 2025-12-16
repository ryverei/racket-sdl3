#lang racket/base

;; Interactive SDL3 example - keyboard and mouse input
;; - Press R, G, B to change background color
;; - Mouse position shown in window title
;; - Press Escape or close window to quit
;; - Key presses printed to console
;;
;; This example uses the idiomatic safe interface.

(require racket/match
         sdl3/safe)

(define window-width 800)
(define window-height 600)
(define initial-title "SDL3 Input - Move mouse, press R/G/B")

;; Current background color (mutable)
(define bg-r 0)
(define bg-g 0)
(define bg-b 0)

(define (set-color! r g b)
  (set! bg-r r)
  (set! bg-g g)
  (set! bg-b b))

(define (main)
  ;; Initialize SDL video subsystem
  (sdl-init!)

  ;; Create window and renderer
  (define-values (window renderer)
    (make-window+renderer initial-title window-width window-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  ;; Main loop
  (let loop ([running? #t])
    (when running?
      ;; Process all pending events
      (define still-running?
        (for/fold ([running? #t])
                  ([ev (in-events)]
                   #:break (not running?))
          (match ev
            ;; Quit events
            [(or (quit-event) (window-event 'close-requested))
             #f]

            ;; Key down events
            [(key-event 'down key _ _ _)
             ;; Print key name
             (printf "Key pressed: ~a~n" (key-name key))

             ;; Check for color keys or escape
             (cond
               [(= key SDLK_ESCAPE) #f]
               [(= key SDLK_R)
                (set-color! 255 0 0)
                running?]
               [(= key SDLK_G)
                (set-color! 0 255 0)
                running?]
               [(= key SDLK_B)
                (set-color! 0 0 255)
                running?]
               [else running?])]

            ;; Mouse motion - update window title
            [(mouse-motion-event x y _ _ _)
             (define title (format "SDL3 Input - Mouse: (~a, ~a)"
                                   (inexact->exact (round x))
                                   (inexact->exact (round y))))
             (window-set-title! window title)
             running?]

            ;; Ignore other events
            [_ running?])))

      ;; Render if still running
      (when still-running?
        (set-draw-color! renderer bg-r bg-g bg-b)
        (render-clear! renderer)
        (render-present! renderer)
        (delay! 16)
        (loop still-running?))))

  ;; Clean up (important for REPL usage)
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run the main function when executed directly
(module+ main
  (main))
