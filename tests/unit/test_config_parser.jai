// Unit tests for the Configuration Parser
//
// Tests parsing of TOML config files, data structure creation,
// validation helpers, and memory management.

#import "Basic";
#import "String";
#import,dir "../../src/daemon/config";

// Registration function for test framework
register_config_parser_tests :: (register: (name: string, proc: () -> bool, category: string)) {
    // Default config tests
    register("config/create_default", test_create_default_config, "unit");
    register("config/default_values", test_default_values, "unit");

    // TOML parsing tests
    register("config/parse_empty", test_parse_empty, "unit");
    register("config/parse_context_section", test_parse_context_section, "unit");
    register("config/parse_tags_section", test_parse_tags_section, "unit");
    register("config/parse_tags_conflicts", test_parse_tags_conflicts, "unit");
    register("config/parse_params_section", test_parse_params_section, "unit");
    register("config/parse_params_enum", test_parse_params_enum, "unit");
    register("config/parse_daemon_section", test_parse_daemon_section, "unit");
    register("config/parse_full_config", test_parse_full_config, "unit");

    // Error handling tests
    register("config/parse_invalid_toml", test_parse_invalid_toml, "unit");
    register("config/parse_missing_file", test_parse_missing_file, "unit");

    // Validation helper tests
    register("config/is_profile_allowed", test_is_profile_allowed, "unit");
    register("config/is_environment_allowed", test_is_environment_allowed, "unit");
    register("config/tags_conflict", test_tags_conflict, "unit");
    register("config/get_tag_definition", test_get_tag_definition, "unit");
    register("config/get_param_definition", test_get_param_definition, "unit");
    register("config/validate_param_bool", test_validate_param_bool, "unit");
    register("config/validate_param_int", test_validate_param_int, "unit");
    register("config/validate_param_enum", test_validate_param_enum, "unit");

    // Memory management tests
    register("config/free_config", test_free_config, "unit");

    // Utility tests
    register("config/param_type_to_string", test_param_type_to_string, "unit");
    register("config/expand_path_tilde", test_expand_path_tilde, "unit");

    // Hotkey config tests
    register("config/hotkey_default", test_hotkey_default, "unit");
    register("config/hotkey_parse_section", test_hotkey_parse_section, "unit");
    register("config/hotkey_parse_disabled", test_hotkey_parse_disabled, "unit");
    register("config/hotkey_preset_to_config", test_hotkey_preset_to_config, "unit");
    register("config/hotkey_preset_display", test_hotkey_preset_display, "unit");
    register("config/hotkey_config_to_toml", test_hotkey_config_to_toml, "unit");
    register("config/hotkey_config_to_string", test_hotkey_config_to_string, "unit");
}

//
// Test State Helper (local to this file)
//
Config_Test_State :: struct {
    passed: int;
    failed: int;
}

config_test_assert :: (state: *Config_Test_State, condition: bool, message: string) {
    if condition {
        state.passed += 1;
    } else {
        state.failed += 1;
        print("  ASSERTION FAILED: %\n", message);
    }
}

//
// Default Config Tests
//

test_create_default_config :: () -> bool {
    state: Config_Test_State;

    config := create_default_config();
    defer free_user_config(*config);

    config_test_assert(*state, config.context_rules.allowed_projects.count > 0, "Should have default allowed_projects");
    config_test_assert(*state, config.context_rules.allowed_profiles.count > 0, "Should have default allowed_profiles");
    config_test_assert(*state, config.context_rules.allowed_environments.count > 0, "Should have default allowed_environments");
    config_test_assert(*state, config.daemon.socket_path.count > 0, "Should have default socket_path");
    config_test_assert(*state, !config.has_error, "Should not have error");

    return state.failed == 0;
}

