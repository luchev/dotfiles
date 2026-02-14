# Research Command

**Description**: Perform deep, autonomous web research with adaptive multi-hop reasoning and quality scoring.

## When to Use

Use this command when you need to:
- Research new technologies or frameworks
- Find best practices and patterns
- Investigate solutions to technical problems
- Compare different approaches or tools
- Gather information from multiple sources
- Stay current with latest developments

## Research Strategies

### Strategy 1: Planning-Only (Low Risk)

**When to use**: Initial exploration, broad topics

**Approach**:
1. Identify 3-5 key search queries
2. Plan the research approach
3. Present the plan for approval
4. Execute searches after approval

**Example**:
```markdown
Research plan for "React state management in 2026":
1. Search: "React state management best practices 2026"
2. Search: "Zustand vs Redux comparison 2026"
3. Search: "React Server Components state management"
4. Search: "TanStack Query vs SWR 2026"
5. Synthesize findings and recommend approach
```

### Strategy 2: Intent-Planning (Medium Risk)

**When to use**: Focused questions, specific technical queries

**Approach**:
1. Start with initial search
2. Analyze results and identify gaps
3. Plan follow-up queries based on findings
4. Execute iterative searches (up to 3 hops)
5. Synthesize and present findings

**Example**:
```markdown
Intent: Find best PostgreSQL indexing strategy for time-series data

Search 1: "PostgreSQL time-series indexing 2026"
→ Found: BRIN indexes, partitioning
→ Gap: Performance comparison needed

Search 2: "PostgreSQL BRIN vs B-tree performance time-series"
→ Found: Benchmarks, use cases
→ Gap: Implementation examples needed

Search 3: "PostgreSQL time-series partitioning implementation"
→ Found: Complete implementation guide

Synthesis: [Comprehensive answer with sources]
```

### Strategy 3: Unified (High Risk)

**When to use**: Complex, multi-faceted questions requiring deep investigation

**Approach**:
1. Decompose question into sub-questions
2. Adaptive multi-hop searches (up to 5 iterations)
3. Quality scoring of sources
4. Cross-reference and verify findings
5. Synthesize comprehensive answer

**Example**:
```markdown
Question: How to implement real-time collaboration in a React app?

Sub-questions:
1. What are WebSocket alternatives in 2026?
2. How to handle conflict resolution?
3. What's the best state synchronization approach?
4. How to ensure data consistency?

Multi-hop search tree:
- WebSocket → WebRTC → WebTransport
- CRDT → Yjs → Automerge comparison
- Optimistic updates → Rollback strategies
- Backend sync → PostgreSQL LISTEN/NOTIFY

Final synthesis with quality-scored sources
```

## Research Output Format

### Standard Research Report

```markdown
# Research Report: [Topic]

## Summary
[2-3 sentence executive summary]

## Key Findings

### Finding 1: [Title]
- **Source**: [URL with credibility score]
- **Details**: [Key points]
- **Relevance**: [Why this matters]

### Finding 2: [Title]
- **Source**: [URL with credibility score]
- **Details**: [Key points]
- **Relevance**: [Why this matters]

[Additional findings...]

## Comparison Table

| Approach | Pros | Cons | Use Cases | Maturity |
|----------|------|------|-----------|----------|
| Option 1 | ... | ... | ... | ... |
| Option 2 | ... | ... | ... | ... |

## Recommendation

[Clear recommendation with reasoning]

## Implementation Guidance

[Practical next steps]

## Sources

1. [Source 1 - Title](URL) - [Reliability: High/Medium/Low]
2. [Source 2 - Title](URL) - [Reliability: High/Medium/Low]
...

## Follow-up Questions

[Questions that emerged during research]
```

## Quality Scoring Criteria

Rate sources on:

**Authority** (1-5):
- Official documentation: 5
- Established tech blogs: 4
- Community forums: 3
- Personal blogs: 2
- Unverified sources: 1

**Recency** (1-5):
- Last 3 months: 5
- Last 6 months: 4
- Last year: 3
- 1-2 years: 2
- Older: 1

**Relevance** (1-5):
- Directly answers question: 5
- Mostly relevant: 4
- Partially relevant: 3
- Tangentially related: 2
- Barely relevant: 1

**Overall Score**: (Authority + Recency + Relevance) / 3

Prioritize sources with scores > 4.0

## Research Best Practices

### DO:
✅ Use current year (2026) in searches
✅ Cross-reference multiple sources
✅ Look for official documentation first
✅ Check publication dates
✅ Verify claims against primary sources
✅ Note conflicting information
✅ Include source URLs in findings
✅ Synthesize, don't just summarize

### DON'T:
❌ Rely on a single source
❌ Use outdated information
❌ Make claims without sources
❌ Ignore contradictory evidence
❌ Copy content verbatim
❌ Skip verification of facts
❌ Present opinions as facts

## Advanced Techniques

### Comparative Research

```markdown
Research goal: Compare Next.js App Router vs Remix

Dimensions to compare:
1. Performance (metrics, benchmarks)
2. Developer experience (DX surveys, GitHub activity)
3. Ecosystem (packages, tooling)
4. Learning curve (documentation quality)
5. Production readiness (case studies)
6. Future trajectory (roadmaps, community)

For each dimension:
- Search for recent comparisons
- Find official benchmarks
- Check real-world case studies
- Gather community feedback
```

### Technology Evaluation

```markdown
Evaluating: Should we use Bun instead of Node.js?

Research checklist:
- [ ] Feature comparison
- [ ] Performance benchmarks
- [ ] Compatibility (npm packages, Docker, etc.)
- [ ] Production case studies
- [ ] Team learning curve
- [ ] Long-term support commitments
- [ ] Migration path and effort
- [ ] Community size and growth
- [ ] Security track record
- [ ] License and governance
```

### Problem-Solution Research

```markdown
Problem: High latency in API responses

Research approach:
1. Identify common causes
   - Search: "API latency optimization 2026"
2. Find diagnostic tools
   - Search: "API performance profiling tools"
3. Explore solutions
   - Caching strategies
   - Database optimization
   - CDN usage
   - Code optimization
4. Find implementation guides
5. Check for our specific stack (Node.js + PostgreSQL)
6. Gather benchmarks and case studies
```

## Follow-Up Actions

After research, typically transition to:
- `/brainstorm` - Design solution based on findings
- `/plan` - Create implementation plan
- `/document` - Document research findings for team

## Example Use Cases

```bash
# General research
/research What are the best practices for React performance optimization in 2026?

# Comparative research
/research Compare Prisma vs Drizzle ORM for PostgreSQL in production

# Problem-solving research
/research How to implement efficient real-time data synchronization between mobile app and backend?

# Technology evaluation
/research Should we migrate from REST to GraphQL for our API?

# Best practices research
/research What are the current best practices for securing JWT tokens in web applications?
```

## Research Quality Checklist

Before presenting research findings:

- [ ] Checked at least 5 high-quality sources
- [ ] Verified information is current (2026)
- [ ] Cross-referenced claims across sources
- [ ] Included official documentation
- [ ] Noted any conflicting information
- [ ] Provided source URLs for all claims
- [ ] Scored source quality
- [ ] Synthesized findings (not just summarized)
- [ ] Provided clear recommendations
- [ ] Identified gaps or follow-up questions
