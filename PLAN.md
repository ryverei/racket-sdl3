# Implementation Plan: Texture & Rendering Improvements

This document outlines the next set of features to add to the SDL3 Racket bindings.

## Goals

Enhance texture rendering and add blend modes to enable sprite-based games with rotation, scaling, transparency, and color effects.

---

## Phase 1: Blend Modes

Add blend mode support for transparency and compositing effects.

### Types (`private/types.rkt`)

```racket
_SDL_BlendMode  ; uint32

;; Constants
SDL_BLENDMODE_NONE               ; no blending
SDL_BLENDMODE_BLEND              ; alpha blending
SDL_BLENDMODE_BLEND_PREMULTIPLIED
SDL_BLENDMODE_ADD                ; additive blending
SDL_BLENDMODE_ADD_PREMULTIPLIED
SDL_BLENDMODE_MOD                ; color modulate
SDL_BLENDMODE_MUL                ; color multiply
```

### Raw Bindings (`raw.rkt`)

```racket
SDL-SetRenderDrawBlendMode  ; renderer blend-mode -> bool
SDL-GetRenderDrawBlendMode  ; renderer -> (values bool blend-mode)
SDL-SetTextureBlendMode     ; texture blend-mode -> bool
SDL-GetTextureBlendMode     ; texture -> (values bool blend-mode)
```

### Safe Wrapper (`safe/draw.rkt`)

```racket
(set-blend-mode! renderer mode)  ; mode: 'none, 'blend, 'add, 'mod, 'mul
```

### Example: `08-blend.rkt`

Demonstrate blend modes with overlapping semi-transparent shapes:
- Draw colored rectangles with alpha < 255
- Toggle between blend modes with number keys (1-5)
- Show additive blending for "glow" effects
- Display current blend mode name

---

## Phase 2: Texture Color & Alpha Modulation

Enable tinting and fading of textures.

### Raw Bindings (`raw.rkt`)

```racket
SDL-SetTextureColorMod   ; texture r g b -> bool
SDL-GetTextureColorMod   ; texture -> (values bool r g b)
SDL-SetTextureAlphaMod   ; texture alpha -> bool
SDL-GetTextureAlphaMod   ; texture -> (values bool alpha)
```

### Safe Wrapper (`safe/texture.rkt`)

```racket
(texture-set-color-mod! texture r g b)
(texture-set-alpha-mod! texture alpha)
```

### Example: `09-tint.rkt`

Demonstrate color and alpha modulation:
- Load a sprite/image
- R/G/B keys tint the sprite red/green/blue
- Up/Down arrows adjust alpha (fade in/out)
- Space resets to normal
- Show current tint values on screen

---

## Phase 3: Rotated Texture Rendering

Enable sprite rotation and flipping.

### Types (`private/types.rkt`)

```racket
_SDL_FlipMode  ; enum

SDL_FLIP_NONE
SDL_FLIP_HORIZONTAL
SDL_FLIP_VERTICAL
```

### Raw Bindings (`raw.rkt`)

```racket
SDL-RenderTextureRotated  ; renderer texture srcrect dstrect angle center flip -> bool
```

### Safe Wrapper (`safe/texture.rkt`)

```racket
(render-texture! renderer texture x y
                 #:angle 45.0           ; rotation in degrees
                 #:center (cx . cy)     ; rotation center (default: texture center)
                 #:flip 'horizontal)    ; 'none, 'horizontal, 'vertical, 'both
```

### Example: `10-rotate.rkt`

Demonstrate rotation and flipping:
- Load a sprite (something asymmetric so rotation is visible)
- Left/Right arrows rotate the sprite
- H key flips horizontally, V key flips vertically
- Mouse position sets rotation center
- Continuous rotation option (spacebar toggles)

---

## Phase 4: Window Size & Position

Add window query and manipulation functions.

### Raw Bindings (`raw.rkt`)

```racket
SDL-GetWindowSize      ; window -> (values bool w h)
SDL-SetWindowSize      ; window w h -> bool
SDL-GetWindowPosition  ; window -> (values bool x y)
SDL-SetWindowPosition  ; window x y -> bool
SDL-GetWindowFlags     ; window -> flags
SDL-SetWindowFullscreen ; window fullscreen? -> bool
```

### Safe Wrapper (`safe/window.rkt`)

```racket
(window-size window)           ; -> (values w h)
(window-set-size! window w h)
(window-position window)       ; -> (values x y)
(window-set-position! window x y)
(window-fullscreen? window)
(window-set-fullscreen! window fullscreen?)
```

### Example: `11-window-controls.rkt`

Demonstrate window manipulation:
- Arrow keys move the window
- +/- keys resize the window
- F key toggles fullscreen
- Display current size and position on screen

---

## Implementation Order

| Phase | Files | Example |
|-------|-------|---------|
| 1 | `private/types.rkt`, `raw.rkt`, `safe/draw.rkt` | `08-blend.rkt` |
| 2 | `raw.rkt`, `safe/texture.rkt` | `09-tint.rkt` |
| 3 | `private/types.rkt`, `raw.rkt`, `safe/texture.rkt` | `10-rotate.rkt` |
| 4 | `raw.rkt`, `safe/window.rkt` | `11-window-controls.rkt` |

---

## Notes

- Each phase is independent and testable via its example
- Phases 1-3 build on each other for sprite rendering
- Phase 4 is orthogonal and can be done in any order
