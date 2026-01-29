cmake_minimum_required(VERSION 3.28)

# Use new timestamp behavior for FetchContent downloads
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

project(taskflow_cpp_template VERSION 0.2.0 LANGUAGES CXX)

# C++20 standard (GoogleTest requires C++17 minimum)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands for clang-tidy and IDEs
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Threading support (required for Taskflow)
find_package(Threads REQUIRED)

# Taskflow library (header-only)
set(TF_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(TF_BUILD_TESTS OFF CACHE BOOL "" FORCE)
add_subdirectory(ext/taskflow)

# Options
option(BUILD_TESTING "Build tests" ON)
option(ENABLE_COVERAGE "Enable code coverage" OFF)

# Include custom CMake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

# Coverage configuration
if(ENABLE_COVERAGE)
    include(Coverage)
endif()

# Library
add_subdirectory(src)

# Executable
add_subdirectory(app)

# Testing
if(BUILD_TESTING)
    enable_testing()
    include(FetchContent)
    # GoogleTest v1.15.2 (2024-07-31)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/b514bdc898e2951020cbdca1304b75f5950d1f59.zip
    )
    # For Windows: Prevent overriding the parent project's compiler/linker settings
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    add_subdirectory(tests)
endif()
