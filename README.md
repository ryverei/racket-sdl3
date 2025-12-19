# SDL3 Racket Bindings

Racket bindings for SDL3, providing both a safe idiomatic interface and low-level FFI access.

## Installation

```bash
raco pkg install sdl3
```

Requires SDL3, SDL3_image, and SDL3_ttf libraries installed on your system.

## Quick Start

Run an example to verify everything works:

```bash
racket examples/basics/window.rkt
```

## Tutorial

This tutorial is designed to be followed interactively. Start a REPL in the project directory:

```bash
racket
```

### 1. Creating a Window

The most basic SDL3 program creates a window:

```racket
(require sdl3)

;; Initialize SDL
(sdl-init!)

;; Create a window and renderer
(define-values (win ren)
  (make-window+renderer "Hello SDL3" 800 600))
```

You should see a window appear. Let's draw something:

```racket
;; Set the background color (RGB)
(set-draw-color! ren 100 149 237)  ; Cornflower blue

;; Clear the screen with that color
(render-clear! ren)

;; Show the result
(render-present! ren)
```

The window should now be blue. Try different colors!

To clean up when you're done:

```racket
(renderer-destroy! ren)
(window-destroy! win)
```

See: [examples/basics/window.rkt](examples/basics/window.rkt)

### 2. Drawing Shapes

Let's draw some shapes. Start fresh:

```racket
(require sdl3)
(sdl-init!)
(define-values (win ren) (make-window+renderer "Shapes" 800 600))

;; Clear to dark background
(set-draw-color! ren 30 30 40)
(render-clear! ren)

;; Draw a red filled rectangle
(set-draw-color! ren 255 0 0)
(fill-rect! ren 50 50 200 150)

;; Draw a green rectangle outline
(set-draw-color! ren 0 255 0)
(draw-rect! ren 300 50 200 150)

;; Draw a blue line
(set-draw-color! ren 0 0 255)
(draw-line! ren 50 300 750 400)

;; Draw some yellow points
(set-draw-color! ren 255 255 0)
(draw-points! ren '((100 400) (150 420) (200 390) (250 410)))

(render-present! ren)
```

See: [examples/basics/drawing.rkt](examples/basics/drawing.rkt)

### 3. Handling Events

SDL3 programs use an event loop. Here's the pattern:

```racket
(require sdl3 racket/match)
(sdl-init!)
(define-values (win ren) (make-window+renderer "Events" 800 600))

;; Simple event loop
(let loop ()
  ;; Process all pending events
  (for ([ev (in-events)])
    (match ev
      [(quit-event)
       (printf "Quit requested!~n")]
      [(key-event 'down key _ _ _)
       (printf "Key pressed: ~a~n" (key-name key))]
      [(mouse-button-event 'down 'left x y _)
       (printf "Click at ~a, ~a~n" x y)]
      [_ (void)]))  ; Ignore other events

  ;; Render
  (set-draw-color! ren 50 50 50)
  (render-clear! ren)
  (render-present! ren)

  ;; Small delay to avoid busy-waiting
  (delay! 16)

  ;; Continue looping (in a real app, check for quit)
  (loop))
```

Press Escape or close the window to quit. You'll need to restart Racket after this loop.

See: [examples/input/keyboard.rkt](examples/input/keyboard.rkt)

### 4. Loading Images

Load and display images with SDL3_image:

```racket
(require sdl3)
(sdl-init!)
(define-values (win ren) (make-window+renderer "Image" 800 600))

;; Load a texture from file
(define tex (load-texture ren "examples/assets/racket-logo.png"))

;; Get texture dimensions
(define-values (w h) (texture-size tex))
(printf "Texture size: ~a x ~a~n" w h)

;; Draw it centered
(set-draw-color! ren 30 30 30)
(render-clear! ren)
(render-texture! ren tex (/ (- 800 w) 2) (/ (- 600 h) 2))
(render-present! ren)
```

See: [examples/basics/image.rkt](examples/basics/image.rkt)

### 5. Rendering Text

Render text with SDL3_ttf:

