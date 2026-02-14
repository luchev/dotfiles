# Improve Command

**Description**: Make targeted code improvements focusing on quality, performance, maintainability, and best practices.

## When to Use

Use this command to:
- Refactor complex code
- Improve code readability
- Optimize performance
- Apply best practices
- Reduce technical debt
- Modernize legacy code

## Improvement Categories

### 1. Code Quality Improvements

**Focus areas**:
- Simplify complex logic
- Improve naming
- Reduce duplication
- Extract functions/modules
- Enhance readability

**Example: Simplify Complex Logic**

```typescript
// ❌ Before: Complex nested conditions
function processUser(user) {
  if (user) {
    if (user.isActive) {
      if (user.permissions && user.permissions.includes('admin')) {
        if (user.lastLogin > Date.now() - 86400000) {
          return { status: 'authorized', level: 'admin' };
        }
      }
    }
  }
  return { status: 'unauthorized' };
}

// ✅ After: Early returns and clear logic
function processUser(user) {
  if (!user || !user.isActive) {
    return { status: 'unauthorized' };
  }

  const isAdmin = user.permissions?.includes('admin');
  const recentLogin = user.lastLogin > Date.now() - 86400000;

  if (isAdmin && recentLogin) {
    return { status: 'authorized', level: 'admin' };
  }

  return { status: 'unauthorized' };
}
```

**Example: Improve Naming**

```typescript
// ❌ Before: Vague names
function process(d) {
  const temp = d.map(x => x * 2);
  return temp.filter(y => y > 10);
}

// ✅ After: Descriptive names
function getDoubledValuesAboveThreshold(numbers) {
  const doubledNumbers = numbers.map(num => num * 2);
  const threshold = 10;
  return doubledNumbers.filter(doubled => doubled > threshold);
}
```

**Example: Reduce Duplication**

```typescript
// ❌ Before: Duplicated logic
function createUser(data) {
  if (!data.email || !data.email.includes('@')) {
    throw new Error('Invalid email');
  }
  if (!data.password || data.password.length < 8) {
    throw new Error('Password too short');
  }
  // create user...
}

function updateUser(id, data) {
  if (!data.email || !data.email.includes('@')) {
    throw new Error('Invalid email');
  }
  if (!data.password || data.password.length < 8) {
    throw new Error('Password too short');
  }
  // update user...
}

// ✅ After: Extract validation
function validateUserData(data) {
  if (!data.email || !data.email.includes('@')) {
    throw new Error('Invalid email');
  }
  if (!data.password || data.password.length < 8) {
    throw new Error('Password too short');
  }
}

function createUser(data) {
  validateUserData(data);
  // create user...
}

function updateUser(id, data) {
  validateUserData(data);
  // update user...
}
```

### 2. Performance Improvements

**Focus areas**:
- Optimize algorithms
- Reduce unnecessary work
- Cache expensive operations
- Lazy load resources
- Improve database queries

**Example: Optimize Algorithm**

```typescript
// ❌ Before: O(n²) lookup
function findCommonElements(arr1, arr2) {
  const common = [];
  for (const item1 of arr1) {
    for (const item2 of arr2) {
      if (item1 === item2) {
        common.push(item1);
      }
    }
  }
  return common;
}

// ✅ After: O(n) with Set
function findCommonElements(arr1, arr2) {
  const set2 = new Set(arr2);
  return arr1.filter(item => set2.has(item));
}
```

**Example: Cache Expensive Operations**

```typescript
// ❌ Before: Recalculate every time
function getExpensiveData() {
  const data = performExpensiveOperation(); // 500ms
  return transformData(data);
}

// ✅ After: Cache with TTL
const cache = new Map();
const CACHE_TTL = 60000; // 1 minute

function getExpensiveData() {
  const cached = cache.get('data');
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.value;
  }

  const data = performExpensiveOperation();
  const transformed = transformData(data);

  cache.set('data', {
    value: transformed,
    timestamp: Date.now()
  });

  return transformed;
}
```

**Example: Optimize Database Queries**

```typescript
// ❌ Before: N+1 queries
async function getUsersWithPosts() {
  const users = await db.user.findMany();
  for (const user of users) {
    user.posts = await db.post.findMany({
      where: { userId: user.id }
    });
  }
  return users;
}

// ✅ After: Single query with JOIN
async function getUsersWithPosts() {
  return await db.user.findMany({
    include: {
      posts: true
    }
  });
}
```

