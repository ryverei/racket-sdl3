#lang racket/base

;; Keyboard State Demo
;;
;; Demonstrates polling-based keyboard input using SDL_GetKeyboardState.
;; This is useful for smooth, continuous input (like game movement) as
;; opposed to event-based input which is better for discrete actions.
;;
;; Features:
;; - Smooth character movement with WASD/arrow keys
;; - Shows all currently pressed keys
;; - Modifier state display
;; - FPS counter showing polling frequency
;;
;; Press Escape to quit.

(require racket/match
         racket/format
         sdl3/safe)

(define window-width 800)
(define window-height 600)

;; Player state
(define player-x 400.0)
(define player-y 300.0)
(define player-size 40.0)
(define move-speed 5.0)

;; Timing for FPS counter
(define last-fps-time 0)
(define frame-count 0)
(define current-fps 0)

;; Draw the player (a simple square)
(define (draw-player! renderer)
  (set-draw-color! renderer 100 200 255)
  (fill-rect! renderer
              (- player-x (/ player-size 2))
              (- player-y (/ player-size 2))
              player-size
              player-size)
  ;; Draw border
  (set-draw-color! renderer 150 230 255)
  (draw-rect! renderer
              (- player-x (/ player-size 2))
              (- player-y (/ player-size 2))
              player-size
              player-size))

;; Draw a single key indicator with label
(define (draw-key-box! renderer x y w h label pressed? color-on)
  (if pressed?
      (apply set-draw-color! renderer color-on)
      (set-draw-color! renderer 60 60 70))
  (fill-rect! renderer x y w h)
  (set-draw-color! renderer 80 80 90)
  (draw-rect! renderer x y w h)
  ;; Draw label centered in box
  (set-draw-color! renderer 200 200 200)
  (define label-x (+ x (/ (- w (* (string-length label) 8)) 2)))
  (define label-y (+ y (/ (- h 8) 2)))
  (render-debug-text! renderer label-x label-y label))

