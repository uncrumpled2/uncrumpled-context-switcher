// Unit tests for jai-toml module (TOML parsing via toml-c)
//
// Tests the Jai bindings to the toml-c library

#import "Basic";
#import "Math";
#import,dir "../../modules/jai-toml-c";

// Registration function for test framework
register_toml_tests :: (register: (name: string, proc: () -> bool, category: string)) {
    register("toml/parse_simple", test_parse_simple, "unit");
    register("toml/parse_string_values", test_parse_string_values, "unit");
    register("toml/parse_integer_values", test_parse_integer_values, "unit");
    register("toml/parse_boolean_values", test_parse_boolean_values, "unit");
    register("toml/parse_float_values", test_parse_float_values, "unit");
    register("toml/parse_nested_tables", test_parse_nested_tables, "unit");
    register("toml/parse_array_of_strings", test_parse_array_of_strings, "unit");
    register("toml/parse_array_of_integers", test_parse_array_of_integers, "unit");
    register("toml/parse_array_of_tables", test_parse_array_of_tables, "unit");
    register("toml/parse_error_handling", test_parse_error_handling, "unit");
    register("toml/table_enumeration", test_table_enumeration, "unit");
    register("toml/missing_keys", test_missing_keys, "unit");
    register("toml/config_file_example", test_config_file_example, "unit");
}

//
// Helper to run a test with proper setup/teardown
//
Test_State_Local :: struct {
    passed: int;
    failed: int;
}

test_assert :: (state: *Test_State_Local, condition: bool, message: string) {
    if condition {
        state.passed += 1;
    } else {
        state.failed += 1;
        print("  ASSERTION FAILED: %\n", message);
    }
}

//
// Test cases
//

test_parse_simple :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
title = "Simple Test"
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        title, ok := get_string(table, "title");
        test_assert(*state, ok, "Should get title");
        test_assert(*state, title == "Simple Test", tprint("Title should match: got '%'", title));
    }

    return state.failed == 0;
}

test_parse_string_values :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
name = "test-project"
description = "A test project for TOML parsing"
empty = ""
special = "hello\nworld"
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        {
            name, ok := get_string(table, "name");
            test_assert(*state, ok, "Should get name");
            test_assert(*state, name == "test-project", tprint("Name should match: got '%'", name));
        }

        {
            desc, ok := get_string(table, "description");
            test_assert(*state, ok, "Should get description");
            test_assert(*state, desc == "A test project for TOML parsing", "Description should match");
        }

        {
            empty, ok := get_string(table, "empty");
            test_assert(*state, ok, "Should get empty string");
            test_assert(*state, empty == "", "Empty string should be empty");
        }
    }

    return state.failed == 0;
}

test_parse_integer_values :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
port = 8080
negative = -42
zero = 0
large = 9223372036854775807
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        {
            port, ok := get_int(table, "port");
            test_assert(*state, ok, "Should get port");
            test_assert(*state, port == 8080, tprint("Port should be 8080: got %", port));
        }

        {
            neg, ok := get_int(table, "negative");
            test_assert(*state, ok, "Should get negative");
            test_assert(*state, neg == -42, tprint("Negative should be -42: got %", neg));
        }

        {
            zero, ok := get_int(table, "zero");
            test_assert(*state, ok, "Should get zero");
            test_assert(*state, zero == 0, tprint("Zero should be 0: got %", zero));
        }

        {
            large, ok := get_int(table, "large");
            test_assert(*state, ok, "Should get large");
            test_assert(*state, large == 9223372036854775807, "Large should match max s64");
        }
    }

    return state.failed == 0;
}

test_parse_boolean_values :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
enabled = true
disabled = false
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        {
            enabled, ok := get_bool(table, "enabled");
            test_assert(*state, ok, "Should get enabled");
            test_assert(*state, enabled == true, "Enabled should be true");
        }

        {
            disabled, ok := get_bool(table, "disabled");
            test_assert(*state, ok, "Should get disabled");
            test_assert(*state, disabled == false, "Disabled should be false");
        }
    }

    return state.failed == 0;
}

test_parse_float_values :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
pi = 3.14159
negative = -0.5
scientific = 1.0e-10
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        {
            pi, ok := get_double(table, "pi");
            test_assert(*state, ok, "Should get pi");
            diff := abs(pi - 3.14159);
            test_assert(*state, diff < 0.00001, tprint("Pi should be approximately 3.14159: got %", pi));
        }

        {
            neg, ok := get_double(table, "negative");
            test_assert(*state, ok, "Should get negative");
            diff := abs(neg - (-0.5));
            test_assert(*state, diff < 0.00001, tprint("Negative should be -0.5: got %", neg));
        }
    }

    return state.failed == 0;
}

test_parse_nested_tables :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
[database]
host = "localhost"
port = 5432

[database.credentials]
username = "admin"
password = "secret"

