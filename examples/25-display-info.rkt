#lang racket/base

;; Display Information Demo
;;
;; Demonstrates the display management API to query monitor information.
;; This is useful for:
;; - Multi-monitor setups
;; - Proper fullscreen mode selection
;; - HiDPI/Retina display handling
;;
;; Features:
;; - Lists all connected displays
;; - Shows resolution, refresh rate, scale factor
;; - Shows display bounds and usable bounds
;; - Shows available fullscreen modes
;; - Window-display relationship
;;
;; Press Escape to quit, F to toggle fullscreen.

(require racket/match
         racket/format
         ffi/unsafe
         sdl3/safe)

(define window-width 800)
(define window-height 600)

;; Scroll offset for fullscreen modes list
(define scroll-offset 0)
(define max-scroll 0)

;; Currently selected display for mode listing
(define selected-display-index 0)
(define display-list '())

;; Draw a section header
(define (draw-header! renderer x y text)
  (set-draw-color! renderer 100 180 255)
  (render-debug-text! renderer x y text))

;; Draw a label-value pair
(define (draw-info! renderer x y label value)
  (set-draw-color! renderer 120 120 130)
  (render-debug-text! renderer x y label)
  (set-draw-color! renderer 200 200 200)
  (render-debug-text! renderer (+ x (* (string-length label) 8) 8) y value))

;; Draw display information panel
(define (draw-display-panel! renderer x y display-id index)
  (define name (display-name display-id))
  (define-values (bx by bw bh) (display-bounds display-id))
  (define-values (ux uy uw uh) (display-usable-bounds display-id))
  (define mode (current-display-mode display-id))
  (define scale (display-content-scale display-id))
  (define primary? (= display-id (primary-display)))

  ;; Background panel
  (define selected? (= index selected-display-index))
  (if selected?
      (set-draw-color! renderer 50 50 70)
      (set-draw-color! renderer 35 35 45))
  (fill-rect! renderer x y 370 130)
  (if selected?
      (set-draw-color! renderer 100 100 150)
      (set-draw-color! renderer 60 60 70))
  (draw-rect! renderer x y 370 130)

  ;; Display name and index
  (draw-header! renderer (+ x 10) (+ y 8)
                (~a "Display " index
                    (if primary? " (PRIMARY)" "")
                    (if selected? " [SELECTED]" "")))

  (set-draw-color! renderer 180 180 180)
  (render-debug-text! renderer (+ x 10) (+ y 22) name)

  ;; Resolution and refresh rate
  (define-values (mw mh) (display-mode-resolution mode))
  (define refresh (display-mode-refresh-rate mode))
  (draw-info! renderer (+ x 10) (+ y 40) "Resolution:"
              (~a mw "x" mh " @ " (~r refresh #:precision 1) "Hz"))

  ;; Pixel density and scale
  (define density (SDL_DisplayMode-pixel_density mode))
  (draw-info! renderer (+ x 10) (+ y 55) "Scale:"
              (~a (~r scale #:precision 2) "x"
                  " (density: " (~r density #:precision 2) ")"))

  ;; Display bounds
  (draw-info! renderer (+ x 10) (+ y 70) "Bounds:"
              (~a bx "," by " " bw "x" bh))

  ;; Usable bounds (excludes dock/taskbar)
  (draw-info! renderer (+ x 10) (+ y 85) "Usable:"
              (~a ux "," uy " " uw "x" uh))

  ;; Pixel format
  (define format (SDL_DisplayMode-format mode))
  (draw-info! renderer (+ x 10) (+ y 100) "Format:"
              (~a "0x" (number->string format 16)))

  ;; Instructions for selection
  (set-draw-color! renderer 100 100 110)
  (render-debug-text! renderer (+ x 10) (+ y 115) "Tab: Select"))

;; Draw fullscreen modes panel
(define (draw-modes-panel! renderer x y display-id)
  (define modes (fullscreen-display-modes display-id))
  (set! max-scroll (max 0 (- (length modes) 12)))

  ;; Background panel
  (set-draw-color! renderer 35 35 45)
  (fill-rect! renderer x y 370 200)
  (set-draw-color! renderer 60 60 70)
  (draw-rect! renderer x y 370 200)

  (draw-header! renderer (+ x 10) (+ y 8) "FULLSCREEN MODES")

  ;; Column headers
  (set-draw-color! renderer 100 100 110)
  (render-debug-text! renderer (+ x 10) (+ y 25) "Resolution")
  (render-debug-text! renderer (+ x 120) (+ y 25) "Refresh")
  (render-debug-text! renderer (+ x 190) (+ y 25) "Density")
  (render-debug-text! renderer (+ x 260) (+ y 25) "Format")

  ;; Draw modes (with scrolling)
  (for ([mode (in-list modes)]
        [i (in-naturals)]
        #:when (>= i scroll-offset)
        #:break (>= (- i scroll-offset) 12))
    (define row-y (+ y 40 (* (- i scroll-offset) 13)))
    (define mode-ptr (cast mode _pointer _SDL_DisplayMode-pointer))
    (define w (SDL_DisplayMode-w mode-ptr))
    (define h (SDL_DisplayMode-h mode-ptr))
    (define refresh (SDL_DisplayMode-refresh_rate mode-ptr))
    (define density (SDL_DisplayMode-pixel_density mode-ptr))
    (define format (SDL_DisplayMode-format mode-ptr))

    (set-draw-color! renderer 180 180 180)
    (render-debug-text! renderer (+ x 10) row-y (~a w "x" h))
    (render-debug-text! renderer (+ x 120) row-y (~a (~r refresh #:precision 1) "Hz"))
    (render-debug-text! renderer (+ x 190) row-y (~a (~r density #:precision 2) "x"))
    (render-debug-text! renderer (+ x 260) row-y
                        (~a "0x" (number->string format 16))))

  ;; Scroll indicator
  (when (> (length modes) 12)
    (set-draw-color! renderer 100 100 110)
    (render-debug-text! renderer (+ x 10) (+ y 185)
                        (~a "Scroll: " scroll-offset "/" max-scroll
                            " (Up/Down to scroll)"))))

;; Draw window info panel
(define (draw-window-panel! renderer window x y)
  (set-draw-color! renderer 35 35 45)
  (fill-rect! renderer x y 370 70)
  (set-draw-color! renderer 60 60 70)
  (draw-rect! renderer x y 370 70)

  (draw-header! renderer (+ x 10) (+ y 8) "WINDOW INFO")

  ;; Window's display
  (define win-display (window-display window))
  (define win-scale (window-display-scale window))
  (draw-info! renderer (+ x 10) (+ y 25) "Display:"
              (~a (display-name win-display)))
  (draw-info! renderer (+ x 10) (+ y 40) "Scale:"
              (~a (~r win-scale #:precision 2) "x"))

  (set-draw-color! renderer 100 100 110)
  (render-debug-text! renderer (+ x 10) (+ y 55) "F: Toggle fullscreen"))

;; Draw instructions
(define (draw-instructions! renderer)
  (set-draw-color! renderer 35 35 45)
  (fill-rect! renderer 10 (- window-height 35) 400 25)
  (set-draw-color! renderer 60 60 70)
  (draw-rect! renderer 10 (- window-height 35) 400 25)

  (set-draw-color! renderer 120 120 130)
  (render-debug-text! renderer 20 (- window-height 27)
                      "Tab: Select display | F: Fullscreen | Esc: Quit"))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer "SDL3 Display Info Demo" window-width window-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  (printf "Display Information Demo~n")
  (printf "========================~n~n")

  ;; Get display list
  (set! display-list (get-displays))
  (printf "Found ~a display(s)~n" (length display-list))

  ;; Print display info to console
  (for ([display-id (in-list display-list)]
        [i (in-naturals)])
    (printf "~nDisplay ~a: ~a~n" i (display-name display-id))
    (define mode (current-display-mode display-id))
    (printf "  Resolution: ~ax~a @ ~a Hz~n"
            (SDL_DisplayMode-w mode)
            (SDL_DisplayMode-h mode)
            (~r (SDL_DisplayMode-refresh_rate mode) #:precision 1))
    (printf "  Content scale: ~ax~n"
            (~r (display-content-scale display-id) #:precision 2)))

  (printf "~nControls:~n")
  (printf "  Tab: Select display~n")
  (printf "  Up/Down: Scroll modes~n")
  (printf "  F: Toggle fullscreen~n")
  (printf "  Escape: Quit~n~n")

  (let loop ([running? #t])
    (when running?
      ;; Process events
      (define quit?
        (for/or ([ev (in-events)])
          (match ev
            [(or (quit-event) (window-event 'close-requested)) #t]
            [(key-event 'down (== SDLK_ESCAPE) _ _ _) #t]
            [(key-event 'down (== SDLK_TAB) _ _ _)
             (set! selected-display-index
                   (modulo (add1 selected-display-index) (length display-list)))
             (set! scroll-offset 0)
             #f]
            [(key-event 'down (== SDLK_F) _ _ _)
             (define fullscreen? (window-fullscreen? window))
             (window-set-fullscreen! window (not fullscreen?))
             #f]
            [(key-event 'down (== SDLK_UP) _ _ _)
             (set! scroll-offset (max 0 (sub1 scroll-offset)))
             #f]
            [(key-event 'down (== SDLK_DOWN) _ _ _)
             (set! scroll-offset (min max-scroll (add1 scroll-offset)))
             #f]
            [_ #f])))

      (unless quit?
        ;; Clear background
        (set-draw-color! renderer 25 25 30)
        (render-clear! renderer)

        ;; Draw display panels (up to 2 displays side by side)
        (for ([display-id (in-list display-list)]
              [i (in-naturals)]
              #:break (>= i 2))
          (define panel-x (+ 10 (* i 390)))
          (draw-display-panel! renderer panel-x 10 display-id i))

        ;; Draw fullscreen modes for selected display
        (when (< selected-display-index (length display-list))
          (define selected-id (list-ref display-list selected-display-index))
          (draw-modes-panel! renderer 10 150 selected-id))

        ;; Draw window info
        (draw-window-panel! renderer window 10 360)

        ;; Draw instructions
        (draw-instructions! renderer)

        (render-present! renderer)
        (delay! 16)
        (loop (not quit?)))))

  (printf "~nDone.~n")

  ;; Clean up
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run when executed directly
(module+ main
  (main))
