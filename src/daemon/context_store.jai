// Context State Store
//
// This module provides thread-safe storage for the application context state.
// It includes:
// - Context struct with all fields (project_id, profile, environment, tags, etc.)
// - Thread-safe read/write access via mutex
// - Version tracking (increment on each change)
// - State persistence (save/load from disk)

#import "Basic";
#import "String";
#import "File";
#import "Hash_Table";
#import "Thread";

// Core Context structure
Context :: struct {
    project_id: string;
    profile: string;
    environment: string;
    tags: [..] string;
    workspace_metadata: Table(string, string);
    user_params: Table(string, string);  // Simplified to string values for now
    version: u64;
    last_modified: Apollo_Time;
}

// Context change event data
Context_Change :: struct {
    previous_version: u64;
    new_version: u64;
    changed_fields: [..] string;
    timestamp: Apollo_Time;
}

// Context Store - thread-safe wrapper around Context
Context_Store :: struct {
    ctx_data: Context;  // Note: 'context' is reserved in Jai
    mutex: Mutex;
    initialized: bool;
    persistence_path: string;
    dirty: bool;  // True if unsaved changes exist
}

// Initialize a new context store
init_context_store :: (store: *Context_Store, persistence_path := "") {
    init(*store.mutex);
    store.initialized = true;
    store.persistence_path = persistence_path;
    store.dirty = false;

    // Initialize context with defaults - use copy_string to make them freeable
    store.ctx_data.project_id = copy_string("");
    store.ctx_data.profile = copy_string("default");
    store.ctx_data.environment = copy_string("dev");
    store.ctx_data.version = 0;
    store.ctx_data.last_modified = current_time_consensus();

    // Try to load from persistence if path is set
    if persistence_path.count > 0 {
        load_context_from_disk(store);
    }
}

// Cleanup context store
destroy_context_store :: (store: *Context_Store) {
    if !store.initialized return;

    lock(*store.mutex);
    defer unlock(*store.mutex);

    // Save before cleanup if dirty
    if store.dirty && store.persistence_path.count > 0 {
        save_context_to_disk_locked(store);
    }

    // Clean up dynamic arrays and tables
    array_free(store.ctx_data.tags);
    deinit(*store.ctx_data.workspace_metadata);
    deinit(*store.ctx_data.user_params);

    destroy(*store.mutex);
    store.initialized = false;
}

// Get a copy of the current context (thread-safe)
get_context :: (store: *Context_Store) -> Context {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    // Return a deep copy
    return copy_context(*store.ctx_data);
}

// Get just the version number (thread-safe, lightweight)
get_version :: (store: *Context_Store) -> u64 {
    lock(*store.mutex);
    defer unlock(*store.mutex);
    return store.ctx_data.version;
}

// Set the entire context (thread-safe)
// Returns the new version number and list of changed fields
set_context :: (store: *Context_Store, new_context: *Context) -> u64, Context_Change {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    change: Context_Change;
    change.previous_version = store.ctx_data.version;
    change.timestamp = current_time_consensus();

    // Detect what changed
    if store.ctx_data.project_id != new_context.project_id {
        array_add(*change.changed_fields, "project_id");
    }
    if store.ctx_data.profile != new_context.profile {
        array_add(*change.changed_fields, "profile");
    }
    if store.ctx_data.environment != new_context.environment {
        array_add(*change.changed_fields, "environment");
    }
    if !arrays_equal(store.ctx_data.tags, new_context.tags) {
        array_add(*change.changed_fields, "tags");
    }

    // Replace context (copy the new values)
    previous_version := store.ctx_data.version;
    free_context_data(*store.ctx_data);
    store.ctx_data = copy_context(new_context);

    // Increment version from previous (not from copied context which may have version 0)
    store.ctx_data.version = previous_version + 1;
    store.ctx_data.last_modified = change.timestamp;

    change.new_version = store.ctx_data.version;
    store.dirty = true;

    return store.ctx_data.version, change;
}

