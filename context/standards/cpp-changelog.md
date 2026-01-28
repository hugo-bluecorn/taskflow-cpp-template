# Keep a Changelog

This project follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).

## File Convention

- Filename: `CHANGELOG.md` (at project root)
- Format: Markdown
- Order: Newest version first

## Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature description

## [1.0.0] - 2024-01-15

### Added
- Initial release feature

### Fixed
- Bug that was fixed

[Unreleased]: https://github.com/user/repo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

## Change Categories

| Category | Description | Use When |
|----------|-------------|----------|
| **Added** | New features | New functionality for users |
| **Changed** | Changes to existing functionality | Behavior modification |
| **Deprecated** | Soon-to-be removed features | Planned removal warning |
| **Removed** | Removed features | Feature deletion |
| **Fixed** | Bug fixes | Corrected behavior |
| **Security** | Vulnerability fixes | Security patches |

## Guidelines

1. **Unreleased section**: Always maintain at top for upcoming changes
2. **Date format**: ISO 8601 (`YYYY-MM-DD`)
3. **Version links**: Add comparison links at bottom of file
4. **Human readable**: Write for humans, not machines
5. **One entry per change**: Each notable change gets its own bullet

## What NOT to Do

- Don't use commit log diffs as changelog
- Don't ignore deprecations
- Don't use confusing date formats
- Don't have inconsistent formatting

## Reference

- Specification: https://keepachangelog.com/en/1.1.0/
