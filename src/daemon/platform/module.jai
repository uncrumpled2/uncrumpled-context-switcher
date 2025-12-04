// Platform Module
//
// Platform-specific functionality for Linux, macOS, and Windows.
// Currently implements Linux specifics.

#if OS == .LINUX {
    #load "linux.jai";
}

// Placeholder for future platform implementations
#if OS == .MACOS {
    // TODO: #load "macos.jai";
}

#if OS == .WINDOWS {
    // TODO: #load "windows.jai";
}
