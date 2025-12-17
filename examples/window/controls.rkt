#lang racket/base

;; Window Size & Position Demo
;;
;; Demonstrates controlling window size, position, fullscreen mode,
;; opacity, size constraints, and other window management features.
;;
;; Controls:
;;   Arrow keys - Move window (50 pixel steps)
;;   +/= - Increase window size
;;   -/_ - Decrease window size
;;   F - Toggle fullscreen
;;   C - Center window on screen
;;   R - Reset to original size and position
;;   O - Cycle opacity (100% -> 75% -> 50% -> 25% -> 100%)
;;   B - Toggle window border
;;   M - Minimize window
;;   X - Maximize window
;;   A - Flash window briefly (for attention)
;;   T - Get and display window title
;;   ESC - Quit

(require racket/match
         racket/format
         sdl3)

(define initial-width 800)
(define initial-height 600)
(define initial-title "SDL3 Window Controls Demo")

(define font-path "/System/Library/Fonts/Supplemental/Arial.ttf")
(define base-font-size 18.0)

;; Movement and resize steps
(define move-step 50)
(define size-step 50)
(define min-size 200)

;; Opacity levels for cycling
(define opacity-levels '(1.0 0.75 0.5 0.25))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer initial-title initial-width initial-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  ;; Scale font for high-DPI
  (define pixel-density (window-pixel-density window))
  (define font-size (* base-font-size pixel-density))
  (define font (open-font font-path font-size))

  ;; Store initial position for reset
  (define-values (init-x init-y) (window-position window))

  ;; Set minimum window size constraint
  (set-window-minimum-size! window min-size min-size)

  (let loop ([running? #t]
             [opacity-idx 0]
             [bordered? #t])
    (when running?
      ;; Get current window state
      (define-values (win-w win-h) (window-size window))
      (define-values (win-x win-y) (window-position window))
      (define fullscreen? (window-fullscreen? window))

      ;; Handle events
      (define-values (still-running? new-opacity-idx new-bordered?)
        (for/fold ([run? #t]
                   [oidx opacity-idx]
                   [bord? bordered?])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            [(or (quit-event) (window-event 'close-requested))
             (values #f oidx bord?)]

            [(key-event 'down key _ _ _)
             (cond
               [(= key SDLK_ESCAPE) (values #f oidx bord?)]

               ;; Arrow keys - move window
               [(= key SDLK_LEFT)
                (window-set-position! window (- win-x move-step) win-y)
                (values run? oidx bord?)]
               [(= key SDLK_RIGHT)
                (window-set-position! window (+ win-x move-step) win-y)
                (values run? oidx bord?)]
               [(= key SDLK_UP)
                (window-set-position! window win-x (- win-y move-step))
                (values run? oidx bord?)]
               [(= key SDLK_DOWN)
                (window-set-position! window win-x (+ win-y move-step))
                (values run? oidx bord?)]

               ;; +/= - increase size
               [(or (= key SDLK_EQUALS) (= key SDLK_PLUS))
                (window-set-size! window (+ win-w size-step) (+ win-h size-step))
                (values run? oidx bord?)]

               ;; - decrease size
               [(= key SDLK_MINUS)
                (window-set-size! window
                                  (max min-size (- win-w size-step))
                                  (max min-size (- win-h size-step)))
                (values run? oidx bord?)]

               ;; F - toggle fullscreen
               [(= key SDLK_F)
                (window-set-fullscreen! window (not fullscreen?))
                (values run? oidx bord?)]

               ;; C - center window (approximate, assumes 1920x1080 display)
               [(= key SDLK_C)
                (window-set-position! window
                                      (quotient (- 1920 win-w) 2)
                                      (quotient (- 1080 win-h) 2))
                (values run? oidx bord?)]

               ;; R - reset
               [(= key SDLK_R)
                (when fullscreen?
                  (window-set-fullscreen! window #f))
                (window-set-size! window initial-width initial-height)
                (window-set-position! window init-x init-y)
                (set-window-opacity! window 1.0)
                (set-window-bordered! window #t)
                (values run? 0 #t)]  ; reset opacity-idx and bordered?

               ;; O - cycle opacity
               [(= key SDLK_O)
                (define next-idx (modulo (+ oidx 1) (length opacity-levels)))
                (define next-opacity (list-ref opacity-levels next-idx))
                (set-window-opacity! window next-opacity)
                (values run? next-idx bord?)]

               ;; B - toggle border
               [(= key SDLK_B)
                (define new-bord? (not bord?))
                (set-window-bordered! window new-bord?)
                (values run? oidx new-bord?)]

               ;; M - minimize
               [(= key SDLK_M)
                (minimize-window! window)
                (values run? oidx bord?)]

               ;; X - maximize
               [(= key SDLK_X)
                (maximize-window! window)
                (values run? oidx bord?)]

               ;; A - flash window
               [(= key SDLK_A)
                (flash-window! window 'briefly)
                (values run? oidx bord?)]

               ;; T - show window title
               [(= key SDLK_T)
                (printf "Window title: ~a~n" (window-title window))
                (values run? oidx bord?)]

               [else (values run? oidx bord?)])]

            [_ (values run? oidx bord?)])))

      (when still-running?
        ;; Re-fetch window state (may have changed)
        (define-values (curr-w curr-h) (window-size window))
        (define-values (curr-x curr-y) (window-position window))
        (define curr-fullscreen? (window-fullscreen? window))

        ;; Clear to dark background
        (set-draw-color! renderer 40 40 40)
        (render-clear! renderer)

        ;; Draw info text
        (draw-text! renderer font "Window Size & Position Demo"
                    20 20 '(255 255 255 255))

        (draw-text! renderer font "Arrows=Move | +/-=Size | F=Full | C=Center | R=Reset | O=Opacity"
                    20 50 '(180 180 180 255))
        (draw-text! renderer font "B=Border | M=Minimize | X=Maximize | A=Flash | T=Title"
                    20 75 '(180 180 180 255))

        ;; Show current values
        (define size-text (format "Size: ~a x ~a" curr-w curr-h))
        (define pos-text (format "Position: (~a, ~a)" curr-x curr-y))
        (define fs-text (format "Fullscreen: ~a" (if curr-fullscreen? "ON" "off")))
        (define opacity-text (format "Opacity: ~a%" (inexact->exact (round (* 100 (list-ref opacity-levels new-opacity-idx))))))
        (define border-text (format "Border: ~a" (if new-bordered? "ON" "off")))

        (draw-text! renderer font size-text 20 145 '(255 255 0 255))
        (draw-text! renderer font pos-text 20 170 '(255 255 0 255))
        (draw-text! renderer font fs-text 20 195 '(255 255 0 255))
        (draw-text! renderer font opacity-text 20 220 '(255 255 0 255))
        (draw-text! renderer font border-text 20 245 '(255 255 0 255))

        ;; Draw a border to visualize window bounds
        (set-draw-color! renderer 100 100 255 255)
        (draw-rect! renderer 10 10 (- curr-w 20) (- curr-h 20))

        (render-present! renderer)
        (delay! 16)

        (loop still-running? new-opacity-idx new-bordered?))))

  (close-font! font)

  ;; Clean up (important for REPL usage)
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run the example when executed directly
(module+ main
  (main))