[server]
host = "0.0.0.0"
port = 8080
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        // Test database table
        db := get_table(table, "database");
        test_assert(*state, db != null, "Should get database table");

        if db {
            host, ok := get_string(db, "host");
            test_assert(*state, ok && host == "localhost", "DB host should be localhost");

            port, ok2 := get_int(db, "port");
            test_assert(*state, ok2 && port == 5432, "DB port should be 5432");

            // Test nested credentials table
            creds := get_table(db, "credentials");
            test_assert(*state, creds != null, "Should get credentials table");

            if creds {
                user, ok3 := get_string(creds, "username");
                test_assert(*state, ok3 && user == "admin", "Username should be admin");

                pass, ok4 := get_string(creds, "password");
                test_assert(*state, ok4 && pass == "secret", "Password should be secret");
            }
        }

        // Test server table
        srv := get_table(table, "server");
        test_assert(*state, srv != null, "Should get server table");

        if srv {
            host, ok := get_string(srv, "host");
            test_assert(*state, ok && host == "0.0.0.0", "Server host should be 0.0.0.0");

            port, ok2 := get_int(srv, "port");
            test_assert(*state, ok2 && port == 8080, "Server port should be 8080");
        }
    }

    return state.failed == 0;
}

test_parse_array_of_strings :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
tags = ["alpha", "beta", "gamma"]
empty_array = []
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        tags := get_array(table, "tags");
        test_assert(*state, tags != null, "Should get tags array");

        if tags {
            len := array_len(tags);
            test_assert(*state, len == 3, tprint("Tags should have 3 elements: got %", len));

            {
                val, ok := array_get_string(tags, 0);
                test_assert(*state, ok && val == "alpha", "First tag should be alpha");
            }
            {
                val, ok := array_get_string(tags, 1);
                test_assert(*state, ok && val == "beta", "Second tag should be beta");
            }
            {
                val, ok := array_get_string(tags, 2);
                test_assert(*state, ok && val == "gamma", "Third tag should be gamma");
            }
        }

        empty := get_array(table, "empty_array");
        test_assert(*state, empty != null, "Should get empty array");
        if empty {
            len := array_len(empty);
            test_assert(*state, len == 0, "Empty array should have 0 elements");
        }
    }

    return state.failed == 0;
}

test_parse_array_of_integers :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
ports = [80, 443, 8080]
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        ports := get_array(table, "ports");
        test_assert(*state, ports != null, "Should get ports array");

        if ports {
            len := array_len(ports);
            test_assert(*state, len == 3, "Ports should have 3 elements");

            {
                val, ok := array_get_int(ports, 0);
                test_assert(*state, ok && val == 80, "First port should be 80");
            }
            {
                val, ok := array_get_int(ports, 1);
                test_assert(*state, ok && val == 443, "Second port should be 443");
            }
            {
                val, ok := array_get_int(ports, 2);
                test_assert(*state, ok && val == 8080, "Third port should be 8080");
            }
        }
    }

    return state.failed == 0;
}

test_parse_array_of_tables :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
[[servers]]
name = "alpha"
ip = "10.0.0.1"

[[servers]]
name = "beta"
ip = "10.0.0.2"

[[servers]]
name = "gamma"
ip = "10.0.0.3"
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        servers := get_array(table, "servers");
        test_assert(*state, servers != null, "Should get servers array");

        if servers {
            len := array_len(servers);
            test_assert(*state, len == 3, tprint("Servers should have 3 elements: got %", len));

            // Check first server
            {
                srv := array_get_table(servers, 0);
                test_assert(*state, srv != null, "Should get first server");
                if srv {
                    name, ok := get_string(srv, "name");
                    test_assert(*state, ok && name == "alpha", "First server name should be alpha");

                    ip, ok2 := get_string(srv, "ip");
                    test_assert(*state, ok2 && ip == "10.0.0.1", "First server IP should be 10.0.0.1");
                }
            }

            // Check second server
            {
                srv := array_get_table(servers, 1);
                test_assert(*state, srv != null, "Should get second server");
                if srv {
                    name, ok := get_string(srv, "name");
                    test_assert(*state, ok && name == "beta", "Second server name should be beta");
                }
            }

            // Check third server
            {
                srv := array_get_table(servers, 2);
                test_assert(*state, srv != null, "Should get third server");
                if srv {
                    name, ok := get_string(srv, "name");
                    test_assert(*state, ok && name == "gamma", "Third server name should be gamma");
                }
            }
        }
    }

    return state.failed == 0;
}

test_parse_error_handling :: () -> bool {
    state: Test_State_Local;

    // Invalid TOML - missing closing quote
    invalid_toml := #string TOML
name = "unclosed
TOML;

    table, success, error := parse(invalid_toml);
    test_assert(*state, !success, "Parse should fail for invalid TOML");
    test_assert(*state, error.count > 0, "Error message should not be empty");
    test_assert(*state, table == null, "Table should be null on error");

    if error.count > 0 {
        free(error);
    }

    // Invalid TOML - bad syntax
    bad_syntax := #string TOML
= "no key"
TOML;

    table2, success2, error2 := parse(bad_syntax);
    test_assert(*state, !success2, "Parse should fail for bad syntax");

    if error2.count > 0 {
        free(error2);
    }

    return state.failed == 0;
}