test_default_values :: () -> bool {
    state: Config_Test_State;

    config := create_default_config();
    defer free_user_config(*config);

    // Check specific defaults
    config_test_assert(*state, config.context_rules.allowed_projects[0] == ".*", "Default project pattern should be '.*'");
    config_test_assert(*state, config.context_rules.allowed_profiles[0] == "default", "First default profile should be 'default'");
    config_test_assert(*state, config.daemon.heartbeat_interval_seconds == 30, "Default heartbeat should be 30");
    config_test_assert(*state, config.daemon.subscriber_timeout_seconds == 90, "Default timeout should be 90");
    config_test_assert(*state, config.daemon.max_log_entries == 1000, "Default max_log_entries should be 1000");
    config_test_assert(*state, config.daemon.log_level == "info", "Default log_level should be 'info'");

    return state.failed == 0;
}

//
// TOML Parsing Tests
//

test_parse_empty :: () -> bool {
    state: Config_Test_State;

    // Empty config should use defaults
    toml_doc := "";

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    // Empty string should still parse but result in empty table
    // The result depends on toml-c behavior
    config_test_assert(*state, !config.has_error || config.error_message.count > 0, "Should parse or give clear error");

    return state.failed == 0;
}

test_parse_context_section :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[context]
allowed_projects = ["project-a", "project-b.*"]
allowed_profiles = ["work", "personal", "gaming"]
allowed_environments = ["dev", "prod"]
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        // Check allowed_projects
        config_test_assert(*state, config.context_rules.allowed_projects.count == 2, "Should have 2 projects");
        if config.context_rules.allowed_projects.count >= 2 {
            config_test_assert(*state, config.context_rules.allowed_projects[0] == "project-a", "First project should match");
            config_test_assert(*state, config.context_rules.allowed_projects[1] == "project-b.*", "Second project should match");
        }

        // Check allowed_profiles
        config_test_assert(*state, config.context_rules.allowed_profiles.count == 3, "Should have 3 profiles");
        if config.context_rules.allowed_profiles.count >= 3 {
            config_test_assert(*state, config.context_rules.allowed_profiles[0] == "work", "First profile should be 'work'");
            config_test_assert(*state, config.context_rules.allowed_profiles[1] == "personal", "Second profile should be 'personal'");
            config_test_assert(*state, config.context_rules.allowed_profiles[2] == "gaming", "Third profile should be 'gaming'");
        }

        // Check allowed_environments
        config_test_assert(*state, config.context_rules.allowed_environments.count == 2, "Should have 2 environments");
        if config.context_rules.allowed_environments.count >= 2 {
            config_test_assert(*state, config.context_rules.allowed_environments[0] == "dev", "First env should be 'dev'");
            config_test_assert(*state, config.context_rules.allowed_environments[1] == "prod", "Second env should be 'prod'");
        }
    }

    return state.failed == 0;
}

test_parse_tags_section :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
description = "Work context"

[[tags.definitions]]
name = "--personal"
description = "Personal context"
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        config_test_assert(*state, config.tags.definitions.count == 2, "Should have 2 tag definitions");

        if config.tags.definitions.count >= 2 {
            config_test_assert(*state, config.tags.definitions[0].name == "--work", "First tag name should be '--work'");
            config_test_assert(*state, config.tags.definitions[0].description == "Work context", "First tag description should match");
            config_test_assert(*state, config.tags.definitions[1].name == "--personal", "Second tag name should be '--personal'");
        }
    }

    return state.failed == 0;
}

test_parse_tags_conflicts :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
description = "Work context"
conflicts_with = ["--personal", "--gaming"]

[[tags.definitions]]
name = "--personal"
description = "Personal context"
conflicts_with = ["--work"]
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        config_test_assert(*state, config.tags.definitions.count == 2, "Should have 2 tag definitions");

        if config.tags.definitions.count >= 1 {
            work_tag := config.tags.definitions[0];
            config_test_assert(*state, work_tag.conflicts_with.count == 2, "Work tag should have 2 conflicts");
            if work_tag.conflicts_with.count >= 2 {
                config_test_assert(*state, work_tag.conflicts_with[0] == "--personal", "First conflict should be '--personal'");
                config_test_assert(*state, work_tag.conflicts_with[1] == "--gaming", "Second conflict should be '--gaming'");
            }
        }

        if config.tags.definitions.count >= 2 {
            personal_tag := config.tags.definitions[1];
            config_test_assert(*state, personal_tag.conflicts_with.count == 1, "Personal tag should have 1 conflict");
            if personal_tag.conflicts_with.count >= 1 {
                config_test_assert(*state, personal_tag.conflicts_with[0] == "--work", "Personal conflict should be '--work'");
            }
        }
    }

    return state.failed == 0;
}

