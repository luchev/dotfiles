# The Ultimate Claude Code Guide
*Shortcuts, Hidden Features & Power User Tips*

## 🎯 Essential Keyboard Shortcuts

### General Controls
| Shortcut | Function |
|----------|----------|
| `Ctrl+C` | Cancel current generation |
| `Ctrl+D` | Exit session |
| `Ctrl+L` | Clear terminal screen (keeps history) |
| `Ctrl+O` | Toggle verbose output |
| `Ctrl+R` | Reverse search command history |
| `Ctrl+V` / `Cmd+V` | Paste images from clipboard |
| `Ctrl+B` | Background running tasks |
| `Esc` twice | **Rewind code/conversation** to previous state |
| `Shift+Tab` / `Alt+M` | **Cycle permission modes** (auto → ask → plan → off) |
| `Option+P` / `Alt+P` | Quick model switcher |
| `Option+T` / `Alt+T` | **Toggle extended thinking mode** |
| `?` | Show all shortcuts |

### Text Editing
| Shortcut | Function |
|----------|----------|
| `Ctrl+K` | Delete to end of line |
| `Ctrl+U` | Delete entire line |
| `Ctrl+Y` | Paste deleted text |
| `Alt+Y` | Cycle through paste history |
| `Alt+B` | Move cursor back one word |
| `Alt+F` | Move cursor forward one word |

### Vim Mode
Enable with `/vim`, then use standard vim navigation:
- **Mode switching**: `Esc` → Normal, `i/a/o` → Insert
- **Navigation**: `h/j/k/l`, `w/e/b`, `0/$`, `gg/G`
- **Editing**: `x`, `dd`, `yy`, `p`, `>>`, `.` (repeat)

---

## 🚀 Must-Know Slash Commands

### Session Management
```bash
/clear              # Clear conversation history
/resume             # Interactive session picker (then press R to rename, P to preview)
/resume name        # Resume specific session
/rename new-name    # Name current session for easy resume later
/rewind             # Undo code/conversation changes
/compact [focus]    # Compress conversation to reduce context
```

### Configuration
```bash
/config             # Open full settings interface
/model              # Switch AI model
/theme              # Change color theme
/output-style       # Set output formatting
/vim                # Enable vim mode
/sandbox            # Enable sandboxed bash
```

### Advanced Features
```bash
/plan               # Enter plan mode (read-only analysis)
/mcp                # Manage MCP server connections
/hooks              # Manage automation hooks
/context            # Visualize token usage
/cost               # Show token/cost statistics
/status             # Version, model, account info
```

### Productivity
```bash
/help               # Get help
Tab                 # Command/argument completion
↑/↓                 # Command history
```

---

## 💡 Hidden Features & Power Moves

### 1. **Permission Modes** (Press `Shift+Tab`)
Cycle through 4 modes:
- **Auto**: Claude acts freely
- **Ask**: Prompts before file changes
- **Plan**: Read-only (perfect for exploring codebases)
- **Off**: No tool usage

**Pro tip**: Use Plan mode before making changes: `claude --permission-mode plan` then ask Claude to explore your codebase and create a plan.

### 2. **Extended Thinking** (`Option+T` or `Alt+T`)
Reserves up to 31,999 tokens for internal reasoning before responding.

**When to use**:
- Complex architectural decisions
- Debugging tricky bugs
- Multi-step planning
- Performance optimization strategies

**Trigger words**: Include "ultrathink" in your message for one-time activation.

**Configure default**: `/config` → Enable thinking mode globally

### 3. **Parallel Sessions with Git Worktrees**
Run multiple Claude instances on different branches simultaneously:
```bash
git worktree add ../project-feature-a -b feature-a
cd ../project-feature-a
claude
# In another terminal:
git worktree add ../project-feature-b -b feature-b
cd ../project-feature-b
claude
```

### 4. **Image Pasting** (`Ctrl+V`)
Paste screenshots directly into Claude for:
- Design review
- Bug reports
- Architecture diagrams
- Error messages

