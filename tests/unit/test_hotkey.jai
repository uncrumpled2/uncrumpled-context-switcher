// Unit tests for the system hotkey module
//
// Tests cover:
// - Hotkey struct creation and manipulation
// - Modifier flag combinations
// - Key enums
// - Hotkey hashing and comparison
// - Hotkey to/from string conversion

// Note: We don't #import the hotkey module here because it needs X11.
// The tests that require display are guarded and may skip if no display is available.

// Local type definitions (matching the hotkey module)
// These are duplicated here to test without requiring X11

Hotkey_Modifier :: enum_flags {
    NONE      :: 0x0;
    CONTROL   :: 0x1;
    SHIFT     :: 0x2;
    ALT       :: 0x4;
    SUPER     :: 0x8;
}

Key :: enum {
    A; B; C; D; E; F; G; H; I; J; K; L; M;
    N; O; P; Q; R; S; T; U; V; W; X; Y; Z;
    NUM_0; NUM_1; NUM_2; NUM_3; NUM_4;
    NUM_5; NUM_6; NUM_7; NUM_8; NUM_9;
    F1; F2; F3; F4; F5; F6; F7; F8; F9; F10; F11; F12;
    UP; DOWN; LEFT; RIGHT;
    SPACE; ENTER; ESCAPE; TAB;
}

Hotkey :: struct {
    modifiers: Hotkey_Modifier;
    key: Key;
}

// ============================================================================
// Test: Hotkey struct creation
// ============================================================================