// Update specific fields of the context (thread-safe)
// Only updates non-empty fields from the update struct
update_context :: (store: *Context_Store, update: *Context) -> u64, Context_Change {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    change: Context_Change;
    change.previous_version = store.ctx_data.version;
    change.timestamp = current_time_consensus();

    // Update only provided fields
    if update.project_id.count > 0 && update.project_id != store.ctx_data.project_id {
        free(store.ctx_data.project_id);
        store.ctx_data.project_id = copy_string(update.project_id);
        array_add(*change.changed_fields, "project_id");
    }
    if update.profile.count > 0 && update.profile != store.ctx_data.profile {
        free(store.ctx_data.profile);
        store.ctx_data.profile = copy_string(update.profile);
        array_add(*change.changed_fields, "profile");
    }
    if update.environment.count > 0 && update.environment != store.ctx_data.environment {
        free(store.ctx_data.environment);
        store.ctx_data.environment = copy_string(update.environment);
        array_add(*change.changed_fields, "environment");
    }
    if update.tags.count > 0 {
        // Replace tags entirely
        for store.ctx_data.tags free(it);
        array_reset(*store.ctx_data.tags);
        for update.tags {
            array_add(*store.ctx_data.tags, copy_string(it));
        }
        array_add(*change.changed_fields, "tags");
    }

    // Only increment version if something actually changed
    if change.changed_fields.count > 0 {
        store.ctx_data.version += 1;
        store.ctx_data.last_modified = change.timestamp;
        store.dirty = true;
    }

    change.new_version = store.ctx_data.version;
    return store.ctx_data.version, change;
}

// Add a tag (thread-safe)
add_tag :: (store: *Context_Store, tag: string) -> bool, u64 {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    // Check if tag already exists
    for store.ctx_data.tags {
        if it == tag return false, store.ctx_data.version;  // Already exists
    }

    // Add the tag
    array_add(*store.ctx_data.tags, copy_string(tag));
    store.ctx_data.version += 1;
    store.ctx_data.last_modified = current_time_consensus();
    store.dirty = true;

    return true, store.ctx_data.version;
}

// Remove a tag (thread-safe)
remove_tag :: (store: *Context_Store, tag: string) -> bool, u64 {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    // Find and remove the tag
    for store.ctx_data.tags {
        if it == tag {
            free(it);
            remove it;
            store.ctx_data.version += 1;
            store.ctx_data.last_modified = current_time_consensus();
            store.dirty = true;
            return true, store.ctx_data.version;
        }
    }

    return false, store.ctx_data.version;  // Tag not found
}

// Check if a tag exists (thread-safe)
has_tag :: (store: *Context_Store, tag: string) -> bool {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    for store.ctx_data.tags {
        if it == tag return true;
    }
    return false;
}

// Get all tags (thread-safe, returns a copy)
get_tags :: (store: *Context_Store) -> [..] string {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    result: [..] string;
    for store.ctx_data.tags {
        array_add(*result, copy_string(it));
    }
    return result;
}

// Set a user parameter (thread-safe)
set_user_param :: (store: *Context_Store, key: string, value: string) -> u64 {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    // Check if we're actually changing the value
    existing := table_find_pointer(*store.ctx_data.user_params, key);
    if existing != null && <<existing == value {
        return store.ctx_data.version;  // No change
    }

    // Set the parameter
    table_set(*store.ctx_data.user_params, copy_string(key), copy_string(value));
    store.ctx_data.version += 1;
    store.ctx_data.last_modified = current_time_consensus();
    store.dirty = true;

    return store.ctx_data.version;
}

// Get a user parameter (thread-safe)
get_user_param :: (store: *Context_Store, key: string) -> string, bool {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    found, value := table_find(*store.ctx_data.user_params, key);
    if found {
        return copy_string(value), true;
    }
    return "", false;
}

// Remove a user parameter (thread-safe)
remove_user_param :: (store: *Context_Store, key: string) -> bool, u64 {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    removed := table_remove(*store.ctx_data.user_params, key);
    if removed {
        store.ctx_data.version += 1;
        store.ctx_data.last_modified = current_time_consensus();
        store.dirty = true;
    }

    return removed, store.ctx_data.version;
}

// Set workspace metadata (thread-safe)
set_workspace_metadata :: (store: *Context_Store, key: string, value: string) -> u64 {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    table_set(*store.ctx_data.workspace_metadata, copy_string(key), copy_string(value));
    store.ctx_data.version += 1;
    store.ctx_data.last_modified = current_time_consensus();
    store.dirty = true;

    return store.ctx_data.version;
}

// Get workspace metadata (thread-safe)
get_workspace_metadata :: (store: *Context_Store, key: string) -> string, bool {
    lock(*store.mutex);
    defer unlock(*store.mutex);

    found, value := table_find(*store.ctx_data.workspace_metadata, key);
    if found {
        return copy_string(value), true;
    }
    return "", false;
}

