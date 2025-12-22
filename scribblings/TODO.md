# Documentation TODO

This file tracks which modules need Scribble documentation.

## Documented

- [x] `initialization.scrbl` - SDL init/quit, with-sdl
- [x] `window.scrbl` - Windows, renderers, with-window, with-renderer
- [x] `drawing.scrbl` - Drawing primitives, colors, blend modes, rendering
- [x] `events.scrbl` - Event polling, event structs, in-events
- [x] `keyboard.scrbl` - Keyboard state, modifiers, text input
- [x] `timer.scrbl` - Timing, delays, performance counter
- [x] `mouse.scrbl` - Mouse state, cursor control
- [x] `texture.scrbl` - Texture loading, rendering, render targets
- [x] `ttf.scrbl` - TrueType font rendering
- [x] `audio.scrbl` - Audio playback and streams

## Not Yet Documented

### Medium Priority

- [ ] `collision.scrbl` - Rectangle collision detection
  - `make-rect`, `make-frect`
  - `rect->values`, `frect->values`
  - `rects-intersect?`, `frects-intersect?`
  - `rect-intersection`, `frect-intersection`
  - `rect-union`, `frect-union`
  - `rect-line-intersection`, `frect-line-intersection`
  - `rect-enclosing-points`, `frect-enclosing-points`

- [ ] `display.scrbl` - Display/monitor information
  - `get-displays`, `primary-display`
  - `display-name`, `display-bounds`, `display-usable-bounds`
  - `display-content-scale`
  - `current-display-mode`, `desktop-display-mode`
  - `fullscreen-display-modes`, `display-mode-resolution`, `display-mode-refresh-rate`

- [ ] `clipboard.scrbl` - Clipboard access
  - `clipboard-text`, `set-clipboard-text!`
  - `clipboard-has-text?`
  - Clipboard event handling

- [ ] `dialog.scrbl` - File dialogs and message boxes
  - `open-file-dialog`, `save-file-dialog`, `open-folder-dialog`
  - `show-message-box`, `show-simple-message-box`

- [ ] `image.scrbl` - Image loading/saving (SDL_image)
  - `load-surface`, `load-texture` (via SDL_image)
  - `save-png!`, `save-jpg!`
  - Supported formats

- [ ] `hints.scrbl` - Configuration hints
  - `get-hint`, `get-hint-boolean`
  - `set-hint!`, `reset-hint!`, `reset-hints!`
  - `set-app-name!`, `set-app-metadata!`
  - Common hint constants

### Lower Priority (specialized)

- [ ] `gamepad.scrbl` - Game controller support
  - `open-gamepad`, `gamepad-destroy!`
  - `gamepad-button`, `gamepad-axis`
  - `gamepad-name`, `gamepad-type`
  - `gamepad-rumble!`, `gamepad-set-led!`
  - Gamepad events

- [ ] `joystick.scrbl` - Raw joystick access
  - `open-joystick`, `joystick-destroy!`
  - Axis, button, hat, ball access
  - Joystick events

- [ ] `camera.scrbl` - Camera/webcam capture
  - `open-camera`, `camera-destroy!`
  - `camera-acquire-frame`, `camera-frame-release!`
  - `camera-frame->texture`
  - Camera enumeration and specs

- [ ] `properties.scrbl` - SDL property bags
  - `make-properties`, `destroy-properties!`
  - `get-property-*`, `set-property-*`

- [ ] `tray.scrbl` - System tray icons
  - `make-tray`, `make-tray-menu`
  - `insert-tray-entry!`, `remove-tray-entry!`
  - Tray entry callbacks

### Advanced/Optional

- [ ] `gl.scrbl` - OpenGL context management
  - `create-gl-context`, `destroy-gl-context!`
  - `gl-make-current!`, `gl-swap-window!`
  - GL attribute getters/setters

- [ ] `vulkan.scrbl` - Vulkan integration
  - `create-vulkan-surface`, `destroy-vulkan-surface!`
  - Vulkan instance extensions

- [ ] `gpu.scrbl` - SDL GPU API (new in SDL3)
  - Device creation, command buffers
  - Render passes, shaders, pipelines
  - Buffer and texture management
  - This is a large API, may need multiple sections

## Notes

- Run `make check-docs` to verify documented functions match exports
- The raw API (`sdl3/raw`) is not documented - users should refer to SDL3 C documentation
- Constants (SDL_*, SDLK_*, etc.) are re-exported but not individually documented
