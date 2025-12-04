// Unit tests for the Context Validator
//
// Tests validation of Context values against User_Config rules,
// including profile/environment validation, tag conflict detection,
// parameter validation, and project pattern matching.

#import "Basic";
#import "String";
#import "Hash_Table";

// Note: context_store types are loaded by test_context_store.jai
// Config parser types are loaded by test_config_parser.jai (which uses #import,dir)
// The validator depends on both Context and User_Config, so we load it here
// after both are available
#load "../../src/daemon/config/validator.jai";

// Registration function for test framework
register_config_validator_tests :: (register: (name: string, proc: () -> bool, category: string)) {
    // Basic validation tests
    register("validator/validate_empty_context", test_validate_empty_context, "unit");
    register("validator/validate_valid_context", test_validate_valid_context, "unit");

    // Profile validation tests
    register("validator/validate_profile_allowed", test_validate_profile_allowed, "unit");
    register("validator/validate_profile_not_allowed", test_validate_profile_not_allowed, "unit");
    register("validator/validate_profile_function", test_validate_profile_function, "unit");

    // Environment validation tests
    register("validator/validate_environment_allowed", test_validate_environment_allowed, "unit");
    register("validator/validate_environment_not_allowed", test_validate_environment_not_allowed, "unit");
    register("validator/validate_environment_function", test_validate_environment_function, "unit");

    // Project pattern matching tests
    register("validator/pattern_match_literal", test_pattern_match_literal, "unit");
    register("validator/pattern_match_wildcard", test_pattern_match_wildcard, "unit");
    register("validator/pattern_match_question", test_pattern_match_question, "unit");
    register("validator/pattern_match_regex_style", test_pattern_match_regex_style, "unit");
    register("validator/is_project_allowed", test_is_project_allowed, "unit");

    // Tag validation tests
    register("validator/validate_tags_no_conflict", test_validate_tags_no_conflict, "unit");
    register("validator/validate_tags_conflict", test_validate_tags_conflict, "unit");
    register("validator/validate_tags_unknown_warning", test_validate_tags_unknown_warning, "unit");
    register("validator/validate_tag_set", test_validate_tag_set, "unit");

    // Parameter validation tests
    register("validator/validate_params_valid", test_validate_params_valid, "unit");
    register("validator/validate_params_missing_required", test_validate_params_missing_required, "unit");
    register("validator/validate_params_invalid_type", test_validate_params_invalid_type, "unit");
    register("validator/validate_params_invalid_enum", test_validate_params_invalid_enum, "unit");
    register("validator/validate_single_param", test_validate_single_param, "unit");

    // Error code utilities
    register("validator/error_code_to_string", test_error_code_to_string, "unit");
    register("validator/has_error_code", test_has_error_code, "unit");
    register("validator/has_warning_code", test_has_warning_code, "unit");

    // Result utilities
    register("validator/get_error_summary", test_get_error_summary, "unit");

    // Memory management
    register("validator/free_validation_result", test_free_validation_result, "unit");
}

//
// Test State Helper
//
Validator_Test_State :: struct {
    passed: int;
    failed: int;
}

validator_assert :: (state: *Validator_Test_State, condition: bool, message: string) {
    if condition {
        state.passed += 1;
    } else {
        state.failed += 1;
        print("  ASSERTION FAILED: %\n", message);
    }
}

//
// Helper to create test context (uses Context from context_store.jai)
//
create_validator_test_context :: () -> Context {
    ctx: Context;
    ctx.project_id = copy_string("test-project");
    ctx.profile = copy_string("work");
    ctx.environment = copy_string("dev");
    return ctx;
}

free_validator_test_context :: (ctx: *Context) {
    free(ctx.project_id);
    free(ctx.profile);
    free(ctx.environment);
    for ctx.tags free(it);
    array_free(ctx.tags);
    deinit(*ctx.user_params);
    deinit(*ctx.workspace_metadata);
}

//
// Basic Validation Tests
//

test_validate_empty_context :: () -> bool {
    state: Validator_Test_State;

    // Empty context with default config
    ctx: Context;
    defer free_validator_test_context(*ctx);

    cfg := create_default_config();
    defer free_user_config(*cfg);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    // Empty context should be valid (nothing to violate)
    validator_assert(*state, result.valid, "Empty context should be valid");
    validator_assert(*state, result.errors.count == 0, "Should have no errors");

    return state.failed == 0;
}

test_validate_valid_context :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work", "personal"]
allowed_environments = ["dev", "prod"]

[[tags.definitions]]
name = "--work"
description = "Work context"
TOML;

    cfg, success := parse_config_string(toml_doc);
    defer free_user_config(*cfg);
    validator_assert(*state, success, "Config should parse");

    ctx := create_validator_test_context();
    defer free_validator_test_context(*ctx);
    array_add(*ctx.tags, copy_string("--work"));

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, result.valid, "Valid context should pass validation");
    validator_assert(*state, result.errors.count == 0, "Should have no errors");

    return state.failed == 0;
}

