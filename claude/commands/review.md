# Review Command

**Description**: Conduct comprehensive code reviews focusing on quality, correctness, security, and maintainability.

## When to Use

Use this command to:
- Review pull requests
- Conduct code audits
- Provide feedback on implementations
- Ensure code quality standards
- Identify potential issues before merge

## Review Types

### 1. Pre-Commit Review (Self-Review)

**Before creating a PR**, review your own code:

```bash
# Check your changes
git diff main...HEAD

# Review checklist:
- [ ] Code follows project conventions
- [ ] Tests are included and passing
- [ ] No debug code or console.logs
- [ ] No commented-out code
- [ ] Documentation updated
- [ ] Commit messages are clear
```

### 2. Pull Request Review

**Reviewing someone else's PR**:

```markdown
## PR Review Checklist

### Functionality
- [ ] Code does what the PR description says
- [ ] Edge cases handled
- [ ] Error conditions handled
- [ ] No obvious bugs

### Code Quality
- [ ] Clear and readable
- [ ] Well-structured
- [ ] Follows project conventions
- [ ] Appropriate abstractions
- [ ] No unnecessary complexity

### Testing
- [ ] Tests included
- [ ] Tests are meaningful
- [ ] Edge cases tested
- [ ] All tests pass
- [ ] Coverage maintained or improved

### Security
- [ ] No security vulnerabilities
- [ ] Input validation present
- [ ] No secrets in code
- [ ] Proper authentication/authorization

### Performance
- [ ] No obvious performance issues
- [ ] Efficient algorithms used
- [ ] No N+1 queries
- [ ] Resources properly released

### Documentation
- [ ] Code comments where needed
- [ ] API documentation updated
- [ ] README updated if needed
- [ ] Breaking changes documented
```

## Review Focus Areas

### 1. Correctness

**Check for**:
- Logic errors
- Edge case handling
- Error handling
- Type safety
- Race conditions

**Example feedback**:
```markdown
**Issue**: Potential null pointer exception
**Location**: `src/user.ts:45`
**Severity**: High

```typescript
// ❌ Current code
function getUser(id) {
  const user = users.find(u => u.id === id);
  return user.name; // ❌ user might be undefined
}

// ✅ Suggested fix
function getUser(id) {
  const user = users.find(u => u.id === id);
  if (!user) {
    throw new Error(`User not found: ${id}`);
  }
  return user.name;
}
```
```

### 2. Code Quality

**Check for**:
- Readability
- Naming conventions
- Code duplication
- Function complexity
- Proper abstractions

**Example feedback**:
```markdown
**Suggestion**: Extract complex logic into named function
**Location**: `src/orders.ts:78-95`
**Severity**: Medium

```typescript
// ❌ Current: Complex inline logic
const eligibleOrders = orders.filter(o =>
  o.status === 'pending' &&
  o.createdAt > Date.now() - 86400000 &&
  o.items.every(i => i.stock > 0) &&
  o.total > 50
);

// ✅ Suggested: Extracted function with clear name
function isEligibleForProcessing(order) {
  const isRecent = order.createdAt > Date.now() - 86400000;
  const hasStock = order.items.every(i => i.stock > 0);
  const meetsMinimum = order.total > 50;

  return order.status === 'pending' &&
         isRecent &&
         hasStock &&
         meetsMinimum;
}

const eligibleOrders = orders.filter(isEligibleForProcessing);
```
```

### 3. Security

**Check for**:
- SQL injection
- XSS vulnerabilities
- CSRF protection
- Authentication/authorization
- Secrets management
- Input validation

**Example feedback**:
```markdown
**Issue**: SQL Injection vulnerability
**Location**: `src/api/search.ts:23`
**Severity**: Critical

```typescript
// ❌ VULNERABLE
const query = `SELECT * FROM users WHERE email = '${req.body.email}'`;

// ✅ SECURE: Use parameterized queries
const query = 'SELECT * FROM users WHERE email = $1';
const result = await db.query(query, [req.body.email]);
```

**Action Required**: Fix before merge
```

### 4. Performance

**Check for**:
- Inefficient algorithms
- N+1 queries
- Memory leaks
- Unnecessary work
- Missing optimizations