test_parse_params_section :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "verbose"
type = "bool"
default = false
description = "Enable verbose output"

[[params.definitions]]
name = "timeout"
type = "int"
default = 30
required = true
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        config_test_assert(*state, config.params.definitions.count == 2, "Should have 2 param definitions");

        if config.params.definitions.count >= 2 {
            verbose := config.params.definitions[0];
            config_test_assert(*state, verbose.name == "verbose", "First param name should be 'verbose'");
            config_test_assert(*state, verbose.param_type == .BOOL, "verbose should be bool type");
            config_test_assert(*state, verbose.default_value == "false", "verbose default should be 'false'");
            config_test_assert(*state, verbose.description == "Enable verbose output", "verbose description should match");
            config_test_assert(*state, !verbose.required, "verbose should not be required");

            timeout := config.params.definitions[1];
            config_test_assert(*state, timeout.name == "timeout", "Second param name should be 'timeout'");
            config_test_assert(*state, timeout.param_type == .INT, "timeout should be int type");
            config_test_assert(*state, timeout.default_value == "30", "timeout default should be '30'");
            config_test_assert(*state, timeout.required, "timeout should be required");
        }
    }

    return state.failed == 0;
}

test_parse_params_enum :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "mode"
type = "enum"
values = ["debug", "release", "profile"]
default = "release"
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        config_test_assert(*state, config.params.definitions.count == 1, "Should have 1 param definition");

        if config.params.definitions.count >= 1 {
            mode := config.params.definitions[0];
            config_test_assert(*state, mode.name == "mode", "Param name should be 'mode'");
            config_test_assert(*state, mode.param_type == .ENUM, "mode should be enum type");
            config_test_assert(*state, mode.default_value == "release", "mode default should be 'release'");
            config_test_assert(*state, mode.values.count == 3, "mode should have 3 values");

            if mode.values.count >= 3 {
                config_test_assert(*state, mode.values[0] == "debug", "First value should be 'debug'");
                config_test_assert(*state, mode.values[1] == "release", "Second value should be 'release'");
                config_test_assert(*state, mode.values[2] == "profile", "Third value should be 'profile'");
            }
        }
    }

    return state.failed == 0;
}

test_parse_daemon_section :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[daemon]
socket_path = "/var/run/uncrumpled.sock"
heartbeat_interval_seconds = 60
subscriber_timeout_seconds = 180
max_log_entries = 5000
log_level = "debug"
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        config_test_assert(*state, config.daemon.socket_path == "/var/run/uncrumpled.sock", "socket_path should match");
        config_test_assert(*state, config.daemon.heartbeat_interval_seconds == 60, "heartbeat should be 60");
        config_test_assert(*state, config.daemon.subscriber_timeout_seconds == 180, "timeout should be 180");
        config_test_assert(*state, config.daemon.max_log_entries == 5000, "max_log_entries should be 5000");
        config_test_assert(*state, config.daemon.log_level == "debug", "log_level should be 'debug'");
    }

    return state.failed == 0;
}

test_parse_full_config :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[context]
allowed_projects = [".*"]
allowed_profiles = ["default", "work", "personal", "gaming"]
allowed_environments = ["dev", "staging", "prod", "local"]

[[tags.definitions]]
name = "--work"
description = "Work context"
conflicts_with = ["--personal", "--gaming"]

[[tags.definitions]]
name = "--personal"
description = "Personal context"

[[params.definitions]]
name = "mode"
type = "enum"
values = ["debug", "release", "profile"]
default = "release"

[[params.definitions]]
name = "verbose"
type = "bool"
default = false

