# Version Control & Git Workflow

This document describes the git workflow for this project. These rules are **required** for both Claude Code and developers unless explicitly overridden.

## Overview

We use **GitHub Flow** with an **approval-gated commit workflow**:
- `main` branch is always stable and deployable
- All work happens in short-lived feature branches
- Changes merge to `main` via Pull Request
- Claude Code stages changes and proposes commits, requiring explicit approval

This ensures quality control while maintaining a clean, linear history.

---

## Branching Strategy

### Branch Structure

```
main (protected, always deployable)
  ├── feature/add-user-authentication
  ├── feature/dashboard-widgets
  ├── fix/login-error-handling
  ├── docs/update-readme
  └── chore/update-dependencies
```

### Branch Types

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/add-user-profile` |
| `fix/` | Bug fixes | `fix/null-pointer-exception` |
| `docs/` | Documentation only | `docs/add-contributing-guide` |
| `refactor/` | Code restructuring, no behavior change | `refactor/extract-auth-service` |
| `test/` | Test additions/fixes only | `test/add-repository-tests` |
| `chore/` | Maintenance, dependencies, tooling | `chore/update-dependencies` |

### Branch Naming Conventions

**Format:** `<type>/<short-description>`

**Rules:**
- Use lowercase only
- Use hyphens to separate words (not underscores)
- Keep descriptions concise (2-5 words)
- Include ticket/issue number if applicable: `fix/issue-42-sync-timeout`

**Examples:**
```
feature/add-dark-mode
fix/dashboard-empty-state
docs/update-setup-instructions
Feature/Add_New_Thing        (wrong case, underscores)
feature/this-is-a-very-long-branch-name-that-describes-everything  (too long)
```

---

## Feature Branch Workflow

### Starting New Work

1. **Ensure `main` is up to date:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Work in small commits** following TDD:
   - Write failing test → commit
   - Make test pass → commit
   - Refactor → commit

### During Development

- **Commit frequently** with clear messages (see Commit Message Format below)
- **Push regularly** to remote for backup:
  ```bash
  git push -u origin feature/your-feature-name
  ```
- **Keep branch focused** on single feature/fix
- **Rebase on main** if branch lives longer than expected:
  ```bash
  git fetch origin
  git rebase origin/main
  ```

### Completing Work

1. **Ensure all tests pass:** `ctest --test-dir build --output-on-failure`
2. **Ensure analysis passes:** `clang-tidy -p build src/*.cpp`
3. **Ensure code is formatted:** `clang-format -i src/*.cpp include/mylib/*.hpp`
4. **Update CHANGELOG.md** (required for every PR)
5. **Push final changes**
6. **Create Pull Request** (see PR Guidelines below)

---

## Pull Request Guidelines

### When to Create a PR

**Always create a PR for:**
- Any merge to `main`
- Even solo work (creates documentation trail)

### PR Creation (Claude Code)

When Claude Code completes a feature branch, it will:

1. **Push the branch** to remote
2. **Create PR** with this format:
   ```
   ## Summary
   - Brief description of changes (1-3 bullets)

   ## Changes
   - List of specific changes made

   ## Testing
   - How the changes were tested
   - Test commands run

   ## Checklist
   - [ ] Tests pass (`ctest --test-dir build`)
   - [ ] Analysis passes (`clang-tidy`)
   - [ ] Code formatted (`clang-format`)
   - [ ] CHANGELOG.md updated
   ```

3. **Request review** (or self-review for solo work)

### PR Review Checklist

Before merging, verify:
- [ ] Changes match PR description
- [ ] Tests are adequate for the changes
- [ ] No analyzer warnings introduced
- [ ] CHANGELOG entry is accurate
- [ ] Branch is up to date with `main`

### Merging

**Preferred method:** Squash and merge
- Creates clean, linear history
- Single commit per feature on `main`
- PR description becomes commit message

**Alternative:** Rebase and merge
- Use when commit history is valuable
- Each commit must be atomic and pass tests

**Never:** Merge commit
- Creates unnecessary merge bubbles
- Complicates history

---

## Release and Tagging

### Release Strategy

This project uses **milestone-based releases** aligned with significant feature completions.

### When to Release

Create a release after completing significant milestones:
- Major feature completion
- Breaking changes
- Significant bug fixes affecting users

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

0.1.0  → First internal release
0.2.0  → New feature added
0.2.1  → Bug fix
1.0.0  → First stable/production release
1.1.0  → New feature after stable release
1.1.1  → Patch/bugfix
```

### Creating a Release

1. **Ensure `main` is stable** and all tests pass

2. **Update version** in `CMakeLists.txt`:
   ```cmake
   project(myproject VERSION 0.2.0 LANGUAGES CXX)
   ```

3. **Update CHANGELOG.md**:
   - Move items from `[Unreleased]` to versioned section
   - Add release date
   ```markdown
   ## [0.2.0] - 2025-12-08

   ### Added
   - New feature description
   - ...
   ```

4. **Commit version bump:**
   ```bash
   git commit -am "chore(release): bump version to 0.2.0"
   ```

5. **Create annotated tag:**
   ```bash
   git tag -a v0.2.0 -m "Release 0.2.0: Feature Description"
   ```

6. **Push with tags:**
   ```bash
   git push origin main --tags
   ```

### Tag Naming

- Format: `v<MAJOR>.<MINOR>.<PATCH>`
- Examples: `v0.1.0`, `v1.0.0`, `v1.2.3`

---

## Exceptions and Overrides

These rules are **required by default** but can be overridden when explicitly requested.

### Valid Override Scenarios

| Scenario | Override | How to Request |
|----------|----------|----------------|
| **Emergency hotfix** | Commit directly to `main` | "Commit this hotfix directly to main" |
| **Trivial fix** | Skip PR for typo/comment | "Skip PR for this one-line fix" |
| **Experimentation** | Work on `main` temporarily | "Let's experiment on main, I'll reset if needed" |
| **Quick iteration** | Delay PR until stable | "Keep working on main, we'll PR when ready" |

### How Overrides Work

1. **Developer explicitly requests** the override
2. **Claude Code acknowledges** the deviation from standard workflow
3. **Work proceeds** with the override
4. **Document why** in commit message if relevant

### What Cannot Be Overridden

- Running tests before release
- Updating CHANGELOG for releases
- Using conventional commit format
- Tagging releases with proper version

---

## Commit Workflow

### Step 1: Claude Code Proposes Changes

When Claude Code completes a task:
1. It stages all modified files
2. It generates a clear, descriptive commit message
3. It proposes the commit to you with the message and file list

### Step 2: Review and Approve

Before Claude Code commits, you should:
1. Review the staged files and changes
2. Review the proposed commit message
3. Approve or request modifications

### Step 3: Documentation Updates

Before proposing the commit, Claude Code will:
1. Identify which documentation files are affected by the changes
2. Update relevant files according to the guide below
3. Include documentation updates in the staged changes

### Step 4: Execute Commit

Once approved, Claude Code commits the changes with the approved message.

## Documentation Update Strategy

The following documentation files should be updated based on the type of changes:

### README.md

Update when:
- Adding or modifying the project's functionality
- Changing how to run or build the project
- Updating installation or usage instructions
- Adding new features or capabilities

Include in README:
- Description of the new/modified feature
- Updated setup or usage instructions
- Updated examples (if applicable)

### CHANGELOG.md

Update **always** before every commit. Use the following format:

```
## [Unreleased]

### Added
- Description of new features

### Changed
- Description of modified existing features

### Fixed
- Description of bug fixes

### Removed
- Description of removed features
```

### Project Documentation

Update when:
- Modifying how developers use this project
- Changing the project process
- Updating project structure documentation

### Code Files

Update when:
- Adding new functionality
- Modifying existing features
- Fixing bugs
- Refactoring code

When modifying code:
- Ensure changes align with project goals
- Test changes thoroughly
- Document any assumptions about project structure

## Documentation Update Guidelines

When updating documentation:

1. **Be concise and clear** — Use language a developer new to the project can understand
2. **Include examples** — Provide code snippets or command examples where helpful
3. **Update cross-references** — If you add a new section, update related documentation
4. **Keep CHANGELOG up-to-date** — This is the historical record of all changes
5. **Test instructions** — If you document a process, verify it actually works

## Identifying Affected Documentation

Use this decision tree to determine which files to update:

- **Is this adding a new feature?** → Update CHANGELOG and README
- **Is this modifying existing functionality?** → Update CHANGELOG and relevant documentation
- **Is this fixing a bug?** → Update CHANGELOG
- **Is this refactoring with no user-facing changes?** → Update CHANGELOG only
- **Is this documentation-only?** → Update only the relevant documentation file

## Example Commit Workflow

1. You ask Claude Code: "Add new feature X"
2. Claude Code makes the changes and proposes:
   - Files modified: `src/feature_x.cpp`
   - Documentation updated: `CHANGELOG.md` (new feature added)
   - Proposed message: "feat: add feature X with Y capability"
3. You review and approve (or request changes)
4. Claude Code executes the commit

## Commit Message Format

Claude Code will use conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Where:
- **type**: feat, fix, docs, style, refactor, perf, test, chore
- **scope**: optional, the area affected
- **subject**: concise description (imperative mood, lowercase)
- **body**: optional, more detailed explanation
- **footer**: optional, references to issues (e.g., "Closes #123")

### Example Commit Messages

```
feat: add user authentication support

Implements login and registration with JWT tokens.

fix: resolve null pointer exception in data processing

Added proper null checks before accessing object properties.

docs: update setup instructions

Clarified CMake version requirements and added troubleshooting section.

refactor: simplify widget composition

Extracted complex nested components into smaller, reusable parts.
```

## Planning and Implementation Workflow

Plan files saved to `planning/` are **committed together with their implementation**. They serve as design documentation, not pre-approval artifacts.

**Workflow:**
1. **Plan** - Create plan, save to `planning/XXX_feature_name.md`
2. **Implement** - Execute the plan
3. **Commit** - Include both plan file and implementation in same commit

This keeps related changes atomic - the plan documents the design decisions for the code being committed.

**Exception:** If a planning session ends without implementation (e.g., deferring to a later session), the plan file remains uncommitted until implementation begins.

---

## Special Cases

### Emergency Fixes

If you need to bypass the approval process for critical fixes, explicitly instruct Claude Code to do so. The CHANGELOG should still be updated.

### Large Changes

For significant changes:
1. Break into multiple smaller commits where logically possible
2. Each commit should be independently buildable
3. Update documentation incrementally with each commit

### Reverting Changes

If you need to revert a commit:
1. Provide the commit hash or message to Claude Code
2. Claude Code will propose the revert with an explanation
3. Follow the normal approval workflow
4. Update CHANGELOG to document the revert

## Reviewing Documentation Updates

When reviewing Claude Code's documentation updates, check:

- [ ] Changes accurately reflect the code changes
- [ ] Examples are correct and runnable
- [ ] Language is clear and consistent with existing docs
- [ ] No dead links or broken references
- [ ] CHANGELOG entry is descriptive and follows the format

## References

- **Keep a Changelog:** https://keepachangelog.com/ — Standard format for maintaining changelog files
- **Conventional Commits:** https://www.conventionalcommits.org/ — Specification for commit message format
- **Semantic Versioning:** https://semver.org/ — Specification for version numbering
