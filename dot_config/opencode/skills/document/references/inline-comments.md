# Inline Code Comments

Load when adding docstrings or inline comments.


**When to comment**:
- Complex algorithms
- Non-obvious business logic
- Workarounds and hacks
- "Why" not "what"

**Examples**:

```typescript
// ❌ Bad: Comments the obvious
// Increment counter by 1
counter++;

// ✅ Good: Explains why
// Use exponential backoff to avoid overwhelming the API
// after rate limit errors (429 responses)
await sleep(Math.pow(2, retryCount) * 1000);

// ✅ Good: Explains complex logic
// We must check permissions before checking existence
// to avoid leaking information about private resources
// (timing attacks could reveal if private resource exists)
if (!hasPermission(user, resourceId)) {
  throw new NotFoundError(); // Not "Forbidden"
}
```

