# AGENTS.md

## Build & Run

```bash
# Racket binary location
/opt/homebrew/bin/racket

# Compile a module
/opt/homebrew/bin/raco make <file.rkt>

# Run examples
/opt/homebrew/bin/racket examples/hello-window.rkt
/opt/homebrew/bin/racket examples/hello-input.rkt

# Clear compiled cache (needed after changing types.rkt or raw.rkt)
rm -rf compiled private/compiled examples/compiled
```

## Project Structure

- `main.rkt` - Package entry point, re-exports raw.rkt
- `raw.rkt` - FFI bindings to SDL3 C functions
- `private/types.rkt` - Type definitions, structs, constants
- `private/lib.rkt` - Library loading (`define-sdl` macro)
- `examples/` - Example programs

## Naming Conventions

- FFI functions use hyphenated names: `SDL-Init`, `SDL-CreateWindow`
- C struct types use underscores: `_SDL_KeyboardEvent`
- Struct accessors use underscores: `SDL_KeyboardEvent-key`
- Constants match SDL3 names: `SDL_EVENT_QUIT`, `SDLK_ESCAPE`

## Adding New Bindings

1. Add types/constants to `private/types.rkt` with `provide`
2. Add function binding to `raw.rkt` using `define-sdl`
3. Clear compiled cache before testing

## SDL3 Notes

- SDL3 uses C99 `bool` (not int like SDL2)
- Event union is 128 bytes (`SDL_EVENT_SIZE`)
- Window flags are 64-bit, init flags are 32-bit
- Coordinates in mouse events are `float`, not `int`
