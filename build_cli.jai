#import "Basic";
#import "Compiler";
#import "String";

#run build();

build :: () {
    // Disable output for the build script workspace itself
    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("Uncrumpled CLI");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    options := get_build_options(w);
    options.output_executable_name = "uncrumpled-cli";
    options.output_path = "bin";
    options.intermediate_path = "bin/int";

    // Add custom module paths
    import_path: [..] string;
    array_add(*import_path, ..options.import_path);
    array_add(*import_path, "modules");
    options.import_path = import_path;

    set_build_options(options, w);

    compiler_begin_intercept(w);

    add_build_file("src/cli/main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if !message break;

        if message.kind == {
            case .ERROR;
                break;
            case .COMPLETE;
                break;
        }
    }

    compiler_end_intercept(w);
}
