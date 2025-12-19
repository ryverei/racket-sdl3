#lang racket/base

;; Basic Input - Keyboard and Mouse
;;
;; Demonstrates simple input handling:
;; - Arrow keys or WASD to move a square
;; - Click to change the square's color
;;
;; Press Escape to exit.

(require racket/match
         sdl3)

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer "Basic Input" 800 600))

  ;; Square position and color
  (define x 400.0)
  (define y 300.0)
  (define size 60)
  (define speed 5.0)
  (define r 100)
  (define g 200)
  (define b 255)

  (let loop ()
    ;; Get keyboard state for smooth movement
    (define kbd (get-keyboard-state))

    ;; Process events
    (define quit?
      (for/or ([ev (in-events)])
        (match ev
          [(quit-event) #t]
          [(key-event 'down (== SDLK_ESCAPE) _ _ _) #t]
          ;; Click to change color
          [(mouse-button-event 'down _ _ _ _)
           (set! r (random 256))
           (set! g (random 256))
           (set! b (random 256))
           #f]
          [_ #f])))

    (unless quit?
      ;; Move with WASD or arrow keys
      (when (or (kbd SDL_SCANCODE_W) (kbd SDL_SCANCODE_UP))
        (set! y (max 0 (- y speed))))
      (when (or (kbd SDL_SCANCODE_S) (kbd SDL_SCANCODE_DOWN))
        (set! y (min (- 600 size) (+ y speed))))
      (when (or (kbd SDL_SCANCODE_A) (kbd SDL_SCANCODE_LEFT))
        (set! x (max 0 (- x speed))))
      (when (or (kbd SDL_SCANCODE_D) (kbd SDL_SCANCODE_RIGHT))
        (set! x (min (- 800 size) (+ x speed))))

      ;; Draw
      (set-draw-color! renderer 30 30 40)
      (render-clear! renderer)

      ;; Draw the square
      (set-draw-color! renderer r g b)
      (fill-rect! renderer x y size size)

      ;; Instructions
      (set-draw-color! renderer 150 150 150)
      (render-debug-text! renderer 10 10 "Basic Input Demo")
      (render-debug-text! renderer 10 25 "WASD/Arrows: Move | Click: Change color | ESC: Quit")

      (render-present! renderer)
      (delay! 16)
      (loop)))

  (renderer-destroy! renderer)
  (window-destroy! window))

(module+ main
  (main))
