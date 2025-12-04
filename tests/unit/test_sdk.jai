// Tests for the Service SDK
//
// These tests verify the Service SDK helper functionality including:
// - Configuration defaults
// - Service registration helpers
// - Registration JSON building
// - Event structures
//
// Note: Socket-dependent tests are not included here because the SDK
// requires POSIX module which is not available in the test runner context.
// Full integration tests would need to be run separately.

// ============================================================================
// Minimal SDK Structures for Testing
// ============================================================================
// These mirror the SDK structures but without socket dependencies

SDK_VERSION :: "1.0.0";
SDK_DEFAULT_SOCKET_PATH :: "/tmp/uncrumpled.sock";
SDK_DEFAULT_HEARTBEAT_INTERVAL :: 30;
SDK_DEFAULT_RECV_BUFFER_SIZE :: 65536;
SDK_DEFAULT_SEND_BUFFER_SIZE :: 8192;

Test_Service_Client_Config :: struct {
    socket_path: string;
    heartbeat_interval_seconds: int;
    recv_buffer_size: int;
    send_buffer_size: int;
    auto_reconnect: bool;
    reconnect_delay_ms: int;
}

init_test_sdk_config :: () -> Test_Service_Client_Config {
    config: Test_Service_Client_Config;
    config.socket_path = SDK_DEFAULT_SOCKET_PATH;
    config.heartbeat_interval_seconds = SDK_DEFAULT_HEARTBEAT_INTERVAL;
    config.recv_buffer_size = SDK_DEFAULT_RECV_BUFFER_SIZE;
    config.send_buffer_size = SDK_DEFAULT_SEND_BUFFER_SIZE;
    config.auto_reconnect = true;
    config.reconnect_delay_ms = 1000;
    return config;
}

Test_SDK_Capability_Manifest :: struct {
    events: [..] string;
    provides_preview: bool;
    api_version: string;
}

Test_Service_Registration :: struct {
    id: string;
    name: string;
    endpoint: string;
    capabilities: Test_SDK_Capability_Manifest;
    preview_callback: string;
}

make_test_registration :: (id: string, name: string, endpoint: string) -> Test_Service_Registration {
    reg: Test_Service_Registration;
    reg.id = copy_string(id);
    reg.name = copy_string(name);
    reg.endpoint = copy_string(endpoint);
    reg.capabilities.api_version = copy_string("1.0.0");
    reg.capabilities.provides_preview = false;
    return reg;
}

free_test_registration :: (reg: *Test_Service_Registration) {
    free(reg.id);
    free(reg.name);
    free(reg.endpoint);
    free(reg.preview_callback);
    for reg.capabilities.events {
        free(it);
    }
    array_free(reg.capabilities.events);
    free(reg.capabilities.api_version);
}

copy_test_registration :: (src: *Test_Service_Registration) -> Test_Service_Registration {
    dst: Test_Service_Registration;
    dst.id = copy_string(src.id);
    dst.name = copy_string(src.name);
    dst.endpoint = copy_string(src.endpoint);
    dst.preview_callback = copy_string(src.preview_callback);
    dst.capabilities.provides_preview = src.capabilities.provides_preview;
    dst.capabilities.api_version = copy_string(src.capabilities.api_version);
    for src.capabilities.events {
        array_add(*dst.capabilities.events, copy_string(it));
    }
    return dst;
}

build_test_registration_json :: (reg: *Test_Service_Registration, request_id: u64) -> string {
    events_json: String_Builder;
    init_string_builder(*events_json);
    defer free_buffers(*events_json);

    append(*events_json, "[");
    for event, idx: reg.capabilities.events {
        if idx > 0 {
            append(*events_json, ",");
        }
        print_to_builder(*events_json, "\"%\"", event);
    }
    append(*events_json, "]");

    events_str := builder_to_string(*events_json);
    defer free(events_str);

    preview_callback := ifx reg.preview_callback.count > 0 then reg.preview_callback else "";

    return tprint(#string END
{"jsonrpc":"2.0","method":"service.register","params":{"id":"%","name":"%","endpoint":"%","preview_callback":"%","capabilities":{"events":%,"provides_preview":%,"api_version":"%"}},"id":%}
END
        , reg.id, reg.name, reg.endpoint, preview_callback, events_str,
          ifx reg.capabilities.provides_preview then "true" else "false",
          reg.capabilities.api_version, request_id);
}