test_table_enumeration :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
alpha = 1
beta = 2
gamma = 3
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        len := table_len(table);
        test_assert(*state, len == 3, tprint("Table should have 3 keys: got %", len));

        // Enumerate keys
        keys: [3] string;
        for i: 0..len-1 {
            key, ok := table_key_at(table, cast(s32)i);
            test_assert(*state, ok, tprint("Should get key at index %", i));
            if i < 3 {
                keys[i] = key;
            }
        }

        // Keys might be in any order, so just verify we got the right ones
        found_alpha := false;
        found_beta := false;
        found_gamma := false;
        for keys {
            if it == "alpha" found_alpha = true;
            if it == "beta" found_beta = true;
            if it == "gamma" found_gamma = true;
        }
        test_assert(*state, found_alpha, "Should find alpha key");
        test_assert(*state, found_beta, "Should find beta key");
        test_assert(*state, found_gamma, "Should find gamma key");
    }

    return state.failed == 0;
}

test_missing_keys :: () -> bool {
    state: Test_State_Local;

    toml_doc := #string TOML
existing = "value"
TOML;

    table, success, error := parse(toml_doc);
    test_assert(*state, success, "Parse should succeed");

    if table {
        defer free_table(table);

        // Test missing string
        {
            val, ok := get_string(table, "nonexistent");
            test_assert(*state, !ok, "Should not find nonexistent string");
            test_assert(*state, val == "", "Missing string should be empty");
        }

        // Test missing int
        {
            val, ok := get_int(table, "nonexistent");
            test_assert(*state, !ok, "Should not find nonexistent int");
            test_assert(*state, val == 0, "Missing int should be 0");
        }

        // Test missing bool
        {
            val, ok := get_bool(table, "nonexistent");
            test_assert(*state, !ok, "Should not find nonexistent bool");
            test_assert(*state, val == false, "Missing bool should be false");
        }

        // Test missing table
        {
            tbl := get_table(table, "nonexistent");
            test_assert(*state, tbl == null, "Missing table should be null");
        }

        // Test missing array
        {
            arr := get_array(table, "nonexistent");
            test_assert(*state, arr == null, "Missing array should be null");
        }
    }

    return state.failed == 0;
}

test_config_file_example :: () -> bool {
    state: Test_State_Local;

    // Example config file structure matching the daemon's config format
    toml_doc := #string TOML
[context]
allowed_projects = [".*"]
allowed_profiles = ["default", "work", "personal", "gaming"]
allowed_environments = ["dev", "staging", "prod", "local"]

[[tags.definitions]]
name = "--work"
description = "Work context"

[[tags.definitions]]
name = "--personal"
description = "Personal context"

[[params.definitions]]
name = "mode"
type = "enum"
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

    table, success, error := parse(toml_doc);
    test_assert(*state, success, tprint("Parse should succeed: %", error));

    if table {
        defer free_table(table);

        // Test [context] section
        ctx := get_table(table, "context");
        test_assert(*state, ctx != null, "Should have context table");

        if ctx {
            profiles := get_array(ctx, "allowed_profiles");
            test_assert(*state, profiles != null, "Should have allowed_profiles");
            if profiles {
                len := array_len(profiles);
                test_assert(*state, len == 4, "Should have 4 profiles");
            }
        }

        // Test [[tags.definitions]] array of tables
        tags := get_table(table, "tags");
        test_assert(*state, tags != null, "Should have tags table");

        if tags {
            defs := get_array(tags, "definitions");
            test_assert(*state, defs != null, "Should have definitions array");

            if defs {
                len := array_len(defs);
                test_assert(*state, len == 2, tprint("Should have 2 tag definitions: got %", len));

                tag0 := array_get_table(defs, 0);
                if tag0 {
                    name, ok := get_string(tag0, "name");
                    test_assert(*state, ok && name == "--work", "First tag should be --work");
                }
            }
        }

        // Test [daemon] section
        daemon := get_table(table, "daemon");
        test_assert(*state, daemon != null, "Should have daemon table");

        if daemon {
            path, ok := get_string(daemon, "socket_path");
            test_assert(*state, ok && path == "/tmp/uncrumpled.sock", "Socket path should match");

            hb, ok2 := get_int(daemon, "heartbeat_interval_seconds");
            test_assert(*state, ok2 && hb == 30, "Heartbeat interval should be 30");

            max_logs, ok3 := get_int(daemon, "max_log_entries");
            test_assert(*state, ok3 && max_logs == 1000, "Max log entries should be 1000");
        }
    }

    return state.failed == 0;
}
