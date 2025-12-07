// POSIX-style Argument Parser
//
// Parses context input strings like:
//   work --mode=programming -v --debug
//   gaming --profile=competitive
//   personal
//
// Supports:
//   - Long options: --key=value, --key value
//   - Long flags: --flag (boolean, no value)
//   - Short flags: -f (boolean)
//   - Combined short flags: -abc (equivalent to -a -b -c)
//   - Short options: -k value
//   - Quoted values: --msg="hello world"

#import "Basic";
#import "String";
#import "Hash_Table";

// ============================================================================
// Types
// ============================================================================

Arg_Value :: struct {
    value: string;      // The value (empty for flags)
    is_flag: bool;      // True if this is a boolean flag
    short_name: string; // Original short form if used (e.g., "v" for -v)
}

Parsed_Input :: struct {
    name: string;                       // Context name (first token)
    args: Table(string, Arg_Value);     // Parsed arguments
    raw: string;                        // Original input string
    success: bool;
    error: string;
}

// ============================================================================
// Parser State
// ============================================================================

Parser_State :: struct {
    input: string;
    pos: s64;
    tokens: [..] string;
    current_token: s64;
}

// ============================================================================
// Main API
// ============================================================================

// Parse a context input string
// Returns a Parsed_Input with the context name and arguments
parse_context_input :: (input: string) -> Parsed_Input {
    result: Parsed_Input;
    result.raw = copy_string(input);
    result.success = false;

    trimmed := trim(input);
    if trimmed.count == 0 {
        result.error = copy_string("Empty input");
        return result;
    }

    // Tokenize the input
    tokens := tokenize(trimmed);
    defer array_free(tokens);

    if tokens.count == 0 {
        result.error = copy_string("No tokens found");
        return result;
    }

    // First token must be the context name (no dashes)
    first := tokens[0];
    if begins_with(first, "-") {
        result.error = copy_string("Context name required before arguments");
        return result;
    }

    result.name = copy_string(first);

    // Parse remaining tokens as arguments
    i := 1;
    while i < tokens.count {
        token := tokens[i];

        if begins_with(token, "--") {
            // Long option or flag
            success, err := parse_long_option(*result, tokens, *i);
            if !success {
                result.error = copy_string(err);
                return result;
            }
        } else if begins_with(token, "-") && token.count > 1 {
            // Short option(s) or flag(s)
            success, err := parse_short_option(*result, tokens, *i);
            if !success {
                result.error = copy_string(err);
                return result;
            }
        } else {
            // Positional argument - not supported, error
            result.error = copy_string(tprint("Unexpected positional argument: %", token));
            return result;
        }
    }

    result.success = true;
    return result;
}

// Free a Parsed_Input's allocated memory
free_parsed_input :: (parsed: *Parsed_Input) {
    free(parsed.name);
    free(parsed.raw);
    free(parsed.error);

    for parsed.args {
        free(it.value);
        free(it.short_name);
        free(it_index);  // Free the key
    }
    deinit(*parsed.args);
}

// Check if an argument exists (flag or option)
has_arg :: (parsed: *Parsed_Input, name: string) -> bool {
    found, _ := table_find(*parsed.args, name);
    return found;
}

// Get an argument value (returns empty string for flags)
get_arg :: (parsed: *Parsed_Input, name: string) -> string, bool {
    found, val := table_find(*parsed.args, name);
    if found {
        return val.value, true;
    }
    return "", false;
}

// Check if an argument is a flag (boolean, no value)
is_flag :: (parsed: *Parsed_Input, name: string) -> bool {
    found, val := table_find(*parsed.args, name);
    if found {
        return val.is_flag;
    }
    return false;
}

// ============================================================================
// Tokenizer
// ============================================================================

// Tokenize input respecting quotes
tokenize :: (input: string) -> [..] string {
    tokens: [..] string;

    i := 0;
    while i < input.count {
        // Skip whitespace
        while i < input.count && is_whitespace(input[i]) {
            i += 1;
        }

        if i >= input.count break;

        // Check for quoted string
        if input[i] == #char "\"" || input[i] == #char "'" {
            quote_char := input[i];
            i += 1;  // Skip opening quote
            start := i;

            while i < input.count && input[i] != quote_char {
                i += 1;
            }

            token := slice(input, start, i - start);
            array_add(*tokens, copy_string(token));

            if i < input.count {
                i += 1;  // Skip closing quote
            }
        } else {
            // Regular token
            start := i;
            while i < input.count && !is_whitespace(input[i]) {
                // Handle inline quotes in --key="value"
                if input[i] == #char "\"" || input[i] == #char "'" {
                    quote_char := input[i];
                    i += 1;
                    while i < input.count && input[i] != quote_char {
                        i += 1;
                    }
                    if i < input.count {
                        i += 1;  // Skip closing quote
                    }
                } else {
                    i += 1;
                }
            }

            token := slice(input, start, i - start);
            array_add(*tokens, copy_string(token));
        }
    }

    return tokens;
}

