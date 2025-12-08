// Test utility functions for the Uncrumpled Context Switcher test suite
//
// Provides common testing utilities including:
// - Temporary file/directory management
// - Mock data generation
// - Timing utilities
// - Test isolation helpers

#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";
#import "Random";

#if OS == .WINDOWS {
    kernel32_test :: #system_library "kernel32";
    GetEnvironmentVariableA_Test :: (lpName: *u8, lpBuffer: *u8, nSize: u32) -> u32 #foreign kernel32_test "GetEnvironmentVariableA";
    GetTempPathA :: (nBufferLength: u32, lpBuffer: *u8) -> u32 #foreign kernel32_test;
}

// Temporary test directory management
Temp_Test_Dir :: struct {
    path: string;
    created: bool;
}

// Get platform-appropriate temp directory for tests
get_test_temp_dir :: () -> string {
    #if OS == .WINDOWS {
        // Use Windows GetTempPath API
        buffer: [512] u8;
        len := GetTempPathA(512, buffer.data);
        if len > 0 && len < 512 {
            // Remove trailing backslash if present
            result_len := cast(s64) len;
            if result_len > 0 && buffer[result_len - 1] == #char "\\" {
                result_len -= 1;
            }
            result: string;
            result.data = buffer.data;
            result.count = result_len;
            return copy_string(result);
        }
        return copy_string("C:\\Windows\\Temp");
    } else {
        return "/tmp";
    }
}

// Create a temporary test directory with a unique name
create_temp_test_dir :: (prefix := "test_") -> Temp_Test_Dir {
    result: Temp_Test_Dir;

    // Use timestamp and random number for uniqueness
    timestamp := cast(s64)(seconds_since_init() * 1000000);
    rand := random_get() % 10000;
    temp_base := get_test_temp_dir();
    #if OS == .WINDOWS {
        dir_name := tprint("%\\%_%_%", temp_base, prefix, timestamp, rand);
    } else {
        dir_name := tprint("%/%_%_%", temp_base, prefix, timestamp, rand);
    }

    success := make_directory_if_it_does_not_exist(dir_name);
    if success {
        result.path = copy_string(dir_name);
        result.created = true;
    } else {
        result.path = "";
        result.created = false;
    }

    return result;
}

// Clean up a temporary test directory
cleanup_temp_test_dir :: (dir: *Temp_Test_Dir) {
    if dir == null return;
    if !dir.created return;
    if dir.path.count == 0 return;

    // Delete all files in directory first
    visitor :: (info: *File_Visit_Info, user_data: *void) {
        if info.is_directory return;
        file_delete(info.full_name);
    }

    visit_files(dir.path, recursive = true, null, visitor, visit_directories = false);

    // Now try to remove directory (may fail if not empty, which is ok for tests)
    delete_directory(dir.path);

    free(dir.path);
    dir.path = "";
    dir.created = false;
}

// Create a temporary file with given content
create_temp_file :: (content: string, extension := ".txt", dir := "") -> string, bool {
    actual_dir := ifx dir.count > 0 then dir else get_test_temp_dir();
    timestamp := cast(s64)(seconds_since_init() * 1000000);
    rand := random_get() % 10000;
    #if OS == .WINDOWS {
        file_path := tprint("%\\test_%_%_%", actual_dir, timestamp, rand, extension);
    } else {
        file_path := tprint("%/test_%_%_%", actual_dir, timestamp, rand, extension);
    }

    success := write_entire_file(file_path, content);
    if success {
        return copy_string(file_path), true;
    }
    return "", false;
}

// Delete a temporary file
delete_temp_file :: (path: string) -> bool {
    if path.count == 0 return false;
    return file_delete(path);
}

// Test timing utilities
Test_Timer :: struct {
    start_time: Apollo_Time;
    end_time: Apollo_Time;
    running: bool;
}

start_timer :: (timer: *Test_Timer) {
    timer.start_time = current_time_consensus();
    timer.running = true;
}

stop_timer :: (timer: *Test_Timer) {
    timer.end_time = current_time_consensus();
    timer.running = false;
}

// Get elapsed time in milliseconds
get_elapsed_ms :: (timer: *Test_Timer) -> float64 {
    end := ifx timer.running then current_time_consensus() else timer.end_time;
    diff := end - timer.start_time;
    return to_float64_seconds(diff) * 1000.0;
}

