# Feature Notes: [Feature Name]

**Created:** [Date]
**Status:** Planning | In Development | Complete

---

## Overview

### Purpose
[Why does this feature exist? What problem does it solve?]

### Use Cases
- Use case 1: [Specific user scenario]
- Use case 2: [Specific user scenario]
- Use case 3: [Specific user scenario]

### Context
[Background information needed to understand this feature]

---

## Requirements Analysis

### Functional Requirements
1. [Concrete requirement 1]
2. [Concrete requirement 2]
3. [Concrete requirement 3]

### Non-Functional Requirements
- [Performance requirement]
- [Scalability requirement]
- [Code quality requirement]
- [Documentation requirement]

### Integration Points
- What other features does this integrate with?
- What APIs does this expose?
- What dependencies does this have?

---

## Implementation Details

### Architectural Approach
[How will this feature be implemented?]

### Design Patterns
[What design patterns apply to this feature?]
- Pattern 1: [How it applies]
- Pattern 2: [How it applies]

### File Structure
```
src/
├── [feature]/
│   ├── [feature].hpp
│   └── [feature].cpp
include/
├── [project]/
│   └── [feature].hpp

tests/
├── [feature]_test.cpp
```

### Naming Conventions
[Framework-specific conventions for this feature]
- Classes: [Pattern]
- Functions: [Pattern]
- Files: [Pattern]
- Constants: [Pattern]

### Visual Design (if applicable)
[ASCII diagrams or descriptions of UI/UX]

```
┌─────────────────────────┐
│   Feature Layout        │
│                         │
│  [Component]            │
│                         │
└─────────────────────────┘
```

---

## TDD Approach

### Test Strategy
Following TDD principles, we'll create tests first for all implementations, then create the implementation to make the tests pass.

**Test Framework:** GoogleTest

### Red Phase - Tests to Write
1. Test 1: [Test description]
2. Test 2: [Test description]
3. Test 3: [Test description]

**Goal:** All tests fail initially (expected)

### Green Phase - Implementation
1. Implement minimal code to pass Test 1
2. Implement minimal code to pass Test 2
3. Implement minimal code to pass Test 3

**Goal:** All tests pass

### Refactor Phase - Code Quality
1. Refactor for readability
2. Extract reusable components
3. Improve performance if needed
4. Ensure tests still pass

**Goal:** Clean, maintainable code

---

## Dependencies

### External Packages
- [ ] Package 1: [Version/reason]
- [ ] Package 2: [Version/reason]

### Internal Dependencies
- [ ] Feature A: [Why needed]
- [ ] Feature B: [Why needed]

### Platform/Framework Requirements
- [ ] Minimum version: [e.g., C++20]
- [ ] Target platforms: [Linux/macOS/Windows]

---

## Testing Strategy

### Unit Tests
- [Component 1] unit tests
- [Component 2] unit tests
- [Business logic] unit tests

### Integration Tests
- [Full feature] integration tests
- [User workflows] integration tests

### Manual Testing Checklist
- [ ] Test on Linux
- [ ] Test on macOS (if applicable)
- [ ] Test on Windows (if applicable)
- [ ] Test edge cases manually
- [ ] Verify performance

---

## Known Limitations / Trade-offs

### Limitations
- [Limitation 1]: Why it exists and future improvements
- [Limitation 2]: Why it exists and future improvements

### Trade-offs Made
- [Trade-off 1]: What was chosen and what was sacrificed
- [Trade-off 2]: What was chosen and what was sacrificed

---

## Implementation Notes

### Key Decisions
- **Decision 1:** [What and why]
- **Decision 2:** [What and why]

### Future Improvements
- [ ] Enhancement 1: [Description and timing]
- [ ] Enhancement 2: [Description and timing]

### Potential Refactoring
- Extract [component] when [condition]
- Optimize [function] after initial implementation
- Consolidate [similar code] once pattern is clear

---

## References

### Related Code
- Link to related implementation
- Link to related tests
- Link to similar features

### Documentation
- [Internal documentation](link)
- [External resources](link)

### Issues/PRs
- #[issue-number]: [Issue title]
- #[PR-number]: [PR title]

---

## Acceptance Criteria

- [ ] All tests pass
- [ ] Code review approved
- [ ] Linting passes
- [ ] Documentation updated
- [ ] Manual testing completed
- [ ] No breaking changes
- [ ] Performance acceptable

---

## Session Log

### Session 1: Planning and Requirements
**Date:** [Date]
**Summary:** [What was accomplished]

### Session 2: Red Phase - Test Writing
**Date:** [Date]
**Summary:** [Tests written, number failing]

### Session 3: Green Phase - Implementation
**Date:** [Date]
**Summary:** [Features implemented, tests passing]

### Session 4: Refactor Phase - Code Quality
**Date:** [Date]
**Summary:** [Improvements made, final status]

---

## Next Steps

1. Create TDD task file: `.claude/tdd-tasks/[feature-name].md`
2. Review this feature notes document
3. Run `/tdd-workflow` command to start TDD workflow
4. Follow Red-Green-Refactor cycle
5. Submit PR when complete

---

**Created:** 2025-11-23
**Last Updated:** [Current Date]
**Status:** [Planning | In Development | Review | Complete]
