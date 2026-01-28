# C++ CMake Template - Claude Code Configuration

## Project Overview

Modern C++20 project template using CMake, GoogleTest, and code quality tools.

## Development Rules

### Mandatory Requirements

1. **TDD is mandatory** - All new features must follow Red-Green-Refactor
2. **Google C++ Style Guide** - Enforced via clang-format and clang-tidy
3. **Feature branches** - Never commit directly to main
4. **CHANGELOG updates** - Required before every commit
5. **Tests must pass** - No commits with failing tests

### TDD Commands

- `/tdd-new <feature>` - Create TDD task and feature notes
- `/tdd-test` - Run tests with phase context
- `/tdd-workflow <task>` - Execute full TDD workflow

### Build Commands

```bash
# Configure and build
cmake --preset default && cmake --build build

# Run tests
ctest --test-dir build --output-on-failure

# TDD build with thread sanitizer (race detection)
cmake --preset tdd-tsan && cmake --build build-tdd-tsan

# TDD build with address sanitizer + coverage
cmake --preset tdd-asan && cmake --build build-tdd-asan

# Generate coverage report
cmake --build build-tdd-asan --target coverage
```

### Code Quality

```bash
# Format code
clang-format -i src/*.cpp include/mylib/*.hpp

# Static analysis
clang-tidy -p build src/*.cpp
```

## Key Documentation

@context/standards/cpp-coding-standards.md
@context/standards/cpp-tdd.md
@context/standards/cpp-tooling.md
@context/standards/cpp-commits.md
@context/standards/cpp-versioning.md
@context/standards/cpp-changelog.md
@context/standards/version-control.md
@context/standards/cmake-best-practices.md
@context/standards/googletest-reference.md
@context/standards/taskflow-reference.md
@context/standards/taskflow-testing-patterns.md

## Project Structure

```
.
├── include/mylib/     # Public headers
├── src/               # Library implementation
├── app/               # Application executable
├── tests/             # Unit tests
├── cmake/             # CMake modules
├── context/           # Reference documentation
│   ├── standards/     # Coding standards & guidelines
│   └── project/       # Project-specific docs
├── ext/               # External submodules
└── .claude/           # Claude Code configuration
    ├── commands/      # TDD slash commands
    ├── templates/     # Feature templates
    └── tdd-tasks/     # TDD task files
```

## Quick Reference

### Naming Conventions (Google Style)

| Element | Style | Example |
|---------|-------|---------|
| Files | `snake_case` | `my_class.cpp` |
| Classes | `PascalCase` | `MyClass` |
| Functions | `PascalCase` | `GetValue()` |
| Variables | `snake_case` | `buffer_size` |
| Members | `snake_case_` | `buffer_size_` |
| Constants | `kPascalCase` | `kMaxSize` |

### Commit Types

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Restructure without behavior change |
| `test` | Add/fix tests (existing code) |
| `docs` | Documentation only |
| `build` | CMake, dependencies |

### TDD Phases

1. **RED** - Write failing test, commit
2. **GREEN** - Minimal implementation, commit
3. **REFACTOR** - Improve quality, commit

## Git Workflow

1. Create feature branch: `git checkout -b feature/<name>`
2. Follow TDD workflow
3. Update CHANGELOG.md
4. Create PR to main
5. Squash and merge