//
// Profile Validation Tests
//

test_validate_profile_allowed :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work", "personal"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx := create_validator_test_context();
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, result.valid, "Profile 'work' should be allowed");
    validator_assert(*state, !has_error_code(*result, .INVALID_PROFILE), "Should not have INVALID_PROFILE error");

    return state.failed == 0;
}

test_validate_profile_not_allowed :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work", "personal"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    ctx.profile = copy_string("gaming");
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, !result.valid, "Profile 'gaming' should not be allowed");
    validator_assert(*state, result.errors.count == 1, "Should have 1 error");
    validator_assert(*state, has_error_code(*result, .INVALID_PROFILE), "Should have INVALID_PROFILE error");

    return state.failed == 0;
}

test_validate_profile_function :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work", "personal"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    valid1, _ := validate_profile("work", *cfg);
    validator_assert(*state, valid1, "'work' should be valid");

    valid2, _ := validate_profile("personal", *cfg);
    validator_assert(*state, valid2, "'personal' should be valid");

    valid3, msg := validate_profile("gaming", *cfg);
    validator_assert(*state, !valid3, "'gaming' should be invalid");
    validator_assert(*state, msg.count > 0, "Should have error message");

    // Empty profile should be valid (not validated)
    valid4, _ := validate_profile("", *cfg);
    validator_assert(*state, valid4, "Empty profile should be valid");

    return state.failed == 0;
}

//
// Environment Validation Tests
//

test_validate_environment_allowed :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_environments = ["dev", "prod"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx := create_validator_test_context();
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, result.valid, "Environment 'dev' should be allowed");

    return state.failed == 0;
}

test_validate_environment_not_allowed :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_environments = ["dev", "prod"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    ctx.environment = copy_string("staging");
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, !result.valid, "Environment 'staging' should not be allowed");
    validator_assert(*state, has_error_code(*result, .INVALID_ENVIRONMENT), "Should have INVALID_ENVIRONMENT error");

    return state.failed == 0;
}

test_validate_environment_function :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_environments = ["dev", "prod"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    valid1, _ := validate_environment("dev", *cfg);
    validator_assert(*state, valid1, "'dev' should be valid");

    valid2, _ := validate_environment("prod", *cfg);
    validator_assert(*state, valid2, "'prod' should be valid");

    valid3, msg := validate_environment("staging", *cfg);
    validator_assert(*state, !valid3, "'staging' should be invalid");
    validator_assert(*state, msg.count > 0, "Should have error message");

    return state.failed == 0;
}

//
// Project Pattern Matching Tests
//

test_pattern_match_literal :: () -> bool {
    state: Validator_Test_State;

    validator_assert(*state, pattern_match("hello", "hello"), "'hello' should match 'hello'");
    validator_assert(*state, !pattern_match("hello", "world"), "'hello' should not match 'world'");
    validator_assert(*state, !pattern_match("hello", "hello!"), "'hello' should not match 'hello!'");
    validator_assert(*state, pattern_match("", ""), "Empty pattern should match empty string");
    validator_assert(*state, !pattern_match("", "a"), "Empty pattern should not match non-empty string");

    return state.failed == 0;
}

test_pattern_match_wildcard :: () -> bool {
    state: Validator_Test_State;

    validator_assert(*state, pattern_match("*", "anything"), "'*' should match 'anything'");
    validator_assert(*state, pattern_match("*", ""), "'*' should match empty string");
    validator_assert(*state, pattern_match("hello*", "hello"), "'hello*' should match 'hello'");
    validator_assert(*state, pattern_match("hello*", "helloworld"), "'hello*' should match 'helloworld'");
    validator_assert(*state, pattern_match("*world", "helloworld"), "'*world' should match 'helloworld'");
    validator_assert(*state, pattern_match("*world", "world"), "'*world' should match 'world'");
    validator_assert(*state, pattern_match("hello*world", "helloXworld"), "'hello*world' should match 'helloXworld'");
    validator_assert(*state, pattern_match("a*b*c", "aXbYc"), "'a*b*c' should match 'aXbYc'");
    validator_assert(*state, !pattern_match("hello*", "world"), "'hello*' should not match 'world'");

    return state.failed == 0;
}

test_pattern_match_question :: () -> bool {
    state: Validator_Test_State;

    validator_assert(*state, pattern_match("?", "a"), "'?' should match single char");
    validator_assert(*state, !pattern_match("?", ""), "'?' should not match empty string");
    validator_assert(*state, !pattern_match("?", "ab"), "'?' should not match two chars");
    validator_assert(*state, pattern_match("a?c", "abc"), "'a?c' should match 'abc'");
    validator_assert(*state, pattern_match("???", "abc"), "'???' should match 'abc'");
    validator_assert(*state, !pattern_match("???", "ab"), "'???' should not match 'ab'");

    return state.failed == 0;
}

