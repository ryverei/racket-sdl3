# Implementation Plan: P1 Features

This document outlines the plan for implementing P1 (important) features for the SDL3 Racket bindings. With P0 complete, these features round out the library for most game and application development.

## Goals

Add commonly-needed features for games and applications:
- Keyboard state queries for smooth input handling
- Additional mouse functionality
- Display/monitor information for proper fullscreen and multi-monitor support
- Message boxes for alerts and confirmations
- File dialogs for loading/saving user files

---

## Phase 1: Keyboard State & Scancodes

Query keyboard state for smooth, polling-based input (complements event-based input). Add full scancode support.

### Raw Bindings (`raw.rkt`)

```racket
;; Keyboard state
SDL-GetKeyboardState         ; numkeys-ptr -> uint8-array
SDL-GetModState              ; -> keymod
SDL-ResetKeyboard            ; -> void

;; Scancode/keycode conversion
SDL-GetKeyFromScancode       ; scancode modstate key-event -> keycode
SDL-GetScancodeFromKey       ; keycode modstate -> scancode
SDL-GetScancodeName          ; scancode -> string
SDL-GetScancodeFromName      ; name -> scancode
SDL-GetKeyFromName           ; name -> keycode
```

### Types (`private/types.rkt`)

```racket
;; Scancode enum (physical key positions)
_SDL_Scancode
SDL_SCANCODE_A through SDL_SCANCODE_Z
SDL_SCANCODE_1 through SDL_SCANCODE_0
SDL_SCANCODE_RETURN
SDL_SCANCODE_ESCAPE
SDL_SCANCODE_BACKSPACE
SDL_SCANCODE_TAB
SDL_SCANCODE_SPACE
SDL_SCANCODE_F1 through SDL_SCANCODE_F12
SDL_SCANCODE_RIGHT, SDL_SCANCODE_LEFT, SDL_SCANCODE_DOWN, SDL_SCANCODE_UP
SDL_SCANCODE_LCTRL, SDL_SCANCODE_LSHIFT, SDL_SCANCODE_LALT
SDL_SCANCODE_RCTRL, SDL_SCANCODE_RSHIFT, SDL_SCANCODE_RALT
; ... ~120 most useful ones
```

### Safe Wrappers (`safe/keyboard.rkt`)

```racket
;; Keyboard state queries
(get-keyboard-state)         ; -> procedure (scancode -> bool)
(key-pressed? scancode)      ; -> bool (requires get-keyboard-state first)
(get-mod-state)              ; -> integer (bitmask)
(mod-state-has? mod-flag)    ; -> bool

;; Scancode/keycode utilities
(scancode-name scancode)     ; -> string
(scancode-from-name name)    ; -> scancode
(key-from-name name)         ; -> keycode
```

### Example: `23-keyboard-state.rkt`

Demonstrate keyboard state:
- Smooth character movement with polling
- Show all currently pressed keys
- Modifier state display
- Compare polling vs event-based input

---

## Phase 2: Mouse Enhancements

Additional mouse functionality for warping and global state.

### Raw Bindings (`raw.rkt`)

```racket
;; Mouse warping
SDL-WarpMouseInWindow        ; window x y -> void
SDL-WarpMouseGlobal          ; x y -> bool

;; Global mouse state
SDL-GetGlobalMouseState      ; x-ptr y-ptr -> button-flags

;; Mouse capture
SDL-CaptureMouse             ; enabled -> bool
```

### Safe Wrappers (`safe/mouse.rkt`)

```racket
;; Mouse warping
(warp-mouse! window x y)     ; move mouse to position in window
(warp-mouse-global! x y)     ; move mouse to screen position

;; Global state
(get-global-mouse-state)     ; -> (values buttons x y)

;; Capture
(capture-mouse! enabled?)    ; capture mouse outside window
```

### Example: `24-mouse-warp.rkt`

Demonstrate mouse features:
- Warp mouse to center on key press
- Show global vs window-relative coordinates
- Mouse capture for drag operations

---

