#lang racket/base

;; Hello Window - Your First SDL3 Program
;;
;; Creates a window with a colored background.
;; This is the simplest possible SDL3 program.
;;
;; Close the window or press Escape to exit.

(require racket/match
         sdl3)

(define (main)
  (with-sdl
    (with-window+renderer "Hello SDL3!" 800 600 (window renderer)
      ;; Main loop
      (let loop ()
        ;; Check for quit events
        (define quit?
          (for/or ([ev (in-events)])
            (match ev
              [(quit-event) #t]
              [(key-event 'down 'escape _ _ _) #t]
              [_ #f])))

        (unless quit?
          ;; Set background color (cornflower blue)
          (set-draw-color! renderer 100 149 237)

          ;; Clear the screen
          (render-clear! renderer)

          ;; Show the frame
          (render-present! renderer)

          ;; Continue the loop
          (loop))))))

(module+ main
  (main))
