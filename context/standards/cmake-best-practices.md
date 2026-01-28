# CMake Best Practices

Modern CMake (3.14+) best practices for C++ projects.

## Modern CMake Philosophy

### Target-Based Approach

Modern CMake uses **targets** as the central abstraction:
- Define targets with `add_library()` or `add_executable()`
- Set properties on targets, not globally
- Express dependencies between targets

```cmake
# Modern (target-based)
add_library(mylib src/mylib.cpp)
target_include_directories(mylib PUBLIC include)
target_compile_features(mylib PUBLIC cxx_std_20)

# Avoid (global scope)
include_directories(include)        # Don't do this
set(CMAKE_CXX_STANDARD 20)          # Prefer target_compile_features
```

### Usage Requirements

Properties propagate through `target_link_libraries()`:

| Scope | Meaning |
|-------|---------|
| `PRIVATE` | Used only when building this target |
| `PUBLIC` | Used when building this target AND by consumers |
| `INTERFACE` | Used only by consumers, not when building this target |

```cmake
add_library(mylib src/mylib.cpp)

# Include directories
target_include_directories(mylib
    PUBLIC  include           # Consumers see public headers
    PRIVATE src              # Only mylib sees internal headers
)

# Link dependencies
target_link_libraries(mylib
    PUBLIC  fmt::fmt         # Consumers also need fmt
    PRIVATE nlohmann_json    # Only mylib uses internally
)
```

## Project Structure

### Recommended Layout

```
project/
├── CMakeLists.txt           # Root CMake file
├── CMakePresets.json        # Build presets
├── cmake/                   # CMake modules
│   ├── Coverage.cmake
│   └── CompilerWarnings.cmake
├── include/                 # Public headers
│   └── mylib/
│       └── mylib.hpp
├── src/                     # Library sources
│   ├── CMakeLists.txt
│   └── mylib.cpp
├── app/                     # Application sources
│   ├── CMakeLists.txt
│   └── main.cpp
└── tests/                   # Test sources
    ├── CMakeLists.txt
    └── test_mylib.cpp
```

### Root CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.14)

# Policy for FetchContent timestamps
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

project(myproject VERSION 0.1.0 LANGUAGES CXX)

# Project-wide settings
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Generate compile_commands.json for tools
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Include custom modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

# Add subdirectories
add_subdirectory(src)
add_subdirectory(app)

# Testing (optional)
option(BUILD_TESTING "Build tests" ON)
if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()
```

## Dependencies with FetchContent

### Basic Usage

```cmake
include(FetchContent)

FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        e39786088138f2749d64e9571571e7a5d79ce4e6  # v1.14.0
)

FetchContent_MakeAvailable(googletest)
```

### Best Practices

1. **Use commit hashes over tags** for reproducibility and security
2. **Check if already available** to support system installations
3. **Group declarations** for parallel downloads

```cmake
include(FetchContent)

# Check if already available (e.g., via package manager)
find_package(GTest QUIET)
if(NOT GTest_FOUND)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        e39786088138f2749d64e9571571e7a5d79ce4e6
    )
endif()

FetchContent_Declare(
    fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG        e69e5f977d458f2650bb346dadf2ad30c5320281  # 10.2.1
)

# Download all at once (parallel)
FetchContent_MakeAvailable(googletest fmt)
```

## CMake Presets

### CMakePresets.json

```json
{
    "version": 6,
    "cmakeMinimumRequired": {
        "major": 3,
        "minor": 21,
        "patch": 0
    },
    "configurePresets": [
        {
            "name": "default",
            "displayName": "Debug Build",
            "binaryDir": "${sourceDir}/build",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Debug",
                "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
            }
        },
        {
            "name": "release",
            "displayName": "Release Build",
            "binaryDir": "${sourceDir}/build-release",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Release"
            }
        },
        {
            "name": "tdd",
            "displayName": "TDD Development",
            "binaryDir": "${sourceDir}/build-tdd",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Debug",
                "ENABLE_COVERAGE": "ON",
                "ENABLE_SANITIZERS": "ON"
            }
        }
    ],
    "buildPresets": [
        {
            "name": "default",
            "configurePreset": "default"
        },
        {
            "name": "release",
            "configurePreset": "release"
        },
        {
            "name": "tdd",
            "configurePreset": "tdd"
        }
    ],
    "testPresets": [
        {
            "name": "default",
            "configurePreset": "default",
            "output": {"outputOnFailure": true}
        },
        {
            "name": "tdd",
            "configurePreset": "tdd",
            "output": {"outputOnFailure": true}
        }
    ]
}
```

### Using Presets

```bash
# Configure with preset
cmake --preset default

# Build with preset
cmake --build --preset default

# Test with preset
ctest --preset default
```

## Testing with CTest

### Basic Setup

```cmake
enable_testing()

