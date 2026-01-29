# Plan: Claude Code TDD Primer

**Status:** Planned
**Created:** 2026-01-29
**Prerequisite:** Complete `taskflow-unit-test-primer.md` first (manual workflow)

## Overview

A companion primer that teaches the same SimplePipeline example using Claude Code's TDD slash commands instead of manual workflow. Assumes reader completed the manual primer and understands TDD fundamentals.

## Target Audience

- Developers who completed the manual TDD primer
- Claude Code users wanting to automate TDD workflow

## Document Location

`context/project/claude-code-tdd-primer.md`

## Outline

### Introduction
- Purpose: Automate TDD workflow with Claude Code
- Prerequisite: Manual primer completed
- Same example (SimplePipeline), different approach

### Phase 0: Setup
- Same as manual primer (project clone, branch creation)
- Verify Claude Code is configured (`.claude/` directory exists)

### Phase 1: Create TDD Task with `/tdd-new`

```
/tdd-new simple-pipeline
```

Show:
- Interactive prompts Claude Code asks
- Generated files: `.claude/tdd-tasks/simple-pipeline.md`, `notes/features/simple-pipeline.md`
- How to review/edit the task file

### Phase 2: RED Phase with `/tdd-test`

- Write the failing test (same as manual primer)
- Run `/tdd-test` to verify RED phase
- Show output format with phase context
- Commit guidance

### Phase 3: GREEN Phase with `/tdd-test`

- Implement minimal code (same as manual primer)
- Run `/tdd-test` to verify GREEN phase
- Show pass/fail output
- Commit guidance

### Phase 4: REFACTOR Phase

- Add task names, documentation (same as manual primer)
- Run `/tdd-test` to verify tests still pass
- Commit guidance

### Phase 5: Full Workflow Demo with `/tdd-workflow`

Show alternative approach using single command:

```
/tdd-workflow .claude/tdd-tasks/simple-pipeline.md
```

- Guided walkthrough of entire RED-GREEN-REFACTOR
- Claude Code prompts at each phase
- Automatic commit suggestions

### Phase 6: Adding Features (counter/Reset)

Use `/tdd-workflow` for the observability feature:
- Show how command guides through adding new functionality
- Compare effort vs manual approach

### Summary

| Approach | Best For |
|----------|----------|
| Manual workflow | Learning, understanding TDD |
| `/tdd-test` | Quick verification during manual work |
| `/tdd-workflow` | Guided automation, consistency |

### Command Reference

| Command | When to Use |
|---------|-------------|
| `/tdd-new <feature>` | Starting a new feature |
| `/tdd-test [file]` | Verify current phase (RED/GREEN/REFACTOR) |
| `/tdd-workflow <task>` | Full guided TDD cycle |

## Implementation Notes

- Keep it shorter than manual primer (assumes TDD knowledge)
- Focus on command usage and output interpretation
- Reference manual primer for concept explanations
- Include screenshots/examples of Claude Code prompts

## Estimated Length

~300-400 lines (vs ~1200 lines for manual primer)

## Dependencies

Before implementing:
- [ ] Verify `/tdd-new` works with current template structure
- [ ] Verify `/tdd-test` detects C++/GoogleTest correctly
- [ ] Verify `/tdd-workflow` produces correct commit messages
- [ ] Test full workflow end-to-end

## Related Files

- `.claude/commands/tdd-new.md` - Command definition
- `.claude/commands/tdd-test.md` - Command definition
- `.claude/commands/tdd-workflow.md` - Command definition
- `.claude/tdd-template.md` - Task file template
- `.claude/templates/feature-notes.md` - Feature notes template
