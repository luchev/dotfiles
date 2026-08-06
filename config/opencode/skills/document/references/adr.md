# Architecture Decision Records

Load when recording an architectural decision, including the ADR template and a worked example.


**ADR (Architecture Decision Record)**:

```markdown
# ADR 001: Use PostgreSQL for Primary Database

## Status

Accepted

## Context

We need to choose a primary database for our application. Requirements:
- ACID compliance for financial transactions
- Complex relational data (users, orders, products, inventory)
- Strong consistency guarantees
- Good TypeScript/Node.js support
- Scalable to millions of records

## Decision

Use PostgreSQL as the primary database.

## Consequences

### Positive
- Battle-tested ACID compliance
- Rich query capabilities (JOINs, aggregations, CTEs)
- JSON support for flexible fields
- Excellent TypeScript/Node.js libraries (pg, Prisma, TypeORM)
- Wide ecosystem and community support
- Good performance for complex queries
- Strong data integrity guarantees

### Negative
- More complex setup than document databases
- Requires schema migrations
- Vertical scaling limitations (though significant)
- More expensive than some NoSQL options

### Neutral
- Need to learn SQL if team unfamiliar
- Requires careful index management for performance

## Alternatives Considered

### MongoDB
- **Pros**: Flexible schema, easy to start
- **Cons**: Weaker consistency guarantees, less suitable for relational data
- **Why not**: Our data is inherently relational (orders → users, products → categories)

### MySQL
- **Pros**: Similar to PostgreSQL, widely known
- **Cons**: Less feature-rich, weaker JSON support
- **Why not**: PostgreSQL offers better feature set with similar trade-offs

## Implementation

- Use Prisma as ORM for type-safe queries
- Set up master-replica for read scaling
- Use connection pooling (PgBouncer)
- Regular backups to S3

## Related Decisions

- ADR 002: Use Prisma as ORM
- ADR 003: Redis for caching

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Database Benchmarks](internal-link)
```