Test_SDK_Event_Type :: enum {
    UNKNOWN;
    CONTEXT_CHANGED;
    SERVICE_REGISTERED;
    SERVICE_UNREGISTERED;
    HEARTBEAT_ACK;
    ERROR;
}

Test_SDK_Event :: struct {
    valid: bool;
    event_type: Test_SDK_Event_Type;
    raw_json: string;
    changed_fields: [..] string;
    error_message: string;
}

make_test_empty_event :: () -> Test_SDK_Event {
    event: Test_SDK_Event;
    event.valid = false;
    event.event_type = .UNKNOWN;
    return event;
}

free_test_sdk_event :: (event: *Test_SDK_Event) {
    free(event.raw_json);
    for event.changed_fields {
        free(it);
    }
    array_free(event.changed_fields);
    free(event.error_message);
}

// ============================================================================
// Configuration Tests
// ============================================================================

test_sdk_default_config :: () -> bool {
    config := init_test_sdk_config();

    assert_equal(config.socket_path, SDK_DEFAULT_SOCKET_PATH, "default socket path");
    assert_equal(config.heartbeat_interval_seconds, SDK_DEFAULT_HEARTBEAT_INTERVAL, "default heartbeat interval");
    assert_equal(config.recv_buffer_size, SDK_DEFAULT_RECV_BUFFER_SIZE, "default recv buffer");
    assert_equal(config.send_buffer_size, SDK_DEFAULT_SEND_BUFFER_SIZE, "default send buffer");
    assert_true(config.auto_reconnect, "auto_reconnect default");
    assert_equal(config.reconnect_delay_ms, 1000, "reconnect delay default");

    return true;
}

// ============================================================================
// Registration Helper Tests
// ============================================================================

test_make_registration :: () -> bool {
    reg := make_test_registration("test-service", "Test Service", "/tmp/test.sock");
    defer free_test_registration(*reg);

    assert_equal(reg.id, "test-service", "id");
    assert_equal(reg.name, "Test Service", "name");
    assert_equal(reg.endpoint, "/tmp/test.sock", "endpoint");
    assert_equal(reg.capabilities.api_version, "1.0.0", "default api_version");
    assert_false(reg.capabilities.provides_preview, "default provides_preview");
    assert_equal(reg.capabilities.events.count, 0, "empty events by default");

    return true;
}

test_registration_with_events :: () -> bool {
    reg := make_test_registration("my-service", "My Service", "/tmp/my.sock");
    defer free_test_registration(*reg);

    array_add(*reg.capabilities.events, copy_string("context.changed"));
    array_add(*reg.capabilities.events, copy_string("service.*"));
    reg.capabilities.provides_preview = true;

    assert_equal(reg.capabilities.events.count, 2, "two events");
    assert_equal(reg.capabilities.events[0], "context.changed", "first event");
    assert_equal(reg.capabilities.events[1], "service.*", "second event");
    assert_true(reg.capabilities.provides_preview, "provides_preview");

    return true;
}