### 3. Modernization Improvements

**Focus areas**:
- Use modern language features
- Update to current best practices
- Replace deprecated APIs
- Improve type safety
- Leverage new frameworks/libraries

**Example: Use Modern JavaScript**

```javascript
// ❌ Before: Old-style JavaScript
var users = [];
for (var i = 0; i < data.length; i++) {
  if (data[i].age >= 18) {
    users.push({
      name: data[i].name,
      email: data[i].email
    });
  }
}

// ✅ After: Modern ES6+
const users = data
  .filter(user => user.age >= 18)
  .map(({ name, email }) => ({ name, email }));
```

**Example: Improve Type Safety (TypeScript)**

```typescript
// ❌ Before: Loose typing
function processData(data: any) {
  return data.items.map(item => ({
    id: item.id,
    value: item.value * 2
  }));
}

// ✅ After: Strong typing
interface Item {
  id: string;
  value: number;
}

interface DataResponse {
  items: Item[];
}

interface ProcessedItem {
  id: string;
  value: number;
}

function processData(data: DataResponse): ProcessedItem[] {
  return data.items.map(item => ({
    id: item.id,
    value: item.value * 2
  }));
}
```

### 4. Error Handling Improvements

**Focus areas**:
- Add proper error handling
- Create custom error types
- Improve error messages
- Add error recovery
- Log errors appropriately

**Example: Better Error Handling**

```typescript
// ❌ Before: Poor error handling
function parseConfig(file) {
  const content = fs.readFileSync(file);
  return JSON.parse(content);
}

// ✅ After: Comprehensive error handling
class ConfigError extends Error {
  constructor(message, cause) {
    super(message);
    this.name = 'ConfigError';
    this.cause = cause;
  }
}

function parseConfig(file) {
  let content;

  try {
    content = fs.readFileSync(file, 'utf-8');
  } catch (error) {
    throw new ConfigError(
      `Failed to read config file: ${file}`,
      error
    );
  }

  try {
    return JSON.parse(content);
  } catch (error) {
    throw new ConfigError(
      `Failed to parse config file: ${file}. Invalid JSON.`,
      error
    );
  }
}
```

### 5. Architecture Improvements

**Focus areas**:
- Improve separation of concerns
- Reduce coupling
- Enhance modularity
- Apply design patterns
- Clarify dependencies

**Example: Separate Concerns**

```typescript
// ❌ Before: Mixed concerns
class UserController {
  async createUser(req, res) {
    // Validation
    if (!req.body.email || !req.body.password) {
      return res.status(400).json({ error: 'Missing fields' });
    }

    // Business logic
    const hashedPassword = await bcrypt.hash(req.body.password, 10);

    // Database access
    const user = await db.query(
      'INSERT INTO users (email, password) VALUES ($1, $2)',
      [req.body.email, hashedPassword]
    );

    // Response
    res.json({ id: user.id });
  }
}

// ✅ After: Separated concerns
// Validation layer
class UserValidator {
  static validate(data) {
    if (!data.email || !data.password) {
      throw new ValidationError('Missing required fields');
    }
  }
}

// Service layer (business logic)
class UserService {
  async createUser(email, password) {
    const hashedPassword = await bcrypt.hash(password, 10);
    return await this.userRepository.create(email, hashedPassword);
  }
}

// Repository layer (data access)
class UserRepository {
  async create(email, hashedPassword) {
    return await db.query(
      'INSERT INTO users (email, password) VALUES ($1, $2)',
      [email, hashedPassword]
    );
  }
}

// Controller layer (HTTP handling)
class UserController {
  constructor(userService) {
    this.userService = userService;
  }

  async createUser(req, res) {
    try {
      UserValidator.validate(req.body);
      const user = await this.userService.createUser(
        req.body.email,
        req.body.password
      );
      res.json({ id: user.id });
    } catch (error) {
      if (error instanceof ValidationError) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }
}
```

## Improvement Process

### 1. Identify Improvement Opportunities

Run analysis first (use `/analyze` command):
```bash
npm run lint
npm test -- --coverage
npx plato -r -d report src/
```

### 2. Prioritize Improvements

**Priority matrix**:

