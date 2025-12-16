# Implementation Plan: Textures, Geometry & Input

This document outlines the next set of features to add to the SDL3 Racket bindings.

## Goals

Enable render-to-texture workflows, add integer geometry types, expand image I/O, and improve mouse control for game-style input.

---

## Phase 1: Render Targets & Texture Creation

Add ability to create blank textures and render to them for off-screen drawing.

### Types (`private/types.rkt`)

```racket
;; Texture access modes
_SDL_TextureAccess
SDL_TEXTUREACCESS_STATIC     ; 0 - changes rarely, not lockable
SDL_TEXTUREACCESS_STREAMING  ; 1 - changes frequently, lockable
SDL_TEXTUREACCESS_TARGET     ; 2 - can be used as render target

;; Scale modes for texture filtering
_SDL_ScaleMode
SDL_SCALEMODE_NEAREST  ; 0 - nearest pixel sampling (pixelated)
SDL_SCALEMODE_LINEAR   ; 1 - linear filtering (smooth)
```

### Raw Bindings (`raw.rkt`)

```racket
SDL-CreateTexture          ; renderer format access w h -> texture
SDL-SetRenderTarget        ; renderer texture -> bool
SDL-GetRenderTarget        ; renderer -> texture or #f
SDL-SetTextureScaleMode    ; texture scalemode -> bool
SDL-GetTextureScaleMode    ; texture -> (values bool scalemode)
```

### Safe Wrapper (`safe/texture.rkt`)

```racket
(create-texture renderer width height
                #:access 'target    ; 'static, 'streaming, or 'target
                #:scale 'nearest)   ; 'nearest or 'linear
(with-render-target renderer texture body ...)  ; render to texture, restore after
```

### Example: `15-render-target.rkt`

- Create an off-screen texture
- Draw a pattern to the texture once
- Render the texture multiple times with different positions/scales
- Show FPS benefit of caching complex drawing

---

## Phase 2: Integer Rectangles & Points

Add integer-based geometry types for pixel-perfect positioning.

### Types (`private/types.rkt`)

```racket
;; Integer point
_SDL_Point
  - x : int
  - y : int

;; Integer rectangle
_SDL_Rect
  - x : int
  - y : int
  - w : int
  - h : int
```

### Optional: Rectangle Utilities

```racket
SDL-HasRectIntersection    ; rect-a rect-b -> bool
SDL-GetRectIntersection    ; rect-a rect-b result -> bool
```

### Example: Update existing examples

- Use integer rects for tile-based positioning where appropriate

---

## Phase 3: Image I/O

Complete image loading and add saving capabilities.

### Raw Bindings (`image.rkt`)

```racket
IMG-Load      ; filename -> surface (load to surface, not texture)
IMG-SavePNG   ; surface filename -> bool
IMG-SaveJPG   ; surface filename quality -> bool
```

### Safe Wrapper (`safe/texture.rkt`)

```racket
(load-surface filename)           ; -> surface
(save-surface-png surface path)   ; -> bool
(save-surface-jpg surface path quality)  ; quality 0-100
```

### Example: `16-screenshot.rkt`

- Render a scene
- Press S to save screenshot as PNG
- Show confirmation message

---

## Phase 4: Relative Mouse & Cursor Control

Enable first-person style mouse input and cursor customization.

### Raw Bindings (`raw.rkt`)

```racket
SDL-GetRelativeMouseState      ; -> (values buttons dx dy)
SDL-SetWindowRelativeMouseMode ; window bool -> bool
SDL-GetWindowRelativeMouseMode ; window -> bool
SDL-ShowCursor                 ; -> bool
SDL-HideCursor                 ; -> bool
SDL-CursorVisible              ; -> bool
SDL-CreateSystemCursor         ; cursor-id -> cursor
SDL-SetCursor                  ; cursor -> bool
SDL-DestroyCursor              ; cursor -> void
```

### Types (`private/types.rkt`)

```racket
;; System cursor types
_SDL_SystemCursor
SDL_SYSTEM_CURSOR_DEFAULT
SDL_SYSTEM_CURSOR_TEXT
SDL_SYSTEM_CURSOR_WAIT
SDL_SYSTEM_CURSOR_CROSSHAIR
SDL_SYSTEM_CURSOR_POINTER
SDL_SYSTEM_CURSOR_MOVE
; ... etc
```

### Safe Wrapper (`safe/mouse.rkt`)

```racket
(get-relative-mouse-state)        ; -> (values buttons dx dy)
(set-relative-mouse-mode! window on?)
(relative-mouse-mode? window)
(show-cursor!)
(hide-cursor!)
(cursor-visible?)
(with-system-cursor cursor-type body ...)
```

### Example: `17-mouselook.rkt`

- Simple 3D-style camera controlled by mouse
- Click to capture mouse (relative mode)
- Escape to release
- Show dx/dy values and accumulated rotation

---

## Phase 5: Clipboard

Add system clipboard support for text.

### Raw Bindings (`raw.rkt`)

```racket
SDL-SetClipboardText   ; text -> bool
SDL-GetClipboardText   ; -> string
SDL-HasClipboardText   ; -> bool
```

### Safe Wrapper

```racket
(clipboard-text)          ; -> string or #f
(set-clipboard-text! str) ; -> bool
(clipboard-has-text?)     ; -> bool
```

### Example: Update `14-keyboard.rkt` or text input example

- Ctrl+C to copy displayed text
- Ctrl+V to paste from clipboard

---

## Phase 6: High-Precision Timer

Add performance counters for accurate timing.

### Raw Bindings (`raw.rkt`)

```racket
SDL-GetPerformanceCounter    ; -> uint64
SDL-GetPerformanceFrequency  ; -> uint64
SDL-DelayPrecise             ; nanoseconds -> void
```

### Safe Wrapper

```racket
(current-time-ns)  ; -> nanoseconds as exact integer
(with-timing body ...)  ; -> (values result elapsed-ns)
```

---

## Phase 7: Audio Foundation

Basic audio playback (larger undertaking).

### Core Functions

```racket
SDL-OpenAudioDevice
SDL-CloseAudioDevice
SDL-LoadWAV
SDL-CreateAudioStream
SDL-PutAudioStreamData
SDL-BindAudioStream
SDL-DestroyAudioStream
```

### Safe Wrapper

```racket
(with-audio-device body ...)
(load-wav path)
(play-sound wav)
```

---

## Implementation Order

| Phase | Priority | Files | Deliverable |
|-------|----------|-------|-------------|
| 1 | High | `types.rkt`, `raw.rkt`, `safe/texture.rkt` | Render targets |
| 2 | High | `types.rkt` | Integer geometry |
| 3 | Medium | `image.rkt`, `safe/texture.rkt` | Screenshot save |
| 4 | Medium | `raw.rkt`, `types.rkt`, `safe/mouse.rkt` | FPS mouse |
| 5 | Low | `raw.rkt` | Copy/paste |
| 6 | Low | `raw.rkt` | Precise timing |
| 7 | Low | New `audio.rkt`, `safe/audio.rkt` | Sound |

---

## Notes

- Phases 1-2 unlock new rendering patterns (caching, tiles)
- Phase 3 enables user content export
- Phase 4 unlocks FPS-style games
- Phases 5-6 are small quality-of-life additions
- Phase 7 is substantial but important for games
