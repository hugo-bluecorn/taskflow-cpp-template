# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Added missing required VSCode extensions list to TDD primer

## [0.2.0] - 2026-01-29

### Added
- Context directory README explaining three-tier structure (standards/libraries/project)
- `context/libraries/` directory for project-specific Claude Code context
- New developer TDD primer with step-by-step instructions
- VSCode GoogleTest integration analysis document
- VSCode debug configuration for C++ TestMate (`.vscode/settings.json`, `.vscode/launch.json`)
- GitHub template setup with usage instructions in README
- Strict warning flags (`-Wall -Wextra -Wpedantic -Werror`) in TDD presets

### Changed
- Renamed project from `taskflow_quickstart` to `taskflow_cpp_template`
- Simplified mylib to minimal Hello World template (PrintGreeting only)
- TDD primer now uses `tdd-tsan` preset as primary development build
- Refactored Taskflow testing patterns catalog from doctest to GoogleTest syntax
- launch.json uses dynamic `${command:cmake.buildDirectory}` for preset switching
- Updated all documentation to use `tdd-tsan`/`tdd-asan` preset names

### Fixed
- VSCode TestMate debugging now works across all CMake presets

## [0.1.0] - 2026-01-28

### Added
- Initial C++ CMake template with TDD support
- Taskflow library integration as git submodule
- Clang toolchain with sanitizer presets (tdd-tsan, tdd-asan)
- Code coverage support using llvm-cov
- Comprehensive Taskflow API reference documentation
- Taskflow testing patterns catalog for TDD development