;; Draw a panel showing pressed keys
(define (draw-pressed-keys! renderer kbd)
  ;; Background panel
  (set-draw-color! renderer 35 35 45)
  (fill-rect! renderer 10 10 280 120)
  (set-draw-color! renderer 60 60 70)
  (draw-rect! renderer 10 10 280 120)

  ;; Title
  (set-draw-color! renderer 150 150 150)
  (render-debug-text! renderer 20 18 "WASD")
  (render-debug-text! renderer 160 18 "ARROWS")

  ;; Draw indicator boxes for WASD
  (define wasd-y 40)
  (define wasd-x 30)
  (define key-w 35)
  (define key-h 28)
  (define gap 5)
  (define green '(100 200 100))
  (define yellow '(200 200 100))

  ;; WASD keys
  (draw-key-box! renderer (+ wasd-x key-w gap) wasd-y key-w key-h "W"
                 (kbd SDL_SCANCODE_W) green)
  (draw-key-box! renderer wasd-x (+ wasd-y key-h gap) key-w key-h "A"
                 (kbd SDL_SCANCODE_A) green)
  (draw-key-box! renderer (+ wasd-x key-w gap) (+ wasd-y key-h gap) key-w key-h "S"
                 (kbd SDL_SCANCODE_S) green)
  (draw-key-box! renderer (+ wasd-x (* 2 (+ key-w gap))) (+ wasd-y key-h gap) key-w key-h "D"
                 (kbd SDL_SCANCODE_D) green)

  ;; Arrow keys
  (define arrow-x 160)
  (draw-key-box! renderer (+ arrow-x key-w gap) wasd-y key-w key-h "^"
                 (kbd SDL_SCANCODE_UP) yellow)
  (draw-key-box! renderer arrow-x (+ wasd-y key-h gap) key-w key-h "<"
                 (kbd SDL_SCANCODE_LEFT) yellow)
  (draw-key-box! renderer (+ arrow-x key-w gap) (+ wasd-y key-h gap) key-w key-h "v"
                 (kbd SDL_SCANCODE_DOWN) yellow)
  (draw-key-box! renderer (+ arrow-x (* 2 (+ key-w gap))) (+ wasd-y key-h gap) key-w key-h ">"
                 (kbd SDL_SCANCODE_RIGHT) yellow))

;; Draw modifier state
(define (draw-mod-state! renderer)
  (define mods (get-mod-state))

  (set-draw-color! renderer 35 35 45)
  (fill-rect! renderer 10 140 280 45)
  (set-draw-color! renderer 60 60 70)
  (draw-rect! renderer 10 140 280 45)

  ;; Title
  (set-draw-color! renderer 150 150 150)
  (render-debug-text! renderer 20 148 "MODIFIERS")

  (define mod-x 20)
  (define mod-y 162)
  (define box-w 60)
  (define box-h 18)
  (define gap 5)

  ;; Shift
  (draw-key-box! renderer mod-x mod-y box-w box-h "SHIFT"
                 (not (zero? (bitwise-and mods SDL_KMOD_SHIFT)))
                 '(255 200 100))

  ;; Ctrl
  (draw-key-box! renderer (+ mod-x box-w gap) mod-y box-w box-h "CTRL"
                 (not (zero? (bitwise-and mods SDL_KMOD_CTRL)))
                 '(100 200 255))

  ;; Alt
  (draw-key-box! renderer (+ mod-x (* 2 (+ box-w gap))) mod-y box-w box-h "ALT"
                 (not (zero? (bitwise-and mods SDL_KMOD_ALT)))
                 '(100 255 150))

  ;; Gui/Cmd
  (draw-key-box! renderer (+ mod-x (* 3 (+ box-w gap))) mod-y box-w box-h "CMD"
                 (not (zero? (bitwise-and mods SDL_KMOD_GUI)))
                 '(255 150 200)))

;; Draw FPS indicator
(define (draw-fps! renderer)
  (set-draw-color! renderer 35 35 45)
  (fill-rect! renderer (- window-width 90) 10 80 30)
  (set-draw-color! renderer 60 60 70)
  (draw-rect! renderer (- window-width 90) 10 80 30)

  ;; FPS text
  (if (> current-fps 55)
      (set-draw-color! renderer 100 200 100)
      (set-draw-color! renderer 200 200 100))
  (render-debug-text! renderer (- window-width 82) 18
                      (~a "FPS: " current-fps)))

;; Draw instructions
(define (draw-instructions! renderer)
  (set-draw-color! renderer 35 35 45)
  (fill-rect! renderer 10 (- window-height 90) 350 80)
  (set-draw-color! renderer 60 60 70)
  (draw-rect! renderer 10 (- window-height 90) 350 80)

  (set-draw-color! renderer 150 150 150)
  (render-debug-text! renderer 20 (- window-height 82) "KEYBOARD STATE DEMO")
  (set-draw-color! renderer 120 120 120)
  (render-debug-text! renderer 20 (- window-height 65) "WASD/Arrows: Move the square")
  (render-debug-text! renderer 20 (- window-height 50) "Shift: Move faster")
  (render-debug-text! renderer 20 (- window-height 35) "Escape: Quit"))

;; Update FPS counter
(define (update-fps! current-time)
  (set! frame-count (add1 frame-count))
  (when (> (- current-time last-fps-time) 1000)
    (set! current-fps frame-count)
    (set! frame-count 0)
    (set! last-fps-time current-time)))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer "SDL3 Keyboard State Demo" window-width window-height))

  (printf "Keyboard State Demo~n")
  (printf "===================~n")
  (printf "This demo uses keyboard state polling (SDL_GetKeyboardState).~n")
  (printf "~n")
  (printf "Controls:~n")
  (printf "  WASD or Arrow keys: Move the square~n")
  (printf "  Shift: Move faster~n")
  (printf "  Escape: Quit~n~n")

  (set! last-fps-time (current-ticks))

  (let loop ([running? #t])
    (when running?
      ;; Get keyboard state once per frame
      (define kbd (get-keyboard-state))

      ;; Check for quit via event (ESC also checked below via state)
      (define quit?
        (for/or ([ev (in-events)])
          (match ev
            [(or (quit-event) (window-event 'close-requested)) #t]
            [_ #f])))

      ;; Also check escape via keyboard state
      (define should-quit? (or quit? (kbd SDL_SCANCODE_ESCAPE)))

      (unless should-quit?
        ;; Calculate speed (shift = faster)
        (define speed
          (if (mod-state-has? SDL_KMOD_SHIFT)
              (* move-speed 2)
              move-speed))

        ;; Handle movement with keyboard state (both WASD and arrows)
        (when (or (kbd SDL_SCANCODE_W) (kbd SDL_SCANCODE_UP))
          (set! player-y (max (/ player-size 2) (- player-y speed))))
        (when (or (kbd SDL_SCANCODE_S) (kbd SDL_SCANCODE_DOWN))
          (set! player-y (min (- window-height (/ player-size 2)) (+ player-y speed))))
        (when (or (kbd SDL_SCANCODE_A) (kbd SDL_SCANCODE_LEFT))
          (set! player-x (max (/ player-size 2) (- player-x speed))))
        (when (or (kbd SDL_SCANCODE_D) (kbd SDL_SCANCODE_RIGHT))
          (set! player-x (min (- window-width (/ player-size 2)) (+ player-x speed))))

        ;; Update FPS
        (update-fps! (current-ticks))

        ;; Clear background
        (set-draw-color! renderer 30 30 35)
        (render-clear! renderer)

        ;; Draw everything
        (draw-player! renderer)
        (draw-pressed-keys! renderer kbd)
        (draw-mod-state! renderer)
        (draw-fps! renderer)
        (draw-instructions! renderer)

        (render-present! renderer)
        (delay! 16)
        (loop (not should-quit?)))))

  (printf "~nDone.~n")

  ;; Clean up
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run when executed directly
(module+ main
  (main))
