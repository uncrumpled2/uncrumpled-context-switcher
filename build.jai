#import "Basic";
#import "Compiler";
#import "String";

#run build();

build :: () {
    w := compiler_create_workspace("Uncrumpled Switcher");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    options := get_build_options(w);
    options.output_executable_name = "uncrumpled";
    options.output_path = "bin";
    options.intermediate_path = "bin/int";
    
    // Optimization levels
    // options.backend = .LLVM; // If available, faster code

    // Add custom module paths for skia bindings
    import_path: [..] string;
    array_add(*import_path, ..options.import_path);
    array_add(*import_path, "modules");
    options.import_path = import_path;

    // Add linker path for libskia.so
    linker_args: [..] string;
    array_add(*linker_args, ..options.additional_linker_arguments);
    array_add(*linker_args, "-Lmodules");
    options.additional_linker_arguments = linker_args;

    set_build_options(options, w);

    compiler_begin_intercept(w);
    
    add_build_file("src/main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if !message break;
        
        if message.kind == .COMPLETE break;
    }

    compiler_end_intercept(w);
}