[daemon]
socket_path = "/tmp/uncrumpled.sock"
heartbeat_interval_seconds = 30
subscriber_timeout_seconds = 90
max_log_entries = 1000
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        // Verify all sections parsed
        config_test_assert(*state, config.context_rules.allowed_profiles.count == 4, "Should have 4 profiles");
        config_test_assert(*state, config.context_rules.allowed_environments.count == 4, "Should have 4 environments");
        config_test_assert(*state, config.tags.definitions.count == 2, "Should have 2 tags");
        config_test_assert(*state, config.params.definitions.count == 2, "Should have 2 params");
        config_test_assert(*state, config.daemon.socket_path == "/tmp/uncrumpled.sock", "socket_path should match");
    }

    return state.failed == 0;
}

//
// Error Handling Tests
//

test_parse_invalid_toml :: () -> bool {
    state: Config_Test_State;

    invalid_toml := "this is not valid toml [[[";

    config, success := parse_config_string(invalid_toml);
    defer free_user_config(*config);

    config_test_assert(*state, !success, "Parse should fail for invalid TOML");
    config_test_assert(*state, config.has_error, "Should have error flag set");
    config_test_assert(*state, config.error_message.count > 0, "Should have error message");

    return state.failed == 0;
}

test_parse_missing_file :: () -> bool {
    state: Config_Test_State;

    config, success := parse_config_file("/nonexistent/path/to/config.toml");
    defer free_user_config(*config);

    config_test_assert(*state, !success, "Parse should fail for missing file");
    config_test_assert(*state, config.has_error, "Should have error flag set");
    config_test_assert(*state, config.error_message.count > 0, "Should have error message");

    return state.failed == 0;
}

//
// Validation Helper Tests
//

test_is_profile_allowed :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["work", "personal"]
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        config_test_assert(*state, is_profile_allowed(*config, "work"), "'work' should be allowed");
        config_test_assert(*state, is_profile_allowed(*config, "personal"), "'personal' should be allowed");
        config_test_assert(*state, !is_profile_allowed(*config, "gaming"), "'gaming' should not be allowed");
        config_test_assert(*state, !is_profile_allowed(*config, "default"), "'default' should not be allowed");
    }

    return state.failed == 0;
}

test_is_environment_allowed :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[context]
allowed_environments = ["dev", "prod"]
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        config_test_assert(*state, is_environment_allowed(*config, "dev"), "'dev' should be allowed");
        config_test_assert(*state, is_environment_allowed(*config, "prod"), "'prod' should be allowed");
        config_test_assert(*state, !is_environment_allowed(*config, "staging"), "'staging' should not be allowed");
    }

    return state.failed == 0;
}

test_tags_conflict :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
conflicts_with = ["--personal", "--gaming"]

[[tags.definitions]]
name = "--personal"
conflicts_with = ["--work"]

[[tags.definitions]]
name = "--gaming"
conflicts_with = ["--work"]
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        config_test_assert(*state, tags_conflict(*config, "--work", "--personal"), "work and personal should conflict");
        config_test_assert(*state, tags_conflict(*config, "--personal", "--work"), "personal and work should conflict (reverse)");
        config_test_assert(*state, tags_conflict(*config, "--work", "--gaming"), "work and gaming should conflict");
        config_test_assert(*state, !tags_conflict(*config, "--personal", "--gaming"), "personal and gaming should not conflict");
    }

    return state.failed == 0;
}

test_get_tag_definition :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[tags.definitions]]
name = "--work"
description = "Work context"
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        tag := get_tag_definition(*config, "--work");
        config_test_assert(*state, tag != null, "Should find --work tag");
        if tag != null {
            config_test_assert(*state, tag.name == "--work", "Tag name should match");
            config_test_assert(*state, tag.description == "Work context", "Tag description should match");
        }

        missing := get_tag_definition(*config, "--missing");
        config_test_assert(*state, missing == null, "Should not find --missing tag");
    }

    return state.failed == 0;
}

test_get_param_definition :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "verbose"
type = "bool"
default = true
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        param := get_param_definition(*config, "verbose");
        config_test_assert(*state, param != null, "Should find 'verbose' param");
        if param != null {
            config_test_assert(*state, param.name == "verbose", "Param name should match");
            config_test_assert(*state, param.param_type == .BOOL, "Param type should be BOOL");
        }

        missing := get_param_definition(*config, "missing");
        config_test_assert(*state, missing == null, "Should not find 'missing' param");
    }

    return state.failed == 0;
}