```racket
(require sdl3)
(sdl-init!)
(define-values (win ren) (make-window+renderer "Text" 800 600))

;; Open a font (adjust path for your system)
(define font (open-font "/System/Library/Fonts/Helvetica.ttc" 48.0))

;; Render text to a texture (cached, efficient for static text)
(define tex (render-text font "Hello, SDL3!" '(255 255 255 255) #:renderer ren))

;; Or draw directly (simpler but recreates texture each frame)
(set-draw-color! ren 0 0 0)
(render-clear! ren)
(render-texture! ren tex 50 50)
(draw-text! ren font "Dynamic text!" 50 150 '(0 255 0 255))
(render-present! ren)
```

See: [examples/text/text.rkt](examples/text/text.rkt)

### 6. Animation

Use `current-ticks` for time-based animation:

```racket
(require sdl3 racket/math)
(sdl-init!)
(define-values (win ren) (make-window+renderer "Animation" 800 600))

(let loop ([last-ticks (current-ticks)])
  (define now (current-ticks))
  (define dt (/ (- now last-ticks) 1000.0))  ; Delta time in seconds
  (define t (/ now 1000.0))                   ; Total time in seconds

  ;; Calculate position using sine wave
  (define x (+ 400 (* 200 (cos t))))
  (define y (+ 300 (* 100 (sin (* 2 t)))))

  ;; Draw
  (set-draw-color! ren 20 20 30)
  (render-clear! ren)
  (set-draw-color! ren 255 100 100)
  (fill-rect! ren (- x 25) (- y 25) 50 50)
  (render-present! ren)

  (delay! 16)
  (loop now))
```

See: [examples/animation/animation.rkt](examples/animation/animation.rkt)

## Examples

See [examples/README.md](examples/README.md) for a complete guide to all examples, organized by topic with a suggested learning path.

Quick start:
- [examples/basics/](examples/basics/) - Start here: window, drawing, input, images
- [examples/advanced/](examples/advanced/) - Cameras, collision, viewports
- [demos/](demos/) - Complete applications

## API Overview

### Initialization
- `(sdl-init!)` - Initialize SDL
- `(sdl-quit!)` - Shutdown SDL

### Window & Renderer
- `(make-window title width height)` - Create a window
- `(make-renderer window)` - Create a renderer for a window
- `(make-window+renderer title width height)` - Create both at once

### Drawing
- `(set-draw-color! renderer r g b [a])` - Set drawing color
- `(render-clear! renderer)` - Clear the screen
- `(render-present! renderer)` - Display the rendered frame
- `(fill-rect! renderer x y w h)` - Draw filled rectangle
- `(draw-rect! renderer x y w h)` - Draw rectangle outline
- `(draw-line! renderer x1 y1 x2 y2)` - Draw line
- `(draw-point! renderer x y)` - Draw point
- `(draw-points! renderer points)` - Draw multiple points
- `(draw-lines! renderer points)` - Draw connected lines

### Textures
- `(load-texture renderer path)` - Load image as texture
- `(render-texture! renderer texture x y)` - Draw texture
- `(texture-size texture)` - Get texture dimensions

### Text
- `(open-font path size)` - Load a TTF font
- `(draw-text! renderer font text x y color)` - Draw text
- `(render-text font text color #:renderer ren)` - Render text to texture

### Events
- `(in-events)` - Sequence of pending events (use with `for`)
- `(poll-event)` - Get next event or #f
- Event types: `quit-event`, `key-event`, `mouse-button-event`, `mouse-motion-event`, `window-event`

### Input
- `(get-keyboard-state)` - Get current keyboard state
- `(get-mouse-state)` - Get mouse position and buttons
- `(key-name keycode)` - Get human-readable key name

### Timing
- `(current-ticks)` - Milliseconds since SDL init
- `(delay! ms)` - Sleep for milliseconds

### Collision
- `(make-rect x y w h)` - Create a rectangle
- `(rects-intersect? a b)` - Check if rectangles overlap
- `(rect-intersection a b)` - Get intersection rectangle

## Low-Level Access

For direct SDL3 C API access:

```racket
(require sdl3/raw)
```

This provides C-style function names like `SDL-CreateWindow`, `SDL-RenderPresent`, etc.

## License

MIT
