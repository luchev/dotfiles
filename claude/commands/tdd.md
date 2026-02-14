# TDD Command

**Description**: Enforce test-driven development - write failing tests first, then minimal implementation.

## The Iron Law

> **NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST**

If you write code before its test, **delete it completely** and restart. No exceptions, no keeping it as reference.

## When to Use

**Always use TDD for**:
- ✅ New features
- ✅ Bug fixes
- ✅ Refactoring
- ✅ Behavior changes

**Exceptions** (requires explicit approval):
- Throwaway prototypes
- Generated code scaffolding
- Configuration files

## The Red-Green-Refactor Cycle

### 🔴 RED: Write Failing Test

Write ONE minimal test demonstrating desired behavior:

```typescript
// Example: Testing a new function
test('calculateTotal should sum item prices', () => {
  const items = [{ price: 10 }, { price: 20 }];
  const total = calculateTotal(items);
  expect(total).toBe(30);
});
```

**Requirements**:
- Tests one specific behavior
- Has a clear, descriptive name
- Tests real code (avoid mocks when possible)
- Is the simplest test that could fail

### 🔍 Verify RED: Watch It Fail

Run the test and confirm:
- ❌ It **fails** (not errors)
- The failure message is what you expected
- It fails because the feature is missing, not due to typos
- The error is clear and actionable

```bash
npm test
# FAIL: ReferenceError: calculateTotal is not defined
```

### 🟢 GREEN: Minimal Implementation

Write the **simplest code** that makes the test pass:

```typescript
function calculateTotal(items: { price: number }[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

**Rules**:
- Write only what's needed to pass the test
- Don't add extra features
- Don't refactor other code yet
- Don't over-engineer

### ✅ Verify GREEN: Watch It Pass

Confirm:
- ✅ The test passes
- ✅ All other tests still pass
- ✅ No errors or warnings

```bash
npm test
# PASS: 1 test passed
```

### 🔄 REFACTOR: Clean Up

Now that tests are green, improve the code:
- Remove duplication
- Improve variable names
- Extract helper functions
- Simplify logic

**Keep tests passing** throughout refactoring.

## Why Order Matters

### Tests Written After Code Pass Immediately
If a test passes on first run, it proves **nothing** about whether it tests the right behavior.

### Testing First Forces Failure
Witnessing the failure confirms the test catches real problems.

### Manual Testing is Unrepeatable
Automated tests run identically every time and document what was verified.

## Common Rationalizations to Reject

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code still breaks |
| "I'll test after" | Passing tests prove nothing |
| "Already manually tested" | No record, can't re-run |
| "Deleting X hours is wasteful" | Unverified code is technical debt |
| "TDD is dogmatic" | TDD finds bugs faster than debugging in production |

## Red Flags: STOP and Restart

⚠️ If you encounter any of these, **delete code and start over with TDD**:

- Code written before test
- Test passes immediately without failure
- Can't explain why test failed
- Added tests "later"
- Rationalized "just this once"
- Keeping old code as "reference"

## Verification Checklist

Before marking work complete:

- [ ] Every function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for the expected reason
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] No errors or warnings in output
- [ ] Tests use real code, not just mocks
- [ ] Edge cases covered
- [ ] Error conditions tested

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write the API you wish existed; write assertions first |
| Test too complicated | Your design is too complicated - simplify it |
| Must mock everything | Code is too coupled - use dependency injection |
| Huge test setup | Extract test helpers; if still complex, simplify design |

## Debugging Integration

When a bug is discovered:
1. Write a **failing test** that reproduces the bug
2. Verify the test fails (confirms the bug)
3. Fix the code minimally
4. Verify the test passes (confirms the fix)
5. The test now prevents regression

## Example TDD Flow

```bash
# 1. RED: Write failing test
echo "test('user login succeeds', ...)" >> tests/auth.test.ts
npm test
# FAIL: function 'login' is not defined

# 2. GREEN: Minimal implementation
echo "export function login() { return true; }" >> src/auth.ts
npm test
# PASS: 1 test passed

# 3. REFACTOR: Improve while keeping tests green
# Add proper implementation
npm test
# PASS: 1 test passed

# 4. Commit
git add tests/auth.test.ts src/auth.ts
git commit -m "feat: add user login functionality"
```

## Final Rule

> Production code → test exists and failed first
>
> Otherwise → NOT TDD

No exceptions without explicit approval.
