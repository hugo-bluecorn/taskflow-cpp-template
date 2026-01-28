---
name: tdd-new
description: Create a new TDD task file and feature notes
---

# /tdd-new - Create a New TDD Task

## Description

Create a new TDD (Test-Driven Development) task file to structure your feature development with pre-development planning, test specifications, and implementation requirements.

---

## Instructions

1. **Get the feature name** from the user (if not provided as an argument)
2. **Pre-Development Checklist:**
   - Verify you're on the correct branch (main or feature branch)
   - Ask user if they understand related existing code
   - Ensure user has read relevant README and documentation
   - Ask clarifying questions about the feature
3. **Create directories:**
   - Create `notes/features/` directory if it doesn't exist
   - Create `.claude/tdd-tasks/` directory if it doesn't exist
4. **Create feature notes:**
   - Use `.claude/templates/feature-notes.md` as template
   - Populate with feature name, date, description
   - Ask user for brief feature description
   - Ask user about initial requirements
   - Save to `notes/features/[feature-name].md`
5. **Create TDD task file:**
   - Use `.claude/tdd-template.md` as template
   - Populate with feature name and date
   - Ask user for test specifications
   - Ask user for implementation details
   - Save to `.claude/tdd-tasks/[feature-name].md`
6. **Provide next steps:**
   - Report both file paths created
   - Explain that user should edit files to complete requirements
   - Explain next command is `/tdd-workflow`

---

## Usage Examples

### Example 1: With feature name as argument
```
/tdd-new Add email validator
```

### Example 2: Without argument (will prompt)
```
/tdd-new
```

---

## Interactive Prompts

If user doesn't provide complete information, ask these questions:

1. **What is the feature name?**
   - Expected: Clear, descriptive feature name
   - Example: "Email address validation", "User authentication"

2. **What should this feature do? (brief description)**
   - Expected: 1-2 sentence description
   - Example: "Validate email addresses with proper RFC 5322 compliance"

3. **What are the main requirements?**
   - Expected: List of specific, testable requirements
   - Examples:
     - "Must accept valid email formats"
     - "Must reject invalid email formats"
     - "Must handle edge cases (special characters, long addresses)"

4. **What test cases should we write?**
   - Expected: List of specific test scenarios
   - Examples:
     - "Test valid email with dots and hyphens"
     - "Test invalid email without @"
     - "Test empty string"

5. **Do you want to edit the files now or start with /tdd-workflow?**
   - Expected: User preference
   - Typical: Start with /tdd-workflow for guided development

---

## Filename Generation

Convert feature name to lowercase with hyphens:
- "Add Email Validator" → `add-email-validator`
- "User Authentication" → `user-authentication`
- "Password Hashing Service" → `password-hashing-service`

---

## Output

After creating files, provide:

### Success Message
```
TDD Task Created Successfully!

Feature Notes: notes/features/[feature-name].md
TDD Task File: .claude/tdd-tasks/[feature-name].md

Next Steps:
1. Review and edit the files to add requirements and test specifications
2. Run: /tdd-workflow .claude/tdd-tasks/[feature-name].md
3. Follow the Red-Green-Refactor cycle

For TDD guidance, see: context/standards/cpp-tdd.md
```

### File Locations
```
Project Structure:
notes/
└── features/
    └── [feature-name].md          ← Feature notes and planning

.claude/
└── tdd-tasks/
    └── [feature-name].md          ← TDD task with test specs
```

---

## Pre-Development Checklist

Before creating TDD task, guide user through:

1. **Read Documentation**
   - [ ] Have you read the README.md?
   - [ ] Have you reviewed relevant documentation?
   - [ ] Do you understand the project structure?

2. **Understand Existing Code**
   - [ ] Have you reviewed related existing code?
   - [ ] Do you understand the patterns used?
   - [ ] Do you know where similar features are implemented?

3. **Clarify Requirements**
   - [ ] Do you have clear requirements?
   - [ ] Have you asked any clarifying questions?
   - [ ] Do you understand edge cases?

4. **Branch Management**
   - [ ] Are you on the correct branch (main or feature)?
   - [ ] Is your branch up to date?
   - [ ] Do you understand the branch naming convention?

---

## TDD Task File Structure

The created TDD task file includes:

```markdown
# TDD Task: [Feature Name]

**Status:** Not Started
**Created:** [Date]

## Feature Description
[User-provided description]

## Requirements
[User-provided requirements]

## Test Specifications
[Test 1, Test 2, Test 3, Edge Cases]

## Implementation Requirements
[File structure, function signatures, dependencies]

## Acceptance Criteria
[Checklist for successful completion]
```

User should fill in:
- Test specifications with Given-When-Then format
- Implementation requirements
- Any specific constraints or considerations

---

## Feature Notes File Structure

The created feature notes file includes:

```markdown
# Feature Notes: [Feature Name]

**Status:** Planning
**Created:** [Date]

## Overview
[Purpose, use cases, context]

## Requirements Analysis
[Functional and non-functional requirements]

## Implementation Details
[Architectural approach, file structure, naming conventions]

## TDD Approach
[Test strategy and phases]

## Acceptance Criteria
[Definition of done]
```

User can expand with:
- Detailed architectural decisions
- Visual design/diagrams
- Integration points
- Known limitations

---

## Important Notes

### Pre-Development is Crucial
- Don't skip reading existing code
- Understand project patterns before starting
- Clarify ambiguous requirements upfront
- This saves time during implementation

### TDD File Collaboration
- Feature notes: Plan and document the feature
- TDD task: Specify tests and implementation details
- Both files guide the /tdd-workflow command

### File Naming
- Use lowercase with hyphens in filenames
- Feature names should be descriptive
- Avoid abbreviations in file/feature names

### Next Command
Users should run `/tdd-workflow .claude/tdd-tasks/[feature-name].md` after preparing the TDD task file.

---

## Troubleshooting

### Files already exist
- Check if feature already has a TDD task
- Ask user if they want to update or create new feature
- Can update existing file with new requirements

### Unclear requirements
- Ask more clarifying questions
- Provide examples
- Check related features for patterns

### User unsure about tests
- Suggest simple test cases first
- Use Given-When-Then pattern
- Start with happy path, then edge cases

---

## References

- **C++ TDD Guide:** `context/standards/cpp-tdd.md`
- **TDD Template:** `.claude/tdd-template.md`
- **Feature Notes Template:** `.claude/templates/feature-notes.md`
- **Next Command:** `/tdd-workflow`
- **Version Control:** `context/standards/version-control.md`

---

**Created:** 2025-11-23