**Example feedback**:
```markdown
**Issue**: N+1 query problem
**Location**: `src/services/user-service.ts:34`
**Severity**: High

```typescript
// ❌ Current: N+1 queries
async function getUsersWithOrders() {
  const users = await User.findAll();
  for (const user of users) {
    user.orders = await Order.findByUserId(user.id); // N queries
  }
  return users;
}

// ✅ Suggested: Single query with JOIN
async function getUsersWithOrders() {
  return await User.findAll({
    include: [{ model: Order }]
  });
}
```

**Performance Impact**: Could cause significant slowdown with many users
```

### 5. Testing

**Check for**:
- Test coverage
- Test quality
- Edge cases
- Error scenarios
- Integration tests

**Example feedback**:
```markdown
**Issue**: Missing edge case tests
**Location**: `tests/validation.test.ts`
**Severity**: Medium

```typescript
// ✅ Current tests
test('validates email', () => {
  expect(isValidEmail('user@example.com')).toBe(true);
});

// ❌ Missing edge cases
test('rejects email without @', () => {
  expect(isValidEmail('userexample.com')).toBe(false);
});

test('rejects email without domain', () => {
  expect(isValidEmail('user@')).toBe(false);
});

test('handles empty string', () => {
  expect(isValidEmail('')).toBe(false);
});

test('handles null/undefined', () => {
  expect(isValidEmail(null)).toBe(false);
  expect(isValidEmail(undefined)).toBe(false);
});
```

**Recommendation**: Add edge case tests before merging
```

### 6. Documentation

**Check for**:
- Code comments
- API documentation
- README updates
- Breaking change notes
- Migration guides

**Example feedback**:
```markdown
**Suggestion**: Add JSDoc comments for public API
**Location**: `src/api/user-api.ts:12`
**Severity**: Low

```typescript
// ❌ Current: No documentation
export function createUser(data) {
  // implementation
}

// ✅ Suggested: Add JSDoc
/**
 * Creates a new user account
 *
 * @param data - User creation data
 * @param data.email - User's email address
 * @param data.password - User's password (will be hashed)
 * @param data.name - User's display name
 * @returns Created user object with generated ID
 * @throws {ValidationError} If data is invalid
 * @throws {DuplicateError} If email already exists
 *
 * @example
 * const user = await createUser({
 *   email: 'user@example.com',
 *   password: 'securepass123',
 *   name: 'John Doe'
 * });
 */
export function createUser(data: UserCreateData): Promise<User> {
  // implementation
}
```
```

## Review Comment Types

### 1. Blocking Issues (Must Fix)

Use for:
- Critical bugs
- Security vulnerabilities
- Breaking changes without migration path
- Tests failing

**Format**:
```markdown
🚫 **BLOCKING**: [Issue description]

[Explanation and suggested fix]

**Must be resolved before merge**
```

### 2. Strong Suggestions (Should Fix)

Use for:
- Performance problems
- Code quality issues
- Missing tests
- Poor error handling

**Format**:
```markdown
⚠️ **SUGGESTION**: [Issue description]

[Explanation and suggested fix]

**Please address or explain why not**
```

### 3. Nitpicks (Nice to Fix)

Use for:
- Style preferences
- Minor improvements
- Optional optimizations

**Format**:
```markdown
💡 **NITPICK**: [Suggestion]

[Brief explanation]

**Optional - feel free to ignore**
```

### 4. Questions (Seek Clarification)

Use for:
- Understanding intent
- Clarifying approach
- Learning from the author

**Format**:
```markdown
❓ **QUESTION**: [Question]

[Context for why asking]
```

### 5. Praise (Acknowledge Good Work)

Use for:
- Clever solutions
- Good practices
- Well-written code

**Format**:
```markdown
✅ **NICE**: [What you liked]

[Why it's good]
```

## Review Process

### Step 1: Understand Context

```markdown
1. Read PR description
2. Check linked issues/tickets
3. Understand the goal
4. Review design documents if available
5. Check discussion comments
```

### Step 2: Check Out Code Locally

```bash
# Get the PR branch
gh pr checkout 123

# Or manually
git fetch origin pull/123/head:pr-123
git checkout pr-123

# Run tests
npm test

# Try it out
npm run dev
```

### Step 3: Review Changes

```bash
# See all changes
git diff main...HEAD

# Review file by file
git diff main...HEAD -- src/specific-file.ts

# Check added/removed lines
git diff --stat main...HEAD
```

