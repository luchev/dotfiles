# Verify Command

**Description**: Comprehensive verification before completing development work to ensure quality and correctness.

## When to Use

Use this command:
- Before marking work as complete
- Before creating a pull request
- After implementing a plan
- Before deploying to production
- After major refactoring

## Verification Checklist

### 1. Tests

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Verify coverage thresholds
# Statements: >= 80%
# Branches: >= 75%
# Functions: >= 80%
# Lines: >= 80%
```

**Checks**:
- [ ] All tests pass
- [ ] No skipped tests (unless documented why)
- [ ] No flaky tests (run multiple times)
- [ ] Test coverage meets thresholds
- [ ] New code has tests
- [ ] Edge cases tested
- [ ] Error scenarios tested
- [ ] Integration tests pass

### 2. Linting and Code Quality

```bash
# Run linter
npm run lint

# Run type checker (TypeScript)
npm run type-check

# Check code formatting
npm run format:check

# Code quality analysis
npx plato -r -d report src/
```

**Checks**:
- [ ] No linting errors
- [ ] No linting warnings (or documented exceptions)
- [ ] No type errors
- [ ] Code formatted consistently
- [ ] Complexity within acceptable limits
- [ ] No code smells detected

### 3. Build

```bash
# Clean build
rm -rf dist/
npm run build

# Check build output
ls -lh dist/

# Verify no errors or warnings
```

**Checks**:
- [ ] Build succeeds without errors
- [ ] No build warnings (or documented)
- [ ] Bundle size within limits
- [ ] Source maps generated (if needed)
- [ ] Assets optimized
- [ ] Tree-shaking working

### 4. Security

```bash
# Dependency audit
npm audit

# Security linting
npx eslint src/ --ext .ts,.tsx --plugin security

# Check for secrets
git secrets --scan

# License compliance
npx license-checker --summary
```

**Checks**:
- [ ] No security vulnerabilities (or documented)
- [ ] No hardcoded secrets
- [ ] Dependencies up to date
- [ ] Licenses compatible with project
- [ ] Security best practices followed
- [ ] Input validation in place
- [ ] Authentication/authorization correct

### 5. Git

```bash
# Check git status
git status

# Review changes
git diff main...HEAD

# Check commit messages
git log --oneline main...HEAD

# Check for large files
git ls-files | xargs ls -lh | sort -k5 -h -r | head
```

**Checks**:
- [ ] No uncommitted changes
- [ ] No untracked files (unless intentional)
- [ ] Commit messages are clear and descriptive
- [ ] No large files added (>1MB without reason)
- [ ] No sensitive files committed
- [ ] Branch up to date with main
- [ ] No merge conflicts

### 6. Documentation

```bash
# Check README exists and is updated
cat README.md

# Verify CHANGELOG updated
cat CHANGELOG.md

# Check API docs if applicable
```

**Checks**:
- [ ] README updated if needed
- [ ] CHANGELOG updated with changes
- [ ] Code comments added where needed
- [ ] API documentation updated
- [ ] Migration guide written (if breaking changes)
- [ ] Architecture docs updated (if architecture changed)

### 7. Functionality

```bash
# Run the application
npm run dev

# Test manually:
# - Happy path
# - Error scenarios
# - Edge cases
# - Performance
```

**Checks**:
- [ ] Feature works as intended
- [ ] No console errors
- [ ] No console warnings
- [ ] Performance acceptable
- [ ] UI/UX as expected
- [ ] Error handling works
- [ ] Loading states work
- [ ] Empty states work

### 8. Database (if applicable)

```bash
# Check migrations
npm run migration:status

# Test migration up/down
npm run migration:up
npm run migration:down
npm run migration:up
```

**Checks**:
- [ ] Migrations run successfully
- [ ] Migrations are reversible
- [ ] No data loss in migrations
- [ ] Indexes created appropriately
- [ ] Database constraints correct
- [ ] Seed data works

### 9. Environment

```bash
# Check environment variables
cat .env.example

# Verify all required vars documented
# Verify no hardcoded environment-specific values
```

**Checks**:
- [ ] .env.example updated
- [ ] All required env vars documented
- [ ] No hardcoded values for different environments
- [ ] Environment-specific configs separated
- [ ] Sensitive values not committed

### 10. Dependencies

```bash
# Check for unused dependencies
npx depcheck

# Check for outdated dependencies
npm outdated

# Verify package.json is clean
cat package.json
```

**Checks**:
- [ ] No unused dependencies
- [ ] Dependencies reasonably up to date
- [ ] package.json and package-lock.json in sync
- [ ] Version ranges appropriate (not too loose/strict)
- [ ] Dev dependencies separated from production

## Comprehensive Verification Script

Create a verification script to run all checks:

```bash
#!/bin/bash
# verify.sh

set -e  # Exit on error

echo "🔍 Starting verification..."

echo "1️⃣ Running tests..."
npm test

echo "2️⃣ Checking code coverage..."
npm test -- --coverage --silent
COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.statements.pct')
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
  echo "❌ Coverage $COVERAGE% is below 80%"
  exit 1
fi
echo "✅ Coverage: $COVERAGE%"

echo "3️⃣ Running linter..."
npm run lint

echo "4️⃣ Type checking..."
npm run type-check

echo "5️⃣ Checking formatting..."
npm run format:check

echo "6️⃣ Building..."
npm run build

echo "7️⃣ Security audit..."
npm audit --audit-level=moderate