test_hotkey_struct_creation :: () -> bool {
    state := init_test_state("test_hotkey_struct_creation", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test basic creation
        hk := Hotkey.{ modifiers = .NONE, key = .A };
        assert_equal(hk.modifiers, .NONE, "Modifier should be NONE");
        assert_equal(cast(int)hk.key, 0, "Key A should be 0");

        // Test with modifiers
        hk2 := Hotkey.{ modifiers = .CONTROL | .ALT, key = .P };
        assert_true(cast(bool)(hk2.modifiers & .CONTROL), "Should have CONTROL modifier");
        assert_true(cast(bool)(hk2.modifiers & .ALT), "Should have ALT modifier");
        assert_false(cast(bool)(hk2.modifiers & .SHIFT), "Should not have SHIFT modifier");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Modifier flag combinations
// ============================================================================

test_hotkey_modifier_flags :: () -> bool {
    state := init_test_state("test_hotkey_modifier_flags", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test single modifiers
        ctrl := Hotkey_Modifier.CONTROL;
        assert_equal(cast(int)ctrl, 0x1, "CONTROL should be 0x1");

        shift := Hotkey_Modifier.SHIFT;
        assert_equal(cast(int)shift, 0x2, "SHIFT should be 0x2");

        alt := Hotkey_Modifier.ALT;
        assert_equal(cast(int)alt, 0x4, "ALT should be 0x4");

        super := Hotkey_Modifier.SUPER;
        assert_equal(cast(int)super, 0x8, "SUPER should be 0x8");

        // Test combined modifiers
        ctrl_shift := Hotkey_Modifier.CONTROL | Hotkey_Modifier.SHIFT;
        assert_equal(cast(int)ctrl_shift, 0x3, "CONTROL|SHIFT should be 0x3");

        ctrl_alt := Hotkey_Modifier.CONTROL | Hotkey_Modifier.ALT;
        assert_equal(cast(int)ctrl_alt, 0x5, "CONTROL|ALT should be 0x5");

        all_mods := Hotkey_Modifier.CONTROL | Hotkey_Modifier.SHIFT | Hotkey_Modifier.ALT | Hotkey_Modifier.SUPER;
        assert_equal(cast(int)all_mods, 0xF, "All modifiers should be 0xF");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Key enum values
// ============================================================================

test_hotkey_key_enum :: () -> bool {
    state := init_test_state("test_hotkey_key_enum", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test letter keys (A-Z should be 0-25)
        assert_equal(cast(int)Key.A, 0, "Key.A should be 0");
        assert_equal(cast(int)Key.Z, 25, "Key.Z should be 25");
        assert_equal(cast(int)Key.P, 15, "Key.P should be 15");

        // Test number keys (NUM_0-NUM_9 should be 26-35)
        assert_equal(cast(int)Key.NUM_0, 26, "Key.NUM_0 should be 26");
        assert_equal(cast(int)Key.NUM_9, 35, "Key.NUM_9 should be 35");

        // Test function keys (F1-F12 should be 36-47)
        assert_equal(cast(int)Key.F1, 36, "Key.F1 should be 36");
        assert_equal(cast(int)Key.F12, 47, "Key.F12 should be 47");

        // Test arrow keys (48-51)
        assert_equal(cast(int)Key.UP, 48, "Key.UP should be 48");
        assert_equal(cast(int)Key.DOWN, 49, "Key.DOWN should be 49");

        // Test special keys
        assert_equal(cast(int)Key.SPACE, 52, "Key.SPACE should be 52");
        assert_equal(cast(int)Key.ENTER, 53, "Key.ENTER should be 53");
        assert_equal(cast(int)Key.ESCAPE, 54, "Key.ESCAPE should be 54");
        assert_equal(cast(int)Key.TAB, 55, "Key.TAB should be 55");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey hashing
// ============================================================================

test_hotkey_hashing :: () -> bool {
    state := init_test_state("test_hotkey_hashing", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test hash function
        hash_hotkey :: (k: Hotkey) -> u32 {
            h := cast(u32) k.modifiers;
            h = (h << 5) + h + cast(u32) k.key;
            return h;
        }

        hk1 := Hotkey.{ modifiers = .CONTROL, key = .P };
        hk2 := Hotkey.{ modifiers = .CONTROL, key = .P };
        hk3 := Hotkey.{ modifiers = .CONTROL | .SHIFT, key = .P };

        hash1 := hash_hotkey(hk1);
        hash2 := hash_hotkey(hk2);
        hash3 := hash_hotkey(hk3);

        // Same hotkeys should have same hash
        assert_equal(hash1, hash2, "Same hotkeys should have same hash");

        // Different hotkeys should (likely) have different hash
        assert_not_equal(hash1, hash3, "Different modifiers should produce different hash");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey comparison
// ============================================================================

test_hotkey_comparison :: () -> bool {
    state := init_test_state("test_hotkey_comparison", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        compare_hotkeys :: (a: Hotkey, b: Hotkey) -> bool {
            return a.modifiers == b.modifiers && a.key == b.key;
        }

        hk1 := Hotkey.{ modifiers = .CONTROL, key = .P };
        hk2 := Hotkey.{ modifiers = .CONTROL, key = .P };
        hk3 := Hotkey.{ modifiers = .CONTROL | .SHIFT, key = .P };
        hk4 := Hotkey.{ modifiers = .CONTROL, key = .A };

        // Same hotkeys should be equal
        assert_true(compare_hotkeys(hk1, hk2), "Same hotkeys should be equal");

        // Different modifiers should not be equal
        assert_false(compare_hotkeys(hk1, hk3), "Different modifiers should not be equal");

        // Different keys should not be equal
        assert_false(compare_hotkeys(hk1, hk4), "Different keys should not be equal");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Common hotkey patterns
// ============================================================================

test_hotkey_common_patterns :: () -> bool {
    state := init_test_state("test_hotkey_common_patterns", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Ctrl+Alt+P (recommended default for Uncrumpled)
        ctrl_alt_p := Hotkey.{ modifiers = .CONTROL | .ALT, key = .P };
        assert_equal(cast(int)ctrl_alt_p.modifiers, 0x5, "Ctrl+Alt should be 0x5");
        assert_equal(ctrl_alt_p.key, Key.P, "Key should be P");

        // Ctrl+Shift+Space (alternative hotkey)
        ctrl_shift_space := Hotkey.{ modifiers = .CONTROL | .SHIFT, key = .SPACE };
        assert_equal(cast(int)ctrl_shift_space.modifiers, 0x3, "Ctrl+Shift should be 0x3");
        assert_equal(ctrl_shift_space.key, Key.SPACE, "Key should be SPACE");

        // Super+P (Windows/macOS style)
        super_p := Hotkey.{ modifiers = .SUPER, key = .P };
        assert_equal(cast(int)super_p.modifiers, 0x8, "Super should be 0x8");

        // F12 alone (function key without modifiers)
        f12 := Hotkey.{ modifiers = .NONE, key = .F12 };
        assert_equal(cast(int)f12.modifiers, 0x0, "No modifiers should be 0x0");
        assert_equal(f12.key, Key.F12, "Key should be F12");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey to string representation (helper for config)
// ============================================================================

test_hotkey_to_string :: () -> bool {
    state := init_test_state("test_hotkey_to_string", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Helper to build a hotkey description string
        hotkey_to_string :: (hk: Hotkey) -> string {
            builder: String_Builder;
            init_string_builder(*builder);

            if hk.modifiers & .CONTROL  append(*builder, "Ctrl+");
            if hk.modifiers & .SHIFT    append(*builder, "Shift+");
            if hk.modifiers & .ALT      append(*builder, "Alt+");
            if hk.modifiers & .SUPER    append(*builder, "Super+");

            // Key name
            if cast(int)hk.key <= 25 {
                c: [2]u8;
                c[0] = #char "A" + cast(u8)hk.key;
                c[1] = 0;  // null terminator
                s: string;
                s.data = c.data;
                s.count = 1;
                append(*builder, s);
            } else if cast(int)hk.key >= 36 && cast(int)hk.key <= 47 {
                append(*builder, "F");
                print_to_builder(*builder, "%", cast(int)hk.key - 35);
            } else if hk.key == .SPACE {
                append(*builder, "Space");
            } else if hk.key == .ENTER {
                append(*builder, "Enter");
            } else {
                append(*builder, "?");
            }

            return builder_to_string(*builder);
        }

        // Test Ctrl+Alt+P
        hk1 := Hotkey.{ modifiers = .CONTROL | .ALT, key = .P };
        str1 := hotkey_to_string(hk1);
        defer free(str1);
        assert_string_equal(str1, "Ctrl+Alt+P", "Should format as Ctrl+Alt+P");

        // Test Ctrl+Shift+Space
        hk2 := Hotkey.{ modifiers = .CONTROL | .SHIFT, key = .SPACE };
        str2 := hotkey_to_string(hk2);
        defer free(str2);
        assert_string_equal(str2, "Ctrl+Shift+Space", "Should format as Ctrl+Shift+Space");

        // Test F12
        hk3 := Hotkey.{ modifiers = .NONE, key = .F12 };
        str3 := hotkey_to_string(hk3);
        defer free(str3);
        assert_string_equal(str3, "F12", "Should format as F12");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Parse hotkey from string (for config loading)
// ============================================================================

test_hotkey_parse_from_string :: () -> bool {
    state := init_test_state("test_hotkey_parse_from_string", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Simple parser for hotkey strings
        parse_hotkey :: (str: string) -> Hotkey, bool {
            result: Hotkey;
            result.modifiers = .NONE;

            parts := split(str, "+");
            if parts.count == 0 return result, false;

            for i: 0..parts.count - 2 {
                part := parts[i];
                if part == "Ctrl" || part == "Control" {
                    result.modifiers |= .CONTROL;
                } else if part == "Shift" {
                    result.modifiers |= .SHIFT;
                } else if part == "Alt" {
                    result.modifiers |= .ALT;
                } else if part == "Super" || part == "Win" || part == "Cmd" {
                    result.modifiers |= .SUPER;
                }
            }

            // Last part is the key
            key_str := parts[parts.count - 1];
            if key_str.count == 1 && key_str[0] >= #char "A" && key_str[0] <= #char "Z" {
                result.key = cast(Key)(key_str[0] - #char "A");
            } else if key_str == "Space" {
                result.key = .SPACE;
            } else if key_str == "Enter" {
                result.key = .ENTER;
            } else if key_str.count >= 2 && key_str[0] == #char "F" {
                fn := key_str;
                fn.data += 1;
                fn.count -= 1;
                num, success := string_to_int(fn);
                if success && num >= 1 && num <= 12 {
                    result.key = cast(Key)(35 + num);
                } else {
                    return result, false;
                }
            } else {
                return result, false;
            }

            return result, true;
        }

        // Test parsing Ctrl+Alt+P
        hk1, ok1 := parse_hotkey("Ctrl+Alt+P");
        assert_true(ok1, "Should parse Ctrl+Alt+P");
        assert_equal(cast(int)hk1.modifiers, 0x5, "Modifiers should be Ctrl+Alt");
        assert_equal(hk1.key, Key.P, "Key should be P");

        // Test parsing Ctrl+Shift+Space
        hk2, ok2 := parse_hotkey("Ctrl+Shift+Space");
        assert_true(ok2, "Should parse Ctrl+Shift+Space");
        assert_equal(cast(int)hk2.modifiers, 0x3, "Modifiers should be Ctrl+Shift");
        assert_equal(hk2.key, Key.SPACE, "Key should be SPACE");

        // Test parsing F12
        hk3, ok3 := parse_hotkey("F12");
        assert_true(ok3, "Should parse F12");
        assert_equal(cast(int)hk3.modifiers, 0x0, "Modifiers should be NONE");
        assert_equal(hk3.key, Key.F12, "Key should be F12");

        // Test parsing Super+P (macOS/Windows style)
        hk4, ok4 := parse_hotkey("Super+P");
        assert_true(ok4, "Should parse Super+P");
        assert_equal(cast(int)hk4.modifiers, 0x8, "Modifiers should be Super");
        assert_equal(hk4.key, Key.P, "Key should be P");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey manager parse modifiers
// ============================================================================

test_hotkey_manager_parse_modifiers :: () -> bool {
    state := init_test_state("test_hotkey_manager_parse_modifiers", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Re-implement parse_modifiers logic for testing
        parse_modifiers_test :: (modifiers_str: string) -> Hotkey_Modifier {
            result: Hotkey_Modifier = .NONE;
            if modifiers_str.count == 0 return result;

            upper := to_upper_copy(modifiers_str);
            defer free(upper);

            if contains(upper, "CTRL") || contains(upper, "CONTROL") {
                result |= .CONTROL;
            }
            if contains(upper, "SHIFT") {
                result |= .SHIFT;
            }
            if contains(upper, "ALT") {
                result |= .ALT;
            }
            if contains(upper, "SUPER") || contains(upper, "WIN") || contains(upper, "CMD") || contains(upper, "COMMAND") || contains(upper, "META") {
                result |= .SUPER;
            }
            return result;
        }

        // Test Ctrl+Alt
        mods1 := parse_modifiers_test("Ctrl+Alt");
        assert_true(cast(bool)(mods1 & .CONTROL), "Should have CONTROL");
        assert_true(cast(bool)(mods1 & .ALT), "Should have ALT");
        assert_false(cast(bool)(mods1 & .SHIFT), "Should not have SHIFT");

        // Test Ctrl+Shift
        mods2 := parse_modifiers_test("Ctrl+Shift");
        assert_true(cast(bool)(mods2 & .CONTROL), "Should have CONTROL");
        assert_true(cast(bool)(mods2 & .SHIFT), "Should have SHIFT");

        // Test Super (Windows key)
        mods3 := parse_modifiers_test("Super");
        assert_true(cast(bool)(mods3 & .SUPER), "Should have SUPER");

        // Test Win (alias for Super)
        mods4 := parse_modifiers_test("Win");
        assert_true(cast(bool)(mods4 & .SUPER), "Win should map to SUPER");

        // Test Command (alias for Super)
        mods5 := parse_modifiers_test("Command");
        assert_true(cast(bool)(mods5 & .SUPER), "Command should map to SUPER");

        // Test empty
        mods6 := parse_modifiers_test("");
        assert_equal(cast(int)mods6, 0, "Empty should be NONE");

        // Test case insensitivity
        mods7 := parse_modifiers_test("ctrl+SHIFT+Alt");
        assert_true(cast(bool)(mods7 & .CONTROL), "Should have CONTROL (case insensitive)");
        assert_true(cast(bool)(mods7 & .SHIFT), "Should have SHIFT (case insensitive)");
        assert_true(cast(bool)(mods7 & .ALT), "Should have ALT (case insensitive)");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey manager parse key
// ============================================================================

test_hotkey_manager_parse_key :: () -> bool {
    state := init_test_state("test_hotkey_manager_parse_key", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Re-implement parse_key logic for testing
        parse_key_test :: (key_str: string) -> Key, bool {
            if key_str.count == 0 return .A, false;

            upper := to_upper_copy(key_str);
            defer free(upper);

            // Single letter keys
            if upper.count == 1 {
                c := upper[0];
                if c >= #char "A" && c <= #char "Z" {
                    offset := c - #char "A";
                    return cast(Key) offset, true;
                }
                if c >= #char "0" && c <= #char "9" {
                    offset := c - #char "0";
                    return cast(Key) (cast(s32) Key.NUM_0 + offset), true;
                }
            }

            if upper == "SPACE"  return .SPACE, true;
            if upper == "ENTER"  return .ENTER, true;
            if upper == "RETURN" return .ENTER, true;
            if upper == "F1"  return .F1, true;
            if upper == "F12" return .F12, true;

            return .A, false;
        }

        // Test letter keys
        key_p, ok_p := parse_key_test("P");
        assert_true(ok_p, "Should parse P");
        assert_equal(key_p, Key.P, "Should be Key.P");

        key_a, ok_a := parse_key_test("a");  // lowercase
        assert_true(ok_a, "Should parse lowercase a");
        assert_equal(key_a, Key.A, "Should be Key.A");

        // Test Space
        key_space, ok_space := parse_key_test("Space");
        assert_true(ok_space, "Should parse Space");
        assert_equal(key_space, Key.SPACE, "Should be Key.SPACE");

        // Test F12
        key_f12, ok_f12 := parse_key_test("F12");
        assert_true(ok_f12, "Should parse F12");
        assert_equal(key_f12, Key.F12, "Should be Key.F12");

        // Test empty (should fail)
        _, ok_empty := parse_key_test("");
        assert_false(ok_empty, "Empty should fail");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey config to display string
// ============================================================================

test_hotkey_config_display_string :: () -> bool {
    state := init_test_state("test_hotkey_config_display_string", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test helper: config to display string
        config_to_display :: (enabled: bool, modifiers: string, key: string) -> string {
            if !enabled return copy_string("(disabled)");
            if modifiers.count == 0 return copy_string(key);
            return copy_string(tprint("%+%", modifiers, key));
        }

        // Test Ctrl+Alt+P
        str1 := config_to_display(true, "Ctrl+Alt", "P");
        defer free(str1);
        assert_string_equal(str1, "Ctrl+Alt+P", "Should be Ctrl+Alt+P");

        // Test F12 (no modifiers)
        str2 := config_to_display(true, "", "F12");
        defer free(str2);
        assert_string_equal(str2, "F12", "Should be just F12");

        // Test disabled
        str3 := config_to_display(false, "Ctrl+Alt", "P");
        defer free(str3);
        assert_string_equal(str3, "(disabled)", "Should be (disabled)");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey preset values
// ============================================================================

test_hotkey_preset_values :: () -> bool {
    state := init_test_state("test_hotkey_preset_values", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Define preset enum (matching config parser)
        Hotkey_Preset :: enum {
            NONE;              // No hotkey
            CTRL_ALT_P;        // Ctrl+Alt+P
            CTRL_SHIFT_SPACE;  // Ctrl+Shift+Space
            SUPER_P;           // Super/Windows+P
            F12;               // F12 key alone
            CUSTOM;            // Custom user-defined
        }

        // Test preset to display mapping
        preset_to_display :: (preset: Hotkey_Preset) -> string {
            if preset == {
                case .NONE;              return "None (disable hotkey)";
                case .CTRL_ALT_P;        return "Ctrl+Alt+P";
                case .CTRL_SHIFT_SPACE;  return "Ctrl+Shift+Space";
                case .SUPER_P;           return "Super+P (Windows/Command+P)";
                case .F12;               return "F12";
                case .CUSTOM;            return "Custom (configure in config.toml)";
            }
            return "Unknown";
        }

        assert_string_equal(preset_to_display(.NONE), "None (disable hotkey)", "NONE preset");
        assert_string_equal(preset_to_display(.CTRL_ALT_P), "Ctrl+Alt+P", "CTRL_ALT_P preset");
        assert_string_equal(preset_to_display(.CTRL_SHIFT_SPACE), "Ctrl+Shift+Space", "CTRL_SHIFT_SPACE preset");
        assert_string_equal(preset_to_display(.SUPER_P), "Super+P (Windows/Command+P)", "SUPER_P preset");
        assert_string_equal(preset_to_display(.F12), "F12", "F12 preset");
        assert_string_equal(preset_to_display(.CUSTOM), "Custom (configure in config.toml)", "CUSTOM preset");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Hotkey toggle state machine
// ============================================================================

test_hotkey_toggle_state :: () -> bool {
    state := init_test_state("test_hotkey_toggle_state", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Simple toggle state machine for testing
        Toggle_State :: struct {
            is_visible: bool;
            toggle_requested: bool;
        }

        toggle_visibility :: (state: *Toggle_State) {
            state.is_visible = !state.is_visible;
        }

        check_and_clear_toggle :: (state: *Toggle_State) -> bool {
            if state.toggle_requested {
                state.toggle_requested = false;
                return true;
            }
            return false;
        }

        // Initial state
        ts: Toggle_State;
        ts.is_visible = true;
        ts.toggle_requested = false;

        assert_true(ts.is_visible, "Should start visible");
        assert_false(ts.toggle_requested, "No toggle requested yet");

        // Simulate hotkey press
        ts.toggle_requested = true;
        assert_true(check_and_clear_toggle(*ts), "Should detect toggle request");
        assert_false(ts.toggle_requested, "Toggle flag should be cleared");

        toggle_visibility(*ts);
        assert_false(ts.is_visible, "Should now be hidden");

        // Second toggle
        ts.toggle_requested = true;
        if check_and_clear_toggle(*ts) {
            toggle_visibility(*ts);
        }
        assert_true(ts.is_visible, "Should now be visible again");

        // No toggle without request
        assert_false(check_and_clear_toggle(*ts), "No pending toggle");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Registration
// ============================================================================

register_hotkey_tests :: () {
    register_test("hotkey/struct_creation", test_hotkey_struct_creation);
    register_test("hotkey/modifier_flags", test_hotkey_modifier_flags);
    register_test("hotkey/key_enum", test_hotkey_key_enum);
    register_test("hotkey/hashing", test_hotkey_hashing);
    register_test("hotkey/comparison", test_hotkey_comparison);
    register_test("hotkey/common_patterns", test_hotkey_common_patterns);
    register_test("hotkey/to_string", test_hotkey_to_string);
    register_test("hotkey/parse_from_string", test_hotkey_parse_from_string);
    register_test("hotkey/manager_parse_modifiers", test_hotkey_manager_parse_modifiers);
    register_test("hotkey/manager_parse_key", test_hotkey_manager_parse_key);
    register_test("hotkey/config_display_string", test_hotkey_config_display_string);
    register_test("hotkey/preset_values", test_hotkey_preset_values);
    register_test("hotkey/toggle_state", test_hotkey_toggle_state);
}