// Get elapsed time in seconds
get_elapsed_seconds :: (timer: *Test_Timer) -> float64 {
    end := ifx timer.running then current_time_consensus() else timer.end_time;
    diff := end - timer.start_time;
    return to_float64_seconds(diff);
}

// String utilities for tests
generate_random_string :: (length: int, charset := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> string {
    if length <= 0 return "";

    builder: String_Builder;
    init_string_builder(*builder);

    for 0..length-1 {
        idx := random_get() % cast(u64) charset.count;
        append(*builder, charset[idx]);
    }

    return builder_to_string(*builder);
}

// Generate a random integer in range [min, max]
random_int_range :: (min: int, max: int) -> int {
    if min >= max return min;
    range := cast(u64)(max - min + 1);
    return min + cast(int)(random_get() % range);
}

// Generate a random float in range [0.0, 1.0)
random_float :: () -> float64 {
    return cast(float64)(random_get() % 1000000) / 1000000.0;
}

// Memory tracking for leak detection in tests
Memory_Snapshot :: struct {
    allocations: int;
    bytes_allocated: int;
}

// Note: These would need to interface with Jai's memory debugger
// For now, provide stubs that can be implemented when needed
take_memory_snapshot :: () -> Memory_Snapshot {
    snapshot: Memory_Snapshot;
    // Would interface with Basic(MEMORY_DEBUGGER = true)
    return snapshot;
}

compare_memory_snapshots :: (before: Memory_Snapshot, after: Memory_Snapshot) -> int, int {
    // Returns: allocation_diff, bytes_diff
    return after.allocations - before.allocations, after.bytes_allocated - before.bytes_allocated;
}

// Socket testing utilities (will be expanded in IPC tests)
Socket_Test_Port :: struct {
    port: u16;
    in_use: bool;
}

// Find an available port for testing (simple implementation)
find_available_test_port :: (start_port: u16 = 49152) -> u16 {
    // In production, would actually check if port is available
    // For now, just return a random port in the dynamic range
    return start_port + cast(u16)(random_get() % 1000);
}

// Wait utilities
sleep_ms :: (ms: int) {
    #if OS == .WINDOWS {
        #import "Windows";
        Sleep(cast(s32) ms);
    } else {
        #import "POSIX";
        spec: timespec;
        spec.tv_sec = ms / 1000;
        spec.tv_nsec = (ms % 1000) * 1_000_000;
        nanosleep(*spec, null);
    }
}

// Retry helper - retries a function until it succeeds or max retries reached
retry_until_success :: (max_retries: int, delay_ms: int, check_func: () -> bool) -> bool {
    for 0..max_retries-1 {
        if check_func() return true;
        if it < max_retries - 1 {
            sleep_ms(delay_ms);
        }
    }
    return false;
}

// Capture print output (useful for testing print statements)
// Note: This is a simplified version - full implementation would redirect stdout
Captured_Output :: struct {
    content: string;
}

// Test data generators
generate_test_json :: (num_fields: int = 5) -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    append(*builder, "{\n");
    for 0..num_fields-1 {
        field_name := tprint("field%", it);
        field_value := generate_random_string(10);
        append(*builder, tprint("  \"%\": \"%\"", field_name, field_value));
        if it < num_fields - 1 {
            append(*builder, ",");
        }
        append(*builder, "\n");
    }
    append(*builder, "}");

    return builder_to_string(*builder);
}

// Generate test context data (matches the Context struct we'll define)
Test_Context_Data :: struct {
    project_id: string;
    profile: string;
    environment: string;
    tags: [..] string;
}

generate_test_context :: () -> Test_Context_Data {
    ctx: Test_Context_Data;

    projects := string.["project-alpha", "project-beta", "project-gamma", "test-project"];
    profiles := string.["default", "work", "personal", "development"];
    environments := string.["dev", "staging", "prod", "local"];
    all_tags := string.["--work", "--personal", "--uni", "--gaming", "--debug"];

    ctx.project_id = projects[random_get() % cast(u64) projects.count];
    ctx.profile = profiles[random_get() % cast(u64) profiles.count];
    ctx.environment = environments[random_get() % cast(u64) environments.count];

    // Add 0-3 random tags
    num_tags := random_get() % 4;
    for 0..cast(int)num_tags-1 {
        tag := all_tags[random_get() % cast(u64) all_tags.count];
        array_add(*ctx.tags, tag);
    }

    return ctx;
}

free_test_context :: (ctx: *Test_Context_Data) {
    array_free(ctx.tags);
}