### 5. **Background Tasks** (`Ctrl+B`)
Background long-running operations and continue working:
```bash
# Start a long test run
claude "run the full test suite"
# While it's running, press Ctrl+B
# Continue with other tasks
```

### 6. **Custom Slash Commands**
Create project-specific commands in `.claude/commands/`:

**Example**: `.claude/commands/test-all.md`
```markdown
---
description: Run all tests with coverage
---

Run the following tests in order:
1. `bazel test //src/git.internal.example/myservice:go_default_test`
2. `bin/coverage src/git.internal.example/myservice`

Then summarize the results.
```

Use with: `/test-all`

**Arguments**: Access with `$ARGUMENTS`, `$1`, `$2`, etc.

### 7. **Automation Hooks**
Create event-driven automations in `.claude/hooks/`:

**Auto-format after edits**: `.claude/hooks/post-tool-use.sh`
```bash
#!/bin/bash
if [[ "$TOOL_NAME" == "Edit" && "$FILE_PATH" == *.ts ]]; then
  prettier --write "$FILE_PATH"
fi
```

**Protect sensitive files**: `.claude/hooks/permission-request.sh`
```bash
#!/bin/bash
if [[ "$FILE_PATH" =~ \.env$ ]] || [[ "$FILE_PATH" =~ package-lock\.json$ ]]; then
  echo "Blocked: Sensitive file"
  exit 2  # Deny permission
fi
```

**Available events**: `PreToolUse`, `PostToolUse`, `PermissionRequest`, `UserPromptSubmit`, `SessionStart`, `SessionEnd`

### 8. **Agent Skills** (Automatic Expertise)
Create reusable expertise in `.claude/skills/my-skill/SKILL.md`:

```markdown
---
name: db-migration
description: Create database migrations following team conventions
allowed-tools: [Read, Write, Edit, Bash]
---

When creating database migrations:
1. Check existing migrations in `migrations/`
2. Follow naming: `YYYYMMDD_description.sql`
3. Always include rollback
4. Test with `make migrate-test`
```

**Progressive disclosure**: Keep SKILL.md < 500 lines, link to detailed docs that load on-demand.

### 9. **Subagents** (Parallel Research)
Claude automatically delegates complex tasks to specialized subagents.

**Built-in agents**:
- `general-purpose`: Multi-step research & code search
- Plan/explore agents for read-only analysis

**Trigger parallel research**: "Research X, Y, and Z in parallel"

**Key benefit**: Each subagent has its own context window.

### 10. **Conversation Compacting** (`/compact`)
Compress long conversations to free up context:
```bash
/compact focus on authentication changes
```

### 11. **Session Picker Shortcuts**
When running `/resume`:
- `↑/↓`: Navigate
- `P`: Preview session
- `R`: Rename session
- `/`: Search sessions
- `Enter`: Resume

### 12. **Headless Mode** (Scripting)
Use Claude in scripts:
```bash
# One-shot task
claude "analyze test coverage and suggest improvements"

# With specific mode
claude --permission-mode plan -p "explain this codebase structure"

# Continue previous session
claude -c
```

---

## 🎓 Pro Tips for Maximum Productivity

### 1. **Be Specific, Not Vague**
❌ "fix the bug"
✅ "fix the login bug where users see a blank screen after entering wrong credentials in auth/login.go:142"

### 2. **Let Claude Explore First**
Before making changes:
```
"First, analyze the codebase structure and understand how authentication works.
Then, add OAuth support following existing patterns."
```

### 3. **Break Complex Tasks into Steps**
```
1. Create database schema for user profiles
2. Build API endpoint to manage profiles
3. Add frontend page for profile editing
```

### 4. **Use Plan Mode for Exploration**
```bash
claude --permission-mode plan
> "Explain how the payment system works"
```

### 5. **Name Important Sessions**
```bash
# During session:
/rename auth-refactor

