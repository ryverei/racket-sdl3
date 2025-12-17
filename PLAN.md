# Implementation Plan: Remaining P0 Features

This document outlines the plan for completing all remaining P0 (essential) features for the SDL3 Racket bindings.

## Goals

Complete the foundational SDL3 bindings needed for basic games and applications by implementing all remaining P0-priority functions for window management, rendering, and drawing.

---

## Phase 1: Window Management Functions

Essential window control functions that most applications need.

### Raw Bindings (`raw.rkt`)

```racket
;; Window creation convenience
SDL-CreateWindowAndRenderer  ; title w h flags win-ptr-ptr ren-ptr-ptr -> bool

;; Window properties
SDL-GetWindowTitle           ; window -> string
SDL-SetWindowIcon            ; window surface -> bool
SDL-GetWindowID              ; window -> uint32
SDL-GetWindowFromID          ; id -> window

;; Window visibility
SDL-ShowWindow               ; window -> bool
SDL-HideWindow               ; window -> bool
SDL-RaiseWindow              ; window -> bool

;; Window state
SDL-MaximizeWindow           ; window -> bool
SDL-MinimizeWindow           ; window -> bool
SDL-RestoreWindow            ; window -> bool

;; Window constraints
SDL-SetWindowMinimumSize     ; window w h -> bool
SDL-SetWindowMaximumSize     ; window w h -> bool
SDL-GetWindowMinimumSize     ; window w-ptr h-ptr -> bool
SDL-GetWindowMaximumSize     ; window w-ptr h-ptr -> bool

;; Window decoration
SDL-SetWindowBordered        ; window bordered -> bool
SDL-SetWindowResizable       ; window resizable -> bool

;; Window effects
SDL-SetWindowOpacity         ; window opacity -> bool
SDL-GetWindowOpacity         ; window -> float
SDL-FlashWindow              ; window operation -> bool

;; Surface rendering (alternative to hardware renderer)
SDL-GetWindowSurface         ; window -> surface
SDL-UpdateWindowSurface      ; window -> bool
```

### Types (`private/types.rkt`)

```racket
;; Flash operation enum
_SDL_FlashOperation
SDL_FLASH_CANCEL             ; 0
SDL_FLASH_BRIEFLY            ; 1
SDL_FLASH_UNTIL_FOCUSED      ; 2
```

### Safe Wrappers (`safe/window.rkt`)

```racket
;; Window control
(show-window! window)
(hide-window! window)
(raise-window! window)
(maximize-window! window)
(minimize-window! window)
(restore-window! window)

;; Window properties
(window-title window)
(set-window-icon! window surface)
(window-id window)
(window-from-id id)

;; Size constraints
(set-window-minimum-size! window w h)
(set-window-maximum-size! window w h)
(window-minimum-size window)  ; -> (values w h)
(window-maximum-size window)  ; -> (values w h)

;; Decoration
(set-window-bordered! window bordered?)
(set-window-resizable! window resizable?)

;; Effects
(window-opacity window)
(set-window-opacity! window opacity)
(flash-window! window [operation])
```

---

## Phase 2: Renderer Query Functions

Functions to query renderer capabilities and state.

### Raw Bindings (`raw.rkt`)

```racket
;; Driver enumeration
SDL-GetNumRenderDrivers      ; -> int
SDL-GetRenderDriver          ; index -> string

;; Renderer queries
SDL-GetRenderer              ; window -> renderer
SDL-GetRenderWindow          ; renderer -> window
SDL-GetRendererName          ; renderer -> string

;; Output size
SDL-GetRenderOutputSize          ; renderer w-ptr h-ptr -> bool
SDL-GetCurrentRenderOutputSize   ; renderer w-ptr h-ptr -> bool

;; Draw color getters
SDL-GetRenderDrawColor       ; renderer r-ptr g-ptr b-ptr a-ptr -> bool
SDL-SetRenderDrawColorFloat  ; renderer r g b a -> bool
SDL-GetRenderDrawColorFloat  ; renderer r-ptr g-ptr b-ptr a-ptr -> bool

;; VSync control
SDL-SetRenderVSync           ; renderer vsync -> bool
SDL-GetRenderVSync           ; renderer vsync-ptr -> bool
```

