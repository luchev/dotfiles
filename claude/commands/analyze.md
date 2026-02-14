# Analyze Command

**Description**: Perform comprehensive code and architecture analysis to identify issues, patterns, and improvement opportunities.

## When to Use

Use this command to:
- Review codebase architecture
- Identify code smells and anti-patterns
- Find performance bottlenecks
- Check security vulnerabilities
- Assess code quality
- Understand complex codebases
- Prepare for refactoring

## Analysis Types

### 1. Architecture Analysis

**Goal**: Understand system structure and design patterns

```markdown
## Architecture Analysis Report

### System Overview
- **Type**: [Monolith/Microservices/Serverless/etc.]
- **Language/Framework**: [Tech stack]
- **Scale**: [Number of services, files, LOC]

### Component Structure
```
src/
├── api/          # REST API endpoints
├── services/     # Business logic
├── models/       # Data models
├── utils/        # Utilities
└── config/       # Configuration
```

### Design Patterns Used
- Repository pattern (data access)
- Factory pattern (object creation)
- Observer pattern (event handling)
- [etc.]

### Architecture Strengths
✅ Clear separation of concerns
✅ Well-defined API contracts
✅ Good test coverage

### Architecture Concerns
⚠️ Tight coupling between services
⚠️ No clear error handling strategy
⚠️ Configuration scattered across files

### Recommendations
1. Introduce dependency injection
2. Centralize error handling
3. Consolidate configuration
```

### 2. Code Quality Analysis

**Goal**: Identify code smells and quality issues

**Analyze for**:
- Complexity (cyclomatic complexity, nesting depth)
- Duplication (repeated code patterns)
- Naming (clarity, consistency)
- Organization (file structure, module boundaries)
- Documentation (comments, README, API docs)

**Example output**:
```markdown
## Code Quality Issues

### High Complexity
- `processOrder()` (src/orders.ts:45) - Complexity: 23
  - Too many branches and conditions
  - Recommend: Extract into smaller functions

### Code Duplication
- User validation logic repeated in 5 files:
  - src/api/users.ts:12
  - src/api/auth.ts:34
  - src/services/user-service.ts:56
  - [etc.]
  - Recommend: Create shared validation module

### Inconsistent Naming
- Mix of camelCase and snake_case
- Vague names: `process()`, `handle()`, `doThing()`
  - Recommend: Establish naming conventions

### Missing Documentation
- No JSDoc comments on public API functions
- README outdated (last updated 2024)
- No architecture documentation
```

### 3. Performance Analysis

**Goal**: Identify performance bottlenecks

**Check for**:
- N+1 queries
- Inefficient algorithms
- Memory leaks
- Large bundle sizes
- Slow database queries
- Blocking operations

**Example output**:
```markdown
## Performance Issues

### Database N+1 Queries
**Location**: `src/api/users.ts:getUserOrders()`
```typescript
// Current (N+1 problem)
const users = await User.findAll();
for (const user of users) {
  user.orders = await Order.findByUserId(user.id); // ❌ N queries
}

// Recommended
const users = await User.findAll({
  include: [{ model: Order }] // ✅ Single query with JOIN
});
```

### Inefficient Algorithm
**Location**: `src/utils/search.ts:findItems()`
- Currently: O(n²) nested loop
- Recommend: Use hash map for O(n) lookup

### Bundle Size
- Main bundle: 2.3 MB (uncompressed)
- Large dependencies:
  - moment.js (288 KB) → Replace with date-fns
  - lodash (71 KB) → Use tree-shaking
- Recommend: Code splitting, lazy loading

### Memory Leak
**Location**: `src/websocket.ts:handleConnection()`
- Event listeners not removed on disconnect
- Recommend: Cleanup in disconnect handler
```

### 4. Security Analysis

**Goal**: Identify security vulnerabilities

**Check for**:
- SQL injection vulnerabilities
- XSS vulnerabilities
- CSRF protection
- Authentication/authorization issues
- Secrets in code
- Dependency vulnerabilities

**Example output**:
```markdown
## Security Issues

### HIGH: SQL Injection Risk
**Location**: `src/api/search.ts:28`
```typescript
// ❌ VULNERABLE
const query = `SELECT * FROM users WHERE name = '${req.query.name}'`;

// ✅ SECURE
const query = `SELECT * FROM users WHERE name = ?`;
db.execute(query, [req.query.name]);
```

### MEDIUM: Missing CSRF Protection
**Location**: `src/api/routes.ts`
- POST/PUT/DELETE endpoints lack CSRF tokens
- Recommend: Add CSRF middleware

### MEDIUM: Secrets in Code
**Location**: `src/config/database.ts:5`
```typescript
// ❌ Hardcoded secret
const API_KEY = 'sk_live_abc123...';

// ✅ Use environment variables
const API_KEY = process.env.API_KEY;
```

### LOW: Missing Security Headers
- No Content-Security-Policy
- No X-Frame-Options
- Recommend: Add helmet.js middleware

### Dependency Vulnerabilities
```bash
npm audit
# Found 3 vulnerabilities (2 moderate, 1 high)
# Run npm audit fix
```
```

### 5. Test Coverage Analysis

**Goal**: Assess test quality and coverage

