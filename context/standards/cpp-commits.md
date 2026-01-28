# Conventional Commits

This project follows [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

## Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Examples:
```
feat(shm): add shared memory buffer allocation
fix(buffer): prevent segfault on null input
refactor(core): extract validation helper function
```

## Commit Types

| Type | Definition | When to Use | C++ Examples |
|------|------------|-------------|--------------|
| `feat` | NEW user-facing capability | User can do something they couldn't before | New API function, new CLI flag, new class |
| `fix` | Corrects broken/incorrect behavior | Something was wrong and now works | Fix segfault, memory leak, wrong calculation |
| `docs` | Documentation ONLY | No code changes | Update README, add doxygen comments |
| `style` | Formatting ONLY | No logic changes | Run clang-format, fix indentation |
| `refactor` | Restructure without behavior change | Same input→same output | Rename variable, extract function |
| `perf` | Performance improvement | Faster/less memory, same behavior | Add caching, optimize algorithm |
| `test` | Test code ONLY | No production code changes | Add unit test, fix flaky test |
| `build` | Build system or dependencies | CMake, packages | Update CMakeLists.txt, bump gtest |
| `ci` | CI/CD configuration | Pipeline changes | Update GitHub Actions |
| `chore` | Maintenance tasks | Doesn't fit above | Update .gitignore |

## Decision Flowchart

```
Does this commit add NEW user-facing capability?
├─ YES → feat
└─ NO → Continue...

Does this fix incorrect/broken behavior?
├─ YES → fix
└─ NO → Continue...

Does this change ONLY documentation?
├─ YES → docs
└─ NO → Continue...

Does this change ONLY tests (no production code)?
├─ YES → test
└─ NO → Continue...

Does this improve performance without changing behavior?
├─ YES → perf
└─ NO → Continue...

Does this restructure code without changing behavior?
├─ YES → refactor
└─ NO → Continue...

Does this change ONLY formatting/whitespace/style?
├─ YES → style
└─ NO → Continue...

Does this change build system or dependencies?
├─ YES → build
└─ NO → Continue...

Does this change CI/CD configuration?
├─ YES → ci
└─ NO → chore (maintenance tasks)
```

## Common Mistakes

| Situation | Correct Type | NOT |
|-----------|--------------|-----|
| Add new API endpoint | `feat` | - |
| Add parameter to existing function | `feat` if new capability, `refactor` if restructuring | - |
| Fix crash when input is null | `fix` | `feat` |
| Improve error message clarity | `fix` (incorrect UX) | `feat` |
| Rename variable for clarity | `refactor` | `feat` |
| Extract helper function | `refactor` | `feat` |
| Add missing test for existing code | `test` | `feat` |
| Update README | `docs` | `feat` |
| Upgrade dependency version | `build` | `feat` |
| Add caching for speed | `perf` | `feat` |

## The "feat" Test

> Ask: "Can users do something NEW they couldn't do before?"
> If NO → it's not a `feat`

## TDD Commit Pattern

When using `/tdd`, commits follow this pattern:

| Phase | Commit? | Type | Reasoning |
|-------|---------|------|-----------|
| RED | No | - | Don't commit failing tests alone |
| GREEN | Yes | `feat` | New capability (test + implementation together) |
| REFACTOR | If changes | `refactor` | Restructure without behavior change |

Example TDD session:
```bash
# RED: Write failing test for buffer allocation
# (no commit - test fails)

# GREEN: Implement buffer allocation
git commit -m "feat(shm): add buffer allocation"

# REFACTOR: Extract validation helper
git commit -m "refactor(shm): extract validation helper"
```

**Note:** The `test` type is for adding tests to EXISTING functionality, not for TDD where tests drive NEW features.

## Breaking Changes

Indicate breaking changes with `!` or footer:

```
feat!: remove deprecated buffer API

BREAKING CHANGE: The old buffer API has been removed.
Use SharedBuffer instead.
```

## Semantic Versioning Integration

| Commit Type | Version Bump |
|-------------|--------------|
| `feat` | MINOR (1.0.0 → 1.1.0) |
| `fix` | PATCH (1.0.0 → 1.0.1) |
| `BREAKING CHANGE` | MAJOR (1.0.0 → 2.0.0) |
| Other types | No version bump |

## Reference

- Specification: https://www.conventionalcommits.org/en/v1.0.0/
