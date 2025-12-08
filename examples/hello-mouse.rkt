#lang racket/base

;; Hello Mouse - SDL3 Racket Bindings Example
;;
;; Demonstrates mouse state polling with SDL_GetMouseState.
;; - Circle follows mouse cursor
;; - Color changes based on which buttons are pressed
;; - Trail of previous positions
;; Press ESC or close the window to exit.

(require ffi/unsafe
         racket/math
         racket/list
         sdl3)

(define WINDOW_WIDTH 800)
(define WINDOW_HEIGHT 600)
(define WINDOW_TITLE "SDL3 Racket - Hello Mouse")

(define PI 3.141592653589793)

;; Draw a filled circle using points (since we don't have circle primitives)
(define (draw-circle renderer cx cy radius)
  (for* ([dy (in-range (- radius) (+ radius 1))])
    (define dx-max (sqrt (max 0 (- (* radius radius) (* dy dy)))))
    (when (> dx-max 0)
      (SDL-RenderLine renderer
                      (- cx dx-max) (+ cy dy)
                      (+ cx dx-max) (+ cy dy)))))

(define (main)
  ;; Initialize SDL video subsystem
  (unless (SDL-Init SDL_INIT_VIDEO)
    (error 'main "Failed to initialize SDL: ~a" (SDL-GetError)))

  (define window #f)
  (define renderer #f)

  (dynamic-wind
    void
    (λ ()
      ;; Create window
      (set! window (SDL-CreateWindow WINDOW_TITLE
                                     WINDOW_WIDTH
                                     WINDOW_HEIGHT
                                     SDL_WINDOW_RESIZABLE))
      (unless window
        (error 'main "Failed to create window: ~a" (SDL-GetError)))

      ;; Create renderer
      (set! renderer (SDL-CreateRenderer window #f))
      (unless renderer
        (error 'main "Failed to create renderer: ~a" (SDL-GetError)))

      ;; Event buffer
      (define event-buf (malloc SDL_EVENT_SIZE))
      (define running? #t)

      ;; Mouse position storage
      (define mouse-x-ptr (malloc _float))
      (define mouse-y-ptr (malloc _float))

      ;; Trail of previous positions (list of (x . y) pairs)
      (define trail '())
      (define max-trail-length 50)

      ;; Main loop
      (let loop ()
        (when running?
          ;; Poll all pending events
          (let poll-events ()
            (when (SDL-PollEvent event-buf)
              (define event-type (sdl-event-type event-buf))
              (cond
                [(= event-type SDL_EVENT_QUIT)
                 (set! running? #f)]
                [(= event-type SDL_EVENT_KEY_DOWN)
                 (define kb-event (event->keyboard event-buf))
                 (define key (SDL_KeyboardEvent-key kb-event))
                 (when (= key SDLK_ESCAPE)
                   (set! running? #f))])
              (poll-events)))

          (when running?
            ;; Get mouse state
            (define buttons (SDL-GetMouseState mouse-x-ptr mouse-y-ptr))
            (define mouse-x (ptr-ref mouse-x-ptr _float))
            (define mouse-y (ptr-ref mouse-y-ptr _float))

            ;; Check which buttons are pressed
            (define left-pressed? (not (zero? (bitwise-and buttons SDL_BUTTON_LMASK))))
            (define middle-pressed? (not (zero? (bitwise-and buttons SDL_BUTTON_MMASK))))
            (define right-pressed? (not (zero? (bitwise-and buttons SDL_BUTTON_RMASK))))

            ;; Add to trail
            (set! trail (cons (cons mouse-x mouse-y) trail))
            (when (> (length trail) max-trail-length)
              (set! trail (take trail max-trail-length)))

            ;; Clear screen
            (SDL-SetRenderDrawColor renderer 20 20 30 255)
            (SDL-RenderClear renderer)

            ;; Draw trail (fading circles)
            (for ([pos (in-list (reverse trail))]
                  [i (in-naturals)])
              (define alpha (exact-round (* 255 (/ i max-trail-length))))
              (define trail-radius (+ 5 (* 15 (/ i max-trail-length))))
              (SDL-SetRenderDrawColor renderer 100 100 (+ 100 (quotient alpha 2)) 255)
              (draw-circle renderer (car pos) (cdr pos) trail-radius))

            ;; Determine cursor color based on buttons
            (define-values (r g b)
              (cond
                [(and left-pressed? right-pressed?) (values 255 255 0)]   ; yellow
                [left-pressed? (values 255 100 100)]                       ; red
                [right-pressed? (values 100 100 255)]                      ; blue
                [middle-pressed? (values 100 255 100)]                     ; green
                [else (values 255 255 255)]))                              ; white

            ;; Draw cursor circle
            (SDL-SetRenderDrawColor renderer r g b 255)
            (draw-circle renderer mouse-x mouse-y 25.0)

            ;; Draw smaller inner circle
            (SDL-SetRenderDrawColor renderer
                                    (quotient r 2)
                                    (quotient g 2)
                                    (quotient b 2) 255)
            (draw-circle renderer mouse-x mouse-y 15.0)

            ;; Draw crosshair at mouse position
            (SDL-SetRenderDrawColor renderer r g b 255)
            (SDL-RenderLine renderer (- mouse-x 30) mouse-y (- mouse-x 10) mouse-y)
            (SDL-RenderLine renderer (+ mouse-x 10) mouse-y (+ mouse-x 30) mouse-y)
            (SDL-RenderLine renderer mouse-x (- mouse-y 30) mouse-x (- mouse-y 10))
            (SDL-RenderLine renderer mouse-x (+ mouse-y 10) mouse-x (+ mouse-y 30))

            ;; Draw button indicators at bottom
            (define indicator-y 560.0)
            (define indicator-size 30.0)

            ;; Left button indicator
            (if left-pressed?
                (SDL-SetRenderDrawColor renderer 255 100 100 255)
                (SDL-SetRenderDrawColor renderer 80 40 40 255))
            (define left-rect (make-SDL_FRect 50.0 indicator-y indicator-size indicator-size))
            (SDL-RenderFillRect renderer left-rect)

            ;; Middle button indicator
            (if middle-pressed?
                (SDL-SetRenderDrawColor renderer 100 255 100 255)
                (SDL-SetRenderDrawColor renderer 40 80 40 255))
            (define middle-rect (make-SDL_FRect 90.0 indicator-y indicator-size indicator-size))
            (SDL-RenderFillRect renderer middle-rect)

            ;; Right button indicator
            (if right-pressed?
                (SDL-SetRenderDrawColor renderer 100 100 255 255)
                (SDL-SetRenderDrawColor renderer 40 40 80 255))
            (define right-rect (make-SDL_FRect 130.0 indicator-y indicator-size indicator-size))
            (SDL-RenderFillRect renderer right-rect)

            ;; Present the rendered frame
            (SDL-RenderPresent renderer)

            ;; Small delay
            (SDL-Delay 16)

            (loop)))))

    ;; Cleanup
    (λ ()
      (when renderer
        (SDL-DestroyRenderer renderer))
      (when window
        (SDL-DestroyWindow window))
      (SDL-Quit))))

;; Run the main function
(main)
