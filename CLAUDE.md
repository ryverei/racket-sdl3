# CLAUDE.md

This is a Racket binding for SDL3. When working here, you'll typically be doing one of these tasks:

## Common Tasks

### "I want to add a new SDL3 function"

1. **Find the C signature** in `/opt/homebrew/include/SDL3/SDL_*.h`
2. **Add types** if needed to `private/types.rkt` (pointer types, struct types)
3. **Add constants** if needed to `private/constants.rkt` (flags, enum values)
4. **Create the raw binding** in the appropriate `raw/*.rkt` file using `define-sdl`
5. **Create a safe wrapper** in the matching `safe/*.rkt` file
6. **Export from aggregators**: add to `raw.rkt` and `safe.rkt` as needed
7. **Test**: create or update an example in `examples/`

**Pattern to follow**: Look at how similar functions are done. For instance, if adding a new renderer function, look at `raw/render.rkt` and `safe/draw.rkt`.

### "I want to understand how X works"

- **Examples are the best documentation**: Check `examples/` first. They're organized by topic (drawing, input, text, etc.)
- **Safe API usage**: Look at `examples/basics/` for common patterns
- **Low-level access**: Check if there's a `raw/*.rkt` file for that subsystem

### "I want to fix a bug"

1. **Reproduce**: Run the relevant example with `PLTCOLLECTS="$PWD:" /opt/homebrew/bin/racket examples/.../file.rkt`
2. **Find the code**: Safe wrappers are in `safe/`, raw bindings in `raw/`
3. **Check types**: Many bugs are FFI type mismatches - check `private/types.rkt`
4. **Clear cache if stuck**: `make clean` (Racket caches compiled bytecode)

### "I want to add a new subsystem (e.g., gamepad, audio)"

1. Create `raw/subsystem.rkt` with FFI bindings
2. Create `safe/subsystem.rkt` with idiomatic wrappers
3. Add exports to `raw.rkt` and `safe.rkt`
4. Create examples in `examples/subsystem/`
5. Follow patterns from existing subsystems (window, events, texture are good references)

## Running Code

**Critical**: This may be a git worktree. Always use:

```bash
PLTCOLLECTS="$PWD:" /opt/homebrew/bin/racket examples/basics/drawing.rkt
```

Without `PLTCOLLECTS="$PWD:"`, Racket loads the installed package instead of your local changes.

First-time setup: `ln -sf . sdl3` (creates symlink so collection resolves)

## Where Things Live

| Looking for... | Check here |
|----------------|------------|
| How to use a feature | `examples/` |
| Safe/idiomatic API | `safe/*.rkt` |
| Raw C-style FFI | `raw/*.rkt` |
| Type definitions | `private/types.rkt` |
| Constants/flags | `private/constants.rkt` |
| Key codes | `private/enums.rkt` |
| Complete demos | `demos/` |

## File Patterns

**Raw bindings** (`raw/*.rkt`):
```racket
(define-sdl SDL-CreateWindow
  (_fun _string _int _int _SDL_WindowFlags -> _SDL_Window-pointer/null)
  #:c-id SDL_CreateWindow)
```
- Function names: `SDL-FunctionName` (hyphenated)
- Returns nullable pointers, doesn't check errors

**Safe wrappers** (`safe/*.rkt`):
```racket
(define (make-window title w h #:flags [flags '()])
  (define ptr (SDL-CreateWindow title w h (flags->window-flags flags)))
  (unless ptr (error 'make-window "~a" (SDL-GetError)))
  (wrap-window ptr))
```
- Function names: `make-thing`, `thing-property`, `do-action!`
- Checks errors, wraps pointers in structs, registers with custodian

## Key Conventions

**When editing `safe/`**, read `safe/CONVENTIONS.md`. Key points:
- Use symbols not constants: `'escape` not `SDLK_ESCAPE`
- Use `!` suffix for side effects: `render-clear!`
- Accept symbols for flags: `#:flags '(resizable)`
- Return multiple values not lists: `(values x y)` not `(list x y)`

**Naming**:
- Raw: `SDL-FunctionName`, `SDL_CONSTANT_NAME`, `_SDL_Type`
- Safe: `make-thing`, `thing-property`, `thing-action!`, `thing?`

## Debugging Tips

- **"unbound identifier" for something you just added**: Run `make clean`, then retry
- **Crashes with no error**: Usually FFI type mismatch. Check pointer types match SDL3 headers
- **Wrong behavior**: Safe wrapper might not be calling the right raw function. Add debug prints
- **Works in installed package but not here**: You forgot `PLTCOLLECTS="$PWD:"`

## SDL3 Gotchas

- SDL3 uses C99 `bool` (not int like SDL2) - use `_sdl-bool` type
- Event union is 128 bytes
- Window flags are 64-bit, init flags are 32-bit
- Mouse coordinates are floats, not ints
- Many functions return `bool` for success, call `SDL-GetError` on failure

## Reference Headers

```
/opt/homebrew/include/SDL3/           # Core SDL3
/opt/homebrew/include/SDL3_image/     # Image loading
/opt/homebrew/include/SDL3_ttf/       # Font rendering
```

## Backwards Compatibility

None needed. Only consumers are `examples/` and `demos/`. Just make sure those still work.
