# SDL3 Racket Examples

A collection of examples demonstrating the sdl3 Racket library, organized from simple to advanced.

## Learning Path

**New to SDL3?** Start with `basics/` and work through in order:

1. **basics/** - Minimal examples to get started
2. **drawing/** - Shapes and rendering techniques
3. **textures/** - Working with images
4. **text/** - Font rendering
5. **input/** - Keyboard and mouse handling
6. **animation/** - Time-based animation
7. **audio/** - Sound playback
8. **video/** - Camera capture and video input
9. **advanced/** - Surfaces, pixel access, collision detection
10. **graphics/** - OpenGL, Vulkan, and GPU API examples
11. **system/** - Tray menus and system integration

## Running Examples

From the repository root:

```bash
PLTCOLLECTS="$PWD:" racket examples/basics/window.rkt
```

## Directory Guide

### basics/

Start here. Each example is ~50 lines and demonstrates one core concept.

| Example | Concepts |
|---------|----------|
| `window.rkt` | Create a window, main loop, handle quit event |
| `drawing.rkt` | Draw rectangles and lines with colors |
| `input.rkt` | WASD movement + mouse clicks |
| `image.rkt` | Load and display an image |

### window/

Window management and system interaction.

| Example | Concepts |
|---------|----------|
| `controls.rkt` | Resize, toggle fullscreen, change title |
| `display-info.rkt` | Query monitor properties |
| `error-handling.rkt` | Gracefully handle missing files |
| `hints.rkt` | SDL hints and configuration |

### drawing/

Rendering primitives and techniques.

| Example | Concepts |
|---------|----------|
| `drawing.rkt` | Shapes, lines, points, hardware-accelerated geometry |
| `blend-modes.rkt` | Alpha blending, additive blending |

### textures/

Image loading and texture manipulation.

| Example | Concepts |
|---------|----------|
| `texture-transforms.rkt` | Tinting, rotation, flipping, pivot points |
| `render-target.rkt` | Render to texture, post-processing |
| `screenshot.rkt` | Save screen contents to file |
| `sprite-animation.rkt` | Sprite sheets, frame timing, animation control |
| `streaming-texture.rkt` | Streaming textures with pixel-level updates |
| `image-io.rkt` | Loading and saving images in various formats |

### text/

TrueType font rendering.

| Example | Concepts |
|---------|----------|
| `text.rkt` | Load fonts, render text, sizing, colors |
| `font-properties.rkt` | Font metrics, styles, text measurement, glyph info |
| `ttf-advanced.rkt` | Advanced TTF rendering techniques |

### input/

User input handling.

| Example | Concepts |
|---------|----------|
| `keyboard.rkt` | Event-driven vs state polling, when to use each |
| `mouse.rkt` | Tracking, buttons, trails, warping, capture |
| `mouse-relative.rkt` | Relative mouse mode for FPS-style controls |
| `mouse-scroll.rkt` | Scroll wheel handling |
| `buttons.rkt` | Clickable UI buttons with hover/press states |
| `custom-cursor.rkt` | Hide system cursor, draw custom cursors |
| `gamepad.rkt` | Gamepad detection, buttons, axes, hot-plug events |
| `gamepad-advanced.rkt` | Advanced gamepad features |
| `clipboard-events.rkt` | Clipboard change notifications |
| `drop-events.rkt` | File and text drop handling |
| `touch-pen-events.rkt` | Touch and pen input events |
| `device-enumeration.rkt` | Listing available input devices |

### animation/

Time-based animation techniques.

| Example | Concepts |
|---------|----------|
| `animation.rkt` | Delta time, frame-rate independence |
| `timer-callbacks.rkt` | SDL timer callbacks |

### audio/

Sound playback.

| Example | Concepts |
|---------|----------|
| `audio.rkt` | Load and play audio files |
| `advanced-audio.rkt` | Advanced audio streaming and control |
| `device-events.rkt` | Audio device hot-plug events |

### video/

Camera capture and video input.

| Example | Concepts |
|---------|----------|
| `camera-preview.rkt` | Enumerate cameras, open device, live preview |

### advanced/

Complex topics for experienced users.

| Example | Concepts |
|---------|----------|
| `collision.rkt` | Rectangle intersection, collision response |
| `viewport.rkt` | Split-screen rendering with viewports |
| `clipping.rkt` | Clip rectangles, masked rendering |
| `scaling.rkt` | Render scale for resolution independence |
| `camera.rkt` | World coordinates, camera follow, parallax, mini-map |
| `wait-events.rkt` | Efficient event-driven rendering (no polling) |
| `surface-basics.rkt` | Surface creation, pixel access, surface-to-texture conversion |
| `surface-advanced.rkt` | Advanced surface manipulation |
| `surface-blit.rkt` | Surface blitting operations |
| `surface-io.rkt` | Loading and saving surfaces |
| `pixel-access.rkt` | Direct pixel manipulation, color mapping |
| `rect-utils.rkt` | Rectangle utility functions |
| `app-metadata.rkt` | Application metadata and properties |

### graphics/

Low-level graphics APIs (OpenGL, Vulkan, SDL GPU).

| Example | Concepts |
|---------|----------|
| `opengl-basic.rkt` | OpenGL context setup, clear color |
| `opengl-triangle.rkt` | Spinning triangle with immediate mode |
| `opengl-cube.rkt` | 3D cube with depth testing |
| `vulkan-info.rkt` | Vulkan surface creation, extension enumeration |
| `gpu-info.rkt` | GPU device info and shader formats |
| `gpu-triangle.rkt` | GPU pipeline setup, rotating triangle |
| `gpu-cube.rkt` | Depth-tested rotating cube |

### dialogs/

System dialogs.

| Example | Concepts |
|---------|----------|
| `message-box.rkt` | Show system message boxes |

### system/

System tray integration.

| Example | Concepts |
|---------|----------|
| `tray-menu.rkt` | Tray icon, menus, callbacks |

## Demos

The `demos/` directory contains more complete applications:

| Demo | Description |
|------|-------------|
| `mini-paint.rkt` | Simple drawing app with file save/load |
| `keyboard-visual.rkt` | Visual keyboard showing pressed keys |
| `mandelbrot.rkt` | Interactive Mandelbrot set explorer |

## Common Patterns

### Basic Window + Event Loop

```racket
#lang racket/base
(require racket/match sdl3)

(with-sdl
  (with-window+renderer "Title" 800 600 (window renderer)
    (let loop ()
      (define quit?
        (for/or ([ev (in-events)])
          (match ev
            [(quit-event) #t]
            [(key-event 'down 'escape _ _ _) #t]
            [_ #f])))

      (unless quit?
        (set-draw-color! renderer 30 30 30)
        (render-clear! renderer)
        ;; ... draw here ...
        (render-present! renderer)
        (loop)))))
```

### Frame-Rate Independent Movement

```racket
(let loop ([last-time (current-ticks)])
  (define now (current-ticks))
  (define dt (/ (- now last-time) 1000.0))

  ;; Move 200 pixels per second regardless of frame rate
  (set! x (+ x (* 200 dt)))
  ...
  (loop now))
```

### Input Handling Approaches

**Event-driven** (for discrete actions like menu selection):
```racket
(for ([ev (in-events)])
  (match ev
    [(key-event 'down 'space _ _ _)
     (fire-bullet!)]
    ...))
```

**State polling** (for smooth continuous movement):
```racket
(define kbd (get-keyboard-state))
(when (kbd 'w) (set! y (- y (* speed dt))))
(when (kbd 's) (set! y (+ y (* speed dt))))
```
