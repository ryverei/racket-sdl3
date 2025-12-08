# Implementation Plan: Better Event Handling & Input

This document outlines the next set of features to add to the SDL3 Racket bindings.

## Goals

Improve event handling with blocking wait functions and enhance input support with mouse wheel events, relative mouse mode, and expanded keyboard constants for modifier keys.

---

## Phase 1: Blocking Event Functions

Add `SDL_WaitEvent` and `SDL_WaitEventTimeout` for CPU-efficient event handling in applications that don't need continuous rendering.

### Raw Bindings (`raw.rkt`)

```racket
SDL-WaitEvent         ; event-ptr -> bool
SDL-WaitEventTimeout  ; event-ptr timeout-ms -> bool
```

### Safe Wrapper (`safe/events.rkt`)

```racket
(wait-event)           ; -> event (blocks indefinitely)
(wait-event-timeout ms) ; -> event or #f (blocks up to ms milliseconds)
```

### Example: `12-wait-events.rkt`

Demonstrate blocking event handling:
- Simple application that only redraws when events occur
- Show CPU usage difference vs polling loop
- Display event type and timestamp on each event
- Use wait-event-timeout with 1000ms to show periodic "idle" updates

---

## Phase 2: Mouse Wheel Events

Add mouse wheel/scroll event support.

### Types (`private/types.rkt`)

```racket
;; Event constant
SDL_EVENT_MOUSE_WHEEL  ; #x403

;; Wheel direction enum
_SDL_MouseWheelDirection
SDL_MOUSEWHEEL_NORMAL   ; 0
SDL_MOUSEWHEEL_FLIPPED  ; 1

;; Event struct
_SDL_MouseWheelEvent
  - type        : uint32
  - reserved    : uint32
  - timestamp   : uint64
  - windowID    : uint32
  - which       : uint32
  - x           : float   ; horizontal scroll amount
  - y           : float   ; vertical scroll amount
  - direction   : int32   ; SDL_MouseWheelDirection
  - mouse_x     : float   ; mouse x position
  - mouse_y     : float   ; mouse y position
```

### Safe Wrapper (`safe/events.rkt`)

```racket
;; New event struct
(struct mouse-wheel-event sdl-event (x y direction mouse-x mouse-y) #:transparent)
;; x, y are scroll amounts (positive = right/away from user)
;; direction is 'normal or 'flipped
;; mouse-x, mouse-y are cursor position
```

### Example: `13-scroll.rkt`

Demonstrate mouse wheel support:
- Display a large virtual canvas (colored grid or pattern)
- Scroll wheel moves viewport up/down
- Shift+scroll or horizontal scroll moves left/right
- Show current scroll position and wheel delta on screen

---

## Phase 3: Keyboard Modifier Constants

Add modifier key constants for detecting Shift, Ctrl, Alt, etc.

### Types (`private/types.rkt`)

```racket
;; Modifier key masks (SDL_Keymod - uint16)
SDL_KMOD_NONE    ; #x0000
SDL_KMOD_LSHIFT  ; #x0001
SDL_KMOD_RSHIFT  ; #x0002
SDL_KMOD_LCTRL   ; #x0040
SDL_KMOD_RCTRL   ; #x0080
SDL_KMOD_LALT    ; #x0100
SDL_KMOD_RALT    ; #x0200
SDL_KMOD_LGUI    ; #x0400  (Command on Mac, Windows key on PC)
SDL_KMOD_RGUI    ; #x0800
SDL_KMOD_NUM     ; #x1000  (Num Lock)
SDL_KMOD_CAPS    ; #x2000  (Caps Lock)
SDL_KMOD_MODE    ; #x4000  (AltGr)
SDL_KMOD_SCROLL  ; #x8000  (Scroll Lock)

;; Combined masks
SDL_KMOD_CTRL    ; (LCTRL | RCTRL)
SDL_KMOD_SHIFT   ; (LSHIFT | RSHIFT)
SDL_KMOD_ALT     ; (LALT | RALT)
SDL_KMOD_GUI     ; (LGUI | RGUI)
```

### Safe Wrapper (`safe/events.rkt`)

```racket
;; Helper predicates for checking modifiers
(mod-shift? mod)  ; -> bool (any shift key)
(mod-ctrl? mod)   ; -> bool (any ctrl key)
(mod-alt? mod)    ; -> bool (any alt key)
(mod-gui? mod)    ; -> bool (any gui/command key)
```

### Example: Update `13-scroll.rkt`

- Use modifier detection to enable Shift+scroll for horizontal scrolling
- Display active modifiers on screen

---

## Phase 4: Common Keycode Constants

Expand the available keycode constants for common keys.

### Types (`private/types.rkt`)

```racket
;; Number keys (top row)
SDLK_0 through SDLK_9  ; ASCII values 48-57

;; Letter keys (add remaining)
SDLK_a through SDLK_z  ; ASCII values 97-122
SDLK_A through SDLK_Z  ; ASCII values 65-90

;; Function keys
SDLK_F1 through SDLK_F12  ; #x4000003A through #x40000045

;; Common control keys
SDLK_RETURN      ; #x0D (Enter)
SDLK_BACKSPACE   ; #x08
SDLK_TAB         ; #x09
SDLK_DELETE      ; #x4000004C
SDLK_INSERT      ; #x40000049
SDLK_HOME        ; #x4000004A
SDLK_END         ; #x4000004D
SDLK_PAGEUP      ; #x4000004B
SDLK_PAGEDOWN    ; #x4000004E
```

### Example: `14-keyboard.rkt`

Comprehensive keyboard demo:
- Display a virtual keyboard layout on screen
- Highlight keys as they're pressed
- Show keycode, scancode, and key name for last pressed key
- Show active modifier keys
- Different colors for modifier combinations (Ctrl+key, Shift+key, etc.)

---

## Implementation Order

| Phase | Files | Example |
|-------|-------|---------|
| 1 | `raw.rkt`, `safe/events.rkt` | `12-wait-events.rkt` |
| 2 | `private/types.rkt`, `safe/events.rkt` | `13-scroll.rkt` |
| 3 | `private/types.rkt`, `safe/events.rkt` | update `13-scroll.rkt` |
| 4 | `private/types.rkt` | `14-keyboard.rkt` |

---

## Notes

- Phases 1-2 add new functionality; Phases 3-4 expand existing patterns
- Blocking events (Phase 1) are useful for GUI apps, editors, tools
- Mouse wheel (Phase 2) is essential for scrollable content
- Modifier keys (Phase 3) enable keyboard shortcuts (Ctrl+S, etc.)
- Extended keycodes (Phase 4) support full keyboard interaction
