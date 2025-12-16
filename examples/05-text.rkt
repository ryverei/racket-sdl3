#lang racket/base

;; SDL3_ttf example using the idiomatic safe interface
;; - Static greeting, live typed text, and FPS counter
;; - Escape quits, backspace deletes

(require racket/match
         racket/format
         sdl3/safe)

(define window-width 800)
(define window-height 600)
(define font-path "/System/Library/Fonts/Supplemental/Arial.ttf")
(define base-font-size 24.0)
(define backspace-key 8)

(define (trim-last s)
  (if (zero? (string-length s))
      s
      (substring s 0 (sub1 (string-length s)))))

(define (main)
  (sdl-init!)

  ;; Create window and renderer (managed by custodian)
  (define-values (window renderer)
    (make-window+renderer "SDL3 TTF - Type to see text"
                          window-width window-height
                          #:window-flags SDL_WINDOW_HIGH_PIXEL_DENSITY))

  ;; Scale font for high-DPI displays
  (define pixel-density (window-pixel-density window))
  (define font-size (* base-font-size pixel-density))
  (define font (open-font font-path font-size))

  ;; Enable text input events
  (SDL-StartTextInput window)

  (define static-color '(255 255 255 255))
  (define typed-color '(0 255 0 255))
  (define fps-color '(255 255 0 255))

  ;; Render once and reuse
  (define static-texture
    (render-text font "Hello from SDL3_ttf!"
                 static-color
                 #:renderer renderer))

  (let loop ([typed-text ""] [fps-text "FPS: --"]
             [frame-count 0]
             [last-time (current-inexact-milliseconds)]
             [running? #t])
    (when running?
      ;; Process events
      (define-values (new-text still-running?)
        (for/fold ([curr-text typed-text] [run? #t])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            [(or (quit-event) (window-event 'close-requested))
             (values curr-text #f)]

            [(key-event 'down key _ _ _)
             (cond
               [(= key SDLK_ESCAPE) (values curr-text #f)]
               [(= key backspace-key) (values (trim-last curr-text) run?)]
               [else (values curr-text run?)])]

            [(text-input-event txt)
             (values (string-append curr-text txt) run?)]

            [_ (values curr-text run?)])))

      ;; Update FPS counter (~2x per second)
      (define next-frame-count (add1 frame-count))
      (define current-time (current-inexact-milliseconds))
      (define elapsed (- current-time last-time))

      (define-values (next-fps-text next-frame next-last-time)
        (if (>= elapsed 500.0)
            (let ([fps (/ (* next-frame-count 1000.0) elapsed)])
              (values (format "FPS: ~a" (~r fps #:precision 1))
                      0
                      current-time))
            (values fps-text next-frame-count last-time)))

      (when still-running?
        ;; Clear background
        (set-draw-color! renderer 0 0 0)
        (render-clear! renderer)

        ;; Static greeting
        (when static-texture
          (render-texture! renderer static-texture 20 20))

        ;; Live typed text
        (draw-text! renderer font new-text 20 80 typed-color)

        ;; FPS counter
        (draw-text! renderer font next-fps-text 20 (- window-height 60) fps-color)

        (render-present! renderer)
        (delay! 16)

        (loop new-text next-fps-text next-frame next-last-time still-running?))))

  (SDL-StopTextInput window)

  (when static-texture
    (texture-destroy! static-texture))

  (close-font! font)

  ;; Clean up (important for REPL usage)
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run when executed directly
(module+ main
  (main))
