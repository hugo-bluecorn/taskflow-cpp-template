# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Context directory README explaining three-tier structure (standards/libraries/project)
- `context/libraries/` directory for project-specific Claude Code context
- New developer TDD primer with step-by-step instructions
- VSCode GoogleTest integration analysis document
- VSCode debug configuration for C++ TestMate (`.vscode/settings.json`, `.vscode/launch.json`)
- GitHub template setup with usage instructions in README

### Changed
- TDD primer now uses `tdd-tsan` preset as primary development build
- Refactored Taskflow testing patterns catalog from doctest to GoogleTest syntax
- Renamed project from `taskflow_quickstart` to `taskflow_cpp_template`
- launch.json uses dynamic `${command:cmake.buildDirectory}` for preset switching

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
