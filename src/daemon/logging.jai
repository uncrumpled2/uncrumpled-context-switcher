// Daemon Logging Module
//
// Provides logging functionality for the daemon with:
// - Timestamp formatting
// - Log levels (info, warning, error)
// - Optional file output

#import "Basic";

// Log levels
Log_Level :: enum {
    DEBUG;
    INFO;
    WARN;
    ERROR;
}

// Global log settings
log_settings: struct {
    min_level: Log_Level;
    show_timestamps: bool;
    log_to_file: bool;
    log_file_path: string;
};

// Initialize default log settings
init_logging :: () {
    log_settings.min_level = .INFO;
    log_settings.show_timestamps = true;
    log_settings.log_to_file = false;
}

// Set minimum log level
set_log_level :: (level: Log_Level) {
    log_settings.min_level = level;
}

// Format timestamp as MM:SS.mmm
format_timestamp :: (seconds: float64) -> string {
    mins := cast(int)(seconds / 60);
    secs := seconds - cast(float64)(mins * 60);
    return tprint("%02d:%06.3f", mins, secs);
}

// Log helper functions
log :: (format: string, args: .. Any) {
    log_with_level(.INFO, format, ..args);
}

log_debug :: (format: string, args: .. Any) {
    log_with_level(.DEBUG, format, ..args);
}

log_error :: (format: string, args: .. Any) {
    log_with_level(.ERROR, format, ..args);
}

log_warning :: (format: string, args: .. Any) {
    log_with_level(.WARN, format, ..args);
}

log_with_level :: (level: Log_Level, format: string, args: .. Any) {
    // Check if we should log at this level
    if cast(int)level < cast(int)log_settings.min_level {
        return;
    }

    msg := tprint(format, ..args);

    level_str: string;
    if level == {
        case .DEBUG; level_str = "DEBUG";
        case .INFO;  level_str = "INFO ";
        case .WARN;  level_str = "WARN ";
        case .ERROR; level_str = "ERROR";
    }

    if log_settings.show_timestamps {
        timestamp := seconds_since_init();
        print("[%] [%] %\n", format_timestamp(timestamp), level_str, msg);
    } else {
        print("[%] %\n", level_str, msg);
    }
}