test_validate_param_bool :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "verbose"
type = "bool"
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        valid_true, _ := validate_param_value(*config, "verbose", "true");
        config_test_assert(*state, valid_true, "'true' should be valid for bool");

        valid_false, _ := validate_param_value(*config, "verbose", "false");
        config_test_assert(*state, valid_false, "'false' should be valid for bool");

        invalid, msg := validate_param_value(*config, "verbose", "yes");
        config_test_assert(*state, !invalid, "'yes' should be invalid for bool");
        config_test_assert(*state, msg.count > 0, "Should have error message");
    }

    return state.failed == 0;
}

test_validate_param_int :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "count"
type = "int"
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        valid_42, _ := validate_param_value(*config, "count", "42");
        config_test_assert(*state, valid_42, "'42' should be valid for int");

        valid_neg, _ := validate_param_value(*config, "count", "-10");
        config_test_assert(*state, valid_neg, "'-10' should be valid for int");

        invalid, msg := validate_param_value(*config, "count", "abc");
        config_test_assert(*state, !invalid, "'abc' should be invalid for int");
        config_test_assert(*state, msg.count > 0, "Should have error message");
    }

    return state.failed == 0;
}

test_validate_param_enum :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[[params.definitions]]
name = "mode"
type = "enum"
values = ["debug", "release"]
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        valid_debug, _ := validate_param_value(*config, "mode", "debug");
        config_test_assert(*state, valid_debug, "'debug' should be valid for mode enum");

        valid_release, _ := validate_param_value(*config, "mode", "release");
        config_test_assert(*state, valid_release, "'release' should be valid for mode enum");

        invalid, msg := validate_param_value(*config, "mode", "profile");
        config_test_assert(*state, !invalid, "'profile' should be invalid for mode enum");
        config_test_assert(*state, msg.count > 0, "Should have error message");
    }

    return state.failed == 0;
}

//
// Memory Management Tests
//

test_free_config :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[context]
allowed_profiles = ["a", "b", "c"]
allowed_environments = ["dev", "prod"]

[[tags.definitions]]
name = "--work"
description = "Work"
conflicts_with = ["--personal"]

[[params.definitions]]
name = "mode"
type = "enum"
values = ["a", "b"]

[daemon]
socket_path = "/tmp/test.sock"
log_level = "debug"
TOML;

    config, success := parse_config_string(toml_doc);
    config_test_assert(*state, success, "Parse should succeed");

    // This should not leak memory (manual verification or use valgrind)
    // Note: In Jai, array_free doesn't zero the count - it just frees the memory
    // So we're mainly testing that this doesn't crash
    free_user_config(*config);

    // The function completed without crashing
    config_test_assert(*state, true, "free_user_config completed without crash");

    return state.failed == 0;
}

//
// Utility Tests
//

test_param_type_to_string :: () -> bool {
    state: Config_Test_State;

    config_test_assert(*state, param_type_to_string(.STRING) == "string", "STRING should convert to 'string'");
    config_test_assert(*state, param_type_to_string(.INT) == "int", "INT should convert to 'int'");
    config_test_assert(*state, param_type_to_string(.BOOL) == "bool", "BOOL should convert to 'bool'");
    config_test_assert(*state, param_type_to_string(.FLOAT) == "float", "FLOAT should convert to 'float'");
    config_test_assert(*state, param_type_to_string(.ENUM) == "enum", "ENUM should convert to 'enum'");

    return state.failed == 0;
}

test_expand_path_tilde :: () -> bool {
    state: Config_Test_State;

    // Test that ~ expands to something
    expanded := expand_path("~/test");
    defer if expanded.data != "~/test".data free(expanded);

    // On Linux/macOS, ~ should expand to something with /home or /Users
    #if OS == .LINUX || OS == .MACOS {
        config_test_assert(*state, expanded.count > 6, "Expanded path should be longer than ~/test");
        config_test_assert(*state, !begins_with(expanded, "~"), "Expanded path should not start with ~");
    }

    // Test empty path
    empty_result := expand_path("");
    config_test_assert(*state, empty_result.count == 0, "Empty path should return empty");

    return state.failed == 0;
}