## Phase 3: Display Management

Query monitor information for proper fullscreen modes and multi-monitor setups.

### Raw Bindings (`raw.rkt`)

```racket
;; Display enumeration
SDL-GetDisplays              ; count-ptr -> display-id-array
SDL-GetPrimaryDisplay        ; -> display-id
SDL-GetDisplayName           ; display-id -> string

;; Display bounds
SDL-GetDisplayBounds         ; display-id rect-ptr -> bool
SDL-GetDisplayUsableBounds   ; display-id rect-ptr -> bool (excludes taskbar, etc.)

;; Display modes
SDL-GetCurrentDisplayMode    ; display-id -> display-mode-ptr
SDL-GetDesktopDisplayMode    ; display-id -> display-mode-ptr
SDL-GetFullscreenDisplayModes ; display-id count-ptr -> display-mode-array

;; Window-display relationship
SDL-GetDisplayForWindow      ; window -> display-id
SDL-GetDisplayContentScale   ; display-id -> float
SDL-GetWindowDisplayScale    ; window -> float
```

### Types (`private/types.rkt`)

```racket
;; Display ID type
_SDL_DisplayID               ; uint32

;; Display mode struct
_SDL_DisplayMode
  - displayID : SDL_DisplayID
  - format : SDL_PixelFormat
  - w : int
  - h : int
  - pixel_density : float
  - refresh_rate : float
```

### Safe Wrappers (`safe/display.rkt`)

```racket
;; Display enumeration
(get-displays)               ; -> (listof display-id)
(primary-display)            ; -> display-id
(display-name display-id)    ; -> string

;; Display bounds
(display-bounds display-id)  ; -> (values x y w h)
(display-usable-bounds display-id) ; -> (values x y w h)

;; Display modes
(current-display-mode display-id)  ; -> display-mode struct
(desktop-display-mode display-id)  ; -> display-mode struct
(fullscreen-display-modes display-id) ; -> (listof display-mode)

;; Window relationship
(window-display window)      ; -> display-id
(display-content-scale display-id) ; -> float
(window-display-scale window) ; -> float
```

### Example: `25-display-info.rkt`

Show display information:
- List all connected displays
- Show resolution, refresh rate, scale factor
- Demonstrate proper fullscreen mode selection

---

## Phase 4: Message Boxes

Native dialog boxes for alerts, confirmations, and errors.

### Raw Bindings (`raw.rkt`)

```racket
;; Simple message box
SDL-ShowSimpleMessageBox     ; flags title message window -> bool

;; Full message box (with custom buttons)
SDL-ShowMessageBox           ; messageboxdata buttonid-ptr -> bool
```

### Types (`private/types.rkt`)

```racket
;; Message box flags
_SDL_MessageBoxFlags
SDL_MESSAGEBOX_ERROR         ; 0x00000010
SDL_MESSAGEBOX_WARNING       ; 0x00000020
SDL_MESSAGEBOX_INFORMATION   ; 0x00000040
SDL_MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT  ; 0x00000080
SDL_MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT  ; 0x00000100

;; Message box button data (for custom buttons)
_SDL_MessageBoxButtonData
  - flags : uint32
  - buttonID : int
  - text : string

;; Message box data
_SDL_MessageBoxData
  - flags : uint32
  - window : window-ptr/null
  - title : string
  - message : string
  - numbuttons : int
  - buttons : button-array-ptr
  - colorScheme : color-scheme-ptr/null
```

### Safe Wrappers (`safe/dialog.rkt`)

```racket
;; Simple message boxes
(show-message-box title message
                  #:type ['info 'warning 'error]
                  #:window [window #f])

;; Confirmation dialog (returns 'yes, 'no, or 'cancel)
(show-confirm-dialog title message
                     #:buttons ['yes-no 'yes-no-cancel 'ok-cancel]
                     #:window [window #f])
```

### Example: `26-message-box.rkt`

Demonstrate message boxes:
- Info, warning, error styles
- Confirmation dialogs
- Using with/without parent window