# Later:
claude --resume auth-refactor
```

### 6. **Leverage Extended Thinking for Hard Problems**
Press `Option+T` / `Alt+T` before asking:
- "How should I architect this new microservice?"
- "Why is this race condition happening?"
- "What's the optimal database schema for this use case?"

### 7. **Create Project Memory** (`.claude/CLAUDE.md`)
Document project conventions so Claude always follows them:
```markdown
# Project Conventions

## Testing
- Always use testify/assert
- Run: `bazel test //path/to:go_default_test`
- Coverage: `bin/coverage src/path/to/service`

## Code Style
- Use Glue framework (Handler → Controller → Gateway/Repository)
- Never use pointer-to-interface
```

### 8. **Reference Code Locations**
When Claude mentions code, it uses `file:line` format:
```
The bug is in auth/login.go:142
```
Your editor can jump directly to that location.

### 9. **Batch Independent Operations**
❌ One request per file
✅ "Update auth in handler.go, controller.go, and repository.go"

### 10. **Use MCP Servers** (`/mcp`)
Connect Claude to external tools:
- Databases (query directly)
- APIs (Jira, GitHub, Confluence)
- Custom tools

---

## 🔥 Advanced Workflows

### Workflow 1: Safe Refactoring
```bash
# Step 1: Analyze in plan mode
claude --permission-mode plan
> "Analyze dependencies of the auth module"

# Step 2: Create plan
> "Create a step-by-step refactoring plan"

# Step 3: Execute with asking permission
# Press Shift+Tab to switch to "ask" mode
> "Execute the refactoring plan"
```

### Workflow 2: Multi-Branch Development
```bash
# Terminal 1: Feature A
git worktree add ../feature-a -b feature-a
cd ../feature-a
claude
> "Implement OAuth integration"

# Terminal 2: Feature B (parallel)
git worktree add ../feature-b -b feature-b
cd ../feature-b
claude
> "Add rate limiting"
```

### Workflow 3: Investigation → Implementation
```bash
# Start with extended thinking
claude
# Press Option+T / Alt+T
> "ultrathink - investigate why latency increased in the last deploy"

# Review findings, then implement
> "Apply the performance optimizations you identified"
```

### Workflow 4: Code Review Assistant
```bash
# Paste screenshot of PR or diff
# Press Ctrl+V
> "Review this code for security issues and suggest improvements"
```

---

## ⚡ Quick Reference Card

```
Ctrl+C       Cancel            |  /plan         Read-only mode
Ctrl+L       Clear screen      |  /compact      Compress history
Ctrl+B       Background task   |  /resume       Pick session
Esc Esc      Rewind changes    |  /vim          Vim mode
Shift+Tab    Change mode       |  /mcp          External tools
Option+T     Deep thinking     |  /hooks        Automation
Ctrl+V       Paste image       |  /context      Token usage
?            Show shortcuts    |  /help         Get help
```

---

## 🎯 When to Use What

| Task | Tool/Feature |
|------|--------------|
| Explore unfamiliar codebase | Plan mode (`Shift+Tab` or `/plan`) |
| Complex architectural decision | Extended thinking (`Option+T`) |
| Parallel feature development | Git worktrees + multiple sessions |
| Protect sensitive files | Hooks (permission-request) |
| Enforce code style | Hooks (post-tool-use) |
| Reusable workflows | Custom slash commands |
| Team conventions | Skills (`.claude/skills/`) |
| Long conversation | `/compact` to reduce context |
| Heavy operations | `Ctrl+B` to background |
| Made a mistake | `Esc` `Esc` to rewind |

---

## 📚 Further Reading

- Full docs: https://code.claude.com/docs
- Report issues: https://github.com/anthropics/claude-code/issues
- Get help: `/help` or `claude --help`

---

**Remember**: Claude Code is a collaborative pair programmer. Communicate naturally, be specific about your goals, and let it explore before making changes. The more context you provide, the better the results.