test_pattern_match_regex_style :: () -> bool {
    state: Validator_Test_State;

    // Support for .* (regex-style match-all)
    validator_assert(*state, pattern_match(".*", "anything"), "'.*' should match anything");
    validator_assert(*state, pattern_match(".*", ""), "'.*' should match empty string");
    validator_assert(*state, pattern_match(".*", "foo-bar-123"), "'.*' should match 'foo-bar-123'");

    return state.failed == 0;
}

test_is_project_allowed :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_projects = ["my-project", "test-*", "prod-???"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    validator_assert(*state, is_project_allowed(*cfg, "my-project"), "'my-project' should be allowed");
    validator_assert(*state, is_project_allowed(*cfg, "test-abc"), "'test-abc' should be allowed");
    validator_assert(*state, is_project_allowed(*cfg, "test-"), "'test-' should be allowed");
    validator_assert(*state, is_project_allowed(*cfg, "prod-123"), "'prod-123' should be allowed");
    validator_assert(*state, !is_project_allowed(*cfg, "prod-12"), "'prod-12' should not be allowed");
    validator_assert(*state, !is_project_allowed(*cfg, "other"), "'other' should not be allowed");

    return state.failed == 0;
}

//
// Tag Validation Tests
//

test_validate_tags_no_conflict :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
conflicts_with = ["--personal"]

[[tags.definitions]]
name = "--focus"
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    array_add(*ctx.tags, copy_string("--work"));
    array_add(*ctx.tags, copy_string("--focus"));
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, result.valid, "Non-conflicting tags should be valid");
    validator_assert(*state, !has_error_code(*result, .TAG_CONFLICT), "Should not have TAG_CONFLICT error");

    return state.failed == 0;
}

test_validate_tags_conflict :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
conflicts_with = ["--personal"]

[[tags.definitions]]
name = "--personal"
conflicts_with = ["--work"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    array_add(*ctx.tags, copy_string("--work"));
    array_add(*ctx.tags, copy_string("--personal"));
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, !result.valid, "Conflicting tags should fail validation");
    validator_assert(*state, has_error_code(*result, .TAG_CONFLICT), "Should have TAG_CONFLICT error");

    return state.failed == 0;
}

test_validate_tags_unknown_warning :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    array_add(*ctx.tags, copy_string("--work"));
    array_add(*ctx.tags, copy_string("--unknown"));  // Not defined
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    // Unknown tags should produce warnings, not errors
    validator_assert(*state, result.valid, "Unknown tags should not cause failure (just warnings)");
    validator_assert(*state, result.warnings.count >= 1, "Should have at least 1 warning");
    validator_assert(*state, has_warning_code(*result, .UNKNOWN_TAG), "Should have UNKNOWN_TAG warning");

    return state.failed == 0;
}

test_validate_tag_set :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
conflicts_with = ["--personal", "--gaming"]

[[tags.definitions]]
name = "--personal"

[[tags.definitions]]
name = "--gaming"
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    // Test valid tag set
    tags_valid: [2] string;
    tags_valid[0] = "--personal";
    tags_valid[1] = "--gaming";

    result1 := validate_tag_set(tags_valid, *cfg);
    defer free_validation_result(*result1);
    validator_assert(*state, result1.valid, "personal and gaming should not conflict");

    // Test conflicting tag set
    tags_conflict: [2] string;
    tags_conflict[0] = "--work";
    tags_conflict[1] = "--personal";

    result2 := validate_tag_set(tags_conflict, *cfg);
    defer free_validation_result(*result2);
    validator_assert(*state, !result2.valid, "work and personal should conflict");

    return state.failed == 0;
}

//
// Parameter Validation Tests
//

test_validate_params_valid :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "verbose"
type = "bool"

[[params.definitions]]
name = "mode"
type = "enum"
values = ["debug", "release"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    table_set(*ctx.user_params, copy_string("verbose"), copy_string("true"));
    table_set(*ctx.user_params, copy_string("mode"), copy_string("debug"));
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, result.valid, "Valid params should pass validation");
    validator_assert(*state, result.errors.count == 0, "Should have no errors");

    return state.failed == 0;
}

test_validate_params_missing_required :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "api_key"
type = "string"
required = true
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;  // No params set
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, !result.valid, "Missing required param should fail");
    validator_assert(*state, has_error_code(*result, .MISSING_PARAM), "Should have MISSING_PARAM error");

    return state.failed == 0;
}

