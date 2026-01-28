# C++ Tooling

This project uses clang-format and clang-tidy for C++ code quality.

## Installation

```bash
sudo apt install clang-format clang-tidy
```

## Configuration Files

| File | Purpose |
|------|---------|
| `.clang-format` | Code formatting rules (Google style) |
| `.clang-tidy` | Static analysis checks |

## Formatting

### Format C++ Code

```bash
# Format all source files
clang-format -i src/*.cpp include/mylib/*.hpp

# Check formatting (CI)
clang-format --dry-run -Werror src/*.cpp include/mylib/*.hpp
```

Returns non-zero if code is not formatted correctly.

## Linting

### Run clang-tidy

```bash
# Lint source files (uses compile_commands.json from build dir)
clang-tidy -p build src/*.cpp

# Filter to only project code (exclude external header warnings)
clang-tidy -p build src/*.cpp --header-filter='include/.*'
```

### Common Warnings and Fixes

| Warning | Fix |
|---------|-----|
| `google-build-using-namespace` | Use specific `using` declarations instead of `using namespace` |
| `performance-avoid-endl` | Use `'\n'` instead of `std::endl` |
| `misc-const-correctness` | Add `const` to variables that don't change |
| `readability-identifier-naming` | Follow Google naming conventions |

### Suppressing Warnings

Use `// NOLINT(check-name)` for intentional exceptions:

```cpp
using namespace std::chrono_literals;  // NOLINT(google-build-using-namespace)
```

## Pre-Commit Checklist

Before committing C++ code:

1. **Format**: `clang-format -i src/*.cpp include/mylib/*.hpp`
2. **Lint**: `clang-tidy -p build src/*.cpp`
3. **Build**: `cmake --build build`
4. **Test**: `ctest --test-dir build --output-on-failure`

## CMake Integration

The CMakeLists.txt can include custom targets:

```cmake
# Find clang-format
find_program(CLANG_FORMAT clang-format)

# Collect all source files
file(GLOB_RECURSE ALL_SOURCE_FILES
    ${CMAKE_SOURCE_DIR}/src/*.cpp
    ${CMAKE_SOURCE_DIR}/include/*.hpp
)

# Format target (in-place modification)
add_custom_target(format
    COMMAND ${CLANG_FORMAT} -i ${ALL_SOURCE_FILES}
    COMMENT "Formatting C++ code with clang-format"
)

# Format check target (verification only)
add_custom_target(format-check
    COMMAND ${CLANG_FORMAT} --dry-run --Werror ${ALL_SOURCE_FILES}
    COMMENT "Checking C++ code formatting"
)
```

## IDE Integration

### VS Code

Install the "clangd" extension for real-time linting and formatting.

Add to `.vscode/settings.json`:

```json
{
  "clangd.arguments": [
    "--compile-commands-dir=${workspaceFolder}/build"
  ],
  "editor.formatOnSave": true,
  "[cpp]": {
    "editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd"
  }
}
```

### CLion

CLion automatically detects `.clang-format` and `.clang-tidy` files.
