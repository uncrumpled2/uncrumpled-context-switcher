# Uncrumpled Switcher (UI Skeleton)

A floating, Spotlight-style command palette built with **Jai**, **SDL2**, and **Skia**.

## Architecture

- **Language**: Jai
- **Windowing**: SDL2 (via standard `SDL` module)
- **Rendering**: Skia (via `Skia` module)
- **Structure**:
  - `src/main.jai`: Application entry, event loop.
  - `src/ui/`: Window creation, Renderer abstraction, UI widgets, Theme.
  - `src/util/`: Fuzzy search logic, shared types.

## Prerequisites

1. **Jai Compiler**: Ensure `jai` is in your path.
2. **SDL2**: Installed on your system.
3. **Skia**: Skia shared library and a Jai module named `Skia`.
   - *Note*: The code assumes a standard binding interface for Skia. You may need to adjust `src/ui/renderer.jai` to match your specific Skia binding API.

## Building

Run the build script:

```bash
jai build.jai
```

The executable will be placed in `bin/uncrumpled`.

## Features Implemented

- **Floating Window**: Borderless, centered.
- **Fuzzy Search**: 'fzf'-like ranking algorithm (in `src/util/fuzzy.jai`).
- **UI Rendering**: Abstraction layer for Skia rendering commands.
- **Theming**: Dark and Light modes (Toggle with `Ctrl+T`).
- **Navigation**: Arrow keys or `Ctrl+N`/`Ctrl+P`.
