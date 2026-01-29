# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Modern C++ template project with library, executable, and test structure. Uses C++20 standard with GoogleTest for testing and Taskflow for parallel programming.

## Build Commands

```bash
# Debug build (default)
cmake --preset default
cmake --build build

# Release build
cmake --preset release
cmake --build build-release

# TDD with Thread Sanitizer (recommended for Taskflow)
cmake --preset tdd-tsan
cmake --build build-tdd-tsan

# TDD with Address Sanitizer + Coverage
cmake --preset tdd-asan
cmake --build build-tdd-asan
```

## Testing

```bash
# Run all tests
ctest --test-dir build-tdd-tsan --output-on-failure

# Run tests by label
ctest --test-dir build-tdd-tsan -L unit

# Run specific test pattern
ctest --test-dir build-tdd-tsan -R "TestName"
```

## Code Coverage

```bash
cmake --preset tdd-asan
cmake --build build-tdd-asan
cmake --build build-tdd-asan --target coverage
# Report: build-tdd-asan/coverage/index.html
```

## Code Quality

```bash
# Check formatting
clang-format --dry-run -Werror src/*.cpp include/mylib/*.hpp

# Apply formatting
clang-format -i src/*.cpp include/mylib/*.hpp app/*.cpp tests/*.cpp

# Static analysis
clang-tidy src/*.cpp -p build
```

## Project Structure

```
include/mylib/    Public headers
src/              Library implementation (mylib)
app/              Application executable
tests/            Unit tests (GoogleTest)
cmake/            CMake modules (Coverage.cmake)
```

## Key Files

- `CMakeLists.txt` - Root build configuration
- `CMakePresets.json` - Build presets (default, release, tdd-tsan, tdd-asan)
- `.clang-format` - Code formatting rules (Google style)
- `.clang-tidy` - Static analysis configuration

## Style Guide

Follows Google C++ Style Guide:
- `CamelCase` for classes, structs, functions
- `snake_case` for variables, parameters
- `kConstantName` for constants
- No exceptions, no RTTI