### Safe Wrappers (`safe/draw.rkt`)

```racket
;; Renderer info
(renderer-name renderer)
(render-output-size renderer)        ; -> (values w h)
(current-render-output-size renderer) ; -> (values w h)

;; Draw color
(draw-color renderer)                ; -> (values r g b a)

;; VSync
(set-render-vsync! renderer vsync)
(render-vsync renderer)
```

---

## Phase 3: Viewport and Clipping

Control what portion of the renderer is visible and where drawing occurs.

### Raw Bindings (`raw.rkt`)

```racket
;; Viewport (visible area)
SDL-SetRenderViewport        ; renderer rect -> bool
SDL-GetRenderViewport        ; renderer rect-ptr -> bool

;; Clip rectangle (drawing constraint)
SDL-SetRenderClipRect        ; renderer rect -> bool
SDL-GetRenderClipRect        ; renderer rect-ptr -> bool
SDL-RenderClipEnabled        ; renderer -> bool

;; Render scale (for resolution independence)
SDL-SetRenderScale           ; renderer scale-x scale-y -> bool
SDL-GetRenderScale           ; renderer scale-x-ptr scale-y-ptr -> bool
```

### Safe Wrappers (`safe/draw.rkt`)

```racket
;; Viewport/clipping
(set-render-viewport! renderer rect)
(render-viewport renderer)
(set-render-clip-rect! renderer rect)
(render-clip-rect renderer)
(render-clip-enabled? renderer)

;; Scale
(set-render-scale! renderer sx sy)
(render-scale renderer)  ; -> (values sx sy)
```

---

## Phase 4: Advanced Texture Rendering

Additional texture rendering modes for special effects and UI.

### Raw Bindings (`raw.rkt`)

```racket
;; Affine transform rendering (arbitrary 2D transforms)
SDL-RenderTextureAffine      ; renderer texture src-rect origin right down -> bool

;; Tiled rendering (for backgrounds, patterns)
SDL-RenderTextureTiled       ; renderer texture src-rect scale dst-rect -> bool

;; 9-grid rendering (for scalable UI elements like buttons, panels)
SDL-RenderTexture9Grid       ; renderer texture src-rect
                             ; left-width right-width top-height bottom-height
                             ; scale dst-rect -> bool
```

### Safe Wrappers (`safe/texture.rkt`)

```racket
;; Advanced texture rendering
(draw-texture-affine! renderer texture src-rect origin right down)
(draw-texture-tiled! renderer texture src-rect scale dst-rect)
(draw-texture-9grid! renderer texture src-rect
                     left-width right-width top-height bottom-height
                     scale dst-rect)
```

---

## Phase 5: Geometry Rendering

Hardware-accelerated arbitrary geometry for particle effects, custom shapes, etc.

### Raw Bindings (`raw.rkt`)

```racket
;; Geometry rendering
SDL-RenderGeometry           ; renderer texture vertices num-verts
                             ; indices num-indices -> bool
SDL-RenderGeometryRaw        ; (lower-level, pointer-based)
```

### Types (`private/types.rkt`)

```racket
;; FColor struct (float colors for vertices)
_SDL_FColor
  - r : float
  - g : float
  - b : float
  - a : float

;; Vertex struct
_SDL_Vertex
  - position : SDL_FPoint
  - color : SDL_FColor
  - tex_coord : SDL_FPoint
```

### Safe Wrappers (`safe/draw.rkt`)

```racket
;; Geometry rendering
(draw-geometry! renderer vertices [texture] [indices])
```

---

## Phase 6: Debug Text Rendering

Built-in debug text for quick prototyping (no TTF needed).

### Raw Bindings (`raw.rkt`)

```racket
SDL-RenderDebugText          ; renderer x y text -> bool
SDL-RenderDebugTextFormat    ; renderer x y fmt ... -> bool (variadic - may skip)
```

