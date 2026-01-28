# Semantic Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## Version Format

```
MAJOR.MINOR.PATCH[-prerelease][+build]
```

Examples: `1.0.0`, `2.1.3`, `1.0.0-alpha`, `1.0.0-beta.2`, `1.0.0+build.123`

## When to Increment

| Component | Increment When | Example |
|-----------|----------------|---------|
| **MAJOR** | Breaking API changes | Remove function, change return type, rename public class |
| **MINOR** | New backward-compatible functionality | Add new function, add optional parameter |
| **PATCH** | Backward-compatible bug fixes | Fix crash, correct calculation, fix memory leak |

## Rules

1. **MAJOR = 0**: Initial development, API may change anytime
2. **MAJOR >= 1**: Public API is stable, follow increment rules strictly
3. **Reset on increment**: MINOR resets PATCH to 0, MAJOR resets both to 0

## Pre-release Versions

Append hyphen + identifiers for unstable versions:

```
1.0.0-alpha       # Early testing
1.0.0-alpha.1     # Alpha iteration
1.0.0-beta        # Feature complete, testing
1.0.0-beta.2      # Beta iteration
1.0.0-rc.1        # Release candidate
```

Pre-release versions have **lower precedence** than the release version:
`1.0.0-alpha < 1.0.0-beta < 1.0.0-rc.1 < 1.0.0`

## Build Metadata

Append plus sign + identifiers for build info (ignored in precedence):

```
1.0.0+20241201           # Build date
1.0.0+build.123          # Build number
1.0.0-beta+exp.sha.5114f85  # Combined
```

## Version Precedence

```
1.0.0 < 2.0.0 < 2.1.0 < 2.1.1
1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-beta < 1.0.0
```

## Reference

- Specification: https://semver.org/spec/v2.0.0.html