---

## Phase 5: File Dialogs

Native file open/save dialogs for user file selection.

### Raw Bindings (`raw.rkt`)

```racket
;; Async file dialogs (SDL3 uses callbacks)
SDL-ShowOpenFileDialog       ; callback userdata window filters nfilters default allow-many -> void
SDL-ShowSaveFileDialog       ; callback userdata window filters nfilters default -> void
SDL-ShowOpenFolderDialog     ; callback userdata window default allow-many -> void
```

### Types (`private/types.rkt`)

```racket
;; Dialog file filter
_SDL_DialogFileFilter
  - name : string    ; e.g., "Image files"
  - pattern : string ; e.g., "*.png;*.jpg;*.gif"

;; Callback type
_SDL_DialogFileCallback      ; (userdata filelist filter) -> void
```

### Safe Wrappers (`safe/dialog.rkt`)

```racket
;; Synchronous wrappers (block until user responds)
(open-file-dialog #:title [title "Open"]
                  #:filters [filters '()]
                  #:default-path [path #f]
                  #:allow-multiple? [multi #f]
                  #:window [window #f])
; -> path-string or (listof path-string) or #f

(save-file-dialog #:title [title "Save"]
                  #:filters [filters '()]
                  #:default-path [path #f]
                  #:window [window #f])
; -> path-string or #f

(open-folder-dialog #:title [title "Select Folder"]
                    #:default-path [path #f]
                    #:allow-multiple? [multi #f]
                    #:window [window #f])
; -> path-string or (listof path-string) or #f
```

### Example: `27-file-dialog.rkt`

Demonstrate file dialogs:
- Open single file with filters
- Open multiple files
- Save file dialog
- Folder selection

---

## Implementation Order

| Step | Phase | Files | Deliverable |
|------|-------|-------|-------------|
| 1 | Phase 1 | `private/types.rkt`, `raw.rkt`, `safe/keyboard.rkt` | Keyboard state + scancodes |
| 2 | Phase 2 | `raw.rkt`, `safe/mouse.rkt` | Mouse warp/capture |
| 3 | Phase 3 | `private/types.rkt`, `raw.rkt`, `safe/display.rkt` | Display info |
| 4 | Phase 4 | `private/types.rkt`, `raw.rkt`, `safe/dialog.rkt` | Message boxes |
| 5 | Phase 5 | `private/types.rkt`, `raw.rkt`, `safe/dialog.rkt` | File dialogs |

---

## Dependencies Between Phases

```
Phase 1 (Keyboard) ─────► Examples
                              ▲
Phase 2 (Mouse) ──────────────┤
                              │
Phase 3 (Display) ────────────┤
                              │
Phase 4 (Message Box) ────────┤
                              │
Phase 5 (File Dialog) ────────┘
```

All phases are independent and can be implemented in any order.

---

## Estimated Function Count

| Phase | Raw Functions | Safe Wrappers | Types/Constants |
|-------|---------------|---------------|-----------------|
| Phase 1 | 7 | 6 | ~120 (scancodes) |
| Phase 2 | 4 | 4 | 0 |
| Phase 3 | 11 | 10 | ~5 |
| Phase 4 | 2 | 2 | ~10 |
| Phase 5 | 3 | 3 | ~5 |
| **Total** | **27** | **25** | **~140** |

---

## Deferred (P2)

These features are useful but lower priority:

- **Gamepad Input**: Controller support - defer until testable
- **Joystick API**: Lower-level than gamepad, for non-standard controllers
- **OpenGL Context**: For users who want raw OpenGL instead of SDL_Renderer
- **Texture Streaming**: `SDL_LockTexture`/`SDL_UnlockTexture` for dynamic textures
- **Surface Operations**: `SDL_BlitSurface`, pixel manipulation

---

## Testing Strategy

After each phase:
1. Clear compiled cache: `rm -rf compiled private/compiled safe/compiled`
2. Compile: `raco make safe.rkt`
3. Run the phase's example program
4. Verify existing examples still work