Note: `SDL_RenderDebugTextFormat` uses C variadic arguments which are complex in FFI. We may implement only `SDL_RenderDebugText` and handle formatting on the Racket side.

### Safe Wrappers (`safe/draw.rkt`)

```racket
(draw-debug-text! renderer x y text)
```

---

## Phase 7: Example Updates

Update examples to demonstrate new features.

### Update Example: `11-window-controls.rkt`

Enhance to demonstrate new window management features:
- Show/hide window
- Minimize/maximize/restore
- Flash window
- Opacity changes
- Size constraints

### New Example: `21-viewport-clipping.rkt`

Demonstrate viewport and clipping:
- Split-screen effect with viewports
- Clipping for UI regions
- Render scale for resolution independence

### New Example: `22-geometry.rkt`

Demonstrate geometry rendering:
- Colored triangles
- Textured geometry
- Simple particle system

---

## Implementation Order

| Step | Phase | Files | Deliverable |
|------|-------|-------|-------------|
| 1 | Phase 1 | `private/types.rkt`, `raw.rkt`, `safe/window.rkt` | Window management |
| 2 | Phase 2 | `raw.rkt`, `safe/draw.rkt` | Renderer queries |
| 3 | Phase 3 | `raw.rkt`, `safe/draw.rkt` | Viewport and clipping |
| 4 | Phase 4 | `raw.rkt`, `safe/texture.rkt` | Advanced texture rendering |
| 5 | Phase 5 | `private/types.rkt`, `raw.rkt`, `safe/draw.rkt` | Geometry rendering |
| 6 | Phase 6 | `raw.rkt`, `safe/draw.rkt` | Debug text |
| 7 | Phase 7 | `examples/` | Example programs |

---

## Key SDL3 Concepts

### Viewports vs Clip Rects

- **Viewport**: Defines the output rectangle where rendering appears. Changing the viewport affects coordinate mapping.
- **Clip Rect**: Restricts drawing to a rectangle without changing coordinates. Drawing outside the clip rect is discarded.

### Render Scale

Render scale allows resolution-independent rendering. Set scale to 2.0 and all coordinates are doubled, useful for:
- HiDPI displays
- Pixel art games
- Dynamic resolution scaling

### 9-Grid Rendering

The 9-grid (or 9-slice) technique divides a texture into 9 regions:
- 4 corners (fixed size)
- 4 edges (stretch in one direction)
- 1 center (stretches both directions)

This allows UI elements like buttons and panels to scale without distorting corners.

### Geometry Rendering

`SDL_RenderGeometry` draws arbitrary triangles with per-vertex:
- Position (x, y)
- Color (r, g, b, a as floats)
- Texture coordinates (u, v)

Useful for particle systems, custom shapes, and 2D mesh deformation.

---

## Testing Notes

After each phase:
1. Clear compiled cache: `rm -rf compiled private/compiled`
2. Compile: `raco make raw.rkt` (or relevant files)
3. Test in REPL or with example programs
4. Verify no regressions in existing examples

---

## Dependencies Between Phases

```
Phase 1 (Window) ─────► Phase 7 (Examples)
                              ▲
Phase 2 (Renderer) ───────────┤
                              │
Phase 3 (Viewport) ───────────┤
                              │
Phase 4 (Texture) ────────────┤
                              │
Phase 5 (Geometry) ───────────┤
                              │
Phase 6 (Debug) ──────────────┘
```

Phases 1-6 can be implemented in any order. Phase 7 (Examples) depends on all prior phases.

---

## Estimated Function Count

| Phase | Raw Functions | Safe Wrappers | Running Total |
|-------|---------------|---------------|---------------|
| Phase 1 | 22 | 19 | 41 |
| Phase 2 | 11 | 6 | 58 |
| Phase 3 | 7 | 7 | 72 |
| Phase 4 | 3 | 3 | 78 |
| Phase 5 | 2 | 1 | 81 |
| Phase 6 | 1 | 1 | 83 |
| **Total** | **46** | **37** | **83** |

After completing this plan, the P0 coverage will be essentially complete.