echo "8️⃣ Checking for secrets..."
git secrets --scan -r . || echo "⚠️ git-secrets not configured"

echo "9️⃣ Checking git status..."
if [[ -n $(git status --porcelain) ]]; then
  echo "❌ Uncommitted changes found"
  git status --short
  exit 1
fi

echo "🔟 Checking commit messages..."
git log --oneline main...HEAD | while read line; do
  if ! echo "$line" | grep -qE "^[a-f0-9]+ (feat|fix|docs|style|refactor|test|chore|perf):"; then
    echo "⚠️ Non-conventional commit: $line"
  fi
done

echo ""
echo "✅ All verifications passed!"
echo ""
echo "📋 Summary:"
echo "  - Tests: ✅ Passing"
echo "  - Coverage: ✅ $COVERAGE%"
echo "  - Linting: ✅ Clean"
echo "  - Types: ✅ Valid"
echo "  - Build: ✅ Success"
echo "  - Security: ✅ No issues"
echo ""
echo "Ready to create PR! 🚀"
```

Usage:
```bash
chmod +x verify.sh
./verify.sh
```

## Pre-PR Verification

**Before creating a pull request**:

```markdown
## PR Readiness Checklist

### Code
- [ ] All tests pass
- [ ] Code coverage >= 80%
- [ ] No linting errors
- [ ] No type errors
- [ ] Build succeeds
- [ ] No console errors/warnings

### Git
- [ ] Branch up to date with main
- [ ] Clear commit messages
- [ ] No merge conflicts
- [ ] Commits squashed if needed
- [ ] No large files added

### Documentation
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] Code comments added
- [ ] PR description written
- [ ] Screenshots added (if UI changes)

### Testing
- [ ] Manual testing completed
- [ ] Edge cases tested
- [ ] Error scenarios tested
- [ ] Performance tested
- [ ] Tested on different browsers (if web)

### Security
- [ ] No security vulnerabilities
- [ ] No secrets committed
- [ ] Input validation added
- [ ] Authentication/authorization correct

### Review
- [ ] Self-reviewed all changes
- [ ] No debug code left behind
- [ ] No commented-out code
- [ ] No TODOs without issues
```

## CI/CD Verification

**Checks that should run in CI**:

```yaml
# .github/workflows/verify.yml
name: Verify

on:
  pull_request:
  push:
    branches: [main]

jobs:
  verify:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Check coverage
        run: npm test -- --coverage

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run type-check

      - name: Build
        run: npm run build

      - name: Security audit
        run: npm audit --audit-level=moderate

      - name: Check bundle size
        run: |
          BUNDLE_SIZE=$(du -sb dist/ | cut -f1)
          MAX_SIZE=5000000  # 5MB
          if [ $BUNDLE_SIZE -gt $MAX_SIZE ]; then
            echo "Bundle size $BUNDLE_SIZE exceeds limit $MAX_SIZE"
            exit 1
          fi
```

## Verification Levels

### Level 1: Quick Check (2 minutes)
```bash
npm test
npm run lint
npm run build
```

### Level 2: Standard Verification (5 minutes)
```bash
npm test -- --coverage
npm run lint
npm run type-check
npm run build
git status
```

### Level 3: Comprehensive Verification (10+ minutes)
```bash
npm test -- --coverage
npm run lint
npm run type-check
npm run format:check
npm run build
npm audit
git secrets --scan -r .
Manual testing
Performance testing
```

## Verification Matrix

For different types of changes:

| Change Type | Quick | Standard | Comprehensive |
|-------------|-------|----------|---------------|
| Bug fix | ✅ | ✅ | - |
| New feature | - | ✅ | ✅ |
| Refactoring | ✅ | ✅ | - |
| Performance | - | - | ✅ |
| Security | - | - | ✅ |
| Docs only | ✅ | - | - |
| Breaking change | - | - | ✅ |

## Common Verification Failures

### Tests Failing

```bash
# Debug test failures
npm test -- --verbose
npm test -- --watch

# Check for race conditions
for i in {1..10}; do npm test || break; done

# Check specific test
npm test -- path/to/test.spec.ts
```

### Build Failures

```bash
# Clean and rebuild
rm -rf node_modules dist
npm install
npm run build

# Check for circular dependencies
npx madge --circular src/

# Check for missing dependencies
npx depcheck
```

### Coverage Below Threshold

```bash
# See uncovered lines
npm test -- --coverage --verbose

# Generate HTML report
npm test -- --coverage
open coverage/lcov-report/index.html

# Add tests for uncovered code
```

### Linting Errors

```bash
# Auto-fix if possible
npm run lint -- --fix

# Show specific rules
npm run lint -- --print-config src/file.ts

# Disable rule (with comment explaining why)
// eslint-disable-next-line rule-name -- reason
```

## After Verification

When all checks pass:

1. **Create PR**:
   ```bash
   gh pr create --title "feat: add user authentication" --body "..."
   ```

2. **Request review**:
   ```bash
   gh pr review request --reviewer @teammate
   ```

3. **Monitor CI**:
   ```bash
   gh pr checks
   ```

4. **Address feedback**

5. **Merge when approved**:
   ```bash
   gh pr merge --squash
   ```

## Integration with Other Commands

- `/tdd` - Tests should already be written
- `/execute` - Verify after each batch
- `/improve` - Verify improvements don't break anything
- `/review` - Verification happens before review
