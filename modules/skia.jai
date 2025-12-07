// =============================================================================
// Skia Bindings - Platform Loader
// =============================================================================
//
// This module automatically loads the correct platform-specific Skia bindings.
//
// Usage:
//   #import "skia";  // or #load "skia.jai"
//
// The bindings are generated per-platform by running:
//   jai generate.jai
//
// This produces:
//   - skia_windows.jai  (on Windows)
//   - skia_linux.jai    (on Linux)
//   - skia_macos.jai    (on macOS)
//
// =============================================================================

#if OS == .WINDOWS {
    #load "skia_windows.jai";
} else #if OS == .LINUX {
    #load "skia_linux.jai";
} else #if OS == .MACOS {
    #load "skia_macos.jai";
} else {
    #run {
        compiler_report("Unsupported platform for Skia bindings!");
    }
}
