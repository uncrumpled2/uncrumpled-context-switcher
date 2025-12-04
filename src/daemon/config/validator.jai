// Context Validator
//
// This module validates Context values against User_Config rules.
// It checks:
// - Profile is allowed by configuration
// - Environment is allowed by configuration
// - Tags don't conflict with each other
// - Required parameters are present
// - Parameter values match their defined types
// - Project ID matches allowed patterns

#import "Basic";
#import "String";

// Note: parser.jai is already loaded by module.jai before this file
// Context type is defined in context_store.jai (loaded separately)

// ============================================================================
// Validation Result Types
// ============================================================================

// Single validation error
Validation_Error :: struct {
    field:   string;   // Which field had the error (e.g., "profile", "tags[0]", "params.mode")
    code:    Validation_Error_Code;
    message: string;   // Human-readable error message
}

Validation_Error_Code :: enum {
    INVALID_PROFILE;      // Profile not in allowed list
    INVALID_ENVIRONMENT;  // Environment not in allowed list
    INVALID_PROJECT;      // Project ID doesn't match any allowed pattern
    TAG_CONFLICT;         // Two tags conflict with each other
    UNKNOWN_TAG;          // Tag not defined in config (warning-level)
    MISSING_PARAM;        // Required parameter not provided
    INVALID_PARAM_TYPE;   // Parameter value doesn't match expected type
    INVALID_PARAM_VALUE;  // Parameter value not in allowed enum values
}

// Result of validating a context
Validation_Result :: struct {
    valid:    bool;                    // True if all validations passed
    errors:   [..] Validation_Error;   // List of validation errors
    warnings: [..] Validation_Error;   // Non-fatal issues (e.g., unknown tags)
}

// ============================================================================
// Main Validation Functions
// ============================================================================

// Validate a full context against configuration rules
validate_context :: (ctx: *Context, config: *User_Config) -> Validation_Result {
    result: Validation_Result;
    result.valid = true;

    // Validate profile
    if ctx.profile.count > 0 {
        if !is_profile_allowed(config, ctx.profile) {
            add_error(*result, "profile", .INVALID_PROFILE,
                tprint("Profile '%' is not allowed. Allowed profiles: %",
                    ctx.profile, config.context_rules.allowed_profiles));
        }
    }

    // Validate environment
    if ctx.environment.count > 0 {
        if !is_environment_allowed(config, ctx.environment) {
            add_error(*result, "environment", .INVALID_ENVIRONMENT,
                tprint("Environment '%' is not allowed. Allowed environments: %",
                    ctx.environment, config.context_rules.allowed_environments));
        }
    }

    // Validate project ID against patterns
    if ctx.project_id.count > 0 {
        if !is_project_allowed(config, ctx.project_id) {
            add_error(*result, "project_id", .INVALID_PROJECT,
                tprint("Project ID '%' does not match any allowed pattern", ctx.project_id));
        }
    }

    // Validate tags - check for conflicts
    validate_tags(*result, ctx.tags, config);

    // Validate parameters
    validate_params(*result, *ctx.user_params, config);

    return result;
}

// Validate just the profile field
validate_profile :: (profile: string, config: *User_Config) -> bool, string {
    if profile.count == 0 return true, "";

    if !is_profile_allowed(config, profile) {
        return false, tprint("Profile '%' is not allowed. Allowed profiles: %",
            profile, config.context_rules.allowed_profiles);
    }
    return true, "";
}

// Validate just the environment field
validate_environment :: (env: string, config: *User_Config) -> bool, string {
    if env.count == 0 return true, "";

    if !is_environment_allowed(config, env) {
        return false, tprint("Environment '%' is not allowed. Allowed environments: %",
            env, config.context_rules.allowed_environments);
    }
    return true, "";
}

// Validate a set of tags against conflict rules
validate_tag_set :: (tags: [] string, config: *User_Config) -> Validation_Result {
    result: Validation_Result;
    result.valid = true;

    validate_tags(*result, tags, config);
    return result;
}

// Validate a single parameter value
validate_single_param :: (name: string, value: string, config: *User_Config) -> bool, string {
    valid, msg := validate_param_value(config, name, value);
    return valid, msg;
}

// ============================================================================
// Project Pattern Matching
// ============================================================================

// Check if a project ID matches any allowed pattern
// Supports simple glob-like patterns:
//   * matches any sequence of characters
//   ? matches exactly one character
is_project_allowed :: (config: *User_Config, project_id: string) -> bool {
    if config.context_rules.allowed_projects.count == 0 return true;

    for config.context_rules.allowed_projects {
        if pattern_match(it, project_id) return true;
    }
    return false;
}

// Simple pattern matching supporting * and ?
// Also supports regex-style .* for backwards compatibility
pattern_match :: (pattern: string, text: string) -> bool {
    // Special case: empty pattern matches empty text only
    if pattern.count == 0 return text.count == 0;

    // Handle regex-style .* (match all) - common in config
    if pattern == ".*" return true;

    // Convert to recursive matching for * and ?
    return do_pattern_match(pattern, text, 0, 0);
}

#scope_file

do_pattern_match :: (pattern: string, text: string, pi: s64, ti: s64) -> bool {
    while pi < pattern.count {
        if pattern[pi] == #char "*" {
            // * matches any sequence - try all possibilities
            // First try matching zero characters
            if do_pattern_match(pattern, text, pi + 1, ti) return true;
            // Then try matching one or more characters
            while ti < text.count {
                ti += 1;
                if do_pattern_match(pattern, text, pi + 1, ti) return true;
            }
            return false;
        } else if pattern[pi] == #char "?" {
            // ? matches exactly one character
            if ti >= text.count return false;
            pi += 1;
            ti += 1;
        } else {
            // Literal character
            if ti >= text.count return false;
            if pattern[pi] != text[ti] return false;
            pi += 1;
            ti += 1;
        }
    }

    // Pattern exhausted - text must also be exhausted
    return ti >= text.count;
}

