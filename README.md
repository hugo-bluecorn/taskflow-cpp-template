# C++ CMake Template

A modern C++ project template using CMake, GoogleTest, and code quality tools.

## Features

- **C++20** standard
- **CMake** build system with presets
- **GoogleTest** for unit testing (via FetchContent)
- **clang-format** for code formatting (Google style)
- **clang-tidy** for static analysis
- **Code coverage** with gcov/lcov
- **Sanitizers** (AddressSanitizer, UndefinedBehaviorSanitizer)

## Project Structure

```
├── include/mylib/    # Public headers
├── src/              # Library implementation
├── app/              # Application executable
├── tests/            # Unit tests
└── cmake/            # CMake modules
```

## Requirements

- CMake 3.14+
- GCC 13+ or Clang 15+
- lcov (for code coverage)

## Building

### Using CMake Presets

```bash
# Debug build
cmake --preset default
cmake --build build

# Release build
cmake --preset release
cmake --build build-release

# TDD development (with coverage and sanitizers)
cmake --preset tdd
cmake --build build-tdd
```

### Manual Build

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
```

## Testing

```bash
# Run all tests
ctest --test-dir build --output-on-failure

# Run tests by label
ctest --test-dir build -L unit

# Run specific test
ctest --test-dir build -R "GreetTest"
```

## Code Coverage

```bash
# Build with coverage preset
cmake --preset tdd
cmake --build build-tdd

# Generate coverage report
cmake --build build-tdd --target coverage

# View report
open build-tdd/coverage/index.html
```

## Code Quality

```bash
# Check formatting
clang-format --dry-run -Werror src/*.cpp include/mylib/*.hpp

# Apply formatting
clang-format -i src/*.cpp include/mylib/*.hpp

# Run static analysis
clang-tidy src/*.cpp -p build
```

## License

MIT License - see [LICENSE](LICENSE)