add_executable(tests
    tests/test_mylib.cpp
)
target_link_libraries(tests
    PRIVATE mylib GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(tests
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    PROPERTIES
        TIMEOUT 10
        LABELS "unit"
)
```

### Test Labels

```cmake
gtest_discover_tests(unit_tests
    PROPERTIES LABELS "unit"
)

gtest_discover_tests(integration_tests
    PROPERTIES LABELS "integration"
)
```

Run by label:
```bash
ctest --test-dir build -L unit
ctest --test-dir build -L integration
```

## Code Coverage

### Coverage.cmake Module

```cmake
# cmake/Coverage.cmake
option(ENABLE_COVERAGE "Enable code coverage" OFF)

if(ENABLE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(--coverage -O0 -g)
        add_link_options(--coverage)
    else()
        message(WARNING "Coverage not supported for this compiler")
    endif()
endif()

# Custom target for generating coverage report
find_program(LCOV lcov)
find_program(GENHTML genhtml)

if(LCOV AND GENHTML)
    add_custom_target(coverage
        COMMAND ${LCOV} --capture --directory . --output-file coverage.info
        COMMAND ${LCOV} --remove coverage.info '/usr/*' '*/test/*' '*/googletest/*'
                --output-file coverage.info
        COMMAND ${GENHTML} coverage.info --output-directory coverage
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating code coverage report"
    )
endif()
```

### Usage

```cmake
include(Coverage)
```

```bash
cmake --preset tdd
cmake --build build-tdd
ctest --test-dir build-tdd
cmake --build build-tdd --target coverage
```

## Sanitizers

### Sanitizer Options

```cmake
option(ENABLE_SANITIZERS "Enable sanitizers" OFF)

if(ENABLE_SANITIZERS)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer)
        add_link_options(-fsanitize=address,undefined)
    endif()
endif()
```

### Available Sanitizers

| Sanitizer | Flag | Detects |
|-----------|------|---------|
| AddressSanitizer | `-fsanitize=address` | Memory errors, leaks |
| UndefinedBehaviorSanitizer | `-fsanitize=undefined` | Undefined behavior |
| ThreadSanitizer | `-fsanitize=thread` | Data races |
| MemorySanitizer | `-fsanitize=memory` | Uninitialized reads |

## Generator Expressions

### Common Patterns

```cmake
# Different flags per config
target_compile_options(mylib PRIVATE
    $<$<CONFIG:Debug>:-O0 -g>
    $<$<CONFIG:Release>:-O3 -DNDEBUG>
)

# Platform-specific options
target_compile_definitions(mylib PRIVATE
    $<$<PLATFORM_ID:Windows>:WIN32_LEAN_AND_MEAN>
    $<$<PLATFORM_ID:Linux>:_GNU_SOURCE>
)

# Compiler-specific options
target_compile_options(mylib PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra>
    $<$<CXX_COMPILER_ID:Clang>:-Wall -Wextra -Wno-unused-parameter>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

# Build vs Install interface
target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
```

## Compiler Warnings

### CompilerWarnings.cmake Module

```cmake
# cmake/CompilerWarnings.cmake
function(set_project_warnings target)
    set(MSVC_WARNINGS
        /W4
        /WX    # Warnings as errors
        /w14242 /w14254 /w14263 /w14265 /w14287
    )

    set(CLANG_WARNINGS
        -Wall -Wextra -Wpedantic
        -Wshadow -Wcast-align -Wunused
        -Wconversion -Wsign-conversion
        -Wnull-dereference -Wdouble-promotion
        -Wformat=2 -Wimplicit-fallthrough
    )

    set(GCC_WARNINGS
        ${CLANG_WARNINGS}
        -Wmisleading-indentation -Wduplicated-cond
        -Wduplicated-branches -Wlogical-op
    )

    if(MSVC)
        set(WARNINGS ${MSVC_WARNINGS})
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(WARNINGS ${CLANG_WARNINGS})
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(WARNINGS ${GCC_WARNINGS})
    endif()

    target_compile_options(${target} PRIVATE ${WARNINGS})
endfunction()
```

## Common Patterns

### Interface Libraries

For header-only libraries:

```cmake
add_library(header_only INTERFACE)
target_include_directories(header_only INTERFACE include)
target_compile_features(header_only INTERFACE cxx_std_20)
```

### Object Libraries

Share compiled objects between targets:

```cmake
add_library(common_objects OBJECT
    src/util.cpp
    src/logger.cpp
)
target_include_directories(common_objects PUBLIC include)

add_executable(app $<TARGET_OBJECTS:common_objects> app/main.cpp)
add_executable(tests $<TARGET_OBJECTS:common_objects> tests/test.cpp)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Modern Alternative |
|--------------|-------------------|
| `include_directories()` | `target_include_directories()` |
| `add_definitions()` | `target_compile_definitions()` |
| `set(CMAKE_CXX_FLAGS ...)` | `target_compile_options()` |
| `link_libraries()` | `target_link_libraries()` |
| Global `CMAKE_CXX_STANDARD` | `target_compile_features()` |
| `file(GLOB ...)` for sources | Explicit source lists |

## References

- [Modern CMake](https://cliutils.gitlab.io/modern-cmake/)
- [CMake Documentation](https://cmake.org/cmake/help/latest/)
- [Effective CMake](https://www.youtube.com/watch?v=bsXLMQ6WgIk) (CppCon talk)
- [Professional CMake](https://crascit.com/professional-cmake/) (Book)