| Impact | Effort | Priority |
|--------|--------|----------|
| High | Low | **Critical** - Do immediately |
| High | High | **Important** - Plan carefully |
| Low | Low | **Quick win** - Do when free |
| Low | High | **Avoid** - Not worth it |

### 3. Write Tests First

Before improving code:
```typescript
// 1. Write test for current behavior
test('existing behavior works', () => {
  const result = oldFunction(input);
  expect(result).toEqual(expectedOutput);
});

// 2. Improve the code

// 3. Verify test still passes
```

### 4. Improve Incrementally

**Don't**: Rewrite everything at once
**Do**: Make small, tested improvements

```bash
# Example flow
git checkout -b improve/simplify-user-validation

# Improvement 1
# - Refactor validation logic
# - Run tests
git commit -m "refactor: simplify user validation logic"

# Improvement 2
# - Extract helper functions
# - Run tests
git commit -m "refactor: extract validation helpers"

# Improvement 3
# - Add better error messages
# - Run tests
git commit -m "improve: enhance validation error messages"
```

### 5. Measure Impact

**Before improvement**:
```bash
# Measure performance
time npm test
# Measure complexity
npx plato -r -d before src/
# Measure bundle size
du -sh dist/
```

**After improvement**:
```bash
# Compare metrics
time npm test        # Should be same or faster
npx plato -r -d after src/  # Should show lower complexity
du -sh dist/         # Should be same or smaller
```

## Improvement Checklist

Before claiming improvement is complete:

- [ ] Tests pass (all existing tests still work)
- [ ] No new warnings or errors
- [ ] Code is simpler/more readable
- [ ] Performance is same or better
- [ ] Test coverage maintained or improved
- [ ] Documentation updated if needed
- [ ] Breaking changes documented
- [ ] Teammates can understand the changes

## Safe Refactoring Techniques

### 1. Extract Function

```typescript
// Before
function processOrder(order) {
  // Validate order (10 lines)
  // Calculate total (15 lines)
  // Apply discount (20 lines)
  // Process payment (25 lines)
}

// After
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order);
  const final = applyDiscount(total, order.coupon);
  return processPayment(final, order.paymentMethod);
}
```

### 2. Replace Conditional with Polymorphism

```typescript
// Before
function getPrice(item) {
  if (item.type === 'book') {
    return item.basePrice * 0.9;
  } else if (item.type === 'electronics') {
    return item.basePrice * 1.2;
  } else {
    return item.basePrice;
  }
}

// After
class Item {
  getPrice() {
    return this.basePrice;
  }
}

class Book extends Item {
  getPrice() {
    return this.basePrice * 0.9;
  }
}

class Electronics extends Item {
  getPrice() {
    return this.basePrice * 1.2;
  }
}
```

### 3. Introduce Parameter Object

```typescript
// Before
function createUser(name, email, age, address, phone, country) {
  // ...
}

// After
interface UserData {
  name: string;
  email: string;
  age: number;
  address: string;
  phone: string;
  country: string;
}

function createUser(userData: UserData) {
  // ...
}
```

## Common Improvement Patterns

### Replace Magic Numbers with Constants

```typescript
// ❌ Before
if (user.age >= 18) { ... }
setTimeout(() => { ... }, 3600000);

// ✅ After
const LEGAL_AGE = 18;
const ONE_HOUR_MS = 60 * 60 * 1000;

if (user.age >= LEGAL_AGE) { ... }
setTimeout(() => { ... }, ONE_HOUR_MS);
```

### Use Guard Clauses

```typescript
// ❌ Before
function process(data) {
  if (data) {
    if (data.isValid) {
      if (data.items.length > 0) {
        // Main logic here
      }
    }
  }
}

// ✅ After
function process(data) {
  if (!data) return;
  if (!data.isValid) return;
  if (data.items.length === 0) return;

  // Main logic here
}
```

### Prefer Composition Over Inheritance

```typescript
// ❌ Before: Deep inheritance
class Animal { }
class Mammal extends Animal { }
class Dog extends Mammal { }
class Poodle extends Dog { }

// ✅ After: Composition
class Animal {
  constructor(private traits: Traits) { }
}

const poodle = new Animal({
  species: 'dog',
  breed: 'poodle',
  abilities: ['bark', 'fetch']
});
```

## After Improvement

Typically follow with:
- `/verify` - Ensure all tests pass
- `/document` - Update documentation
- Create PR for code review
