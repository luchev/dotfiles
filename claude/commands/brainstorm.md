# Brainstorm Command

**Description**: You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores requirements and design before implementation.

## When to Use

Use this command before:
- Creating new features
- Building new components
- Adding functionality
- Modifying existing behavior
- Any creative development work

## Process

### 1. Explore Context
- Review relevant files, documentation, and recent commits
- Understand the current system architecture
- Identify constraints and dependencies

### 2. Ask Clarifying Questions
Ask questions one at a time to understand:
- Purpose: Why are we building this?
- Constraints: What are the technical/business limitations?
- Success criteria: How will we know it's done right?
- User impact: Who will use this and how?

### 3. Propose Approaches
Present 2-3 different approaches with:
- Trade-offs for each approach
- Pros and cons
- Your recommendation with reasoning
- Resource/complexity estimates

### 4. Present Design Incrementally
Get approval for each major section:
- Architecture overview
- Data models
- API contracts
- User interface (if applicable)
- Error handling strategy

### 5. Document Design
Save the design to `docs/designs/YYYY-MM-DD-<topic>.md` with:
- Problem statement
- Proposed solution
- Architecture diagrams (if needed)
- Implementation approach
- Testing strategy
- Rollout plan

### 6. Commit Design
Create a commit with the design document before implementation

### 7. Transition
After design is approved, transition to the `/plan` command to create detailed implementation steps

## Key Principles

- **Even simple projects need design** - A todo list, single function, or config change still needs design (though the design may be brief)
- **Get approval incrementally** - Don't write the entire design at once
- **Ask before assuming** - Clarify requirements rather than guessing
- **Document decisions** - Record why choices were made

## Anti-Patterns to Avoid

❌ Skipping brainstorming for "simple" projects
❌ Writing code before design approval
❌ Making assumptions about requirements
❌ Designing everything in isolation without approval
❌ Moving to implementation without documenting decisions
