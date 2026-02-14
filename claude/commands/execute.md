# Execute Command

**Description**: Execute implementation plans with batch processing and verification checkpoints.

## When to Use

Use this command to:
- Execute a plan created with `/plan`
- Implement features with structured review points
- Work through multi-step implementations systematically

## Prerequisites

- A written plan must exist (created with `/plan`)
- Plan location: `docs/plans/YYYY-MM-DD-<feature-name>.md`

## The Five-Step Process

### Step 1: Load and Review Plan

1. Read the plan file thoroughly
2. Identify any questions, gaps, or concerns
3. **STOP and raise concerns** before proceeding if:
   - Instructions are unclear
   - Dependencies are missing
   - Plan has gaps
   - You don't understand a step
4. If plan is clear, create tasks and advance

### Step 2: Execute Batch

- **Default batch size**: First 3 tasks
- For each task:
  1. Mark task as `in_progress`
  2. Follow plan steps exactly (no improvising)
  3. Run all verifications
  4. Confirm tests pass
  5. Mark task as `completed`

### Step 3: Report Progress

After completing a batch:
- Show what was implemented
- Display verification output (test results)
- Announce: **"Ready for feedback on tasks [X-Y]"**
- **WAIT for feedback** before continuing

### Step 4: Apply Feedback and Continue

- Address any feedback or changes
- Execute next batch of 3 tasks
- Repeat steps 2-4 until all tasks complete

### Step 5: Complete Development

After all tasks are verified:
- Announce: "Using the `/verify` command to finalize"
- Run final verification (all tests pass, no warnings)
- Present completion options:
  - Create PR
  - Request code review
  - Merge to main

## Critical Rules

### ⛔ STOP Immediately If:

- You hit blockers mid-batch
- Plan has gaps preventing progress
- Instructions are unclear or ambiguous
- Verification fails repeatedly (>2 times)
- Dependencies are missing
- Tests fail unexpectedly

### ✅ Key Reminders:

- **Review critically first** - Don't blindly execute
- **Follow plan exactly** - No creative additions
- **Don't skip verifications** - Every test must run
- **Wait between batches** - Get feedback before continuing
- **Never start on main** - Always use a feature branch

## Batch Execution Example

```markdown
## Batch 1 (Tasks 1-3)

### Task 1: ✅ Create authentication test
- File: `tests/auth.test.ts`
- Status: PASS
- Commit: a3f8b2c

### Task 2: ✅ Implement authentication function
- File: `src/auth.ts`
- Status: PASS
- Commit: b7c4d9e

### Task 3: ✅ Add password hashing
- File: `src/auth.ts`
- Status: PASS
- Commit: c8d5e1f

**Verification Output**:
```bash
npm test
# PASS tests/auth.test.ts
# Test Suites: 1 passed, 1 total
# Tests: 3 passed, 3 total
```

**Ready for feedback on tasks 1-3**
```

## Integration with Other Commands

**Required before**: `/plan` - Must have a written plan
**Required after**: `/verify` - Final verification before completion
**Optional**: `/worktree` - Use git worktrees for parallel work

## Error Recovery

If execution fails:
1. Document the failure
2. Update the plan with lessons learned
3. Create a new task to address the blocker
4. Resume execution from last successful checkpoint
