# TDD Task: [Feature Name]

**Status:** Not Started
**Created:** [Date]
**Last Updated:** [Date]

---

## Feature Description

[Brief description of what this feature should do and why it's needed]

---

## Requirements

### Functional Requirements
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

### Non-Functional Requirements
- [ ] Performance consideration (if applicable)
- [ ] Code style/linting
- [ ] Documentation

---

## Test Specifications

### Test 1: [Test Name]

**Description:** [What this test validates]

**Given:**
- [Precondition 1]
- [Precondition 2]

**When:**
- [Action or trigger]

**Then:**
- [Expected outcome 1]
- [Expected outcome 2]

**Test Code Location:** `tests/[test_file]_test.cpp`

---

### Test 2: [Test Name]

**Description:** [What this test validates]

**Given:**
- [Precondition]

**When:**
- [Action]

**Then:**
- [Expected outcome]

**Test Code Location:** `tests/[test_file]_test.cpp`

---

### Test 3: Edge Cases/Error Conditions

**Description:** Handle edge cases and error scenarios

**Given:**
- [Edge case condition]

**When:**
- [Action under edge case]

**Then:**
- [Expected behavior for edge case]

**Test Code Location:** `tests/[test_file]_test.cpp`

---

## Implementation Requirements

### File Structure
- **Header:** `include/[project]/[source_file].hpp`
- **Source:** `src/[source_file].cpp`
- **Tests:** `tests/[test_file]_test.cpp`

### Framework-Specific Information

**Test Framework:** GoogleTest
**Test Command:** `ctest --test-dir build --output-on-failure`
**Analysis Command:** `clang-tidy src/*.cpp -p build`

### Function/Class Signatures

```cpp
// Define expected function/class signatures here
// Include parameters, return types, and documentation
```

### Dependencies Required
- [ ] Dependency 1
- [ ] Dependency 2
- [ ] Does this require external packages? (yes/no)

### Edge Cases to Handle
- [ ] Empty/null inputs
- [ ] Boundary values (max/min)
- [ ] Invalid inputs
- [ ] Special characters or formats
- [ ] [Other edge case]

---

## Acceptance Criteria

- [ ] All tests pass
- [ ] Code follows style guidelines
- [ ] No linting errors (code analysis passes)
- [ ] Edge cases are handled
- [ ] Documentation is complete
- [ ] No breaking changes to existing APIs
- [ ] Performance requirements met (if applicable)

---

## Implementation Notes

[Add any implementation notes, design decisions, architectural considerations, or known constraints here]

### Architectural Decisions
[Document why certain patterns or approaches were chosen]

### Potential Refactoring Opportunities
[Note any refactoring that could be done after tests pass]

---

## Test Results Tracking

### Iteration 1 (RED Phase)

**Date:** [Date]
**Status:** Tests written and confirmed failing
**Failing Tests:** [Number of tests that should fail]
**Notes:** [Any initial observations about test failures]

### Iteration 2 (GREEN Phase)

**Date:** [Date]
**Tests Passed:** 0/X → X/X
**Status:** Implementation complete and tests passing
**Notes:** [How the implementation satisfied the tests]

### Iteration 3 (REFACTOR Phase)

**Date:** [Date]
**Tests Status:** All passing
**Refactoring Done:** [Brief description of improvements]
**Notes:** [Final code quality improvements]

---

## Related Issues/Features

- Links to related GitHub issues
- Dependencies on other features
- Blocked by: [if applicable]
- Blocks: [if applicable]

---

## Checklist Before Implementation

- [ ] I understand the requirements completely
- [ ] I've reviewed relevant existing code
- [ ] I've identified all test cases needed
- [ ] I have a plan for the implementation approach
- [ ] I'm ready to start with the Red phase (writing tests)
- [ ] I'm on the correct branch (main or feature branch)

---

## Command References

### Start TDD Implementation
```bash
/tdd-workflow .claude/tdd-tasks/[feature-name].md
```

### Run Tests During Development
```bash
/tdd-test tests/[feature]_test.cpp
```

### View TDD Guidelines
```
See: context/standards/cpp-tdd.md
```

---

**Created:** 2025-11-23
**Last Modified:** [Current Date]