#scope_export

// ============================================================================
// Tag Validation
// ============================================================================

#scope_file

validate_tags :: (result: *Validation_Result, tags: [] string, config: *User_Config) {
    // Check each tag pair for conflicts
    for i: 0..tags.count-1 {
        tag1 := tags[i];

        // Check if tag is defined (add warning if not)
        if get_tag_definition(config, tag1) == null {
            add_warning(result, tprint("tags[%]", i), .UNKNOWN_TAG,
                tprint("Tag '%' is not defined in configuration", tag1));
        }

        // Check for conflicts with other tags
        for j: i+1..tags.count-1 {
            tag2 := tags[j];
            if tags_conflict(config, tag1, tag2) {
                add_error(result, "tags", .TAG_CONFLICT,
                    tprint("Tag '%' conflicts with tag '%'", tag1, tag2));
            }
        }
    }
}

#scope_export

// ============================================================================
// Parameter Validation
// ============================================================================

#scope_file

Hash_Table :: #import "Hash_Table";

validate_params :: (result: *Validation_Result, params: *Hash_Table.Table(string, string), config: *User_Config) {
    // Check for required parameters
    for *config.params.definitions {
        if it.required {
            value_ptr := Hash_Table.table_find_pointer(params, it.name);
            if value_ptr == null {
                add_error(result, tprint("params.%", it.name), .MISSING_PARAM,
                    tprint("Required parameter '%' is missing", it.name));
            }
        }
    }

    // Validate each provided parameter
    for <<params {
        valid, error_msg := validate_param_value(config, it_index, it);
        if !valid {
            def := get_param_definition(config, it_index);
            if def != null {
                if def.param_type == .ENUM {
                    add_error(result, tprint("params.%", it_index), .INVALID_PARAM_VALUE, error_msg);
                } else {
                    add_error(result, tprint("params.%", it_index), .INVALID_PARAM_TYPE, error_msg);
                }
            }
        }
    }
}

#scope_export

// ============================================================================
// Helper Functions
// ============================================================================

#scope_file

add_error :: (result: *Validation_Result, field: string, code: Validation_Error_Code, message: string) {
    error: Validation_Error;
    error.field = copy_string(field);
    error.code = code;
    error.message = copy_string(message);
    array_add(*result.errors, error);
    result.valid = false;
}

add_warning :: (result: *Validation_Result, field: string, code: Validation_Error_Code, message: string) {
    warning: Validation_Error;
    warning.field = copy_string(field);
    warning.code = code;
    warning.message = copy_string(message);
    array_add(*result.warnings, warning);
    // Warnings don't affect validity
}

#scope_export

// ============================================================================
// Error Code Utilities
// ============================================================================

error_code_to_string :: (code: Validation_Error_Code) -> string {
    if code == {
        case .INVALID_PROFILE;     return "INVALID_PROFILE";
        case .INVALID_ENVIRONMENT; return "INVALID_ENVIRONMENT";
        case .INVALID_PROJECT;     return "INVALID_PROJECT";
        case .TAG_CONFLICT;        return "TAG_CONFLICT";
        case .UNKNOWN_TAG;         return "UNKNOWN_TAG";
        case .MISSING_PARAM;       return "MISSING_PARAM";
        case .INVALID_PARAM_TYPE;  return "INVALID_PARAM_TYPE";
        case .INVALID_PARAM_VALUE; return "INVALID_PARAM_VALUE";
    }
    return "UNKNOWN";
}

// ============================================================================
// Validation Result Utilities
// ============================================================================

// Get a summary of validation errors
get_error_summary :: (result: *Validation_Result) -> string {
    if result.valid && result.warnings.count == 0 {
        return "Validation passed";
    }

    builder: String_Builder;
    init_string_builder(*builder);

    if result.errors.count > 0 {
        append(*builder, tprint("% error(s):\n", result.errors.count));
        for result.errors {
            append(*builder, tprint("  - [%] %: %\n", error_code_to_string(it.code), it.field, it.message));
        }
    }

    if result.warnings.count > 0 {
        append(*builder, tprint("% warning(s):\n", result.warnings.count));
        for result.warnings {
            append(*builder, tprint("  - [%] %: %\n", error_code_to_string(it.code), it.field, it.message));
        }
    }

    return builder_to_string(*builder);
}

// Check if result has any errors of a specific code
has_error_code :: (result: *Validation_Result, code: Validation_Error_Code) -> bool {
    for result.errors {
        if it.code == code return true;
    }
    return false;
}

// Check if result has any warnings of a specific code
has_warning_code :: (result: *Validation_Result, code: Validation_Error_Code) -> bool {
    for result.warnings {
        if it.code == code return true;
    }
    return false;
}

// ============================================================================
// Memory Management
// ============================================================================

free_validation_error :: (error: *Validation_Error) {
    if error.field.count > 0 free(error.field);
    if error.message.count > 0 free(error.message);
}

free_validation_result :: (result: *Validation_Result) {
    for *result.errors {
        free_validation_error(it);
    }
    array_free(result.errors);

    for *result.warnings {
        free_validation_error(it);
    }
    array_free(result.warnings);
}
