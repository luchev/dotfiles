# Claude Code Commands

This directory contains custom commands for Claude Code that combine the best ideas from [obra/superpowers](https://github.com/obra/superpowers) and [SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework).

## Available Commands

### Planning & Development

- **`brainstorm.md`** - Mandatory structured brainstorming before any creative work
  - Explore context and requirements
  - Ask clarifying questions
  - Propose multiple approaches with trade-offs
  - Document design decisions

- **`plan.md`** - Create detailed implementation plans with bite-sized tasks
  - Zero-context instructions (anyone can follow)
  - Test-driven approach (write test first)
  - Exact file paths and complete code examples
  - 2-5 minute actionable tasks

- **`execute.md`** - Execute plans with batch processing and checkpoints
  - Review plan before starting
  - Execute in batches of 3 tasks
  - Wait for feedback between batches
  - Verify all changes

### Code Quality

- **`tdd.md`** - Enforce test-driven development (THE IRON LAW)
  - Red-Green-Refactor cycle
  - Write failing test first (no exceptions)
  - Watch test fail, then implement
  - Verification checklist

- **`debug.md`** - Systematic debugging (faster than guess-and-check)
  - 5-phase debugging process
  - Reproduce → Isolate → Root Cause → Fix → Verify
  - 95% of "no root cause" = incomplete investigation

- **`improve.md`** - Code improvements and refactoring
  - Quality improvements (complexity, naming, duplication)
  - Performance optimization
  - Modernization and best practices
  - Safe refactoring techniques

- **`review.md`** - Comprehensive code review
  - Pre-commit self-review
  - Pull request review checklist
  - Security, performance, testing focus
  - Constructive feedback guidelines

### Research & Analysis

- **`research.md`** - Deep web research with multi-hop reasoning
  - Planning-only, Intent-planning, Unified strategies
  - Quality scoring of sources
  - Comparative and technology evaluation
  - Research report templates

- **`analyze.md`** - Code and architecture analysis
  - Architecture analysis
  - Code quality metrics
  - Performance profiling
  - Security scanning
  - Dependency analysis

### Documentation & Verification

- **`document.md`** - Generate comprehensive documentation
  - README templates
  - API documentation (JSDoc/TSDoc)
  - Architecture Decision Records (ADR)
  - User guides and tutorials
  - Changelogs

- **`verify.md`** - Verification before completion
  - Comprehensive pre-PR checklist
  - Test, lint, build, security checks
  - Git status verification
  - CI/CD integration

### Development Tools

- **`worktree.md`** - Git worktree management
  - Work on multiple branches simultaneously
  - PR review without disturbing work
  - Parallel testing on different branches
  - Worktree best practices and workflows

## Command Workflow

Typical development flow using these commands:

```
1. /brainstorm  → Design and explore requirements
2. /plan        → Create detailed implementation plan
3. /tdd         → Write tests first (always)
4. /execute     → Implement in verified batches
5. /verify      → Comprehensive checks before PR
6. /review      → Code review process
7. /document    → Update documentation
```

## Usage

These commands are markdown files that provide structured guidance for Claude Code. To use them:

1. Reference them in conversations: "Use the /plan command approach"
2. Copy relevant sections into CLAUDE.md for project-specific workflows
3. Adapt them to your team's needs

## Command Philosophy

These commands follow several key principles:

### From obra/superpowers:
- **Process discipline** - Mandatory brainstorming, TDD, verification
- **Bite-sized tasks** - 2-5 minute increments with verification
- **No code without tests** - The Iron Law
- **Systematic approach** - Structured debugging, planning, execution
- **Batch processing** - Work in chunks with feedback points

### From SuperClaude Framework:
- **Comprehensive coverage** - Research, analysis, documentation
- **Quality scoring** - Evaluate sources and solutions
- **Multi-expert perspective** - Multiple approaches, trade-offs
- **Automation** - Verification scripts, CI/CD integration
- **Adaptability** - Different strategies for different needs

### Core Principles:
- **Test-driven everything** - No code without failing test first
- **Document decisions** - Write down the "why"
- **Verify before shipping** - Comprehensive checks
- **Incremental progress** - Small, verified steps
- **Learn from failures** - Systematic investigation

## Customization

Feel free to modify these commands for your needs:

```bash
# Edit commands
cd ~/.claude/commands
vi brainstorm.md

# Create new commands
cp plan.md my-custom-command.md
vi my-custom-command.md

# Share with team
git add commands/
git commit -m "docs: add custom Claude commands"
```

## Integration with Projects

Add command references to project CLAUDE.md:

```markdown
# Project Guidelines

Before any feature work, use `/brainstorm` command approach:
- Review requirements
- Ask clarifying questions
- Propose approaches
- Document design

All code must follow `/tdd` command:
- Write failing test first
- Watch it fail
- Implement minimal code
- Verify test passes
```

## Sources

These commands synthesize best practices from:

- **[obra/superpowers](https://github.com/obra/superpowers)** - Agentic skills framework
  - Systematic debugging
  - Test-driven development
  - Writing plans
  - Executing plans
  - Brainstorming

- **[SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)** - Configuration framework for Claude Code
  - Deep research capabilities
  - Code analysis and improvement
  - Multi-expert analysis
  - Comprehensive command set

## Contributing

To improve these commands:

1. Try the command in practice
2. Note what works and what doesn't
3. Update the command with improvements
4. Share learnings with the team

## License

These commands are part of your dotfiles and can be freely modified and shared.
