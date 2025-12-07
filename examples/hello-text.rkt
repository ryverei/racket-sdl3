#lang racket/base

;; SDL3 TTF example - Text rendering with keyboard input
;; - Shows static text "Hello from SDL3_ttf!"
;; - Type characters to display them dynamically
;; - Backspace to delete last character
;; - Shows FPS counter
;; - Press Escape to quit

(require ffi/unsafe
         racket/format
         sdl3
         sdl3/ttf)

(define WINDOW_WIDTH 800)
(define WINDOW_HEIGHT 600)
(define FONT_PATH "/System/Library/Fonts/Supplemental/Arial.ttf")
(define BASE_FONT_SIZE 24.0)

;; Current typed text (mutable)
(define typed-text "")

;; Add character to typed text
(define (add-char! ch)
  (set! typed-text (string-append typed-text (string ch))))

;; Remove last character
(define (backspace!)
  (when (> (string-length typed-text) 0)
    (set! typed-text (substring typed-text 0 (- (string-length typed-text) 1)))))

;; Create a texture from text using TTF
;; Returns #f on failure, texture pointer on success
(define (render-text-to-texture renderer font text color)
  (if (string=? text "")
      #f  ; Don't render empty string
      (let ()
        ;; Render text to surface (length 0 = null-terminated)
        (define surface (TTF-RenderText-Blended font text 0 color))
        (when (not surface)
          (printf "Warning: TTF_RenderText_Blended failed: ~a~n" (SDL-GetError))
          (set! surface #f))

        (if surface
            (let ()
              ;; Convert surface to texture
              (define texture (SDL-CreateTextureFromSurface renderer surface))

              ;; Free the surface (we have the texture now)
              (SDL-DestroySurface surface)

              (when (not texture)
                (printf "Warning: SDL_CreateTextureFromSurface failed: ~a~n" (SDL-GetError)))

              texture)
            #f))))

;; Get texture size (SDL3 uses floats)
(define (get-texture-size texture)
  (define w-ptr (malloc _float 'atomic-interior))
  (define h-ptr (malloc _float 'atomic-interior))
  (SDL-GetTextureSize texture w-ptr h-ptr)
  (values (ptr-ref w-ptr _float) (ptr-ref h-ptr _float)))

;; Render texture at position
(define (render-texture-at renderer texture x y)
  (when texture
    (define-values (w h) (get-texture-size texture))
    (define dest-rect (make-SDL_FRect x y w h))
    (SDL-RenderTexture renderer texture #f dest-rect)))

;; Handle key down event - only check for special keys
(define (handle-key-down event-ptr)
  (define kb (event->keyboard event-ptr))
  (define keycode (SDL_KeyboardEvent-key kb))

  (cond
    ;; Escape - quit
    [(= keycode SDLK_ESCAPE) #t]

    ;; Backspace - remove last character
    [(= keycode 8)  ; Backspace
     (backspace!)
     #f]

    ;; Other keys - ignore (printable characters come from text input events)
    [else #f]))

;; Handle text input event - get the actual typed character
(define (handle-text-input event-ptr)
  (define text-event (event->text-input event-ptr))
  (define text-ptr (SDL_TextInputEvent-text text-event))
  ;; The text field is already a pointer to a C string, so we cast it directly
  (define text (cast text-ptr _pointer _string/utf-8))
  ;; Add each character from the text (usually just one)
  (for ([ch (in-string text)])
    (add-char! ch)))

(define (main)
  ;; Initialize SDL video subsystem
  (unless (SDL-Init SDL_INIT_VIDEO)
    (error 'main "Failed to initialize SDL: ~a" (SDL-GetError)))

  ;; Initialize SDL_ttf
  (unless (TTF-Init)
    (error 'main "Failed to initialize SDL_ttf: ~a" (SDL-GetError)))

  (printf "SDL_ttf initialized successfully~n")

  (define window #f)
  (define renderer #f)
  (define font #f)

  (dynamic-wind
    void
    (lambda ()
      ;; Create window with high DPI support
      (set! window (SDL-CreateWindow "SDL3 TTF - Type to see text"
                                     WINDOW_WIDTH
                                     WINDOW_HEIGHT
                                     SDL_WINDOW_HIGH_PIXEL_DENSITY))
      (unless window
        (error 'main "Failed to create window: ~a" (SDL-GetError)))

      ;; Create renderer
      (set! renderer (SDL-CreateRenderer window #f))
      (unless renderer
        (error 'main "Failed to create renderer: ~a" (SDL-GetError)))

      ;; Get pixel density for font scaling (e.g., 2.0 on Retina)
      (define pixel-density (SDL-GetWindowPixelDensity window))
      (define font-size (* BASE_FONT_SIZE pixel-density))
      (printf "Pixel density: ~a, font size: ~a~n" pixel-density font-size)

      ;; Load font at scaled size
      (set! font (TTF-OpenFont FONT_PATH font-size))
      (unless font
        (error 'main "Failed to load font ~a: ~a" FONT_PATH (SDL-GetError)))

      (printf "Font loaded successfully: ~a at ~a pt~n" FONT_PATH font-size)

      ;; Enable text input for the window
      (SDL-StartTextInput window)

      ;; Create color structs
      (define white (make-SDL_Color 255 255 255 255))
      (define green (make-SDL_Color 0 255 0 255))
      (define yellow (make-SDL_Color 255 255 0 255))

      ;; Create static text texture
      (define static-text "Hello from SDL3_ttf!")
      (define static-texture #f)

      ;; Event buffer
      (define event (malloc SDL_EVENT_SIZE 'atomic-interior))
      (define running? #t)

      ;; FPS tracking
      (define frame-count 0)
      (define last-time (current-inexact-milliseconds))
      (define fps-text "FPS: --")

      ;; Main loop
      (let loop ()
        (when running?
          ;; Poll all pending events
          (let event-loop ()
            (when (SDL-PollEvent event)
              (define type (sdl-event-type event))
              (cond
                [(= type SDL_EVENT_QUIT)
                 (set! running? #f)]
                [(= type SDL_EVENT_WINDOW_CLOSE_REQUESTED)
                 (set! running? #f)]
                [(= type SDL_EVENT_KEY_DOWN)
                 (when (handle-key-down event)
                   (set! running? #f))]
                [(= type SDL_EVENT_TEXT_INPUT)
                 (handle-text-input event)]
                [else (void)])
              (event-loop)))

          ;; Render if still running
          (when running?
            ;; Set background to black
            (SDL-SetRenderDrawColor renderer 0 0 0 255)
            (SDL-RenderClear renderer)

            ;; Render static text (create texture on first frame)
            (unless static-texture
              (set! static-texture (render-text-to-texture renderer font static-text white)))
            (render-texture-at renderer static-texture 20.0 20.0)

            ;; Render typed text (recreate each frame when text changes)
            (define typed-texture (render-text-to-texture renderer font typed-text green))
            (when typed-texture
              (render-texture-at renderer typed-texture 20.0 80.0)
              (SDL-DestroyTexture typed-texture))

            ;; Calculate FPS
            (set! frame-count (+ frame-count 1))
            (define current-time (current-inexact-milliseconds))
            (define elapsed (- current-time last-time))

            (when (>= elapsed 500.0)  ; Update FPS every 500ms
              (define fps (/ (* frame-count 1000.0) elapsed))
              (set! fps-text (format "FPS: ~a" (~r fps #:precision 1)))
              (set! frame-count 0)
              (set! last-time current-time))

            ;; Render FPS
            (define fps-texture (render-text-to-texture renderer font fps-text yellow))
            (when fps-texture
              (render-texture-at renderer fps-texture 20.0 (- WINDOW_HEIGHT 60.0))
              (SDL-DestroyTexture fps-texture))

            ;; Present the rendered frame
            (SDL-RenderPresent renderer)

            ;; Small delay (~60fps)
            (SDL-Delay 16)

            (loop))))

      ;; Cleanup textures
      (when static-texture
        (SDL-DestroyTexture static-texture)))

    ;; Cleanup
    (lambda ()
      (when window
        (SDL-StopTextInput window))
      (when font
        (TTF-CloseFont font))
      (when renderer
        (SDL-DestroyRenderer renderer))
      (when window
        (SDL-DestroyWindow window))
      (TTF-Quit)
      (SDL-Quit))))

;; Run the main function
(main)
