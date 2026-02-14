# Plan Command

**Description**: Create detailed implementation plan with bite-sized, actionable tasks assuming the implementer has zero context.

## When to Use

Use this command:
- After completing the `/brainstorm` phase
- When you have specifications or requirements
- Before starting any multi-step implementation
- When breaking down complex features

## Plan Structure

### Header
```markdown
# [Feature Name]

**Goal**: [One sentence describing what we're building]

**Architecture**: [2-3 sentences on the technical approach]

**Tech Stack**:
- Language/Framework: [specific versions]
- Dependencies: [key libraries]
- Testing: [testing framework]
```

### Tasks Format

Each task should represent a **2-5 minute action** following TDD:

```markdown
## Task N: [Action Title]

**File**: `path/to/file.ext`

**Action**:
1. Write failing test:
   ```language
   // Exact code example
   ```

2. Run test and verify it fails:
   ```bash
   npm test -- path/to/test
   # Expected output: FAIL - [specific error message]
   ```

3. Implement minimal code:
   ```language
   // Exact implementation
   ```

4. Run test and verify it passes:
   ```bash
   npm test -- path/to/test
   # Expected output: PASS
   ```

5. Commit:
   ```bash
   git add path/to/file path/to/test
   git commit -m "feat: [specific change]"
   ```
```

## Required Elements

Each task must include:
- ✅ Exact file paths (no placeholders like `src/...`)
- ✅ Complete code examples (not "add a function here")
- ✅ Specific commands with expected output
- ✅ Test-first approach (write test → verify fail → implement → verify pass)
- ✅ Frequent commits (after each passing test)

## Key Principles

- **Bite-sized**: Each task = 2-5 minutes
- **Zero context**: Anyone can follow the plan
- **TDD always**: Test first, then implement
- **DRY**: Don't repeat yourself
- **YAGNI**: You aren't gonna need it - build only what's specified
- **Exact paths**: No vague file references
- **Complete examples**: No partial code snippets

## Plan Location

Save plans to: `docs/plans/YYYY-MM-DD-<feature-name>.md`

## After Planning

When plan is complete, offer execution options:
1. **Subagent-driven**: Execute in current session with fresh subagents per task
2. **Parallel session**: Use the `/execute` command in a separate session

## Example Task

```markdown
## Task 1: Create user authentication test

**File**: `tests/auth.test.ts`

**Action**:
1. Write failing test:
   ```typescript
   import { authenticateUser } from '../src/auth';

   describe('authenticateUser', () => {
     it('should return token for valid credentials', async () => {
       const result = await authenticateUser('user@example.com', 'password123');
       expect(result.token).toBeDefined();
       expect(result.user.email).toBe('user@example.com');
     });
   });
   ```

2. Run test and verify failure:
   ```bash
   npm test -- auth.test.ts
   # Expected: FAIL - Cannot find module '../src/auth'
   ```

3. Create minimal implementation:
   ```typescript
   // src/auth.ts
   export async function authenticateUser(email: string, password: string) {
     return {
       token: 'temp-token',
       user: { email }
     };
   }
   ```

4. Run test and verify pass:
   ```bash
   npm test -- auth.test.ts
   # Expected: PASS - 1 passed
   ```

5. Commit:
   ```bash
   git add src/auth.ts tests/auth.test.ts
   git commit -m "feat: add user authentication function"
   ```
```