```markdown
## Test Coverage Report

### Overall Coverage
- Statements: 67% (target: 80%)
- Branches: 54% (target: 75%)
- Functions: 71% (target: 80%)
- Lines: 65% (target: 80%)

### Files Lacking Coverage

| File | Coverage | Missing Tests |
|------|----------|---------------|
| src/payment.ts | 23% | Error handling, edge cases |
| src/auth.ts | 45% | Token refresh, expiration |
| src/validation.ts | 12% | All validation rules |

### Test Quality Issues
- ❌ Tests that always pass (tautologies)
- ❌ No integration tests
- ❌ No edge case testing
- ❌ Mocking everything (not testing real behavior)

### Recommendations
1. Add tests for payment error scenarios
2. Create integration test suite
3. Test edge cases (empty inputs, large data, etc.)
4. Reduce mocking, test real interactions
```

### 6. Dependency Analysis

**Goal**: Review dependencies for issues

```markdown
## Dependency Analysis

### Outdated Dependencies
```bash
npm outdated
# Package     Current  Wanted  Latest
# react       17.0.2   17.0.2  18.2.0
# typescript  4.5.0    4.9.5   5.1.6
```

### Unused Dependencies
- `lodash` - imported but never used
- `axios` - replaced by fetch, still in package.json

### Dependency Weight
- Total dependencies: 342 (156 direct, 186 transitive)
- node_modules size: 287 MB
- Recommend: Audit and remove unused packages

### License Concerns
- `some-package` - GPL-3.0 (incompatible with MIT project)
- Recommend: Find alternative with compatible license

### Security Alerts
```bash
npm audit
# 2 vulnerabilities (1 moderate, 1 high)
# Run npm audit fix to resolve
```
```

## Analysis Process

### Step 1: Scope the Analysis

Define what to analyze:
- Entire codebase or specific modules?
- What aspects? (architecture, performance, security, etc.)
- What's the goal? (refactoring, optimization, review)

### Step 2: Gather Data

```bash
# Code metrics
npx cloc src/

# Dependencies
npm list --depth=0
npm outdated

# Test coverage
npm test -- --coverage

# Security scan
npm audit
npx snyk test

# Bundle size
npx webpack-bundle-analyzer

# Type coverage (TypeScript)
npx type-coverage

# Linting
npx eslint src/ --format=json
```

### Step 3: Analyze Patterns

Look for:
- Repeated code patterns
- Common anti-patterns
- Architectural inconsistencies
- Performance bottlenecks
- Security vulnerabilities

### Step 4: Prioritize Findings

Categorize issues:
- **Critical**: Security vulnerabilities, data loss risks
- **High**: Performance problems, major bugs
- **Medium**: Code quality, maintainability
- **Low**: Style, minor improvements

### Step 5: Generate Report

Create actionable report with:
- Executive summary
- Detailed findings
- Code examples
- Recommendations
- Priority levels
- Estimated effort

## Analysis Tools

### Static Analysis
```bash
# JavaScript/TypeScript
npx eslint src/
npx tsc --noEmit

# Python
pylint src/
mypy src/

# Go
golangci-lint run
```

### Security Scanning
```bash
# Dependency scanning
npm audit
snyk test

# Code scanning
semgrep --config=auto

# Secret detection
git-secrets --scan
truffleHog --regex --entropy=False .
```

### Performance Profiling
```bash
# Node.js profiling
node --prof app.js
node --prof-process isolate-*.log

# Chrome DevTools
lighthouse https://example.com

# Load testing
artillery quick --count 100 --num 10 https://example.com
```

### Code Metrics
```bash
# Complexity
npx plato -r -d report src/

# Bundle analysis
npx webpack-bundle-analyzer

# Type coverage
npx type-coverage --detail
```

## Report Template

```markdown
# Code Analysis Report: [Project Name]

**Date**: [YYYY-MM-DD]
**Analyzer**: [Name]
**Scope**: [What was analyzed]

## Executive Summary

[2-3 paragraphs summarizing key findings and recommendations]

## Critical Issues (Must Fix)

### Issue 1: [Title]
- **Severity**: Critical
- **Category**: [Security/Performance/Bug]
- **Location**: [File:line]
- **Impact**: [What breaks/risk]
- **Recommendation**: [How to fix]
- **Effort**: [Time estimate]

## High Priority Issues

[Similar format]

## Medium Priority Issues

[Similar format]

## Low Priority Issues

[Similar format]

## Metrics Dashboard

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Test Coverage | 67% | 80% | ⚠️ |
| Performance Score | 72 | 90 | ⚠️ |
| Security Score | 85 | 95 | ⚠️ |
| Code Quality | B | A | ⚠️ |
| Dependencies | 342 | <200 | ❌ |

## Recommendations

1. **Immediate** (this week):
   - Fix critical security issues
   - Resolve high-severity bugs

2. **Short-term** (this month):
   - Improve test coverage
   - Refactor complex functions
   - Update critical dependencies

3. **Long-term** (this quarter):
   - Architectural improvements
   - Performance optimization
   - Documentation updates

## Next Steps

[Specific actionable items]

## Appendix

### Detailed Metrics
[Full data, charts, graphs]

### Tool Outputs
[Raw tool outputs if relevant]
```

## After Analysis

Typically transition to:
- `/improve` - Implement recommended improvements
- `/plan` - Plan refactoring work
- `/document` - Document findings for team
- `/brainstorm` - Design architectural changes