//
// Hotkey Config Tests
//

test_hotkey_default :: () -> bool {
    state: Config_Test_State;

    config := create_default_config();
    defer free_user_config(*config);

    // Default hotkey should be Ctrl+Alt+P
    config_test_assert(*state, config.hotkey.enabled, "Default hotkey should be enabled");
    config_test_assert(*state, config.hotkey.key == "P", "Default key should be 'P'");
    config_test_assert(*state, config.hotkey.modifiers == "Ctrl+Alt", "Default modifiers should be 'Ctrl+Alt'");

    return state.failed == 0;
}

test_hotkey_parse_section :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[hotkey]
enabled = true
key = "Space"
modifiers = "Ctrl+Shift"
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, tprint("Parse should succeed: %", config.error_message));

    if success {
        config_test_assert(*state, config.hotkey.enabled, "Hotkey should be enabled");
        config_test_assert(*state, config.hotkey.key == "Space", tprint("Key should be 'Space', got '%'", config.hotkey.key));
        config_test_assert(*state, config.hotkey.modifiers == "Ctrl+Shift", tprint("Modifiers should be 'Ctrl+Shift', got '%'", config.hotkey.modifiers));
    }

    return state.failed == 0;
}

test_hotkey_parse_disabled :: () -> bool {
    state: Config_Test_State;

    toml_doc := #string TOML
[hotkey]
enabled = false
TOML;

    config, success := parse_config_string(toml_doc);
    defer free_user_config(*config);

    config_test_assert(*state, success, "Parse should succeed");

    if success {
        config_test_assert(*state, !config.hotkey.enabled, "Hotkey should be disabled");
    }

    return state.failed == 0;
}

test_hotkey_preset_to_config :: () -> bool {
    state: Config_Test_State;

    // Test NONE preset
    none_cfg := get_hotkey_from_preset(.NONE);
    defer {
        if none_cfg.key.count > 0 free(none_cfg.key);
        if none_cfg.modifiers.count > 0 free(none_cfg.modifiers);
    }
    config_test_assert(*state, !none_cfg.enabled, "NONE preset should be disabled");

    // Test CTRL_ALT_P preset
    ctrl_alt_p := get_hotkey_from_preset(.CTRL_ALT_P);
    defer {
        if ctrl_alt_p.key.count > 0 free(ctrl_alt_p.key);
        if ctrl_alt_p.modifiers.count > 0 free(ctrl_alt_p.modifiers);
    }
    config_test_assert(*state, ctrl_alt_p.enabled, "CTRL_ALT_P should be enabled");
    config_test_assert(*state, ctrl_alt_p.key == "P", "CTRL_ALT_P key should be 'P'");
    config_test_assert(*state, ctrl_alt_p.modifiers == "Ctrl+Alt", "CTRL_ALT_P modifiers should be 'Ctrl+Alt'");

    // Test CTRL_SHIFT_SPACE preset
    ctrl_shift_space := get_hotkey_from_preset(.CTRL_SHIFT_SPACE);
    defer {
        if ctrl_shift_space.key.count > 0 free(ctrl_shift_space.key);
        if ctrl_shift_space.modifiers.count > 0 free(ctrl_shift_space.modifiers);
    }
    config_test_assert(*state, ctrl_shift_space.enabled, "CTRL_SHIFT_SPACE should be enabled");
    config_test_assert(*state, ctrl_shift_space.key == "Space", "CTRL_SHIFT_SPACE key should be 'Space'");
    config_test_assert(*state, ctrl_shift_space.modifiers == "Ctrl+Shift", "CTRL_SHIFT_SPACE modifiers should be 'Ctrl+Shift'");

    // Test F12 preset
    f12 := get_hotkey_from_preset(.F12);
    defer {
        if f12.key.count > 0 free(f12.key);
        if f12.modifiers.count > 0 free(f12.modifiers);
    }
    config_test_assert(*state, f12.enabled, "F12 should be enabled");
    config_test_assert(*state, f12.key == "F12", "F12 key should be 'F12'");
    config_test_assert(*state, f12.modifiers.count == 0, "F12 should have no modifiers");

    return state.failed == 0;
}

