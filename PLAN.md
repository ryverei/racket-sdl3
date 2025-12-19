# Examples Cleanup Plan

## Overview

Reorganize and consolidate the examples directory to reduce redundancy, fill coverage gaps, and improve the learning progression.

## Phase 1: Merges ✓ DONE

### 1.1 Merge keyboard-events.rkt + keyboard-state.rkt → keyboard.rkt
- Combine into single example showing both approaches
- Section 1: Event-driven input (for menus, typing, one-shot actions)
- Section 2: State polling (for smooth continuous movement)
- Show when to use each approach
- Delete: `keyboard-events.rkt`, `keyboard-state.rkt`

### 1.2 Merge tint.rkt + rotate.rkt → texture-transforms.rkt
- Combine color modulation and geometric transforms
- Demo: tinting, alpha fade, rotation, flipping, custom pivot
- Delete: `tint.rkt`, `rotate.rkt`

### 1.3 Merge mouse-events.rkt + mouse-warp.rkt → mouse.rkt
- Combine basic tracking with warping
- Section 1: Following cursor, button states, trail effect
- Section 2: Warping, capturing, drawing lines
- Delete: `mouse-events.rkt`, `mouse-warp.rkt`

### 1.4 Merge shapes.rkt + geometry.rkt → drawing.rkt
- Combine basic primitives with advanced geometry
- Section 1: Built-in primitives (rects, lines, points)
- Section 2: Hardware-accelerated geometry with vertex colors
- Delete: `shapes.rkt`, `geometry.rkt`

**Outcome:** Completed successfully. Created 4 merged example files combining related functionality:
- `examples/input/keyboard.rkt` - combines event-driven and state polling approaches
- `examples/textures/texture-transforms.rkt` - combines color modulation with rotation/flipping
- `examples/input/mouse.rkt` - combines tracking, trail, warp, and capture features
- `examples/drawing/drawing.rkt` - combines primitives with hardware-accelerated geometry

Deleted 8 old files. Also fixed a pre-existing bug in `safe/window.rkt` where `(all-from-out "../raw.rkt")` caused duplicate identifier exports when combined with `safe/events.rkt`.

## Phase 2: Removals ✓ DONE

### 2.1 Remove image.rkt ✓
- Functionality covered by texture-transforms.rkt and other texture examples
- Basic image loading is shown in multiple places

## Phase 3: Additions ✓ DONE

### 3.1 Add sprite-animation.rkt (textures/) ✓
- Programmatically generated sprite sheet (no external asset needed)
- Animate through frames based on time
- Variable animation speed control
- Frame timing independent of FPS
- Controls: Left/Right move, Up/Down speed, Space pause, R reverse

### 3.2 Add camera.rkt (advanced/) ✓
- World 3x larger than window (2400x1800)
- Smooth camera follow with lerp
- World coordinates vs screen coordinates
- Parallax background layers (toggleable)
- Mini-map showing viewport position
- Controls: WASD/Arrows, Space toggle smooth, P toggle parallax

### 3.3 Add error-handling.rkt (window/) ✓
- Graceful handling of missing image files
- Graceful handling of missing font files
- Interactive demo with keyboard triggers
- Shows caught exception messages
- Also fixed `raw/ttf.rkt` to properly return null on font load failure

### 3.4 Add buttons.rkt (input/) ✓
- Clickable rectangular buttons with 3D effect
- Hover, pressed, and disabled states
- Click detection with proper press/release handling
- Counter demo with increment, decrement, reset, double, random buttons

### 3.5 Add custom-cursor.rkt (input/) ✓
- Hide system cursor and draw custom cursor at mouse position
- 5 cursor styles: crosshair, circle, arrow, target, hand
- Click effect animation
- Toggle system cursor visibility for comparison
- Cycle through system cursor types

## Phase 4: Structural Reorganization

### 4.1 Create basics/ directory
Move or create simple introductory examples:
- `basics/window.rkt` (rename from window/basic.rkt)
- `basics/drawing.rkt` (simple shapes only, simpler than drawing/drawing.rkt)
- `basics/input.rkt` (minimal keyboard + mouse)
- `basics/image.rkt` (load and display one image)

### 4.2 Simplify complex examples

**display-info.rkt**: Trim to essential display querying, remove excessive UI chrome

**keyboard-visual.rkt**: Consider moving to demos/ or simplifying the keyboard layout code

**viewport-clip.rkt**: Split into three separate examples:
- `viewport.rkt` - split-screen viewports
- `clipping.rkt` - clipping rectangles
- `scaling.rkt` - render scaling

### 4.3 Rebalance directories
After all changes, target structure:

```
examples/
├── basics/           # Start here (4 examples)
│   ├── window.rkt
│   ├── drawing.rkt
│   ├── input.rkt
│   └── image.rkt
│
├── window/           # Window management (2 examples)
│   ├── controls.rkt
│   └── display-info.rkt
│
├── drawing/          # Drawing & rendering (2 examples)
│   ├── drawing.rkt       # merged shapes + geometry
│   └── blend-modes.rkt
│
├── textures/         # Texture operations (4 examples)
│   ├── texture-transforms.rkt  # merged tint + rotate
│   ├── render-target.rkt
│   ├── screenshot.rkt
│   └── sprite-animation.rkt    # NEW
│
├── text/             # Text rendering (1 example)
│   └── text.rkt
│
├── input/            # Input handling (6 examples)
│   ├── keyboard.rkt      # merged events + state
│   ├── keyboard-visual.rkt
│   ├── mouse.rkt         # merged events + warp
│   ├── mouse-relative.rkt
│   ├── mouse-scroll.rkt
│   ├── buttons.rkt       # NEW
│   └── custom-cursor.rkt # NEW
│
├── animation/        # Animation (1 example)
│   └── animation.rkt
│
├── audio/            # Audio (1 example)
│   └── audio.rkt
│
├── advanced/         # Advanced topics (5 examples)
│   ├── collision.rkt
│   ├── viewport.rkt      # split from viewport-clip
│   ├── clipping.rkt      # split from viewport-clip
│   ├── scaling.rkt       # split from viewport-clip
│   ├── camera.rkt        # NEW
│   └── wait-events.rkt
│
├── dialogs/          # System dialogs (1 example)
│   └── message-box.rkt
│
└── assets/           # Shared assets
    ├── (existing images)
    └── spritesheet.png   # NEW (for sprite-animation)
```

## Phase 5: Documentation

### 5.1 Add examples/README.md
- Learning path: basics → specific topics → advanced
- Brief description of each example
- Which concepts each example demonstrates

## Execution Order

1. Phase 1 (Merges) - reduces file count, no new features needed
2. Phase 2 (Removals) - quick cleanup
3. Phase 4.2 (Split viewport-clip.rkt) - reduces complexity
4. Phase 4.1 (Create basics/) - improves onboarding
5. Phase 3 (Additions) - new examples
6. Phase 5 (Documentation) - final polish

## Notes

- Each merge should preserve all demonstrated functionality
- Test each example after changes: `PLTCOLLECTS="$PWD:" racket examples/path/to/example.rkt`
- Keep individual examples under ~200 lines where possible
- New examples need assets added to examples/assets/
