# Debug Command

**Description**: Systematic debugging is FASTER than guess-and-check thrashing. Follow structured phases to identify root causes.

## Core Principle

> **95% of "no root cause" cases are incomplete investigation**

Systematic debugging beats random guessing every time.

## When to Use

Use this command when:
- Encountering unexpected behavior
- Tests are failing
- Production issues occur
- Performance problems arise
- Bugs are reported

## The Five Phases

### Phase 1: Reproduce Reliably

**Goal**: Create a minimal, consistent reproduction

1. **Document the symptoms**:
   - What's the expected behavior?
   - What's the actual behavior?
   - Error messages (exact text)
   - When did it start?

2. **Find minimal reproduction**:
   - Smallest input that triggers the bug
   - Specific steps to reproduce
   - Required environment conditions

3. **Create a failing test**:
   ```typescript
   test('bug: user login fails with special characters', () => {
     // Exact reproduction of the bug
     const result = login('user@example.com', 'p@ssw0rd!');
     expect(result.success).toBe(true); // Currently fails
   });
   ```

4. **Verify consistency**:
   - Can you reproduce it every time?
   - What's the reproduction rate? (100%, 50%, 10%?)

**Exit criteria**: You can reproduce the bug reliably

### Phase 2: Isolate the Location

**Goal**: Find exactly where the bug occurs

1. **Use binary search**:
   - Add logging/breakpoints at midpoint
   - Narrow down to smaller sections
   - Repeat until you find the exact line

2. **Trace the execution path**:
   ```bash
   # Add strategic logging
   console.log('1. Input:', input);
   console.log('2. After validation:', validated);
   console.log('3. After processing:', processed);
   console.log('4. Output:', output);
   ```

3. **Check assumptions**:
   - What do you assume is true at this point?
   - Add assertions to verify assumptions
   - Which assumption breaks first?

4. **Examine state**:
   - What's the value of each variable?
   - Is the state what you expected?
   - When does state diverge from expectations?

**Exit criteria**: You know the exact line/function where the bug occurs

### Phase 3: Identify the Root Cause

**Goal**: Understand WHY the bug occurs

1. **Ask the "5 Whys"**:
   ```
   Bug: Login fails with special characters
   Why? Password validation rejects special chars
   Why? Regex pattern doesn't include special chars
   Why? Pattern was copied from basic example
   Why? No test coverage for special characters
   Why? Requirements didn't specify special char support
   Root cause: Missing requirement + no edge case testing
   ```

2. **Distinguish symptoms from causes**:
   - Symptom: What you observe
   - Cause: What creates the symptom
   - Keep asking "why" until you reach the root

3. **Examine git history**:
   ```bash
   git log -p --follow path/to/buggy/file.ts
   git blame path/to/buggy/file.ts
   ```
   - When was the buggy code introduced?
   - What was the intent of that change?
   - Did it break something that worked before?

4. **Check related code**:
   - Are there similar patterns elsewhere?
   - Is this a systemic issue?
   - Could the same bug exist in other places?

**Exit criteria**: You understand the root cause, not just the symptom

### Phase 4: Design the Fix

**Goal**: Plan the minimal, correct fix

1. **Consider fix approaches**:
   - Quick patch vs. proper fix
   - Where should the fix be applied?
   - What are the trade-offs?

2. **Evaluate side effects**:
   - What else could this fix affect?
   - Are there edge cases to consider?
   - Could this break other functionality?

3. **Design verification**:
   - How will you know the fix works?
   - What tests need to be added/updated?
   - How will you prevent regression?

4. **Plan the change**:
   ```markdown
   Fix approach: Update password validation regex

   Changes needed:
   1. Update regex in src/validation.ts
   2. Add test case for special characters
   3. Update documentation

   Tests to add:
   - Special characters in password
   - All printable ASCII characters
   - Unicode characters
   ```

**Exit criteria**: You have a clear plan for the minimal fix

### Phase 5: Implement and Verify

**Goal**: Fix the bug and prevent regression

1. **Write a failing test** (if not done in Phase 1):
   ```typescript
   test('bug: accepts special characters in password', () => {
     const result = login('user@example.com', 'p@ssw0rd!');
     expect(result.success).toBe(true);
   });
   ```

2. **Verify the test fails**:
   ```bash
   npm test
   # FAIL: expected true, received false
   ```

3. **Implement minimal fix**:
   ```typescript
   // Before: const PASSWORD_REGEX = /^[a-zA-Z0-9]+$/;
   // After:
   const PASSWORD_REGEX = /^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+$/;
   ```

4. **Verify the test passes**:
   ```bash
   npm test
   # PASS: all tests passed
   ```

5. **Check for regressions**:
   ```bash
   npm test -- --coverage
   npm run lint
   npm run build
   ```

6. **Add edge case tests**:
   ```typescript
   test('accepts all special characters', () => { ... });
   test('accepts unicode characters', () => { ... });
   test('rejects empty password', () => { ... });
   ```

**Exit criteria**: Bug fixed, tests pass, no regressions

## Debugging Tools

### Logging Strategies

```typescript
// Strategic logging
console.log('🔍 [DEBUG] Function called with:', args);
console.log('📍 [CHECKPOINT] State before:', state);
console.log('⚠️ [WARNING] Unexpected value:', value);
console.log('✅ [SUCCESS] Operation completed:', result);
```

### Breakpoint Debugging

```bash
# Node.js
node --inspect-brk your-file.js
# Then open chrome://inspect

# VS Code
# Add breakpoint in editor (F9)
# Run debugger (F5)
```

### Git Bisect for Regressions

```bash
# Find which commit introduced the bug
git bisect start
git bisect bad                  # Current commit is bad
git bisect good v1.2.0         # v1.2.0 was good
# Git checks out midpoint
npm test                        # Test if bug exists
git bisect good|bad            # Mark the result
# Repeat until git finds the bad commit
git bisect reset
```

### Network/API Debugging

```bash
# Capture HTTP traffic
curl -v https://api.example.com
tcpdump -i any port 80

# Test API endpoints
http POST https://api.example.com/login email=user@example.com password=test
```

## Common Anti-Patterns

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| "Let me try random changes" | Follow the 5 phases systematically |
| "It works on my machine" | Reproduce in the failing environment |
| "I'll add more logging" | Use targeted logging at decision points |
| "Let's rewrite it" | Fix the root cause, don't paper over it |
| "It's probably X" | Prove it with data, don't assume |

## When Stuck

| Situation | Action |
|-----------|--------|
| Can't reproduce | Ask for more details, check environment differences |
| Too many variables | Isolate one variable at a time |
| Heisenbug (disappears when debugging) | Add minimal logging, check for race conditions |
| Intermittent failure | Gather more data points, look for patterns |
| Multiple possible causes | Test hypotheses one at a time |

## Checklist Before Claiming "Can't Find Root Cause"

- [ ] Created minimal reproduction
- [ ] Added logging at key decision points
- [ ] Used binary search to isolate location
- [ ] Examined git history for recent changes
- [ ] Checked assumptions with assertions
- [ ] Inspected variable state at failure point
- [ ] Asked "why" at least 5 times
- [ ] Reviewed related code for similar patterns
- [ ] Tested in same environment as failure
- [ ] Checked for race conditions / timing issues

## Final Principles

1. **Systematic beats random** - Follow the phases, don't skip
2. **Understand, don't patch** - Fix root causes, not symptoms
3. **Test first, then fix** - Prove the bug, then prove the fix
4. **Prevent regression** - Add tests so it never comes back
5. **Document learnings** - Share what you discovered

Remember: **If you can't find the root cause, you haven't investigated thoroughly enough.**