### Step 4: Run Checks

```bash
# Run linter
npm run lint

# Run tests
npm test

# Check types
npm run type-check

# Check coverage
npm test -- --coverage

# Try to break it
# - Test edge cases
# - Try invalid inputs
# - Check error scenarios
```

### Step 5: Provide Feedback

Use GitHub PR review interface or format like:

```markdown
## Overall Assessment

[Summary of the PR - what it does well, major concerns]

**Recommendation**: [Approve / Request Changes / Comment]

---

## Detailed Comments

### File: `src/user-service.ts`

#### Line 45: SQL Injection Risk
🚫 **BLOCKING**: Vulnerable to SQL injection

Current code directly interpolates user input into SQL query.

Suggested fix:
```typescript
// Use parameterized query
const result = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

#### Line 67: Good Error Handling
✅ **NICE**: Comprehensive error handling

Good job providing detailed error messages and proper error types.

---

### File: `tests/user-service.test.ts`

#### Missing Edge Cases
⚠️ **SUGGESTION**: Add tests for error scenarios

Current tests only cover happy path. Please add:
- Test for duplicate email
- Test for invalid email format
- Test for missing required fields

---

## Questions

1. ❓ Why was bcrypt chosen over argon2 for password hashing?
2. ❓ Should we add rate limiting for user creation?

---

## Minor Suggestions

💡 **NITPICK**: Consider extracting validation logic
- Could make `validateUserData` reusable across create/update
- Optional improvement for future refactoring
```

## Review Response Guidelines

### For Reviewee (Receiving Feedback)

**DO**:
- ✅ Thank reviewers for their time
- ✅ Address all blocking issues
- ✅ Explain if you disagree (politely)
- ✅ Ask clarifying questions
- ✅ Mark conversations as resolved

**DON'T**:
- ❌ Get defensive
- ❌ Ignore feedback
- ❌ Make excuses
- ❌ Take criticism personally

**Example responses**:
```markdown
> 🚫 BLOCKING: SQL injection vulnerability

Fixed in abc123d. Now using parameterized queries. Thanks for catching this!

---

> ⚠️ SUGGESTION: Extract validation logic

Good idea! I'll do this in a follow-up PR to keep this one focused.
Created issue #456 to track.

---

> ❓ Why bcrypt over argon2?

Great question! Bcrypt is currently used everywhere in our codebase.
I'm open to migrating to argon2, but that should be a separate effort.
Want to discuss in the next architecture meeting?

---

> 💡 NITPICK: Add JSDoc comments

Added in commit def789a. Good catch!
```

### For Reviewer (Giving Feedback)

**DO**:
- ✅ Be constructive and specific
- ✅ Explain the "why" behind suggestions
- ✅ Provide code examples
- ✅ Acknowledge good work
- ✅ Ask questions to understand

**DON'T**:
- ❌ Be vague ("this looks wrong")
- ❌ Just point out problems without helping
- ❌ Be condescending
- ❌ Nitpick excessively
- ❌ Block on personal preferences

## Review Efficiency Tips

### Use Review Templates

```markdown
## Quick Review Template

**What**: [One-line summary]
**Verdict**: ✅ LGTM / ⚠️ Minor issues / 🚫 Needs work

### Positives
- [Good things]

### Issues
- [ ] [Blocking issue 1]
- [ ] [Blocking issue 2]

### Suggestions
- [Optional improvement 1]
- [Optional improvement 2]

### Questions
- [Question 1]
```

### Review in Layers

```markdown
Pass 1: High-level (architecture, approach)
Pass 2: Logic (correctness, edge cases)
Pass 3: Quality (readability, naming)
Pass 4: Details (style, formatting)
```

### Time-Box Reviews

- Small PR (<200 lines): 15-30 minutes
- Medium PR (200-500 lines): 30-60 minutes
- Large PR (>500 lines): Ask to split into smaller PRs

## After Review

- Mark PR as approved/request changes
- Follow up on discussions
- Re-review after changes
- Merge when ready
- Thank the contributor

## Integration with Other Commands

- `/analyze` - Before reviewing, analyze the code
- `/improve` - Suggest specific improvements
- `/debug` - Help debug issues found in review
- `/verify` - Ensure all checks pass
