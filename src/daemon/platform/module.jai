// Platform Module
//
// Platform-specific functionality for Linux, macOS, and Windows.
// Each platform provides path helpers, service integration, and directory management.

#if OS == .LINUX {
    #load "linux.jai";
}

#if OS == .MACOS {
    #load "macos.jai";
}

#if OS == .WINDOWS {
    #load "windows.jai";
}
