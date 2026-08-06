# API Documentation

Load when documenting a public API, endpoints, or exported symbols.


**Function documentation (JSDoc/TSDoc)**:

```typescript
/**
 * Authenticates a user with email and password.
 *
 * @param email - User's email address
 * @param password - User's password (will be hashed for comparison)
 * @param options - Optional authentication options
 * @param options.rememberMe - Keep user logged in for extended period
 * @param options.mfa - Multi-factor authentication token
 *
 * @returns Authentication result with token and user data
 * @throws {ValidationError} If email or password is invalid
 * @throws {AuthenticationError} If credentials don't match
 * @throws {AccountLockedError} If account is locked due to failed attempts
 *
 * @example
 * ```typescript
 * const result = await authenticateUser(
 *   'user@example.com',
 *   'securePassword123',
 *   { rememberMe: true }
 * );
 * console.log(result.token); // JWT token
 * console.log(result.user);  // User object
 * ```
 *
 * @example
 * ```typescript
 * // With MFA
 * const result = await authenticateUser(
 *   'user@example.com',
 *   'password',
 *   { mfa: '123456' }
 * );
 * ```
 *
 * @see {@link createUser} for user registration
 * @see {@link refreshToken} for token renewal
 *
 * @since 1.0.0
 * @public
 */
export async function authenticateUser(
  email: string,
  password: string,
  options?: AuthOptions
): Promise<AuthResult> {
  // implementation
}
```

**Class documentation**:

```typescript
/**
 * Manages user sessions and authentication state.
 *
 * @remarks
 * This class handles session creation, validation, and expiration.
 * Sessions are stored in Redis with automatic expiration.
 *
 * @example
 * ```typescript
 * const sessionManager = new SessionManager(redisClient);
 *
 * // Create session
 * const session = await sessionManager.create(userId, {
 *   expiresIn: '7d'
 * });
 *
 * // Validate session
 * const isValid = await sessionManager.validate(session.id);
 *
 * // Destroy session
 * await sessionManager.destroy(session.id);
 * ```
 *
 * @public
 */
export class SessionManager {
  /**
   * Creates a new session manager.
   *
   * @param redisClient - Redis client instance for session storage
   * @param options - Optional configuration
   */
  constructor(
    private redisClient: Redis,
    private options?: SessionManagerOptions
  ) {}

  /**
   * Creates a new session for a user.
   *
   * @param userId - ID of the user to create session for
   * @param options - Session creation options
   * @returns Created session with ID and expiration
   */
  async create(
    userId: string,
    options?: CreateSessionOptions
  ): Promise<Session> {
    // implementation
  }
}
```

