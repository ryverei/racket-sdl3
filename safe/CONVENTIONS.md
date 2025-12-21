# safe/CONVENTIONS.md

## Scope

These conventions apply to all modules under `safe/`.

## Naming Conventions

### Functions
- `make-*` for constructors: `make-window`, `make-rect`, `make-renderer`
- `*-destroy!` for explicit cleanup: `window-destroy!`, `renderer-destroy!`
- `*!` suffix for side-effecting operations: `render-clear!`, `set-draw-color!`
- `*?` suffix for predicates: `window?`, `key-pressed?`, `rects-intersect?`
- `in-*` for sequences: `in-events`
- `call-with-*` for scoped resource management: `call-with-window+renderer`

### Accessors
- `<type>-<field>` for struct accessors: `rect-x`, `rect-w`, `window-size`
- `set-<type>-<field>!` or `<type>-set-<field>!` for setters: `window-set-title!`

### Constants and Flags
- Safe layer should accept symbols, not `SDL_*` constants
- Raw constants remain available for low-level use via `sdl3/raw`

## API Shape (Prefer This -> Not That)

- **Objects over pointers**
  - Good: `(show-message-box #:window win)` where `win` is a `window` struct
  - Bad: `(show-message-box #:window (window-ptr win))`

- **Symbols over SDL_* constants**
  - Good: `(make-window "Title" 800 600 #:flags '(resizable high-pixel-density))`
  - Bad: `(make-window "Title" 800 600 #:flags (bitwise-ior SDL_WINDOW_RESIZABLE SDL_WINDOW_HIGH_PIXEL_DENSITY))`

- **Symbols for keys and buttons**
  - Good: `(key-pressed? 'escape)`, `(key-pressed? 'w)`
  - Bad: `(key-pressed? SDL_SCANCODE_ESCAPE)`
  - Good: `[(key-event 'down 'escape _ _ _) ...]`
  - Bad: `[(key-event 'down (== SDLK_ESCAPE) _ _ _) ...]`

- **Booleans over stringly config**
  - Good: `(set-hint! 'render-vsync #t)`
  - Bad: `(set-hint! "SDL_RENDER_VSYNC" "1")`

- **Multiple values over list unpacking**
  - Good: `(define-values (x y w h) (rect->values r))`
  - Bad: `(define x (list-ref (rect->list r) 0))`

## Data Representations

### Rectangles
- Canonical form: `SDL_Rect` / `SDL_FRect` objects via `make-rect` / `make-frect`
- Safe APIs return rect objects, not lists
- Accept list `(x y w h)` or vector `#(x y w h)` as input for convenience
- Provide `rect->values` for destructuring: `(define-values (x y w h) (rect->values r))`

### Points
- Prefer multiple values: `(define-values (x y) (mouse-position))`
- Avoid returning `(list x y)` or `(cons x y)`
- Accept list/vector/struct inputs where convenient

### Colors
- Canonical input: separate RGBA integers (0-255): `(set-draw-color! ren 255 128 0 255)`
- Accept list/vector `(r g b)` or `(r g b a)` where ergonomic
- Float colors (0.0-1.0) use explicit `-float` suffix in function names

### Keys and Scancodes
- Symbol names for common keys: `'escape`, `'space`, `'return`, `'left`, `'right`, `'a` through `'z`
- Special keys: `'left-shift`, `'right-ctrl`, `'left-alt`, `'f1` through `'f12`
- Scancodes (integers) remain available for performance-critical polling

## Input Helpers

- `key-pressed?` accepts symbols or scancodes: `(key-pressed? 'w)` or `(key-pressed? SDL_SCANCODE_W)`
- `get-keyboard-state` returns a procedure that accepts symbols or scancodes
- Mouse button queries accept symbols: `'left`, `'middle`, `'right`, `'x1`, `'x2`
- Event structs use symbols for type discrimination: `'down`, `'up`, `'left`, `'right`

## Resource Management

- **Custodian-based cleanup**: Resources created with `make-*` are registered with the current custodian
- **Scoped helpers preferred**: `call-with-window+renderer`, `call-with-sdl`
- **Manual destroy available**: `window-destroy!`, `renderer-destroy!` for explicit control
- **Typical code needs no manual cleanup**: Let custodian shutdown handle it

```racket
;; Preferred: scoped helper
(call-with-window+renderer "Title" 800 600
  (lambda (win ren)
    (game-loop win ren)))

;; Also fine: custodian manages cleanup
(define win (make-window "Title" 800 600))
(define ren (make-renderer win))
;; ... use win and ren ...
;; cleanup happens when custodian shuts down

;; Manual cleanup if needed
(renderer-destroy! ren)
(window-destroy! win)
```

## Error Handling

- Safe wrappers raise Racket exceptions on failure
- Use descriptive error messages that include the SDL error string
- Never surface raw error codes in the safe API
- Errors use the function name as the error source: `(error 'make-window "...")`

## Event Handling

- Event structs are transparent for use with `match`
- Type fields use symbols: `'down`, `'up`, `'shown`, `'hidden`, `'close-requested`
- Button fields use symbols: `'left`, `'middle`, `'right`
- Gamepad/joystick axes and buttons use symbols: `'left-x`, `'south`, `'start`
- Keycodes in events are integers (for now) but `key-name` provides human-readable strings