// Force save to disk (thread-safe)
save_context :: (store: *Context_Store) -> bool {
    if store.persistence_path.count == 0 return false;

    lock(*store.mutex);
    defer unlock(*store.mutex);

    return save_context_to_disk_locked(store);
}

// Reload from disk (thread-safe)
reload_context :: (store: *Context_Store) -> bool {
    if store.persistence_path.count == 0 return false;

    lock(*store.mutex);
    defer unlock(*store.mutex);

    return load_context_from_disk_locked(store);
}

//
// Internal helpers (must be called with mutex held)
//

// Deep copy a context
copy_context :: (src: *Context) -> Context {
    dst: Context;
    dst.project_id = copy_string(src.project_id);
    dst.profile = copy_string(src.profile);
    dst.environment = copy_string(src.environment);
    dst.version = src.version;
    dst.last_modified = src.last_modified;

    // Copy tags
    for src.tags {
        array_add(*dst.tags, copy_string(it));
    }

    // Copy workspace metadata
    for src.workspace_metadata {
        table_set(*dst.workspace_metadata, copy_string(it_index), copy_string(it));
    }

    // Copy user params
    for src.user_params {
        table_set(*dst.user_params, copy_string(it_index), copy_string(it));
    }

    return dst;
}

// Free context data (but not the struct itself)
free_context_data :: (ctx: *Context) {
    free(ctx.project_id);
    free(ctx.profile);
    free(ctx.environment);
    for ctx.tags free(it);
    array_free(ctx.tags);
    // TODO: Free table keys/values
    deinit(*ctx.workspace_metadata);
    deinit(*ctx.user_params);
}

// Free a context copy
free_context :: (ctx: *Context) {
    free_context_data(ctx);
}

// Compare two string arrays
arrays_equal :: (a: [] string, b: [] string) -> bool {
    if a.count != b.count return false;
    for i: 0..a.count-1 {
        if a[i] != b[i] return false;
    }
    return true;
}

// Save context to disk (must be called with mutex held)
save_context_to_disk_locked :: (store: *Context_Store) -> bool {
    // Build JSON representation manually for now
    // TODO: Use jason module for proper JSON serialization
    builder: String_Builder;
    init_string_builder(*builder);

    append(*builder, "{\n");
    append(*builder, tprint("  \"version\": %,\n", store.ctx_data.version));
    append(*builder, tprint("  \"project_id\": \"%\",\n", store.ctx_data.project_id));
    append(*builder, tprint("  \"profile\": \"%\",\n", store.ctx_data.profile));
    append(*builder, tprint("  \"environment\": \"%\",\n", store.ctx_data.environment));

    // Tags array
    append(*builder, "  \"tags\": [");
    for store.ctx_data.tags {
        if it_index > 0 append(*builder, ", ");
        append(*builder, tprint("\"%\"", it));
    }
    append(*builder, "],\n");

    // Workspace metadata
    append(*builder, "  \"workspace_metadata\": {");
    first := true;
    for store.ctx_data.workspace_metadata {
        if !first append(*builder, ", ");
        first = false;
        append(*builder, tprint("\"%\": \"%\"", it_index, it));
    }
    append(*builder, "},\n");

    // User params
    append(*builder, "  \"user_params\": {");
    first = true;
    for store.ctx_data.user_params {
        if !first append(*builder, ", ");
        first = false;
        append(*builder, tprint("\"%\": \"%\"", it_index, it));
    }
    append(*builder, "}\n");

    append(*builder, "}\n");

    content := builder_to_string(*builder);
    defer free(content);

    success := write_entire_file(store.persistence_path, content);
    if success {
        store.dirty = false;
    }
    return success;
}

// Load context from disk (must be called with mutex held)
load_context_from_disk_locked :: (store: *Context_Store) -> bool {
    content, success := read_entire_file(store.persistence_path);
    if !success return false;
    defer free(content);

    // TODO: Use jason module for proper JSON parsing
    // For now, just mark as loaded
    store.dirty = false;
    return true;
}

// Load context from disk (public version)
load_context_from_disk :: (store: *Context_Store) -> bool {
    lock(*store.mutex);
    defer unlock(*store.mutex);
    return load_context_from_disk_locked(store);
}
