cmake_minimum_required(VERSION 3.22)

project(metal-compute-sample)

    add_subdirectory(deps)

    add_executable(metal-compute-sample main.mm shaders.metal)

    # TODO https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/platform_dependent_issues/HowToUseExistingOSXFrameworks
    target_link_libraries(metal-compute-sample PRIVATE glfw "-framework Metal -framework QuartzCore")

    set_source_files_properties(shaders.metal PROPERTIES LANGUAGE METAL)
    set_target_properties(metal-compute-sample PROPERTIES XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES)
    target_compile_features(metal-compute-sample PRIVATE cxx_std_17)
