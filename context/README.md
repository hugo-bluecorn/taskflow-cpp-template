# Context Directory

This directory contains reference documentation for the project. It is organized into three subdirectories with different purposes.

## Directory Structure

```
context/
├── README.md           ← You are here
├── standards/          ← Linked to Claude Code (template standards)
├── libraries/          ← Linked to Claude Code (project-specific)
└── project/            ← NOT linked (human reference only)
```

## standards/

**Purpose:** Coding standards, best practices, and reference documentation that ship with the template. Claude Code uses these during AI-assisted development.

**Linked to:** `.claude/CLAUDE.md` via `@context/standards/<file>.md` references.

**When modified:** Rarely. These are template defaults. Override behavior by adding to `libraries/` instead.

**Contents:**
| File | Purpose |
|------|---------|
| `cpp-coding-standards.md` | Google C++ Style Guide summary |
| `cpp-tdd.md` | Test-Driven Development workflow |
| `cpp-commits.md` | Conventional Commits specification |
| `cpp-changelog.md` | CHANGELOG.md format |
| `cpp-versioning.md` | Semantic versioning rules |
| `cpp-tooling.md` | clang-format, clang-tidy setup |
| `version-control.md` | Git branching strategy |
| `cmake-best-practices.md` | CMake patterns |
| `googletest-reference.md` | GoogleTest/GoogleMock API |
| `taskflow-reference.md` | Taskflow library API |
| `taskflow-testing-patterns.md` | Taskflow unit test patterns |

## libraries/

**Purpose:** Project-specific library documentation added during application development. When you add a new submodule or dependency, document it here for Claude Code to use.

**Linked to:** `.claude/CLAUDE.md` via `@context/libraries/<file>.md` references (you add the link).

**When modified:** During development, as you add new dependencies.

**Example workflow:**

```bash
# 1. Add a new submodule
git submodule add https://github.com/example/cool-lib ext/cool-lib

# 2. Create Claude Code context for it
#    File: context/libraries/cool-lib-reference.md
#    Contents: API summary, patterns, usage examples

# 3. Link it in .claude/CLAUDE.md
#    Add: @context/libraries/cool-lib-reference.md
```

**What to include:**
- API reference (key classes, functions)
- Common usage patterns
- Integration notes specific to your project
- Testing patterns for the library

## project/

**Purpose:** Project-specific documentation for human developers. Tutorials, analysis, decision records, and other documents that Claude Code does not need during development.

**NOT linked to:** `.claude/CLAUDE.md` — Claude Code does not automatically read these files.

**When modified:** Anytime. Add documentation as needed for your team.

**Contents:**
| File | Purpose |
|------|---------|
| `taskflow-unit-test-primer.md` | New developer TDD tutorial |
| `vscode-gtest-integration-analysis.md` | VSCode extension comparison |

## Summary Table

| Directory | Linked to Claude Code? | Ships with Template? | Purpose |
|-----------|:----------------------:|:--------------------:|---------|
| `standards/` | Yes | Yes | "How to write code" (template rules) |
| `libraries/` | Yes (manually) | No (empty) | "How to use dependencies" (project-specific) |
| `project/` | No | No (empty) | "How to learn the project" (human docs) |

## For Novice Programmers

### What is Claude Code?

Claude Code is an AI assistant that helps with software development. It reads the `.claude/CLAUDE.md` file to understand project rules and conventions.

### Why three directories?

| Directory | Read by Claude Code? | Added by |
|-----------|:--------------------:|----------|
| `standards/` | Yes (automatic) | Template |
| `libraries/` | Yes (when you link it) | You, during development |
| `project/` | No | You, during development |

### Example

When you ask Claude Code to "add a feature using cool-lib":

1. It reads `standards/cpp-tdd.md` to follow TDD workflow
2. It reads `libraries/cool-lib-reference.md` to understand the library API
3. It does NOT read `project/` docs (those are for you)

### Decision Guide: Where to Put New Documents

| Document Type | Put in | Link to CLAUDE.md? |
|---------------|--------|:------------------:|
| Coding standard | `standards/` | Already linked |
| Template best practice | `standards/` | Already linked |
| New library/submodule reference | `libraries/` | Yes, add link |
| Project-specific patterns | `libraries/` | Yes, add link |
| Tutorial/primer | `project/` | No |
| Tool comparison/analysis | `project/` | No |
| Architecture decision record | `project/` | No |
| Meeting notes | `project/` | No |

## Adding New Library Context

When you add a dependency that Claude Code should know about:

1. Create the file in `context/libraries/`:
   ```bash
   touch context/libraries/my-library-reference.md
   ```

2. Add content (API reference, patterns, examples)

3. Link it in `.claude/CLAUDE.md`:
   ```markdown
   ## Key Documentation

   @context/standards/cpp-tdd.md
   @context/libraries/my-library-reference.md   # Add this line
   ```

## Adding New Project Docs

For human-only documentation:

1. Create the file in `context/project/`:
   ```bash
   touch context/project/my-analysis.md
   ```

2. No further action needed (not linked to Claude Code)