is_whitespace :: (c: u8) -> bool {
    return c == #char " " || c == #char "\t" || c == #char "\n" || c == #char "\r";
}

// ============================================================================
// Option Parsing
// ============================================================================

// Parse a long option (--key=value or --flag)
parse_long_option :: (result: *Parsed_Input, tokens: [] string, index: *s64) -> bool, string {
    token := tokens[<<index];
    <<index += 1;

    // Remove leading --
    option_part := slice(token, 2, token.count - 2);

    if option_part.count == 0 {
        return false, "Empty option name after --";
    }

    // Check for = in the option
    eq_pos := find_index_from_left(option_part, #char "=");

    if eq_pos >= 0 {
        // --key=value format
        key := slice(option_part, 0, eq_pos);
        value_part := slice(option_part, eq_pos + 1, option_part.count - eq_pos - 1);

        // Remove quotes from value if present
        value := strip_quotes(value_part);

        arg: Arg_Value;
        arg.value = copy_string(value);
        arg.is_flag = false;

        table_set(*result.args, copy_string(key), arg);
    } else {
        // Could be a flag, or --key value format
        // Check if next token exists and isn't an option
        if <<index < tokens.count && !begins_with(tokens[<<index], "-") {
            // --key value format
            value := strip_quotes(tokens[<<index]);
            <<index += 1;

            arg: Arg_Value;
            arg.value = copy_string(value);
            arg.is_flag = false;

            table_set(*result.args, copy_string(option_part), arg);
        } else {
            // It's a flag
            arg: Arg_Value;
            arg.value = copy_string("");
            arg.is_flag = true;

            table_set(*result.args, copy_string(option_part), arg);
        }
    }

    return true, "";
}

// Parse short option(s) (-f, -abc, -k value)
parse_short_option :: (result: *Parsed_Input, tokens: [] string, index: *s64) -> bool, string {
    token := tokens[<<index];
    <<index += 1;

    // Remove leading -
    flags := slice(token, 1, token.count - 1);

    if flags.count == 0 {
        return false, "Empty option name after -";
    }

    // Single character could be a flag or option with value
    if flags.count == 1 {
        flag_name := slice(flags, 0, 1);

        // Check if next token is a value (not starting with -)
        if <<index < tokens.count && !begins_with(tokens[<<index], "-") {
            // -k value format
            value := strip_quotes(tokens[<<index]);
            <<index += 1;

            arg: Arg_Value;
            arg.value = copy_string(value);
            arg.is_flag = false;
            arg.short_name = copy_string(flag_name);

            table_set(*result.args, copy_string(flag_name), arg);
        } else {
            // It's a flag
            arg: Arg_Value;
            arg.value = copy_string("");
            arg.is_flag = true;
            arg.short_name = copy_string(flag_name);

            table_set(*result.args, copy_string(flag_name), arg);
        }
    } else {
        // Multiple characters: -abc means -a -b -c (all flags)
        for i: 0..flags.count-1 {
            flag_name := slice(flags, i, 1);

            arg: Arg_Value;
            arg.value = copy_string("");
            arg.is_flag = true;
            arg.short_name = copy_string(flag_name);

            table_set(*result.args, copy_string(flag_name), arg);
        }
    }

    return true, "";
}

// Remove surrounding quotes from a string
strip_quotes :: (s: string) -> string {
    if s.count < 2 return s;

    first := s[0];
    last := s[s.count - 1];

    if (first == #char "\"" && last == #char "\"") ||
       (first == #char "'" && last == #char "'") {
        return slice(s, 1, s.count - 2);
    }

    return s;
}

// ============================================================================
// Utility
// ============================================================================

// Convert parsed input back to a canonical string form
to_string :: (parsed: *Parsed_Input) -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    append(*builder, parsed.name);

    for parsed.args {
        append(*builder, " ");

        key := it_index;
        val := it;

        if val.is_flag {
            if key.count == 1 {
                append(*builder, "-");
            } else {
                append(*builder, "--");
            }
            append(*builder, key);
        } else {
            if key.count == 1 {
                append(*builder, "-");
                append(*builder, key);
                append(*builder, " ");
            } else {
                append(*builder, "--");
                append(*builder, key);
                append(*builder, "=");
            }

            // Quote value if it contains spaces
            if contains(val.value, " ") {
                append(*builder, "\"");
                append(*builder, val.value);
                append(*builder, "\"");
            } else {
                append(*builder, val.value);
            }
        }
    }

    return builder_to_string(*builder);
}