test_hotkey_preset_display :: () -> bool {
    state: Config_Test_State;

    config_test_assert(*state, hotkey_preset_to_display(.NONE) == "None (disable hotkey)", "NONE display string");
    config_test_assert(*state, hotkey_preset_to_display(.CTRL_ALT_P) == "Ctrl+Alt+P", "CTRL_ALT_P display string");
    config_test_assert(*state, hotkey_preset_to_display(.CTRL_SHIFT_SPACE) == "Ctrl+Shift+Space", "CTRL_SHIFT_SPACE display string");
    config_test_assert(*state, hotkey_preset_to_display(.F12) == "F12", "F12 display string");

    // Test roundtrip
    config_test_assert(*state, display_to_hotkey_preset("Ctrl+Alt+P") == .CTRL_ALT_P, "Roundtrip CTRL_ALT_P");
    config_test_assert(*state, display_to_hotkey_preset("None (disable hotkey)") == .NONE, "Roundtrip NONE");

    return state.failed == 0;
}

test_hotkey_config_to_toml :: () -> bool {
    state: Config_Test_State;

    // Test enabled config
    enabled_cfg := get_hotkey_from_preset(.CTRL_ALT_P);
    defer {
        if enabled_cfg.key.count > 0 free(enabled_cfg.key);
        if enabled_cfg.modifiers.count > 0 free(enabled_cfg.modifiers);
    }
    enabled_toml := hotkey_config_to_toml(*enabled_cfg);
    defer free(enabled_toml);

    config_test_assert(*state, contains(enabled_toml, "enabled = true"), "TOML should contain 'enabled = true'");
    config_test_assert(*state, contains(enabled_toml, "key = \"P\""), "TOML should contain key");
    config_test_assert(*state, contains(enabled_toml, "modifiers = \"Ctrl+Alt\""), "TOML should contain modifiers");

    // Test disabled config
    disabled_cfg := get_hotkey_from_preset(.NONE);
    defer {
        if disabled_cfg.key.count > 0 free(disabled_cfg.key);
        if disabled_cfg.modifiers.count > 0 free(disabled_cfg.modifiers);
    }
    disabled_toml := hotkey_config_to_toml(*disabled_cfg);
    defer free(disabled_toml);

    config_test_assert(*state, contains(disabled_toml, "enabled = false"), "Disabled TOML should contain 'enabled = false'");

    return state.failed == 0;
}

test_hotkey_config_to_string :: () -> bool {
    state: Config_Test_State;

    // Test enabled with modifiers
    cfg1 := get_hotkey_from_preset(.CTRL_ALT_P);
    defer {
        if cfg1.key.count > 0 free(cfg1.key);
        if cfg1.modifiers.count > 0 free(cfg1.modifiers);
    }
    str1 := hotkey_config_to_string(*cfg1);
    defer free(str1);
    config_test_assert(*state, str1 == "Ctrl+Alt+P", tprint("Expected 'Ctrl+Alt+P', got '%'", str1));

    // Test enabled without modifiers
    cfg2 := get_hotkey_from_preset(.F12);
    defer {
        if cfg2.key.count > 0 free(cfg2.key);
        if cfg2.modifiers.count > 0 free(cfg2.modifiers);
    }
    str2 := hotkey_config_to_string(*cfg2);
    defer free(str2);
    config_test_assert(*state, str2 == "F12", tprint("Expected 'F12', got '%'", str2));

    // Test disabled
    cfg3 := get_hotkey_from_preset(.NONE);
    defer {
        if cfg3.key.count > 0 free(cfg3.key);
        if cfg3.modifiers.count > 0 free(cfg3.modifiers);
    }
    str3 := hotkey_config_to_string(*cfg3);
    defer free(str3);
    config_test_assert(*state, str3 == "(disabled)", tprint("Expected '(disabled)', got '%'", str3));

    return state.failed == 0;
}
