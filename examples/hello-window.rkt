#lang racket/base

;; Hello Window - SDL3 Racket Bindings Example
;;
;; Creates an 800x600 window with a cornflower blue background.
;; Close the window to exit.

(require ffi/unsafe
         sdl3)

(define WINDOW_WIDTH 800)
(define WINDOW_HEIGHT 600)
(define WINDOW_TITLE "SDL3 Racket - Hello Window")

;; Cornflower blue: R=100, G=149, B=237
(define COLOR_R 100)
(define COLOR_G 149)
(define COLOR_B 237)
(define COLOR_A 255)

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

      ;; Create renderer (use default renderer by passing #f)
      (set! renderer (SDL-CreateRenderer window #f))
      (unless renderer
        (error 'main "Failed to create renderer: ~a" (SDL-GetError)))

      ;; Event buffer - SDL_Event is a union, ~128 bytes max
      (define event-buf (malloc 128))
      (define running? #t)

      ;; Main loop
      (let loop ()
        (when running?
          ;; Poll all pending events
          (let poll-events ()
            (when (SDL-PollEvent event-buf)
              ;; Read event type (first 4 bytes as uint32)
              (define event-type (ptr-ref event-buf _uint32))
              (when (= event-type SDL_EVENT_QUIT)
                (set! running? #f))
              (poll-events)))

          (when running?
            ;; Set draw color to cornflower blue
            (SDL-SetRenderDrawColor renderer COLOR_R COLOR_G COLOR_B COLOR_A)

            ;; Clear the screen
            (SDL-RenderClear renderer)

            ;; Present the rendered frame
            (SDL-RenderPresent renderer)

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