test_copy_registration :: () -> bool {
    orig := make_test_registration("orig-service", "Original", "/tmp/orig.sock");
    defer free_test_registration(*orig);

    array_add(*orig.capabilities.events, copy_string("context.*"));
    orig.capabilities.provides_preview = true;

    copied := copy_test_registration(*orig);
    defer free_test_registration(*copied);

    assert_equal(copied.id, "orig-service", "copied id");
    assert_equal(copied.name, "Original", "copied name");
    assert_equal(copied.endpoint, "/tmp/orig.sock", "copied endpoint");
    assert_equal(copied.capabilities.events.count, 1, "copied events count");
    assert_equal(copied.capabilities.events[0], "context.*", "copied event");
    assert_true(copied.capabilities.provides_preview, "copied provides_preview");

    // Verify independence (modifying original doesn't affect copy)
    free(orig.name);
    orig.name = copy_string("Modified");
    assert_equal(copied.name, "Original", "copy should be independent");

    return true;
}

// ============================================================================
// Registration JSON Builder Tests
// ============================================================================

test_build_registration_json :: () -> bool {
    reg := make_test_registration("test-svc", "Test Service", "/tmp/test.sock");
    defer free_test_registration(*reg);

    array_add(*reg.capabilities.events, copy_string("context.changed"));
    reg.capabilities.provides_preview = true;

    json := build_test_registration_json(*reg, 42);
    // Note: json is tprint result (temporary), don't free

    assert_true(contains(json, "\"method\":\"service.register\""), "has method");
    assert_true(contains(json, "\"id\":\"test-svc\"") || contains(json, "\"id\": \"test-svc\""), "has service id");
    assert_true(contains(json, "\"name\":\"Test Service\"") || contains(json, "\"name\": \"Test Service\""), "has name");
    assert_true(contains(json, "\"endpoint\":\"/tmp/test.sock\"") || contains(json, "\"endpoint\": \"/tmp/test.sock\""), "has endpoint");
    assert_true(contains(json, "\"context.changed\""), "has event");
    assert_true(contains(json, "provides_preview"), "has provides_preview");
    assert_true(contains(json, "\"id\":42") || contains(json, ",\"id\":42"), "has request id 42");

    return true;
}

test_build_registration_json_empty_events :: () -> bool {
    reg := make_test_registration("empty-svc", "Empty Events", "/tmp/empty.sock");
    defer free_test_registration(*reg);

    json := build_test_registration_json(*reg, 1);
    // Note: json is tprint result (temporary), don't free

    assert_true(contains(json, "\"events\":[]"), "has empty events array");

    return true;
}

// ============================================================================
// Event Tests
// ============================================================================

test_make_empty_event :: () -> bool {
    event := make_test_empty_event();

    assert_false(event.valid, "should be invalid");
    assert_equal(cast(int) event.event_type, cast(int) Test_SDK_Event_Type.UNKNOWN, "should be UNKNOWN");
    assert_equal(event.raw_json.count, 0, "no raw json");
    assert_equal(event.changed_fields.count, 0, "no changed fields");
    assert_equal(event.error_message.count, 0, "no error message");

    return true;
}

test_free_sdk_event :: () -> bool {
    event: Test_SDK_Event;
    event.valid = true;
    event.event_type = .CONTEXT_CHANGED;
    event.raw_json = copy_string("{\"test\": true}");
    array_add(*event.changed_fields, copy_string("tags"));
    array_add(*event.changed_fields, copy_string("profile"));
    event.error_message = copy_string("test error");

    free_test_sdk_event(*event);

    // Memory freed - just verify no crash
    return true;
}

// ============================================================================
// Test Registration
// ============================================================================

register_sdk_tests :: (register: (string, () -> bool, string) -> ()) {
    // Configuration tests
    register("sdk/default_config", test_sdk_default_config, "unit");

    // Registration helper tests
    register("sdk/make_registration", test_make_registration, "unit");
    register("sdk/registration_with_events", test_registration_with_events, "unit");
    register("sdk/copy_registration", test_copy_registration, "unit");

    // Registration JSON tests
    register("sdk/build_registration_json", test_build_registration_json, "unit");
    register("sdk/build_registration_json_empty_events", test_build_registration_json_empty_events, "unit");

    // Event tests
    register("sdk/make_empty_event", test_make_empty_event, "unit");
    register("sdk/free_sdk_event", test_free_sdk_event, "unit");
}