test_validate_params_invalid_type :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "count"
type = "int"
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    table_set(*ctx.user_params, copy_string("count"), copy_string("not-a-number"));
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, !result.valid, "Invalid type should fail");
    validator_assert(*state, has_error_code(*result, .INVALID_PARAM_TYPE), "Should have INVALID_PARAM_TYPE error");

    return state.failed == 0;
}

test_validate_params_invalid_enum :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "mode"
type = "enum"
values = ["debug", "release"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    table_set(*ctx.user_params, copy_string("mode"), copy_string("profile"));  // Not in values
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, !result.valid, "Invalid enum value should fail");
    validator_assert(*state, has_error_code(*result, .INVALID_PARAM_VALUE), "Should have INVALID_PARAM_VALUE error");

    return state.failed == 0;
}

test_validate_single_param :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "verbose"
type = "bool"
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    valid1, _ := validate_single_param("verbose", "true", *cfg);
    validator_assert(*state, valid1, "'true' should be valid for verbose");

    valid2, _ := validate_single_param("verbose", "false", *cfg);
    validator_assert(*state, valid2, "'false' should be valid for verbose");

    valid3, msg := validate_single_param("verbose", "yes", *cfg);
    validator_assert(*state, !valid3, "'yes' should be invalid for verbose");
    validator_assert(*state, msg.count > 0, "Should have error message");

    // Unknown params are allowed
    valid4, _ := validate_single_param("unknown", "anything", *cfg);
    validator_assert(*state, valid4, "Unknown param should be allowed");

    return state.failed == 0;
}

//
// Error Code Utilities
//

test_error_code_to_string :: () -> bool {
    state: Validator_Test_State;

    validator_assert(*state, error_code_to_string(.INVALID_PROFILE) == "INVALID_PROFILE", "INVALID_PROFILE conversion");
    validator_assert(*state, error_code_to_string(.INVALID_ENVIRONMENT) == "INVALID_ENVIRONMENT", "INVALID_ENVIRONMENT conversion");
    validator_assert(*state, error_code_to_string(.INVALID_PROJECT) == "INVALID_PROJECT", "INVALID_PROJECT conversion");
    validator_assert(*state, error_code_to_string(.TAG_CONFLICT) == "TAG_CONFLICT", "TAG_CONFLICT conversion");
    validator_assert(*state, error_code_to_string(.UNKNOWN_TAG) == "UNKNOWN_TAG", "UNKNOWN_TAG conversion");
    validator_assert(*state, error_code_to_string(.MISSING_PARAM) == "MISSING_PARAM", "MISSING_PARAM conversion");
    validator_assert(*state, error_code_to_string(.INVALID_PARAM_TYPE) == "INVALID_PARAM_TYPE", "INVALID_PARAM_TYPE conversion");
    validator_assert(*state, error_code_to_string(.INVALID_PARAM_VALUE) == "INVALID_PARAM_VALUE", "INVALID_PARAM_VALUE conversion");

    return state.failed == 0;
}

test_has_error_code :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    ctx.profile = copy_string("gaming");
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, has_error_code(*result, .INVALID_PROFILE), "Should find INVALID_PROFILE");
    validator_assert(*state, !has_error_code(*result, .TAG_CONFLICT), "Should not find TAG_CONFLICT");

    return state.failed == 0;
}

test_has_warning_code :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    array_add(*ctx.tags, copy_string("--unknown"));
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    validator_assert(*state, has_warning_code(*result, .UNKNOWN_TAG), "Should find UNKNOWN_TAG warning");
    validator_assert(*state, !has_warning_code(*result, .TAG_CONFLICT), "Should not find TAG_CONFLICT warning");

    return state.failed == 0;
}

//
// Result Utilities
//

test_get_error_summary :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work"]
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    ctx.profile = copy_string("gaming");
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);
    defer free_validation_result(*result);

    summary := get_error_summary(*result);
    defer free(summary);

    validator_assert(*state, summary.count > 0, "Summary should not be empty");
    validator_assert(*state, contains(summary, "error"), "Summary should mention error");
    validator_assert(*state, contains(summary, "profile"), "Summary should mention profile");

    return state.failed == 0;
}

//
// Memory Management
//

test_free_validation_result :: () -> bool {
    state: Validator_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work"]

[[tags.definitions]]
name = "--work"
TOML;

    cfg, _ := parse_config_string(toml_doc);
    defer free_user_config(*cfg);

    ctx: Context;
    ctx.profile = copy_string("gaming");  // Invalid
    array_add(*ctx.tags, copy_string("--unknown"));  // Warning
    defer free_validator_test_context(*ctx);

    result := validate_context(*ctx, *cfg);

    // Should not crash
    free_validation_result(*result);

    validator_assert(*state, true, "free_validation_result completed without crash");

    return state.failed == 0;
}
